-- 1) Le contrôle « service_role » lisait un réglage qui peut être absent selon la version de PostgREST.
--    On utilise auth.role(), qui lit aussi bien l'ancien que le nouveau format de jeton.
DO $$
DECLARE
  f record;
  def text;
BEGIN
  FOR f IN
    SELECT p.oid
    FROM pg_proc p JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.proname IN ('jdvcrm_confirm_subscription_payment_v1', 'jdvcrm_process_subscription_webhook_v1')
  LOOP
    def := pg_get_functiondef(f.oid);
    def := replace(def,
      'current_setting(''request.jwt.claim.role'', true) <> ''service_role''',
      'coalesce(auth.role(), '''') <> ''service_role''');
    EXECUTE def;
  END LOOP;
END $$;

-- 2) Préparer un paiement d'abonnement : le montant et le plan viennent de la base,
--    jamais du navigateur. Réservé à la clé serveur (service_role).
CREATE OR REPLACE FUNCTION public.jdvcrm_prepare_subscription_payment_v1(
  p_organization_id uuid,
  p_plan_code text
)
RETURNS TABLE(payment_id uuid, subscription_id uuid, amount numeric, currency text, plan_code text, plan_name text)
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_plan public.subscription_plans;
  v_sub public.organization_subscriptions;
  v_pay public.subscription_payments;
BEGIN
  IF coalesce(auth.role(), '') <> 'service_role' THEN
    RAISE EXCEPTION 'SERVICE_ROLE_REQUIRED';
  END IF;

  SELECT * INTO v_plan FROM public.subscription_plans
  WHERE code = upper(trim(p_plan_code)) AND active = true;
  IF NOT FOUND OR v_plan.code = 'TRIAL' THEN
    RAISE EXCEPTION 'PLAN_NOT_AVAILABLE';
  END IF;
  IF coalesce(v_plan.billing_amount_xof, 0) <= 0 THEN
    RAISE EXCEPTION 'PLAN_FEDAPAY_AMOUNT_NOT_CONFIGURED';
  END IF;

  PERFORM 1 FROM public.organizations WHERE id = p_organization_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'ORGANIZATION_NOT_FOUND'; END IF;

  SELECT * INTO v_sub FROM public.organization_subscriptions os
  WHERE os.organization_id = p_organization_id
    AND os.status IN ('pending', 'trial', 'active', 'past_due')
  ORDER BY os.created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO public.organization_subscriptions(organization_id, plan_id, status)
    VALUES (p_organization_id, v_plan.id, 'pending')
    RETURNING * INTO v_sub;
  END IF;

  INSERT INTO public.subscription_payments(organization_id, subscription_id, amount, currency, provider, status, metadata)
  VALUES (
    p_organization_id, v_sub.id, v_plan.billing_amount_xof, 'XOF', 'fedapay', 'pending',
    jsonb_build_object('plan_code', v_plan.code, 'plan_id', v_plan.id, 'source', 'payment_wall')
  )
  RETURNING * INTO v_pay;

  RETURN QUERY SELECT v_pay.id, v_sub.id, v_pay.amount, v_pay.currency, v_plan.code, v_plan.name;
END;
$function$;

-- 3) Régler un paiement confirmé par FedaPay : applique le plan choisi puis active l'abonnement.
CREATE OR REPLACE FUNCTION public.jdvcrm_settle_fedapay_payment_v1(
  p_payment_id uuid,
  p_transaction_id text,
  p_amount numeric,
  p_currency text,
  p_event_id text,
  p_event_type text,
  p_payload jsonb
)
RETURNS public.subscription_payments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  v_pay public.subscription_payments;
  v_plan_id uuid;
  v_result public.subscription_payments;
BEGIN
  IF coalesce(auth.role(), '') <> 'service_role' THEN
    RAISE EXCEPTION 'SERVICE_ROLE_REQUIRED';
  END IF;

  SELECT * INTO v_pay FROM public.subscription_payments WHERE id = p_payment_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'PAYMENT_NOT_FOUND'; END IF;
  IF v_pay.provider IS DISTINCT FROM 'fedapay' THEN RAISE EXCEPTION 'PAYMENT_PROVIDER_MISMATCH'; END IF;
  IF v_pay.provider_reference IS DISTINCT FROM trim(p_transaction_id) THEN
    RAISE EXCEPTION 'PAYMENT_REFERENCE_MISMATCH';
  END IF;

  -- Déjà réglé : on ne refait rien (les webhooks peuvent arriver plusieurs fois).
  IF v_pay.status = 'successful' THEN
    RETURN v_pay;
  END IF;

  -- Le plan choisi au moment du paiement est appliqué à l'abonnement de l'entreprise.
  v_plan_id := nullif(v_pay.metadata->>'plan_id', '')::uuid;
  IF v_plan_id IS NOT NULL THEN
    UPDATE public.organization_subscriptions
       SET plan_id = v_plan_id, updated_at = now()
     WHERE id = v_pay.subscription_id
       AND status IN ('pending', 'trial', 'active', 'past_due')
       AND plan_id <> v_plan_id;
  END IF;

  v_result := public.jdvcrm_process_subscription_webhook_v1(
    'fedapay', p_event_id, p_event_type, v_pay.subscription_id,
    p_amount, p_currency, trim(p_transaction_id), NULL, p_payload
  );
  RETURN v_result;
END;
$function$;

REVOKE ALL ON FUNCTION public.jdvcrm_prepare_subscription_payment_v1(uuid, text) FROM PUBLIC, anon, authenticated;
REVOKE ALL ON FUNCTION public.jdvcrm_settle_fedapay_payment_v1(uuid, text, numeric, text, text, text, jsonb) FROM PUBLIC, anon, authenticated;
GRANT EXECUTE ON FUNCTION public.jdvcrm_prepare_subscription_payment_v1(uuid, text) TO service_role;
GRANT EXECUTE ON FUNCTION public.jdvcrm_settle_fedapay_payment_v1(uuid, text, numeric, text, text, text, jsonb) TO service_role;
