-- Complete tenant/admin access for advanced inventory, purchasing, warehouse and returns modules.
-- SUPER ADMIN policies already exist; these policies add organization ADMIN access.

DROP POLICY IF EXISTS admin_full_access ON public.suppliers;
CREATE POLICY admin_full_access ON public.suppliers
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.purchase_orders;
CREATE POLICY admin_full_access ON public.purchase_orders
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.purchase_order_items;
CREATE POLICY admin_full_access ON public.purchase_order_items
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.goods_receipts;
CREATE POLICY admin_full_access ON public.goods_receipts
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.goods_receipt_items;
CREATE POLICY admin_full_access ON public.goods_receipt_items
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.supplier_payments;
CREATE POLICY admin_full_access ON public.supplier_payments
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.warehouses;
CREATE POLICY admin_full_access ON public.warehouses
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.warehouse_users;
CREATE POLICY admin_full_access ON public.warehouse_users
FOR ALL TO authenticated
USING (
  private.is_super_admin()
  OR EXISTS (
    SELECT 1 FROM public.warehouses w
    WHERE w.id = warehouse_users.warehouse_id
      AND private.is_org_admin(w.organization_id)
  )
)
WITH CHECK (
  private.is_super_admin()
  OR EXISTS (
    SELECT 1 FROM public.warehouses w
    WHERE w.id = warehouse_users.warehouse_id
      AND private.is_org_admin(w.organization_id)
  )
);

DROP POLICY IF EXISTS admin_full_access ON public.warehouse_inventory;
CREATE POLICY admin_full_access ON public.warehouse_inventory
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.stock_transfers;
CREATE POLICY admin_full_access ON public.stock_transfers
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.stock_transfer_items;
CREATE POLICY admin_full_access ON public.stock_transfer_items
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.serial_numbers;
CREATE POLICY admin_full_access ON public.serial_numbers
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.article_serial_assignments;
CREATE POLICY admin_full_access ON public.article_serial_assignments
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.sales_returns;
CREATE POLICY admin_full_access ON public.sales_returns
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.sales_return_items;
CREATE POLICY admin_full_access ON public.sales_return_items
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.payment_refunds;
CREATE POLICY admin_full_access ON public.payment_refunds
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

DROP POLICY IF EXISTS admin_full_access ON public.article_categories;
CREATE POLICY admin_full_access ON public.article_categories
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

-- Existing article/stock policies are preserved. Add missing admin update/delete coverage to stock movements.
DROP POLICY IF EXISTS stock_movements_admin_full_access ON public.stock_movements;
CREATE POLICY stock_movements_admin_full_access ON public.stock_movements
FOR ALL TO authenticated
USING (private.is_org_admin(organization_id) OR private.is_super_admin())
WITH CHECK (private.is_org_admin(organization_id) OR private.is_super_admin());

-- Prospecteur stock: exact ownership for operational users, admin/global access preserved.
DROP POLICY IF EXISTS prospecteur_stocks_prospecteur_modify ON public.prospecteur_stocks;
CREATE POLICY prospecteur_stocks_prospecteur_modify ON public.prospecteur_stocks
FOR INSERT TO authenticated
WITH CHECK (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND EXISTS (
      SELECT 1 FROM public.prospecteurs p
      WHERE p.id = prospecteur_stocks.prospecteur_id
        AND p.organization_id = prospecteur_stocks.organization_id
        AND p.user_id = auth.uid()
    )
  )
);

DROP POLICY IF EXISTS prospecteur_stocks_prospecteur_update ON public.prospecteur_stocks;
CREATE POLICY prospecteur_stocks_prospecteur_update ON public.prospecteur_stocks
FOR UPDATE TO authenticated
USING (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND EXISTS (
      SELECT 1 FROM public.prospecteurs p
      WHERE p.id = prospecteur_stocks.prospecteur_id
        AND p.organization_id = prospecteur_stocks.organization_id
        AND p.user_id = auth.uid()
    )
  )
)
WITH CHECK (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND EXISTS (
      SELECT 1 FROM public.prospecteurs p
      WHERE p.id = prospecteur_stocks.prospecteur_id
        AND p.organization_id = prospecteur_stocks.organization_id
        AND p.user_id = auth.uid()
    )
  )
);

DROP POLICY IF EXISTS prospecteur_stocks_prospecteur_delete ON public.prospecteur_stocks;
CREATE POLICY prospecteur_stocks_prospecteur_delete ON public.prospecteur_stocks
FOR DELETE TO authenticated
USING (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND EXISTS (
      SELECT 1 FROM public.prospecteurs p
      WHERE p.id = prospecteur_stocks.prospecteur_id
        AND p.organization_id = prospecteur_stocks.organization_id
        AND p.user_id = auth.uid()
    )
  )
);
