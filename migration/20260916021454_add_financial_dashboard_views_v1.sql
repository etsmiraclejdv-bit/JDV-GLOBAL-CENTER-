create or replace view public.jdvcrm_financial_kpi_monthly_v1 with (security_invoker=true) as
select s.organization_id,
       date_trunc('month',s.sale_date)::date as month,
       count(*)::bigint as sales_count,
       coalesce(sum((case when lower(s.sale_type)='credit' then s.credit_price else s.cash_price end)*s.quantity),0)::numeric as sales_total,
       coalesce(sum(s.amount_paid),0)::numeric as amount_paid,
       coalesce(sum(s.amount_remaining),0)::numeric as amount_remaining
from public.sales s
where s.status <> 'cancelled'
group by s.organization_id,date_trunc('month',s.sale_date)::date;

create or replace view public.jdvcrm_collections_monthly_v1 with (security_invoker=true) as
select p.organization_id,
       date_trunc('month',p.payment_date)::date as month,
       coalesce(sum(p.amount) filter(where p.status='successful'),0)::numeric as collected_total,
       count(*) filter(where p.status='successful')::bigint as payment_count
from public.payments p
group by p.organization_id,date_trunc('month',p.payment_date)::date;

create or replace view public.jdvcrm_commissions_monthly_v1 with (security_invoker=true) as
select c.organization_id,
       date_trunc('month',c.created_at)::date as month,
       coalesce(sum(c.commission_amount) filter(where c.status<>'cancelled'),0)::numeric as commission_total,
       coalesce(sum(c.commission_amount) filter(where c.status in('pending','approved')),0)::numeric as commission_unpaid,
       coalesce(sum(c.commission_amount) filter(where c.status='paid'),0)::numeric as commission_paid
from public.commissions c
group by c.organization_id,date_trunc('month',c.created_at)::date;

revoke all on public.jdvcrm_financial_kpi_monthly_v1 from anon;
revoke all on public.jdvcrm_collections_monthly_v1 from anon;
revoke all on public.jdvcrm_commissions_monthly_v1 from anon;
grant select on public.jdvcrm_financial_kpi_monthly_v1,public.jdvcrm_collections_monthly_v1,public.jdvcrm_commissions_monthly_v1 to authenticated;
