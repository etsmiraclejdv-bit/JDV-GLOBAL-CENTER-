CREATE OR REPLACE FUNCTION public.jdvcrm_validate_purchase_order_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_org uuid;
BEGIN
  IF NEW.organization_id IS NULL OR NEW.supplier_id IS NULL THEN RAISE EXCEPTION 'Commande fournisseur: organisation et fournisseur obligatoires'; END IF;
  SELECT organization_id INTO v_org FROM suppliers WHERE id=NEW.supplier_id;
  IF v_org IS NULL OR v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Fournisseur incompatible avec l''organisation'; END IF;
  RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_purchase_order_item_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_org uuid;
BEGIN
  SELECT organization_id INTO v_org FROM purchase_orders WHERE id=NEW.purchase_order_id;
  IF v_org IS NULL OR v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Ligne commande incompatible avec l''organisation'; END IF;
  SELECT organization_id INTO v_org FROM articles WHERE id=NEW.article_id;
  IF v_org IS NOT NULL AND v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Article incompatible avec l''organisation'; END IF;
  IF NEW.quantity IS NULL OR NEW.quantity<=0 THEN RAISE EXCEPTION 'Quantité commandée invalide'; END IF;
  IF COALESCE(NEW.unit_cost,0)<0 OR COALESCE(NEW.discount_amount,0)<0 OR COALESCE(NEW.tax_amount,0)<0 OR COALESCE(NEW.total_amount,0)<0 THEN RAISE EXCEPTION 'Montants de commande invalides'; END IF;
  RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_goods_receipt_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_org uuid;
BEGIN
  SELECT organization_id INTO v_org FROM purchase_orders WHERE id=NEW.purchase_order_id;
  IF v_org IS NULL OR v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Réception incompatible avec la commande fournisseur'; END IF;
  IF NEW.received_by IS NULL AND NEW.status='received' THEN NEW.received_by:=auth.uid(); END IF;
  RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_goods_receipt_item_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_org uuid;
BEGIN
  SELECT organization_id INTO v_org FROM goods_receipts WHERE id=NEW.receipt_id;
  IF v_org IS NULL OR v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Ligne de réception incompatible avec la réception'; END IF;
  SELECT organization_id INTO v_org FROM articles WHERE id=NEW.article_id;
  IF v_org IS NOT NULL AND v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Article de réception incompatible avec l''organisation'; END IF;
  IF NEW.quantity_received IS NULL OR NEW.quantity_received<=0 THEN RAISE EXCEPTION 'Quantité reçue invalide'; END IF;
  IF COALESCE(NEW.unit_cost,0)<0 THEN RAISE EXCEPTION 'Coût unitaire invalide'; END IF;
  RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_warehouse_inventory_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_org uuid;
BEGIN
  SELECT organization_id INTO v_org FROM warehouses WHERE id=NEW.warehouse_id;
  IF v_org IS NULL OR v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Inventaire entrepôt incompatible avec l''organisation'; END IF;
  IF NEW.quantity<0 OR NEW.reserved_quantity<0 OR NEW.minimum_quantity<0 THEN RAISE EXCEPTION 'Quantités d''entrepôt invalides'; END IF;
  IF NEW.reserved_quantity>NEW.quantity THEN RAISE EXCEPTION 'Stock réservé supérieur au stock disponible'; END IF;
  RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_stock_transfer_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE vo uuid; vd uuid;
BEGIN
  SELECT organization_id INTO vo FROM warehouses WHERE id=NEW.source_warehouse_id;
  SELECT organization_id INTO vd FROM warehouses WHERE id=NEW.destination_warehouse_id;
  IF vo IS NULL OR vd IS NULL OR vo<>NEW.organization_id OR vd<>NEW.organization_id THEN RAISE EXCEPTION 'Entrepôts incompatibles avec l''organisation'; END IF;
  IF NEW.source_warehouse_id=NEW.destination_warehouse_id THEN RAISE EXCEPTION 'Source et destination doivent être différents'; END IF;
  RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_stock_transfer_item_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_org uuid; v_aorg uuid;
BEGIN
  SELECT organization_id INTO v_org FROM stock_transfers WHERE id=NEW.transfer_id;
  SELECT organization_id INTO v_aorg FROM articles WHERE id=NEW.article_id;
  IF v_org IS NULL OR v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Ligne de transfert incompatible avec le transfert'; END IF;
  IF v_aorg IS NOT NULL AND v_aorg<>NEW.organization_id THEN RAISE EXCEPTION 'Article de transfert incompatible avec l''organisation'; END IF;
  IF NEW.quantity<=0 OR NEW.received_quantity<0 OR NEW.received_quantity>NEW.quantity THEN RAISE EXCEPTION 'Quantités de transfert invalides'; END IF;
  RETURN NEW;
END; $$;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_supplier_payment_v1()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE vo uuid; vs uuid;
BEGIN
  SELECT organization_id,supplier_id INTO vo,vs FROM purchase_orders WHERE id=NEW.purchase_order_id;
  IF vo IS NULL OR vo<>NEW.organization_id OR vs<>NEW.supplier_id THEN RAISE EXCEPTION 'Paiement fournisseur incompatible avec la commande'; END IF;
  IF NEW.amount<=0 THEN RAISE EXCEPTION 'Montant du paiement fournisseur invalide'; END IF;
  RETURN NEW;
END; $$;

DROP TRIGGER IF EXISTS trg_jdvcrm_validate_purchase_order_v1 ON public.purchase_orders;
CREATE TRIGGER trg_jdvcrm_validate_purchase_order_v1 BEFORE INSERT OR UPDATE ON public.purchase_orders FOR EACH ROW EXECUTE FUNCTION public.jdvcrm_validate_purchase_order_v1();
DROP TRIGGER IF EXISTS trg_jdvcrm_validate_purchase_order_item_v1 ON public.purchase_order_items;
CREATE TRIGGER trg_jdvcrm_validate_purchase_order_item_v1 BEFORE INSERT OR UPDATE ON public.purchase_order_items FOR EACH ROW EXECUTE FUNCTION public.jdvcrm_validate_purchase_order_item_v1();
DROP TRIGGER IF EXISTS trg_jdvcrm_validate_goods_receipt_v1 ON public.goods_receipts;
CREATE TRIGGER trg_jdvcrm_validate_goods_receipt_v1 BEFORE INSERT OR UPDATE ON public.goods_receipts FOR EACH ROW EXECUTE FUNCTION public.jdvcrm_validate_goods_receipt_v1();
DROP TRIGGER IF EXISTS trg_jdvcrm_validate_goods_receipt_item_v1 ON public.goods_receipt_items;
CREATE TRIGGER trg_jdvcrm_validate_goods_receipt_item_v1 BEFORE INSERT OR UPDATE ON public.goods_receipt_items FOR EACH ROW EXECUTE FUNCTION public.jdvcrm_validate_goods_receipt_item_v1();
DROP TRIGGER IF EXISTS trg_jdvcrm_validate_warehouse_inventory_v1 ON public.warehouse_inventory;
CREATE TRIGGER trg_jdvcrm_validate_warehouse_inventory_v1 BEFORE INSERT OR UPDATE ON public.warehouse_inventory FOR EACH ROW EXECUTE FUNCTION public.jdvcrm_validate_warehouse_inventory_v1();
DROP TRIGGER IF EXISTS trg_jdvcrm_validate_stock_transfer_v1 ON public.stock_transfers;
CREATE TRIGGER trg_jdvcrm_validate_stock_transfer_v1 BEFORE INSERT OR UPDATE ON public.stock_transfers FOR EACH ROW EXECUTE FUNCTION public.jdvcrm_validate_stock_transfer_v1();
DROP TRIGGER IF EXISTS trg_jdvcrm_validate_stock_transfer_item_v1 ON public.stock_transfer_items;
CREATE TRIGGER trg_jdvcrm_validate_stock_transfer_item_v1 BEFORE INSERT OR UPDATE ON public.stock_transfer_items FOR EACH ROW EXECUTE FUNCTION public.jdvcrm_validate_stock_transfer_item_v1();
DROP TRIGGER IF EXISTS trg_jdvcrm_validate_supplier_payment_v1 ON public.supplier_payments;
CREATE TRIGGER trg_jdvcrm_validate_supplier_payment_v1 BEFORE INSERT OR UPDATE ON public.supplier_payments FOR EACH ROW EXECUTE FUNCTION public.jdvcrm_validate_supplier_payment_v1();

CREATE OR REPLACE FUNCTION public.jdvcrm_process_goods_receipt_v1(p_receipt_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE r goods_receipts%ROWTYPE; i record; s stocks%ROWTYPE; v_count integer:=0;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentification requise'; END IF;
  SELECT * INTO r FROM goods_receipts WHERE id=p_receipt_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Réception introuvable'; END IF;
  IF NOT (private.is_super_admin() OR private.is_org_admin(r.organization_id)) THEN RAISE EXCEPTION 'Accès refusé'; END IF;
  IF r.status<>'received' THEN RAISE EXCEPTION 'La réception doit être au statut received'; END IF;
  FOR i IN SELECT * FROM goods_receipt_items WHERE receipt_id=r.id ORDER BY id LOOP
    IF EXISTS (SELECT 1 FROM stock_movements WHERE organization_id=r.organization_id AND reference_type='goods_receipt' AND reference_id=r.id AND article_id=i.article_id) THEN CONTINUE; END IF;
    SELECT * INTO s FROM stocks WHERE organization_id=r.organization_id AND article_id=i.article_id FOR UPDATE;
    IF FOUND THEN
      UPDATE stocks SET quantity=quantity+i.quantity_received, updated_at=now() WHERE id=s.id;
    ELSE
      INSERT INTO stocks(organization_id,article_id,quantity,reserved_quantity,minimum_quantity,updated_at) VALUES(r.organization_id,i.article_id,i.quantity_received,0,0,now());
    END IF;
    INSERT INTO stock_movements(organization_id,article_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
    VALUES(r.organization_id,i.article_id,'entry',i.quantity_received,'goods_receipt',r.id,'supplier','stock_principal','Entrée liée à la réception '||r.receipt_number,COALESCE(r.received_by,auth.uid()),now());
    v_count:=v_count+1;
  END LOOP;
  RETURN jsonb_build_object('success',true,'receipt_id',r.id,'processed_items',v_count);
END; $$;
REVOKE ALL ON FUNCTION public.jdvcrm_process_goods_receipt_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.jdvcrm_process_goods_receipt_v1(uuid) TO authenticated;

CREATE OR REPLACE FUNCTION public.jdvcrm_process_sale_stock_v42(p_sale_id uuid)
RETURNS boolean LANGUAGE plpgsql SECURITY DEFINER SET search_path TO 'public'
AS $$
DECLARE v_sale public.sales%ROWTYPE; v_stock_id uuid; v_stock_quantity numeric; v_ps_id uuid; v_ps_qty numeric; v_qty numeric; v_existing boolean;
BEGIN
 SELECT * INTO v_sale FROM public.sales WHERE id=p_sale_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Vente introuvable : %',p_sale_id; END IF;
 v_qty:=COALESCE(v_sale.quantity,0); IF v_qty<=0 THEN RAISE EXCEPTION 'Quantité de vente invalide : %',v_qty; END IF;
 IF v_sale.article_id IS NULL THEN RAISE EXCEPTION 'La vente ne possède aucun article'; END IF;
 SELECT EXISTS(SELECT 1 FROM stock_movements WHERE organization_id=v_sale.organization_id AND reference_type='sale' AND reference_id=v_sale.id AND movement_type='sale') INTO v_existing;
 IF v_existing THEN RETURN true; END IF;
 IF v_sale.prospecteur_id IS NOT NULL THEN
   SELECT id,quantity INTO v_ps_id,v_ps_qty FROM prospecteur_stocks WHERE organization_id=v_sale.organization_id AND prospecteur_id=v_sale.prospecteur_id AND article_id=v_sale.article_id FOR UPDATE;
   IF NOT FOUND THEN RAISE EXCEPTION 'Aucun stock prospecteur disponible pour cette vente'; END IF;
   IF v_ps_qty<v_qty THEN RAISE EXCEPTION 'Stock prospecteur insuffisant. Disponible : %, demandé : %',v_ps_qty,v_qty; END IF;
   UPDATE prospecteur_stocks SET quantity=quantity-v_qty,updated_at=now() WHERE id=v_ps_id;
   INSERT INTO stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
   VALUES(v_sale.organization_id,v_sale.article_id,v_sale.prospecteur_id,'sale',v_qty,'sale',v_sale.id,'stock_prospecteur','client','Sortie automatique du stock prospecteur liée à la vente '||v_sale.sale_number,auth.uid(),now());
 ELSE
   SELECT id,quantity INTO v_stock_id,v_stock_quantity FROM stocks WHERE organization_id=v_sale.organization_id AND article_id=v_sale.article_id FOR UPDATE;
   IF NOT FOUND THEN RAISE EXCEPTION 'Aucun stock trouvé pour l''article dans l''organisation'; END IF;
   IF v_stock_quantity<v_qty THEN RAISE EXCEPTION 'Stock insuffisant. Disponible : %, demandé : %',v_stock_quantity,v_qty; END IF;
   UPDATE stocks SET quantity=quantity-v_qty,updated_at=now() WHERE id=v_stock_id;
   INSERT INTO stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
   VALUES(v_sale.organization_id,v_sale.article_id,NULL,'sale',v_qty,'sale',v_sale.id,'stock_principal','client','Sortie automatique du stock principal liée à la vente '||v_sale.sale_number,auth.uid(),now());
 END IF;
 RETURN true;
END; $$;
REVOKE ALL ON FUNCTION public.jdvcrm_process_sale_stock_v42(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.jdvcrm_process_sale_stock_v42(uuid) TO authenticated;
