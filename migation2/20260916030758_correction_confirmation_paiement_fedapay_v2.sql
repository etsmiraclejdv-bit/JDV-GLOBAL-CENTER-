BEGIN;

CREATE OR REPLACE FUNCTION public.jdvcrm_confirm_subscription_payment_v1(
  p_subscription_id uuid,
  p_amount numeric,
  p_currency text,
  p_provider text,
  p_provider_reference text,
  p_payment_method text DEFAULT NULL::text,
  p_metadata jsonb DEFAULT '{}'::jsonb
)
RETURNS public.subscription_payments
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private'
AS $function$
DECLARE
  v_sub public.organization_subscriptions;
  v_plan public.subscription_plans;
  v_payment public.subscription_payments;
  v_existing_payment public.subscription_payments;
  v_start timestamptz;
  v_end timestamptz;
  v_now timestamptz := now();
  v_currency text;
  v_provider text;
  v_provider_reference text;
  v_plan_amount_xof numeric;
BEGIN
  IF current_setting('request.jwt.claim.role', true) <> 'service_role'
     AND (
       auth.uid() IS NULL
       OR NOT private.is_super_admin()
     )
  THEN
    RAISE EXCEPTION 'SERVICE_ROLE_OR_SUPER_ADMIN_REQUIRED';
  END IF;

  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'INVALID_AMOUNT';
  END IF;

  IF NULLIF(trim(p_provider), '') IS NULL THEN
    RAISE EXCEPTION 'PROVIDER_REQUIRED';
  END IF;

  IF NULLIF(trim(p_provider_reference), '') IS NULL THEN
    RAISE EXCEPTION 'PROVIDER_REFERENCE_REQUIRED';
  END IF;

  IF NULLIF(trim(p_currency), '') IS NULL THEN
    RAISE EXCEPTION 'CURRENCY_REQUIRED';
  END IF;

  v_provider := lower(trim(p_provider));
  v_currency := upper(trim(p_currency));
  v_provider_reference := trim(p_provider_reference);

  SELECT * INTO v_sub
  FROM public.organization_subscriptions
  WHERE id = p_subscription_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SUBSCRIPTION_NOT_FOUND';
  END IF;

  SELECT * INTO v_plan
  FROM public.subscription_plans
  WHERE id = v_sub.plan_id
    AND active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PLAN_NOT_FOUND';
  END IF;

  IF v_provider = 'fedapay' THEN
    IF v_currency <> 'XOF' THEN
      RAISE EXCEPTION 'FEDAPAY_CURRENCY_MUST_BE_XOF';
    END IF;

    v_plan_amount_xof := v_plan.billing_amount_xof;

    IF v_plan_amount_xof IS NULL OR v_plan_amount_xof <= 0 THEN
      RAISE EXCEPTION 'PLAN_FEDAPAY_AMOUNT_NOT_CONFIGURED';
    END IF;

    IF p_amount <> v_plan_amount_xof THEN
      RAISE EXCEPTION 'FEDAPAY_AMOUNT_MISMATCH';
    END IF;
  END IF;

  SELECT * INTO v_existing_payment
  FROM public.subscription_payments
  WHERE provider = v_provider
    AND provider_reference = v_provider_reference
  LIMIT 1
  FOR UPDATE;

  IF FOUND THEN
    IF v_existing_payment.subscription_id IS DISTINCT FROM p_subscription_id THEN
      RAISE EXCEPTION 'PAYMENT_SUBSCRIPTION_MISMATCH';
    END IF;

    IF v_existing_payment.organization_id IS DISTINCT FROM v_sub.organization_id THEN
      RAISE EXCEPTION 'PAYMENT_ORGANIZATION_MISMATCH';
    END IF;

    IF v_existing_payment.status = 'successful' THEN
      RETURN v_existing_payment;
    END IF;

    IF v_existing_payment.status IN ('refunded', 'cancelled') THEN
      RAISE EXCEPTION 'PAYMENT_ALREADY_CLOSED';
    END IF;

    UPDATE public.subscription_payments
    SET
      amount = p_amount,
      currency = v_currency,
      provider = v_provider,
      provider_reference = v_provider_reference,
      payment_method = COALESCE(p_payment_method, payment_method),
      status = 'successful',
      paid_at = v_now,
      metadata = COALESCE(metadata, '{}'::jsonb)
        || COALESCE(p_metadata, '{}'::jsonb)
        || jsonb_build_object(
          'confirmed_at', v_now,
          'confirmation_source', 'jdvcrm_confirm_subscription_payment_v1'
        )
    WHERE id = v_existing_payment.id
    RETURNING * INTO v_payment;
  ELSE
    INSERT INTO public.subscription_payments(
      organization_id,
      subscription_id,
      amount,
      currency,
      provider,
      provider_reference,
      payment_method,
      status,
      paid_at,
      metadata
    )
    VALUES(
      v_sub.organization_id,
      p_subscription_id,
      p_amount,
      v_currency,
      v_provider,
      v_provider_reference,
      p_payment_method,
      'successful',
      v_now,
      COALESCE(p_metadata, '{}'::jsonb)
        || jsonb_build_object(
          'confirmed_at', v_now,
          'confirmation_source', 'jdvcrm_confirm_subscription_payment_v1'
        )
    )
    RETURNING * INTO v_payment;
  END IF;

  v_start := CASE
    WHEN v_sub.status IN ('active', 'trial', 'past_due')
      AND v_sub.expires_at IS NOT NULL
      AND v_sub.expires_at > v_now
    THEN v_sub.expires_at
    ELSE v_now
  END;

  v_end := v_start + make_interval(days => v_plan.duration_days);

  UPDATE public.organization_subscriptions
  SET
    status = 'active',
    started_at = COALESCE(started_at, v_now),
    expires_at = v_end,
    external_reference = v_provider_reference,
    updated_at = v_now
  WHERE id = p_subscription_id;

  UPDATE public.organization_subscriptions
  SET
    status = 'cancelled',
    auto_renew = false,
    updated_at = v_now
  WHERE organization_id = v_sub.organization_id
    AND status = 'trial'
    AND id <> p_subscription_id;

  UPDATE public.organizations
  SET
    status = 'active',
    subscription_status = 'active',
    updated_at = v_now
  WHERE id = v_sub.organization_id;

  INSERT INTO public.subscription_events(
    organization_id,
    subscription_id,
    event_type,
    provider,
    provider_reference,
    amount,
    currency,
    metadata
  )
  VALUES(
    v_sub.organization_id,
    p_subscription_id,
    'payment_succeeded',
    v_provider,
    v_provider_reference,
    p_amount,
    v_currency,
    COALESCE(p_metadata, '{}'::jsonb)
      || jsonb_build_object(
        'confirmed_at', v_now,
        'plan_code', v_plan.code,
        'plan_name', v_plan.name,
        'expires_at', v_end
      )
  );

  RETURN v_payment;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.jdvcrm_confirm_subscription_payment_v1(uuid, numeric, text, text, text, text, jsonb) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.jdvcrm_confirm_subscription_payment_v1(uuid, numeric, text, text, text, text, jsonb) FROM anon;
REVOKE EXECUTE ON FUNCTION public.jdvcrm_confirm_subscription_payment_v1(uuid, numeric, text, text, text, text, jsonb) FROM authenticated;

GRANT EXECUTE ON FUNCTION public.jdvcrm_confirm_subscription_payment_v1(uuid, numeric, text, text, text, text, jsonb) TO service_role;
GRANT EXECUTE ON FUNCTION public.jdvcrm_confirm_subscription_payment_v1(uuid, numeric, text, text, text, text, jsonb) TO postgres;

COMMIT;
