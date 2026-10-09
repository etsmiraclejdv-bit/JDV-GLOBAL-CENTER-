CREATE OR REPLACE FUNCTION public.jdvcrm_validate_serial_number_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_org uuid; v_article uuid; v_client uuid;
BEGIN
 IF NEW.organization_id IS NULL OR NEW.article_id IS NULL OR NULLIF(trim(NEW.serial_number),'') IS NULL THEN RAISE EXCEPTION 'Numéro de série, article et organisation obligatoires'; END IF;
 SELECT organization_id INTO v_org FROM public.articles WHERE id=NEW.article_id;
 IF v_org IS NOT NULL AND v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Article et numéro de série appartiennent à des organisations différentes'; END IF;
 IF NEW.status NOT IN ('in_stock','reserved','sold','returned','damaged','lost','inactive') THEN RAISE EXCEPTION 'Statut de numéro de série invalide'; END IF;
 IF NEW.status='sold' AND NEW.sale_id IS NULL THEN RAISE EXCEPTION 'Un numéro de série vendu doit être lié à une vente'; END IF;
 IF NEW.sale_id IS NOT NULL THEN
   SELECT organization_id,article_id,client_id INTO v_org,v_article,v_client FROM public.sales WHERE id=NEW.sale_id;
   IF NOT FOUND OR v_org<>NEW.organization_id OR v_article<>NEW.article_id THEN RAISE EXCEPTION 'Vente incompatible avec le numéro de série'; END IF;
   IF NEW.client_id IS NOT NULL AND v_client IS NOT NULL AND NEW.client_id<>v_client THEN RAISE EXCEPTION 'Client incompatible avec la vente'; END IF;
 END IF;
 IF NEW.client_id IS NOT NULL THEN
   SELECT organization_id INTO v_org FROM public.clients WHERE id=NEW.client_id;
   IF NOT FOUND OR v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Client incompatible avec le numéro de série'; END IF;
 END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_serial_assignment_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_org uuid; v_article uuid; v_serial_status text; v_prospect_org uuid; v_wh_org uuid;
BEGIN
 SELECT organization_id,article_id,status INTO v_org,v_article,v_serial_status FROM public.serial_numbers WHERE id=NEW.serial_number_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Numéro de série introuvable'; END IF;
 IF v_org<>NEW.organization_id OR v_article<>NEW.article_id THEN RAISE EXCEPTION 'Affectation incompatible avec le numéro de série'; END IF;
 IF NEW.prospecteur_id IS NOT NULL THEN
   SELECT organization_id INTO v_prospect_org FROM public.prospecteurs WHERE id=NEW.prospecteur_id;
   IF NOT FOUND OR v_prospect_org<>NEW.organization_id THEN RAISE EXCEPTION 'Prospecteur incompatible avec l''affectation'; END IF;
 END IF;
 IF NEW.warehouse_id IS NOT NULL THEN
   SELECT organization_id INTO v_wh_org FROM public.warehouses WHERE id=NEW.warehouse_id;
   IF NOT FOUND OR v_wh_org<>NEW.organization_id THEN RAISE EXCEPTION 'Entrepôt incompatible avec l''affectation'; END IF;
 END IF;
 IF NEW.active AND v_serial_status IN ('sold','lost','damaged','inactive') THEN RAISE EXCEPTION 'Ce numéro de série ne peut pas être affecté dans son état actuel'; END IF;
 IF NEW.released_at IS NOT NULL AND NEW.released_at<NEW.assigned_at THEN RAISE EXCEPTION 'released_at ne peut pas précéder assigned_at'; END IF;
 RETURN NEW;
END $$;

DROP TRIGGER IF EXISTS trg_jdvcrm_validate_serial_number_v1 ON public.serial_numbers;
CREATE TRIGGER trg_jdvcrm_validate_serial_number_v1 BEFORE INSERT OR UPDATE ON public.serial_numbers FOR EACH ROW EXECUTE FUNCTION public.jdvcrm_validate_serial_number_v1();
DROP TRIGGER IF EXISTS trg_jdvcrm_validate_serial_assignment_v1 ON public.article_serial_assignments;
CREATE TRIGGER trg_jdvcrm_validate_serial_assignment_v1 BEFORE INSERT OR UPDATE ON public.article_serial_assignments FOR EACH ROW EXECUTE FUNCTION public.jdvcrm_validate_serial_assignment_v1();

CREATE UNIQUE INDEX IF NOT EXISTS ux_jdvcrm_active_serial_assignment ON public.article_serial_assignments(serial_number_id) WHERE active=true;
CREATE UNIQUE INDEX IF NOT EXISTS ux_jdvcrm_serial_number_normalized ON public.serial_numbers(organization_id, lower(trim(serial_number)));

ALTER TABLE public.serial_numbers ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.article_serial_assignments ENABLE ROW LEVEL SECURITY;
DROP POLICY IF EXISTS super_admin_full_access ON public.serial_numbers;
DROP POLICY IF EXISTS admin_full_access ON public.serial_numbers;
DROP POLICY IF EXISTS prospecteur_read_own ON public.serial_numbers;
CREATE POLICY super_admin_full_access ON public.serial_numbers FOR ALL TO authenticated USING (private.is_super_admin()) WITH CHECK (private.is_super_admin());
CREATE POLICY admin_full_access ON public.serial_numbers FOR ALL TO authenticated USING (private.is_org_admin(organization_id)) WITH CHECK (private.is_org_admin(organization_id));
CREATE POLICY prospecteur_read_own ON public.serial_numbers FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.article_serial_assignments a WHERE a.serial_number_id=serial_numbers.id AND a.active=true AND a.prospecteur_id=(SELECT id FROM public.prospecteurs WHERE user_id=auth.uid()) AND a.organization_id=serial_numbers.organization_id));
DROP POLICY IF EXISTS super_admin_full_access ON public.article_serial_assignments;
DROP POLICY IF EXISTS admin_full_access ON public.article_serial_assignments;
DROP POLICY IF EXISTS prospecteur_read_own ON public.article_serial_assignments;
CREATE POLICY super_admin_full_access ON public.article_serial_assignments FOR ALL TO authenticated USING (private.is_super_admin()) WITH CHECK (private.is_super_admin());
CREATE POLICY admin_full_access ON public.article_serial_assignments FOR ALL TO authenticated USING (private.is_org_admin(organization_id)) WITH CHECK (private.is_org_admin(organization_id));
CREATE POLICY prospecteur_read_own ON public.article_serial_assignments FOR SELECT TO authenticated USING (prospecteur_id=(SELECT id FROM public.prospecteurs WHERE user_id=auth.uid()) AND organization_id=private.current_org_id());
