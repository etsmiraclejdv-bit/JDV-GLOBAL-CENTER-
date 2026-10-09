-- Traçabilité complète des retours : agent/prospecteur, date/heure, article, emplacement et réception
alter table public.sales_returns
  add column if not exists returned_by_user_id uuid references auth.users(id) on delete set null,
  add column if not exists returned_by_name text,
  add column if not exists returned_by_role text,
  add column if not exists warehouse_id uuid references public.warehouses(id) on delete restrict,
  add column if not exists subwarehouse_id uuid references public.warehouse_subwarehouses(id) on delete restrict,
  add column if not exists received_by_user_id uuid references auth.users(id) on delete set null,
  add column if not exists received_at timestamptz;
alter table public.sales_return_items
  add column if not exists article_code_snapshot text,
  add column if not exists article_name_snapshot text;
create index if not exists idx_sales_returns_returned_by_user on public.sales_returns(returned_by_user_id);
create index if not exists idx_sales_returns_warehouse on public.sales_returns(warehouse_id,return_date desc);
create index if not exists idx_sales_returns_subwarehouse on public.sales_returns(subwarehouse_id,return_date desc);

create or replace function public.jdvcrm_return_trace_guard_v1()
returns trigger language plpgsql security definer set search_path='' as $$
declare v_sale_org uuid;v_wh_org uuid;v_sub_org uuid;v_sub_parent uuid;v_name text;
begin
 select s.organization_id into v_sale_org from public.sales s where s.id=new.sale_id;
 if v_sale_org is null then raise exception 'Vente introuvable'; end if;
 new.organization_id:=v_sale_org;
 if new.returned_by_user_id is null then new.returned_by_user_id:=new.created_by; end if;
 if new.returned_by_user_id is not null then
   select coalesce(trim(concat(p.first_name,' ',p.last_name)),p.display_name) into v_name from public.profiles p where p.id=new.returned_by_user_id;
   if v_name is null then select email into v_name from auth.users where id=new.returned_by_user_id; end if;
   new.returned_by_name:=coalesce(new.returned_by_name,v_name);
 end if;
 if new.warehouse_id is not null then
   select organization_id into v_wh_org from public.warehouses where id=new.warehouse_id and active=true;
   if v_wh_org is distinct from v_sale_org then raise exception 'Entrepôt incompatible avec la vente'; end if;
 end if;
 if new.subwarehouse_id is not null then
   select organization_id,parent_warehouse_id into v_sub_org,v_sub_parent from public.warehouse_subwarehouses where id=new.subwarehouse_id and active=true;
   if v_sub_org is distinct from v_sale_org then raise exception 'Sous-entrepôt incompatible avec la vente'; end if;
   if new.warehouse_id is null then new.warehouse_id:=v_sub_parent;
   elsif new.warehouse_id is distinct from v_sub_parent then raise exception 'Sous-entrepôt rattaché à un autre entrepôt'; end if;
 end if;
 if new.received_by_user_id is not null and new.received_at is null then new.received_at:=now(); end if;
 return new;
end $$;
revoke all on function public.jdvcrm_return_trace_guard_v1() from public,anon,authenticated;
drop trigger if exists trg_jdvcrm_return_trace_guard on public.sales_returns;
create trigger trg_jdvcrm_return_trace_guard before insert or update on public.sales_returns for each row execute function public.jdvcrm_return_trace_guard_v1();

drop view if exists public.jdvcrm_returns_traceability_v1;
create view public.jdvcrm_returns_traceability_v1 with (security_invoker=true) as
select r.id return_id,r.return_number,r.return_date,r.reason,r.status,r.organization_id,r.sale_id,s.prospecteur_id,
 r.returned_by_user_id,r.returned_by_name,r.returned_by_role,r.warehouse_id,w.name warehouse_name,w.code warehouse_code,
 r.subwarehouse_id,sw.name subwarehouse_name,sw.code subwarehouse_code,r.received_by_user_id,r.received_at,
 ri.id return_item_id,ri.article_id,coalesce(ri.article_code_snapshot,a.code) article_code,coalesce(ri.article_name_snapshot,a.name) article_name,
 ri.quantity,ri.refund_amount
from public.sales_returns r join public.sales s on s.id=r.sale_id join public.sales_return_items ri on ri.return_id=r.id
join public.articles a on a.id=ri.article_id left join public.warehouses w on w.id=r.warehouse_id left join public.warehouse_subwarehouses sw on sw.id=r.subwarehouse_id;
revoke all on public.jdvcrm_returns_traceability_v1 from anon;
grant select on public.jdvcrm_returns_traceability_v1 to authenticated;