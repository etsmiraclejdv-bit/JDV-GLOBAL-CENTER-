-- 1) Abonnements : seul le concepteur (super admin) peut créer ou modifier un abonnement.
--    Les admins d'entreprise gardent la lecture de leur propre abonnement.
DROP POLICY IF EXISTS subscriptions_insert ON public.organization_subscriptions;
DROP POLICY IF EXISTS subscriptions_update ON public.organization_subscriptions;

-- 2) Paiements d'abonnement : seul le concepteur peut en enregistrer.
DROP POLICY IF EXISTS subscription_payments_insert ON public.subscription_payments;
CREATE POLICY subscription_payments_insert ON public.subscription_payments
  FOR INSERT TO authenticated
  WITH CHECK (private.is_super_admin());

-- 3) Organisations : un utilisateur connecté (non concepteur) ne peut plus modifier
--    lui-même le statut ni l'état d'abonnement de son entreprise.
--    Les fonctions internes (SECURITY DEFINER) restent autorisées.
CREATE OR REPLACE FUNCTION private.guard_organization_platform_fields()
RETURNS trigger
LANGUAGE plpgsql
SET search_path TO 'public', 'private'
AS $function$
BEGIN
  IF current_user IN ('authenticated', 'anon')
     AND NOT private.is_super_admin()
     AND (NEW.status IS DISTINCT FROM OLD.status
          OR NEW.subscription_status IS DISTINCT FROM OLD.subscription_status) THEN
    RAISE EXCEPTION 'SUPER_ADMIN_REQUIRED';
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS guard_organization_platform_fields ON public.organizations;
CREATE TRIGGER guard_organization_platform_fields
  BEFORE UPDATE ON public.organizations
  FOR EACH ROW EXECUTE FUNCTION private.guard_organization_platform_fields();

-- 4) Journal de démonstration : uniquement pour l'utilisateur connecté, pas d'accès anonyme.
REVOKE ALL ON FUNCTION private.guard_organization_platform_fields() FROM PUBLIC, anon, authenticated;
