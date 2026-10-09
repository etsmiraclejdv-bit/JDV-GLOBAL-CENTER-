create or replace function public.jdvcrm_assign_prospecteur_warehouse_v1(
  p_organization_id uuid,p_prospecteur_id uuid,p_warehouse_id uuid,
  p_department text default null,p_city text default null,p_work_zone text default null
) returns jsonb language plpgsql security definer set search_path=public,private
as $$
declare v_uid uuid:=auth.uid(); v_porg uuid; v_worg uuid; v_id uuid;
begin
  if v_uid is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
  if not private.is_super_admin() and not private.is_org_admin(p_organization_id) then raise exception 'ACCESS_DENIED'; end if;
  select organization_id into v_porg from public.prospecteurs where id=p_prospecteur_id and status='active';
  if v_porg is null or v_porg<>p_organization_id then raise exception 'PROSPECTEUR_NOT_IN_ORGANIZATION'; end if;
  select organization_id into v_worg from public.warehouses where id=p_warehouse_id and active=true;
  if v_worg is null or v_worg<>p_organization_id then raise exception 'WAREHOUSE_NOT_IN_ORGANIZATION'; end if;
  update public.prospecteur_warehouse_assignments
    set active=false,is_primary=false,unassigned_at=now()
    where organization_id=p_organization_id and prospecteur_id=p_prospecteur_id and active=true;
  insert into public.prospecteur_warehouse_assignments(
    organization_id,prospecteur_id,warehouse_id,department,city,work_zone,is_primary,active
  ) values(p_organization_id,p_prospecteur_id,p_warehouse_id,p_department,p_city,p_work_zone,true,true)
  returning id into v_id;
  return jsonb_build_object('assignment_id',v_id,'prospecteur_id',p_prospecteur_id,'warehouse_id',p_warehouse_id);
end $$;
revoke all on function public.jdvcrm_assign_prospecteur_warehouse_v1(uuid,uuid,uuid,text,text,text) from public,anon,authenticated;
grant execute on function public.jdvcrm_assign_prospecteur_warehouse_v1(uuid,uuid,uuid,text,text,text) to authenticated;