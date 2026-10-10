-- JDV CRM: warehouse creation/assignment RPCs and return traceability view.
-- Additive only; existing sales, returns, and stock records are preserved.

create table if not exists public.prospecteur_warehouse_assignments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  prospecteur_id uuid not null references public.prospecteurs(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete cascade,
  department text,
  city text,
  work_zone text,
  is_primary boolean not null default true,
  active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_pwa_org on public.prospecteur_warehouse_assignments(organization_id);
create index if not exists idx_pwa_prospecteur_active on public.prospecteur_warehouse_assignments(prospecteur_id) where active=true;
create index if not exists idx_pwa_warehouse_active on public.prospecteur_warehouse_assignments(warehouse_id) where active=true;

create or replace function public.jdvcrm_create_warehouse_v1(
  p_organization_id uuid,
  p_code text,
  p_name text,
  p_address text default null,
  p_city text default null,
  p_country text default 'Benin'
)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  if not (public.is_super_admin() or public.is_org_admin(p_organization_id)) then
    raise exception 'Seul un administrateur de cette organisation peut créer un entrepôt';
  end if;
  if p_organization_id is null or not exists(select 1 from public.organizations where id=p_organization_id) then
    raise exception 'Organisation introuvable';
  end if;
  if length(trim(coalesce(p_code,'')))<2 or length(trim(coalesce(p_name,'')))<2 then
    raise exception 'Le code et le nom doivent contenir au moins deux caractères';
  end if;
  insert into public.warehouses(organization_id,code,name,address,city,country,manager_user_id,active)
  values(p_organization_id,upper(trim(p_code)),trim(p_name),nullif(trim(p_address),''),nullif(trim(p_city),''),coalesce(nullif(trim(p_country),''),'Benin'),auth.uid(),true)
  returning id into v_id;
  return v_id;
end $$;
revoke all on function public.jdvcrm_create_warehouse_v1(uuid,text,text,text,text,text) from public,anon;
grant execute on function public.jdvcrm_create_warehouse_v1(uuid,text,text,text,text,text) to authenticated;

create or replace function public.jdvcrm_assign_prospecteur_warehouse_v1(
  p_organization_id uuid,
  p_prospecteur_id uuid,
  p_warehouse_id uuid,
  p_department text default null,
  p_city text default null,
  p_work_zone text default null
)
returns uuid language plpgsql security definer set search_path=''
as $$
declare v_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  if not (public.is_super_admin() or public.is_org_admin(p_organization_id)) then
    raise exception 'Seul un administrateur de cette organisation peut affecter un prospecteur';
  end if;
  if not exists(select 1 from public.warehouses where id=p_warehouse_id and organization_id=p_organization_id and active=true) then
    raise exception 'Entrepôt invalide pour cette organisation';
  end if;
  if not exists(select 1 from public.prospecteurs where id=p_prospecteur_id and organization_id=p_organization_id and status='active') then
    raise exception 'Prospecteur invalide pour cette organisation';
  end if;
  update public.prospecteur_warehouse_assignments
  set active=false,is_primary=false,updated_at=now()
  where organization_id=p_organization_id and prospecteur_id=p_prospecteur_id and active=true and is_primary=true;
  insert into public.prospecteur_warehouse_assignments(
    organization_id,prospecteur_id,warehouse_id,department,city,work_zone,is_primary,active,created_by
  ) values (
    p_organization_id,p_prospecteur_id,p_warehouse_id,nullif(trim(p_department),''),nullif(trim(p_city),''),
    nullif(trim(p_work_zone),''),true,true,auth.uid()
  ) returning id into v_id;
  return v_id;
end $$;
revoke all on function public.jdvcrm_assign_prospecteur_warehouse_v1(uuid,uuid,uuid,text,text,text) from public,anon;
grant execute on function public.jdvcrm_assign_prospecteur_warehouse_v1(uuid,uuid,uuid,text,text,text) to authenticated;

alter table public.prospecteur_warehouse_assignments enable row level security;
drop policy if exists prospecteur_warehouse_assignments_select on public.prospecteur_warehouse_assignments;
create policy prospecteur_warehouse_assignments_select on public.prospecteur_warehouse_assignments for select to authenticated
using (public.is_super_admin() or public.is_org_admin(organization_id) or exists (
  select 1 from public.warehouse_managers wm
  where wm.warehouse_id=prospecteur_warehouse_assignments.warehouse_id
    and wm.user_id=auth.uid() and wm.status='active'
));
drop policy if exists prospecteur_warehouse_assignments_admin_write on public.prospecteur_warehouse_assignments;
create policy prospecteur_warehouse_assignments_admin_write on public.prospecteur_warehouse_assignments for all to authenticated
using (public.is_super_admin() or public.is_org_admin(organization_id))
with check (public.is_super_admin() or public.is_org_admin(organization_id));
revoke all on public.prospecteur_warehouse_assignments from public,anon;
grant select,insert,update on public.prospecteur_warehouse_assignments to authenticated;
grant all on public.prospecteur_warehouse_assignments to service_role;

alter table public.sales_returns
  add column if not exists returned_by_user_id uuid references auth.users(id) on delete set null,
  add column if not exists returned_by_name text,
  add column if not exists returned_by_role text,
  add column if not exists warehouse_id uuid references public.warehouses(id) on delete restrict,
  add column if not exists subwarehouse_id uuid references public.warehouse_subwarehouses(id) on delete restrict,
  add column if not exists received_by_user_id uuid references auth.users(id) on delete set null,
  add column if not exists received_at timestamptz;
alter table public.sales_return_items
  add column if not exists article_code_snapshot text,
  add column if not exists article_name_snapshot text;
create index if not exists idx_sales_returns_returned_by on public.sales_returns(returned_by_user_id);
create index if not exists idx_sales_returns_warehouse on public.sales_returns(warehouse_id,return_date desc);
create index if not exists idx_sales_returns_subwarehouse on public.sales_returns(subwarehouse_id,return_date desc);

create or replace view public.jdvcrm_returns_traceability_v1
with (security_invoker=true) as
select
  r.id as return_id,
  r.return_number,
  r.return_date,
  r.reason,
  r.status,
  r.organization_id,
  r.sale_id,
  s.prospecteur_id,
  r.returned_by_user_id,
  coalesce(r.returned_by_name, nullif(trim(coalesce(p.full_name, concat_ws(' ',p.first_name,p.last_name))),''), u.email) as returned_by_name,
  coalesce(r.returned_by_role, rr.code) as returned_by_role,
  r.warehouse_id,
  w.name as warehouse_name,
  w.code as warehouse_code,
  r.subwarehouse_id,
  sw.name as subwarehouse_name,
  sw.code as subwarehouse_code,
  r.received_by_user_id,
  r.received_at,
  ri.id as return_item_id,
  ri.article_id,
  coalesce(ri.article_code_snapshot,a.code) as article_code,
  coalesce(ri.article_name_snapshot,a.name) as article_name,
  ri.quantity,
  ri.refund_amount
from public.sales_returns r
join public.sales s on s.id=r.sale_id
join public.sales_return_items ri on ri.return_id=r.id
join public.articles a on a.id=ri.article_id
left join public.warehouses w on w.id=r.warehouse_id
left join public.warehouse_subwarehouses sw on sw.id=r.subwarehouse_id
left join public.profiles p on p.id=coalesce(r.returned_by_user_id,r.created_by)
left join auth.users u on u.id=coalesce(r.returned_by_user_id,r.created_by)
left join lateral (
  select roles.code from public.organization_members om
  join public.roles on roles.id=om.role_id
  where om.user_id=coalesce(r.returned_by_user_id,r.created_by)
    and om.organization_id=r.organization_id
    and om.member_status='active'
  order by om.joined_at asc limit 1
) rr on true;
revoke all on public.jdvcrm_returns_traceability_v1 from anon;
grant select on public.jdvcrm_returns_traceability_v1 to authenticated;
