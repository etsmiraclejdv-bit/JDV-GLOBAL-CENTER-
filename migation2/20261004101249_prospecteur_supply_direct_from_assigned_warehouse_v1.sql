-- JDV CRM: le prospecteur se réapprovisionne directement depuis son entrepôt principal affecté.
-- L'administrateur alimente les entrepôts mais ne valide plus les sorties vers les prospecteurs.

create or replace function public.jdvcrm_request_prospecteur_supply_v1(
  p_warehouse_id uuid,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_prospecteur_id uuid;
  v_org_id uuid;
  v_request_id uuid;
  v_item record;
  v_available numeric;
  v_article_name text;
  v_blocked_count integer;
begin
  if v_uid is null then
    raise exception 'Session utilisateur introuvable';
  end if;

  if p_warehouse_id is null then
    raise exception 'Entrepôt obligatoire';
  end if;

  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Sélectionnez au moins un article';
  end if;

  select p.id, p.organization_id
    into v_prospecteur_id, v_org_id
  from public.prospecteurs p
  where p.user_id = v_uid
    and p.status = 'active'
  limit 1;

  if v_prospecteur_id is null then
    raise exception 'Compte prospecteur introuvable';
  end if;

  if not exists (
    select 1
    from public.warehouses w
    where w.id = p_warehouse_id
      and w.organization_id = v_org_id
      and w.active = true
  ) then
    raise exception 'Entrepôt invalide ou inactif';
  end if;

  if not exists (
    select 1
    from public.prospecteur_warehouse_assignments a
    where a.prospecteur_id = v_prospecteur_id
      and a.organization_id = v_org_id
      and a.warehouse_id = p_warehouse_id
      and a.active = true
      and a.is_primary = true
  ) then
    raise exception 'Ce prospecteur ne peut se réapprovisionner que dans son entrepôt principal affecté';
  end if;

  select count(*)
    into v_blocked_count
  from public.prospecteur_stock_holdings h
  where h.organization_id = v_org_id
    and h.prospecteur_id = v_prospecteur_id
    and h.remaining_quantity > 0
    and h.status in ('active','overdue')
    and h.return_due_at <= now();

  if v_blocked_count > 0 then
    raise exception 'Approvisionnement bloqué : une ou plusieurs marchandises doivent être retournées à l''entrepôt';
  end if;

  insert into public.prospecteur_supply_requests (
    organization_id, prospecteur_id, warehouse_id, status,
    requested_at, processed_at, processed_by, notes
  )
  values (
    v_org_id, v_prospecteur_id, p_warehouse_id, 'approved',
    now(), now(), v_uid, 'Réapprovisionnement direct depuis l''entrepôt affecté'
  )
  returning id into v_request_id;

  for v_item in
    select x.article_id, x.quantity
    from jsonb_to_recordset(p_items) as x(article_id uuid, quantity numeric)
  loop
    if v_item.article_id is null or v_item.quantity is null or v_item.quantity <= 0 or v_item.quantity <> trunc(v_item.quantity) then
      raise exception 'Quantité invalide pour un article';
    end if;

    select a.name
      into v_article_name
    from public.articles a
    where a.id = v_item.article_id
      and a.organization_id = v_org_id
      and a.active = true;

    if v_article_name is null then
      raise exception 'Article introuvable ou inactif';
    end if;

    insert into public.prospecteur_supply_request_items (
      organization_id, request_id, article_id, quantity
    )
    values (
      v_org_id, v_request_id, v_item.article_id, v_item.quantity
    );

    select coalesce(wi.quantity - wi.reserved_quantity, 0)
      into v_available
    from public.warehouse_inventory wi
    where wi.organization_id = v_org_id
      and wi.warehouse_id = p_warehouse_id
      and wi.article_id = v_item.article_id
    for update;

    if coalesce(v_available, 0) < v_item.quantity then
      raise exception 'Stock insuffisant pour % (disponible: %, demandé: %)',
        v_article_name, coalesce(v_available, 0), v_item.quantity;
    end if;

    update public.warehouse_inventory
      set quantity = quantity - v_item.quantity,
          updated_at = now()
    where organization_id = v_org_id
      and warehouse_id = p_warehouse_id
      and article_id = v_item.article_id;

    insert into public.prospecteur_stocks (
      organization_id, prospecteur_id, article_id, quantity, updated_at
    )
    values (
      v_org_id, v_prospecteur_id, v_item.article_id, v_item.quantity::integer, now()
    )
    on conflict (prospecteur_id, article_id)
    do update set
      quantity = public.prospecteur_stocks.quantity + excluded.quantity,
      updated_at = now();

    insert into public.prospecteur_stock_holdings (
      organization_id, prospecteur_id, article_id, warehouse_id,
      supply_request_id, quantity, remaining_quantity, supplied_at,
      return_due_at, hard_due_at, status, notes
    )
    values (
      v_org_id, v_prospecteur_id, v_item.article_id, p_warehouse_id,
      v_request_id, v_item.quantity, v_item.quantity, now(),
      now() + interval '10 days', now() + interval '20 days',
      'active',
      'Marchandise confiée au prospecteur depuis son entrepôt affecté; retour obligatoire si non vendue.'
    );

    insert into public.stock_movements (
      organization_id, article_id, prospecteur_id, movement_type,
      quantity, reference_type, reference_id, source_location,
      destination_location, notes, created_by
    )
    values (
      v_org_id, v_item.article_id, v_prospecteur_id, 'transfer_to_prospecteur',
      v_item.quantity::integer, 'prospecteur_supply_request', v_request_id,
      (
        select coalesce(w.name,'') ||
          case when w.city is not null then ' - ' || w.city else '' end
        from public.warehouses w
        where w.id = p_warehouse_id
      ),
      'stock_prospecteur',
      'Réapprovisionnement direct depuis l''entrepôt affecté',
      v_uid
    );
  end loop;

  return jsonb_build_object(
    'request_id', v_request_id,
    'status', 'approved',
    'prospecteur_id', v_prospecteur_id,
    'warehouse_id', p_warehouse_id
  );
end;
$$;

revoke all on function public.jdvcrm_approve_prospecteur_supply_v1(uuid) from public;
revoke all on function public.jdvcrm_approve_prospecteur_supply_v1(uuid) from authenticated;

revoke insert on public.prospecteur_supply_requests from authenticated;
revoke insert on public.prospecteur_supply_request_items from authenticated;

grant select on public.prospecteur_supply_requests to authenticated;
grant select on public.prospecteur_supply_request_items to authenticated;
grant execute on function public.jdvcrm_request_prospecteur_supply_v1(uuid,jsonb) to authenticated;

drop policy if exists "prospecteur_supply_request_select" on public.prospecteur_supply_requests;
create policy "prospecteur_supply_request_select"
on public.prospecteur_supply_requests
for select to authenticated
using (
  prospecteur_id in (
    select p.id from public.prospecteurs p
    where p.user_id = (select auth.uid())
  )
  or exists (
    select 1
    from public.organization_members om
    where om.organization_id = prospecteur_supply_requests.organization_id
      and om.user_id = (select auth.uid())
      and om.status = 'active'
      and om.role in ('business_admin','manager','accountant','viewer')
  )
);

drop policy if exists "prospecteur_supply_request_item_select" on public.prospecteur_supply_request_items;
create policy "prospecteur_supply_request_item_select"
on public.prospecteur_supply_request_items
for select to authenticated
using (
  exists (
    select 1
    from public.prospecteur_supply_requests r
    where r.id = prospecteur_supply_request_items.request_id
      and (
        r.prospecteur_id in (
          select p.id from public.prospecteurs p
          where p.user_id = (select auth.uid())
        )
        or exists (
          select 1
          from public.organization_members om
          where om.organization_id = r.organization_id
            and om.user_id = (select auth.uid())
            and om.status = 'active'
            and om.role in ('business_admin','manager','accountant','viewer')
        )
      )
  )
);
