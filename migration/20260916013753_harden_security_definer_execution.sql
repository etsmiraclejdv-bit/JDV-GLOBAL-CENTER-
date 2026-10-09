-- SECURITY DEFINER functions must never be callable by the anonymous role.
-- Trigger execution is unaffected by EXECUTE privileges.
DO $$
DECLARE r record;
BEGIN
  FOR r IN
    SELECT p.oid::regprocedure AS fn
    FROM pg_proc p
    JOIN pg_namespace n ON n.oid = p.pronamespace
    WHERE n.nspname = 'public'
      AND p.prosecdef = true
  LOOP
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM PUBLIC', r.fn);
    EXECUTE format('REVOKE EXECUTE ON FUNCTION %s FROM anon', r.fn);
  END LOOP;
END $$;

-- Re-grant only the authenticated RPCs that are intended to be called by the application.
GRANT EXECUTE ON FUNCTION public.register_company(text,text,text,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.create_company_onboarding(uuid,text,text,text,text,text,text,text,text,text,text,text,text,text) TO authenticated;
GRANT EXECUTE ON FUNCTION public.ensure_organization_personalization(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_current_super_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.is_current_user_super_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.verify_current_super_admin() TO authenticated;
GRANT EXECUTE ON FUNCTION public.jdv_business_integrity_report() TO authenticated;
GRANT EXECUTE ON FUNCTION public.jdv_process_prospect_followups() TO authenticated;
GRANT EXECUTE ON FUNCTION public.jdv_run_daily_business_maintenance() TO authenticated;
GRANT EXECUTE ON FUNCTION public.jdVcrm_generate_sale_schedules_v42(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.jdvcrm_get_payment_followups_v43(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.jdvcrm_process_payment_v43(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.jdvcrm_process_sale_stock_v42(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.jdvcrm_process_sale_v42(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.jdvcrm_recalculate_sale(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.jdVcrm_refresh_payment_schedule(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.jdVcrm_refresh_sale_schedules_v43(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.jdVcrm_refresh_schedule_v41(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.jdVcrm_refresh_schedule_v43(uuid) TO authenticated;
GRANT EXECUTE ON FUNCTION public.jdVcrm_generate_sale_schedules_v42(uuid) TO authenticated;
