-- =====================================================================
-- JDV CRM - Journal détaillé du stock + inventaire + clôture journalière
-- Complément au système de stock existant. Aucun stock parallèle n'est créé.
-- =====================================================================

alter table public.stock_movements
  add column if not exists unit_price numeric;

create index if not exists idx_stock_movements_article_created
  on public.stock_movements (organization_id, article_id, created_at);

create index if not exists idx_stock_movements_locations_created
  on public.stock_movements (source_location, destination_location, created_at);

create or replace function public.jdvcrm_stock_movement_price_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
begin
  if new.unit_price is null then
    select coalesce(a.fixed_price, a.cash_price, a.credit_price, 0)
      into new.unit_price
      from public.articles a
     where a.id = new.article_id;
  end if;
  return new;
end;
$function$;

revoke all on function public.jdvcrm_stock_movement_price_v1() from public, anon, authenticated;

drop trigger if exists trg_jdvcrm_stock_movement_price_v1 on public.stock_movements;
create trigger trg_jdvcrm_stock_movement_price_v1
before insert on public.stock_movements
for each row execute function public.jdvcrm_stock_movement_price_v1();

-- Une clôture = une journée d'exploitation pour un entrepôt.
create table if not exists public.warehouse_stock_daily_closures (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete restrict,
  exercise_date date not null,
  status text not null default 'open' check (status in ('open','closed','reopened')),
  opened_at timestamptz not null default now(),
  closed_at timestamptz,
  closed_by uuid references auth.users(id) on delete set null,
  reopened_at timestamptz,
  reopened_by uuid references auth.users(id) on delete set null,
  opening_units numeric not null default 0,
  total_entries numeric not null default 0,
  total_exits numeric not null default 0,
  closing_units numeric not null default 0,
  theoretical_value numeric not null default 0,
  physical_value numeric,
  variance_units numeric,
  variance_value numeric,
  movement_count integer not null default 0,
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (warehouse_id, exercise_date)
);

create table if not exists public.warehouse_stock_daily_closure_lines (
  id uuid primary key default gen_random_uuid(),
  closure_id uuid not null references public.warehouse_stock_daily_closures(id) on delete cascade,
  organization_id uuid not null references public.organizations(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete restrict,
  article_id uuid not null references public.articles(id) on delete restrict,
  opening_quantity numeric not null default 0,
  entry_quantity numeric not null default 0,
  exit_quantity numeric not null default 0,
  closing_quantity numeric not null default 0,
  unit_price numeric not null default 0,
  theoretical_value numeric not null default 0,
  physical_quantity numeric,
  variance_quantity numeric,
  variance_value numeric,
  movement_count integer not null default 0,
  created_at timestamptz not null default now(),
  unique (closure_id, article_id)
);

create index if not exists idx_stock_daily_closures_org_date
  on public.warehouse_stock_daily_closures (organization_id, exercise_date desc);

create index if not exists idx_stock_daily_closures_warehouse_date
  on public.warehouse_stock_daily_closures (warehouse_id, exercise_date desc);

create index if not exists idx_stock_daily_closure_lines_closure
  on public.warehouse_stock_daily_closure_lines (closure_id);

create index if not exists idx_stock_daily_closure_lines_article
  on public.warehouse_stock_daily_closure_lines (warehouse_id, article_id);

alter table public.warehouse_stock_daily_closures enable row level security;
alter table public.warehouse_stock_daily_closure_lines enable row level security;

revoke all on public.warehouse_stock_daily_closures from public, anon;
revoke all on public.warehouse_stock_daily_closure_lines from public, anon;
grant select on public.warehouse_stock_daily_closures to authenticated;
grant select on public.warehouse_stock_daily_closure_lines to authenticated;
grant all on public.warehouse_stock_daily_closures, public.warehouse_stock_daily_closure_lines to service_role;

drop policy if exists warehouse_stock_daily_closures_select on public.warehouse_stock_daily_closures;
create policy warehouse_stock_daily_closures_select
on public.warehouse_stock_daily_closures
for select to authenticated
using ((select private.can_manage_warehouse(warehouse_id)));

drop policy if exists warehouse_stock_daily_closure_lines_select on public.warehouse_stock_daily_closure_lines;
create policy warehouse_stock_daily_closure_lines_select
on public.warehouse_stock_daily_closure_lines
for select to authenticated
using ((select private.can_manage_warehouse(warehouse_id)));

-- Ledger détaillé : une ligne par impact sur l'entrepôt.
-- Le stock avant/après est reconstruit à partir du stock courant et de l'historique.
create or replace view public.jdvcrm_warehouse_stock_ledger_v1
with (security_invoker = true)
as
with impacts as (
  select
    sm.id as movement_id,
    sm.organization_id,
    replace(sm.source_location, 'warehouse:', '')::uuid as warehouse_id,
    sm.article_id,
    sm.created_at as occurred_at,
    sm.movement_type,
    sm.reference_type,
    sm.reference_id,
    sm.quantity::numeric as quantity,
    0::numeric as entry_quantity,
    sm.quantity::numeric as exit_quantity,
    coalesce(sm.unit_price, a.fixed_price, a.cash_price, a.credit_price, 0)::numeric as unit_price,
    sm.created_by,
    sm.notes
  from public.stock_movements sm
  join public.articles a on a.id = sm.article_id
  where sm.source_location ~* '^(warehouse:)?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'

  union all

  select
    sm.id as movement_id,
    sm.organization_id,
    replace(sm.destination_location, 'warehouse:', '')::uuid as warehouse_id,
    sm.article_id,
    sm.created_at as occurred_at,
    sm.movement_type,
    sm.reference_type,
    sm.reference_id,
    sm.quantity::numeric as quantity,
    sm.quantity::numeric as entry_quantity,
    0::numeric as exit_quantity,
    coalesce(sm.unit_price, a.fixed_price, a.cash_price, a.credit_price, 0)::numeric as unit_price,
    sm.created_by,
    sm.notes
  from public.stock_movements sm
  join public.articles a on a.id = sm.article_id
  where sm.destination_location ~* '^(warehouse:)?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
),
current_stock as (
  select wi.organization_id, wi.warehouse_id, wi.article_id, wi.quantity::numeric as current_quantity
  from public.warehouse_inventory wi
),
totals as (
  select i.warehouse_id, i.article_id, sum(i.entry_quantity - i.exit_quantity) as all_time_delta
  from impacts i
  group by i.warehouse_id, i.article_id
),
base as (
  select
    cs.organization_id,
    cs.warehouse_id,
    cs.article_id,
    greatest(cs.current_quantity - coalesce(t.all_time_delta,0),0) as opening_quantity
  from current_stock cs
  left join totals t on t.warehouse_id = cs.warehouse_id and t.article_id = cs.article_id
),
ordered as (
  select
    i.*,
    b.opening_quantity,
    row_number() over (
      partition by i.warehouse_id, i.article_id
      order by i.occurred_at, i.movement_id
    ) as rn
  from impacts i
  join base b on b.warehouse_id = i.warehouse_id and b.article_id = i.article_id
)
select
  o.movement_id,
  o.organization_id,
  o.warehouse_id,
  w.name as warehouse_name,
  w.code as warehouse_code,
  o.article_id,
  a.code as article_code,
  a.name as article_name,
  o.occurred_at,
  o.movement_type,
  o.reference_type,
  o.reference_id,
  case when o.entry_quantity > 0 then 'Entrée' else 'Sortie' end as movement_label,
  case when o.entry_quantity > 0 then o.entry_quantity else 0 end as entry_quantity,
  case when o.exit_quantity > 0 then o.exit_quantity else 0 end as exit_quantity,
  (
    o.opening_quantity
    + coalesce(sum(o.entry_quantity - o.exit_quantity) over (
      partition by o.warehouse_id, o.article_id
      order by o.occurred_at, o.movement_id
      rows between unbounded preceding and 1 preceding
    ),0)
  ) as stock_before,
  (
    o.opening_quantity
    + sum(o.entry_quantity - o.exit_quantity) over (
      partition by o.warehouse_id, o.article_id
      order by o.occurred_at, o.movement_id
      rows unbounded preceding
    )
  ) as stock_after,
  o.unit_price,
  (case when o.entry_quantity > 0 then o.entry_quantity else o.exit_quantity end) * o.unit_price as movement_amount,
  (
    o.opening_quantity
    + sum(o.entry_quantity - o.exit_quantity) over (
      partition by o.warehouse_id, o.article_id
      order by o.occurred_at, o.movement_id
      rows unbounded preceding
    )
  ) * o.unit_price as stock_value_after,
  o.created_by,
  o.notes
from ordered o
join public.warehouses w on w.id = o.warehouse_id
join public.articles a on a.id = o.article_id;

revoke all on public.jdvcrm_warehouse_stock_ledger_v1 from anon;
grant select on public.jdvcrm_warehouse_stock_ledger_v1 to authenticated;

-- Synthèse automatique d'une journée.
create or replace function public.jdvcrm_warehouse_daily_summary_v1(
  p_warehouse_id uuid,
  p_exercise_date date default (now() at time zone 'Africa/Porto-Novo')::date
)
returns table (
  warehouse_id uuid,
  exercise_date date,
  opening_units numeric,
  total_entries numeric,
  total_exits numeric,
  closing_units numeric,
  theoretical_value numeric,
  movement_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $function$
begin
  if (select auth.uid()) is null then raise exception 'Authentification requise'; end if;
  if not private.can_manage_warehouse(p_warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;

  return query
  with current_totals as (
    select coalesce(sum(wi.quantity),0)::numeric units,
           coalesce(sum(wi.quantity * coalesce(a.fixed_price,a.cash_price,a.credit_price,0)),0)::numeric value
    from public.warehouse_inventory wi
    join public.articles a on a.id = wi.article_id
    where wi.warehouse_id = p_warehouse_id
  ),
  day as (
    select
      coalesce(sum(l.entry_quantity),0)::numeric entries,
      coalesce(sum(l.exit_quantity),0)::numeric exits,
      count(distinct l.movement_id)::bigint movements
    from public.jdvcrm_warehouse_stock_ledger_v1 l
    where l.warehouse_id = p_warehouse_id
      and (l.occurred_at at time zone 'Africa/Porto-Novo')::date = p_exercise_date
  )
  select
    p_warehouse_id,
    p_exercise_date,
    (c.units - d.entries + d.exits)::numeric,
    d.entries,
    d.exits,
    c.units,
    c.value,
    d.movements
  from current_totals c cross join day d;
end;
$function$;

revoke all on function public.jdvcrm_warehouse_daily_summary_v1(uuid,date) from public, anon;
grant execute on function public.jdvcrm_warehouse_daily_summary_v1(uuid,date) to authenticated;

-- Clôture transactionnelle avec inventaire physique facultatif.
create or replace function public.jdvcrm_warehouse_close_day_v1(
  p_warehouse_id uuid,
  p_exercise_date date default (now() at time zone 'Africa/Porto-Novo')::date,
  p_physical_counts jsonb default '[]'::jsonb,
  p_notes text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_uid uuid := (select auth.uid());
  v_org uuid;
  v_closure_id uuid;
  v_summary record;
  v_item record;
  v_physical numeric;
  v_line record;
  v_physical_total numeric := 0;
  v_variance_units numeric := 0;
  v_variance_value numeric := 0;
begin
  if v_uid is null then raise exception 'Authentification requise'; end if;
  if not private.can_manage_warehouse(p_warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;

  select w.organization_id into v_org
  from public.warehouses w
  where w.id = p_warehouse_id and w.active = true;

  if v_org is null then raise exception 'Entrepôt introuvable ou inactif'; end if;

  select * into v_summary
  from public.jdvcrm_warehouse_daily_summary_v1(p_warehouse_id, p_exercise_date);

  select id into v_closure_id
  from public.warehouse_stock_daily_closures
  where warehouse_id = p_warehouse_id and exercise_date = p_exercise_date
  for update;

  if v_closure_id is not null then
    if exists (
      select 1 from public.warehouse_stock_daily_closures
      where id = v_closure_id and status = 'closed'
    ) then
      raise exception 'Cette journée est déjà clôturée';
    end if;
  else
    insert into public.warehouse_stock_daily_closures (
      organization_id, warehouse_id, exercise_date, status
    ) values (
      v_org, p_warehouse_id, p_exercise_date, 'open'
    )
    returning id into v_closure_id;
  end if;

  delete from public.warehouse_stock_daily_closure_lines where closure_id = v_closure_id;

  for v_line in
    select
      l.article_id,
      max(l.article_code) article_code,
      max(l.article_name) article_name,
      min(l.stock_before) opening_quantity,
      coalesce(sum(l.entry_quantity),0) entry_quantity,
      coalesce(sum(l.exit_quantity),0) exit_quantity,
      max(l.stock_after) closing_quantity,
      max(l.unit_price) unit_price,
      max(l.stock_value_after) stock_value_after,
      count(*)::integer movement_count
    from public.jdvcrm_warehouse_stock_ledger_v1 l
    where l.warehouse_id = p_warehouse_id
      and (l.occurred_at at time zone 'Africa/Porto-Novo')::date = p_exercise_date
    group by l.article_id
  loop
    v_physical := null;
    if jsonb_typeof(p_physical_counts) = 'array' then
      select (x.physical_quantity)::numeric into v_physical
      from jsonb_to_recordset(p_physical_counts) as x(article_id uuid, physical_quantity numeric)
      where x.article_id = v_line.article_id
      limit 1;
    end if;

    insert into public.warehouse_stock_daily_closure_lines (
      closure_id, organization_id, warehouse_id, article_id,
      opening_quantity, entry_quantity, exit_quantity, closing_quantity,
      unit_price, theoretical_value, physical_quantity,
      variance_quantity, variance_value, movement_count
    ) values (
      v_closure_id, v_org, p_warehouse_id, v_line.article_id,
      v_line.opening_quantity, v_line.entry_quantity, v_line.exit_quantity,
      v_line.closing_quantity, coalesce(v_line.unit_price,0),
      v_line.closing_quantity * coalesce(v_line.unit_price,0),
      v_physical,
      case when v_physical is null then null else v_physical - v_line.closing_quantity end,
      case when v_physical is null then null else (v_physical - v_line.closing_quantity) * coalesce(v_line.unit_price,0) end,
      v_line.movement_count
    );

    if v_physical is not null then
      v_physical_total := v_physical_total + v_physical * coalesce(v_line.unit_price,0);
      v_variance_units := v_variance_units + (v_physical - v_line.closing_quantity);
      v_variance_value := v_variance_value + (v_physical - v_line.closing_quantity) * coalesce(v_line.unit_price,0);
    end if;
  end loop;

  update public.warehouse_stock_daily_closures
  set status = 'closed',
      closed_at = now(),
      closed_by = v_uid,
      opening_units = v_summary.opening_units,
      total_entries = v_summary.total_entries,
      total_exits = v_summary.total_exits,
      closing_units = v_summary.closing_units,
      theoretical_value = v_summary.theoretical_value,
      physical_value = case when jsonb_array_length(coalesce(p_physical_counts,'[]'::jsonb)) > 0 then v_physical_total else null end,
      variance_units = case when jsonb_array_length(coalesce(p_physical_counts,'[]'::jsonb)) > 0 then v_variance_units else null end,
      variance_value = case when jsonb_array_length(coalesce(p_physical_counts,'[]'::jsonb)) > 0 then v_variance_value else null end,
      movement_count = v_summary.movement_count::integer,
      notes = nullif(trim(p_notes),''),
      updated_at = now()
  where id = v_closure_id;

  return jsonb_build_object(
    'closure_id', v_closure_id,
    'warehouse_id', p_warehouse_id,
    'exercise_date', p_exercise_date,
    'status', 'closed',
    'opening_units', v_summary.opening_units,
    'entries', v_summary.total_entries,
    'exits', v_summary.total_exits,
    'closing_units', v_summary.closing_units,
    'theoretical_value', v_summary.theoretical_value,
    'physical_value', case when jsonb_array_length(coalesce(p_physical_counts,'[]'::jsonb)) > 0 then v_physical_total else null end,
    'variance_units', case when jsonb_array_length(coalesce(p_physical_counts,'[]'::jsonb)) > 0 then v_variance_units else null end,
    'variance_value', case when jsonb_array_length(coalesce(p_physical_counts,'[]'::jsonb)) > 0 then v_variance_value else null end,
    'movement_count', v_summary.movement_count
  );
end;
$function$;

revoke all on function public.jdvcrm_warehouse_close_day_v1(uuid,date,jsonb,text) from public, anon;
grant execute on function public.jdvcrm_warehouse_close_day_v1(uuid,date,jsonb,text) to authenticated;

-- Empêche les mouvements directs après clôture pour les emplacements d'entrepôt.
create or replace function public.jdvcrm_block_closed_warehouse_movement_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_date date := (coalesce(new.created_at, now()) at time zone 'Africa/Porto-Novo')::date;
  v_wh uuid;
begin
  for v_wh in
    select distinct replace(x.loc, 'warehouse:', '')::uuid
    from (values (new.source_location),(new.destination_location)) as x(loc)
    where x.loc ~* '^(warehouse:)?[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
  loop
    if exists (
      select 1 from public.warehouse_stock_daily_closures c
      where c.warehouse_id = v_wh
        and c.exercise_date = v_date
        and c.status = 'closed'
    ) then
      raise exception 'La journée de stock du % est clôturée pour cet entrepôt', v_date;
    end if;
  end loop;
  return new;
end;
$function$;

revoke all on function public.jdvcrm_block_closed_warehouse_movement_v1() from public, anon, authenticated;

drop trigger if exists trg_jdvcrm_block_closed_warehouse_movement_v1 on public.stock_movements;
create trigger trg_jdvcrm_block_closed_warehouse_movement_v1
before insert on public.stock_movements
for each row execute function public.jdvcrm_block_closed_warehouse_movement_v1();

-- Permissions fonctionnelles.
insert into public.permissions (code,name,description,module)
values
 ('stock.journal.view','Voir le journal détaillé du stock','Consulter les mouvements avec stock avant/après et valorisation','stock'),
 ('stock.inventory.daily','Faire l''inventaire journalier','Saisir et contrôler le stock physique journalier','stock'),
 ('stock.daily_closure.view','Voir les clôtures journalières','Consulter les exercices et clôtures de stock','stock'),
 ('stock.daily_closure.close','Clôturer la journée de stock','Calculer et verrouiller la journée d''exploitation','stock')
on conflict (code) do update set name=excluded.name,description=excluded.description,module=excluded.module;

insert into public.role_permissions(role,permission_id)
select r.role,p.id
from (values ('business_admin'),('manager')) r(role)
join public.permissions p on p.code in (
 'stock.journal.view','stock.inventory.daily','stock.daily_closure.view','stock.daily_closure.close'
)
on conflict (role,permission_id) do nothing;

insert into public.role_permissions(role,permission_id)
select 'supervisor',p.id
from public.permissions p
where p.code in ('stock.journal.view','stock.inventory.daily','stock.daily_closure.view')
on conflict (role,permission_id) do nothing;
