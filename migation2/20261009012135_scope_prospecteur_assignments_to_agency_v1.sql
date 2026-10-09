-- Les affectations de prospecteurs : administrateurs de l'entreprise partout ; chef d'agence uniquement sur son entrepôt
drop policy if exists prospecteur_warehouse_assignment_admin_write on public.prospecteur_warehouse_assignments;
create policy prospecteur_warehouse_assignment_admin_write on public.prospecteur_warehouse_assignments
  for all to authenticated
  using ((select private.is_org_admin(organization_id)))
  with check ((select private.is_org_admin(organization_id)));