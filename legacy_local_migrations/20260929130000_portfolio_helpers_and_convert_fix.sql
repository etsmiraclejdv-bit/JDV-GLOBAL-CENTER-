-- Portefeuille clients de l'utilisateur connecté (créé si absent).
CREATE OR REPLACE FUNCTION public.jdvcrm_ensure_my_portfolio_v1(p_organization_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public', 'private'
AS $function$
DECLARE
  v_id uuid;
  v_type text;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'AUTHENTICATION_REQUIRED'; END IF;
  IF private.is_super_admin() THEN v_type := 'super_admin';
  ELSIF private.is_prospecteur(p_organization_id) THEN v_type := 'prospecteur';
  ELSE RAISE EXCEPTION 'ACCESS_DENIED';
  END IF;

  SELECT id INTO v_id FROM public.client_portfolios
  WHERE organization_id = p_organization_id AND owner_user_id = auth.uid() AND status = 'active'
  ORDER BY created_at LIMIT 1;

  IF v_id IS NULL THEN
    INSERT INTO public.client_portfolios(organization_id, owner_user_id, owner_type, name)
    VALUES (p_organization_id, auth.uid(), v_type,
            CASE WHEN v_type = 'super_admin' THEN 'Portefeuille concepteur' ELSE 'Mon portefeuille clients' END)
    RETURNING id INTO v_id;
  END IF;
  RETURN v_id;
END;
$function$;

REVOKE ALL ON FUNCTION public.jdvcrm_ensure_my_portfolio_v1(uuid) FROM PUBLIC, anon;
GRANT EXECUTE ON FUNCTION public.jdvcrm_ensure_my_portfolio_v1(uuid) TO authenticated;

-- La conversion prospect -> client garde le portefeuille du prospect.
CREATE OR REPLACE FUNCTION public.jdvcrm_convert_prospect_to_client_v1(p_prospect_id uuid)
RETURNS uuid
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
  pr public.prospects%ROWTYPE;
  c_id uuid;
  v_portfolio uuid;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentification requise'; END IF;
  SELECT * INTO pr FROM public.prospects WHERE id = p_prospect_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Prospect introuvable'; END IF;
  IF NOT (
    private.is_super_admin()
    OR private.is_org_admin(pr.organization_id)
    OR (private.is_prospecteur(pr.organization_id)
        AND EXISTS (SELECT 1 FROM public.prospecteurs p
                    WHERE p.id = pr.prospecteur_id AND p.user_id = auth.uid() AND p.status = 'active'))
  ) THEN
    RAISE EXCEPTION 'Accès refusé';
  END IF;
  IF pr.client_id IS NOT NULL THEN RETURN pr.client_id; END IF;

  v_portfolio := pr.portfolio_id;
  IF v_portfolio IS NULL AND pr.prospecteur_id IS NOT NULL THEN
    SELECT cp.id INTO v_portfolio
    FROM public.client_portfolios cp
    JOIN public.prospecteurs p ON p.user_id = cp.owner_user_id
    WHERE p.id = pr.prospecteur_id AND cp.organization_id = pr.organization_id AND cp.status = 'active'
    ORDER BY cp.created_at LIMIT 1;
  END IF;

  INSERT INTO public.clients(organization_id, prospecteur_id, portfolio_id, first_name, last_name, phone, whatsapp,
                             address, city, status, temperature, notes, last_contact_at, last_activity_at)
  VALUES (pr.organization_id, pr.prospecteur_id, v_portfolio, pr.first_name, pr.last_name, pr.phone, pr.whatsapp,
          pr.address, pr.city, 'active', pr.temperature, pr.notes, COALESCE(pr.last_contact_at, now()), now())
  RETURNING id INTO c_id;

  UPDATE public.prospects SET client_id = c_id, status = 'converted', updated_at = now() WHERE id = pr.id;
  RETURN c_id;
END $function$;
