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
begin
  if auth.uid() is null then
    raise exception 'Authentification requise';
  end if;

  select * into r
  from public.sales_returns
  where id = p_return_id
  for update;

  if not found then
    raise exception 'Retour introuvable';
  end if;

  if not (private.is_super_admin() or private.is_org_admin()) then
    raise exception 'Accès refusé au traitement du retour';
  end if;

  if r.status = 'processed' then
    return true;
  end if;

  if r.status <> 'approved' then
    raise exception 'Le retour doit être approuvé avant traitement';
  end if;

  select * into v_sale
  from public.sales
  where id = r.sale_id
  for update;

  if not found then
    raise exception 'Vente d''origine introuvable';
  end if;

  if v_sale.organization_id <> r.organization_id then
    raise exception 'Incohérence d''organisation entre le retour et la vente';
  end if;

  if r.client_id is not null and v_sale.client_id is not null and r.client_id <> v_sale.client_id then
    raise exception 'Le client du retour ne correspond pas à la vente';
  end if;

  for i in
    select * from public.sales_return_items
    where return_id = r.id
    order by id
  loop
    if i.organization_id <> r.organization_id then
      raise exception 'Article de retour rattaché à une autre organisation';
    end if;

    if i.quantity <= 0 then
      raise exception 'Quantité de retour invalide pour l''article %', i.article_id;
    end if;

    if v_sale.article_id is not null and i.article_id <> v_sale.article_id then
      raise exception 'Article du retour différent de l''article de la vente';
    end if;

    select exists(
      select 1
      from public.stock_movements sm
      where sm.organization_id = r.organization_id
        and sm.reference_type = 'sale_return'
        and sm.reference_id = r.id
        and sm.article_id = i.article_id
        and sm.movement_type = 'return'
    ) into v_existing;

    if v_existing then
      continue;
    end if;

    if v_sale.prospecteur_id is not null then
      select id, quantity
      into v_ps_id, v_ps_qty
      from public.prospecteur_stocks
      where organization_id = r.organization_id
        and prospecteur_id = v_sale.prospecteur_id
        and article_id = i.article_id
      for update;

      if not found then
        insert into public.prospecteur_stocks(
          organization_id, prospecteur_id, article_id, quantity, updated_at
        ) values (
          r.organization_id, v_sale.prospecteur_id, i.article_id, i.quantity, now()
        );
      else
        update public.prospecteur_stocks
        set quantity = quantity + i.quantity,
            updated_at = now()
        where id = v_ps_id;
      end if;

      insert into public.stock_movements(
        organization_id, article_id, prospecteur_id, movement_type, quantity,
        reference_type, reference_id, source_location, destination_location,
        notes, created_by, created_at
      ) values (
        r.organization_id, i.article_id, v_sale.prospecteur_id, 'return', i.quantity,
        'sale_return', r.id, 'client', 'stock_prospecteur',
        'Réintégration du retour ' || r.return_number || ' vers le stock du prospecteur',
        auth.uid(), now()
      );
    else
      select id, quantity
      into v_stock_id, v_stock_qty
      from public.stocks
      where organization_id = r.organization_id
        and article_id = i.article_id
      for update;

      if not found then
        insert into public.stocks(
          organization_id, article_id, quantity, updated_at
        ) values (
          r.organization_id, i.article_id, i.quantity, now()
        );
      else
        update public.stocks
        set quantity = quantity + i.quantity,
            updated_at = now()
        where id = v_stock_id;
      end if;

      insert into public.stock_movements(
        organization_id, article_id, prospecteur_id, movement_type, quantity,
        reference_type, reference_id, source_location, destination_location,
        notes, created_by, created_at
      ) values (
        r.organization_id, i.article_id, null, 'return', i.quantity,
        'sale_return', r.id, 'client', 'stock_principal',
        'Réintégration du retour ' || r.return_number || ' vers le stock principal',
        auth.uid(), now()
      );
    end if;
  end loop;

  update public.sales_returns
  set status = 'processed', updated_at = now()
  where id = r.id;

  return true;
end;
$function$;

revoke all on function public.jdvcrm_process_sale_return(uuid) from public;
grant execute on function public.jdvcrm_process_sale_return(uuid) to authenticated;

create unique index if not exists uq_jdvcrm_stock_return_movement
on public.stock_movements(reference_type, reference_id, article_id, movement_type)
where reference_type = 'sale_return' and reference_id is not null and movement_type = 'return';
