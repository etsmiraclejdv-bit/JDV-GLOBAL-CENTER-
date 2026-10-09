-- JDV CRM — durcissement des droits ADMIN / PROSPECTEUR / SUPER ADMIN
-- Le SUPER ADMIN conserve l'accès global et sans abonnement.

-- PROSPECTS
DROP POLICY IF EXISTS prospects_insert ON public.prospects;
DROP POLICY IF EXISTS prospects_update ON public.prospects;
CREATE POLICY prospects_insert ON public.prospects
FOR INSERT TO authenticated
WITH CHECK (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND prospecteur_id IN (
      SELECT p.id FROM public.prospecteurs p
      WHERE p.user_id = (SELECT auth.uid())
        AND p.organization_id = prospects.organization_id
        AND p.status = 'active'
    )
  )
);
CREATE POLICY prospects_update ON public.prospects
FOR UPDATE TO authenticated
USING (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND prospecteur_id IN (
      SELECT p.id FROM public.prospecteurs p
      WHERE p.user_id = (SELECT auth.uid())
        AND p.organization_id = prospects.organization_id
        AND p.status = 'active'
    )
  )
)
WITH CHECK (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND prospecteur_id IN (
      SELECT p.id FROM public.prospecteurs p
      WHERE p.user_id = (SELECT auth.uid())
        AND p.organization_id = prospects.organization_id
        AND p.status = 'active'
    )
  )
);

-- CLIENTS
DROP POLICY IF EXISTS clients_insert ON public.clients;
DROP POLICY IF EXISTS clients_update ON public.clients;
CREATE POLICY clients_insert ON public.clients
FOR INSERT TO authenticated
WITH CHECK (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND prospecteur_id IN (
      SELECT p.id FROM public.prospecteurs p
      WHERE p.user_id = (SELECT auth.uid())
        AND p.organization_id = clients.organization_id
        AND p.status = 'active'
    )
  )
);
CREATE POLICY clients_update ON public.clients
FOR UPDATE TO authenticated
USING (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND prospecteur_id IN (
      SELECT p.id FROM public.prospecteurs p
      WHERE p.user_id = (SELECT auth.uid())
        AND p.organization_id = clients.organization_id
        AND p.status = 'active'
    )
  )
)
WITH CHECK (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND prospecteur_id IN (
      SELECT p.id FROM public.prospecteurs p
      WHERE p.user_id = (SELECT auth.uid())
        AND p.organization_id = clients.organization_id
        AND p.status = 'active'
    )
  )
);

-- SALES
DROP POLICY IF EXISTS sales_insert ON public.sales;
DROP POLICY IF EXISTS sales_update ON public.sales;
CREATE POLICY sales_insert ON public.sales
FOR INSERT TO authenticated
WITH CHECK (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND prospecteur_id IN (
      SELECT p.id FROM public.prospecteurs p
      WHERE p.user_id = (SELECT auth.uid())
        AND p.organization_id = sales.organization_id
        AND p.status = 'active'
    )
  )
);
CREATE POLICY sales_update ON public.sales
FOR UPDATE TO authenticated
USING (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND prospecteur_id IN (
      SELECT p.id FROM public.prospecteurs p
      WHERE p.user_id = (SELECT auth.uid())
        AND p.organization_id = sales.organization_id
        AND p.status = 'active'
    )
  )
)
WITH CHECK (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND prospecteur_id IN (
      SELECT p.id FROM public.prospecteurs p
      WHERE p.user_id = (SELECT auth.uid())
        AND p.organization_id = sales.organization_id
        AND p.status = 'active'
    )
  )
);

-- PAYMENT SCHEDULES : un prospecteur ne manipule que les échéanciers de ses ventes.
DROP POLICY IF EXISTS schedules_insert ON public.payment_schedules;
DROP POLICY IF EXISTS schedules_update ON public.payment_schedules;
CREATE POLICY schedules_insert ON public.payment_schedules
FOR INSERT TO authenticated
WITH CHECK (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND EXISTS (
      SELECT 1 FROM public.sales s
      JOIN public.prospecteurs p ON p.id = s.prospecteur_id
      WHERE s.id = payment_schedules.sale_id
        AND s.organization_id = payment_schedules.organization_id
        AND p.user_id = (SELECT auth.uid())
        AND p.status = 'active'
    )
  )
);
CREATE POLICY schedules_update ON public.payment_schedules
FOR UPDATE TO authenticated
USING (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND EXISTS (
      SELECT 1 FROM public.sales s
      JOIN public.prospecteurs p ON p.id = s.prospecteur_id
      WHERE s.id = payment_schedules.sale_id
        AND s.organization_id = payment_schedules.organization_id
        AND p.user_id = (SELECT auth.uid())
        AND p.status = 'active'
    )
  )
)
WITH CHECK (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND EXISTS (
      SELECT 1 FROM public.sales s
      JOIN public.prospecteurs p ON p.id = s.prospecteur_id
      WHERE s.id = payment_schedules.sale_id
        AND s.organization_id = payment_schedules.organization_id
        AND p.user_id = (SELECT auth.uid())
        AND p.status = 'active'
    )
  )
);

-- PAYMENTS : le prospecteur ne peut enregistrer/agir que sur ses propres ventes.
DROP POLICY IF EXISTS payments_insert ON public.payments;
CREATE POLICY payments_insert ON public.payments
FOR INSERT TO authenticated
WITH CHECK (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR (
    private.is_prospecteur(organization_id)
    AND prospecteur_id IN (
      SELECT p.id FROM public.prospecteurs p
      WHERE p.user_id = (SELECT auth.uid())
        AND p.organization_id = payments.organization_id
        AND p.status = 'active'
    )
  )
);

-- SALE ITEMS : accès métier aligné sur la vente parente.
CREATE POLICY sale_items_admin_access ON public.sale_items
FOR ALL TO authenticated
USING (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR EXISTS (
    SELECT 1 FROM public.sales s
    JOIN public.prospecteurs p ON p.id = s.prospecteur_id
    WHERE s.id = sale_items.sale_id
      AND s.organization_id = sale_items.organization_id
      AND p.user_id = (SELECT auth.uid())
      AND p.status = 'active'
  )
)
WITH CHECK (
  private.is_super_admin()
  OR private.is_org_admin(organization_id)
  OR EXISTS (
    SELECT 1 FROM public.sales s
    JOIN public.prospecteurs p ON p.id = s.prospecteur_id
    WHERE s.id = sale_items.sale_id
      AND s.organization_id = sale_items.organization_id
      AND p.user_id = (SELECT auth.uid())
      AND p.status = 'active'
  )
);
