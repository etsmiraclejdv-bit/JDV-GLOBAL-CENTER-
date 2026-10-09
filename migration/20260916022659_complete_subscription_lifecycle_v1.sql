-- BLOC 4 : cycle de vie abonnement.
-- Les traitements internes peuvent être appelés par le service_role (webhook)
-- ou par le SUPER ADMIN. Les utilisateurs d'entreprise ne peuvent pas
-- confirmer eux-mêmes un paiement.

create or replace function public.jdvcrm_sync_subscription_status_v1(p_organization_id uuid)
returns text
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_status text;
  v_expiry timestamptz;
  v_effective text;
begin
  if auth.uid() is null and current_setting('request.jwt.claim.role', true) <> 'service_role' then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  select os.status, os.expires_at
    into v_status, v_expiry
  from public.organization_subscriptions os
  where os.organization_id = p_organization_id
  order by case os.status when 'active' then 1 when 'trial' then 2 when 'past_due' then 3 when 'pending' then 4 else 5 end,
           coalesce(os.expires_at,'infinity'::timestamptz) desc
  limit 1;

  if v_status is null then
    update public.organizations set subscription_status='inactive',updated_at=now() where id=p_organization_id;
    return 'inactive';
  end if;

  if v_status in ('trial','active','past_due') and v_expiry is not null and v_expiry <= now() then
    update public.organization_subscriptions
       set status='expired',updated_at=now()
     where organization_id=p_organization_id
       and status in ('trial','active','past_due')
       and expires_at is not null and expires_at <= now();
    v_effective := 'expired';
  else
    v_effective := v_status;
  end if;

  update public.organizations
     set subscription_status=v_effective,updated_at=now()
   where id=p_organization_id;

  return v_effective;
end;
$$;

revoke all on function public.jdvcrm_sync_subscription_status_v1(uuid) from public, anon, authenticated;
grant execute on function public.jdvcrm_sync_subscription_status_v1(uuid) to authenticated;

create or replace function public.jdvcrm_confirm_subscription_payment_v1(
  p_subscription_id uuid,
  p_amount numeric,
  p_currency text,
  p_provider text,
  p_provider_reference text,
  p_payment_method text default null,
  p_metadata jsonb default '{}'::jsonb
)
returns public.subscription_payments
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_sub public.organization_subscriptions;
  v_plan public.subscription_plans;
  v_payment public.subscription_payments;
  v_start timestamptz;
  v_end timestamptz;
begin
  if current_setting('request.jwt.claim.role', true) <> 'service_role'
     and (auth.uid() is null or not private.is_super_admin()) then
    raise exception 'SERVICE_ROLE_OR_SUPER_ADMIN_REQUIRED';
  end if;

  if p_amount is null or p_amount <= 0 then raise exception 'INVALID_AMOUNT'; end if;
  if nullif(trim(p_provider),'') is null then raise exception 'PROVIDER_REQUIRED'; end if;
  if nullif(trim(p_provider_reference),'') is null then raise exception 'PROVIDER_REFERENCE_REQUIRED'; end if;

  select * into v_sub
  from public.organization_subscriptions
  where id=p_subscription_id
  for update;
  if not found then raise exception 'SUBSCRIPTION_NOT_FOUND'; end if;

  select * into v_plan from public.subscription_plans where id=v_sub.plan_id and active=true;
  if not found then raise exception 'PLAN_NOT_FOUND'; end if;

  -- Idempotence : un même provider_reference ne crée jamais deux paiements.
  select * into v_payment
  from public.subscription_payments
  where provider=trim(p_provider) and provider_reference=trim(p_provider_reference)
  limit 1;
  if found then return v_payment; end if;

  v_start := case when v_sub.status in ('active','trial','past_due') and v_sub.expires_at is not null and v_sub.expires_at > now()
                  then v_sub.expires_at else now() end;
  v_end := v_start + make_interval(days => v_plan.duration_days);

  insert into public.subscription_payments(
    organization_id,subscription_id,amount,currency,provider,provider_reference,
    payment_method,status,paid_at,metadata
  ) values (
    v_sub.organization_id,p_subscription_id,p_amount,upper(trim(p_currency)),trim(p_provider),
    trim(p_provider_reference),p_payment_method,'successful',now(),coalesce(p_metadata,'{}'::jsonb)
  ) returning * into v_payment;

  update public.organization_subscriptions
     set status='active',started_at=coalesce(started_at,now()),expires_at=v_end,
         external_reference=trim(p_provider_reference),updated_at=now()
   where id=p_subscription_id;

  update public.organizations
     set subscription_status='active',updated_at=now()
   where id=v_sub.organization_id;

  insert into public.subscription_events(
    organization_id,subscription_id,event_type,provider,provider_reference,amount,currency,metadata
  ) values (
    v_sub.organization_id,p_subscription_id,'payment_succeeded',trim(p_provider),trim(p_provider_reference),
    p_amount,upper(trim(p_currency)),coalesce(p_metadata,'{}'::jsonb)
  );

  return v_payment;
end;
$$;

revoke all on function public.jdvcrm_confirm_subscription_payment_v1(uuid,numeric,text,text,text,text,jsonb) from public, anon, authenticated;
grant execute on function public.jdvcrm_confirm_subscription_payment_v1(uuid,numeric,text,text,text,text,jsonb) to authenticated;

-- Synchronisation idempotente des entreprises déjà existantes : aucune donnée
-- d'abonnement n'est créée automatiquement ici.;
