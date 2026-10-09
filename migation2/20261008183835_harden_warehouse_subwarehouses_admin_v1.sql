-- Harden subwarehouse manager validation and keep creation admin-only.

create or replace function public.jdvcrm_subwarehouse_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_org uuid;
begin
  if new.parent_warehouse_id is null then
    raise exception 'Entrepôt parent obligatoire';
  end if;

  select w.organization_id
    into v_org
    from public.warehouses w
   where w.id = new.parent_warehouse_id
     and w.active = true;

  if not found then
    raise exception 'Entrepôt parent introuvable ou inactif';
  end if;

  new.organization_id := v_org;
  new.code := upper(trim(new.code));
  new.name := trim(new.name);
  new.address := nullif(trim(new.address), '');
  new.city := nullif(trim(new.city), '');
  new.zone := nullif(trim(new.zone), '');
  new.updated_at := now();

  if new.manager_user_id is not null
     and not (
       exists (
         select 1
         from public.super_admins sa
         where sa.user_id = new.manager_user_id
           and sa.status = 'active'
           and coalesce(sa.actif, true) = true
       )
       or exists (
         select 1
         from public.organization_members om
         where om.user_id = new.manager_user_id
           and om.organization_id = v_org
           and om.status = 'active'
           and lower(om.role) in ('business_admin', 'admin')
       )
       or exists (
         select 1
         from public.warehouse_managers wm
         where wm.warehouse_id = new.parent_warehouse_id
           and wm.user_id = new.manager_user_id
           and wm.status = 'active'
       )
     ) then
    raise exception 'Le responsable doit être un administrateur ou un responsable actif de l''entrepôt parent';
  end if;

  return new;
end;
$function$;

revoke all on function public.jdvcrm_subwarehouse_guard_v1() from public, anon, authenticated;

delete from public.role_permissions rp
using public.permissions p
where rp.permission_id = p.id
  and rp.role in ('manager', 'supervisor')
  and p.code in (
    'warehouses.subwarehouses.create',
    'warehouses.subwarehouses.update',
    'warehouses.subwarehouses.deactivate'
  );

insert into public.role_permissions (role, permission_id)
select 'manager', p.id
from public.permissions p
where p.code = 'warehouses.subwarehouses.view'
on conflict (role, permission_id) do nothing;

insert into public.role_permissions (role, permission_id)
select 'supervisor', p.id
from public.permissions p
where p.code = 'warehouses.subwarehouses.view'
on conflict (role, permission_id) do nothing;
