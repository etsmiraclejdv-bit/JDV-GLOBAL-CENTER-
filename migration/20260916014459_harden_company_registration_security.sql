BEGIN;

-- The Auth trigger function is invoked by Postgres internally; it must not be callable
-- by normal authenticated clients.
REVOKE EXECUTE ON FUNCTION public.handle_new_user() FROM anon, authenticated;

-- Company registration is intentionally available only after authentication.
REVOKE EXECUTE ON FUNCTION public.register_company(text,text,text,text,text) FROM anon;
GRANT EXECUTE ON FUNCTION public.register_company(text,text,text,text,text) TO authenticated;

-- Super Admin remains the only role with unrestricted organization creation/editing.
-- Keep the existing authenticated owner insert rule because it is constrained to auth.uid().
-- Keep organization_members INSERT because it is required for controlled member onboarding.

COMMIT;
