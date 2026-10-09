-- Authorization catalogs are not public application data.
revoke all privileges on table public.permissions, public.role_permissions from anon;
revoke all privileges on table public.super_admins from anon;
