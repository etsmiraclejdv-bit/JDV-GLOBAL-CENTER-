-- Concepteur: relier les 3 branches et piloter le cycle des abonnements.
create or replace function public.jdvcrm_get_concepteur_workspace_v1()
returns table(branch_code text,branch_label text,route text,organization_id uuid,organization_name text,is_own_company boolean,subscription_required boolean)
language plpgsql security definer set search_path=public,private as $function$
declare v_uid uuid:=auth.uid(); v_own_org_id uuid;
begin
 if v_uid is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
 if not private.is_super_admin() then raise exception 'CONCEPTEUR_ONLY'; end if;
 select o.id into v_own_org_id from public.organizations o where o.owner_user_id=v_uid and o.status in ('active','trial','suspended') order by o.created_at limit 1;
 return query select 'admin','ADMINISTRATEUR / ENTREPRISE','/business/dashboard',v_own_org_id,(select o.name from public.organizations o where o.id=v_own_org_id),true,false;
 return query select 'prospecteur','PROSPECTEUR','/terrain/dashboard',v_own_org_id,(select o.name from public.organizations o where o.id=v_own_org_id),true,false;
 return query select 'concepteur','GESTION DE LA PLATEFORME','/hidden-concepteur-gate/dashboard',null::uuid,null::text,true,false;
end;$function$;

create or replace function public.jdvcrm_platform_subscription_guard_v1()
returns integer language plpgsql security definer set search_path=public,private as $function$
declare v_count integer:=0;
begin
 if auth.uid() is not null and private.is_super_admin() then
  update public.organization_subscriptions set status='expired',updated_at=now() where status in('trial','active','past_due') and expires_at is not null and expires_at<=now();
  get diagnostics v_count=row_count;
  update public.organizations o set subscription_status='expired',status='suspended',updated_at=now()
   where o.id in(select os.organization_id from public.organization_subscriptions os where os.status='expired')
   and o.owner_user_id is not null and o.subscription_status in('trial','active','past_due') and o.status not in('blocked');
 end if;
 return v_count;
end;$function$;

create or replace function public.jdvcrm_get_platform_companies_v1()
returns table(organization_id uuid,organization_name text,city text,phone text,organization_status text,subscription_status text,plan_code text,plan_name text,plan_price numeric,plan_currency text,started_at timestamptz,expires_at timestamptz,auto_renew boolean,last_payment_at timestamptz,last_payment_status text,days_remaining integer)
language plpgsql security definer set search_path=public,private as $function$
begin
 if auth.uid() is null or not private.is_super_admin() then raise exception 'SUPER_ADMIN_REQUIRED'; end if;
 perform public.jdvcrm_platform_subscription_guard_v1();
 return query
 select o.id,o.name,o.city,o.phone,o.status,o.subscription_status,sp.code,sp.name,sp.price,sp.currency,os.started_at,os.expires_at,coalesce(os.auto_renew,false),lp.paid_at,lp.status,
 case when os.expires_at is null then null else greatest(0,ceil(extract(epoch from(os.expires_at-now()))/86400)::integer) end
 from public.organizations o
 left join lateral(select s.* from public.organization_subscriptions s where s.organization_id=o.id order by s.created_at desc limit 1) os on true
 left join public.subscription_plans sp on sp.id=os.plan_id
 left join lateral(select p.paid_at,p.status from public.subscription_payments p where p.organization_id=o.id order by coalesce(p.paid_at,p.created_at) desc limit 1) lp on true
 order by o.created_at desc;
end;$function$;

create or replace function public.jdvcrm_platform_suspend_organization_v1(p_organization_id uuid)
returns jsonb language plpgsql security definer set search_path=public,private as $function$
begin
 if auth.uid() is null or not private.is_super_admin() then raise exception 'SUPER_ADMIN_REQUIRED'; end if;
 update public.organizations set status='suspended',updated_at=now() where id=p_organization_id and owner_user_id is not null;
 if not found then raise exception 'ORGANIZATION_NOT_FOUND'; end if;
 return jsonb_build_object('success',true,'status','suspended');
end;$function$;

create or replace function public.jdvcrm_platform_subscription_reminder_v1(p_organization_id uuid)
returns jsonb language plpgsql security definer set search_path=public,private as $function$
declare v_owner uuid;v_name text;
begin
 if auth.uid() is null or not private.is_super_admin() then raise exception 'SUPER_ADMIN_REQUIRED'; end if;
 select owner_user_id,name into v_owner,v_name from public.organizations where id=p_organization_id;
 if v_owner is null then raise exception 'ORGANIZATION_NOT_FOUND'; end if;
 insert into public.notifications(organization_id,user_id,title,message,type,metadata)
 values(p_organization_id,v_owner,'Relance abonnement JDV CRM','Votre abonnement arrive à échéance ou nécessite une régularisation. Ouvrez JDV CRM pour renouveler votre abonnement.','subscription',jsonb_build_object('organization_id',p_organization_id,'action','renew_subscription'));
 return jsonb_build_object('success',true,'organization',v_name);
end;$function$;

create or replace function public.jdvcrm_platform_set_auto_renew_v1(p_organization_id uuid,p_auto_renew boolean)
returns jsonb language plpgsql security definer set search_path=public,private as $function$
begin
 if auth.uid() is null or not private.is_super_admin() then raise exception 'SUPER_ADMIN_REQUIRED'; end if;
 update public.organization_subscriptions set auto_renew=p_auto_renew,updated_at=now()
 where id=(select id from public.organization_subscriptions where organization_id=p_organization_id order by created_at desc limit 1);
 if not found then raise exception 'SUBSCRIPTION_NOT_FOUND'; end if;
 return jsonb_build_object('success',true,'auto_renew',p_auto_renew);
end;$function$;

revoke all on function public.jdvcrm_platform_subscription_guard_v1() from public,anon;
revoke all on function public.jdvcrm_get_platform_companies_v1() from public,anon;
revoke all on function public.jdvcrm_platform_suspend_organization_v1(uuid) from public,anon;
revoke all on function public.jdvcrm_platform_subscription_reminder_v1(uuid) from public,anon;
revoke all on function public.jdvcrm_platform_set_auto_renew_v1(uuid,boolean) from public,anon;
grant execute on function public.jdvcrm_platform_subscription_guard_v1() to authenticated;
grant execute on function public.jdvcrm_get_platform_companies_v1() to authenticated;
grant execute on function public.jdvcrm_platform_suspend_organization_v1(uuid) to authenticated;
grant execute on function public.jdvcrm_platform_subscription_reminder_v1(uuid) to authenticated;
grant execute on function public.jdvcrm_platform_set_auto_renew_v1(uuid,boolean) to authenticated;