-- JDV CRM - rattachement stock et mouvements aux sous-entrepôts
alter table public.warehouse_inventory
  add column if not exists subwarehouse_id uuid references public.warehouse_subwarehouses(id) on delete restrict;

alter table public.stock_movements
  add column if not exists source_subwarehouse_id uuid references public.warehouse_subwarehouses(id) on delete restrict,
  add column if not exists destination_subwarehouse_id uuid references public.warehouse_subwarehouses(id) on delete restrict;

alter table public.warehouse_inventory drop constraint if exists warehouse_inventory_warehouse_id_article_id_key;
create unique index if not exists uq_warehouse_inventory_central
  on public.warehouse_inventory(warehouse_id, article_id)
  where subwarehouse_id is null;
create unique index if not exists uq_warehouse_inventory_subwarehouse
  on public.warehouse_inventory(subwarehouse_id, article_id)
  where subwarehouse_id is not null;

create index if not exists idx_warehouse_inventory_subwarehouse
  on public.warehouse_inventory(subwarehouse_id, article_id);

create index if not exists idx_stock_movements_source_subwarehouse
  on public.stock_movements(source_subwarehouse_id, article_id, created_at);
create index if not exists idx_stock_movements_destination_subwarehouse
  on public.stock_movements(destination_subwarehouse_id, article_id, created_at);

create or replace function public.jdvcrm_subwarehouse_stock_guard_v1()
returns trigger language plpgsql security definer set search_path=''
as $$
declare
  v_org uuid;
  v_parent uuid;
begin
  if new.subwarehouse_id is null then return new; end if;
  select organization_id,parent_warehouse_id into v_org,v_parent
    from public.warehouse_subwarehouses
   where id=new.subwarehouse_id and active=true;
  if v_org is null then raise exception 'Sous-entrepôt introuvable ou inactif'; end if;
  if v_org <> new.organization_id or v_parent <> new.warehouse_id then
    raise exception 'Le sous-entrepôt ne correspond pas à l''organisation ou à l''entrepôt parent';
  end if;
  return new;
end $$;
revoke all on function public.jdvcrm_subwarehouse_stock_guard_v1() from public,anon,authenticated;

drop trigger if exists trg_jdvcrm_subwarehouse_stock_guard on public.warehouse_inventory;
create trigger trg_jdvcrm_subwarehouse_stock_guard
before insert or update on public.warehouse_inventory
for each row execute function public.jdvcrm_subwarehouse_stock_guard_v1();

create or replace function public.jdvcrm_subwarehouse_movement_guard_v1()
returns trigger language plpgsql security definer set search_path=''
as $$
declare v_org uuid; v_parent uuid; v_wh uuid;
begin
  if new.source_subwarehouse_id is not null then
    select organization_id,parent_warehouse_id into v_org,v_parent from public.warehouse_subwarehouses where id=new.source_subwarehouse_id and active=true;
    if v_org is null or v_org<>new.organization_id then raise exception 'Sous-entrepôt source invalide'; end if;
    v_wh := nullif(replace(new.source_location,'warehouse:',''),'')::uuid;
    if v_wh is not null and v_wh<>v_parent then raise exception 'Entrepôt source incohérent avec le sous-entrepôt'; end if;
  end if;
  if new.destination_subwarehouse_id is not null then
    select organization_id,parent_warehouse_id into v_org,v_parent from public.warehouse_subwarehouses where id=new.destination_subwarehouse_id and active=true;
    if v_org is null or v_org<>new.organization_id then raise exception 'Sous-entrepôt destination invalide'; end if;
    v_wh := nullif(replace(new.destination_location,'warehouse:',''),'')::uuid;
    if v_wh is not null and v_wh<>v_parent then raise exception 'Entrepôt destination incohérent avec le sous-entrepôt'; end if;
  end if;
  return new;
end $$;
revoke all on function public.jdvcrm_subwarehouse_movement_guard_v1() from public,anon,authenticated;
drop trigger if exists trg_jdvcrm_subwarehouse_movement_guard on public.stock_movements;
create trigger trg_jdvcrm_subwarehouse_movement_guard
before insert or update on public.stock_movements
for each row execute function public.jdvcrm_subwarehouse_movement_guard_v1();

-- Vue opérationnelle: stock central + stock de chaque sous-entrepôt.
create or replace view public.jdvcrm_subwarehouse_stock_v1
with (security_invoker=true) as
select
  wi.id as inventory_id,
  wi.organization_id,
  wi.warehouse_id,
  w.name as warehouse_name,
  w.code as warehouse_code,
  wi.subwarehouse_id,
  sw.name as subwarehouse_name,
  sw.code as subwarehouse_code,
  wi.article_id,
  a.code as article_code,
  a.name as article_name,
  wi.quantity,
  wi.reserved_quantity,
  wi.minimum_quantity,
  wi.updated_at
from public.warehouse_inventory wi
join public.warehouses w on w.id=wi.warehouse_id
join public.articles a on a.id=wi.article_id
left join public.warehouse_subwarehouses sw on sw.id=wi.subwarehouse_id;

revoke all on public.jdvcrm_subwarehouse_stock_v1 from anon;
grant select on public.jdvcrm_subwarehouse_stock_v1 to authenticated;

-- Transfert atomique entre deux emplacements: central ou sous-entrepôt.
create or replace function public.jdvcrm_transfer_stock_location_v1(
  p_article_id uuid,
  p_quantity numeric,
  p_source_warehouse_id uuid,
  p_source_subwarehouse_id uuid default null,
  p_destination_warehouse_id uuid default null,
  p_destination_subwarehouse_id uuid default null,
  p_notes text default null
)
returns uuid
language plpgsql security definer set search_path=''
as $$
declare
  v_uid uuid := auth.uid();
  v_org uuid;
  v_source_qty numeric;
  v_price numeric;
  v_ref uuid := gen_random_uuid();
  v_source text;
  v_dest text;
begin
  if v_uid is null then raise exception 'Authentification requise'; end if;
  if p_quantity <= 0 then raise exception 'La quantité doit être positive'; end if;
  if not private.can_manage_warehouse(p_source_warehouse_id) then raise exception 'Accès refusé à l''entrepôt source'; end if;
  if p_destination_warehouse_id is null then p_destination_warehouse_id:=p_source_warehouse_id; end if;
  if not private.can_manage_warehouse(p_destination_warehouse_id) then raise exception 'Accès refusé à l''entrepôt destination'; end if;

  select organization_id into v_org from public.warehouses where id=p_source_warehouse_id and active=true;
  if v_org is null then raise exception 'Entrepôt source invalide'; end if;

  if p_source_subwarehouse_id is not null then
    if not exists(select 1 from public.warehouse_subwarehouses where id=p_source_subwarehouse_id and parent_warehouse_id=p_source_warehouse_id and organization_id=v_org and active=true)
      then raise exception 'Sous-entrepôt source invalide'; end if;
  end if;
  if p_destination_subwarehouse_id is not null then
    if not exists(select 1 from public.warehouse_subwarehouses where id=p_destination_subwarehouse_id and parent_warehouse_id=p_destination_warehouse_id and organization_id=v_org and active=true)
      then raise exception 'Sous-entrepôt destination invalide'; end if;
  end if;

  select quantity into v_source_qty from public.warehouse_inventory
   where warehouse_id=p_source_warehouse_id and article_id=p_article_id
     and ((subwarehouse_id=p_source_subwarehouse_id) or (subwarehouse_id is null and p_source_subwarehouse_id is null))
   for update;
  if coalesce(v_source_qty,0) < p_quantity then raise exception 'Stock insuffisant pour le transfert'; end if;

  select coalesce(fixed_price,cash_price,credit_price,0) into v_price from public.articles where id=p_article_id and organization_id=v_org;
  if v_price is null then raise exception 'Article introuvable'; end if;

  update public.warehouse_inventory
     set quantity=quantity-p_quantity, updated_at=now()
   where warehouse_id=p_source_warehouse_id and article_id=p_article_id
     and ((subwarehouse_id=p_source_subwarehouse_id) or (subwarehouse_id is null and p_source_subwarehouse_id is null));

  insert into public.warehouse_inventory(organization_id,warehouse_id,subwarehouse_id,article_id,quantity,reserved_quantity,minimum_quantity)
  values(v_org,p_destination_warehouse_id,p_destination_subwarehouse_id,p_article_id,p_quantity,0,0)
  on conflict do nothing;

  update public.warehouse_inventory
     set quantity=quantity+p_quantity, updated_at=now()
   where warehouse_id=p_destination_warehouse_id and article_id=p_article_id
     and ((subwarehouse_id=p_destination_subwarehouse_id) or (subwarehouse_id is null and p_destination_subwarehouse_id is null));

  v_source := 'warehouse:'||p_source_warehouse_id;
  v_dest := 'warehouse:'||p_destination_warehouse_id;

  insert into public.stock_movements(organization_id,article_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,source_subwarehouse_id,destination_subwarehouse_id,unit_price,notes,created_by)
  values(v_org,p_article_id,'transfer_out',p_quantity,'stock_transfer',v_ref,v_source,v_dest,p_source_subwarehouse_id,p_destination_subwarehouse_id,v_price,p_notes,v_uid);

  insert into public.stock_movements(organization_id,article_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,source_subwarehouse_id,destination_subwarehouse_id,unit_price,notes,created_by)
  values(v_org,p_article_id,'transfer_in',p_quantity,'stock_transfer',v_ref,v_source,v_dest,p_source_subwarehouse_id,p_destination_subwarehouse_id,v_price,p_notes,v_uid);

  return v_ref;
end $$;

revoke all on function public.jdvcrm_transfer_stock_location_v1(uuid,numeric,uuid,uuid,uuid,uuid,text) from public,anon;
grant execute on function public.jdvcrm_transfer_stock_location_v1(uuid,numeric,uuid,uuid,uuid,uuid,text) to authenticated;

insert into public.permissions(code,name,description,module)
values
 ('stock.subwarehouses.view','Voir le stock des sous-entrepôts','Consulter le stock par sous-entrepôt','stock'),
 ('stock.subwarehouses.transfer','Transférer du stock vers ou depuis un sous-entrepôt','Effectuer des transferts tracés entre emplacements','stock')
on conflict(code) do update set name=excluded.name,description=excluded.description,module=excluded.module;

insert into public.role_permissions(role,permission_id)
select r.role,p.id from (values('business_admin'),('manager'),('supervisor')) r(role)
join public.permissions p on p.code in ('stock.subwarehouses.view','stock.subwarehouses.transfer')
on conflict(role,permission_id) do nothing;
