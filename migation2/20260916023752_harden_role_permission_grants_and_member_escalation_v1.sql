-- BLOCK 9: harden role/permission grants and prevent cross-company self-enrollment

-- Prevent a normal authenticated user from inserting themselves as business_admin
-- into an arbitrary organization. Self-created business_admin membership is valid
-- only when the user is the organization's owner (the onboarding flow).
drop policy if exists members_insert on public.organization_members;
create policy members_insert
on public.organization_members
for insert
to authenticated
with check (
  private.is_org_admin(organization_id)
  or private.is_super_admin()
  or (
    user_id = (select auth.uid())
    and role = 'business_admin'
    and exists (
      select 1
      from public.organizations o
      where o.id = organization_id
        and o.owner_user_id = (select auth.uid())
    )
  )
);

-- No anonymous access to internal authorization tables.
revoke all privileges on table
  public.organization_members,
  public.user_permissions,
  public.super_admins,
  public.super_admin_modules
from anon;

-- Authorization catalog is read-only for authenticated users.
revoke insert, update, delete, truncate, references, trigger
on table public.permissions, public.role_permissions
from anon, authenticated;

grant select on table public.permissions, public.role_permissions
to authenticated;

-- SUPER ADMIN registry is never writable through the Data API.
revoke insert, update, delete, truncate, references, trigger
on table public.super_admins
from authenticated;

grant select on table public.super_admins
to authenticated;

-- Remove TRUNCATE from membership/permission assignment tables.
-- RLS does not protect TRUNCATE, so this privilege must be explicitly removed.
revoke truncate
on table public.organization_members, public.user_permissions, public.super_admin_modules
from authenticated;

-- Permission assignment remains SUPER ADMIN controlled by RLS policies.
-- Keep the normal authenticated table privileges required by those policies.;
