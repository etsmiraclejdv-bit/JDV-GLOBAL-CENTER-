-- Allow a prospecteur to read only the active primary warehouse to which they are assigned.
-- No write access is granted and no other warehouse rows become visible.
create policy "prospecteurs_read_primary_assigned_warehouse"
on public.warehouses
for select
to authenticated
using (
  exists (
    select 1
    from public.prospecteur_warehouse_assignments pwa
    join public.prospecteurs p
      on p.id = pwa.prospecteur_id
    where pwa.warehouse_id = warehouses.id
      and pwa.organization_id = warehouses.organization_id
      and pwa.active = true
      and pwa.is_primary = true
      and p.user_id = (select auth.uid())
  )
);
