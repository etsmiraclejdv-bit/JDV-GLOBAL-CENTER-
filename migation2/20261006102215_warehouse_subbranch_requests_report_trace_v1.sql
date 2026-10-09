-- ---------- Demandes d'approvisionnement : création ----------
create or replace function public.jdvcrm_warehouse_request_supply_v1(
  p_warehouse_id uuid, p_target text, p_supplier_id uuid, p_items jsonb, p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_org uuid;
  v_request_id uuid;
  v_ref text;
  v_item record;
  v_n integer := 0;
begin
  if v_uid is null then raise exception 'Authentification requise'; end if;
  select w.organization_id into v_org from public.warehouses w where w.id = p_warehouse_id and w.active = true;
  if v_org is null then raise exception 'Entrepôt introuvable ou inactif'; end if;
  if not private.can_manage_warehouse(p_warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;
  if not private.is_super_admin() and not private.org_subscription_active(v_org) then raise exception 'Abonnement requis'; end if;
  if p_target not in ('supplier', 'admin') then raise exception 'Destinataire invalide (fournisseur ou admin)'; end if;
  if p_target = 'supplier' and p_supplier_id is null then raise exception 'Choisissez un fournisseur'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Sélectionnez au moins un article';
  end if;

  insert into public.warehouse_supply_requests(organization_id, warehouse_id, target, supplier_id, status, notes, requested_by)
  values (v_org, p_warehouse_id, p_target, case when p_target = 'supplier' then p_supplier_id end, 'sent',
          nullif(trim(p_notes), ''), v_uid)
  returning id, reference into v_request_id, v_ref;

  for v_item in
    select x.article_id, x.quantity from jsonb_to_recordset(p_items) as x(article_id uuid, quantity numeric)
  loop
    if v_item.article_id is null or v_item.quantity is null or v_item.quantity <= 0
       or v_item.quantity <> trunc(v_item.quantity) then
      raise exception 'Quantité invalide pour un article';
    end if;
    insert into public.warehouse_supply_request_items(organization_id, warehouse_id, request_id, article_id, quantity)
    values (v_org, p_warehouse_id, v_request_id, v_item.article_id, v_item.quantity);
    v_n := v_n + 1;
  end loop;

  return jsonb_build_object('request_id', v_request_id, 'reference', v_ref, 'lines', v_n, 'status', 'sent');
end;
$function$;

-- ---------- Demandes : annuler / marquer commandée ----------
create or replace function public.jdvcrm_warehouse_update_supply_v1(p_request_id uuid, p_action text, p_notes text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  r public.warehouse_supply_requests%rowtype;
begin
  if v_uid is null then raise exception 'Authentification requise'; end if;
  select * into r from public.warehouse_supply_requests where id = p_request_id for update;
  if not found then raise exception 'Demande introuvable'; end if;
  if not private.can_manage_warehouse(r.warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;

  if p_action = 'cancel' then
    if r.status not in ('sent', 'approved', 'ordered') then raise exception 'Cette demande ne peut plus être annulée'; end if;
    update public.warehouse_supply_requests
       set status = 'cancelled', processed_by = v_uid, processed_at = now(),
           response_notes = coalesce(nullif(trim(p_notes), ''), response_notes)
     where id = r.id;
  elsif p_action = 'mark_ordered' then
    if r.target <> 'supplier' or r.status <> 'sent' then raise exception 'Seule une demande envoyée à un fournisseur peut être marquée commandée'; end if;
    update public.warehouse_supply_requests
       set status = 'ordered', processed_by = v_uid, processed_at = now(),
           response_notes = coalesce(nullif(trim(p_notes), ''), response_notes)
     where id = r.id;
  else
    raise exception 'Action inconnue';
  end if;
  return jsonb_build_object('request_id', r.id, 'action', p_action);
end;
$function$;

-- ---------- Demandes au fournisseur : réception de marchandise dans l'entrepôt ----------
create or replace function public.jdvcrm_warehouse_receive_supply_v1(p_request_id uuid, p_items jsonb default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  r public.warehouse_supply_requests%rowtype;
  v_label text;
  v_line record;
  v_item public.warehouse_supply_request_items%rowtype;
  v_qty numeric;
  v_total numeric := 0;
  v_open integer;
begin
  if v_uid is null then raise exception 'Authentification requise'; end if;
  select * into r from public.warehouse_supply_requests where id = p_request_id for update;
  if not found then raise exception 'Demande introuvable'; end if;
  if not private.can_manage_warehouse(r.warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;
  if not private.is_super_admin() and not private.org_subscription_active(r.organization_id) then raise exception 'Abonnement requis'; end if;
  if r.target <> 'supplier' then raise exception 'La réception directe concerne les demandes au fournisseur'; end if;
  if r.status not in ('sent', 'ordered', 'partially_received') then raise exception 'Cette demande ne peut pas recevoir de marchandise'; end if;
  v_label := private.jdvcrm_wh_label_v1(r.warehouse_id);

  for v_line in
    select x.article_id, x.quantity
    from jsonb_to_recordset(
      coalesce(p_items, (
        select coalesce(jsonb_agg(jsonb_build_object('article_id', i.article_id, 'quantity', i.quantity - i.received_quantity)), '[]'::jsonb)
        from public.warehouse_supply_request_items i
        where i.request_id = r.id and i.quantity - i.received_quantity > 0))
    ) as x(article_id uuid, quantity numeric)
  loop
    v_qty := v_line.quantity;
    if v_qty is null or v_qty <= 0 or v_qty <> trunc(v_qty) then raise exception 'Quantité reçue invalide'; end if;

    select * into v_item from public.warehouse_supply_request_items i
    where i.request_id = r.id and i.article_id = v_line.article_id and i.quantity - i.received_quantity >= v_qty
    order by i.created_at limit 1 for update;
    if not found then raise exception 'Quantité reçue supérieure au reste attendu pour un article'; end if;

    update public.warehouse_supply_request_items set received_quantity = received_quantity + v_qty where id = v_item.id;

    insert into public.warehouse_inventory(organization_id, warehouse_id, article_id, quantity, reserved_quantity,
      minimum_quantity, updated_at)
    values (r.organization_id, r.warehouse_id, v_line.article_id, v_qty, 0, 0, now())
    on conflict (warehouse_id, article_id)
    do update set quantity = public.warehouse_inventory.quantity + excluded.quantity, updated_at = now();

    insert into public.stock_movements(organization_id, article_id, movement_type, quantity, reference_type,
      reference_id, source_location, destination_location, notes, created_by)
    values (r.organization_id, v_line.article_id, 'entry', v_qty::integer, 'warehouse_supply_request',
      r.id, 'supplier', v_label, 'Réception de la demande ' || r.reference, v_uid);

    v_total := v_total + v_qty;
  end loop;

  select count(*) into v_open from public.warehouse_supply_request_items i
  where i.request_id = r.id and i.received_quantity < i.quantity;

  update public.warehouse_supply_requests
     set status = case when v_open = 0 then 'received' else 'partially_received' end,
         processed_by = v_uid, processed_at = now()
   where id = r.id;

  return jsonb_build_object('request_id', r.id, 'received_units', v_total,
                            'status', case when v_open = 0 then 'received' else 'partially_received' end);
end;
$function$;

-- ---------- Demandes à l'admin : décision (et approvisionnement depuis le stock central) ----------
create or replace function public.jdvcrm_respond_warehouse_supply_v1(p_request_id uuid, p_decision text, p_notes text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  r public.warehouse_supply_requests%rowtype;
  i record;
  v_min numeric;
  v_remaining numeric;
  v_name text;
begin
  if v_uid is null then raise exception 'Authentification requise'; end if;
  select * into r from public.warehouse_supply_requests where id = p_request_id for update;
  if not found then raise exception 'Demande introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(r.organization_id)) then
    raise exception 'Accès refusé : administrateur requis';
  end if;
  if r.target <> 'admin' then raise exception 'Cette demande est adressée à un fournisseur'; end if;
  if p_decision not in ('approved', 'rejected', 'fulfilled') then raise exception 'Décision invalide'; end if;
  if r.status not in ('sent', 'approved') then raise exception 'Cette demande a déjà été traitée'; end if;

  if p_decision = 'fulfilled' then
    begin
      for i in
        select it.id, it.article_id, it.quantity, it.received_quantity
        from public.warehouse_supply_request_items it
        where it.request_id = r.id and it.quantity - it.received_quantity > 0
        for update
      loop
        v_remaining := i.quantity - i.received_quantity;
        select coalesce(wi.minimum_quantity, 0) into v_min from public.warehouse_inventory wi
        where wi.warehouse_id = r.warehouse_id and wi.article_id = i.article_id;
        perform public.jdvcrm_admin_supply_warehouse_v1(r.organization_id, r.warehouse_id, i.article_id,
          v_remaining::integer, coalesce(v_min, 0)::integer, 'Demande ' || r.reference);
        update public.warehouse_supply_request_items set received_quantity = quantity where id = i.id;
      end loop;
    exception when others then
      raise exception 'Approvisionnement impossible : %', replace(sqlerrm, 'INSUFFICIENT_CENTRAL_STOCK', 'stock central insuffisant');
    end;
    update public.warehouse_supply_requests
       set status = 'received', processed_by = v_uid, processed_at = now(),
           response_notes = coalesce(nullif(trim(p_notes), ''), response_notes)
     where id = r.id;
  else
    update public.warehouse_supply_requests
       set status = p_decision, processed_by = v_uid, processed_at = now(),
           response_notes = coalesce(nullif(trim(p_notes), ''), response_notes)
     where id = r.id;
  end if;

  return jsonb_build_object('request_id', r.id, 'status', case when p_decision = 'fulfilled' then 'received' else p_decision end);
end;
$function$;

-- ---------- Tableau de fin de service ----------
create or replace function public.jdvcrm_warehouse_day_report_v1(p_warehouse_id uuid, p_date date default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  w public.warehouses%rowtype;
  v_label text;
  v_day date;
  v_from timestamptz;
  v_to timestamptz;
  v_entries jsonb;
  v_exits jsonb;
  v_sales jsonb;
  v_sales_total jsonb;
  v_customer_returns jsonb;
  v_stock jsonb;
  v_held jsonb;
  v_tickets jsonb;
  v_requests jsonb;
  v_closure jsonb;
begin
  if (select auth.uid()) is null then raise exception 'Authentification requise'; end if;
  select * into w from public.warehouses where id = p_warehouse_id;
  if not found then raise exception 'Entrepôt introuvable'; end if;
  if not private.can_manage_warehouse(p_warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;

  v_label := w.name || case when w.city is not null then ' - ' || w.city else '' end;
  v_day := coalesce(p_date, (now() at time zone 'Africa/Lagos')::date);
  v_from := v_day::timestamp at time zone 'Africa/Lagos';
  v_to := (v_day + 1)::timestamp at time zone 'Africa/Lagos';

  select coalesce(jsonb_agg(to_jsonb(x) order by x.article_name, x.origin), '[]'::jsonb) into v_entries from (
    select a.name as article_name,
      case when sm.source_location = 'supplier' then 'Fournisseur'
           when sm.source_location in ('stock_central', 'stock_principal') then 'Stock central (admin)'
           when sm.source_location = 'stock_prospecteur'
             then 'Retour prospecteur · ' || coalesce(nullif(concat_ws(' ', p.first_name, p.last_name), ''), 'inconnu')
           when sm.source_location = 'client' then 'Retour client'
           else 'Transfert · ' || coalesce(private.jdvcrm_loc_label_v1(sm.source_location, null), 'autre') end as origin,
      sum(sm.quantity)::numeric as quantity
    from public.stock_movements sm
    join public.articles a on a.id = sm.article_id
    left join public.prospecteurs p on p.id = sm.prospecteur_id
    where sm.organization_id = w.organization_id and sm.created_at >= v_from and sm.created_at < v_to
      and private.jdvcrm_loc_is_warehouse_v1(sm.destination_location, w.id, v_label)
    group by a.name, 2
  ) x;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.article_name, x.destination), '[]'::jsonb) into v_exits from (
    select a.name as article_name,
      case when sm.destination_location = 'stock_prospecteur'
             then 'Prospecteur · ' || coalesce(nullif(concat_ws(' ', p.first_name, p.last_name), ''), 'inconnu')
           else coalesce(private.jdvcrm_loc_label_v1(sm.destination_location, null), 'Autre') end as destination,
      sum(sm.quantity)::numeric as quantity
    from public.stock_movements sm
    join public.articles a on a.id = sm.article_id
    left join public.prospecteurs p on p.id = sm.prospecteur_id
    where sm.organization_id = w.organization_id and sm.created_at >= v_from and sm.created_at < v_to
      and private.jdvcrm_loc_is_warehouse_v1(sm.source_location, w.id, v_label)
    group by a.name, 2
  ) x;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.article_name), '[]'::jsonb) into v_sales from (
    select a.name as article_name, sum(s.quantity)::numeric as quantity, count(*) as sales_count,
           sum((case when s.sale_type = 'cash' then s.cash_price else s.credit_price end) * s.quantity)::numeric as amount
    from public.sales s join public.articles a on a.id = s.article_id
    where s.organization_id = w.organization_id and s.status <> 'cancelled'
      and s.sale_date::timestamptz >= v_from and s.sale_date::timestamptz < v_to
      and s.prospecteur_id in (select a2.prospecteur_id from public.prospecteur_warehouse_assignments a2
                               where a2.warehouse_id = w.id and a2.active = true and a2.is_primary = true)
    group by a.name
  ) x;

  select jsonb_build_object(
    'quantity', coalesce(sum((e ->> 'quantity')::numeric), 0),
    'amount', coalesce(sum((e ->> 'amount')::numeric), 0),
    'sales_count', coalesce(sum((e ->> 'sales_count')::numeric), 0))
  into v_sales_total from jsonb_array_elements(v_sales) e;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.article_name), '[]'::jsonb) into v_customer_returns from (
    select a.name as article_name, sum(sm.quantity)::numeric as quantity
    from public.stock_movements sm join public.articles a on a.id = sm.article_id
    where sm.organization_id = w.organization_id and sm.reference_type = 'sale_return'
      and sm.created_at >= v_from and sm.created_at < v_to
      and sm.prospecteur_id in (select a2.prospecteur_id from public.prospecteur_warehouse_assignments a2
                                where a2.warehouse_id = w.id and a2.active = true and a2.is_primary = true)
    group by a.name
  ) x;

  select coalesce(jsonb_agg(jsonb_build_object('article_name', a.name, 'quantity', wi.quantity,
           'minimum', wi.minimum_quantity,
           'is_low', (wi.minimum_quantity > 0 and wi.quantity <= wi.minimum_quantity)) order by a.name), '[]'::jsonb)
  into v_stock
  from public.warehouse_inventory wi join public.articles a on a.id = wi.article_id
  where wi.warehouse_id = w.id;

  select coalesce(jsonb_agg(to_jsonb(x) order by x.prospecteur_name, x.article_name), '[]'::jsonb) into v_held from (
    select coalesce(nullif(concat_ws(' ', p.first_name, p.last_name), ''), 'inconnu') as prospecteur_name,
           a.name as article_name, sum(h.remaining_quantity)::numeric as quantity
    from public.prospecteur_stock_holdings h
    join public.prospecteurs p on p.id = h.prospecteur_id
    join public.articles a on a.id = h.article_id
    where h.warehouse_id = w.id and h.remaining_quantity > 0 and h.status in ('active', 'overdue')
    group by 1, 2
  ) x;

  select jsonb_build_object(
    'opened', (select count(*) from public.warehouse_tickets t
               where t.warehouse_id = w.id and t.created_at >= v_from and t.created_at < v_to),
    'resolved', (select count(*) from public.warehouse_tickets t
                 where t.warehouse_id = w.id and t.resolved_at >= v_from and t.resolved_at < v_to),
    'still_open', (select count(*) from public.warehouse_tickets t
                   where t.warehouse_id = w.id and t.status in ('open', 'in_progress')),
    'open_list', coalesce((select jsonb_agg(jsonb_build_object('ticket_number', t.ticket_number, 'subject', t.subject,
                   'kind', t.kind, 'priority', t.priority, 'status', t.status) order by t.created_at desc)
                 from (select * from public.warehouse_tickets t2 where t2.warehouse_id = w.id
                         and t2.status in ('open', 'in_progress') order by t2.created_at desc limit 10) t), '[]'::jsonb))
  into v_tickets;

  select jsonb_build_object(
    'created_today', (select count(*) from public.warehouse_supply_requests r
                      where r.warehouse_id = w.id and r.requested_at >= v_from and r.requested_at < v_to),
    'pending', (select count(*) from public.warehouse_supply_requests r
                where r.warehouse_id = w.id and r.status in ('sent', 'approved', 'ordered', 'partially_received')))
  into v_requests;

  select to_jsonb(c) - 'snapshot' into v_closure
  from public.warehouse_day_closures c where c.warehouse_id = w.id and c.service_date = v_day;

  return jsonb_build_object(
    'service_date', v_day, 'generated_at', now(),
    'warehouse', jsonb_build_object('id', w.id, 'name', w.name, 'city', w.city),
    'entries', v_entries, 'exits', v_exits,
    'sales', v_sales, 'sales_total', v_sales_total, 'customer_returns', v_customer_returns,
    'stock', v_stock, 'held_by_prospecteurs', v_held,
    'tickets', v_tickets, 'supply_requests', v_requests,
    'closure', v_closure);
end;
$function$;

create or replace function public.jdvcrm_close_warehouse_day_v1(p_warehouse_id uuid, p_date date default null, p_notes text default null)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_org uuid;
  v_day date;
  v_report jsonb;
begin
  if v_uid is null then raise exception 'Authentification requise'; end if;
  select w.organization_id into v_org from public.warehouses w where w.id = p_warehouse_id;
  if v_org is null then raise exception 'Entrepôt introuvable'; end if;
  if not private.can_manage_warehouse(p_warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;
  if not private.is_super_admin() and not private.org_subscription_active(v_org) then raise exception 'Abonnement requis'; end if;

  v_day := coalesce(p_date, (now() at time zone 'Africa/Lagos')::date);
  if v_day > (now() at time zone 'Africa/Lagos')::date then raise exception 'Impossible de clôturer un jour futur'; end if;
  v_report := public.jdvcrm_warehouse_day_report_v1(p_warehouse_id, v_day);

  insert into public.warehouse_day_closures(organization_id, warehouse_id, service_date, closed_by, closed_at, notes, snapshot)
  values (v_org, p_warehouse_id, v_day, v_uid, now(), nullif(trim(p_notes), ''), v_report)
  on conflict (warehouse_id, service_date)
  do update set closed_by = excluded.closed_by, closed_at = now(), notes = excluded.notes, snapshot = excluded.snapshot;

  return jsonb_build_object('warehouse_id', p_warehouse_id, 'service_date', v_day, 'closed', true);
end;
$function$;

-- ---------- Traçabilité par produit ----------
create or replace function public.jdvcrm_warehouse_trace_v1(p_warehouse_id uuid, p_article_id uuid default null, p_days integer default 30)
returns table (occurred_at timestamptz, article_name text, movement_label text, quantity numeric,
               from_label text, to_label text, prospecteur_name text, reference_type text, notes text)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  w public.warehouses%rowtype;
  v_label text;
begin
  if (select auth.uid()) is null then raise exception 'Authentification requise'; end if;
  select * into w from public.warehouses where id = p_warehouse_id;
  if not found then raise exception 'Entrepôt introuvable'; end if;
  if not private.can_manage_warehouse(p_warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;
  v_label := w.name || case when w.city is not null then ' - ' || w.city else '' end;

  return query
  select sm.created_at, a.name,
    case sm.movement_type
      when 'entry' then 'Entrée' when 'exit' then 'Sortie'
      when 'transfer_to_prospecteur' then 'Approvisionnement prospecteur'
      when 'return_from_prospecteur' then 'Retour de marchandise'
      when 'sale' then 'Vente' when 'adjustment' then 'Ajustement' when 'loss' then 'Perte'
      when 'transfer_out' then 'Transfert sortant' when 'transfer_in' then 'Transfert entrant'
      else sm.movement_type end,
    sm.quantity::numeric,
    private.jdvcrm_loc_label_v1(sm.source_location, nullif(concat_ws(' ', p.first_name, p.last_name), '')),
    private.jdvcrm_loc_label_v1(sm.destination_location, nullif(concat_ws(' ', p.first_name, p.last_name), '')),
    nullif(concat_ws(' ', p.first_name, p.last_name), ''),
    sm.reference_type, sm.notes
  from public.stock_movements sm
  join public.articles a on a.id = sm.article_id
  left join public.prospecteurs p on p.id = sm.prospecteur_id
  where sm.organization_id = w.organization_id
    and sm.created_at >= now() - make_interval(days => greatest(1, least(coalesce(p_days, 30), 365)))
    and (p_article_id is null or sm.article_id = p_article_id)
    and (private.jdvcrm_loc_is_warehouse_v1(sm.source_location, w.id, v_label)
         or private.jdvcrm_loc_is_warehouse_v1(sm.destination_location, w.id, v_label)
         or sm.prospecteur_id in (select a2.prospecteur_id from public.prospecteur_warehouse_assignments a2
                                  where a2.warehouse_id = w.id and a2.active = true and a2.is_primary = true))
  order by sm.created_at desc
  limit 500;
end;
$function$;

-- ---------- Traçabilité par numéro de série ----------
create or replace function public.jdvcrm_warehouse_trace_serial_v1(p_warehouse_id uuid, p_serial text)
returns jsonb
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare
  v_org uuid;
  v_admin boolean;
  s record;
  v_related boolean;
  v_events jsonb;
begin
  if (select auth.uid()) is null then raise exception 'Authentification requise'; end if;
  select w.organization_id into v_org from public.warehouses w where w.id = p_warehouse_id;
  if v_org is null then raise exception 'Entrepôt introuvable'; end if;
  if not private.can_manage_warehouse(p_warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;
  v_admin := private.is_super_admin() or private.is_org_admin(v_org);

  select sn.id, sn.serial_number, sn.status, sn.sale_id, sn.created_at, a.name as article_name, sa.sale_number, sa.sale_date
    into s
  from public.serial_numbers sn
  join public.articles a on a.id = sn.article_id
  left join public.sales sa on sa.id = sn.sale_id
  where sn.organization_id = v_org and lower(sn.serial_number) = lower(trim(p_serial))
  limit 1;
  if not found then return jsonb_build_object('found', false); end if;

  v_related := exists (
    select 1 from public.article_serial_assignments asg
    where asg.serial_number_id = s.id
      and (asg.warehouse_id = p_warehouse_id
           or asg.prospecteur_id in (select a2.prospecteur_id from public.prospecteur_warehouse_assignments a2
                                     where a2.warehouse_id = p_warehouse_id and a2.active = true and a2.is_primary = true))
  );
  if not v_admin and not v_related then return jsonb_build_object('found', false); end if;

  select coalesce(jsonb_agg(jsonb_build_object('at', e.at, 'event', e.event, 'detail', e.detail) order by e.at), '[]'::jsonb)
  into v_events
  from (
    select s.created_at as at, 'Enregistré'::text as event, 'Numéro de série enregistré'::text as detail
    union all
    select asg.assigned_at, 'Affecté',
           'Prospecteur ' || coalesce(nullif(concat_ws(' ', p.first_name, p.last_name), ''), 'inconnu')
             || coalesce(' · entrepôt ' || private.jdvcrm_wh_label_v1(asg.warehouse_id), '')
    from public.article_serial_assignments asg left join public.prospecteurs p on p.id = asg.prospecteur_id
    where asg.serial_number_id = s.id and asg.assigned_at is not null
    union all
    select asg.released_at, 'Libéré',
           'Prospecteur ' || coalesce(nullif(concat_ws(' ', p.first_name, p.last_name), ''), 'inconnu')
    from public.article_serial_assignments asg left join public.prospecteurs p on p.id = asg.prospecteur_id
    where asg.serial_number_id = s.id and asg.released_at is not null
    union all
    select s.sale_date::timestamptz, 'Vendu', 'Vente ' || s.sale_number where s.sale_id is not null
    union all
    select sr.created_at, 'Retourné', 'Retour ' || sr.return_number || ' (' || sr.status || ')'
    from public.sales_return_items i join public.sales_returns sr on sr.id = i.return_id
    where i.serial_number_id = s.id
  ) e
  where e.at is not null;

  return jsonb_build_object('found', true, 'serial_number', s.serial_number, 'article_name', s.article_name,
                            'status', s.status, 'sale_number', s.sale_number, 'events', v_events);
end;
$function$;

-- ---------- Retours de vente : ouverts au responsable de l'entrepôt du prospecteur ----------
do $$
declare v_def text; v_new text;
begin
  select pg_get_functiondef(p.oid) into v_def from pg_proc p
  where p.pronamespace = 'public'::regnamespace and p.proname = 'jdvcrm_process_sale_return';
  v_new := replace(v_def,
    'if not (private.is_super_admin() or private.is_org_admin(r.organization_id)) then',
    'if not (private.is_super_admin() or private.is_org_admin(r.organization_id) or private.can_manage_sale_warehouse(r.sale_id)) then');
  if v_new = v_def then raise exception 'Garde de jdvcrm_process_sale_return introuvable'; end if;
  execute v_new;

  select pg_get_functiondef(p.oid) into v_def from pg_proc p
  where p.pronamespace = 'public'::regnamespace and p.proname = 'jdvcrm_create_sale_return_v1';
  v_new := replace(v_def,
    'if not (private.is_super_admin() or private.is_org_admin(v_sale.organization_id)) then',
    'if not (private.is_super_admin() or private.is_org_admin(v_sale.organization_id) or private.can_manage_sale_warehouse(v_sale.id)) then');
  v_new := replace(v_new,
    'if not private.is_super_admin() and not private.has_active_subscription(v_sale.organization_id) then',
    'if not private.is_super_admin() and not private.org_subscription_active(v_sale.organization_id) then');
  if v_new = v_def then raise exception 'Gardes de jdvcrm_create_sale_return_v1 introuvables'; end if;
  execute v_new;
end $$;

-- ---------- Droits d'exécution ----------
do $$
declare f text;
begin
  foreach f in array array[
    'public.jdvcrm_warehouse_request_supply_v1(uuid, text, uuid, jsonb, text)',
    'public.jdvcrm_warehouse_update_supply_v1(uuid, text, text)',
    'public.jdvcrm_warehouse_receive_supply_v1(uuid, jsonb)',
    'public.jdvcrm_respond_warehouse_supply_v1(uuid, text, text)',
    'public.jdvcrm_warehouse_day_report_v1(uuid, date)',
    'public.jdvcrm_close_warehouse_day_v1(uuid, date, text)',
    'public.jdvcrm_warehouse_trace_v1(uuid, uuid, integer)',
    'public.jdvcrm_warehouse_trace_serial_v1(uuid, text)'
  ] loop
    execute format('revoke all on function %s from public, anon', f);
    execute format('grant execute on function %s to authenticated', f);
  end loop;
end $$;