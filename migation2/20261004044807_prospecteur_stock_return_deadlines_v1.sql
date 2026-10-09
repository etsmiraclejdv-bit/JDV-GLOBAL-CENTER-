create table if not exists public.prospecteur_stock_holdings (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  prospecteur_id uuid not null references public.prospecteurs(id) on delete cascade,
  article_id uuid not null references public.articles(id) on delete restrict,
  warehouse_id uuid not null references public.warehouses(id) on delete restrict,
  supply_request_id uuid references public.prospecteur_supply_requests(id) on delete set null,
  quantity numeric(14,3) not null check (quantity > 0),
  remaining_quantity numeric(14,3) not null check (remaining_quantity >= 0 and remaining_quantity <= quantity),
  supplied_at timestamptz not null default now(),
  return_due_at timestamptz not null default (now() + interval '10 days'),
  hard_due_at timestamptz not null default (now() + interval '20 days'),
  sold_at timestamptz,
  returned_at timestamptz,
  status text not null default 'active' check (status in ('active','overdue','sold','returned')),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index if not exists idx_psh_prospecteur_status_due
  on public.prospecteur_stock_holdings(organization_id, prospecteur_id, status, return_due_at);
create index if not exists idx_psh_article
  on public.prospecteur_stock_holdings(organization_id, article_id, status);

alter table public.prospecteur_stock_holdings enable row level security;
grant select on public.prospecteur_stock_holdings to authenticated;

drop policy if exists "prospecteur_stock_holdings_select" on public.prospecteur_stock_holdings;
create policy "prospecteur_stock_holdings_select"
on public.prospecteur_stock_holdings
for select to authenticated
using (
  prospecteur_id in (select p.id from public.prospecteurs p where p.user_id=(select auth.uid()))
  or exists (
    select 1 from public.organization_members om
    where om.organization_id=prospecteur_stock_holdings.organization_id
      and om.user_id=(select auth.uid()) and om.status='active'
      and om.role in ('business_admin','manager','accountant','viewer')
  )
);

create or replace function public.jdvcrm_approve_prospecteur_supply_v1(p_request_id uuid)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare
  r public.prospecteur_supply_requests%rowtype;
  item record;
  membership_ok boolean;
  available numeric;
  blocked_count integer;
begin
  select * into r from public.prospecteur_supply_requests where id=p_request_id for update;
  if not found then raise exception 'Demande d''approvisionnement introuvable'; end if;
  select exists(
    select 1 from public.organization_members om
    where om.organization_id=r.organization_id and om.user_id=(select auth.uid())
      and om.status='active' and om.role in ('business_admin','manager')
  ) into membership_ok;
  if not membership_ok then raise exception 'Accès refusé'; end if;
  if r.status <> 'pending' then raise exception 'Cette demande a déjà été traitée'; end if;

  select count(*) into blocked_count
  from public.prospecteur_stock_holdings h
  where h.organization_id=r.organization_id and h.prospecteur_id=r.prospecteur_id
    and h.remaining_quantity > 0 and h.status in ('active','overdue')
    and h.return_due_at <= now();
  if blocked_count > 0 then
    raise exception 'Approvisionnement bloqué : une ou plusieurs marchandises sont à retourner depuis 10 jours ou plus';
  end if;

  for item in
    select i.*, a.name article_name
    from public.prospecteur_supply_request_items i
    join public.articles a on a.id=i.article_id
    where i.request_id=r.id
  loop
    select coalesce(wi.quantity-wi.reserved_quantity,0) into available
    from public.warehouse_inventory wi
    where wi.warehouse_id=r.warehouse_id and wi.article_id=item.article_id
      and wi.organization_id=r.organization_id for update;
    if coalesce(available,0) < item.quantity then
      raise exception 'Stock insuffisant pour % (disponible: %, demandé: %)', item.article_name, coalesce(available,0), item.quantity;
    end if;

    update public.warehouse_inventory set quantity=quantity-item.quantity,updated_at=now()
    where warehouse_id=r.warehouse_id and article_id=item.article_id and organization_id=r.organization_id;

    insert into public.prospecteur_stocks(organization_id,prospecteur_id,article_id,quantity,updated_at)
    values(r.organization_id,r.prospecteur_id,item.article_id,item.quantity::integer,now())
    on conflict(prospecteur_id,article_id)
    do update set quantity=public.prospecteur_stocks.quantity+excluded.quantity,updated_at=now();

    insert into public.prospecteur_stock_holdings(
      organization_id,prospecteur_id,article_id,warehouse_id,supply_request_id,
      quantity,remaining_quantity,supplied_at,return_due_at,hard_due_at,status,notes
    )
    values(
      r.organization_id,r.prospecteur_id,item.article_id,r.warehouse_id,r.id,
      item.quantity,item.quantity,now(),now()+interval '10 days',now()+interval '20 days',
      'active','Marchandise confiée au prospecteur; retour obligatoire si non vendue.'
    );

    insert into public.stock_movements(
      organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,
      source_location,destination_location,notes,created_by
    )
    values(
      r.organization_id,item.article_id,r.prospecteur_id,'transfer_to_prospecteur',item.quantity::integer,
      'prospecteur_supply_request',r.id,
      (select coalesce(name,'')||case when city is not null then ' - '||city else '' end from public.warehouses where id=r.warehouse_id),
      'stock_prospecteur','Approvisionnement validé; retour requis à J+10, limite J+20',(select auth.uid())
    );
  end loop;

  update public.prospecteur_supply_requests
  set status='approved',processed_at=now(),processed_by=(select auth.uid()),updated_at=now()
  where id=r.id;

  return jsonb_build_object('request_id',r.id,'status','approved','prospecteur_id',r.prospecteur_id,'warehouse_id',r.warehouse_id);
end;
$$;

revoke execute on function public.jdvcrm_approve_prospecteur_supply_v1(uuid) from public,anon;
grant execute on function public.jdvcrm_approve_prospecteur_supply_v1(uuid) to authenticated;

create or replace function public.jdvcrm_return_prospecteur_stock_v1(p_holding_id uuid)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare
  h public.prospecteur_stock_holdings%rowtype;
  caller_prospecteur_id uuid;
  org_ok boolean;
  ps_qty integer;
begin
  select * into h from public.prospecteur_stock_holdings where id=p_holding_id for update;
  if not found then raise exception 'Marchandise affectée introuvable'; end if;

  select p.id into caller_prospecteur_id
  from public.prospecteurs p
  where p.user_id=(select auth.uid()) and p.id=h.prospecteur_id
    and p.organization_id=h.organization_id and p.status='active';

  select exists(
    select 1 from public.organization_members om
    where om.organization_id=h.organization_id and om.user_id=(select auth.uid())
      and om.status='active' and om.role in ('business_admin','manager')
  ) into org_ok;

  if caller_prospecteur_id is null and not org_ok then raise exception 'Accès refusé'; end if;
  if h.remaining_quantity <= 0 or h.status in ('returned','sold') then
    raise exception 'Cette marchandise ne contient plus de quantité à retourner';
  end if;

  select ps.quantity into ps_qty
  from public.prospecteur_stocks ps
  where ps.organization_id=h.organization_id and ps.prospecteur_id=h.prospecteur_id
    and ps.article_id=h.article_id for update;
  if not found or ps_qty < h.remaining_quantity then
    raise exception 'Stock prospecteur incohérent pour cet article';
  end if;

  update public.prospecteur_stocks set quantity=quantity-h.remaining_quantity,updated_at=now()
  where organization_id=h.organization_id and prospecteur_id=h.prospecteur_id and article_id=h.article_id;

  insert into public.warehouse_inventory(
    organization_id,warehouse_id,article_id,quantity,reserved_quantity,minimum_quantity,updated_at
  )
  values(h.organization_id,h.warehouse_id,h.article_id,h.remaining_quantity,0,0,now())
  on conflict(warehouse_id,article_id)
  do update set quantity=public.warehouse_inventory.quantity+excluded.quantity,updated_at=now();

  insert into public.stock_movements(
    organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,
    source_location,destination_location,notes,created_by
  )
  values(
    h.organization_id,h.article_id,h.prospecteur_id,'return_from_prospecteur',h.remaining_quantity::integer,
    'prospecteur_stock_return',h.id,'stock_prospecteur',
    (select coalesce(name,'')||case when city is not null then ' - '||city else '' end from public.warehouses where id=h.warehouse_id),
    'Retour intégral de marchandise non vendue; aucune commission générée',(select auth.uid())
  );

  update public.prospecteur_stock_holdings
  set remaining_quantity=0,returned_at=now(),status='returned',updated_at=now()
  where id=h.id;

  return jsonb_build_object('holding_id',h.id,'status','returned','returned_quantity',h.remaining_quantity,'commission_created',false);
end;
$$;

revoke execute on function public.jdvcrm_return_prospecteur_stock_v1(uuid) from public,anon;
grant execute on function public.jdvcrm_return_prospecteur_stock_v1(uuid) to authenticated;

create or replace function public.jdvcrm_process_sale_stock_v42(p_sale_id uuid)
returns boolean language plpgsql security definer set search_path=public
as $$
declare
  v_sale public.sales%rowtype;
  v_stock_id uuid;
  v_stock_quantity numeric;
  v_ps_id uuid;
  v_ps_qty numeric;
  v_qty numeric;
  v_remaining numeric;
  h record;
begin
  select * into v_sale from public.sales where id=p_sale_id for update;
  if not found then raise exception 'Vente introuvable : %',p_sale_id; end if;
  v_qty:=coalesce(v_sale.quantity,0);
  if v_qty<=0 then raise exception 'Quantité de vente invalide : %',v_qty; end if;
  if v_sale.article_id is null then raise exception 'La vente ne possède aucun article'; end if;

  if exists(
    select 1 from public.stock_movements
    where organization_id=v_sale.organization_id and reference_type='sale'
      and reference_id=v_sale.id and movement_type='sale'
  ) then return true; end if;

  if v_sale.prospecteur_id is not null then
    v_remaining := v_qty;
    for h in
      select id,remaining_quantity
      from public.prospecteur_stock_holdings
      where organization_id=v_sale.organization_id and prospecteur_id=v_sale.prospecteur_id
        and article_id=v_sale.article_id and remaining_quantity>0
        and status in ('active','overdue')
      order by supplied_at asc,created_at asc
      for update
    loop
      exit when v_remaining<=0;
      update public.prospecteur_stock_holdings
      set remaining_quantity=remaining_quantity-least(remaining_quantity,v_remaining),
          sold_at=case when remaining_quantity-least(remaining_quantity,v_remaining)=0 then now() else sold_at end,
          status=case when remaining_quantity-least(remaining_quantity,v_remaining)=0 then 'sold' else status end,
          updated_at=now()
      where id=h.id;
      v_remaining:=v_remaining-least(h.remaining_quantity,v_remaining);
    end loop;

    if v_remaining>0 then
      raise exception 'Stock affecté au prospecteur insuffisant pour cette vente. Reste à vendre : %',v_remaining;
    end if;

    select id,quantity into v_ps_id,v_ps_qty
    from public.prospecteur_stocks
    where organization_id=v_sale.organization_id and prospecteur_id=v_sale.prospecteur_id
      and article_id=v_sale.article_id for update;
    if not found or v_ps_qty<v_qty then
      raise exception 'Stock prospecteur insuffisant. Disponible : %, demandé : %',coalesce(v_ps_qty,0),v_qty;
    end if;

    update public.prospecteur_stocks set quantity=quantity-v_qty,updated_at=now() where id=v_ps_id;

    insert into public.stock_movements(
      organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,
      source_location,destination_location,notes,created_by,created_at
    )
    values(
      v_sale.organization_id,v_sale.article_id,v_sale.prospecteur_id,'sale',v_qty,'sale',v_sale.id,
      'stock_prospecteur','client','Sortie automatique du stock prospecteur liée à la vente '||v_sale.sale_number,
      auth.uid(),now()
    );
  else
    select id,quantity into v_stock_id,v_stock_quantity
    from public.stocks
    where organization_id=v_sale.organization_id and article_id=v_sale.article_id for update;
    if not found then raise exception 'Aucun stock trouvé pour l''article dans l''organisation'; end if;
    if v_stock_quantity<v_qty then raise exception 'Stock insuffisant. Disponible : %, demandé : %',v_stock_quantity,v_qty; end if;
    update public.stocks set quantity=quantity-v_qty,updated_at=now() where id=v_stock_id;
    insert into public.stock_movements(
      organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,
      source_location,destination_location,notes,created_by,created_at
    )
    values(
      v_sale.organization_id,v_sale.article_id,null,'sale',v_qty,'sale',v_sale.id,
      'stock_principal','client','Sortie automatique du stock principal liée à la vente '||v_sale.sale_number,
      auth.uid(),now()
    );
  end if;
  return true;
end;
$$;

revoke execute on function public.jdvcrm_process_sale_stock_v42(uuid) from public,anon;
grant execute on function public.jdvcrm_process_sale_stock_v42(uuid) to authenticated;
