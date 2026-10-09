do $$
declare r record;
begin
  for r in
    select p.oid, n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) as args
    from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public'
      and has_function_privilege('anon', p.oid, 'execute')
  loop
    execute format('revoke execute on function %I.%I(%s) from anon', r.nspname, r.proname, r.args);
  end loop;
end $$;

revoke execute on function public.jdVcrm_process_subscription_webhook_v1(text,text,text,uuid,numeric,text,text,text,jsonb) from authenticated;
revoke execute on function public.jdvcrm_confirm_subscription_payment_v1(uuid,numeric,text,text,text,text,jsonb) from authenticated;

-- These payment-provider processing functions are service-role/backend only.
revoke execute on function public.jdvcrm_process_subscription_webhook_v1(text,text,text,uuid,numeric,text,text,text,jsonb) from public, anon, authenticated;
revoke execute on function public.jdvcrm_confirm_subscription_payment_v1(uuid,numeric,text,text,text,text,jsonb) from public, anon, authenticated;

grant execute on function public.jdvcrm_process_subscription_webhook_v1(text,text,text,uuid,numeric,text,text,text,jsonb) to service_role;
grant execute on function public.jdvcrm_confirm_subscription_payment_v1(uuid,numeric,text,text,text,text,jsonb) to service_role;
