-- Une organisation créée directement par un utilisateur connecté démarre toujours
-- en « pending / inactive ». Seul le concepteur (ou les fonctions internes
-- sécurisées comme create_company_onboarding) peut donner un autre statut.
CREATE OR REPLACE FUNCTION private.force_initial_organization_status()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public', 'private'
AS $function$
BEGIN
  IF current_user IN ('authenticated', 'anon')
     AND NOT private.is_super_admin() THEN
    NEW.status := 'pending';
    NEW.subscription_status := 'inactive';
  END IF;
  RETURN NEW;
END;
$function$;

REVOKE ALL ON FUNCTION private.force_initial_organization_status() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS force_initial_organization_status ON public.organizations;
CREATE TRIGGER force_initial_organization_status
  BEFORE INSERT ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION private.force_initial_organization_status();
