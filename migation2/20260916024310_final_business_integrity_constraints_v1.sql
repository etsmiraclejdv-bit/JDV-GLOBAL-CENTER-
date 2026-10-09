BEGIN;

-- Numeric integrity: all existing data was verified clean before adding these constraints.
ALTER TABLE public.sales
  ADD CONSTRAINT sales_quantity_nonnegative CHECK (quantity >= 0),
  ADD CONSTRAINT sales_prices_nonnegative CHECK (fixed_price >= 0 AND cash_price >= 0 AND credit_price >= 0),
  ADD CONSTRAINT sales_amounts_nonnegative CHECK (amount_paid >= 0 AND amount_remaining >= 0 AND payment_amount >= 0);

ALTER TABLE public.sale_items
  ADD CONSTRAINT sale_items_quantity_positive CHECK (quantity > 0),
  ADD CONSTRAINT sale_items_amounts_nonnegative CHECK (
    discount_amount >= 0 AND line_total >= 0
    AND (unit_fixed_price IS NULL OR unit_fixed_price >= 0)
    AND (unit_cash_price IS NULL OR unit_cash_price >= 0)
    AND (unit_credit_price IS NULL OR unit_credit_price >= 0)
  );

ALTER TABLE public.payments
  ADD CONSTRAINT payments_amount_positive CHECK (amount > 0);

ALTER TABLE public.payment_schedules
  ADD CONSTRAINT payment_schedules_installment_positive CHECK (installment_number > 0),
  ADD CONSTRAINT payment_schedules_amounts_valid CHECK (expected_amount > 0 AND paid_amount >= 0 AND paid_amount <= expected_amount);

CREATE UNIQUE INDEX IF NOT EXISTS uq_payment_schedules_sale_installment
  ON public.payment_schedules (sale_id, installment_number);

ALTER TABLE public.stocks
  ADD CONSTRAINT stocks_quantities_nonnegative CHECK (quantity >= 0 AND reserved_quantity >= 0 AND minimum_quantity >= 0),
  ADD CONSTRAINT stocks_reserved_not_above_quantity CHECK (reserved_quantity <= quantity);

ALTER TABLE public.stock_movements
  ADD CONSTRAINT stock_movements_quantity_positive CHECK (quantity > 0);

ALTER TABLE public.sales_returns
  ADD CONSTRAINT sales_returns_refund_nonnegative CHECK (refund_amount >= 0);

ALTER TABLE public.sales_return_items
  ADD CONSTRAINT sales_return_items_quantity_positive CHECK (quantity > 0),
  ADD CONSTRAINT sales_return_items_refund_nonnegative CHECK (refund_amount >= 0);

ALTER TABLE public.prospects
  ADD CONSTRAINT prospects_visit_count_nonnegative CHECK (visit_count >= 0);

ALTER TABLE public.prospecteurs
  ADD CONSTRAINT prospecteurs_commission_rate_valid CHECK (commission_rate >= 0 AND commission_rate <= 100);

ALTER TABLE public.organization_subscriptions
  ADD CONSTRAINT organization_subscriptions_dates_valid CHECK (
    expires_at IS NULL OR started_at IS NULL OR expires_at > started_at
  );

COMMIT;
