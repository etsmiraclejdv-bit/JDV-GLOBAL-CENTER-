-- Une organisation créée directement par un utilisateur connecté démarre en « pending / inactive ».
CREATE OR REPLACE FUNCTION private.force_initial_organization_status()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public', 'auth'
AS $function$
BEGIN
  IF current_user IN ('authenticated', 'anon')
     AND NOT EXISTS (
       SELECT 1 FROM public.super_admins sa
       WHERE sa.user_id = auth.uid() AND sa.status = 'active' AND COALESCE(sa.actif, true)
     ) THEN
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
