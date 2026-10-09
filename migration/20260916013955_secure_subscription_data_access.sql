ALTER TABLE public.organization_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_limits ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.subscription_payments ENABLE ROW LEVEL SECURITY;

DROP POLICY IF EXISTS subscription_plans_authenticated_read ON public.subscription_plans;
CREATE POLICY subscription_plans_authenticated_read ON public.subscription_plans
FOR SELECT TO authenticated USING (active = true OR private.is_super_admin());

DROP POLICY IF EXISTS organization_subscriptions_super_admin ON public.organization_subscriptions;
CREATE POLICY organization_subscriptions_super_admin ON public.organization_subscriptions
FOR ALL TO authenticated USING (private.is_super_admin()) WITH CHECK (private.is_super_admin());
DROP POLICY IF EXISTS organization_subscriptions_org_read ON public.organization_subscriptions;
CREATE POLICY organization_subscriptions_org_read ON public.organization_subscriptions
FOR SELECT TO authenticated USING (organization_id = private.current_org_id());

DROP POLICY IF EXISTS subscriptions_super_admin ON public.subscriptions;
CREATE POLICY subscriptions_super_admin ON public.subscriptions
FOR ALL TO authenticated USING (private.is_super_admin()) WITH CHECK (private.is_super_admin());
DROP POLICY IF EXISTS subscriptions_org_read ON public.subscriptions;
CREATE POLICY subscriptions_org_read ON public.subscriptions
FOR SELECT TO authenticated USING (organization_id = private.current_org_id());

DROP POLICY IF EXISTS subscription_limits_super_admin ON public.subscription_limits;
CREATE POLICY subscription_limits_super_admin ON public.subscription_limits
FOR ALL TO authenticated USING (private.is_super_admin()) WITH CHECK (private.is_super_admin());
DROP POLICY IF EXISTS subscription_limits_authenticated_read ON public.subscription_limits;
CREATE POLICY subscription_limits_authenticated_read ON public.subscription_limits
FOR SELECT TO authenticated USING (EXISTS (SELECT 1 FROM public.subscription_plans sp WHERE sp.id = subscription_limits.plan_id AND sp.active = true) OR private.is_super_admin());

DROP POLICY IF EXISTS subscription_events_super_admin ON public.subscription_events;
CREATE POLICY subscription_events_super_admin ON public.subscription_events
FOR ALL TO authenticated USING (private.is_super_admin()) WITH CHECK (private.is_super_admin());
DROP POLICY IF EXISTS subscription_events_org_read ON public.subscription_events;
CREATE POLICY subscription_events_org_read ON public.subscription_events
FOR SELECT TO authenticated USING (organization_id = private.current_org_id());

DROP POLICY IF EXISTS subscription_payments_super_admin ON public.subscription_payments;
CREATE POLICY subscription_payments_super_admin ON public.subscription_payments
FOR ALL TO authenticated USING (private.is_super_admin()) WITH CHECK (private.is_super_admin());
DROP POLICY IF EXISTS subscription_payments_org_read ON public.subscription_payments;
CREATE POLICY subscription_payments_org_read ON public.subscription_payments
FOR SELECT TO authenticated USING (organization_id = private.current_org_id());
