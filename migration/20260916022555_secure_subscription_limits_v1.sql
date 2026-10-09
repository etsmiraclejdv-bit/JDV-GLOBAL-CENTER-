-- BLOC 3 : contrôle centralisé des quotas d'abonnement

create unique index if not exists uq_subscription_limits_plan_resource
on public.subscription_limits(plan_id, resource_code);

-- Synchronise les trois limites natives des plans dans subscription_limits.
insert into public.subscription_limits(plan_id,resource_code,limit_value,unlimited)
select sp.id,'admins',sp.max_admins,(sp.max_admins is null)
from public.subscription_plans sp
on conflict (plan_id,resource_code) do update set
  limit_value=excluded.limit_value,
  unlimited=excluded.unlimited;

insert into public.subscription_limits(plan_id,resource_code,limit_value,unlimited)
select sp.id,'prospecteurs',sp.max_prospecteurs,(sp.max_prospecteurs is null)
from public.subscription_plans sp
on conflict (plan_id,resource_code) do update set
  limit_value=excluded.limit_value,
  unlimited=excluded.unlimited;

insert into public.subscription_limits(plan_id,resource_code,limit_value,unlimited)
select sp.id,'clients',sp.max_clients,(sp.max_clients is null)
from public.subscription_plans sp
on conflict (plan_id,resource_code) do update set
  limit_value=excluded.limit_value,
  unlimited=excluded.unlimited;

create or replace function public.jdvcrm_check_subscription_limit_v1(
  p_organization_id uuid,
  p_resource_code text
)
returns table(
  allowed boolean,
  resource_code text,
  current_count bigint,
  limit_value bigint,
  unlimited boolean,
  subscription_status text,
  plan_code text,
  reason text
)
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_plan_id uuid;
  v_status text;
  v_plan_code text;
  v_limit bigint;
  v_unlimited boolean;
  v_count bigint := 0;
begin
  if auth.uid() is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if not private.is_super_admin() and not private.is_org_admin(p_organization_id) then
    raise exception 'ACCESS_DENIED';
  end if;

  select os.plan_id, os.status, sp.code
    into v_plan_id, v_status, v_plan_code
  from public.organization_subscriptions os
  join public.subscription_plans sp on sp.id=os.plan_id
  where os.organization_id=p_organization_id
    and os.status in ('trial','active','past_due')
    and (os.expires_at is null or os.expires_at > now())
  order by case os.status when 'active' then 1 when 'trial' then 2 else 3 end,
           coalesce(os.expires_at,'infinity'::timestamptz) desc
  limit 1;

  if private.is_super_admin() then
    return query select true,p_resource_code,0::bigint,null::bigint,true,
      coalesce(v_status,'super_admin'),coalesce(v_plan_code,'SUPER_ADMIN'),'SUPER_ADMIN_UNLIMITED';
    return;
  end if;

  if v_plan_id is null then
    return query select false,p_resource_code,0::bigint,0::bigint,false,
      'inactive',null::text,'SUBSCRIPTION_REQUIRED';
    return;
  end if;

  select sl.limit_value, sl.unlimited
    into v_limit,v_unlimited
  from public.subscription_limits sl
  where sl.plan_id=v_plan_id and sl.resource_code=lower(trim(p_resource_code));

  if lower(trim(p_resource_code))='admins' then
    select count(*) into v_count
    from public.organization_members om
    where om.organization_id=p_organization_id
      and om.status='active'
      and om.role in ('business_admin','admin','administrateur');
  elsif lower(trim(p_resource_code))='prospecteurs' then
    select count(*) into v_count
    from public.prospecteurs p
    where p.organization_id=p_organization_id
      and p.status='active';
  elsif lower(trim(p_resource_code))='clients' then
    select count(*) into v_count
    from public.clients c
    where c.organization_id=p_organization_id
      and c.archived_at is null;
  else
    raise exception 'UNKNOWN_RESOURCE_CODE';
  end if;

  if coalesce(v_unlimited,false) then
    return query select true,lower(trim(p_resource_code)),v_count,v_limit,true,
      v_status,v_plan_code,'UNLIMITED';
  end if;

  return query select (v_count < coalesce(v_limit,0)),lower(trim(p_resource_code)),v_count,
    coalesce(v_limit,0),false,v_status,v_plan_code,
    case when v_count < coalesce(v_limit,0) then 'LIMIT_AVAILABLE' else 'LIMIT_REACHED' end;
end;
$$;

revoke all on function public.jdvcrm_check_subscription_limit_v1(uuid,text) from public,anon;
grant execute on function public.jdvcrm_check_subscription_limit_v1(uuid,text) to authenticated;
