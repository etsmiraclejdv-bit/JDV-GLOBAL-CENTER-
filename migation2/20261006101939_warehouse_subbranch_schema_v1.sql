-- =====================================================================================
-- Sous-branche Entrepôt : responsables, tickets (call center), demandes d'approvisionnement,
-- clôture de fin de service. Schéma, garde-fous et droits d'accès.
-- =====================================================================================

-- ---------- Abonnement de l'entreprise (sans exiger d'appartenance, pour les responsables d'entrepôt) ----------
create or replace function private.org_subscription_active(p_org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select p_org_id is not null and exists (
    select 1 from public.organization_subscriptions os
    where os.organization_id = p_org_id
      and os.status in ('trial', 'active', 'past_due')
      and (os.expires_at is null or os.expires_at > now())
  );
$function$;

-- ---------- Tables ----------
create table public.warehouse_managers (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  display_name text,
  phone text,
  status text not null default 'active' check (status in ('active', 'suspended')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (warehouse_id, user_id)
);
create index idx_fk_warehouse_managers_organization_id on public.warehouse_managers (organization_id);
create index idx_fk_warehouse_managers_created_by on public.warehouse_managers (created_by);
create index idx_warehouse_managers_user_active on public.warehouse_managers (user_id) where status = 'active';

create table public.warehouse_tickets (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete cascade,
  ticket_number text,
  kind text not null default 'inquiry' check (kind in ('complaint', 'suggestion', 'inquiry', 'other')),
  channel text not null default 'phone' check (channel in ('phone', 'whatsapp', 'walk_in', 'other')),
  caller_name text,
  caller_phone text,
  subject text not null,
  description text,
  priority text not null default 'normal' check (priority in ('low', 'normal', 'high', 'urgent')),
  status text not null default 'open' check (status in ('open', 'in_progress', 'resolved', 'closed')),
  article_id uuid references public.articles(id) on delete set null,
  prospecteur_id uuid references public.prospecteurs(id) on delete set null,
  sale_id uuid references public.sales(id) on delete set null,
  assigned_to uuid references auth.users(id) on delete set null,
  resolution text,
  resolved_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, ticket_number)
);
create index idx_warehouse_tickets_wh_status on public.warehouse_tickets (warehouse_id, status, created_at desc);
create index idx_fk_warehouse_tickets_organization_id on public.warehouse_tickets (organization_id);
create index idx_fk_warehouse_tickets_article_id on public.warehouse_tickets (article_id);
create index idx_fk_warehouse_tickets_prospecteur_id on public.warehouse_tickets (prospecteur_id);
create index idx_fk_warehouse_tickets_sale_id on public.warehouse_tickets (sale_id);
create index idx_fk_warehouse_tickets_assigned_to on public.warehouse_tickets (assigned_to);
create index idx_fk_warehouse_tickets_created_by on public.warehouse_tickets (created_by);

create table public.warehouse_ticket_notes (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete cascade,
  ticket_id uuid not null references public.warehouse_tickets(id) on delete cascade,
  note text not null,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_fk_warehouse_ticket_notes_ticket_id on public.warehouse_ticket_notes (ticket_id);
create index idx_fk_warehouse_ticket_notes_organization_id on public.warehouse_ticket_notes (organization_id);
create index idx_fk_warehouse_ticket_notes_warehouse_id on public.warehouse_ticket_notes (warehouse_id);
create index idx_fk_warehouse_ticket_notes_created_by on public.warehouse_ticket_notes (created_by);

create table public.warehouse_supply_requests (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete cascade,
  reference text,
  target text not null check (target in ('supplier', 'admin')),
  supplier_id uuid references public.suppliers(id) on delete set null,
  status text not null default 'sent'
    check (status in ('sent', 'approved', 'ordered', 'partially_received', 'received', 'rejected', 'cancelled')),
  notes text,
  requested_by uuid references auth.users(id) on delete set null,
  requested_at timestamptz not null default now(),
  processed_by uuid references auth.users(id) on delete set null,
  processed_at timestamptz,
  response_notes text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (organization_id, reference)
);
create index idx_warehouse_supply_requests_wh on public.warehouse_supply_requests (warehouse_id, status, requested_at desc);
create index idx_fk_warehouse_supply_requests_organization_id on public.warehouse_supply_requests (organization_id);
create index idx_fk_warehouse_supply_requests_supplier_id on public.warehouse_supply_requests (supplier_id);
create index idx_fk_warehouse_supply_requests_requested_by on public.warehouse_supply_requests (requested_by);
create index idx_fk_warehouse_supply_requests_processed_by on public.warehouse_supply_requests (processed_by);

create table public.warehouse_supply_request_items (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete cascade,
  request_id uuid not null references public.warehouse_supply_requests(id) on delete cascade,
  article_id uuid not null references public.articles(id) on delete restrict,
  quantity numeric not null check (quantity > 0),
  received_quantity numeric not null default 0 check (received_quantity >= 0),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index idx_fk_warehouse_supply_request_items_request_id on public.warehouse_supply_request_items (request_id);
create index idx_fk_warehouse_supply_request_items_article_id on public.warehouse_supply_request_items (article_id);
create index idx_fk_warehouse_supply_request_items_organization_id on public.warehouse_supply_request_items (organization_id);
create index idx_fk_warehouse_supply_request_items_warehouse_id on public.warehouse_supply_request_items (warehouse_id);

create table public.warehouse_day_closures (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  warehouse_id uuid not null references public.warehouses(id) on delete cascade,
  service_date date not null,
  closed_by uuid references auth.users(id) on delete set null,
  closed_at timestamptz not null default now(),
  notes text,
  snapshot jsonb not null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (warehouse_id, service_date)
);
create index idx_fk_warehouse_day_closures_organization_id on public.warehouse_day_closures (organization_id);
create index idx_fk_warehouse_day_closures_closed_by on public.warehouse_day_closures (closed_by);

-- ---------- Fonctions de droits ----------
create or replace function private.can_manage_warehouse(p_warehouse_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1 from public.warehouses w
    where w.id = p_warehouse_id
      and (
        private.is_super_admin()
        or private.is_org_admin(w.organization_id)
        or exists (
          select 1 from public.warehouse_managers m
          where m.warehouse_id = w.id
            and m.user_id = (select auth.uid())
            and m.status = 'active'
        )
      )
  );
$function$;

revoke all on function private.can_manage_warehouse(uuid) from public, anon;
grant execute on function private.can_manage_warehouse(uuid) to authenticated;

-- Un responsable d'entrepôt peut traiter les retours des ventes de ses prospecteurs.
create or replace function private.can_manage_sale_warehouse(p_sale_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.sales s
    join public.prospecteur_warehouse_assignments a
      on a.prospecteur_id = s.prospecteur_id and a.active = true and a.is_primary = true
    where s.id = p_sale_id
      and private.can_manage_warehouse(a.warehouse_id)
  );
$function$;

revoke all on function private.can_manage_sale_warehouse(uuid) from public, anon, authenticated;

-- ---------- Garde-fou commun : l'entreprise est toujours celle de l'entrepôt ----------
create or replace function public.jdvcrm_warehouse_child_guard_v1()
returns trigger
language plpgsql
security definer
set search_path = ''
as $function$
declare
  v_org uuid;
  v_other uuid;
begin
  select organization_id into v_org from public.warehouses where id = new.warehouse_id;
  if not found then raise exception 'Entrepôt introuvable'; end if;
  new.organization_id := v_org;
  new.updated_at := now();

  if tg_table_name = 'warehouse_tickets' then
    if new.ticket_number is null or new.ticket_number = '' then
      new.ticket_number := 'TK-' || to_char(now() at time zone 'Africa/Lagos', 'YYMMDD') || '-'
                           || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
    end if;
    if new.article_id is not null then
      select organization_id into v_other from public.articles where id = new.article_id;
      if v_other is distinct from v_org then raise exception 'Article d''une autre entreprise'; end if;
    end if;
    if new.prospecteur_id is not null then
      select organization_id into v_other from public.prospecteurs where id = new.prospecteur_id;
      if v_other is distinct from v_org then raise exception 'Prospecteur d''une autre entreprise'; end if;
    end if;
    if new.sale_id is not null then
      select organization_id into v_other from public.sales where id = new.sale_id;
      if v_other is distinct from v_org then raise exception 'Vente d''une autre entreprise'; end if;
    end if;
    if new.status in ('resolved', 'closed') and new.resolved_at is null then
      new.resolved_at := now();
    end if;
  elsif tg_table_name = 'warehouse_ticket_notes' then
    select warehouse_id into v_other from public.warehouse_tickets where id = new.ticket_id;
    if v_other is distinct from new.warehouse_id then raise exception 'Ticket d''un autre entrepôt'; end if;
  elsif tg_table_name = 'warehouse_supply_requests' then
    if new.reference is null or new.reference = '' then
      new.reference := 'AP-' || to_char(now() at time zone 'Africa/Lagos', 'YYMMDD') || '-'
                       || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 6));
    end if;
    if new.target = 'supplier' then
      if new.supplier_id is null then raise exception 'Fournisseur obligatoire pour une demande au fournisseur'; end if;
      select organization_id into v_other from public.suppliers where id = new.supplier_id;
      if v_other is distinct from v_org then raise exception 'Fournisseur d''une autre entreprise'; end if;
    else
      new.supplier_id := null;
    end if;
  elsif tg_table_name = 'warehouse_supply_request_items' then
    select warehouse_id into v_other from public.warehouse_supply_requests where id = new.request_id;
    if v_other is distinct from new.warehouse_id then raise exception 'Demande d''un autre entrepôt'; end if;
    select organization_id into v_other from public.articles where id = new.article_id;
    if v_other is distinct from v_org then raise exception 'Article d''une autre entreprise'; end if;
    if new.received_quantity > new.quantity then raise exception 'Quantité reçue supérieure à la quantité demandée'; end if;
  end if;
  return new;
end;
$function$;

revoke all on function public.jdvcrm_warehouse_child_guard_v1() from public, anon, authenticated;

create trigger trg_warehouse_managers_guard before insert or update on public.warehouse_managers
  for each row execute function public.jdvcrm_warehouse_child_guard_v1();
create trigger trg_warehouse_tickets_guard before insert or update on public.warehouse_tickets
  for each row execute function public.jdvcrm_warehouse_child_guard_v1();
create trigger trg_warehouse_ticket_notes_guard before insert or update on public.warehouse_ticket_notes
  for each row execute function public.jdvcrm_warehouse_child_guard_v1();
create trigger trg_warehouse_supply_requests_guard before insert or update on public.warehouse_supply_requests
  for each row execute function public.jdvcrm_warehouse_child_guard_v1();
create trigger trg_warehouse_supply_request_items_guard before insert or update on public.warehouse_supply_request_items
  for each row execute function public.jdvcrm_warehouse_child_guard_v1();
create trigger trg_warehouse_day_closures_guard before insert or update on public.warehouse_day_closures
  for each row execute function public.jdvcrm_warehouse_child_guard_v1();

-- ---------- Sécurité d'accès (RLS) ----------
alter table public.warehouse_managers enable row level security;
alter table public.warehouse_tickets enable row level security;
alter table public.warehouse_ticket_notes enable row level security;
alter table public.warehouse_supply_requests enable row level security;
alter table public.warehouse_supply_request_items enable row level security;
alter table public.warehouse_day_closures enable row level security;

-- Responsables : visibles par l'équipe de l'entrepôt ; seul l'admin les gère.
create policy warehouse_managers_select on public.warehouse_managers
  for select to authenticated using (private.can_manage_warehouse(warehouse_id));
create policy warehouse_managers_admin_write on public.warehouse_managers
  for all to authenticated
  using (private.is_org_admin(organization_id)) with check (private.is_org_admin(organization_id));

-- Tickets et notes : l'équipe de l'entrepôt a la main libre.
create policy warehouse_tickets_manage on public.warehouse_tickets
  for all to authenticated
  using (private.can_manage_warehouse(warehouse_id)) with check (private.can_manage_warehouse(warehouse_id));
create policy warehouse_ticket_notes_manage on public.warehouse_ticket_notes
  for all to authenticated
  using (private.can_manage_warehouse(warehouse_id)) with check (private.can_manage_warehouse(warehouse_id));

-- Demandes d'approvisionnement : lecture par l'équipe ; création et décisions via fonctions contrôlées.
create policy warehouse_supply_requests_select on public.warehouse_supply_requests
  for select to authenticated using (private.can_manage_warehouse(warehouse_id));
create policy warehouse_supply_requests_admin_write on public.warehouse_supply_requests
  for all to authenticated
  using (private.is_org_admin(organization_id)) with check (private.is_org_admin(organization_id));
create policy warehouse_supply_request_items_select on public.warehouse_supply_request_items
  for select to authenticated using (private.can_manage_warehouse(warehouse_id));
create policy warehouse_supply_request_items_admin_write on public.warehouse_supply_request_items
  for all to authenticated
  using (private.is_org_admin(organization_id)) with check (private.is_org_admin(organization_id));

-- Clôtures : lecture seule (écriture par la fonction de clôture).
create policy warehouse_day_closures_select on public.warehouse_day_closures
  for select to authenticated using (private.can_manage_warehouse(warehouse_id));

-- ---------- Privilèges ----------
revoke all on public.warehouse_managers, public.warehouse_tickets, public.warehouse_ticket_notes,
  public.warehouse_supply_requests, public.warehouse_supply_request_items, public.warehouse_day_closures
  from public, anon;
grant select, insert, update, delete on public.warehouse_managers, public.warehouse_supply_requests,
  public.warehouse_supply_request_items to authenticated;
grant select, insert, update, delete on public.warehouse_tickets, public.warehouse_ticket_notes to authenticated;
grant select on public.warehouse_day_closures to authenticated;
grant all on public.warehouse_managers, public.warehouse_tickets, public.warehouse_ticket_notes,
  public.warehouse_supply_requests, public.warehouse_supply_request_items, public.warehouse_day_closures
  to service_role;