-- Référentiels (branches, rôles, actions permises) : lecture pour tout connecté, écriture réservée aux super admins
create policy "demo_branches_select_authenticated"
on public.demo_branches for select
to authenticated
using (true);

create policy "demo_branches_write_super_admin"
on public.demo_branches for all
to authenticated
using (exists (select 1 from public.super_admins sa where sa.user_id = auth.uid() and sa.status = 'active' and sa.actif = true))
with check (exists (select 1 from public.super_admins sa where sa.user_id = auth.uid() and sa.status = 'active' and sa.actif = true));

create policy "demo_roles_select_authenticated"
on public.demo_roles for select
to authenticated
using (true);

create policy "demo_roles_write_super_admin"
on public.demo_roles for all
to authenticated
using (exists (select 1 from public.super_admins sa where sa.user_id = auth.uid() and sa.status = 'active' and sa.actif = true))
with check (exists (select 1 from public.super_admins sa where sa.user_id = auth.uid() and sa.status = 'active' and sa.actif = true));

create policy "demo_actions_permises_select_authenticated"
on public.demo_actions_permises for select
to authenticated
using (true);

create policy "demo_actions_permises_write_super_admin"
on public.demo_actions_permises for all
to authenticated
using (exists (select 1 from public.super_admins sa where sa.user_id = auth.uid() and sa.status = 'active' and sa.actif = true))
with check (exists (select 1 from public.super_admins sa where sa.user_id = auth.uid() and sa.status = 'active' and sa.actif = true));

-- user_permissions : chaque utilisateur voit ses propres permissions ; seul un super admin peut créer/modifier/supprimer
create policy "user_permissions_select_own_or_admin"
on public.user_permissions for select
to authenticated
using (
  user_id = auth.uid()
  or exists (select 1 from public.super_admins sa where sa.user_id = auth.uid() and sa.status = 'active' and sa.actif = true)
);

create policy "user_permissions_insert_super_admin"
on public.user_permissions for insert
to authenticated
with check (exists (select 1 from public.super_admins sa where sa.user_id = auth.uid() and sa.status = 'active' and sa.actif = true));

create policy "user_permissions_update_super_admin"
on public.user_permissions for update
to authenticated
using (exists (select 1 from public.super_admins sa where sa.user_id = auth.uid() and sa.status = 'active' and sa.actif = true))
with check (exists (select 1 from public.super_admins sa where sa.user_id = auth.uid() and sa.status = 'active' and sa.actif = true));

create policy "user_permissions_delete_super_admin"
on public.user_permissions for delete
to authenticated
using (exists (select 1 from public.super_admins sa where sa.user_id = auth.uid() and sa.status = 'active' and sa.actif = true));

-- demo_actions_log : journal d'audit, lecture réservée aux super admins, écriture ouverte pour journaliser les actions des connectés
create policy "demo_actions_log_select_super_admin"
on public.demo_actions_log for select
to authenticated
using (exists (select 1 from public.super_admins sa where sa.user_id = auth.uid() and sa.status = 'active' and sa.actif = true));

create policy "demo_actions_log_insert_authenticated"
on public.demo_actions_log for insert
to authenticated
with check (true);
