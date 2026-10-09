-- BLOCK 11: function execution hardening.
-- Preserve the exact current authenticated/service_role access model, while
-- removing implicit PUBLIC/anon execution and preventing future exposure.
do $$
declare
  r record;
  keep_authenticated boolean;
  keep_service_role boolean;
begin
  for r in
    select p.oid, n.nspname, p.proname, pg_get_function_identity_arguments(p.oid) as args
    from pg_proc p
    join pg_namespace n on n.oid = p.pronamespace
    where n.nspname = 'public'
      and p.prokind = 'f'
  loop
    keep_authenticated := has_function_privilege('authenticated', r.oid, 'execute');
    keep_service_role := has_function_privilege('service_role', r.oid, 'execute');

    execute format('revoke execute on function %I.%I(%s) from public, anon, authenticated, service_role',
      r.nspname, r.proname, r.args);

    if keep_authenticated then
      execute format('grant execute on function %I.%I(%s) to authenticated',
        r.nspname, r.proname, r.args);
    end if;

    if keep_service_role then
      execute format('grant execute on function %I.%I(%s) to service_role',
        r.nspname, r.proname, r.args);
    end if;
  end loop;
end $$;

-- New public functions are opt-in rather than automatically executable.
alter default privileges in schema public revoke execute on functions from public;
alter default privileges in schema public revoke execute on functions from anon;
alter default privileges in schema public revoke execute on functions from authenticated;
