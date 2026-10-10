
-- Core CRM activation data; no changes to existing GLOBAL organizations or modules.
create or replace function public.jdvcrm_set_updated_at()
returns trigger language plpgsql set search_path=pg_catalog,public
as $function$ begin new.updated_at:=now(); return new; end $function$;
revoke all on function public.jdvcrm_set_updated_at() from public,anon;
grant execute on function public.jdvcrm_set_updated_at() to authenticated;

do $triggers$
declare r record;
begin
 for r in
  select c.table_name
  from information_schema.columns c
  where c.table_schema='public' and c.column_name='updated_at'
    and c.table_name in ('article_categories','article_serial_assignments','articles','call_center_tasks','client_portfolios','clients','commissions','company_settings','documents','field_visits','goods_receipts','organization_personalization','organization_settings','organization_subscriptions','payment_schedules','payments','prospect_activities','prospect_assignments','prospect_followups','prospecteurs','prospects','purchase_orders','sale_items','sales','serial_numbers','stock_transfers','stocks','subscription_plans','subscription_payments','super_admin_modules','suppliers','user_settings','warehouse_inventory','warehouses')
 loop
  if not exists(select 1 from pg_trigger where tgname='trg_jdvcrm_updated_at' and tgrelid=format('public.%I',r.table_name)::regclass) then
   execute format('create trigger trg_jdvcrm_updated_at before update on public.%I for each row execute function public.jdvcrm_set_updated_at()',r.table_name);
  end if;
 end loop;
end $triggers$;

create or replace function public.jdvcrm_sync_payment_totals_v1()
returns trigger language plpgsql security definer set search_path=pg_catalog,public
as $function$
declare v_sale_id uuid; v_schedule_id uuid; v_total numeric(14,2); v_paid numeric(14,2); v_due numeric(14,2); r record;
begin
 if tg_op='DELETE' then v_sale_id:=old.sale_id; v_schedule_id:=old.schedule_id;
 else v_sale_id:=new.sale_id; v_schedule_id:=new.schedule_id; end if;

 if v_schedule_id is not null then
  select ps.expected_amount into v_due from public.payment_schedules ps where ps.id=v_schedule_id;
  if found then
   select least(v_due,coalesce(sum(p.amount),0)) into v_paid from public.payments p where p.schedule_id=v_schedule_id and p.status='successful';
   update public.payment_schedules
    set paid_amount=v_paid,
        status=case when v_paid>=expected_amount then 'paid' when v_paid>0 then 'partial' when due_date<current_date then 'late' else 'pending' end,
        paid_at=case when v_paid>=expected_amount then coalesce(paid_at,now()) else null end,
        updated_at=now()
    where id=v_schedule_id;
  end if;
 end if;

 if v_sale_id is not null then
  select (case when lower(s.sale_type)='credit' then s.credit_price else s.cash_price end * s.quantity)::numeric(14,2)
   into v_total from public.sales s where s.id=v_sale_id;
  if found then
   select coalesce(sum(p.amount),0)::numeric(14,2) into v_paid from public.payments p where p.sale_id=v_sale_id and p.status='successful';
   update public.sales set amount_paid=v_paid,amount_remaining=greatest(v_total-v_paid,0),
    status=case when v_total>0 and v_paid>=v_total then 'completed' when status='completed' and v_paid<v_total then 'active' else status end,
    completed_at=case when v_total>0 and v_paid>=v_total then coalesce(completed_at,now()) when v_paid<v_total then null else completed_at end,
    updated_at=now()
   where id=v_sale_id;
   update public.clients c set last_payment_at=(select max(p.payment_date) from public.payments p where p.client_id=c.id and p.status='successful'),
    last_activity_at=now(),updated_at=now()
   where c.id=(select s.client_id from public.sales s where s.id=v_sale_id);
  end if;
 end if;

 if tg_op='DELETE' then return old; else return new; end if;
end $function$;
revoke all on function public.jdvcrm_sync_payment_totals_v1() from public,anon;
grant execute on function public.jdvcrm_sync_payment_totals_v1() to authenticated;
do $payment_trigger$
begin
 if not exists(select 1 from pg_trigger where tgname='trg_jdvcrm_sync_payment_totals' and tgrelid='public.payments'::regclass) then
  create trigger trg_jdvcrm_sync_payment_totals after insert or update or delete on public.payments for each row execute function public.jdvcrm_sync_payment_totals_v1();
 end if;
end $payment_trigger$;

create or replace function public.jdvcrm_after_sale_v1()
returns trigger language plpgsql security definer set search_path=pg_catalog,public
as $function$
declare v_total numeric(14,2); v_rate numeric(8,2); v_stock integer; v_freq text; v_due date; v_amount numeric(14,2); v_n integer; i integer; v_expected numeric(14,2);
begin
 v_total:=case when lower(new.sale_type)='credit' then new.credit_price else new.cash_price end*new.quantity;
 if new.prospecteur_id is not null then
  select coalesce(p.commission_rate,0) into v_rate from public.prospecteurs p where p.id=new.prospecteur_id and p.organization_id=new.organization_id;
  if coalesce(v_rate,0)>0 then
   if exists(select 1 from public.commissions c where c.sale_id=new.id and c.prospecteur_id=new.prospecteur_id and c.status in ('pending','approved')) then
    update public.commissions set article_id=new.article_id,commission_rate=v_rate,base_amount=v_total,commission_amount=round(v_total*v_rate/100,2),updated_at=now()
     where sale_id=new.id and prospecteur_id=new.prospecteur_id and status in ('pending','approved');
   elsif not exists(select 1 from public.commissions c where c.sale_id=new.id and c.prospecteur_id=new.prospecteur_id) then
    insert into public.commissions(organization_id,prospecteur_id,sale_id,article_id,commission_rate,base_amount,commission_amount,status)
    values(new.organization_id,new.prospecteur_id,new.id,new.article_id,v_rate,v_total,round(v_total*v_rate/100,2),'pending');
   end if;
  end if;
 end if;

 if new.article_id is not null then
  select st.quantity into v_stock from public.stocks st where st.organization_id=new.organization_id and st.article_id=new.article_id for update;
  if found then
   if v_stock < new.quantity then raise exception 'Stock insuffisant pour l''article %',new.article_id; end if;
   update public.stocks set quantity=quantity-new.quantity,updated_at=now() where organization_id=new.organization_id and article_id=new.article_id;
   insert into public.stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,notes,created_by)
   values(new.organization_id,new.article_id,new.prospecteur_id,'sale',new.quantity,'sale',new.id,'Sortie automatique après vente',auth.uid());
  end if;
 end if;

 if lower(new.sale_type)='credit' and new.payment_amount>0 and v_total>new.amount_paid and not exists(select 1 from public.payment_schedules ps where ps.sale_id=new.id) then
  v_amount:=new.payment_amount;
  v_n:=ceil((v_total-new.amount_paid)/v_amount)::integer;
  v_freq:=coalesce(new.payment_frequency,'monthly');
  for i in 1..least(v_n,1000) loop
   v_expected:=least(v_amount,v_total-new.amount_paid-v_amount*(i-1));
   if v_expected<=0 then exit; end if;
   v_due:=coalesce(new.deadline_date,new.sale_date::date)+case v_freq
    when 'daily' then i
    when 'weekly' then i*7
    when 'biweekly' then i*14
    when 'quarterly' then i*90
    when 'monthly' then i*30
    else i*30 end;
   insert into public.payment_schedules(organization_id,sale_id,installment_number,due_date,expected_amount,paid_amount,status)
   values(new.organization_id,new.id,i,v_due,v_expected,0,case when v_due<current_date then 'late' else 'pending' end)
   on conflict (sale_id,installment_number) do nothing;
  end loop;
 end if;
 return new;
end $function$;
revoke all on function public.jdvcrm_after_sale_v1() from public,anon;
grant execute on function public.jdvcrm_after_sale_v1() to authenticated;
do $sale_trigger$
begin
 if not exists(select 1 from pg_trigger where tgname='trg_jdvcrm_after_sale' and tgrelid='public.sales'::regclass) then
  create trigger trg_jdvcrm_after_sale after insert on public.sales for each row execute function public.jdvcrm_after_sale_v1();
 end if;
end $sale_trigger$;

insert into public.subscription_plans(code,name,description,price,currency,duration_days,features,active)
select v.code,v.name,v.description,v.price,'USD',v.duration_days,v.features,true
from (values
 ('mensuel','Mensuel','Abonnement JDV CRM de 30 jours',50::numeric,30,jsonb_build_object('crm',true,'trial_days',14)),
 ('trimestriel','Trimestriel','Abonnement JDV CRM de 90 jours',150::numeric,90,jsonb_build_object('crm',true,'trial_days',14)),
 ('semestriel','Semestriel','Abonnement JDV CRM de 180 jours',300::numeric,180,jsonb_build_object('crm',true,'trial_days',14)),
 ('annuel','Annuel','Abonnement JDV CRM de 365 jours',600::numeric,365,jsonb_build_object('crm',true,'trial_days',14))
) as v(code,name,description,price,duration_days,features)
where not exists(select 1 from public.subscription_plans p where p.code=v.code);

insert into public.super_admin_modules(user_id,module_code,module_name,enabled,subscription_required)
select sa.user_id,'crm','JDV CRM',true,false
from public.super_admins sa
where sa.admin_status='active'::public.super_admin_status
and not exists(select 1 from public.super_admin_modules m where m.user_id=sa.user_id and m.module_code='crm');

do $org$
declare v_user uuid; v_org uuid; v_role uuid;
begin
 select sa.user_id into v_user from public.super_admins sa where sa.admin_status='active'::public.super_admin_status order by sa.created_at desc limit 1;
 if v_user is null then raise exception 'Aucun concepteur actif'; end if;
 select id into v_role from public.roles where code='owner' limit 1;
 if v_role is null then raise exception 'Rôle owner introuvable'; end if;
 select id into v_org from public.organizations where slug='jdv-crm-concepteur';
 if v_org is null then
  insert into public.organizations(name,slug,org_type,org_status,owner_id) values('JDV CRM - Concepteur','jdv-crm-concepteur','company','active',v_user) returning id into v_org;
 else
  update public.organizations set owner_id=v_user,org_status='active',updated_at=now() where id=v_org;
 end if;
 if exists(select 1 from public.organization_members where organization_id=v_org and user_id=v_user) then
  update public.organization_members set role_id=v_role,member_status='active',updated_at=now() where organization_id=v_org and user_id=v_user;
 else
  insert into public.organization_members(organization_id,user_id,role_id,member_status,joined_at) values(v_org,v_user,v_role,'active',now());
 end if;
end $org$;


drop policy if exists jdv_global_crm_prospecteur_insert on public.prospects;
create policy jdv_global_crm_prospecteur_insert on public.prospects for insert to authenticated
with check (public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospecteur_id and p.organization_id=prospects.organization_id and p.user_id=auth.uid() and p.status='active'));
drop policy if exists jdv_global_crm_prospecteur_update on public.prospects;
create policy jdv_global_crm_prospecteur_update on public.prospects for update to authenticated
using (public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospecteur_id and p.organization_id=prospects.organization_id and p.user_id=auth.uid() and p.status='active'))
with check (public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospecteur_id and p.organization_id=prospects.organization_id and p.user_id=auth.uid() and p.status='active'));
drop policy if exists jdv_global_crm_prospecteur_insert on public.clients;
create policy jdv_global_crm_prospecteur_insert on public.clients for insert to authenticated
with check (public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospecteur_id and p.organization_id=clients.organization_id and p.user_id=auth.uid() and p.status='active'));
drop policy if exists jdv_global_crm_prospecteur_update on public.clients;
create policy jdv_global_crm_prospecteur_update on public.clients for update to authenticated
using (public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospecteur_id and p.organization_id=clients.organization_id and p.user_id=auth.uid() and p.status='active'))
with check (public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospecteur_id and p.organization_id=clients.organization_id and p.user_id=auth.uid() and p.status='active'));
drop policy if exists jdv_global_crm_prospecteur_insert on public.field_visits;
create policy jdv_global_crm_prospecteur_insert on public.field_visits for insert to authenticated
with check (public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospecteur_id and p.organization_id=field_visits.organization_id and p.user_id=auth.uid() and p.status='active'));
drop policy if exists jdv_global_crm_prospecteur_insert on public.prospect_activities;
create policy jdv_global_crm_prospecteur_insert on public.prospect_activities for insert to authenticated
with check (public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospecteur_id and p.organization_id=prospect_activities.organization_id and p.user_id=auth.uid() and p.status='active'));
drop policy if exists jdv_global_crm_prospecteur_insert on public.sales;
create policy jdv_global_crm_prospecteur_insert on public.sales for insert to authenticated
with check (public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospecteur_id and p.organization_id=sales.organization_id and p.user_id=auth.uid() and p.status='active'));
drop policy if exists jdv_global_crm_prospecteur_insert on public.payments;
create policy jdv_global_crm_prospecteur_insert on public.payments for insert to authenticated
with check (public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospecteur_id and p.organization_id=payments.organization_id and p.user_id=auth.uid() and p.status='active'));


-- Generate identifiers server-side when forms omit them.
create or replace function public.jdvcrm_generate_entity_code_v1()
returns trigger language plpgsql set search_path=pg_catalog,public
as $function$
begin
 if tg_table_name='clients' and nullif(trim(new.code),'') is null then
  new.code:='CLI-'||to_char(now(),'YYYYMMDD')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,6));
 elsif tg_table_name='prospecteurs' and nullif(trim(new.code),'') is null then
  new.code:='PRO-'||to_char(now(),'YYYYMMDD')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,6));
 elsif tg_table_name='articles' and nullif(trim(new.code),'') is null then
  new.code:='ART-'||to_char(now(),'YYYYMMDD')||'-'||upper(substr(replace(gen_random_uuid()::text,'-',''),1,6));
 end if;
 return new;
end $function$;
revoke all on function public.jdvcrm_generate_entity_code_v1() from public,anon;
grant execute on function public.jdvcrm_generate_entity_code_v1() to authenticated;
do $codes$
begin
 if not exists(select 1 from pg_trigger where tgname='trg_jdvcrm_generate_client_code' and tgrelid='public.clients'::regclass) then
  create trigger trg_jdvcrm_generate_client_code before insert on public.clients for each row execute function public.jdvcrm_generate_entity_code_v1();
 end if;
 if not exists(select 1 from pg_trigger where tgname='trg_jdvcrm_generate_prospecteur_code' and tgrelid='public.prospecteurs'::regclass) then
  create trigger trg_jdvcrm_generate_prospecteur_code before insert on public.prospecteurs for each row execute function public.jdvcrm_generate_entity_code_v1();
 end if;
 if not exists(select 1 from pg_trigger where tgname='trg_jdvcrm_generate_article_code' and tgrelid='public.articles'::regclass) then
  create trigger trg_jdvcrm_generate_article_code before insert on public.articles for each row execute function public.jdvcrm_generate_entity_code_v1();
 end if;
end $codes$;
