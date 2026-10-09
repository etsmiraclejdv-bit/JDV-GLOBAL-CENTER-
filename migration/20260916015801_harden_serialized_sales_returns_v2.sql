alter table public.sales_return_items add column if not exists serial_number_id uuid;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname='sales_return_items_serial_number_id_fkey'
  ) THEN
    ALTER TABLE public.sales_return_items
      ADD CONSTRAINT sales_return_items_serial_number_id_fkey
      FOREIGN KEY (serial_number_id) REFERENCES public.serial_numbers(id) ON DELETE RESTRICT;
  END IF;
END $$;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_sale_return_item_serial_v2()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  v_return_org uuid;
  v_sale_id uuid;
  v_sale_org uuid;
  v_sale_article uuid;
  v_sale_client uuid;
  v_serial_org uuid;
  v_serial_article uuid;
  v_serial_sale uuid;
  v_serial_client uuid;
  v_serial_status text;
BEGIN
  SELECT organization_id, sale_id INTO v_return_org, v_sale_id
  FROM public.sales_returns WHERE id = NEW.return_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Retour introuvable'; END IF;
  IF v_return_org <> NEW.organization_id THEN RAISE EXCEPTION 'Article de retour incompatible avec l''organisation'; END IF;

  SELECT organization_id, article_id, client_id INTO v_sale_org, v_sale_article, v_sale_client
  FROM public.sales WHERE id = v_sale_id;
  IF NOT FOUND OR v_sale_org <> NEW.organization_id THEN RAISE EXCEPTION 'Vente incompatible avec le retour'; END IF;
  IF NEW.article_id <> v_sale_article THEN RAISE EXCEPTION 'Article retourné différent de l''article vendu'; END IF;

  IF NEW.serial_number_id IS NOT NULL THEN
    IF NEW.quantity <> 1 THEN RAISE EXCEPTION 'Un retour avec numéro de série doit avoir une quantité égale à 1'; END IF;
    SELECT organization_id, article_id, sale_id, client_id, status
      INTO v_serial_org, v_serial_article, v_serial_sale, v_serial_client, v_serial_status
    FROM public.serial_numbers WHERE id = NEW.serial_number_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Numéro de série introuvable'; END IF;
    IF v_serial_org <> NEW.organization_id OR v_serial_article <> NEW.article_id THEN
      RAISE EXCEPTION 'Numéro de série incompatible avec l''article ou l''organisation';
    END IF;
    IF v_serial_sale IS DISTINCT FROM v_sale_id THEN RAISE EXCEPTION 'Le numéro de série n''est pas lié à cette vente'; END IF;
    IF v_sale_client IS NOT NULL AND v_serial_client IS NOT NULL AND v_serial_client <> v_sale_client THEN
      RAISE EXCEPTION 'Numéro de série incompatible avec le client de la vente';
    END IF;
    IF v_serial_status NOT IN ('sold','returned') THEN
      RAISE EXCEPTION 'Le numéro de série n''est pas dans un état retournable';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$;

DROP TRIGGER IF EXISTS trg_jdvcrm_validate_sale_return_item_serial_v2 ON public.sales_return_items;
CREATE TRIGGER trg_jdvcrm_validate_sale_return_item_serial_v2
BEFORE INSERT OR UPDATE ON public.sales_return_items
FOR EACH ROW EXECUTE FUNCTION public.jdvcrm_validate_sale_return_item_serial_v2();

CREATE OR REPLACE FUNCTION public.jdvcrm_process_sale_return(p_return_id uuid)
RETURNS boolean
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = public
AS $function$
DECLARE
  r public.sales_returns%ROWTYPE;
  v_sale public.sales%ROWTYPE;
  i record;
  v_stock_id uuid;
  v_stock_qty integer;
  v_ps_id uuid;
  v_ps_qty integer;
  v_existing boolean;
  v_serial_org uuid;
  v_serial_article uuid;
  v_serial_sale uuid;
  v_serial_client uuid;
  v_serial_status text;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentification requise'; END IF;
  SELECT * INTO r FROM public.sales_returns WHERE id=p_return_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Retour introuvable'; END IF;
  SELECT * INTO v_sale FROM public.sales WHERE id=r.sale_id FOR UPDATE;
  IF NOT FOUND OR v_sale.organization_id<>r.organization_id THEN RAISE EXCEPTION 'Vente incompatible avec le retour'; END IF;
  IF r.status='processed' THEN RETURN true; END IF;
  IF r.status<>'approved' THEN RAISE EXCEPTION 'Le retour doit être approuvé avant traitement'; END IF;

  FOR i IN SELECT * FROM public.sales_return_items WHERE return_id=r.id ORDER BY id LOOP
    SELECT EXISTS(
      SELECT 1 FROM public.stock_movements
      WHERE organization_id=r.organization_id AND reference_type='sale_return'
        AND reference_id=r.id AND article_id=i.article_id AND movement_type='return'
        AND ((i.serial_number_id IS NULL AND notes NOT LIKE '%serial:%') OR (i.serial_number_id IS NOT NULL AND notes LIKE '%serial:'||i.serial_number_id::text||'%'))
    ) INTO v_existing;
    IF v_existing THEN CONTINUE; END IF;

    IF i.serial_number_id IS NOT NULL THEN
      SELECT organization_id, article_id, sale_id, client_id, status
        INTO v_serial_org, v_serial_article, v_serial_sale, v_serial_client, v_serial_status
      FROM public.serial_numbers WHERE id=i.serial_number_id FOR UPDATE;
      IF NOT FOUND OR v_serial_org<>r.organization_id OR v_serial_article<>i.article_id OR v_serial_sale<>r.sale_id THEN
        RAISE EXCEPTION 'Numéro de série incompatible avec le retour';
      END IF;
      IF v_sale.client_id IS NOT NULL AND v_serial_client IS NOT NULL AND v_serial_client<>v_sale.client_id THEN
        RAISE EXCEPTION 'Client incompatible avec le numéro de série';
      END IF;
      IF v_serial_status NOT IN ('sold','returned') THEN RAISE EXCEPTION 'Numéro de série non retournable'; END IF;
    END IF;

    IF v_sale.prospecteur_id IS NOT NULL THEN
      SELECT id, quantity INTO v_ps_id, v_ps_qty
      FROM public.prospecteur_stocks
      WHERE organization_id=r.organization_id AND prospecteur_id=v_sale.prospecteur_id AND article_id=i.article_id
      FOR UPDATE;
      IF NOT FOUND THEN
        INSERT INTO public.prospecteur_stocks(organization_id,prospecteur_id,article_id,quantity,updated_at)
        VALUES(r.organization_id,v_sale.prospecteur_id,i.article_id,i.quantity,now())
        RETURNING id,quantity INTO v_ps_id,v_ps_qty;
      ELSE
        UPDATE public.prospecteur_stocks SET quantity=quantity+i.quantity,updated_at=now() WHERE id=v_ps_id;
      END IF;
      INSERT INTO public.stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
      VALUES(r.organization_id,i.article_id,v_sale.prospecteur_id,'return',i.quantity,'sale_return',r.id,'client','stock_prospecteur','Réintégration retour '||r.return_number||CASE WHEN i.serial_number_id IS NOT NULL THEN ' serial:'||i.serial_number_id::text ELSE '' END,auth.uid(),now());
    ELSE
      SELECT id,quantity INTO v_stock_id,v_stock_qty FROM public.stocks
      WHERE organization_id=r.organization_id AND article_id=i.article_id FOR UPDATE;
      IF NOT FOUND THEN
        INSERT INTO public.stocks(organization_id,article_id,quantity,reserved_quantity,minimum_quantity,updated_at)
        VALUES(r.organization_id,i.article_id,i.quantity,0,0,now());
      ELSE
        UPDATE public.stocks SET quantity=quantity+i.quantity,updated_at=now() WHERE id=v_stock_id;
      END IF;
      INSERT INTO public.stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
      VALUES(r.organization_id,i.article_id,NULL,'return',i.quantity,'sale_return',r.id,'client','stock_principal','Réintégration retour '||r.return_number||CASE WHEN i.serial_number_id IS NOT NULL THEN ' serial:'||i.serial_number_id::text ELSE '' END,auth.uid(),now());
    END IF;

    IF i.serial_number_id IS NOT NULL THEN
      UPDATE public.article_serial_assignments
      SET active=false,released_at=now()
      WHERE serial_number_id=i.serial_number_id AND active=true;

      UPDATE public.serial_numbers
      SET status='returned', client_id=NULL, updated_at=now()
      WHERE id=i.serial_number_id;

      IF v_sale.prospecteur_id IS NOT NULL THEN
        INSERT INTO public.article_serial_assignments(organization_id,serial_number_id,article_id,prospecteur_id,warehouse_id,assigned_at,released_at,active,created_by)
        VALUES(r.organization_id,i.serial_number_id,i.article_id,v_sale.prospecteur_id,NULL,now(),NULL,true,auth.uid());
      END IF;
    END IF;
  END LOOP;

  UPDATE public.sales_returns SET status='processed',updated_at=now() WHERE id=r.id;
  RETURN true;
END;
$function$;

REVOKE EXECUTE ON FUNCTION public.jdvcrm_process_sale_return(uuid) FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.jdvcrm_process_sale_return(uuid) FROM anon;
GRANT EXECUTE ON FUNCTION public.jdvcrm_process_sale_return(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.jdvcrm_validate_sale_return_item_serial_v2() FROM PUBLIC;
REVOKE EXECUTE ON FUNCTION public.jdvcrm_validate_sale_return_item_serial_v2() FROM anon;
REVOKE EXECUTE ON FUNCTION public.jdvcrm_validate_sale_return_item_serial_v2() FROM authenticated;
