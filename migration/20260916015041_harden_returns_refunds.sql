CREATE OR REPLACE FUNCTION public.jdvcrm_validate_sale_return()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_sale public.sales%ROWTYPE; v_returned numeric;
BEGIN
 IF NEW.quantity IS NULL OR NEW.quantity <= 0 THEN RAISE EXCEPTION 'Quantité de retour invalide'; END IF;
 SELECT * INTO v_sale FROM public.sales WHERE id=NEW.sale_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Vente introuvable'; END IF;
 IF v_sale.organization_id <> NEW.organization_id THEN RAISE EXCEPTION 'Organisation incohérente'; END IF;
 IF NEW.client_id IS NOT NULL AND NEW.client_id <> v_sale.client_id THEN RAISE EXCEPTION 'Client incohérent avec la vente'; END IF;
 SELECT COALESCE(SUM(i.quantity),0) INTO v_returned FROM public.sales_return_items i JOIN public.sales_returns r ON r.id=i.return_id WHERE r.sale_id=NEW.sale_id AND r.status IN ('approved','processed') AND i.article_id=NEW.article_id AND r.id<>COALESCE(NEW.return_id,r.id);
 IF v_returned + NEW.quantity > COALESCE(v_sale.quantity,0) THEN RAISE EXCEPTION 'Quantité retournée supérieure à la quantité vendue'; END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_return_header()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_sale public.sales%ROWTYPE;
BEGIN
 SELECT * INTO v_sale FROM public.sales WHERE id=NEW.sale_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Vente introuvable'; END IF;
 IF NEW.organization_id <> v_sale.organization_id THEN RAISE EXCEPTION 'Organisation incohérente'; END IF;
 IF NEW.client_id IS NOT NULL AND NEW.client_id <> v_sale.client_id THEN RAISE EXCEPTION 'Client incohérent avec la vente'; END IF;
 IF NEW.status NOT IN ('pending','approved','processed','cancelled') THEN RAISE EXCEPTION 'Statut de retour invalide'; END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.jdvcrm_process_sale_return(p_return_id uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE r public.sales_returns%ROWTYPE; i record; v_stock public.stocks%ROWTYPE; v_existing boolean;
BEGIN
 SELECT * INTO r FROM public.sales_returns WHERE id=p_return_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Retour introuvable'; END IF;
 IF r.status='processed' THEN RETURN true; END IF;
 IF r.status<>'approved' THEN RAISE EXCEPTION 'Le retour doit être approuvé avant traitement'; END IF;
 FOR i IN SELECT * FROM public.sales_return_items WHERE return_id=r.id LOOP
   SELECT EXISTS(SELECT 1 FROM public.stock_movements WHERE organization_id=r.organization_id AND reference_type='sale_return' AND reference_id=r.id AND article_id=i.article_id AND movement_type='return') INTO v_existing;
   IF v_existing THEN CONTINUE; END IF;
   SELECT * INTO v_stock FROM public.stocks WHERE organization_id=r.organization_id AND article_id=i.article_id FOR UPDATE;
   IF NOT FOUND THEN
     INSERT INTO public.stocks(organization_id,article_id,quantity) VALUES(r.organization_id,i.article_id,i.quantity);
   ELSE
     UPDATE public.stocks SET quantity=quantity+i.quantity,updated_at=now() WHERE id=v_stock.id;
   END IF;
   INSERT INTO public.stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
   VALUES(r.organization_id,i.article_id,(SELECT prospecteur_id FROM public.sales WHERE id=r.sale_id),'return',i.quantity,r' sale_return',r.id,'client','stock_principal','Réintégration retour '||r.return_number,auth.uid(),now());
 END LOOP;
 UPDATE public.sales_returns SET status='processed',updated_at=now() WHERE id=r.id;
 RETURN true;
END $$;

DROP TRIGGER IF EXISTS trg_jdvcrm_validate_sale_return_header ON public.sales_returns;
CREATE TRIGGER trg_jdvcrm_validate_sale_return_header BEFORE INSERT OR UPDATE ON public.sales_returns FOR EACH ROW EXECUTE FUNCTION public.jdvcrm_validate_return_header();
DROP TRIGGER IF EXISTS trg_jdvcrm_validate_sale_return_item ON public.sales_return_items;
CREATE TRIGGER trg_jdvcrm_validate_sale_return_item BEFORE INSERT OR UPDATE ON public.sales_return_items FOR EACH ROW EXECUTE FUNCTION public.jdvcrm_validate_sale_return();

ALTER TABLE public.sales_returns ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.sales_return_items ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.payment_refunds ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS super_admin_full_access ON public.sales_returns;
DROP POLICY IF EXISTS admin_full_access ON public.sales_returns;
CREATE POLICY super_admin_full_access ON public.sales_returns FOR ALL TO authenticated USING (private.is_super_admin()) WITH CHECK (private.is_super_admin());
CREATE POLICY admin_full_access ON public.sales_returns FOR ALL TO authenticated USING (private.is_org_admin(organization_id)) WITH CHECK (private.is_org_admin(organization_id));
DROP POLICY IF EXISTS super_admin_full_access ON public.sales_return_items;
DROP POLICY IF EXISTS admin_full_access ON public.sales_return_items;
CREATE POLICY super_admin_full_access ON public.sales_return_items FOR ALL TO authenticated USING (private.is_super_admin()) WITH CHECK (private.is_super_admin());
CREATE POLICY admin_full_access ON public.sales_return_items FOR ALL TO authenticated USING (private.is_org_admin(organization_id)) WITH CHECK (private.is_org_admin(organization_id));
DROP POLICY IF EXISTS super_admin_full_access ON public.payment_refunds;
DROP POLICY IF EXISTS admin_full_access ON public.payment_refunds;
CREATE POLICY super_admin_full_access ON public.payment_refunds FOR ALL TO authenticated USING (private.is_super_admin()) WITH CHECK (private.is_super_admin());
CREATE POLICY admin_full_access ON public.payment_refunds FOR ALL TO authenticated USING (private.is_org_admin(organization_id)) WITH CHECK (private.is_org_admin(organization_id));

CREATE UNIQUE INDEX IF NOT EXISTS ux_payment_refunds_payment_processed ON public.payment_refunds(payment_id) WHERE status='processed';
