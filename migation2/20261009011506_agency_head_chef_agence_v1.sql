-- Chef d'agence : la personne qui pilote un entrepôt (agence) et ses sous-entrepôts.
-- Basé sur warehouse_managers (un chef d'agence actif par entrepôt).

-- 1. Un seul chef d'agence actif par entrepôt
create unique index if not exists warehouse_managers_one_active_head
  on public.warehouse_managers (warehouse_id) where status = 'active';

-- 2. warehouses.manager_user_id suit toujours le chef d'agence actif
create or replace function public.jdvcrm_sync_warehouse_head_v1()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if tg_op = 'DELETE' then
    update public.warehouses set manager_user_id = null where id = OLD.warehouse_id and manager_user_id = OLD.user_id;
    return OLD;
  end if;
  if NEW.status = 'active' then
    update public.warehouses set manager_user_id = NEW.user_id where id = NEW.warehouse_id;
  else
    update public.warehouses set manager_user_id = null where id = NEW.warehouse_id and manager_user_id = NEW.user_id;
  end if;
  return NEW;
end $$;

drop trigger if exists jdvcrm_sync_warehouse_head on public.warehouse_managers;
create trigger jdvcrm_sync_warehouse_head
  after insert or update of status, user_id, warehouse_id or delete on public.warehouse_managers
  for each row execute function public.jdvcrm_sync_warehouse_head_v1();

update public.warehouses w set manager_user_id = m.user_id
  from public.warehouse_managers m
 where m.warehouse_id = w.id and m.status = 'active' and w.manager_user_id is distinct from m.user_id;

-- 3. Le chef d'agence gère les sous-entrepôts de SON entrepôt (création, modification, responsable)
drop policy if exists warehouse_subwarehouses_admin_insert on public.warehouse_subwarehouses;
create policy warehouse_subwarehouses_admin_insert on public.warehouse_subwarehouses
  for insert to authenticated
  with check (
    (select private.is_org_admin(organization_id))
    or (
      (select private.can_manage_warehouse(parent_warehouse_id))
      and organization_id = (select w.organization_id from public.warehouses w where w.id = parent_warehouse_id)
    )
  );

drop policy if exists warehouse_subwarehouses_admin_update on public.warehouse_subwarehouses;
create policy warehouse_subwarehouses_admin_update on public.warehouse_subwarehouses
  for update to authenticated
  using (
    (select private.is_org_admin(organization_id))
    or (select private.can_manage_warehouse(parent_warehouse_id))
  )
  with check (
    (select private.is_org_admin(organization_id))
    or (
      (select private.can_manage_warehouse(parent_warehouse_id))
      and organization_id = (select w.organization_id from public.warehouses w where w.id = parent_warehouse_id)
    )
  );

-- 4. Le chef d'agence affecte les prospecteurs à SON entrepôt (en plus des règles existantes)
drop policy if exists prospecteur_warehouse_assignment_head_write on public.prospecteur_warehouse_assignments;
create policy prospecteur_warehouse_assignment_head_write on public.prospecteur_warehouse_assignments
  for all to authenticated
  using ((select private.can_manage_warehouse(warehouse_id)))
  with check (
    (select private.can_manage_warehouse(warehouse_id))
    and organization_id = (select w.organization_id from public.warehouses w where w.id = warehouse_id)
  );