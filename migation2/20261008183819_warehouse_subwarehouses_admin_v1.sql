-- =====================================================================================
-- Sous-entrepôts : unités opérationnelles rattachées à un entrepôt parent.
-- Création / modification / désactivation réservées aux Super Admin et Business Admin.
-- =====================================================================================

create table public.warehouse_subwarehouses (
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

create index idx_subwarehouses_org on public.warehouse_subwarehouses (organization_id);
create index idx_subwarehouses_parent on public.warehouse_subwarehouses (parent_warehouse_id);
create index idx_subwarehouses_manager on public.warehouse_subwarehouses (manager_user_id)
  where manager_user_id is not null;
create index idx_subwarehouses_active_parent on public.warehouse_subwarehouses (parent_warehouse_id, active);

create or replace function private.can_access_subwarehouse(p_subwarehouse_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.warehouse_subwarehouses sw
    where sw.id = p_subwarehouse_id
      and (
        private.is_super_admin()
        or private.is_org_admin(sw.organization_id)
        or exists (
          select 1
          from public.warehouse_managers wm
          where wm.warehouse_id = sw.parent_warehouse_id
            and wm.user_id = (select auth.uid())
            and wm.status = 'active'
        )
      )
  );
$function$;

revoke all on function private.can_access_subwarehouse(uuid) from public, anon;
grant execute on function private.can_access_subwarehouse(uuid) to authenticated;

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
       private.is_org_admin(v_org)
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

drop trigger if exists trg_warehouse_subwarehouses_guard on public.warehouse_subwarehouses;
create trigger trg_warehouse_subwarehouses_guard
before insert or update on public.warehouse_subwarehouses
for each row execute function public.jdvcrm_subwarehouse_guard_v1();

alter table public.warehouse_subwarehouses enable row level security;

drop policy if exists warehouse_subwarehouses_select on public.warehouse_subwarehouses;
create policy warehouse_subwarehouses_select
on public.warehouse_subwarehouses
for select to authenticated
using ((select private.can_access_subwarehouse(id)));

drop policy if exists warehouse_subwarehouses_admin_insert on public.warehouse_subwarehouses;
create policy warehouse_subwarehouses_admin_insert
on public.warehouse_subwarehouses
for insert to authenticated
with check ((select private.is_org_admin(organization_id)));

drop policy if exists warehouse_subwarehouses_admin_update on public.warehouse_subwarehouses;
create policy warehouse_subwarehouses_admin_update
on public.warehouse_subwarehouses
for update to authenticated
using ((select private.is_org_admin(organization_id)))
with check ((select private.is_org_admin(organization_id)));

drop policy if exists warehouse_subwarehouses_admin_delete on public.warehouse_subwarehouses;
create policy warehouse_subwarehouses_admin_delete
on public.warehouse_subwarehouses
for delete to authenticated
using ((select private.is_org_admin(organization_id)));

revoke all on public.warehouse_subwarehouses from public, anon;
grant select, insert, update, delete on public.warehouse_subwarehouses to authenticated;
grant all on public.warehouse_subwarehouses to service_role;

insert into public.permissions (code, name, description, module)
values
  ('warehouses.subwarehouses.view', 'Voir les sous-entrepôts', 'Consulter les sous-entrepôts accessibles', 'warehouses'),
  ('warehouses.subwarehouses.create', 'Créer un sous-entrepôt', 'Créer une unité rattachée à un entrepôt parent', 'warehouses'),
  ('warehouses.subwarehouses.update', 'Modifier un sous-entrepôt', 'Modifier les informations d''un sous-entrepôt', 'warehouses'),
  ('warehouses.subwarehouses.deactivate', 'Désactiver un sous-entrepôt', 'Désactiver un sous-entrepôt sans supprimer son historique', 'warehouses')
on conflict (code) do update
set name = excluded.name,
    description = excluded.description,
    module = excluded.module;

insert into public.role_permissions (role, permission_id)
select r.role, p.id
from (
  values
    ('business_admin'),
    ('manager')
) as r(role)
cross join public.permissions p
where p.code in (
  'warehouses.subwarehouses.view',
  'warehouses.subwarehouses.create',
  'warehouses.subwarehouses.update',
  'warehouses.subwarehouses.deactivate'
)
on conflict (role, permission_id) do nothing;

insert into public.role_permissions (role, permission_id)
select 'supervisor', p.id
from public.permissions p
where p.code = 'warehouses.subwarehouses.view'
on conflict (role, permission_id) do nothing;

-- Référentiel de test régressif : vérifie au minimum l'existence et le verrouillage RLS.
