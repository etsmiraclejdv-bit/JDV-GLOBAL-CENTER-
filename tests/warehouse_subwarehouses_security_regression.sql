-- Regression checks for warehouse subwarehouse security.
-- These checks are intentionally read-only; authenticated-session allow/deny tests
-- should be executed with Supabase's database test harness when credentials are available.

select
  c.relname as table_name,
  c.relrowsecurity as rls_enabled
from pg_class c
join pg_namespace n on n.oid = c.relnamespace
where n.nspname = 'public'
  and c.relname = 'warehouse_subwarehouses';

select policyname, cmd, roles
from pg_policies
where schemaname = 'public'
  and tablename = 'warehouse_subwarehouses'
order by policyname;

select code
from public.permissions
where code like 'warehouses.subwarehouses.%'
order by code;

select
  p.code,
  rp.role
from public.role_permissions rp
join public.permissions p on p.id = rp.permission_id
where p.code like 'warehouses.subwarehouses.%'
order by p.code, rp.role;

select has_table_privilege('anon', 'public.warehouse_subwarehouses', 'INSERT') as anon_can_insert;
select has_table_privilege('anon', 'public.warehouse_subwarehouses', 'UPDATE') as anon_can_update;
select has_table_privilege('anon', 'public.warehouse_subwarehouses', 'DELETE') as anon_can_delete;
