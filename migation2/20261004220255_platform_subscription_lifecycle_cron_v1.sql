-- Automatic subscription expiry/suspension for JDV CRM platform.
create extension if not exists pg_cron with schema extensions;
create or replace function public.jdvcrm_subscription_lifecycle_job_v1()
returns integer language plpgsql security definer set search_path=public,private as $function$
declare v_count integer:=0;
begin
 update public.organization_subscriptions set status='expired',updated_at=now() where status in('trial','active','past_due') and expires_at is not null and expires_at<=now();
 get diagnostics v_count=row_count;
 update public.organizations o set subscription_status='expired',status='suspended',updated_at=now()
 where o.id in(select os.organization_id from public.organization_subscriptions os where os.status='expired')
 and o.owner_user_id is not null and o.subscription_status in('trial','active','past_due') and o.status not in('blocked');
 insert into public.notifications(organization_id,user_id,title,message,type,metadata)
 select o.id,o.owner_user_id,'Abonnement suspendu automatiquement','Votre abonnement JDV CRM a expiré ou n''a pas été régularisé. Renouvelez votre abonnement pour réactiver votre entreprise.','subscription',jsonb_build_object('action','renew_subscription','automatic',true)
 from public.organizations o where o.status='suspended' and o.subscription_status='expired' and o.owner_user_id is not null
 and not exists(select 1 from public.notifications n where n.organization_id=o.id and n.user_id=o.owner_user_id and n.type='subscription' and n.metadata->>'action'='renew_subscription' and n.created_at>now()-interval '24 hours');
 return v_count;
end;$function$;
revoke all on function public.jdvcrm_subscription_lifecycle_job_v1() from public,anon,authenticated;
select cron.unschedule(jobid) from cron.job where jobname='jdvcrm-subscription-lifecycle';
select cron.schedule('jdvcrm-subscription-lifecycle','0 * * * *',$$select public.jdvcrm_subscription_lifecycle_job_v1();$$);