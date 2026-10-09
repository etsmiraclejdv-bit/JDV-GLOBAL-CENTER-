-- Concepteur: accès libre sans abonnement.
-- Les entreprises dont le propriétaire est un super admin actif (concepteur)
-- ne sont jamais expirées ni suspendues par le contrôle d'abonnement.
-- NOTE: déjà appliquée sur Supabase (version 20261005074655). Ce fichier sert à garder l'historique GitHub identique.

create or replace function private.is_platform_owner_org(p_org_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $function$
  select exists (
    select 1
    from public.organizations o
    join public.super_admins sa on sa.user_id = o.owner_user_id
    where o.id = p_org_id
      and sa.status = 'active'
      and coalesce(sa.actif, true) = true
  );
$function$;

revoke all on function private.is_platform_owner_org(uuid) from public, anon, authenticated;

create or replace function public.jdvcrm_subscription_lifecycle_job_v1()
returns integer
language plpgsql
security definer
set search_path = public, private
as $function$
declare v_count integer := 0;
begin
  update public.organization_subscriptions
     set status = 'expired', updated_at = now()
   where status in ('trial','active','past_due')
     and expires_at is not null
     and expires_at <= now()
     and not private.is_platform_owner_org(organization_id);
  get diagnostics v_count = row_count;

  update public.organizations o
     set subscription_status = 'expired', status = 'suspended', updated_at = now()
   where o.id in (select os.organization_id from public.organization_subscriptions os where os.status = 'expired')
     and o.owner_user_id is not null
     and o.subscription_status in ('trial','active','past_due')
     and o.status not in ('blocked')
     and not private.is_platform_owner_org(o.id);

  insert into public.notifications(organization_id, user_id, title, message, type, metadata)
  select o.id, o.owner_user_id, 'Abonnement suspendu automatiquement',
         'Votre abonnement JDV CRM a expiré ou n''a pas été régularisé. Renouvelez votre abonnement pour réactiver votre entreprise.',
         'subscription', jsonb_build_object('action','renew_subscription','automatic',true)
    from public.organizations o
   where o.status = 'suspended' and o.subscription_status = 'expired'
     and o.owner_user_id is not null
     and not private.is_platform_owner_org(o.id)
     and not exists (
       select 1 from public.notifications n
        where n.organization_id = o.id and n.user_id = o.owner_user_id
          and n.type = 'subscription' and n.metadata->>'action' = 'renew_subscription'
          and n.created_at > now() - interval '24 hours');
  return v_count;
end;
$function$;

create or replace function public.jdvcrm_platform_subscription_guard_v1()
returns integer
language plpgsql
security definer
set search_path = public, private
as $function$
declare v_count integer := 0;
begin
  if auth.uid() is not null and private.is_super_admin() then
    update public.organization_subscriptions
       set status = 'expired', updated_at = now()
     where status in ('trial','active','past_due')
       and expires_at is not null
       and expires_at <= now()
       and not private.is_platform_owner_org(organization_id);
    get diagnostics v_count = row_count;

    update public.organizations o
       set subscription_status = 'expired', status = 'suspended', updated_at = now()
     where o.id in (select os.organization_id from public.organization_subscriptions os where os.status = 'expired')
       and o.owner_user_id is not null
       and o.subscription_status in ('trial','active','past_due')
       and o.status not in ('blocked')
       and not private.is_platform_owner_org(o.id);
  end if;
  return v_count;
end;
$function$;

revoke all on function public.jdvcrm_subscription_lifecycle_job_v1() from public, anon, authenticated;
revoke all on function public.jdvcrm_platform_subscription_guard_v1() from public, anon;
grant execute on function public.jdvcrm_platform_subscription_guard_v1() to authenticated;

-- L'abonnement de l'entreprise du concepteur n'a plus d'échéance.
update public.organization_subscriptions os
   set expires_at = null, auto_renew = false, updated_at = now()
 where private.is_platform_owner_org(os.organization_id)
   and os.status in ('trial','active','past_due');