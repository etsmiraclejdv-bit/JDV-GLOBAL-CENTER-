-- Public SECURITY DEFINER trigger functions must not be callable as API endpoints.
revoke execute on function public.jdvcrm_record_prospect_status_history_v1() from public,anon,authenticated;
revoke execute on function public.jdvcrm_refresh_prospect_activity_v1() from public,anon,authenticated;
revoke execute on function public.jdvcrm_refresh_prospect_visit_v1() from public,anon,authenticated;

create or replace function public.jdvcrm_archive_old_prospects_v1(p_organization_id uuid)
returns integer language plpgsql security definer set search_path=public,private
as $$
declare v_count integer;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 if not(private.is_super_admin() or private.is_org_admin(p_organization_id)) then raise exception 'Accès refusé'; end if;
 update public.prospects set status='archived',archived_at=coalesce(archived_at,now()),updated_at=now()
 where organization_id=p_organization_id and archived_at is null and coalesce(last_contact_at,created_at)<=now()-interval '3 months' and coalesce(status,'') not in ('converted','archived','closed');
 get diagnostics v_count=row_count; return v_count;
end $$;
revoke execute on function public.jdvcrm_archive_old_prospects_v1(uuid) from public,anon;
grant execute on function public.jdvcrm_archive_old_prospects_v1(uuid) to authenticated;

create or replace function public.jdvcrm_archive_inactive_clients_v1(p_organization_id uuid)
returns integer language plpgsql security definer set search_path=public,private
as $$
declare v_count integer;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 if not(private.is_super_admin() or private.is_org_admin(p_organization_id)) then raise exception 'Accès refusé'; end if;
 update public.clients set status='archived',archived_at=coalesce(archived_at,now()),updated_at=now()
 where organization_id=p_organization_id and archived_at is null and coalesce(last_activity_at,created_at)<=now()-interval '3 months' and coalesce(status,'') not in ('archived','inactive');
 get diagnostics v_count=row_count; return v_count;
end $$;
revoke execute on function public.jdvcrm_archive_inactive_clients_v1(uuid) from public,anon;
grant execute on function public.jdvcrm_archive_inactive_clients_v1(uuid) to authenticated;
