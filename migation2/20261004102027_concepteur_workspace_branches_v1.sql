-- Concepteur workspace branches
create or replace function public.jdvcrm_get_concepteur_workspace_v1()
returns table(
  branch_code text,
  branch_label text,
  route text,
  organization_id uuid,
  organization_name text,
  is_own_company boolean,
  subscription_required boolean
)
language plpgsql
security definer
set search_path = public, private
as $function$
declare
  v_uid uuid := auth.uid();
  v_own_org_id uuid;
begin
  if v_uid is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
  if not private.is_super_admin() then raise exception 'CONCEPTEUR_ONLY'; end if;

  select o.id into v_own_org_id
  from public.organizations o
  where o.owner_user_id = v_uid
    and o.status in ('active','trial')
  order by o.created_at
  limit 1;

  return query select 'admin'::text,'ADMINISTRATEUR / ENTREPRISE'::text,'/business/dashboard'::text,
    v_own_org_id,(select o.name from public.organizations o where o.id=v_own_org_id),true,false;
  return query select 'prospecteur'::text,'PROSPECTEUR'::text,'/terrain/dashboard'::text,
    v_own_org_id,(select o.name from public.organizations o where o.id=v_own_org_id),true,false;
  return query select 'concepteur'::text,'CONCEPTEUR / CONTRÔLE'::text,'/hidden-concepteur-gate/dashboard'::text,
    null::uuid,null::text,true,false;
end;
$function$;

revoke all on function public.jdvcrm_get_concepteur_workspace_v1() from public, anon;
grant execute on function public.jdvcrm_get_concepteur_workspace_v1() to authenticated;