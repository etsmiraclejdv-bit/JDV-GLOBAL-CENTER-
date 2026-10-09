create or replace function public.jdvcrm_admin_stock_entry_v1(
  p_organization_id uuid,p_article_id uuid,p_quantity integer,
  p_minimum_quantity integer default 0,p_notes text default null
) returns jsonb
language plpgsql security definer set search_path=public,private
as $$
declare v_uid uuid:=auth.uid(); v_article_org uuid; v_stock public.stocks%rowtype;
begin
  if v_uid is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
  if not private.is_super_admin() and not private.is_org_admin(p_organization_id) then raise exception 'ACCESS_DENIED'; end if;
  if p_quantity is null or p_quantity<=0 then raise exception 'QUANTITY_MUST_BE_POSITIVE'; end if;
  if coalesce(p_minimum_quantity,0)<0 then raise exception 'MINIMUM_QUANTITY_INVALID'; end if;
  select organization_id into v_article_org from public.articles where id=p_article_id and active=true;
  if v_article_org is null or v_article_org<>p_organization_id then raise exception 'ARTICLE_NOT_IN_ORGANIZATION'; end if;
  insert into public.stocks(organization_id,article_id,quantity,reserved_quantity,minimum_quantity,updated_at)
  values(p_organization_id,p_article_id,p_quantity,0,coalesce(p_minimum_quantity,0),now())
  on conflict(organization_id,article_id) do update set quantity=public.stocks.quantity+excluded.quantity,
    minimum_quantity=excluded.minimum_quantity,updated_at=now()
  returning * into v_stock;
  insert into public.stock_movements(organization_id,article_id,movement_type,quantity,reference_type,
    source_location,destination_location,notes,created_by)
  values(p_organization_id,p_article_id,'entry',p_quantity,'admin_stock_entry','supplier','stock_central',p_notes,v_uid);
  return jsonb_build_object('stock_id',v_stock.id,'article_id',p_article_id,'quantity',v_stock.quantity);
end $$;

create or replace function public.jdvcrm_admin_supply_warehouse_v1(
  p_organization_id uuid,p_warehouse_id uuid,p_article_id uuid,p_quantity integer,
  p_minimum_quantity integer default 0,p_notes text default null
) returns jsonb
language plpgsql security definer set search_path=public,private
as $$
declare v_uid uuid:=auth.uid(); v_wh_org uuid; v_article_org uuid; v_stock public.stocks%rowtype;
  v_inventory public.warehouse_inventory%rowtype;
begin
  if v_uid is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
  if not private.is_super_admin() and not private.is_org_admin(p_organization_id) then raise exception 'ACCESS_DENIED'; end if;
  if p_quantity is null or p_quantity<=0 then raise exception 'QUANTITY_MUST_BE_POSITIVE'; end if;
  if coalesce(p_minimum_quantity,0)<0 then raise exception 'MINIMUM_QUANTITY_INVALID'; end if;
  select organization_id into v_wh_org from public.warehouses where id=p_warehouse_id and active=true;
  if v_wh_org is null or v_wh_org<>p_organization_id then raise exception 'WAREHOUSE_NOT_IN_ORGANIZATION'; end if;
  select organization_id into v_article_org from public.articles where id=p_article_id and active=true;
  if v_article_org is null or v_article_org<>p_organization_id then raise exception 'ARTICLE_NOT_IN_ORGANIZATION'; end if;
  select * into v_stock from public.stocks where organization_id=p_organization_id and article_id=p_article_id for update;
  if not found or (v_stock.quantity-v_stock.reserved_quantity)<p_quantity then raise exception 'INSUFFICIENT_CENTRAL_STOCK'; end if;
  update public.stocks set quantity=quantity-p_quantity,updated_at=now() where id=v_stock.id;
  insert into public.warehouse_inventory(organization_id,warehouse_id,article_id,quantity,reserved_quantity,minimum_quantity,updated_at)
  values(p_organization_id,p_warehouse_id,p_article_id,p_quantity,0,coalesce(p_minimum_quantity,0),now())
  on conflict(warehouse_id,article_id) do update set quantity=public.warehouse_inventory.quantity+excluded.quantity,
    minimum_quantity=excluded.minimum_quantity,updated_at=now()
  returning * into v_inventory;
  insert into public.stock_movements(organization_id,article_id,movement_type,quantity,reference_type,
    source_location,destination_location,notes,created_by)
  values(p_organization_id,p_article_id,'transfer_out',p_quantity,'admin_warehouse_supply',
    'stock_central',p_warehouse_id::text,p_notes,v_uid);
  return jsonb_build_object('warehouse_inventory_id',v_inventory.id,'article_id',p_article_id,
    'warehouse_id',p_warehouse_id,'warehouse_quantity',v_inventory.quantity,'central_quantity',v_stock.quantity-p_quantity);
end $$;

revoke all on function public.jdvcrm_admin_stock_entry_v1(uuid,uuid,integer,integer,text) from public,anon,authenticated;
revoke all on function public.jdvcrm_admin_supply_warehouse_v1(uuid,uuid,uuid,integer,integer,text) from public,anon,authenticated;
grant execute on function public.jdvcrm_admin_stock_entry_v1(uuid,uuid,integer,integer,text) to authenticated;
grant execute on function public.jdvcrm_admin_supply_warehouse_v1(uuid,uuid,uuid,integer,integer,text) to authenticated;
revoke execute on function public.jdvcrm_request_prospecteur_supply_v1(uuid,jsonb) from anon;