-- Preserve subwarehouse history: disable hard delete through the Data API.
drop policy if exists warehouse_subwarehouses_admin_delete on public.warehouse_subwarehouses;
revoke delete on public.warehouse_subwarehouses from authenticated;

-- Keep only explicit CRUD required by the application.
revoke all on public.warehouse_subwarehouses from public, anon;
grant select, insert, update on public.warehouse_subwarehouses to authenticated;
grant all on public.warehouse_subwarehouses to service_role;
