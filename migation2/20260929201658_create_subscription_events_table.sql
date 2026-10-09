-- Table d'historique des abonnements, attendue par jdvcrm_confirm_subscription_payment_v1
-- (elle n'existait pas : toute confirmation de paiement échouait).
CREATE TABLE IF NOT EXISTS public.subscription_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  organization_id uuid NOT NULL REFERENCES public.organizations(id) ON DELETE CASCADE,
  subscription_id uuid REFERENCES public.organization_subscriptions(id) ON DELETE SET NULL,
  event_type text NOT NULL,
  provider text,
  provider_reference text,
  amount numeric,
  currency text,
  metadata jsonb NOT NULL DEFAULT '{}'::jsonb,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_subscription_events_org_created
  ON public.subscription_events (organization_id, created_at DESC);

ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;

-- Lecture : le concepteur voit tout, un admin d'entreprise voit l'historique de son entreprise.
-- Aucune écriture directe : seules les fonctions sécurisées alimentent cette table.
CREATE POLICY subscription_events_select ON public.subscription_events
  FOR SELECT TO authenticated
  USING (private.is_super_admin() OR private.is_org_admin(organization_id));
