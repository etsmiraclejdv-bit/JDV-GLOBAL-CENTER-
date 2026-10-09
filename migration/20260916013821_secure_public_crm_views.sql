-- All CRM reporting views contain business data and must not be anonymously readable.
REVOKE SELECT ON TABLE public.jdV_super_admin_modules FROM anon;
REVOKE SELECT ON TABLE public.jdvcrm_clients_overdue FROM anon;
REVOKE SELECT ON TABLE public.jdvcrm_clients_to_reactivate FROM anon;
REVOKE SELECT ON TABLE public.jdvcrm_followup_queue FROM anon;
REVOKE SELECT ON TABLE public.jdvcrm_low_stocks FROM anon;
REVOKE SELECT ON TABLE public.jdvcrm_overdue_credit_sales FROM anon;
REVOKE SELECT ON TABLE public.jdvcrm_overdue_payment_schedules FROM anon;
REVOKE SELECT ON TABLE public.jdvcrm_pending_commissions FROM anon;
REVOKE SELECT ON TABLE public.jdvcrm_prospecteur_followup_queue FROM anon;
REVOKE SELECT ON TABLE public.jdvcrm_prospecteur_stock_status FROM anon;
REVOKE SELECT ON TABLE public.jdvcrm_prospects_to_followup FROM anon;

-- The two legacy views without security_invoker were the risky ones.
ALTER VIEW public.jdvcrm_followup_queue SET (security_invoker = true);
ALTER VIEW public.jdvcrm_overdue_payment_schedules SET (security_invoker = true);
