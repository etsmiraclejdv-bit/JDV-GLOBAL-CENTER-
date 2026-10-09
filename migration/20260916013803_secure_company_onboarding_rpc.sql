CREATE OR REPLACE FUNCTION public.create_company_onboarding(
  p_user_id uuid,
  p_company_name text,
  p_legal_name text,
  p_email text,
  p_phone text,
  p_country text,
  p_city text,
  p_address text,
  p_website text,
  p_industry text,
  p_team_size text,
  p_plan_code text,
  p_first_name text,
  p_last_name text
)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private'
AS $$
DECLARE
  v_org uuid;
  v_plan uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'AUTHENTICATION_REQUIRED';
  END IF;

  IF auth.uid() <> p_user_id AND NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'ACCESS_DENIED';
  END IF;

  IF p_company_name IS NULL OR trim(p_company_name) = '' THEN
    RAISE EXCEPTION 'COMPANY_NAME_REQUIRED';
  END IF;

  SELECT id INTO v_plan
  FROM public.subscription_plans
  WHERE code = upper(trim(p_plan_code))
    AND active = true
  LIMIT 1;

  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'PLAN_NOT_FOUND';
  END IF;

  INSERT INTO public.organizations(
    name, legal_name, email, phone, country, city, address, website,
    status, subscription_status, language, currency, timezone, owner_user_id
  )
  VALUES(
    trim(p_company_name), p_legal_name, p_email, p_phone,
    coalesce(nullif(trim(p_country), ''), 'Bénin'), p_city, p_address, p_website,
    'trial', 'trial', 'fr', 'XOF', 'Africa/Porto-Novo', p_user_id
  )
  RETURNING id INTO v_org;

  INSERT INTO public.profiles(
    id, first_name, last_name, display_name, phone, country,
    preferred_language, status
  )
  VALUES(
    p_user_id, p_first_name, p_last_name,
    trim(coalesce(p_first_name,'') || ' ' || coalesce(p_last_name,'')),
    p_phone, p_country, 'fr', 'active'
  )
  ON CONFLICT(id) DO UPDATE SET
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    display_name = excluded.display_name,
    phone = excluded.phone,
    country = excluded.country,
    preferred_language = 'fr',
    status = 'active',
    updated_at = now();

  INSERT INTO public.organization_members(organization_id, user_id, role, status)
  VALUES(v_org, p_user_id, 'business_admin', 'active');

  INSERT INTO public.organization_settings(organization_id, settings)
  VALUES(
    v_org,
    jsonb_build_object(
      'industry', coalesce(p_industry,''),
      'team_size', coalesce(p_team_size,''),
      'address', coalesce(p_address,''),
      'website', coalesce(p_website,''),
      'language', 'fr',
      'currency', 'XOF',
      'timezone', 'Africa/Porto-Novo'
    )
  );

  INSERT INTO public.organization_subscriptions(
    organization_id, plan_id, status, started_at, expires_at, auto_renew
  )
  SELECT v_org, id, 'trial', now(), now() + interval '14 days', false
  FROM public.subscription_plans
  WHERE code = 'TRIAL' AND active = true
  LIMIT 1
  ON CONFLICT DO NOTHING;

  RETURN v_org;
END;
$$;
