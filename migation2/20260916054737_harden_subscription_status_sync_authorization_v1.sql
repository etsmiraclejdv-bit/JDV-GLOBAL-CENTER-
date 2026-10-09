CREATE OR REPLACE FUNCTION public.jdvcrm_sync_subscription_status_v1(p_organization_id uuid)
RETURNS text
LANGUAGE plpgsql
SECURITY DEFINER
SET search_path = 'public', 'private'
AS $function$
declare
  v_status text;
  v_expiry timestamptz;
  v_effective text;
begin
  if current_setting('request.jwt.claim.role', true) = 'service_role' then
    null;
  elsif auth.uid() is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  elsif not (private.is_super_admin() or private.is_org_admin(p_organization_id)) then
    raise exception 'ACCESS_DENIED';
  end if;

  if p_organization_id is null then
    raise exception 'ORGANIZATION_REQUIRED';
  end if;

  select os.status, os.expires_at
    into v_status, v_expiry
  from public.organization_subscriptions os
  where os.organization_id = p_organization_id
  order by case os.status
             when 'active' then 1
             when 'trial' then 2
             when 'past_due' then 3
             when 'pending' then 4
             else 5
           end,
           coalesce(os.expires_at, 'infinity'::timestamptz) desc
  limit 1;

  if v_status is null then
    update public.organizations
       set subscription_status = 'inactive',
           updated_at = now()
     where id = p_organization_id;
    return 'inactive';
  end if;

  if v_status in ('trial','active','past_due')
     and v_expiry is not null
     and v_expiry <= now()
  then
    update public.organization_subscriptions
       set status = 'expired',
           updated_at = now()
     where organization_id = p_organization_id
       and status in ('trial','active','past_due')
       and expires_at is not null
       and expires_at <= now();

    v_effective := 'expired';
  else
    v_effective := v_status;
  end if;

  update public.organizations
     set subscription_status = v_effective,
         updated_at = now()
   where id = p_organization_id;

  return v_effective;
end;
$function$;

REVOKE ALL ON FUNCTION public.jdvcrm_sync_subscription_status_v1(uuid) FROM PUBLIC;
GRANT EXECUTE ON FUNCTION public.jdvcrm_sync_subscription_status_v1(uuid) TO authenticated;
REVOKE EXECUTE ON FUNCTION public.jdvcrm_sync_subscription_status_v1(uuid) FROM anon;
