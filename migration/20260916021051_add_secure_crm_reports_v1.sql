create or replace function public.jdvcrm_report_sales_v1(p_organization_id uuid,p_start_date date,p_end_date date)
returns table(sale_date date,sale_number text,client_id uuid,prospecteur_id uuid,sale_type text,status text,quantity numeric,total_amount numeric,amount_paid numeric,amount_remaining numeric)
language sql security definer set search_path=public,private as $$
 select s.sale_date::date,s.sale_number,s.client_id,s.prospecteur_id,s.sale_type,s.status,s.quantity,
 (case when lower(s.sale_type)='credit' then s.credit_price else s.cash_price end*s.quantity)::numeric,s.amount_paid,s.amount_remaining
 from sales s where s.organization_id=p_organization_id and s.sale_date::date between p_start_date and p_end_date
 and (private.is_super_admin() or private.is_org_admin(p_organization_id)) order by s.sale_date desc;
$$;
revoke all on function public.jdvcrm_report_sales_v1(uuid,date,date) from public,anon,authenticated; grant execute on function public.jdvcrm_report_sales_v1(uuid,date,date) to authenticated;

create or replace function public.jdvcrm_report_payments_v1(p_organization_id uuid,p_start_date date,p_end_date date)
returns table(payment_date date,payment_id uuid,sale_id uuid,client_id uuid,prospecteur_id uuid,amount numeric,currency text,payment_method text,provider text,status text)
language sql security definer set search_path=public,private as $$
 select p.payment_date::date,p.id,p.sale_id,p.client_id,p.prospecteur_id,p.amount,p.currency,p.payment_method,p.provider,p.status
 from payments p where p.organization_id=p_organization_id and p.payment_date::date between p_start_date and p_end_date
 and (private.is_super_admin() or private.is_org_admin(p_organization_id)) order by p.payment_date desc;
$$;
revoke all on function public.jdvcrm_report_payments_v1(uuid,date,date) from public,anon,authenticated; grant execute on function public.jdvcrm_report_payments_v1(uuid,date,date) to authenticated;

create or replace function public.jdvcrm_report_overdue_v1(p_organization_id uuid)
returns table(schedule_id uuid,sale_id uuid,client_id uuid,due_date date,expected_amount numeric,paid_amount numeric,remaining_amount numeric,status text,days_late integer)
language sql security definer set search_path=public,private as $$
 select ps.id,ps.sale_id,s.client_id,ps.due_date,ps.expected_amount,ps.paid_amount,greatest(ps.expected_amount-ps.paid_amount,0),ps.status,greatest(current_date-ps.due_date,0)::integer
 from payment_schedules ps join sales s on s.id=ps.sale_id
 where ps.organization_id=p_organization_id and ps.status in ('late','partial','pending') and ps.paid_amount<ps.expected_amount
 and (private.is_super_admin() or private.is_org_admin(p_organization_id)) order by ps.due_date;
$$;
revoke all on function public.jdvcrm_report_overdue_v1(uuid) from public,anon,authenticated; grant execute on function public.jdvcrm_report_overdue_v1(uuid) to authenticated;

create or replace function public.jdvcrm_report_commissions_v1(p_organization_id uuid,p_start_date date,p_end_date date)
returns table(commission_id uuid,prospecteur_id uuid,sale_id uuid,article_id uuid,rate numeric,base_amount numeric,commission_amount numeric,status text,paid_at timestamptz)
language sql security definer set search_path=public,private as $$
 select c.id,c.prospecteur_id,c.sale_id,c.article_id,c.commission_rate,c.base_amount,c.commission_amount,c.status,c.paid_at
 from commissions c where c.organization_id=p_organization_id and c.created_at::date between p_start_date and p_end_date
 and (private.is_super_admin() or private.is_org_admin(p_organization_id)) order by c.created_at desc;
$$;
revoke all on function public.jdvcrm_report_commissions_v1(uuid,date,date) from public,anon,authenticated; grant execute on function public.jdvcrm_report_commissions_v1(uuid,date,date) to authenticated;

create index if not exists idx_jdvcrm_sales_report_date on public.sales(organization_id,sale_date);
create index if not exists idx_jdvcrm_payments_report_date on public.payments(organization_id,payment_date);
create index if not exists idx_jdvcrm_commissions_report_date on public.commissions(organization_id,created_at);
