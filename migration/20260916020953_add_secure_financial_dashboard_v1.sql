create or replace function public.jdvcrm_financial_dashboard_v1(p_organization_id uuid,p_start_date date default null,p_end_date date default null)
returns jsonb language plpgsql security definer set search_path=public,private as $$
declare v_start date:=coalesce(p_start_date,date_trunc('month',current_date)::date); v_end date:=coalesce(p_end_date,current_date); v jsonb;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 if not (private.is_super_admin() or private.is_org_admin(p_organization_id)) then raise exception 'Accès refusé'; end if;
 if v_end<v_start then raise exception 'Période invalide'; end if;
 select jsonb_build_object('period_start',v_start,'period_end',v_end,'sales_count',coalesce((select count(*) from sales s where s.organization_id=p_organization_id and s.sale_date::date between v_start and v_end),0),'sales_total',coalesce((select sum(case when lower(s.sale_type)='credit' then s.credit_price else s.cash_price end*s.quantity) from sales s where s.organization_id=p_organization_id and s.sale_date::date between v_start and v_end),0),'cash_collected',coalesce((select sum(p.amount) from payments p where p.organization_id=p_organization_id and p.status='successful' and p.payment_date::date between v_start and v_end),0),'credit_outstanding',coalesce((select sum(s.amount_remaining) from sales s where s.organization_id=p_organization_id and s.status not in ('cancelled','completed') and lower(s.sale_type)='credit'),0),'overdue_amount',coalesce((select sum(greatest(ps.expected_amount-ps.paid_amount,0)) from payment_schedules ps where ps.organization_id=p_organization_id and ps.status in ('late','partial') and ps.paid_amount<ps.expected_amount),0),'overdue_schedules',coalesce((select count(*) from payment_schedules ps where ps.organization_id=p_organization_id and ps.status in ('late','partial') and ps.paid_amount<ps.expected_amount),0),'commission_total',coalesce((select sum(c.commission_amount) from commissions c where c.organization_id=p_organization_id and c.created_at::date between v_start and v_end and c.status<>'cancelled'),0),'commission_unpaid',coalesce((select sum(c.commission_amount) from commissions c where c.organization_id=p_organization_id and c.status in ('pending','approved')),0),'commission_paid',coalesce((select sum(c.commission_amount) from commissions c where c.organization_id=p_organization_id and c.status='paid' and c.paid_at::date between v_start and v_end),0)) into v; return v;
end; $$;
revoke all on function public.jdvcrm_financial_dashboard_v1(uuid,date,date) from public,anon,authenticated;
grant execute on function public.jdvcrm_financial_dashboard_v1(uuid,date,date) to authenticated;

create or replace function public.jdvcrm_financial_dashboard_by_prospecteur_v1(p_organization_id uuid,p_start_date date default null,p_end_date date default null)
returns table(prospecteur_id uuid,sales_count bigint,sales_total numeric,collected numeric,outstanding numeric,commission_total numeric,commission_paid numeric,commission_unpaid numeric)
language sql security definer set search_path=public,private as $$
 select p.id,
 coalesce((select count(*) from sales s where s.prospecteur_id=p.id and s.organization_id=p_organization_id and s.sale_date::date between coalesce(p_start_date,date_trunc('month',current_date)::date) and coalesce(p_end_date,current_date)),0),
 coalesce((select sum(case when lower(s.sale_type)='credit' then s.credit_price else s.cash_price end*s.quantity) from sales s where s.prospecteur_id=p.id and s.organization_id=p_organization_id and s.sale_date::date between coalesce(p_start_date,date_trunc('month',current_date)::date) and coalesce(p_end_date,current_date)),0),
 coalesce((select sum(x.amount) from payments x where x.prospecteur_id=p.id and x.organization_id=p_organization_id and x.status='successful' and x.payment_date::date between coalesce(p_start_date,date_trunc('month',current_date)::date) and coalesce(p_end_date,current_date)),0),
 coalesce((select sum(s.amount_remaining) from sales s where s.prospecteur_id=p.id and s.organization_id=p_organization_id and s.status not in ('cancelled','completed')),0),
 coalesce((select sum(c.commission_amount) from commissions c where c.prospecteur_id=p.id and c.organization_id=p_organization_id and c.status<>'cancelled' and c.created_at::date between coalesce(p_start_date,date_trunc('month',current_date)::date) and coalesce(p_end_date,current_date)),0),
 coalesce((select sum(c.commission_amount) from commissions c where c.prospecteur_id=p.id and c.organization_id=p_organization_id and c.status='paid' and c.paid_at::date between coalesce(p_start_date,date_trunc('month',current_date)::date) and coalesce(p_end_date,current_date)),0),
 coalesce((select sum(c.commission_amount) from commissions c where c.prospecteur_id=p.id and c.organization_id=p_organization_id and c.status in ('pending','approved')),0)
 from prospecteurs p where p.organization_id=p_organization_id and (private.is_super_admin() or private.is_org_admin(p_organization_id));
$$;
revoke all on function public.jdvcrm_financial_dashboard_by_prospecteur_v1(uuid,date,date) from public,anon,authenticated;
grant execute on function public.jdvcrm_financial_dashboard_by_prospecteur_v1(uuid,date,date) to authenticated;
