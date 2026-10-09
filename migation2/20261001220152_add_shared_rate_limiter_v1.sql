-- Limiteur de débit partagé entre toutes les instances de l'application.
-- Accessible uniquement au service_role (routes API serveur) : aucun accès pour anon / authenticated.
create table if not exists public.rate_limits (
  key text primary key,
  count integer not null default 0,
  reset_at timestamptz not null
);

alter table public.rate_limits enable row level security;
revoke all on table public.rate_limits from anon, authenticated;

create or replace function public.jdvcrm_rate_limit_check_v1(
  p_key text,
  p_limit integer,
  p_window_seconds integer
)
returns table(allowed boolean, remaining integer, retry_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
  v_reset timestamptz;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if p_key is null or length(p_key) = 0 or length(p_key) > 200 then
    raise exception 'INVALID_KEY';
  end if;
  if p_limit is null or p_limit < 1 or p_window_seconds is null or p_window_seconds < 1 then
    raise exception 'INVALID_LIMIT';
  end if;

  insert into public.rate_limits as r (key, count, reset_at)
  values (p_key, 1, now() + make_interval(secs => p_window_seconds))
  on conflict (key) do update
    set count = case when r.reset_at < now() then 1 else r.count + 1 end,
        reset_at = case when r.reset_at < now()
                        then now() + make_interval(secs => p_window_seconds)
                        else r.reset_at end
  returning r.count, r.reset_at into v_count, v_reset;

  -- Nettoyage occasionnel des fenêtres expirées depuis plus d'une heure
  if random() < 0.02 then
    delete from public.rate_limits where reset_at < now() - interval '1 hour';
  end if;

  return query select (v_count <= p_limit), greatest(0, p_limit - v_count), v_reset;
end;
$$;

revoke all on function public.jdvcrm_rate_limit_check_v1(text, integer, integer) from public, anon, authenticated;
grant execute on function public.jdvcrm_rate_limit_check_v1(text, integer, integer) to service_role;
