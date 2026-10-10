-- Corrected return traceability view: use public profiles only; do not expose auth.users through the API.
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
  coalesce(r.returned_by_name, nullif(trim(coalesce(p.full_name, concat_ws(' ',p.first_name,p.last_name))),''), p.email) as returned_by_name,
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
