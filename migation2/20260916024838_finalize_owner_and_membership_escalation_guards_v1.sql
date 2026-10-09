CREATE OR REPLACE FUNCTION private.guard_organization_owner_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $function$
BEGIN
  IF NEW.owner_user_id IS DISTINCT FROM OLD.owner_user_id
     AND NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'ORGANIZATION_OWNER_CHANGE_FORBIDDEN';
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_guard_organization_owner_change ON public.organizations;
CREATE TRIGGER trg_guard_organization_owner_change
BEFORE UPDATE OF owner_user_id ON public.organizations
FOR EACH ROW
EXECUTE FUNCTION private.guard_organization_owner_change();

CREATE OR REPLACE FUNCTION private.guard_membership_user_change()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public, private
AS $function$
BEGIN
  IF NEW.user_id IS DISTINCT FROM OLD.user_id
     AND NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'MEMBERSHIP_USER_CHANGE_FORBIDDEN';
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_guard_membership_user_change ON public.organization_members;
CREATE TRIGGER trg_guard_membership_user_change
BEFORE UPDATE OF user_id ON public.organization_members
FOR EACH ROW
EXECUTE FUNCTION private.guard_membership_user_change();
