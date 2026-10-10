-- JDV CRM core: sub-entrepots et transferts de stock.
-- Additive migration: preserves existing warehouse_inventory rows and its current uniqueness constraint.
-- Apply after verifying the target project is lncgghdbnkehdcyhqdfo.

create table if not exists public.warehouse_managers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text,
  phone text,
  status text not null default 'active' check (status in ('active', 'suspended')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (warehouse_id, user_id)
);
create index if not exists idx_warehouse_managers_org on public.warehouse_managers(organization_id);
create index if not exists idx_warehouse_managers_user_active on public.warehouse_managers(user_id) where status='active';

create table if not exists public.warehouse_subwarehouses (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  parent_warehouse_id uuid not null references public.warehouses(id) on delete restrict,
  code text not null,
  name text not null,
  address text,
  city text,
  zone text,
  manager_user_id uuid references auth.users(id) on delete set null,
  active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint warehouse_subwarehouses_code_not_blank check (length(trim(code)) >= 2),
  constraint warehouse_subwarehouses_name_not_blank check (length(trim(name)) >= 2),
  unique (organization_id, code)
);
create index if not exists idx_subwarehouses_org on public.warehouse_subwarehouses(organization_id);
create index if not exists idx_subwarehouses_parent on public.warehouse_subwarehouses(parent_warehouse_id);
create index if not exists idx_subwarehouses_active_parent on public.warehouse_subwarehouses(parent_warehouse_id, active);

create table if not exists public.warehouse_subwarehouse_inventory (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete restrict,
  subwarehouse_id uuid not null references public.warehouse_subwarehouses(id) on delete restrict,
  article_id uuid not null references public.articles(id) on delete restrict,
  quantity numeric not null default 0 check (quantity >= 0),
  reserved_quantity numeric not null default 0 check (reserved_quantity >= 0),
  minimum_quantity numeric not null default 0 check (minimum_quantity >= 0),
  updated_at timestamptz not null default now(),
  unique (subwarehouse_id, article_id)
);
create index if not exists idx_subwarehouse_inventory_org on public.warehouse_subwarehouse_inventory(organization_id);
create index if not exists idx_subwarehouse_inventory_parent on public.warehouse_subwarehouse_inventory(warehouse_id, article_id);

create or replace function public.jdvcrm_subwarehouse_guard_v1()
returns trigger language plpgsql security definer set search_path=''
as $$
declare v_org uuid;
begin
  select w.organization_id into v_org
  from public.warehouses w
  where w.id=new.parent_warehouse_id and w.active=true;
  if v_org is null then raise exception 'Entrepôt parent introuvable ou inactif'; end if;
  new.organization_id:=v_org;
  new.code:=upper(trim(new.code));
  new.name:=trim(new.name);
  new.address:=nullif(trim(new.address),'');
  new.city:=nullif(trim(new.city),'');
  new.zone:=nullif(trim(new.zone),'');
  new.updated_at:=now();
  if new.manager_user_id is not null and not (
    public.is_super_admin()
    or public.is_org_admin(v_org)
    or exists (
      select 1 from public.warehouse_managers wm
      where wm.warehouse_id=new.parent_warehouse_id
        and wm.user_id=new.manager_user_id and wm.status='active'
    )
  ) then
    raise exception 'Le responsable doit être un administrateur ou un responsable actif de l''entrepôt parent';
  end if;
  return new;
end $$;
revoke all on function public.jdvcrm_subwarehouse_guard_v1() from public, anon, authenticated;
drop trigger if exists trg_warehouse_subwarehouses_guard on public.warehouse_subwarehouses;
create trigger trg_warehouse_subwarehouses_guard
before insert or update on public.warehouse_subwarehouses
for each row execute function public.jdvcrm_subwarehouse_guard_v1();

create or replace function public.jdvcrm_subwarehouse_inventory_guard_v1()
returns trigger language plpgsql security definer set search_path=''
as $$
declare v_org uuid; v_parent uuid; v_article_org uuid;
begin
  select organization_id,parent_warehouse_id into v_org,v_parent
  from public.warehouse_subwarehouses where id=new.subwarehouse_id and active=true;
  if v_org is null then raise exception 'Sous-entrepôt introuvable ou inactif'; end if;
  if new.organization_id<>v_org or new.warehouse_id<>v_parent then
    raise exception 'Le sous-entrepôt ne correspond pas à l''organisation ou à l''entrepôt parent';
  end if;
  select organization_id into v_article_org from public.articles where id=new.article_id and active=true;
  if v_article_org is distinct from v_org then raise exception 'Article incompatible avec l''organisation'; end if;
  if new.reserved_quantity>new.quantity then raise exception 'Le stock réservé dépasse le stock disponible'; end if;
  new.updated_at:=now();
  return new;
end $$;
revoke all on function public.jdvcrm_subwarehouse_inventory_guard_v1() from public, anon, authenticated;
drop trigger if exists trg_jdvcrm_subwarehouse_inventory_guard on public.warehouse_subwarehouse_inventory;
create trigger trg_jdvcrm_subwarehouse_inventory_guard
before insert or update on public.warehouse_subwarehouse_inventory
for each row execute function public.jdvcrm_subwarehouse_inventory_guard_v1();

alter table public.warehouse_managers enable row level security;
alter table public.warehouse_subwarehouses enable row level security;
alter table public.warehouse_subwarehouse_inventory enable row level security;

drop policy if exists warehouse_managers_select on public.warehouse_managers;
create policy warehouse_managers_select on public.warehouse_managers for select to authenticated
using (public.is_super_admin() or public.is_org_admin(organization_id) or user_id=auth.uid());
drop policy if exists warehouse_managers_admin_write on public.warehouse_managers;
create policy warehouse_managers_admin_write on public.warehouse_managers for all to authenticated
using (public.is_super_admin() or public.is_org_admin(organization_id))
with check (public.is_super_admin() or public.is_org_admin(organization_id));

drop policy if exists warehouse_subwarehouses_select on public.warehouse_subwarehouses;
create policy warehouse_subwarehouses_select on public.warehouse_subwarehouses for select to authenticated
using (
  public.is_super_admin() or public.is_org_admin(organization_id)
  or exists (select 1 from public.warehouse_managers wm
    where wm.warehouse_id=parent_warehouse_id and wm.user_id=auth.uid() and wm.status='active')
);
drop policy if exists warehouse_subwarehouses_admin_insert on public.warehouse_subwarehouses;
create policy warehouse_subwarehouses_admin_insert on public.warehouse_subwarehouses for insert to authenticated
with check (public.is_super_admin() or public.is_org_admin(organization_id));
drop policy if exists warehouse_subwarehouses_admin_update on public.warehouse_subwarehouses;
create policy warehouse_subwarehouses_admin_update on public.warehouse_subwarehouses for update to authenticated
using (public.is_super_admin() or public.is_org_admin(organization_id))
with check (public.is_super_admin() or public.is_org_admin(organization_id));

drop policy if exists subwarehouse_inventory_select on public.warehouse_subwarehouse_inventory;
create policy subwarehouse_inventory_select on public.warehouse_subwarehouse_inventory for select to authenticated
using (
  public.is_super_admin() or public.is_org_admin(organization_id)
  or exists (select 1 from public.warehouse_managers wm
    where wm.warehouse_id=warehouse_subwarehouse_inventory.warehouse_id
      and wm.user_id=auth.uid() and wm.status='active')
);
drop policy if exists subwarehouse_inventory_admin_write on public.warehouse_subwarehouse_inventory;
create policy subwarehouse_inventory_admin_write on public.warehouse_subwarehouse_inventory for all to authenticated
using (public.is_super_admin() or public.is_org_admin(organization_id))
with check (public.is_super_admin() or public.is_org_admin(organization_id));

revoke all on public.warehouse_managers, public.warehouse_subwarehouses, public.warehouse_subwarehouse_inventory from public, anon;
grant select, insert, update on public.warehouse_managers, public.warehouse_subwarehouses, public.warehouse_subwarehouse_inventory to authenticated;
grant all on public.warehouse_managers, public.warehouse_subwarehouses, public.warehouse_subwarehouse_inventory to service_role;

alter table public.stock_movements
  add column if not exists source_subwarehouse_id uuid references public.warehouse_subwarehouses(id) on delete restrict,
  add column if not exists destination_subwarehouse_id uuid references public.warehouse_subwarehouses(id) on delete restrict;

create or replace view public.jdvcrm_subwarehouse_stock_v1
with (security_invoker=true) as
select wi.id inventory_id, wi.organization_id, wi.warehouse_id, w.name warehouse_name, w.code warehouse_code,
       null::uuid subwarehouse_id, null::text subwarehouse_name, null::text subwarehouse_code,
       wi.article_id, a.code article_code, a.name article_name, wi.quantity, wi.reserved_quantity,
       wi.minimum_quantity, wi.updated_at
from public.warehouse_inventory wi
join public.warehouses w on w.id=wi.warehouse_id
join public.articles a on a.id=wi.article_id
union all
select swi.id, swi.organization_id, swi.warehouse_id, w.name, w.code,
       swi.subwarehouse_id, sw.name, sw.code, swi.article_id, a.code, a.name,
       swi.quantity, swi.reserved_quantity, swi.minimum_quantity, swi.updated_at
from public.warehouse_subwarehouse_inventory swi
join public.warehouses w on w.id=swi.warehouse_id
join public.warehouse_subwarehouses sw on sw.id=swi.subwarehouse_id
join public.articles a on a.id=swi.article_id;
revoke all on public.jdvcrm_subwarehouse_stock_v1 from anon;
grant select on public.jdvcrm_subwarehouse_stock_v1 to authenticated;

create or replace function public.jdvcrm_transfer_stock_location_v1(
  p_article_id uuid,
  p_quantity numeric,
  p_source_warehouse_id uuid,
  p_source_subwarehouse_id uuid default null,
  p_destination_warehouse_id uuid default null,
  p_destination_subwarehouse_id uuid default null,
  p_notes text default null
)
returns uuid language plpgsql security definer set search_path=''
as $$
declare
  v_uid uuid:=auth.uid();
  v_org uuid;
  v_dst_org uuid;
  v_source_qty numeric;
  v_source_reserved numeric;
  v_ref uuid:=gen_random_uuid();
  v_source text;
  v_dest text;
begin
  if v_uid is null then raise exception 'Authentification requise'; end if;
  if p_quantity is null or p_quantity<=0 or p_quantity<>trunc(p_quantity) then
    raise exception 'La quantité doit être un entier positif';
  end if;
  if p_destination_warehouse_id is null then p_destination_warehouse_id:=p_source_warehouse_id; end if;
  if not (public.is_super_admin() or public.is_org_admin((select organization_id from public.warehouses where id=p_source_warehouse_id))) then
    if not exists(select 1 from public.warehouse_managers wm where wm.warehouse_id=p_source_warehouse_id and wm.user_id=v_uid and wm.status='active') then
      raise exception 'Accès refusé à l''entrepôt source';
    end if;
  end if;
  if not (public.is_super_admin() or public.is_org_admin((select organization_id from public.warehouses where id=p_destination_warehouse_id))) then
    if not exists(select 1 from public.warehouse_managers wm where wm.warehouse_id=p_destination_warehouse_id and wm.user_id=v_uid and wm.status='active') then
      raise exception 'Accès refusé à l''entrepôt destination';
    end if;
  end if;
  select organization_id into v_org from public.warehouses where id=p_source_warehouse_id and active=true;
  select organization_id into v_dst_org from public.warehouses where id=p_destination_warehouse_id and active=true;
  if v_org is null or v_dst_org is null or v_org<>v_dst_org then raise exception 'Entrepôt source ou destination invalide'; end if;
  if not exists(select 1 from public.articles where id=p_article_id and organization_id=v_org and active=true) then
    raise exception 'Article invalide pour cette organisation';
  end if;
  if p_source_subwarehouse_id is not null and not exists(select 1 from public.warehouse_subwarehouses where id=p_source_subwarehouse_id and parent_warehouse_id=p_source_warehouse_id and organization_id=v_org and active=true) then
    raise exception 'Sous-entrepôt source invalide';
  end if;
  if p_destination_subwarehouse_id is not null and not exists(select 1 from public.warehouse_subwarehouses where id=p_destination_subwarehouse_id and parent_warehouse_id=p_destination_warehouse_id and organization_id=v_org and active=true) then
    raise exception 'Sous-entrepôt destination invalide';
  end if;
  if p_source_warehouse_id=p_destination_warehouse_id and p_source_subwarehouse_id is not distinct from p_destination_subwarehouse_id then
    raise exception 'La source et la destination doivent être différentes';
  end if;

  perform pg_advisory_xact_lock(hashtextextended(
    p_article_id::text||':'||coalesce(p_source_subwarehouse_id::text,'central:'||p_source_warehouse_id::text)||':'||
    coalesce(p_destination_subwarehouse_id::text,'central:'||p_destination_warehouse_id::text),0));

  if p_source_subwarehouse_id is null then
    select quantity,reserved_quantity into v_source_qty,v_source_reserved
    from public.warehouse_inventory where warehouse_id=p_source_warehouse_id and article_id=p_article_id for update;
    if not found or v_source_qty-v_source_reserved<p_quantity then raise exception 'Stock central insuffisant'; end if;
    update public.warehouse_inventory set quantity=quantity-p_quantity,updated_at=now()
    where warehouse_id=p_source_warehouse_id and article_id=p_article_id;
  else
    select quantity,reserved_quantity into v_source_qty,v_source_reserved
    from public.warehouse_subwarehouse_inventory where subwarehouse_id=p_source_subwarehouse_id and article_id=p_article_id for update;
    if not found or v_source_qty-v_source_reserved<p_quantity then raise exception 'Stock du sous-entrepôt insuffisant'; end if;
    update public.warehouse_subwarehouse_inventory set quantity=quantity-p_quantity,updated_at=now()
    where subwarehouse_id=p_source_subwarehouse_id and article_id=p_article_id;
  end if;

  if p_destination_subwarehouse_id is null then
    insert into public.warehouse_inventory(organization_id,warehouse_id,article_id,quantity,reserved_quantity,minimum_quantity,updated_at)
    values(v_org,p_destination_warehouse_id,p_article_id,p_quantity,0,0,now())
    on conflict(warehouse_id,article_id) do update set quantity=public.warehouse_inventory.quantity+excluded.quantity,updated_at=now();
  else
    insert into public.warehouse_subwarehouse_inventory(organization_id,warehouse_id,subwarehouse_id,article_id,quantity,reserved_quantity,minimum_quantity,updated_at)
    values(v_org,p_destination_warehouse_id,p_destination_subwarehouse_id,p_article_id,p_quantity,0,0,now())
    on conflict(subwarehouse_id,article_id) do update set quantity=public.warehouse_subwarehouse_inventory.quantity+excluded.quantity,updated_at=now();
  end if;

  v_source:='warehouse:'||p_source_warehouse_id::text;
  v_dest:='warehouse:'||p_destination_warehouse_id::text;
  insert into public.stock_movements(organization_id,article_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,source_subwarehouse_id,destination_subwarehouse_id)
  values(v_org,p_article_id,'transfer_out',p_quantity::integer,'subwarehouse_transfer',v_ref,v_source,v_dest,nullif(trim(p_notes),''),v_uid,p_source_subwarehouse_id,null);
  insert into public.stock_movements(organization_id,article_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,source_subwarehouse_id,destination_subwarehouse_id)
  values(v_org,p_article_id,'transfer_in',p_quantity::integer,'subwarehouse_transfer',v_ref,v_source,v_dest,nullif(trim(p_notes),''),v_uid,null,p_destination_subwarehouse_id);
  return v_ref;
end $$;
revoke all on function public.jdvcrm_transfer_stock_location_v1(uuid,numeric,uuid,uuid,uuid,uuid,text) from public,anon;
grant execute on function public.jdvcrm_transfer_stock_location_v1(uuid,numeric,uuid,uuid,uuid,uuid,text) to authenticated;
