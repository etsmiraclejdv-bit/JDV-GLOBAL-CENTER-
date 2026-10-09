REVOKE ALL ON FUNCTION private.guard_organization_owner_change() FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION private.guard_membership_user_change() FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION private.guard_organization_owner_change() TO postgres;
GRANT EXECUTE ON FUNCTION private.guard_membership_user_change() TO postgres;
