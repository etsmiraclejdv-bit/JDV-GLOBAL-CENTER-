-- Seul le concepteur (super admin) agit sur toute la plateforme.

-- Abonnements et paiements d'abonnement : écriture réservée au concepteur.
DROP POLICY IF EXISTS subscriptions_insert ON public.organization_subscriptions;
DROP POLICY IF EXISTS subscriptions_update ON public.organization_subscriptions;

DROP POLICY IF EXISTS subscription_payments_insert ON public.subscription_payments;
CREATE POLICY subscription_payments_insert ON public.subscription_payments
  FOR INSERT TO authenticated
  WITH CHECK (private.is_super_admin());

-- Garde : un utilisateur connecté (non concepteur) ne change ni le statut ni l'abonnement
-- de son entreprise. Les fonctions SECURITY DEFINER (propriétaire) ne sont pas concernées.
-- Les rôles applicatifs n'ont pas accès au schéma « private » : on lit public.super_admins.
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

REVOKE ALL ON FUNCTION private.guard_organization_platform_fields() FROM PUBLIC, anon, authenticated;

DROP TRIGGER IF EXISTS guard_organization_platform_fields ON public.organizations;
CREATE TRIGGER guard_organization_platform_fields
  BEFORE UPDATE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION private.guard_organization_platform_fields();
