-- JDV GLOBAL CENTER: CRM RPC compatibility layer.
-- Tables are provisioned by the additive schema migration; shared GLOBAL tables are not replaced.
-- All privileged RPCs require an authenticated caller and explicit organization authorization.

create or replace function public.is_org_manager(org_id uuid)
returns boolean language sql stable security definer set search_path=pg_catalog,public
as $function$
 select exists (
  select 1 from public.organization_members om
  join public.roles r on r.id=om.role_id
  where om.organization_id=org_id and om.user_id=auth.uid()
    and om.member_status='active' and r.code in ('owner','admin','manager','accountant')
 );
$function$;
revoke all on function public.is_org_manager(uuid) from public,anon;
grant execute on function public.is_org_manager(uuid) to authenticated;

create or replace function public.jdvcrm_get_concepteur_workspace_v1()
returns table(branch_code text)
language sql stable security definer set search_path=pg_catalog,public
as $function$
 select 'concepteur'::text
 where auth.uid() is not null and exists (
  select 1 from public.super_admins sa
  where sa.user_id=auth.uid() and sa.admin_status='active'::public.super_admin_status
 );
$function$;
revoke all on function public.jdvcrm_get_concepteur_workspace_v1() from public,anon;
grant execute on function public.jdvcrm_get_concepteur_workspace_v1() to authenticated;

create or replace function public.jdvcrm_get_business_access_v1(p_organization_id uuid default null)
returns jsonb language plpgsql stable security definer set search_path=pg_catalog,public
as $function$
declare v_sub record;
begin
 if auth.uid() is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
 if public.is_super_admin() then
  return jsonb_build_object('organization_id',p_organization_id,'is_super_admin',true,'is_admin',coalesce(public.is_org_admin(p_organization_id),false),'is_member',coalesce(public.is_org_member(p_organization_id),false),'business_access',true,'unlimited',true,'reason','SUPER_ADMIN_UNLIMITED');
 end if;
 if p_organization_id is null then return jsonb_build_object('organization_id',null,'is_super_admin',false,'is_admin',false,'is_member',false,'business_access',false,'unlimited',false,'reason','ORGANIZATION_REQUIRED'); end if;
 if not public.is_org_member(p_organization_id) then return jsonb_build_object('organization_id',p_organization_id,'is_super_admin',false,'is_admin',false,'is_member',false,'business_access',false,'unlimited',false,'reason','ORGANIZATION_ACCESS_REQUIRED'); end if;
 select os.status,os.started_at,os.expires_at,sp.code plan_code,sp.name plan_name into v_sub
 from public.organization_subscriptions os join public.subscription_plans sp on sp.id=os.plan_id
 where os.organization_id=p_organization_id and os.status in ('trial','active','past_due') and (os.expires_at is null or os.expires_at>now())
 order by case os.status when 'active' then 1 when 'trial' then 2 else 3 end,os.expires_at desc nulls last limit 1;
 if v_sub is null then return jsonb_build_object('organization_id',p_organization_id,'is_super_admin',false,'is_admin',public.is_org_admin(p_organization_id),'is_member',true,'business_access',false,'unlimited',false,'reason','SUBSCRIPTION_REQUIRED'); end if;
 return jsonb_build_object('organization_id',p_organization_id,'is_super_admin',false,'is_admin',public.is_org_admin(p_organization_id),'is_member',true,'business_access',true,'unlimited',false,'subscription_status',v_sub.status,'plan_code',v_sub.plan_code,'plan_name',v_sub.plan_name,'expires_at',v_sub.expires_at,'reason','SUBSCRIPTION_ACTIVE');
end $function$;

create or replace function public.jdvcrm_get_current_subscription_v1(p_organization_id uuid)
returns table(subscription_id uuid,organization_id uuid,plan_id uuid,plan_code text,plan_name text,status text,started_at timestamptz,expires_at timestamptz,auto_renew boolean,is_effectively_active boolean)
language plpgsql stable security definer set search_path=pg_catalog,public
as $function$
begin
 if auth.uid() is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
 if not public.is_super_admin() and not public.is_org_admin(p_organization_id) then raise exception 'ACCESS_DENIED'; end if;
 return query select os.id,os.organization_id,os.plan_id,sp.code,sp.name,
 case when os.status in ('trial','active','past_due') and (os.expires_at is null or os.expires_at>now()) then os.status when os.status in ('trial','active','past_due') and os.expires_at<=now() then 'expired' else os.status end,
 os.started_at,os.expires_at,os.auto_renew,(os.status in ('trial','active','past_due') and (os.expires_at is null or os.expires_at>now()))
 from public.organization_subscriptions os join public.subscription_plans sp on sp.id=os.plan_id
 where os.organization_id=p_organization_id
 order by case os.status when 'active' then 1 when 'trial' then 2 when 'past_due' then 3 when 'pending' then 4 else 5 end,coalesce(os.expires_at,'infinity'::timestamptz) desc limit 1;
end $function$;

create or replace function public.jdvcrm_report_sales_v1(p_organization_id uuid,p_start_date date,p_end_date date)
returns table(sale_date date,sale_number text,client_id uuid,prospecteur_id uuid,sale_type text,status text,quantity numeric,total_amount numeric,amount_paid numeric,amount_remaining numeric)
language sql stable security definer set search_path=pg_catalog,public
as $function$
 select s.sale_date::date,s.sale_number,s.client_id,s.prospecteur_id,s.sale_type,s.status,s.quantity::numeric,
 (case when lower(s.sale_type)='credit' then s.credit_price else s.cash_price end*s.quantity)::numeric,s.amount_paid,s.amount_remaining
 from public.sales s where s.organization_id=p_organization_id and s.sale_date::date between p_start_date and p_end_date
 and (public.is_super_admin() or public.is_org_admin(p_organization_id)) order by s.sale_date desc
$function$;
create or replace function public.jdvcrm_report_payments_v1(p_organization_id uuid,p_start_date date,p_end_date date)
returns table(payment_date date,payment_id uuid,sale_id uuid,client_id uuid,prospecteur_id uuid,amount numeric,currency text,payment_method text,provider text,status text)
language sql stable security definer set search_path=pg_catalog,public
as $function$
 select p.payment_date::date,p.id,p.sale_id,p.client_id,p.prospecteur_id,p.amount,p.currency,p.payment_method,p.provider,p.status
 from public.payments p where p.organization_id=p_organization_id and p.payment_date::date between p_start_date and p_end_date
 and (public.is_super_admin() or public.is_org_admin(p_organization_id)) order by p.payment_date desc
$function$;
create or replace function public.jdvcrm_report_commissions_v1(p_organization_id uuid,p_start_date date,p_end_date date)
returns table(commission_id uuid,prospecteur_id uuid,sale_id uuid,article_id uuid,rate numeric,base_amount numeric,commission_amount numeric,status text,paid_at timestamptz)
language sql stable security definer set search_path=pg_catalog,public
as $function$
 select c.id,c.prospecteur_id,c.sale_id,c.article_id,c.commission_rate,c.base_amount,c.commission_amount,c.status,c.paid_at
 from public.commissions c where c.organization_id=p_organization_id and c.created_at::date between p_start_date and p_end_date
 and (public.is_super_admin() or public.is_org_admin(p_organization_id)) order by c.created_at desc
$function$;
create or replace function public.jdvcrm_report_overdue_v1(p_organization_id uuid)
returns table(schedule_id uuid,sale_id uuid,client_id uuid,due_date date,expected_amount numeric,paid_amount numeric,remaining_amount numeric,status text,days_late integer)
language sql stable security definer set search_path=pg_catalog,public
as $function$
 select ps.id,ps.sale_id,s.client_id,ps.due_date,ps.expected_amount,ps.paid_amount,greatest(ps.expected_amount-ps.paid_amount,0),ps.status,greatest(current_date-ps.due_date,0)::integer
 from public.payment_schedules ps join public.sales s on s.id=ps.sale_id
 where ps.organization_id=p_organization_id and ps.status in ('late','partial','pending') and ps.paid_amount<ps.expected_amount
 and (public.is_super_admin() or public.is_org_admin(p_organization_id)) order by ps.due_date
$function$;

create or replace function public.jdvcrm_financial_dashboard_v1(p_organization_id uuid,p_start_date date default null,p_end_date date default null)
returns jsonb language plpgsql stable security definer set search_path=pg_catalog,public
as $function$
declare v_start date:=coalesce(p_start_date,date_trunc('month',current_date)::date); v_end date:=coalesce(p_end_date,current_date);
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 if not (public.is_super_admin() or public.is_org_admin(p_organization_id)) then raise exception 'Accès refusé'; end if;
 if v_end<v_start then raise exception 'Période invalide'; end if;
 return jsonb_build_object('period_start',v_start,'period_end',v_end,
 'sales_count',(select count(*) from public.sales s where s.organization_id=p_organization_id and s.sale_date::date between v_start and v_end),
 'sales_total',coalesce((select sum((case when lower(s.sale_type)='credit' then s.credit_price else s.cash_price end)*s.quantity) from public.sales s where s.organization_id=p_organization_id and s.sale_date::date between v_start and v_end),0),
 'cash_collected',coalesce((select sum(p.amount) from public.payments p where p.organization_id=p_organization_id and p.status='successful' and p.payment_date::date between v_start and v_end),0),
 'credit_outstanding',coalesce((select sum(s.amount_remaining) from public.sales s where s.organization_id=p_organization_id and s.status not in ('cancelled','completed') and lower(s.sale_type)='credit'),0),
 'overdue_amount',coalesce((select sum(greatest(ps.expected_amount-ps.paid_amount,0)) from public.payment_schedules ps where ps.organization_id=p_organization_id and ps.status in ('late','partial') and ps.paid_amount<ps.expected_amount),0),
 'overdue_schedules',(select count(*) from public.payment_schedules ps where ps.organization_id=p_organization_id and ps.status in ('late','partial') and ps.paid_amount<ps.expected_amount),
 'commission_total',coalesce((select sum(c.commission_amount) from public.commissions c where c.organization_id=p_organization_id and c.created_at::date between v_start and v_end and c.status<>'cancelled'),0),
 'commission_unpaid',coalesce((select sum(c.commission_amount) from public.commissions c where c.organization_id=p_organization_id and c.status in ('pending','approved')),0),
 'commission_paid',coalesce((select sum(c.commission_amount) from public.commissions c where c.organization_id=p_organization_id and c.status='paid' and c.paid_at::date between v_start and v_end),0));
end $function$;

create or replace function public.jdvcrm_ensure_my_portfolio_v1(p_organization_id uuid)
returns uuid language plpgsql security definer set search_path=pg_catalog,public
as $function$
declare v_id uuid; v_type text;
begin
 if auth.uid() is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
 if public.is_super_admin() then v_type:='super_admin';
 elsif exists(select 1 from public.prospecteurs p where p.organization_id=p_organization_id and p.user_id=auth.uid() and p.status='active') then v_type:='prospecteur';
 else raise exception 'ACCESS_DENIED'; end if;
 select cp.id into v_id from public.client_portfolios cp where cp.organization_id=p_organization_id and cp.owner_user_id=auth.uid() and cp.status='active' order by cp.created_at limit 1;
 if v_id is null then insert into public.client_portfolios(organization_id,owner_user_id,owner_type,name) values(p_organization_id,auth.uid(),v_type,case when v_type='super_admin' then 'Portefeuille concepteur' else 'Mon portefeuille clients' end) returning id into v_id; end if;
 return v_id;
end $function$;

create or replace function public.jdvcrm_convert_prospect_to_client_v1(p_prospect_id uuid)
returns uuid language plpgsql security definer set search_path=pg_catalog,public
as $function$
declare pr public.prospects%rowtype; v_client uuid; v_portfolio uuid;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 select * into pr from public.prospects where id=p_prospect_id for update;
 if not found then raise exception 'Prospect introuvable'; end if;
 if not (public.is_super_admin() or public.is_org_admin(pr.organization_id) or exists(select 1 from public.prospecteurs p where p.id=pr.prospecteur_id and p.organization_id=pr.organization_id and p.user_id=auth.uid() and p.status='active')) then raise exception 'Accès refusé'; end if;
 if pr.client_id is not null then return pr.client_id; end if;
 v_portfolio:=pr.portfolio_id;
 if v_portfolio is null then select cp.id into v_portfolio from public.client_portfolios cp join public.prospecteurs p on p.user_id=cp.owner_user_id where p.id=pr.prospecteur_id and cp.organization_id=pr.organization_id and cp.status='active' order by cp.created_at limit 1; end if;
 insert into public.clients(organization_id,prospecteur_id,portfolio_id,code,first_name,last_name,phone,whatsapp,address,city,status,temperature,notes,last_contact_at,last_activity_at)
 values(pr.organization_id,pr.prospecteur_id,v_portfolio,'CLI-'||upper(substr(gen_random_uuid()::text,1,8)),pr.first_name,pr.last_name,pr.phone,pr.whatsapp,pr.address,pr.city,'active',pr.temperature,pr.notes,coalesce(pr.last_contact_at,now()),now())
 returning id into v_client;
 update public.prospects set client_id=v_client,status='converted',updated_at=now() where id=pr.id;
 return v_client;
end $function$;

revoke all on function public.jdvcrm_get_business_access_v1(uuid) from public,anon;
revoke all on function public.jdvcrm_get_current_subscription_v1(uuid) from public,anon;
revoke all on function public.jdvcrm_report_sales_v1(uuid,date,date) from public,anon;
revoke all on function public.jdvcrm_report_payments_v1(uuid,date,date) from public,anon;
revoke all on function public.jdvcrm_report_commissions_v1(uuid,date,date) from public,anon;
revoke all on function public.jdvcrm_report_overdue_v1(uuid) from public,anon;
revoke all on function public.jdvcrm_financial_dashboard_v1(uuid,date,date) from public,anon;
revoke all on function public.jdvcrm_ensure_my_portfolio_v1(uuid) from public,anon;
revoke all on function public.jdvcrm_convert_prospect_to_client_v1(uuid) from public,anon;
grant execute on function public.jdvcrm_get_business_access_v1(uuid) to authenticated;
grant execute on function public.jdvcrm_get_current_subscription_v1(uuid) to authenticated;
grant execute on function public.jdvcrm_report_sales_v1(uuid,date,date) to authenticated;
grant execute on function public.jdvcrm_report_payments_v1(uuid,date,date) to authenticated;
grant execute on function public.jdvcrm_report_commissions_v1(uuid,date,date) to authenticated;
grant execute on function public.jdvcrm_report_overdue_v1(uuid) to authenticated;
grant execute on function public.jdvcrm_financial_dashboard_v1(uuid,date,date) to authenticated;
grant execute on function public.jdvcrm_ensure_my_portfolio_v1(uuid) to authenticated;
grant execute on function public.jdvcrm_convert_prospect_to_client_v1(uuid) to authenticated;
