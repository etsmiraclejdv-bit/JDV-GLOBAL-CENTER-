-- ---------- Utilitaires internes ----------
create or replace function private.jdvcrm_wh_label_v1(p_warehouse_id uuid)
returns text
language sql
stable
security definer
set search_path = ''
as $function$
  select w.name || case when w.city is not null then ' - ' || w.city else '' end
  from public.warehouses w where w.id = p_warehouse_id;
$function$;

create or replace function private.jdvcrm_loc_is_warehouse_v1(p_loc text, p_wh uuid, p_label text)
returns boolean
language sql
immutable
set search_path = ''
as $function$
  select p_loc is not null and (p_loc = p_wh::text or p_loc = 'warehouse:' || p_wh::text or p_loc = p_label);
$function$;

create or replace function private.jdvcrm_loc_label_v1(p_loc text, p_pros text)
returns text
language sql
stable
security definer
set search_path = ''
as $function$
  select case
    when p_loc is null then null
    when p_loc in ('stock_central', 'stock_principal') then 'Stock central'
    when p_loc = 'stock_prospecteur' then 'Prospecteur · ' || coalesce(p_pros, 'inconnu')
    when p_loc = 'supplier' then 'Fournisseur'
    when p_loc = 'client' then 'Client'
    when p_loc ~* '^(warehouse:)?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then
      coalesce((select 'Entrepôt · ' || w.name || case when w.city is not null then ' - ' || w.city else '' end
                from public.warehouses w where w.id = replace(p_loc, 'warehouse:', '')::uuid), 'Entrepôt')
    else 'Entrepôt · ' || p_loc
  end;
$function$;

revoke all on function private.jdvcrm_wh_label_v1(uuid), private.jdvcrm_loc_is_warehouse_v1(text, uuid, text),
  private.jdvcrm_loc_label_v1(text, text) from public, anon, authenticated;

-- ---------- Entrepôts accessibles ----------
create or replace function public.jdvcrm_my_warehouses_v1()
returns table (warehouse_id uuid, organization_id uuid, code text, name text, city text, active boolean, access_role text)
language sql
stable
security definer
set search_path = ''
as $function$
  select w.id, w.organization_id, w.code, w.name, w.city, w.active,
         case when private.is_super_admin() or private.is_org_admin(w.organization_id) then 'admin' else 'manager' end
  from public.warehouses w
  where (select auth.uid()) is not null and private.can_manage_warehouse(w.id)
  order by w.name;
$function$;

-- ---------- Stock de l'entrepôt ----------
create or replace function public.jdvcrm_warehouse_stock_v1(p_warehouse_id uuid)
returns table (article_id uuid, article_name text, article_code text, category text, quantity numeric,
               reserved_quantity numeric, available numeric, minimum_quantity numeric, is_low boolean)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare v_org uuid;
begin
  if (select auth.uid()) is null then raise exception 'Authentification requise'; end if;
  if not private.can_manage_warehouse(p_warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;
  select w.organization_id into v_org from public.warehouses w where w.id = p_warehouse_id;
  return query
  select a.id, a.name, a.code, a.category,
         coalesce(wi.quantity, 0), coalesce(wi.reserved_quantity, 0),
         coalesce(wi.quantity, 0) - coalesce(wi.reserved_quantity, 0),
         coalesce(wi.minimum_quantity, 0),
         (coalesce(wi.minimum_quantity, 0) > 0 and coalesce(wi.quantity, 0) <= coalesce(wi.minimum_quantity, 0))
  from public.articles a
  left join public.warehouse_inventory wi on wi.article_id = a.id and wi.warehouse_id = p_warehouse_id
  where a.organization_id = v_org and a.active = true
  order by a.name;
end;
$function$;

-- ---------- Prospecteurs affectés à l'entrepôt ----------
create or replace function public.jdvcrm_warehouse_prospecteurs_v1(p_warehouse_id uuid)
returns table (prospecteur_id uuid, code text, full_name text, phone text, status text, work_zone text,
               stock_units numeric, to_return_units numeric, overdue_count bigint,
               next_due_at timestamptz, last_supply_at timestamptz)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if (select auth.uid()) is null then raise exception 'Authentification requise'; end if;
  if not private.can_manage_warehouse(p_warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;
  return query
  select p.id, p.code, nullif(concat_ws(' ', p.first_name, p.last_name), ''), p.phone, p.status, a.work_zone,
    coalesce((select sum(ps.quantity) from public.prospecteur_stocks ps where ps.prospecteur_id = p.id), 0)::numeric,
    coalesce((select sum(h.remaining_quantity) from public.prospecteur_stock_holdings h
              where h.prospecteur_id = p.id and h.warehouse_id = p_warehouse_id
                and h.status in ('active', 'overdue') and h.remaining_quantity > 0), 0)::numeric,
    (select count(*) from public.prospecteur_stock_holdings h
      where h.prospecteur_id = p.id and h.warehouse_id = p_warehouse_id
        and h.status in ('active', 'overdue') and h.remaining_quantity > 0 and h.return_due_at <= now()),
    (select min(h.return_due_at) from public.prospecteur_stock_holdings h
      where h.prospecteur_id = p.id and h.warehouse_id = p_warehouse_id
        and h.status in ('active', 'overdue') and h.remaining_quantity > 0),
    (select max(h.supplied_at) from public.prospecteur_stock_holdings h
      where h.prospecteur_id = p.id and h.warehouse_id = p_warehouse_id)
  from public.prospecteur_warehouse_assignments a
  join public.prospecteurs p on p.id = a.prospecteur_id
  where a.warehouse_id = p_warehouse_id and a.active = true and a.is_primary = true
  order by 3;
end;
$function$;

-- ---------- Marchandises confiées (à retourner) ----------
create or replace function public.jdvcrm_warehouse_holdings_v1(p_warehouse_id uuid, p_prospecteur_id uuid default null)
returns table (holding_id uuid, prospecteur_id uuid, prospecteur_name text, article_id uuid, article_name text,
               quantity numeric, remaining_quantity numeric, supplied_at timestamptz, return_due_at timestamptz,
               hard_due_at timestamptz, status text, is_overdue boolean)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if (select auth.uid()) is null then raise exception 'Authentification requise'; end if;
  if not private.can_manage_warehouse(p_warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;
  return query
  select h.id, h.prospecteur_id, nullif(concat_ws(' ', p.first_name, p.last_name), ''), h.article_id, a.name,
         h.quantity, h.remaining_quantity, h.supplied_at, h.return_due_at, h.hard_due_at, h.status,
         (h.return_due_at <= now())
  from public.prospecteur_stock_holdings h
  join public.prospecteurs p on p.id = h.prospecteur_id
  join public.articles a on a.id = h.article_id
  where h.warehouse_id = p_warehouse_id and h.remaining_quantity > 0 and h.status in ('active', 'overdue')
    and (p_prospecteur_id is null or h.prospecteur_id = p_prospecteur_id)
  order by h.return_due_at;
end;
$function$;

-- ---------- L'entrepôt fournit un prospecteur ----------
create or replace function public.jdvcrm_warehouse_supply_prospecteur_v1(
  p_warehouse_id uuid, p_prospecteur_id uuid, p_items jsonb,
  p_override boolean default false, p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_org uuid;
  v_label text;
  v_request_id uuid;
  v_item record;
  v_available numeric;
  v_article_name text;
  v_blocked integer;
  v_units numeric := 0;
  v_lines integer := 0;
  v_note text;
begin
  if v_uid is null then raise exception 'Authentification requise'; end if;
  select w.organization_id into v_org from public.warehouses w where w.id = p_warehouse_id and w.active = true;
  if v_org is null then raise exception 'Entrepôt introuvable ou inactif'; end if;
  if not private.can_manage_warehouse(p_warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;
  if not private.is_super_admin() and not private.org_subscription_active(v_org) then raise exception 'Abonnement requis'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Sélectionnez au moins un article';
  end if;
  if not exists (select 1 from public.prospecteurs p
                 where p.id = p_prospecteur_id and p.organization_id = v_org and p.status = 'active') then
    raise exception 'Prospecteur introuvable ou inactif';
  end if;
  if not exists (select 1 from public.prospecteur_warehouse_assignments a
                 where a.prospecteur_id = p_prospecteur_id and a.organization_id = v_org
                   and a.warehouse_id = p_warehouse_id and a.active = true and a.is_primary = true) then
    raise exception 'Ce prospecteur n''est pas affecté à cet entrepôt';
  end if;

  select count(*) into v_blocked from public.prospecteur_stock_holdings h
  where h.organization_id = v_org and h.prospecteur_id = p_prospecteur_id
    and h.remaining_quantity > 0 and h.status in ('active', 'overdue') and h.return_due_at <= now();
  if v_blocked > 0 and not coalesce(p_override, false) then
    raise exception 'Ce prospecteur a % lot(s) à retourner en retard. Confirmez pour le fournir malgré tout.', v_blocked;
  end if;

  v_label := private.jdvcrm_wh_label_v1(p_warehouse_id);
  v_note := coalesce(nullif(trim(p_notes), ''), 'Approvisionnement par le responsable de l''entrepôt');

  insert into public.prospecteur_supply_requests(organization_id, prospecteur_id, warehouse_id, status,
    requested_at, processed_at, processed_by, notes)
  values (v_org, p_prospecteur_id, p_warehouse_id, 'approved', now(), now(), v_uid, v_note)
  returning id into v_request_id;

  for v_item in
    select x.article_id, x.quantity from jsonb_to_recordset(p_items) as x(article_id uuid, quantity numeric)
  loop
    if v_item.article_id is null or v_item.quantity is null or v_item.quantity <= 0
       or v_item.quantity <> trunc(v_item.quantity) then
      raise exception 'Quantité invalide pour un article';
    end if;

    v_article_name := null;
    select a.name into v_article_name from public.articles a
    where a.id = v_item.article_id and a.organization_id = v_org and a.active = true;
    if v_article_name is null then raise exception 'Article introuvable ou inactif'; end if;

    insert into public.prospecteur_supply_request_items(organization_id, request_id, article_id, quantity)
    values (v_org, v_request_id, v_item.article_id, v_item.quantity);

    v_available := null;
    select coalesce(wi.quantity - wi.reserved_quantity, 0) into v_available
    from public.warehouse_inventory wi
    where wi.organization_id = v_org and wi.warehouse_id = p_warehouse_id and wi.article_id = v_item.article_id
    for update;
    if coalesce(v_available, 0) < v_item.quantity then
      raise exception 'Stock insuffisant pour % (disponible: %, demandé: %)',
        v_article_name, coalesce(v_available, 0), v_item.quantity;
    end if;

    update public.warehouse_inventory set quantity = quantity - v_item.quantity, updated_at = now()
    where organization_id = v_org and warehouse_id = p_warehouse_id and article_id = v_item.article_id;

    insert into public.prospecteur_stocks(organization_id, prospecteur_id, article_id, quantity, updated_at)
    values (v_org, p_prospecteur_id, v_item.article_id, v_item.quantity::integer, now())
    on conflict (prospecteur_id, article_id)
    do update set quantity = public.prospecteur_stocks.quantity + excluded.quantity, updated_at = now();

    insert into public.prospecteur_stock_holdings(organization_id, prospecteur_id, article_id, warehouse_id,
      supply_request_id, quantity, remaining_quantity, supplied_at, return_due_at, hard_due_at, status, notes)
    values (v_org, p_prospecteur_id, v_item.article_id, p_warehouse_id, v_request_id, v_item.quantity,
      v_item.quantity, now(), now() + interval '10 days', now() + interval '20 days', 'active',
      'Marchandise confiée par le responsable de l''entrepôt; retour obligatoire si non vendue.');

    insert into public.stock_movements(organization_id, article_id, prospecteur_id, movement_type, quantity,
      reference_type, reference_id, source_location, destination_location, notes, created_by)
    values (v_org, v_item.article_id, p_prospecteur_id, 'transfer_to_prospecteur', v_item.quantity::integer,
      'prospecteur_supply_request', v_request_id, v_label, 'stock_prospecteur', v_note, v_uid);

    v_units := v_units + v_item.quantity;
    v_lines := v_lines + 1;
  end loop;

  return jsonb_build_object('request_id', v_request_id, 'lines', v_lines, 'units', v_units,
                            'override_used', v_blocked > 0);
end;
$function$;

-- ---------- L'entrepôt reçoit un retour de marchandise d'un prospecteur (total ou partiel) ----------
create or replace function public.jdvcrm_warehouse_receive_return_v1(
  p_holding_id uuid, p_quantity numeric default null, p_note text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  h public.prospecteur_stock_holdings%rowtype;
  v_qty numeric;
  v_ps_qty integer;
  v_left numeric;
begin
  if v_uid is null then raise exception 'Authentification requise'; end if;
  select * into h from public.prospecteur_stock_holdings where id = p_holding_id for update;
  if not found then raise exception 'Marchandise confiée introuvable'; end if;
  if not private.can_manage_warehouse(h.warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;
  if not private.is_super_admin() and not private.org_subscription_active(h.organization_id) then
    raise exception 'Abonnement requis';
  end if;
  if h.remaining_quantity <= 0 or h.status in ('returned', 'sold') then
    raise exception 'Cette marchandise ne contient plus de quantité à retourner';
  end if;

  v_qty := coalesce(p_quantity, h.remaining_quantity);
  if v_qty <= 0 or v_qty <> trunc(v_qty) or v_qty > h.remaining_quantity then
    raise exception 'Quantité invalide : entre 1 et %', h.remaining_quantity;
  end if;

  select ps.quantity into v_ps_qty from public.prospecteur_stocks ps
  where ps.organization_id = h.organization_id and ps.prospecteur_id = h.prospecteur_id and ps.article_id = h.article_id
  for update;
  if not found or v_ps_qty < v_qty then raise exception 'Stock prospecteur incohérent pour cet article'; end if;

  update public.prospecteur_stocks set quantity = quantity - v_qty, updated_at = now()
  where organization_id = h.organization_id and prospecteur_id = h.prospecteur_id and article_id = h.article_id;

  insert into public.warehouse_inventory(organization_id, warehouse_id, article_id, quantity, reserved_quantity,
    minimum_quantity, updated_at)
  values (h.organization_id, h.warehouse_id, h.article_id, v_qty, 0, 0, now())
  on conflict (warehouse_id, article_id)
  do update set quantity = public.warehouse_inventory.quantity + excluded.quantity, updated_at = now();

  insert into public.stock_movements(organization_id, article_id, prospecteur_id, movement_type, quantity,
    reference_type, reference_id, source_location, destination_location, notes, created_by)
  values (h.organization_id, h.article_id, h.prospecteur_id, 'return_from_prospecteur', v_qty::integer,
    'prospecteur_stock_return', h.id, 'stock_prospecteur', private.jdvcrm_wh_label_v1(h.warehouse_id),
    coalesce(nullif(trim(p_note), ''), 'Retour de marchandise non vendue reçu par l''entrepôt; aucune commission générée'),
    v_uid);

  v_left := h.remaining_quantity - v_qty;
  update public.prospecteur_stock_holdings
     set remaining_quantity = v_left,
         status = case when v_left = 0 then 'returned' else status end,
         returned_at = case when v_left = 0 then now() else returned_at end,
         updated_at = now()
   where id = h.id;

  return jsonb_build_object('holding_id', h.id, 'returned_quantity', v_qty, 'remaining_quantity', v_left,
                            'status', case when v_left = 0 then 'returned' else h.status end);
end;
$function$;

-- ---------- Équipe de l'entrepôt (admin) ----------
create or replace function public.jdvcrm_warehouse_team_v1(p_warehouse_id uuid)
returns table (manager_id uuid, user_id uuid, display_name text, phone text, email text, status text, created_at timestamptz)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare v_org uuid;
begin
  if (select auth.uid()) is null then raise exception 'Authentification requise'; end if;
  select w.organization_id into v_org from public.warehouses w where w.id = p_warehouse_id;
  if v_org is null then raise exception 'Entrepôt introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(v_org)) then raise exception 'Accès refusé : administrateur requis'; end if;
  return query
  select m.id, m.user_id, m.display_name, m.phone, u.email::text, m.status, m.created_at
  from public.warehouse_managers m left join auth.users u on u.id = m.user_id
  where m.warehouse_id = p_warehouse_id
  order by m.created_at;
end;
$function$;

create or replace function public.jdvcrm_set_warehouse_manager_status_v1(p_manager_id uuid, p_status text)
returns void
language plpgsql
security definer
set search_path = ''
as $function$
declare v_org uuid;
begin
  if (select auth.uid()) is null then raise exception 'Authentification requise'; end if;
  if p_status not in ('active', 'suspended') then raise exception 'Statut invalide'; end if;
  select m.organization_id into v_org from public.warehouse_managers m where m.id = p_manager_id;
  if v_org is null then raise exception 'Responsable introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(v_org)) then raise exception 'Accès refusé : administrateur requis'; end if;
  update public.warehouse_managers set status = p_status, updated_at = now() where id = p_manager_id;
end;
$function$;

-- ---------- Vue d'ensemble des sous-branches pour l'admin ----------
create or replace function public.jdvcrm_warehouse_admin_overview_v1(p_organization_id uuid)
returns table (warehouse_id uuid, code text, name text, city text, active boolean, managers_count bigint,
               prospecteurs_count bigint, stock_units numeric, low_stock_count bigint, open_tickets bigint,
               pending_requests bigint)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if (select auth.uid()) is null then raise exception 'Authentification requise'; end if;
  if not (private.is_super_admin() or private.is_org_admin(p_organization_id)) then
    raise exception 'Accès refusé : administrateur requis';
  end if;
  return query
  select w.id, w.code, w.name, w.city, w.active,
    (select count(*) from public.warehouse_managers m where m.warehouse_id = w.id and m.status = 'active'),
    (select count(*) from public.prospecteur_warehouse_assignments a where a.warehouse_id = w.id and a.active and a.is_primary),
    coalesce((select sum(wi.quantity) from public.warehouse_inventory wi where wi.warehouse_id = w.id), 0)::numeric,
    (select count(*) from public.warehouse_inventory wi where wi.warehouse_id = w.id
       and wi.minimum_quantity > 0 and wi.quantity <= wi.minimum_quantity),
    (select count(*) from public.warehouse_tickets t where t.warehouse_id = w.id and t.status in ('open', 'in_progress')),
    (select count(*) from public.warehouse_supply_requests r where r.warehouse_id = w.id
       and r.target = 'admin' and r.status in ('sent', 'approved'))
  from public.warehouses w
  where w.organization_id = p_organization_id
  order by w.name;
end;
$function$;

-- ---------- Droits d'exécution ----------
do $$
declare f text;
begin
  foreach f in array array[
    'public.jdvcrm_my_warehouses_v1()',
    'public.jdvcrm_warehouse_stock_v1(uuid)',
    'public.jdvcrm_warehouse_prospecteurs_v1(uuid)',
    'public.jdvcrm_warehouse_holdings_v1(uuid, uuid)',
    'public.jdvcrm_warehouse_supply_prospecteur_v1(uuid, uuid, jsonb, boolean, text)',
    'public.jdvcrm_warehouse_receive_return_v1(uuid, numeric, text)',
    'public.jdvcrm_warehouse_team_v1(uuid)',
    'public.jdvcrm_set_warehouse_manager_status_v1(uuid, text)',
    'public.jdvcrm_warehouse_admin_overview_v1(uuid)'
  ] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;