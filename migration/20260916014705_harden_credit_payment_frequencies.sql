BEGIN;

ALTER TABLE public.sales DROP CONSTRAINT IF EXISTS sales_payment_frequency_check;
ALTER TABLE public.sales ADD CONSTRAINT sales_payment_frequency_check
CHECK (payment_frequency = ANY (ARRAY['daily'::text,'weekly'::text,'biweekly'::text,'monthly'::text,'quarterly'::text,'custom'::text]));

CREATE OR REPLACE FUNCTION public.jdvcrm_generate_sale_schedules_v42(p_sale_id uuid)
RETURNS integer
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path TO 'public'
AS $function$
DECLARE
    v_sale public.sales%ROWTYPE;
    v_total NUMERIC(14,2);
    v_payment NUMERIC(14,2);
    v_remaining NUMERIC(14,2);
    v_installments INTEGER;
    v_i INTEGER;
    v_expected NUMERIC(14,2);
    v_due_date DATE;
    v_created INTEGER := 0;
    v_base_date DATE;
BEGIN
    SELECT * INTO v_sale
    FROM public.sales
    WHERE id = p_sale_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Vente introuvable : %', p_sale_id;
    END IF;

    IF lower(COALESCE(v_sale.sale_type, 'credit')) <> 'credit' THEN
        RETURN 0;
    END IF;

    v_total := COALESCE(v_sale.credit_price, 0) * COALESCE(v_sale.quantity, 0);
    IF v_total <= 0 THEN
        RAISE EXCEPTION 'Montant crédit invalide pour la vente %', p_sale_id;
    END IF;

    v_payment := COALESCE(v_sale.payment_amount, 0);

    IF lower(COALESCE(v_sale.payment_frequency, 'daily')) = 'custom' THEN
        -- Une fréquence personnalisée est planifiée manuellement par l'administrateur.
        RETURN 0;
    END IF;

    IF v_payment <= 0 THEN
        RAISE EXCEPTION 'Le montant de paiement doit être supérieur à 0. Vente : %', p_sale_id;
    END IF;

    IF EXISTS (SELECT 1 FROM public.payment_schedules WHERE sale_id = p_sale_id) THEN
        SELECT COUNT(*) INTO v_created
        FROM public.payment_schedules
        WHERE sale_id = p_sale_id;
        RETURN v_created;
    END IF;

    v_installments := CEIL(v_total / v_payment)::INTEGER;
    v_base_date := COALESCE(v_sale.sale_date::date, CURRENT_DATE) + 1;
    v_remaining := v_total;

    FOR v_i IN 1..v_installments LOOP
        v_expected := LEAST(v_payment, v_remaining);

        CASE lower(COALESCE(v_sale.payment_frequency, 'daily'))
            WHEN 'daily' THEN
                v_due_date := v_base_date + (v_i - 1);
            WHEN 'weekly' THEN
                v_due_date := v_base_date + ((v_i - 1) * 7);
            WHEN 'biweekly' THEN
                v_due_date := v_base_date + ((v_i - 1) * 14);
            WHEN 'monthly' THEN
                v_due_date := (v_base_date + ((v_i - 1) || ' month')::interval)::date;
            WHEN 'quarterly' THEN
                v_due_date := (v_base_date + ((v_i - 1) || ' quarter')::interval)::date;
            ELSE
                RAISE EXCEPTION 'Fréquence de paiement non supportée : %', v_sale.payment_frequency;
        END CASE;

        IF v_sale.deadline_date IS NOT NULL AND v_due_date > v_sale.deadline_date THEN
            v_due_date := v_sale.deadline_date;
        END IF;

        INSERT INTO public.payment_schedules (
            organization_id, sale_id, installment_number, due_date,
            expected_amount, paid_amount, status, paid_at,
            reminder_sent, created_at, updated_at
        ) VALUES (
            v_sale.organization_id, v_sale.id, v_i, v_due_date,
            v_expected, 0, 'pending', NULL, false, now(), now()
        );

        v_created := v_created + 1;
        v_remaining := v_remaining - v_expected;
    END LOOP;

    RETURN v_created;
END;
$function$;

-- La validation v41 est la version de référence car elle contrôle aussi l'appartenance organisationnelle.
DROP TRIGGER IF EXISTS trg_jdvcrm_validate_schedule ON public.payment_schedules;
DROP TRIGGER IF EXISTS trg_jdvcrm_validate_commission ON public.commissions;

COMMIT;
