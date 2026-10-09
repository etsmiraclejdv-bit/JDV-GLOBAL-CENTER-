-- Ventes des prospecteurs de l'entrepôt (sans aucune donnée client) : sert à traiter les retours clients.
create or replace function public.jdvcrm_warehouse_sales_v1(p_warehouse_id uuid, p_days integer default 30)
returns table (sale_id uuid, sale_number text, sale_date timestamptz, article_name text, quantity numeric,
               returned_quantity numeric, prospecteur_name text, amount numeric, status text)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare v_org uuid;
begin
  if (select auth.uid()) is null then raise exception 'Authentification requise'; end if;
  if not private.can_manage_warehouse(p_warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;
  select w.organization_id into v_org from public.warehouses w where w.id = p_warehouse_id;
  return query
  select s.id, s.sale_number, s.sale_date, a.name, s.quantity::numeric,
    coalesce((select sum(i.quantity) from public.sales_return_items i
              join public.sales_returns sr on sr.id = i.return_id
              where sr.sale_id = s.id and sr.status in ('approved', 'processed') and i.article_id = s.article_id), 0)::numeric,
    nullif(concat_ws(' ', p.first_name, p.last_name), ''),
    ((case when s.sale_type = 'cash' then s.cash_price else s.credit_price end) * s.quantity)::numeric,
    s.status
  from public.sales s
  join public.articles a on a.id = s.article_id
  join public.prospecteurs p on p.id = s.prospecteur_id
  where s.organization_id = v_org and s.status <> 'cancelled'
    and s.sale_date >= now() - make_interval(days => greatest(1, least(coalesce(p_days, 30), 365)))
    and s.prospecteur_id in (select a2.prospecteur_id from public.prospecteur_warehouse_assignments a2
                             where a2.warehouse_id = p_warehouse_id and a2.active = true and a2.is_primary = true)
  order by s.sale_date desc
  limit 300;
end;
$function$;

-- Fournisseurs de l'entreprise, pour les demandes d'approvisionnement de l'entrepôt.
create or replace function public.jdvcrm_warehouse_suppliers_v1(p_warehouse_id uuid)
returns table (supplier_id uuid, name text, contact_name text, phone text, status text)
language plpgsql
stable
security definer
set search_path = ''
as $function$
declare v_org uuid;
begin
  if (select auth.uid()) is null then raise exception 'Authentification requise'; end if;
  if not private.can_manage_warehouse(p_warehouse_id) then raise exception 'Accès refusé à cet entrepôt'; end if;
  select w.organization_id into v_org from public.warehouses w where w.id = p_warehouse_id;
  return query
  select su.id, su.company_name, su.contact_name, su.phone, su.status
  from public.suppliers su
  where su.organization_id = v_org
  order by su.company_name;
end;
$function$;

revoke all on function public.jdvcrm_warehouse_sales_v1(uuid, integer) from public, anon;
grant execute on function public.jdvcrm_warehouse_sales_v1(uuid, integer) to authenticated;
revoke all on function public.jdvcrm_warehouse_suppliers_v1(uuid) from public, anon;
grant execute on function public.jdvcrm_warehouse_suppliers_v1(uuid) to authenticated;