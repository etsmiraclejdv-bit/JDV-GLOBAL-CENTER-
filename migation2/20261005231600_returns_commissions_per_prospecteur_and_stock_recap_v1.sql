-- ---------- 1) Règles de commission : possibilité de cibler un prospecteur ----------
alter table public.commission_rules
  add column if not exists prospecteur_id uuid references public.prospecteurs(id) on delete cascade;

create index if not exists idx_fk_commission_rules_prospecteur_id on public.commission_rules (prospecteur_id);

do $$
begin
  if not exists (select 1 from pg_constraint where conname = 'commission_rules_created_by_fkey') then
    alter table public.commission_rules
      add constraint commission_rules_created_by_fkey
      foreign key (created_by) references auth.users(id) on delete set null;
  end if;
  if not exists (select 1 from pg_constraint where conname = 'commission_rules_amounts_check') then
    alter table public.commission_rules
      add constraint commission_rules_amounts_check check (
        (rate_percent is null or (rate_percent >= 0 and rate_percent <= 100))
        and (fixed_amount is null or fixed_amount >= 0)
        and (per_unit_amount is null or per_unit_amount >= 0)
      );
  end if;
end $$;

create or replace function public.jdvcrm_validate_commission_rule_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare v_org uuid;
begin
  if new.prospecteur_id is not null then
    select organization_id into v_org from public.prospecteurs where id = new.prospecteur_id;
    if not found or v_org <> new.organization_id then
      raise exception 'Le prospecteur de la règle n''appartient pas à cette entreprise';
    end if;
  end if;
  if new.article_id is not null then
    select organization_id into v_org from public.articles where id = new.article_id;
    if not found or v_org <> new.organization_id then
      raise exception 'L''article de la règle n''appartient pas à cette entreprise';
    end if;
  end if;
  select organization_id into v_org from public.commission_types where id = new.commission_type_id;
  if not found or v_org <> new.organization_id then
    raise exception 'Le type de commission n''appartient pas à cette entreprise';
  end if;
  return new;
end;
$function$;

revoke all on function public.jdvcrm_validate_commission_rule_v1() from public, anon, authenticated;

drop trigger if exists trg_jdvcrm_validate_commission_rule_v1 on public.commission_rules;
create trigger trg_jdvcrm_validate_commission_rule_v1
  before insert or update on public.commission_rules
  for each row execute function public.jdvcrm_validate_commission_rule_v1();

-- ---------- 2) Droits : seul l'admin (ou manager) gère les commissions ----------
drop policy if exists commission_types_org_access on public.commission_types;

create policy commission_types_member_select on public.commission_types
  for select to authenticated
  using (
    private.is_org_admin(organization_id)
    or exists (select 1 from public.organization_members om
               where om.organization_id = commission_types.organization_id
                 and om.user_id = (select auth.uid()) and om.status = 'active')
  );

create policy commission_types_admin_insert on public.commission_types
  for insert to authenticated
  with check (
    private.is_org_admin(organization_id)
    or exists (select 1 from public.organization_members om
               where om.organization_id = commission_types.organization_id
                 and om.user_id = (select auth.uid()) and om.status = 'active'
                 and om.role in ('business_admin','manager'))
  );

create policy commission_types_admin_update on public.commission_types
  for update to authenticated
  using (
    private.is_org_admin(organization_id)
    or exists (select 1 from public.organization_members om
               where om.organization_id = commission_types.organization_id
                 and om.user_id = (select auth.uid()) and om.status = 'active'
                 and om.role in ('business_admin','manager'))
  )
  with check (
    private.is_org_admin(organization_id)
    or exists (select 1 from public.organization_members om
               where om.organization_id = commission_types.organization_id
                 and om.user_id = (select auth.uid()) and om.status = 'active'
                 and om.role in ('business_admin','manager'))
  );

create policy commission_types_admin_delete on public.commission_types
  for delete to authenticated
  using (
    private.is_org_admin(organization_id)
    or exists (select 1 from public.organization_members om
               where om.organization_id = commission_types.organization_id
                 and om.user_id = (select auth.uid()) and om.status = 'active'
                 and om.role in ('business_admin','manager'))
  );

-- Règles : un prospecteur ne voit que les règles générales et les siennes.
drop policy if exists commission_rules_org_access on public.commission_rules;

create policy commission_rules_visible_select on public.commission_rules
  for select to authenticated
  using (
    private.is_org_admin(organization_id)
    or exists (select 1 from public.organization_members om
               where om.organization_id = commission_rules.organization_id
                 and om.user_id = (select auth.uid()) and om.status = 'active'
                 and om.role in ('business_admin','manager','accountant','viewer'))
    or exists (select 1 from public.prospecteurs p
               where p.organization_id = commission_rules.organization_id
                 and p.user_id = (select auth.uid()) and p.status = 'active'
                 and (commission_rules.prospecteur_id is null or commission_rules.prospecteur_id = p.id))
  );

-- Ajustements : un prospecteur ne voit que les siens.
drop policy if exists commission_adjustments_org_access on public.commission_adjustments;

create policy commission_adjustments_visible_select on public.commission_adjustments
  for select to authenticated
  using (
    private.is_org_admin(organization_id)
    or exists (select 1 from public.organization_members om
               where om.organization_id = commission_adjustments.organization_id
                 and om.user_id = (select auth.uid()) and om.status = 'active'
                 and om.role in ('business_admin','manager','accountant','viewer'))
    or exists (select 1 from public.prospecteurs p
               where p.id = commission_adjustments.prospecteur_id
                 and p.user_id = (select auth.uid()) and p.status = 'active')
  );

-- Le concepteur (super admin) garde la main sur les règles et ajustements.
create policy commission_rules_super_admin_all on public.commission_rules
  for all to authenticated
  using (private.is_super_admin()) with check (private.is_super_admin());

create policy commission_adjustments_super_admin_all on public.commission_adjustments
  for all to authenticated
  using (private.is_super_admin()) with check (private.is_super_admin());

-- ---------- 3) Calcul des commissions : règles par prospecteur + taux personnel ----------
create or replace function public.jdvcrm_apply_sale_commissions_v1(p_sale_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_sale public.sales%rowtype;
  v_total numeric(14,2);
  v_count integer := 0;
  v_amount numeric(14,2) := 0;
  r record;
  v_calc numeric(14,2);
  v_cat text;
  v_rate numeric;
begin
  select * into v_sale from public.sales where id = p_sale_id for update;
  if not found then raise exception 'Vente introuvable'; end if;
  if v_sale.prospecteur_id is null then
    return jsonb_build_object('sale_id', p_sale_id, 'commission_count', 0, 'total', 0);
  end if;

  v_total := case when v_sale.sale_type = 'cash' then v_sale.cash_price * v_sale.quantity
                  else v_sale.credit_price * v_sale.quantity end;
  select a.category into v_cat from public.articles a where a.id = v_sale.article_id;

  for r in
    with m as (
      select cr.*, ct.name as type_name, ct.calculation_method as type_method
      from public.commission_rules cr
      join public.commission_types ct on ct.id = cr.commission_type_id and ct.active = true
      where cr.organization_id = v_sale.organization_id
        and cr.active = true
        and (cr.valid_from is null or cr.valid_from <= v_sale.sale_date)
        and (cr.valid_to is null or cr.valid_to >= v_sale.sale_date)
        and (cr.applies_to_sale_type = 'both' or cr.applies_to_sale_type = v_sale.sale_type)
        and cr.target_role = 'prospecteur'
        and (cr.prospecteur_id is null or cr.prospecteur_id = v_sale.prospecteur_id)
        and (cr.scope = 'organization'
             or (cr.scope = 'article' and cr.article_id = v_sale.article_id)
             or (cr.scope = 'category' and lower(coalesce(cr.category_name, '')) = lower(coalesce(v_cat, ''))))
    )
    select m.* from m
    where m.cumulative = true
       or m.priority = (select max(m2.priority) from m m2 where m2.cumulative = false)
    order by m.priority desc, m.created_at asc
  loop
    if exists (select 1 from public.commissions c
               where c.sale_id = v_sale.id and c.rule_id = r.id and c.prospecteur_id = v_sale.prospecteur_id) then
      continue;
    end if;

    v_calc := round(case
      when r.type_method = 'percentage' then v_total * coalesce(r.rate_percent, 0) / 100
      when r.type_method = 'per_unit' then v_sale.quantity * coalesce(r.per_unit_amount, 0)
      else coalesce(r.fixed_amount, 0) end, 2);

    insert into public.commissions(organization_id, prospecteur_id, sale_id, article_id, commission_rate, base_amount,
      commission_amount, status, commission_type_id, rule_id, calculation_method, source_type, calculation_snapshot, description)
    values (v_sale.organization_id, v_sale.prospecteur_id, v_sale.id, v_sale.article_id, coalesce(r.rate_percent, 0), v_total,
      v_calc, 'pending', r.commission_type_id, r.id, r.type_method, 'sale',
      jsonb_build_object('rule_id', r.id, 'rule_name', r.name, 'type', r.type_name, 'method', r.type_method,
        'scope', r.scope, 'priority', r.priority, 'rate_percent', r.rate_percent, 'fixed_amount', r.fixed_amount,
        'per_unit_amount', r.per_unit_amount, 'prospecteur_specific', r.prospecteur_id is not null,
        'base_amount', v_total, 'quantity', v_sale.quantity, 'sale_type', v_sale.sale_type),
      r.name);
    v_count := v_count + 1;
    v_amount := v_amount + v_calc;
  end loop;

  -- Aucune règle applicable : on utilise le pourcentage personnel du prospecteur (défini par l'admin).
  if v_count = 0 then
    select least(greatest(coalesce(p.commission_rate, 0), 0), 100) into v_rate
    from public.prospecteurs p where p.id = v_sale.prospecteur_id;
    if coalesce(v_rate, 0) > 0
       and not exists (select 1 from public.commissions c
                       where c.sale_id = v_sale.id and c.prospecteur_id = v_sale.prospecteur_id
                         and c.source_type = 'prospecteur_rate') then
      v_calc := round(v_total * v_rate / 100, 2);
      insert into public.commissions(organization_id, prospecteur_id, sale_id, article_id, commission_rate, base_amount,
        commission_amount, status, calculation_method, source_type, calculation_snapshot, description)
      values (v_sale.organization_id, v_sale.prospecteur_id, v_sale.id, v_sale.article_id, v_rate, v_total,
        v_calc, 'pending', 'percentage', 'prospecteur_rate',
        jsonb_build_object('method', 'percentage', 'rate_percent', v_rate, 'base_amount', v_total,
          'quantity', v_sale.quantity, 'sale_type', v_sale.sale_type, 'origin', 'taux_personnel_prospecteur'),
        'Taux personnel du prospecteur');
      v_count := 1;
      v_amount := v_calc;
    end if;
  end if;

  return jsonb_build_object('sale_id', v_sale.id, 'commission_count', v_count, 'total', v_amount);
end;
$function$;

-- ---------- 4) Retour de marchandise : la commission est annulée ----------
create or replace function public.jdvcrm_cancel_return_commissions_v1(p_return_id uuid)
returns integer
language plpgsql
security definer
set search_path = ''
as $function$
declare
  r public.sales_returns%rowtype;
  v_sale public.sales%rowtype;
  v_returned numeric;
  v_ratio numeric;
  c record;
  v_orig_amount numeric;
  v_orig_base numeric;
  v_target_amount numeric;
  v_target_base numeric;
  v_money_out boolean;
  v_clawed numeric;
  v_delta numeric;
  v_snap jsonb;
  v_count integer := 0;
begin
  select * into r from public.sales_returns where id = p_return_id;
  if not found then return 0; end if;
  select * into v_sale from public.sales where id = r.sale_id;
  if not found or v_sale.prospecteur_id is null or coalesce(v_sale.quantity, 0) <= 0 then return 0; end if;

  select coalesce(sum(i.quantity), 0) into v_returned
  from public.sales_return_items i
  join public.sales_returns sr on sr.id = i.return_id
  where sr.sale_id = r.sale_id and sr.status = 'processed' and i.article_id = v_sale.article_id;

  v_ratio := least(1, v_returned / v_sale.quantity);
  if v_ratio <= 0 then return 0; end if;

  for c in
    select * from public.commissions
    where sale_id = r.sale_id and status in ('pending', 'approved', 'paid')
    for update
  loop
    v_snap := coalesce(c.calculation_snapshot, '{}'::jsonb);
    v_orig_amount := coalesce((v_snap ->> 'original_commission_amount')::numeric, c.commission_amount);
    v_orig_base := coalesce((v_snap ->> 'original_base_amount')::numeric, c.base_amount);
    v_target_amount := round(v_orig_amount * (1 - v_ratio), 2);
    v_target_base := round(v_orig_base * (1 - v_ratio), 2);
    v_money_out := c.status = 'paid'
      or exists (select 1 from public.commission_payouts po
                 where po.commission_id = c.id and po.status in ('processing', 'pending', 'paid'));
    v_snap := v_snap || jsonb_build_object(
      'original_commission_amount', v_orig_amount, 'original_base_amount', v_orig_base,
      'returned_ratio', v_ratio, 'last_return_id', r.id, 'last_return_number', r.return_number);

    if v_money_out then
      -- Argent déjà parti (ou en cours d'envoi) : on enregistre une reprise à déduire du prospecteur.
      v_clawed := coalesce((v_snap ->> 'clawback_total')::numeric, 0);
      v_delta := round(v_orig_amount * v_ratio, 2) - v_clawed;
      if v_delta > 0 then
        insert into public.commission_adjustments(organization_id, prospecteur_id, commission_type_id, amount, reason, status, created_by)
        values (c.organization_id, c.prospecteur_id, c.commission_type_id, -v_delta,
                'Retour de marchandise ' || r.return_number || ' : commission déjà versée à reprendre',
                'pending', (select auth.uid()));
        v_snap := v_snap || jsonb_build_object('clawback_total', v_clawed + v_delta);
        update public.commissions set calculation_snapshot = v_snap, updated_at = now() where id = c.id;
        v_count := v_count + 1;
      end if;
    elsif v_target_amount <= 0 then
      -- Tout est retourné : plus aucune commission possible.
      update public.commission_payouts
         set status = 'cancelled', failure_reason = 'Retour de marchandise ' || r.return_number, updated_at = now()
       where commission_id = c.id and status in ('queued', 'failed');
      update public.commissions
         set status = 'cancelled', commission_amount = 0, base_amount = 0,
             calculation_snapshot = v_snap, updated_at = now()
       where id = c.id;
      v_count := v_count + 1;
    else
      -- Retour partiel : la commission est réduite au prorata des articles conservés.
      update public.commission_payouts
         set amount = v_target_amount, updated_at = now()
       where commission_id = c.id and status in ('queued', 'failed');
      update public.commissions
         set commission_amount = v_target_amount, base_amount = v_target_base,
             calculation_snapshot = v_snap, updated_at = now()
       where id = c.id;
      v_count := v_count + 1;
    end if;
  end loop;

  return v_count;
end;
$function$;

revoke all on function public.jdvcrm_cancel_return_commissions_v1(uuid) from public, anon, authenticated;

create or replace function public.jdvcrm_return_commission_trigger_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.status = 'processed' and old.status is distinct from 'processed' then
    perform public.jdvcrm_cancel_return_commissions_v1(new.id);
  end if;
  return new;
end;
$function$;

revoke all on function public.jdvcrm_return_commission_trigger_v1() from public, anon, authenticated;

drop trigger if exists trg_jdvcrm_return_cancel_commissions on public.sales_returns;
create trigger trg_jdvcrm_return_cancel_commissions
  after update of status on public.sales_returns
  for each row execute function public.jdvcrm_return_commission_trigger_v1();

-- ---------- 5) Retour de marchandise en une seule étape (stock + commission immédiats) ----------
create or replace function public.jdvcrm_create_sale_return_v1(
  p_sale_id uuid,
  p_items jsonb default null,
  p_reason text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_sale public.sales%rowtype;
  v_return_id uuid;
  v_number text;
  v_items jsonb;
  v_item record;
  v_unit numeric;
  v_line numeric;
  v_refund numeric := 0;
  v_updated integer;
begin
  if v_uid is null then raise exception 'Authentification requise'; end if;
  select * into v_sale from public.sales where id = p_sale_id;
  if not found then raise exception 'Vente introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(v_sale.organization_id)) then
    raise exception 'Accès refusé : administrateur requis';
  end if;
  if not private.is_super_admin() and not private.has_active_subscription(v_sale.organization_id) then
    raise exception 'Abonnement requis';
  end if;
  if v_sale.status = 'cancelled' then raise exception 'Vente annulée : retour impossible'; end if;

  v_items := case when p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0
                  then jsonb_build_array(jsonb_build_object('quantity', v_sale.quantity))
                  else p_items end;
  v_unit := case when v_sale.sale_type = 'cash' then v_sale.cash_price else v_sale.credit_price end;
  v_number := 'RET-' || to_char(now() at time zone 'utc', 'YYMMDD') || '-'
              || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));

  insert into public.sales_returns(organization_id, sale_id, client_id, return_number, reason, refund_amount, status, created_by)
  values (v_sale.organization_id, v_sale.id, v_sale.client_id, v_number, p_reason, 0, 'pending', v_uid)
  returning id into v_return_id;

  for v_item in
    select x.article_id, x.quantity, x.serial_number_id, x.refund_amount
    from jsonb_to_recordset(v_items) as x(article_id uuid, quantity numeric, serial_number_id uuid, refund_amount numeric)
  loop
    if v_item.quantity is null or v_item.quantity <= 0 or v_item.quantity <> trunc(v_item.quantity) then
      raise exception 'Quantité de retour invalide';
    end if;
    v_line := coalesce(v_item.refund_amount, v_unit * v_item.quantity);
    insert into public.sales_return_items(organization_id, return_id, article_id, quantity, refund_amount, serial_number_id)
    values (v_sale.organization_id, v_return_id, coalesce(v_item.article_id, v_sale.article_id),
            v_item.quantity, v_line, v_item.serial_number_id);
    v_refund := v_refund + v_line;
  end loop;

  update public.sales_returns set refund_amount = v_refund, status = 'approved' where id = v_return_id;
  perform public.jdvcrm_process_sale_return(v_return_id);

  select count(*) into v_updated from public.commissions
  where sale_id = v_sale.id and calculation_snapshot ->> 'last_return_id' = v_return_id::text;

  return jsonb_build_object('return_id', v_return_id, 'return_number', v_number, 'status', 'processed',
                            'refund_amount', v_refund, 'commissions_updated', v_updated);
end;
$function$;

revoke all on function public.jdvcrm_create_sale_return_v1(uuid, jsonb, text) from public, anon;
grant execute on function public.jdvcrm_create_sale_return_v1(uuid, jsonb, text) to authenticated;

-- ---------- 6) Journal et récapitulatif des entrées / sorties de stock ----------
create or replace view public.jdvcrm_stock_journal_v1
with (security_invoker = true) as
with base as (
  select sm.*,
    case when sm.source_location ~* '^(warehouse:)?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
         then replace(sm.source_location, 'warehouse:', '')::uuid end as src_wh,
    case when sm.destination_location ~* '^(warehouse:)?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
         then replace(sm.destination_location, 'warehouse:', '')::uuid end as dst_wh
  from public.stock_movements sm
)
select
  b.id as movement_id,
  b.created_at as occurred_at,
  b.organization_id,
  b.article_id,
  a.name as article_name,
  a.code as article_code,
  b.movement_type,
  case b.movement_type
    when 'entry' then 'Entrée'
    when 'exit' then 'Sortie'
    when 'transfer_to_prospecteur' then 'Approvisionnement prospecteur'
    when 'return_from_prospecteur' then 'Retour de marchandise'
    when 'sale' then 'Vente'
    when 'adjustment' then 'Ajustement'
    when 'loss' then 'Perte'
    when 'transfer_out' then 'Transfert sortant'
    when 'transfer_in' then 'Transfert entrant'
    else b.movement_type end as movement_label,
  b.quantity,
  case
    when b.source_location is null then
      case when b.movement_type in ('exit', 'loss', 'sale', 'transfer_out') then
        case when b.prospecteur_id is not null and b.movement_type in ('exit', 'loss', 'sale')
             then 'Prospecteur · ' || coalesce(nullif(concat_ws(' ', p.first_name, p.last_name), ''), 'inconnu')
             else 'Stock central' end
      end
    when b.source_location in ('stock_central', 'stock_principal') then 'Stock central'
    when b.source_location = 'stock_prospecteur' then 'Prospecteur · ' || coalesce(nullif(concat_ws(' ', p.first_name, p.last_name), ''), 'inconnu')
    when b.source_location = 'supplier' then 'Fournisseur'
    when b.source_location = 'client' then 'Client'
    when b.src_wh is not null then 'Entrepôt · ' || coalesce(ws.name || case when ws.city is not null then ' - ' || ws.city else '' end, 'inconnu')
    else 'Entrepôt · ' || b.source_location
  end as from_section,
  case
    when b.destination_location is null then
      case when b.movement_type in ('entry', 'transfer_in') then 'Stock central' end
    when b.destination_location in ('stock_central', 'stock_principal') then 'Stock central'
    when b.destination_location = 'stock_prospecteur' then 'Prospecteur · ' || coalesce(nullif(concat_ws(' ', p.first_name, p.last_name), ''), 'inconnu')
    when b.destination_location = 'client' then 'Client'
    when b.dst_wh is not null then 'Entrepôt · ' || coalesce(wd.name || case when wd.city is not null then ' - ' || wd.city else '' end, 'inconnu')
    else 'Entrepôt · ' || b.destination_location
  end as to_section,
  b.prospecteur_id,
  nullif(concat_ws(' ', p.first_name, p.last_name), '') as prospecteur_name,
  b.reference_type,
  b.reference_id,
  b.notes,
  b.created_by
from base b
join public.articles a on a.id = b.article_id
left join public.prospecteurs p on p.id = b.prospecteur_id
left join public.warehouses ws on ws.id = b.src_wh
left join public.warehouses wd on wd.id = b.dst_wh;

create or replace view public.jdvcrm_stock_recap_v1
with (security_invoker = true) as
select
  x.organization_id, x.article_id, x.article_name, x.article_code, x.section,
  coalesce(sum(x.quantity) filter (where x.direction = 'entrée'), 0) as total_entrees,
  coalesce(sum(x.quantity) filter (where x.direction = 'sortie'), 0) as total_sorties,
  coalesce(sum(x.quantity) filter (where x.direction = 'entrée'), 0)
    - coalesce(sum(x.quantity) filter (where x.direction = 'sortie'), 0) as solde,
  max(x.occurred_at) as dernier_mouvement
from (
  select organization_id, article_id, article_name, article_code, to_section as section, 'entrée'::text as direction, quantity, occurred_at
  from public.jdvcrm_stock_journal_v1
  where to_section is not null and to_section not in ('Client', 'Fournisseur')
  union all
  select organization_id, article_id, article_name, article_code, from_section, 'sortie'::text, quantity, occurred_at
  from public.jdvcrm_stock_journal_v1
  where from_section is not null and from_section not in ('Client', 'Fournisseur')
) x
group by x.organization_id, x.article_id, x.article_name, x.article_code, x.section;

-- ---------- 7) Tableau unique de gestion des prospecteurs ----------
create or replace view public.jdvcrm_prospecteur_management_v1
with (security_invoker = true) as
select
  p.id as prospecteur_id,
  p.organization_id,
  p.code,
  nullif(concat_ws(' ', p.first_name, p.last_name), '') as full_name,
  p.phone,
  p.city,
  p.status,
  p.hired_at,
  p.commission_rate as personal_commission_rate,
  p.commission_payout_mode,
  wa.warehouse_id,
  w.name as warehouse_name,
  w.city as warehouse_city,
  wa.work_zone,
  wa.department,
  coalesce(ps.units, 0) as stock_units_held,
  coalesce(h.overdue, 0) as overdue_holdings,
  coalesce(s.sales_count, 0) as sales_count,
  coalesce(s.sales_amount, 0) as sales_amount,
  coalesce(cr.rules, 0) as specific_rules_count,
  coalesce(c.pending, 0) as commissions_pending,
  coalesce(c.approved, 0) as commissions_approved,
  coalesce(c.paid, 0) as commissions_paid,
  coalesce(c.cancelled_count, 0) as commissions_cancelled_count,
  coalesce(r.returns_count, 0) as returns_count
from public.prospecteurs p
left join lateral (
  select a.warehouse_id, a.work_zone, a.department
  from public.prospecteur_warehouse_assignments a
  where a.prospecteur_id = p.id and a.active = true and a.is_primary = true
  limit 1
) wa on true
left join public.warehouses w on w.id = wa.warehouse_id
left join lateral (
  select sum(x.quantity) as units from public.prospecteur_stocks x where x.prospecteur_id = p.id
) ps on true
left join lateral (
  select count(*) as overdue from public.prospecteur_stock_holdings hh
  where hh.prospecteur_id = p.id and hh.remaining_quantity > 0 and hh.status in ('active', 'overdue') and hh.return_due_at <= now()
) h on true
left join lateral (
  select count(*) as sales_count,
         sum((case when sa.sale_type = 'cash' then sa.cash_price else sa.credit_price end) * sa.quantity) as sales_amount
  from public.sales sa where sa.prospecteur_id = p.id and sa.status <> 'cancelled'
) s on true
left join lateral (
  select count(*) as rules from public.commission_rules rr where rr.prospecteur_id = p.id and rr.active = true
) cr on true
left join lateral (
  select sum(cm.commission_amount) filter (where cm.status = 'pending') as pending,
         sum(cm.commission_amount) filter (where cm.status = 'approved') as approved,
         sum(cm.commission_amount) filter (where cm.status = 'paid') as paid,
         count(*) filter (where cm.status = 'cancelled') as cancelled_count
  from public.commissions cm where cm.prospecteur_id = p.id
) c on true
left join lateral (
  select count(distinct sr.id) as returns_count
  from public.sales_returns sr join public.sales sa2 on sa2.id = sr.sale_id
  where sa2.prospecteur_id = p.id and sr.status = 'processed'
) r on true;

revoke all on public.jdvcrm_stock_journal_v1, public.jdvcrm_stock_recap_v1, public.jdvcrm_prospecteur_management_v1 from public, anon;
grant select on public.jdvcrm_stock_journal_v1, public.jdvcrm_stock_recap_v1, public.jdvcrm_prospecteur_management_v1 to authenticated;