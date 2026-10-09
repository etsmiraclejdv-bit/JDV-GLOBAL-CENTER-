begin;

-- Trigger-only SECURITY DEFINER functions must not be exposed as RPC endpoints.
revoke all on function public.jdvcrm_process_payment_v43(uuid) from public, anon, authenticated;
revoke all on function public.jdvcrm_recalculate_sale(uuid) from public, anon, authenticated;
revoke all on function public.jdvcrm_after_payment_v43() from public, anon, authenticated;
revoke all on function public.jdvcrm_after_sale_v42() from public, anon, authenticated;
revoke all on function public.jdvcrm_process_sale_v42(uuid) from public, anon, authenticated;
revoke all on function public.jdvcrm_process_sale_stock_v42(uuid) from public, anon, authenticated;
revoke all on function public.jdvcrm_generate_sale_schedules_v42(uuid) from public, anon, authenticated;
revoke all on function public.jdvcrm_refresh_schedule_v43(uuid) from public, anon, authenticated;
revoke all on function public.jdvcrm_refresh_sale_schedules_v43(uuid) from public, anon, authenticated;

-- Payment creation remains a normal authenticated INSERT through RLS.
-- Financial recalculation is performed only by trusted database triggers.

commit;
