create or replace function private.has_active_subscription(p_org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public, private
as $$
  select
    private.is_super_admin()
    or exists (
      select 1
      from public.organization_subscriptions os
      where os.organization_id = p_org_id
        and os.status in ('trial','active','past_due')
        and (os.expires_at is null or os.expires_at > now())
    );
$$;

create or replace function public.jdvcrm_get_business_access_v1(p_organization_id uuid default null)
returns jsonb
language plpgsql
stable
security definer
set search_path = public, private
as $$
declare
  v_org_id uuid := coalesce(p_organization_id, private.current_org_id());
  v_is_super boolean;
  v_is_admin boolean;
  v_is_member boolean;
  v_sub record;
begin
  if auth.uid() is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  v_is_super := private.is_super_admin();
  v_is_admin := case when v_org_id is not null then private.is_org_admin(v_org_id) else false end;
  v_is_member := case when v_org_id is not null then private.is_org_member(v_org_id) else false end;

  if v_org_id is null then
    return jsonb_build_object(
      'organization_id', null,
      'is_super_admin', v_is_super,
      'is_admin', false,
      'is_member', false,
      'business_access', v_is_super,
      'reason', case when v_is_super then 'SUPER_ADMIN_UNLIMITED' else 'ORGANIZATION_REQUIRED' end
    );
  end if;

  if v_is_super then
    return jsonb_build_object(
      'organization_id', v_org_id,
      'is_super_admin', true,
      'is_admin', v_is_admin,
      'is_member', v_is_member,
      'business_access', true,
      'unlimited', true,
      'reason', 'SUPER_ADMIN_UNLIMITED'
    );
  end if;

  if not v_is_member then
    return jsonb_build_object(
      'organization_id', v_org_id,
      'is_super_admin', false,
      'is_admin', false,
      'is_member', false,
      'business_access', false,
      'unlimited', false,
      'reason', 'ORGANIZATION_ACCESS_REQUIRED'
    );
  end if;

  select os.status, os.started_at, os.expires_at, sp.code plan_code, sp.name plan_name
    into v_sub
  from public.organization_subscriptions os
  join public.subscription_plans sp on sp.id = os.plan_id
  where os.organization_id = v_org_id
    and os.status in ('trial','active','past_due')
    and (os.expires_at is null or os.expires_at > now())
  order by case os.status when 'active' then 1 when 'trial' then 2 when 'past_due' then 3 else 4 end,
           os.expires_at desc nulls last
  limit 1;

  if v_sub is null then
    return jsonb_build_object(
      'organization_id', v_org_id,
      'is_super_admin', false,
      'is_admin', v_is_admin,
      'is_member', true,
      'business_access', false,
      'unlimited', false,
      'reason', 'SUBSCRIPTION_REQUIRED'
    );
  end if;

  return jsonb_build_object(
    'organization_id', v_org_id,
    'is_super_admin', false,
    'is_admin', v_is_admin,
    'is_member', true,
    'business_access', true,
    'unlimited', false,
    'reason', 'SUBSCRIPTION_ACTIVE',
    'subscription_status', v_sub.status,
    'plan_code', v_sub.plan_code,
    'plan_name', v_sub.plan_name,
    'started_at', v_sub.started_at,
    'expires_at', v_sub.expires_at
  );
end;
$$;

revoke execute on function public.jdvcrm_get_business_access_v1(uuid) from public, anon;
grant execute on function public.jdvcrm_get_business_access_v1(uuid) to authenticated;
revoke execute on function private.has_active_subscription(uuid) from public, anon, authenticated;
