-- Correction : les rôles applicatifs n'ont pas accès au schéma « private ».
-- Les deux gardes lisent donc directement public.super_admins (lecture de sa propre ligne
-- autorisée par RLS) au lieu d'appeler private.is_super_admin().
-- Les fonctions internes SECURITY DEFINER s'exécutent sous le propriétaire :
-- elles ne sont pas concernées par ces gardes.

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

CREATE OR REPLACE FUNCTION private.guard_organization_platform_fields()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public', 'auth'
AS $function$
BEGIN
  IF current_user IN ('authenticated', 'anon')
     AND (NEW.status IS DISTINCT FROM OLD.status
          OR NEW.subscription_status IS DISTINCT FROM OLD.subscription_status)
     AND NOT EXISTS (
       SELECT 1 FROM public.super_admins sa
       WHERE sa.user_id = auth.uid() AND sa.status = 'active' AND COALESCE(sa.actif, true)
     ) THEN
    RAISE EXCEPTION 'SUPER_ADMIN_REQUIRED';
  END IF;
  RETURN NEW;
END;
$function$;
