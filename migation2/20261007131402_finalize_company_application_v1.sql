-- Finalisation sécurisée d'une demande d'entreprise après approbation du Concepteur.
create or replace function public.jdvcrm_finalize_company_application_v1(p_application_id uuid)
returns table(organization_id uuid, status text, trial_expires_at timestamptz)
language plpgsql
security definer
set search_path = public, private
as $$
declare
  v_app public.organization_applications%rowtype;
  v_org_id uuid;
  v_trial_plan public.subscription_plans%rowtype;
  v_trial_expires timestamptz;
begin
  if auth.uid() is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  select * into v_app
  from public.organization_applications
  where id = p_application_id
    and applicant_user_id = auth.uid()
  for update;

  if not found then
    raise exception 'APPLICATION_NOT_FOUND';
  end if;

  if v_app.status = 'activated' then
    select id into v_org_id
    from public.organizations
    where owner_user_id = auth.uid()
    order by created_at desc
    limit 1;

    select expires_at into v_trial_expires
    from public.organization_subscriptions
    where organization_id = v_org_id
    order by created_at desc
    limit 1;

    return query select v_org_id, 'activated'::text, v_trial_expires;
    return;
  end if;

  if v_app.status <> 'approved_pending_email' then
    raise exception 'APPLICATION_NOT_APPROVED';
  end if;

  select id into v_org_id
  from public.organizations
  where owner_user_id = auth.uid()
  order by created_at desc
  limit 1;

  if v_org_id is null then
    insert into public.organizations (
      name, legal_name, registration_number, tax_number, email, phone,
      country, address, city, website, owner_user_id, status, subscription_status,
      language, currency, timezone
    )
    values (
      v_app.company_name, v_app.legal_name, v_app.registration_number, v_app.tax_number,
      v_app.professional_email, v_app.phone, v_app.country, v_app.address, v_app.city,
      v_app.website, auth.uid(), 'active', 'trial', 'fr', 'XOF', 'Africa/Porto-Novo'
    )
    returning id into v_org_id;

    insert into public.organization_members (organization_id, user_id, role, status)
    values (v_org_id, auth.uid(), 'business_admin', 'active');

    insert into public.organization_settings (organization_id, settings)
    values (v_org_id, '{}'::jsonb)
    on conflict (organization_id) do nothing;
  else
    update public.organizations
       set status='active',
           subscription_status='trial',
           updated_at=now()
     where id=v_org_id;

    insert into public.organization_members (organization_id, user_id, role, status)
    values (v_org_id, auth.uid(), 'business_admin', 'active')
    on conflict (organization_id, user_id) do update
      set role='business_admin', status='active', updated_at=now();
  end if;

  select * into v_trial_plan
  from public.subscription_plans
  where code='TRIAL' and active=true
  order by duration_days asc
  limit 1;

  if not found then
    raise exception 'TRIAL_PLAN_NOT_FOUND';
  end if;

  select expires_at into v_trial_expires
  from public.organization_subscriptions
  where organization_id=v_org_id
    and status in ('trial','active','past_due')
  order by created_at desc
  limit 1;

  if v_trial_expires is null then
    v_trial_expires := now() + make_interval(days => v_trial_plan.duration_days);
    insert into public.organization_subscriptions (
      organization_id, plan_id, status, started_at, expires_at, auto_renew
    )
    values (
      v_org_id, v_trial_plan.id, 'trial', now(), v_trial_expires, false
    );
  end if;

  update public.organization_applications
     set status='activated',
         email_verified_at=coalesce(email_verified_at, now()),
         activated_at=now(),
         updated_at=now()
   where id=v_app.id;

  return query select v_org_id, 'activated'::text, v_trial_expires;
end;
$$;

revoke all on function public.jdvcrm_finalize_company_application_v1(uuid) from public;
grant execute on function public.jdvcrm_finalize_company_application_v1(uuid) to authenticated;
