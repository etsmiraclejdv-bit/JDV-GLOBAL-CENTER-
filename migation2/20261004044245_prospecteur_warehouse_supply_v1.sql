-- JDV CRM: prospecteur -> entrepot -> approvisionnement -> stock personnel
create table if not exists public.prospecteur_warehouse_assignments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  prospecteur_id uuid not null references public.prospecteurs(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete restrict,
  department text,
  city text,
  is_primary boolean not null default true,
  active boolean not null default true,
  assigned_at timestamptz not null default now(),
  unassigned_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create unique index if not exists uq_prospecteur_active_primary_warehouse on public.prospecteur_warehouse_assignments(prospecteur_id) where active=true and is_primary=true;
create index if not exists idx_pwa_org_warehouse on public.prospecteur_warehouse_assignments(organization_id,warehouse_id) where active=true;

create table if not exists public.prospecteur_supply_requests (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  prospecteur_id uuid not null references public.prospecteurs(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete restrict,
  status text not null default 'pending' check (status in ('pending','approved','rejected','cancelled')),
  requested_at timestamptz not null default now(),
  processed_at timestamptz,
  processed_by uuid references auth.users(id),
  notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists idx_psr_prospecteur_status on public.prospecteur_supply_requests(prospecteur_id,status,requested_at desc);

create table if not exists public.prospecteur_supply_request_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  request_id uuid not null references public.prospecteur_supply_requests(id) on delete cascade,
  article_id uuid not null references public.articles(id) on delete restrict,
  quantity numeric not null check (quantity>0),
  created_at timestamptz not null default now(),
  unique(request_id,article_id)
);
create index if not exists idx_psri_request on public.prospecteur_supply_request_items(request_id);

alter table public.prospecteur_warehouse_assignments enable row level security;
alter table public.prospecteur_supply_requests enable row level security;
alter table public.prospecteur_supply_request_items enable row level security;

grant select,insert,update on public.prospecteur_warehouse_assignments to authenticated;
grant select,insert on public.prospecteur_supply_requests to authenticated;
grant select,insert on public.prospecteur_supply_request_items to authenticated;

create or replace function public.jdvcrm_approve_prospecteur_supply_v1(p_request_id uuid)
returns jsonb language plpgsql security definer set search_path=public
as $$
declare r public.prospecteur_supply_requests%rowtype; item record; membership_ok boolean; available numeric;
begin
  select * into r from public.prospecteur_supply_requests where id=p_request_id for update;
  if not found then raise exception 'Demande d''approvisionnement introuvable'; end if;
  select exists(select 1 from public.organization_members om where om.organization_id=r.organization_id and om.user_id=(select auth.uid()) and om.status='active' and om.role in ('business_admin','manager')) into membership_ok;
  if not membership_ok then raise exception 'Accès refusé'; end if;
  if r.status <> 'pending' then raise exception 'Cette demande a déjà été traitée'; end if;
  for item in select i.*,a.name article_name from public.prospecteur_supply_request_items i join public.articles a on a.id=i.article_id where i.request_id=r.id loop
    select coalesce(wi.quantity-wi.reserved_quantity,0) into available from public.warehouse_inventory wi where wi.warehouse_id=r.warehouse_id and wi.article_id=item.article_id and wi.organization_id=r.organization_id for update;
    if coalesce(available,0)<item.quantity then raise exception 'Stock insuffisant pour % (disponible: %, demandé: %)',item.article_name,coalesce(available,0),item.quantity; end if;
    update public.warehouse_inventory set quantity=quantity-item.quantity,updated_at=now() where warehouse_id=r.warehouse_id and article_id=item.article_id and organization_id=r.organization_id;
    insert into public.prospecteur_stocks(organization_id,prospecteur_id,article_id,quantity,updated_at) values(r.organization_id,r.prospecteur_id,item.article_id,item.quantity::integer,now())
      on conflict(prospecteur_id,article_id) do update set quantity=public.prospecteur_stocks.quantity+excluded.quantity,updated_at=now();
    insert into public.stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by)
      values(r.organization_id,item.article_id,r.prospecteur_id,'supply',item.quantity::integer,'prospecteur_supply_request',r.id,
        (select coalesce(name,'')||case when city is not null then ' - '||city else '' end from public.warehouses where id=r.warehouse_id),
        'stock_prospecteur','Approvisionnement validé',(select auth.uid()));
  end loop;
  update public.prospecteur_supply_requests set status='approved',processed_at=now(),processed_by=(select auth.uid()),updated_at=now() where id=r.id;
  return jsonb_build_object('request_id',r.id,'status','approved','prospecteur_id',r.prospecteur_id,'warehouse_id',r.warehouse_id);
end; $$;
grant execute on function public.jdvcrm_approve_prospecteur_supply_v1(uuid) to authenticated;
create unique index if not exists uq_prospecteur_stock_article on public.prospecteur_stocks(prospecteur_id,article_id);

drop policy if exists "prospecteur_warehouse_assignment_select" on public.prospecteur_warehouse_assignments;
create policy "prospecteur_warehouse_assignment_select" on public.prospecteur_warehouse_assignments for select to authenticated using (
  prospecteur_id in(select p.id from public.prospecteurs p where p.user_id=(select auth.uid()))
  or exists(select 1 from public.organization_members om where om.organization_id=prospecteur_warehouse_assignments.organization_id and om.user_id=(select auth.uid()) and om.status='active' and om.role in('business_admin','manager','accountant','viewer'))
);
drop policy if exists "prospecteur_warehouse_assignment_admin_write" on public.prospecteur_warehouse_assignments;
create policy "prospecteur_warehouse_assignment_admin_write" on public.prospecteur_warehouse_assignments for all to authenticated using (
  exists(select 1 from public.organization_members om where om.organization_id=prospecteur_warehouse_assignments.organization_id and om.user_id=(select auth.uid()) and om.status='active' and om.role in('business_admin','manager'))
) with check (
  exists(select 1 from public.organization_members om where om.organization_id=prospecteur_warehouse_assignments.organization_id and om.user_id=(select auth.uid()) and om.status='active' and om.role in('business_admin','manager'))
);
drop policy if exists "prospecteur_supply_request_select" on public.prospecteur_supply_requests;
create policy "prospecteur_supply_request_select" on public.prospecteur_supply_requests for select to authenticated using (
  prospecteur_id in(select p.id from public.prospecteurs p where p.user_id=(select auth.uid()))
  or exists(select 1 from public.organization_members om where om.organization_id=prospecteur_supply_requests.organization_id and om.user_id=(select auth.uid()) and om.status='active' and om.role in('business_admin','manager','accountant','viewer'))
);
drop policy if exists "prospecteur_supply_request_insert" on public.prospecteur_supply_requests;
create policy "prospecteur_supply_request_insert" on public.prospecteur_supply_requests for insert to authenticated with check (
  prospecteur_id in(select p.id from public.prospecteurs p where p.user_id=(select auth.uid()))
  and exists(select 1 from public.prospecteur_warehouse_assignments a where a.prospecteur_id=prospecteur_supply_requests.prospecteur_id and a.warehouse_id=prospecteur_supply_requests.warehouse_id and a.organization_id=prospecteur_supply_requests.organization_id and a.active=true and a.is_primary=true)
);
drop policy if exists "prospecteur_supply_request_item_select" on public.prospecteur_supply_request_items;
create policy "prospecteur_supply_request_item_select" on public.prospecteur_supply_request_items for select to authenticated using(exists(
  select 1 from public.prospecteur_supply_requests r where r.id=prospecteur_supply_request_items.request_id and (
    r.prospecteur_id in(select p.id from public.prospecteurs p where p.user_id=(select auth.uid()))
    or exists(select 1 from public.organization_members om where om.organization_id=r.organization_id and om.user_id=(select auth.uid()) and om.status='active' and om.role in('business_admin','manager','accountant','viewer'))
  )
));
drop policy if exists "prospecteur_supply_request_item_insert" on public.prospecteur_supply_request_items;
create policy "prospecteur_supply_request_item_insert" on public.prospecteur_supply_request_items for insert to authenticated with check(exists(
  select 1 from public.prospecteur_supply_requests r where r.id=prospecteur_supply_request_items.request_id
  and r.prospecteur_id in(select p.id from public.prospecteurs p where p.user_id=(select auth.uid())) and r.status='pending'
));