-- Restrict the unified stock view to the current user's organization/warehouse access.
create or replace view public.jdvcrm_subwarehouse_stock_v1
with (security_invoker=true) as
select wi.id inventory_id, wi.organization_id, wi.warehouse_id, w.name warehouse_name, w.code warehouse_code,
       null::uuid subwarehouse_id, null::text subwarehouse_name, null::text subwarehouse_code,
       wi.article_id, a.code article_code, a.name article_name, wi.quantity, wi.reserved_quantity,
       wi.minimum_quantity, wi.updated_at
from public.warehouse_inventory wi
join public.warehouses w on w.id=wi.warehouse_id
join public.articles a on a.id=wi.article_id
where public.is_super_admin()
   or public.is_org_admin(wi.organization_id)
   or exists (
     select 1 from public.organization_members om
     where om.organization_id=wi.organization_id and om.user_id=auth.uid() and om.member_status='active'
   )
   or exists (
     select 1 from public.warehouse_managers wm
     where wm.warehouse_id=wi.warehouse_id and wm.user_id=auth.uid() and wm.status='active'
   )
union all
select swi.id, swi.organization_id, swi.warehouse_id, w.name, w.code,
       swi.subwarehouse_id, sw.name, sw.code, swi.article_id, a.code, a.name,
       swi.quantity, swi.reserved_quantity, swi.minimum_quantity, swi.updated_at
from public.warehouse_subwarehouse_inventory swi
join public.warehouses w on w.id=swi.warehouse_id
join public.warehouse_subwarehouses sw on sw.id=swi.subwarehouse_id
join public.articles a on a.id=swi.article_id
where public.is_super_admin()
   or public.is_org_admin(swi.organization_id)
   or exists (
     select 1 from public.organization_members om
     where om.organization_id=swi.organization_id and om.user_id=auth.uid() and om.member_status='active'
   )
   or exists (
     select 1 from public.warehouse_managers wm
     where wm.warehouse_id=swi.warehouse_id and wm.user_id=auth.uid() and wm.status='active'
   );
revoke all on public.jdvcrm_subwarehouse_stock_v1 from anon;
grant select on public.jdvcrm_subwarehouse_stock_v1 to authenticated;
