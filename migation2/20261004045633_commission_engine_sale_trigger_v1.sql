create or replace function public.jdvcrm_apply_sale_commissions_v1(p_sale_id uuid)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_sale public.sales%rowtype; v_total numeric(14,2); v_count integer:=0; v_amount numeric(14,2):=0; r record; v_calc numeric(14,2);
begin
select * into v_sale from public.sales where id=p_sale_id for update;
if not found then raise exception 'Vente introuvable'; end if;
if v_sale.prospecteur_id is null then return jsonb_build_object('sale_id',p_sale_id,'commission_count',0,'total',0); end if;
v_total:=case when v_sale.sale_type='cash' then v_sale.cash_price*v_sale.quantity else v_sale.credit_price*v_sale.quantity end;
for r in select cr.*,ct.name type_name,ct.calculation_method type_method from public.commission_rules cr join public.commission_types ct on ct.id=cr.commission_type_id and ct.active=true join public.articles a on a.id=v_sale.article_id where cr.organization_id=v_sale.organization_id and cr.active=true and (cr.valid_from is null or cr.valid_from<=v_sale.sale_date) and (cr.valid_to is null or cr.valid_to>=v_sale.sale_date) and (cr.applies_to_sale_type='both' or cr.applies_to_sale_type=v_sale.sale_type) and cr.target_role='prospecteur' and (cr.scope='organization' or (cr.scope='article' and cr.article_id=v_sale.article_id) or (cr.scope='category' and lower(coalesce(cr.category_name,''))=lower(coalesce(a.category,'')))) and (cr.cumulative=true or cr.priority=(select max(cr2.priority) from public.commission_rules cr2 where cr2.organization_id=v_sale.organization_id and cr2.active=true and cr2.cumulative=false and cr2.target_role='prospecteur' and (cr2.valid_from is null or cr2.valid_from<=v_sale.sale_date) and (cr2.valid_to is null or cr2.valid_to>=v_sale.sale_date) and (cr2.applies_to_sale_type='both' or cr2.applies_to_sale_type=v_sale.sale_type) and (cr2.scope='organization' or (cr2.scope='article' and cr2.article_id=v_sale.article_id) or (cr2.scope='category' and lower(coalesce(cr2.category_name,''))=lower(coalesce(a.category,'')))))) order by cr.priority desc,cr.created_at asc loop
if exists(select 1 from public.commissions c where c.sale_id=v_sale.id and c.rule_id=r.id and c.prospecteur_id=v_sale.prospecteur_id) then continue; end if;
v_calc:=case when r.type_method='percentage' then v_total*coalesce(r.rate_percent,0)/100 when r.type_method='per_unit' then v_sale.quantity*coalesce(r.per_unit_amount,0) else coalesce(r.fixed_amount,0) end;
insert into public.commissions(organization_id,prospecteur_id,sale_id,article_id,commission_rate,base_amount,commission_amount,status,commission_type_id,rule_id,calculation_method,source_type,calculation_snapshot,description) values(v_sale.organization_id,v_sale.prospecteur_id,v_sale.id,v_sale.article_id,coalesce(r.rate_percent,0),v_total,v_calc,'pending',r.commission_type_id,r.id,r.type_method,'sale',jsonb_build_object('rule_id',r.id,'rule_name',r.name,'type',r.type_name,'method',r.type_method,'scope',r.scope,'priority',r.priority,'rate_percent',r.rate_percent,'fixed_amount',r.fixed_amount,'per_unit_amount',r.per_unit_amount,'base_amount',v_total,'quantity',v_sale.quantity,'sale_type',v_sale.sale_type),r.name);
v_count:=v_count+1; v_amount:=v_amount+v_calc;
end loop;
return jsonb_build_object('sale_id',v_sale.id,'commission_count',v_count,'total',v_amount);
end; $$;

create or replace function public.jdvcrm_calculate_sale_commissions_v1(p_sale_id uuid)
returns jsonb language plpgsql security definer set search_path=''
as $$
declare v_sale public.sales%rowtype; v_user uuid := (select auth.uid());
begin
select * into v_sale from public.sales where id=p_sale_id;
if not found then raise exception 'Vente introuvable'; end if;
if not exists(select 1 from public.organization_members om where om.organization_id=v_sale.organization_id and om.user_id=v_user and om.status='active' and (om.role in ('business_admin','manager','accountant') or (om.role='prospecteur' and exists(select 1 from public.prospecteurs p where p.id=v_sale.prospecteur_id and p.user_id=v_user)))) then raise exception 'Accès refusé'; end if;
return public.jdvcrm_apply_sale_commissions_v1(p_sale_id);
end; $$;

create or replace function public.jdvcrm_create_sale_commission()
returns trigger language plpgsql security definer set search_path=''
as $$ begin perform public.jdvcrm_apply_sale_commissions_v1(new.id); return new; end; $$;

revoke execute on function public.jdvcrm_apply_sale_commissions_v1(uuid) from public,anon,authenticated;
grant execute on function public.jdvcrm_calculate_sale_commissions_v1(uuid) to authenticated;
