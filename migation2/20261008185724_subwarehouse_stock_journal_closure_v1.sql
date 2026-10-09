-- JDV CRM - journal et clôture par sous-entrepôt
create or replace view public.jdvcrm_subwarehouse_stock_ledger_v1
with (security_invoker=true) as
with impacts as (
  select sm.id movement_id,sm.organization_id,sm.source_subwarehouse_id subwarehouse_id,sm.article_id,sm.created_at occurred_at,
         sm.movement_type,sm.reference_type,sm.reference_id,sm.quantity::numeric quantity,0::numeric entry_quantity,sm.quantity::numeric exit_quantity,
         coalesce(sm.unit_price,a.fixed_price,a.cash_price,a.credit_price,0)::numeric unit_price,sm.created_by,sm.notes
  from public.stock_movements sm join public.articles a on a.id=sm.article_id
  where sm.source_subwarehouse_id is not null
  union all
  select sm.id,sm.organization_id,sm.destination_subwarehouse_id,sm.article_id,sm.created_at,sm.movement_type,sm.reference_type,sm.reference_id,
         sm.quantity::numeric,sm.quantity::numeric,0::numeric,coalesce(sm.unit_price,a.fixed_price,a.cash_price,a.credit_price,0)::numeric,sm.created_by,sm.notes
  from public.stock_movements sm join public.articles a on a.id=sm.article_id
  where sm.destination_subwarehouse_id is not null
), current_stock as (
  select wi.organization_id,wi.warehouse_id,wi.subwarehouse_id,wi.article_id,wi.quantity::numeric current_quantity
  from public.warehouse_inventory wi where wi.subwarehouse_id is not null
), totals as (
  select subwarehouse_id,article_id,sum(entry_quantity-exit_quantity) all_time_delta from impacts group by subwarehouse_id,article_id
), base as (
  select cs.*,greatest(cs.current_quantity-coalesce(t.all_time_delta,0),0)::numeric opening_quantity
  from current_stock cs left join totals t on t.subwarehouse_id=cs.subwarehouse_id and t.article_id=cs.article_id
), ordered as (
  select i.*,b.warehouse_id,b.opening_quantity from impacts i join base b on b.subwarehouse_id=i.subwarehouse_id and b.article_id=i.article_id
)
select o.movement_id,o.organization_id,o.warehouse_id,w.name warehouse_name,w.code warehouse_code,o.subwarehouse_id,sw.name subwarehouse_name,sw.code subwarehouse_code,
       o.article_id,a.code article_code,a.name article_name,o.occurred_at,o.movement_type,o.reference_type,o.reference_id,
       case when o.entry_quantity>0 then 'Entrée' else 'Sortie' end movement_label,o.entry_quantity,o.exit_quantity,
       o.opening_quantity+coalesce(sum(o.entry_quantity-o.exit_quantity) over(partition by o.subwarehouse_id,o.article_id order by o.occurred_at,o.movement_id rows between unbounded preceding and 1 preceding),0) stock_before,
       o.opening_quantity+sum(o.entry_quantity-o.exit_quantity) over(partition by o.subwarehouse_id,o.article_id order by o.occurred_at,o.movement_id rows unbounded preceding) stock_after,
       o.unit_price,greatest(o.entry_quantity,o.exit_quantity)*o.unit_price movement_amount,
       (o.opening_quantity+sum(o.entry_quantity-o.exit_quantity) over(partition by o.subwarehouse_id,o.article_id order by o.occurred_at,o.movement_id rows unbounded preceding))*o.unit_price stock_value_after,
       o.created_by,o.notes
from ordered o join public.warehouses w on w.id=o.warehouse_id join public.warehouse_subwarehouses sw on sw.id=o.subwarehouse_id join public.articles a on a.id=o.article_id;
revoke all on public.jdvcrm_subwarehouse_stock_ledger_v1 from anon;
grant select on public.jdvcrm_subwarehouse_stock_ledger_v1 to authenticated;

create table if not exists public.warehouse_subwarehouse_daily_closures (
 id uuid primary key default gen_random_uuid(),organization_id uuid not null references public.organizations(id) on delete restrict,
 warehouse_id uuid not null references public.warehouses(id) on delete restrict,subwarehouse_id uuid not null references public.warehouse_subwarehouses(id) on delete restrict,
 exercise_date date not null,status text not null default 'open',opening_units numeric not null default 0,total_entries numeric not null default 0,total_exits numeric not null default 0,
 closing_units numeric not null default 0,theoretical_value numeric not null default 0,physical_value numeric,variance_units numeric,variance_value numeric,movement_count integer not null default 0,
 closed_at timestamptz,closed_by uuid references auth.users(id),notes text,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
 unique(subwarehouse_id,exercise_date));
create table if not exists public.warehouse_subwarehouse_daily_closure_lines (
 id uuid primary key default gen_random_uuid(),closure_id uuid not null references public.warehouse_subwarehouse_daily_closures(id) on delete cascade,
 organization_id uuid not null references public.organizations(id) on delete restrict,warehouse_id uuid not null references public.warehouses(id) on delete restrict,
 subwarehouse_id uuid not null references public.warehouse_subwarehouses(id) on delete restrict,article_id uuid not null references public.articles(id) on delete restrict,
 opening_quantity numeric not null default 0,entry_quantity numeric not null default 0,exit_quantity numeric not null default 0,closing_quantity numeric not null default 0,unit_price numeric not null default 0,
 theoretical_value numeric not null default 0,physical_quantity numeric,variance_quantity numeric,variance_value numeric,movement_count integer not null default 0,unique(closure_id,article_id));
alter table public.warehouse_subwarehouse_daily_closures enable row level security;
alter table public.warehouse_subwarehouse_daily_closure_lines enable row level security;
revoke all on public.warehouse_subwarehouse_daily_closures,public.warehouse_subwarehouse_daily_closure_lines from anon;
grant select on public.warehouse_subwarehouse_daily_closures,public.warehouse_subwarehouse_daily_closure_lines to authenticated;
drop policy if exists subwh_closure_select on public.warehouse_subwarehouse_daily_closures;
create policy subwh_closure_select on public.warehouse_subwarehouse_daily_closures for select using (private.can_access_subwarehouse(subwarehouse_id));
drop policy if exists subwh_closure_lines_select on public.warehouse_subwarehouse_daily_closure_lines;
create policy subwh_closure_lines_select on public.warehouse_subwarehouse_daily_closure_lines for select using (private.can_access_subwarehouse(subwarehouse_id));

create or replace function public.jdvcrm_subwarehouse_daily_summary_v1(p_subwarehouse_id uuid,p_exercise_date date default ((now() at time zone 'Africa/Porto-Novo')::date))
returns table(subwarehouse_id uuid,exercise_date date,opening_units numeric,total_entries numeric,total_exits numeric,closing_units numeric,theoretical_value numeric,movement_count bigint)
language plpgsql stable security definer set search_path='' as $$
begin
 if (select auth.uid()) is null then raise exception 'Authentification requise'; end if;
 if not private.can_access_subwarehouse(p_subwarehouse_id) then raise exception 'Accès refusé à ce sous-entrepôt'; end if;
 return query with cur as (
  select coalesce(sum(wi.quantity),0)::numeric units,coalesce(sum(wi.quantity*coalesce(a.fixed_price,a.cash_price,a.credit_price,0)),0)::numeric value
  from public.warehouse_inventory wi join public.articles a on a.id=wi.article_id where wi.subwarehouse_id=p_subwarehouse_id
 ),day as (
  select coalesce(sum(l.entry_quantity),0)::numeric entries,coalesce(sum(l.exit_quantity),0)::numeric exits,count(*)::bigint movements
  from public.jdvcrm_subwarehouse_stock_ledger_v1 l where l.subwarehouse_id=p_subwarehouse_id and (l.occurred_at at time zone 'Africa/Porto-Novo')::date=p_exercise_date)
 select p_subwarehouse_id,p_exercise_date,(c.units-d.entries+d.exits),d.entries,d.exits,c.units,c.value,d.movements from cur c cross join day d;
end $$;
revoke all on function public.jdvcrm_subwarehouse_daily_summary_v1(uuid,date) from public,anon;
grant execute on function public.jdvcrm_subwarehouse_daily_summary_v1(uuid,date) to authenticated;

create or replace function public.jdvcrm_subwarehouse_close_day_v1(p_subwarehouse_id uuid,p_exercise_date date default ((now() at time zone 'Africa/Porto-Novo')::date),p_physical_counts jsonb default '[]'::jsonb,p_notes text default null)
returns jsonb language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=(select auth.uid());v_org uuid;v_wh uuid;v_id uuid;v_sum record;v_line record;v_ph numeric;v_phys_value numeric:=0;v_var numeric:=0;v_var_value numeric:=0;
begin
 if v_uid is null then raise exception 'Authentification requise'; end if;
 if not private.can_access_subwarehouse(p_subwarehouse_id) then raise exception 'Accès refusé à ce sous-entrepôt'; end if;
 select organization_id,parent_warehouse_id into v_org,v_wh from public.warehouse_subwarehouses where id=p_subwarehouse_id and active=true;
 if v_org is null then raise exception 'Sous-entrepôt introuvable ou inactif'; end if;
 select * into v_sum from public.jdvcrm_subwarehouse_daily_summary_v1(p_subwarehouse_id,p_exercise_date);
 select id into v_id from public.warehouse_subwarehouse_daily_closures where subwarehouse_id=p_subwarehouse_id and exercise_date=p_exercise_date for update;
 if v_id is not null and exists(select 1 from public.warehouse_subwarehouse_daily_closures where id=v_id and status='closed') then raise exception 'Cette journée est déjà clôturée'; end if;
 if v_id is null then insert into public.warehouse_subwarehouse_daily_closures(organization_id,warehouse_id,subwarehouse_id,exercise_date,status) values(v_org,v_wh,p_subwarehouse_id,p_exercise_date,'open') returning id into v_id; end if;
 delete from public.warehouse_subwarehouse_daily_closure_lines where closure_id=v_id;
 for v_line in select l.article_id,max(l.stock_before) opening_quantity,coalesce(sum(l.entry_quantity),0) entry_quantity,coalesce(sum(l.exit_quantity),0) exit_quantity,max(l.stock_after) closing_quantity,max(l.unit_price) unit_price,count(*)::integer movement_count
 from public.jdvcrm_subwarehouse_stock_ledger_v1 l where l.subwarehouse_id=p_subwarehouse_id and (l.occurred_at at time zone 'Africa/Porto-Novo')::date=p_exercise_date group by l.article_id loop
  v_ph:=null;
  if jsonb_typeof(p_physical_counts)='array' then select x.physical_quantity::numeric into v_ph from jsonb_to_recordset(p_physical_counts) x(article_id uuid,physical_quantity numeric) where x.article_id=v_line.article_id limit 1; end if;
  insert into public.warehouse_subwarehouse_daily_closure_lines(closure_id,organization_id,warehouse_id,subwarehouse_id,article_id,opening_quantity,entry_quantity,exit_quantity,closing_quantity,unit_price,theoretical_value,physical_quantity,variance_quantity,variance_value,movement_count)
  values(v_id,v_org,v_wh,p_subwarehouse_id,v_line.article_id,coalesce(v_line.opening_quantity,0),v_line.entry_quantity,v_line.exit_quantity,coalesce(v_line.closing_quantity,0),coalesce(v_line.unit_price,0),coalesce(v_line.closing_quantity,0)*coalesce(v_line.unit_price,0),v_ph,case when v_ph is null then null else v_ph-coalesce(v_line.closing_quantity,0) end,case when v_ph is null then null else (v_ph-coalesce(v_line.closing_quantity,0))*coalesce(v_line.unit_price,0) end,v_line.movement_count);
  if v_ph is not null then v_phys_value:=v_phys_value+v_ph*coalesce(v_line.unit_price,0);v_var:=v_var+(v_ph-coalesce(v_line.closing_quantity,0));v_var_value:=v_var_value+(v_ph-coalesce(v_line.closing_quantity,0))*coalesce(v_line.unit_price,0);end if;
 end loop;
 update public.warehouse_subwarehouse_daily_closures set status='closed',closed_at=now(),closed_by=v_uid,opening_units=v_sum.opening_units,total_entries=v_sum.total_entries,total_exits=v_sum.total_exits,closing_units=v_sum.closing_units,theoretical_value=v_sum.theoretical_value,physical_value=case when jsonb_array_length(coalesce(p_physical_counts,'[]'::jsonb))>0 then v_phys_value end,variance_units=case when jsonb_array_length(coalesce(p_physical_counts,'[]'::jsonb))>0 then v_var end,variance_value=case when jsonb_array_length(coalesce(p_physical_counts,'[]'::jsonb))>0 then v_var_value end,movement_count=v_sum.movement_count::integer,notes=nullif(trim(p_notes),''),updated_at=now() where id=v_id;
 return jsonb_build_object('closure_id',v_id,'subwarehouse_id',p_subwarehouse_id,'exercise_date',p_exercise_date,'status','closed','opening_units',v_sum.opening_units,'entries',v_sum.total_entries,'exits',v_sum.total_exits,'closing_units',v_sum.closing_units,'theoretical_value',v_sum.theoretical_value,'physical_value',case when jsonb_array_length(coalesce(p_physical_counts,'[]'::jsonb))>0 then v_phys_value end,'variance_units',case when jsonb_array_length(coalesce(p_physical_counts,'[]'::jsonb))>0 then v_var end,'variance_value',case when jsonb_array_length(coalesce(p_physical_counts,'[]'::jsonb))>0 then v_var_value end,'movement_count',v_sum.movement_count);
end $$;
revoke all on function public.jdvcrm_subwarehouse_close_day_v1(uuid,date,jsonb,text) from public,anon;
grant execute on function public.jdvcrm_subwarehouse_close_day_v1(uuid,date,jsonb,text) to authenticated;