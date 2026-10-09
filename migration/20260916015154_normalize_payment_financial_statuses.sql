CREATE OR REPLACE FUNCTION public.jdvcrm_recalculate_sale(p_sale_id uuid)
RETURNS numeric LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_paid numeric(14,2); v_total numeric(14,2); v_remaining numeric(14,2); v_status text;
BEGIN
 SELECT CASE WHEN lower(coalesce(sale_type,'credit'))='credit' THEN coalesce(credit_price,0)*coalesce(quantity,0) ELSE coalesce(cash_price,0)*coalesce(quantity,0) END INTO v_total FROM public.sales WHERE id=p_sale_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Vente introuvable : %',p_sale_id; END IF;
 SELECT coalesce(sum(amount),0) INTO v_paid FROM public.payments WHERE sale_id=p_sale_id AND lower(coalesce(status,''))='successful';
 v_remaining:=greatest(v_total-v_paid,0);
 IF v_paid>=v_total AND v_total>0 THEN v_status:='completed'; ELSIF v_paid>0 THEN v_status:='active'; ELSE v_status:='pending'; END IF;
 UPDATE public.sales SET amount_paid=v_paid,amount_remaining=v_remaining,status=v_status,completed_at=CASE WHEN v_status='completed' THEN coalesce(completed_at,now()) ELSE NULL END,updated_at=now() WHERE id=p_sale_id;
 RETURN v_remaining;
END $$;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_payment_v43()
RETURNS trigger LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_sale_org uuid; v_sale_client uuid; v_sale_prospecteur uuid; v_schedule_sale uuid; v_schedule_org uuid; v_schedule_status text; v_sale_total numeric(14,2); v_existing_paid numeric(14,2);
BEGIN
 IF NEW.amount IS NULL OR NEW.amount<=0 THEN RAISE EXCEPTION 'Le montant du paiement doit être supérieur à 0.'; END IF;
 IF NEW.organization_id IS NULL THEN RAISE EXCEPTION 'organization_id obligatoire pour un paiement.'; END IF;
 IF NEW.sale_id IS NOT NULL THEN
  SELECT organization_id,client_id,prospecteur_id,CASE WHEN lower(coalesce(sale_type,'credit'))='credit' THEN coalesce(credit_price,0)*coalesce(quantity,0) ELSE coalesce(cash_price,0)*coalesce(quantity,0) END INTO v_sale_org,v_sale_client,v_sale_prospecteur,v_sale_total FROM public.sales WHERE id=NEW.sale_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Vente introuvable : %',NEW.sale_id; END IF;
  IF v_sale_org<>NEW.organization_id THEN RAISE EXCEPTION 'Le paiement et la vente appartiennent à des organisations différentes.'; END IF;
  IF NEW.client_id IS NOT NULL AND v_sale_client IS NOT NULL AND NEW.client_id<>v_sale_client THEN RAISE EXCEPTION 'Le client du paiement ne correspond pas à celui de la vente.'; END IF;
  IF NEW.prospecteur_id IS NOT NULL AND v_sale_prospecteur IS NOT NULL AND NEW.prospecteur_id<>v_sale_prospecteur THEN RAISE EXCEPTION 'Le prospecteur du paiement ne correspond pas au prospecteur de la vente.'; END IF;
  IF lower(coalesce(NEW.status,''))='successful' THEN
   SELECT coalesce(sum(amount),0) INTO v_existing_paid FROM public.payments WHERE sale_id=NEW.sale_id AND lower(coalesce(status,''))='successful' AND id IS DISTINCT FROM NEW.id;
   IF v_existing_paid+NEW.amount>v_sale_total THEN RAISE EXCEPTION 'Paiement refusé : cumul %.2f supérieur au total de la vente %.2f.',v_existing_paid+NEW.amount,v_sale_total; END IF;
  END IF;
 END IF;
 IF NEW.schedule_id IS NOT NULL THEN
  SELECT sale_id,organization_id,status INTO v_schedule_sale,v_schedule_org,v_schedule_status FROM public.payment_schedules WHERE id=NEW.schedule_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Échéance introuvable : %',NEW.schedule_id; END IF;
  IF v_schedule_org<>NEW.organization_id THEN RAISE EXCEPTION 'L''échéance et le paiement appartiennent à des organisations différentes.'; END IF;
  IF NEW.sale_id IS NOT NULL AND v_schedule_sale<>NEW.sale_id THEN RAISE EXCEPTION 'L''échéance ne correspond pas à la vente.'; END IF;
  IF v_schedule_status='cancelled' THEN RAISE EXCEPTION 'Impossible d''enregistrer un paiement sur une échéance annulée.'; END IF;
 END IF;
 RETURN NEW;
END $$;

CREATE OR REPLACE FUNCTION public.jdvcrm_process_payment_v43(p_payment_id uuid)
RETURNS jsonb LANGUAGE plpgsql SECURITY DEFINER SET search_path=public AS $$
DECLARE v_payment public.payments%ROWTYPE; v_remaining numeric(14,2); v_total numeric(14,2); v_paid numeric(14,2); v_schedule_count integer:=0;
BEGIN
 SELECT * INTO v_payment FROM public.payments WHERE id=p_payment_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Paiement introuvable : %',p_payment_id; END IF;
 IF v_payment.sale_id IS NULL THEN RETURN jsonb_build_object('success',true,'payment_id',p_payment_id,'financially_applied',false,'reason','no_sale'); END IF;
 IF lower(coalesce(v_payment.status,''))='successful' THEN
  IF v_payment.schedule_id IS NOT NULL THEN PERFORM public.jdvcrm_refresh_schedule_v43(v_payment.schedule_id); END IF;
  v_schedule_count:=public.jdvcrm_refresh_sale_schedules_v43(v_payment.sale_id);
 END IF;
 PERFORM public.jdvcrm_recalculate_sale(v_payment.sale_id);
 SELECT CASE WHEN lower(coalesce(sale_type,'credit'))='credit' THEN coalesce(credit_price,0)*coalesce(quantity,0) ELSE coalesce(cash_price,0)*coalesce(quantity,0) END,coalesce(amount_paid,0),coalesce(amount_remaining,0) INTO v_total,v_paid,v_remaining FROM public.sales WHERE id=v_payment.sale_id;
 RETURN jsonb_build_object('success',true,'payment_id',p_payment_id,'financially_applied',lower(coalesce(v_payment.status,''))='successful','sale_id',v_payment.sale_id,'schedule_id',v_payment.schedule_id,'schedule_count',v_schedule_count,'sale_total',v_total,'sale_paid',v_paid,'sale_remaining',v_remaining);
END $$;

DROP TRIGGER IF EXISTS trg_jdvcrm_after_payment_recalculate ON public.payments;
DROP TRIGGER IF EXISTS trg_jdvcrm_after_payment_schedule_refresh ON public.payments;
DROP TRIGGER IF EXISTS trg_jdvcrm_after_payment_v43 ON public.payments;
CREATE TRIGGER trg_jdvcrm_after_payment_v43 AFTER INSERT OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION public.jdvcrm_after_payment_v43();
