-- JDV CRM: canonical subscription lifecycle
-- Source of truth: organization_subscriptions.
-- The legacy subscriptions table is retained untouched for compatibility and is not used by this lifecycle.

-- 1) Complete the 14-day trial plan required by the existing onboarding function.
insert into public.subscription_plans
  (code, name, description, price, currency, duration_days, max_admins, max_prospecteurs, max_clients, features, active, billing_amount_xof)
values
  ('TRIAL', 'Essai gratuit', 'Période d''essai gratuite de 14 jours', 0, 'USD', 14, null, null, null,
   jsonb_build_object('trial', true, 'crm', true, 'stock', true, 'terrain', true, 'commissions', true, 'daily_tokens', true),
   true, 0)
on conflict (code) do update set
  name = excluded.name,
  description = excluded.description,
  price = excluded.price,
  currency = excluded.currency,
  duration_days = excluded.duration_days,
  features = excluded.features,
  active = true,
  billing_amount_xof = excluded.billing_amount_xof,
  updated_at = now();

-- 2) Enforce valid plan/status references for the canonical table.
alter table public.organization_subscriptions
  drop constraint if exists organization_subscriptions_plan_id_fkey;
alter table public.organization_subscriptions
  add constraint organization_subscriptions_plan_id_fkey
  foreign key (plan_id) references public.subscription_plans(id) on delete restrict;

alter table public.organization_subscriptions
  drop constraint if exists organization_subscriptions_organization_id_fkey;
alter table public.organization_subscriptions
  add constraint organization_subscriptions_organization_id_fkey
  foreign key (organization_id) references public.organizations(id) on delete cascade;

alter table public.organization_subscriptions
  drop constraint if exists organization_subscriptions_status_check;
alter table public.organization_subscriptions
  add constraint organization_subscriptions_status_check
  check (status in ('pending','trial','active','past_due','expired','cancelled'));

alter table public.organization_subscriptions
  drop constraint if exists organization_subscriptions_dates_check;
alter table public.organization_subscriptions
  add constraint organization_subscriptions_dates_check
  check (expires_at is null or started_at is null or expires_at >= started_at);

create unique index if not exists uq_jdvcrm_org_active_subscription
  on public.organization_subscriptions(organization_id)
  where status in ('pending','trial','active','past_due');

create index if not exists idx_jdvcrm_org_subscriptions_expiry
  on public.organization_subscriptions(organization_id, expires_at)
  where status in ('trial','active','past_due');

-- 3) Canonical secure lookup: SUPER ADMIN bypasses subscription restrictions.
create or replace function public.jdvcrm_get_current_subscription_v1(p_organization_id uuid)
returns table (
  subscription_id uuid,
  organization_id uuid,
  plan_id uuid,
  plan_code text,
  plan_name text,
  status text,
  started_at timestamptz,
  expires_at timestamptz,
  auto_renew boolean,
  is_effectively_active boolean
)
language plpgsql
security definer
set search_path = public, private
as $$
begin
  if auth.uid() is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if not private.is_super_admin() and not private.is_org_admin(p_organization_id) then
    raise exception 'ACCESS_DENIED';
  end if;

  return query
  select os.id, os.organization_id, os.plan_id, sp.code, sp.name,
         case
           when os.status in ('trial','active','past_due')
                and (os.expires_at is null or os.expires_at > now())
             then os.status
           when os.status in ('trial','active','past_due')
                and os.expires_at <= now()
             then 'expired'
           else os.status
         end,
         os.started_at, os.expires_at, os.auto_renew,
         (os.status in ('trial','active','past_due') and (os.expires_at is null or os.expires_at > now()))
  from public.organization_subscriptions os
  join public.subscription_plans sp on sp.id = os.plan_id
  where os.organization_id = p_organization_id
  order by case os.status when 'active' then 1 when 'trial' then 2 when 'past_due' then 3 when 'pending' then 4 else 5 end,
           coalesce(os.expires_at, 'infinity'::timestamptz) desc
  limit 1;
end;
$$;

-- 4) Expiration job-safe function. No payment is created or activated here.
create or replace function public.jdvcrm_expire_subscriptions_v1()
returns integer
language plpgsql
security definer
set search_path = public, private
as $$
declare v_count integer;
begin
  if auth.uid() is null or not private.is_super_admin() then
    raise exception 'SUPER_ADMIN_REQUIRED';
  end if;

  update public.organization_subscriptions
     set status = 'expired', updated_at = now()
   where status in ('trial','active','past_due')
     and expires_at is not null
     and expires_at <= now();

  get diagnostics v_count = row_count;

  update public.organizations o
     set subscription_status = 'expired', updated_at = now()
   where o.id in (
     select os.organization_id
     from public.organization_subscriptions os
     where os.status = 'expired'
   )
   and o.subscription_status in ('trial','active','past_due');

  return v_count;
end;
$$;

-- 5) Secure activation/prolongation primitive for the future FedaPay webhook.
-- It is deliberately SUPER ADMIN-only for now; the external webhook layer will call it server-side later.
create or replace function public.jdvcrm_activate_subscription_v1(
  p_subscription_id uuid,
  p_provider text default null,
  p_provider_reference text default null,
  p_started_at timestamptz default now()
)
returns public.organization_subscriptions
language plpgsql
security definer
set search_path = public, private
as $$
declare v_sub public.organization_subscriptions;
        v_plan public.subscription_plans;
        v_end timestamptz;
begin
  if auth.uid() is null or not private.is_super_admin() then
    raise exception 'SUPER_ADMIN_REQUIRED';
  end if;

  select * into v_sub
  from public.organization_subscriptions
  where id = p_subscription_id
  for update;

  if not found then
    raise exception 'SUBSCRIPTION_NOT_FOUND';
  end if;

  select * into v_plan from public.subscription_plans where id = v_sub.plan_id and active = true;
  if not found then
    raise exception 'PLAN_NOT_FOUND';
  end if;

  v_end := p_started_at + make_interval(days => v_plan.duration_days);

  update public.organization_subscriptions
     set status = 'active',
         started_at = p_started_at,
         expires_at = v_end,
         external_reference = coalesce(p_provider_reference, external_reference),
         updated_at = now()
   where id = v_sub.id
   returning * into v_sub;

  update public.organizations
     set subscription_status = 'active', updated_at = now()
   where id = v_sub.organization_id;

  return v_sub;
end;
$$;

-- 6) Publicly callable permissions are restricted to authenticated users.
revoke all on function public.jdvcrm_get_current_subscription_v1(uuid) from public, anon;
grant execute on function public.jdvcrm_get_current_subscription_v1(uuid) to authenticated;
revoke all on function public.jdvcrm_expire_subscriptions_v1() from public, anon, authenticated;
grant execute on function public.jdvcrm_expire_subscriptions_v1() to authenticated;
revoke all on function public.jdvcrm_activate_subscription_v1(uuid,text,text,timestamptz) from public, anon, authenticated;
grant execute on function public.jdvcrm_activate_subscription_v1(uuid,text,text,timestamptz) to authenticated;

comment on table public.organization_subscriptions is 'JDV CRM canonical organization subscription lifecycle. Retained as source of truth; legacy subscriptions table is not used by this lifecycle.';
comment on table public.subscriptions is 'Legacy compatibility table retained intentionally; do not use as the canonical subscription source.';
