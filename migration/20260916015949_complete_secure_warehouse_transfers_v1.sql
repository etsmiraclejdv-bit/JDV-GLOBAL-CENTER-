create unique index if not exists uq_jdvcrm_transfer_out_movement on public.stock_movements(reference_type, reference_id, movement_type) where reference_type='stock_transfer' and reference_id is not null and movement_type='transfer_out';
create unique index if not exists uq_jdvcrm_transfer_in_movement on public.stock_movements(reference_type, reference_id, movement_type) where reference_type='stock_transfer' and reference_id is not null and movement_type='transfer_in';

create or replace function public.jdvcrm_send_stock_transfer_v1(p_transfer_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_transfer public.stock_transfers%rowtype;
  v_item record;
  v_inv public.warehouse_inventory%rowtype;
  v_existing boolean;
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  select * into v_transfer from public.stock_transfers where id=p_transfer_id for update;
  if not found then raise exception 'Transfert introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(v_transfer.organization_id)) then raise exception 'Accès refusé'; end if;
  if v_transfer.status='in_transit' or v_transfer.status='received' then return true; end if;
  if v_transfer.status<>'draft' then raise exception 'Le transfert doit être en brouillon avant expédition'; end if;
  if not exists(select 1 from public.stock_transfer_items where transfer_id=v_transfer.id) then raise exception 'Le transfert ne contient aucun article'; end if;

  for v_item in select * from public.stock_transfer_items where transfer_id=v_transfer.id order by id loop
    select * into v_inv from public.warehouse_inventory
      where organization_id=v_transfer.organization_id and warehouse_id=v_transfer.source_warehouse_id and article_id=v_item.article_id
      for update;
    if not found then raise exception 'Stock source introuvable pour l''article %',v_item.article_id; end if;
    if v_inv.quantity - v_inv.reserved_quantity < v_item.quantity then
      raise exception 'Stock disponible insuffisant dans l''entrepôt source pour l''article %',v_item.article_id;
    end if;
    select exists(select 1 from public.stock_movements where organization_id=v_transfer.organization_id and reference_type='stock_transfer' and reference_id=v_transfer.id and article_id=v_item.article_id and movement_type='transfer_out') into v_existing;
    if not v_existing then
      update public.warehouse_inventory set quantity=quantity-v_item.quantity, updated_at=now() where id=v_inv.id;
      insert into public.stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
      values(v_transfer.organization_id,v_item.article_id,null,'transfer_out',v_item.quantity,'stock_transfer',v_transfer.id,'warehouse:'||v_transfer.source_warehouse_id::text,'warehouse:'||v_transfer.destination_warehouse_id::text,'Expédition transfert '||v_transfer.transfer_number,auth.uid(),now());
    end if;
  end loop;
  update public.stock_transfers set status='in_transit', updated_at=now() where id=v_transfer.id;
  return true;
end;
$function$;

create or replace function public.jdvcrm_receive_stock_transfer_v1(p_transfer_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public
as $function$
declare
  v_transfer public.stock_transfers%rowtype;
  v_item record;
  v_inv public.warehouse_inventory%rowtype;
  v_existing boolean;
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  select * into v_transfer from public.stock_transfers where id=p_transfer_id for update;
  if not found then raise exception 'Transfert introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(v_transfer.organization_id)) then raise exception 'Accès refusé'; end if;
  if v_transfer.status='received' then return true; end if;
  if v_transfer.status<>'in_transit' then raise exception 'Le transfert doit être en transit avant réception'; end if;

  for v_item in select * from public.stock_transfer_items where transfer_id=v_transfer.id order by id loop
    select exists(select 1 from public.stock_movements where organization_id=v_transfer.organization_id and reference_type='stock_transfer' and reference_id=v_transfer.id and article_id=v_item.article_id and movement_type='transfer_in') into v_existing;
    if not v_existing then
      select * into v_inv from public.warehouse_inventory
        where organization_id=v_transfer.organization_id and warehouse_id=v_transfer.destination_warehouse_id and article_id=v_item.article_id
        for update;
      if found then
        update public.warehouse_inventory set quantity=quantity+v_item.quantity, updated_at=now() where id=v_inv.id;
      else
        insert into public.warehouse_inventory(organization_id,warehouse_id,article_id,quantity,reserved_quantity,minimum_quantity,updated_at)
        values(v_transfer.organization_id,v_transfer.destination_warehouse_id,v_item.article_id,v_item.quantity,0,0,now());
      end if;
      insert into public.stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
      values(v_transfer.organization_id,v_item.article_id,null,'transfer_in',v_item.quantity,'stock_transfer',v_transfer.id,'warehouse:'||v_transfer.source_warehouse_id::text,'warehouse:'||v_transfer.destination_warehouse_id::text,'Réception transfert '||v_transfer.transfer_number,auth.uid(),now());
    end if;
    update public.stock_transfer_items set received_quantity=quantity where id=v_item.id;
  end loop;
  update public.stock_transfers set status='received',received_by=auth.uid(),updated_at=now() where id=v_transfer.id;
  return true;
end;
$function$;

revoke execute on function public.jdvcrm_send_stock_transfer_v1(uuid) from public, anon;
grant execute on function public.jdvcrm_send_stock_transfer_v1(uuid) to authenticated;
revoke execute on function public.jdvcrm_receive_stock_transfer_v1(uuid) from public, anon;
grant execute on function public.jdvcrm_receive_stock_transfer_v1(uuid) to authenticated;
