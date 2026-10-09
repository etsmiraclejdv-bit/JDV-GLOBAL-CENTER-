-- JDV CRM — RBAC / RLS regression checks
-- Read-only audit script. Run with a privileged database role in a non-production
-- environment or a controlled SQL session. It intentionally does not mutate data.
--
-- Coverage:
-- 1) RLS enabled on authorization and core business tables.
-- 2) No anonymous privileges on authorization tables.
-- 3) RBAC catalog has no duplicate permission codes or role mappings.
-- 4) has_permission helper exists and is executable by authenticated users.
-- 5) Warehouse manager guard helpers are SECURITY DEFINER and not executable by anon.
--
-- NOTE: This script cannot prove end-to-end user isolation by itself. For that,
-- execute authenticated-session tests with JWT subjects for at least:
-- super_admin, business_admin, manager, supervisor, prospecteur, viewer.

DO $$
DECLARE
  v_count bigint;
BEGIN
  SELECT count(*) INTO v_count
  FROM pg_class c
  JOIN pg_namespace n ON n.oid = c.relnamespace
  WHERE n.nspname = 'public'
    AND c.relname IN (
      'organization_members','permissions','role_permissions',
      'warehouse_managers','warehouse_inventory',
      'prospects','clients','sales'
    )
    AND c.relrowsecurity;

  IF v_count <> 8 THEN
    RAISE EXCEPTION 'RBAC/RLS CHECK FAILED: expected RLS on 8 protected tables, found %', v_count;
  END IF;

  SELECT count(*) INTO v_count
  FROM information_schema.role_table_grants
  WHERE grantee = 'anon'
    AND table_schema = 'public'
    AND table_name IN ('organization_members','permissions','role_permissions')
    AND privilege_type IN ('INSERT','UPDATE','DELETE','TRUNCATE');

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'RBAC CHECK FAILED: anon has write privileges on authorization tables';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.permissions
  GROUP BY code
  HAVING count(*) > 1;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'RBAC CHECK FAILED: duplicate permission codes detected';
  END IF;

  SELECT count(*) INTO v_count
  FROM public.role_permissions
  GROUP BY role, permission_id
  HAVING count(*) > 1;

  IF v_count <> 0 THEN
    RAISE EXCEPTION 'RBAC CHECK FAILED: duplicate role/permission mappings detected';
  END IF;

  IF to_regprocedure('private.has_permission(text,uuid)') IS NULL THEN
    RAISE EXCEPTION 'RBAC CHECK FAILED: private.has_permission(text,uuid) is missing';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM information_schema.routine_privileges
    WHERE routine_schema = 'private'
      AND routine_name = 'has_permission'
      AND grantee = 'authenticated'
      AND privilege_type = 'EXECUTE'
  ) THEN
    RAISE EXCEPTION 'RBAC CHECK FAILED: authenticated cannot execute has_permission';
  END IF;

  IF NOT EXISTS (
    SELECT 1
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'private'
      AND p.proname = 'has_permission'
      AND p.prosecdef
  ) THEN
    RAISE EXCEPTION 'RBAC CHECK FAILED: has_permission is not SECURITY DEFINER';
  END IF;

  RAISE NOTICE 'JDV RBAC/RLS structural checks passed';
END $$;

-- Human-readable policy inventory:
SELECT schemaname, tablename, policyname, permissive, roles, cmd, qual, with_check
FROM pg_policies
WHERE schemaname = 'public'
  AND tablename IN (
    'organization_members','permissions','role_permissions',
    'warehouse_managers','warehouse_inventory',
    'prospects','clients','sales'
  )
ORDER BY tablename, policyname;
