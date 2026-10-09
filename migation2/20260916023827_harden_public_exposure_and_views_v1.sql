-- BLOCK 10: close anonymous table exposure and make public reporting views obey RLS.

-- Anonymous users do not directly access the CRM database. Public onboarding
-- is performed through authenticated RPCs / Auth, not table access.
do $$
declare
  r record;
begin
  for r in
    select n.nspname as schema_name, c.relname as object_name, c.relkind
    from pg_class c
    join pg_namespace n on n.oid = c.relnamespace
    where n.nspname = 'public'
      and c.relkind in ('r','p','v','m')
  loop
    if r.relkind in ('r','p') then
      execute format('revoke all privileges on table %I.%I from anon', r.schema_name, r.object_name);
    elsif r.relkind = 'v' then
      execute format('revoke all privileges on table %I.%I from anon', r.schema_name, r.object_name);
      execute format('alter view %I.%I set (security_invoker = true)', r.schema_name, r.object_name);
    end if;
  end loop;
end $$;
