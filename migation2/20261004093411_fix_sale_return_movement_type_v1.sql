create or replace function public.jdvcrm_process_sale_return(p_return_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, private
as $function$
declare
  r public.sales_returns%rowtype;
  v_sale public.sales%rowtype;
  i record;
  v_stock_id uuid;
  v_stock_qty integer;
  v_ps_id uuid;
  v_ps_qty integer;
  v_existing boolean;
  v_serial_org uuid;
  v_serial_article uuid;
  v_serial_sale uuid;
  v_serial_client uuid;
  v_serial_status text;
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  select * into r from public.sales_returns where id=p_return_id for update;
  if not found then raise exception 'Retour introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(r.organization_id)) then
    raise exception 'Accès refusé : administrateur ou concepteur requis';
  end if;
  select * into v_sale from public.sales where id=r.sale_id for update;
  if not found or v_sale.organization_id<>r.organization_id then raise exception 'Vente incompatible avec le retour'; end if;
  if r.status='processed' then return true; end if;
  if r.status<>'approved' then raise exception 'Le retour doit être approuvé avant traitement'; end if;

  for i in select * from public.sales_return_items where return_id=r.id order by id loop
    select exists(
      select 1 from public.stock_movements
      where organization_id=r.organization_id and reference_type='sale_return'
        and reference_id=r.id and article_id=i.article_id
        and movement_type in ('return_from_prospecteur','entry')
        and ((i.serial_number_id is null and notes not like '%serial:%')
          or (i.serial_number_id is not null and notes like '%serial:'||i.serial_number_id::text||'%'))
    ) into v_existing;
    if v_existing then continue; end if;

    if i.serial_number_id is not null then
      select organization_id, article_id, sale_id, client_id, status
        into v_serial_org, v_serial_article, v_serial_sale, v_serial_client, v_serial_status
      from public.serial_numbers where id=i.serial_number_id for update;
      if not found or v_serial_org<>r.organization_id or v_serial_article<>i.article_id or v_serial_sale<>r.sale_id then
        raise exception 'Numéro de série incompatible avec le retour';
      end if;
      if v_sale.client_id is not null and v_serial_client is not null and v_serial_client<>v_sale.client_id then
        raise exception 'Client incompatible avec le numéro de série';
      end if;
      if v_serial_status not in ('sold','returned') then raise exception 'Numéro de série non retournable'; end if;
    end if;

    if v_sale.prospecteur_id is not null then
      select id, quantity into v_ps_id, v_ps_qty
      from public.prospecteur_stocks
      where organization_id=r.organization_id and prospecteur_id=v_sale.prospecteur_id and article_id=i.article_id
      for update;
      if not found then
        insert into public.prospecteur_stocks(organization_id,prospecteur_id,article_id,quantity,updated_at)
        values(r.organization_id,v_sale.prospecteur_id,i.article_id,i.quantity,now())
        returning id,quantity into v_ps_id,v_ps_qty;
      else
        update public.prospecteur_stocks set quantity=quantity+i.quantity,updated_at=now() where id=v_ps_id;
      end if;
      insert into public.stock_movements(
        organization_id,article_id,prospecteur_id,movement_type,quantity,
        reference_type,reference_id,source_location,destination_location,notes,created_by,created_at
      ) values(
        r.organization_id,i.article_id,v_sale.prospecteur_id,'return_from_prospecteur',i.quantity,
        'sale_return',r.id,'client','stock_prospecteur',
        'Réintégration retour '||r.return_number||case when i.serial_number_id is not null then ' serial:'||i.serial_number_id::text else '' end,
        auth.uid(),now()
      );
    else
      select id,quantity into v_stock_id,v_stock_qty from public.stocks
      where organization_id=r.organization_id and article_id=i.article_id for update;
      if not found then
        insert into public.stocks(organization_id,article_id,quantity,reserved_quantity,minimum_quantity,updated_at)
        values(r.organization_id,i.article_id,i.quantity,0,0,now());
      else
        update public.stocks set quantity=quantity+i.quantity,updated_at=now() where id=v_stock_id;
      end if;
      insert into public.stock_movements(
        organization_id,article_id,prospecteur_id,movement_type,quantity,
        reference_type,reference_id,source_location,destination_location,notes,created_by,created_at
      ) values(
        r.organization_id,i.article_id,null,'entry',i.quantity,
        'sale_return',r.id,'client','stock_principal',
        'Réintégration retour '||r.return_number||case when i.serial_number_id is not null then ' serial:'||i.serial_number_id::text else '' end,
        auth.uid(),now()
      );
    end if;

    if i.serial_number_id is not null then
      update public.article_serial_assignments set active=false,released_at=now()
      where serial_number_id=i.serial_number_id and active=true;
      update public.serial_numbers set status='returned',client_id=null,updated_at=now()
      where id=i.serial_number_id;
      if v_sale.prospecteur_id is not null then
        insert into public.article_serial_assignments(
          organization_id,serial_number_id,article_id,prospecteur_id,warehouse_id,assigned_at,released_at,active,created_by
        ) values(r.organization_id,i.serial_number_id,i.article_id,v_sale.prospecteur_id,null,now(),null,true,auth.uid());
      end if;
    end if;
  end loop;
  update public.sales_returns set status='processed',updated_at=now() where id=r.id;
  return true;
end;
$function$;