-- Mode provisoire (sans IA) : contrôle humain des documents par le concepteur

create or replace function public.jdvcrm_get_documents_to_review_v1()
returns table(document_id uuid, application_id uuid, company_name text, document_type text, document_name text, storage_path text, created_at timestamptz)
language plpgsql security definer set search_path = public, private as $$
begin
  if not coalesce(private.is_super_admin(), false) then raise exception 'SUPER_ADMIN_REQUIRED'; end if;
  return query
    select d.id, d.application_id, a.company_name, d.document_type, d.document_name, d.storage_path, d.created_at
    from public.organization_application_documents d
    join public.organization_applications a on a.id = d.application_id
    where d.status = 'needs_review'
    order by d.created_at asc;
end $$;

create or replace function public.jdvcrm_review_application_document_v1(p_document_id uuid, p_decision text, p_reason text default null)
returns boolean language plpgsql security definer set search_path = public, private as $$
declare d public.organization_application_documents%rowtype; v_fp text;
begin
  if not coalesce(private.is_super_admin(), false) then raise exception 'SUPER_ADMIN_REQUIRED'; end if;
  if p_decision not in ('verified','rejected') then raise exception 'INVALID_DECISION'; end if;
  if p_decision = 'rejected' and coalesce(btrim(p_reason),'') = '' then raise exception 'REASON_REQUIRED'; end if;
  select * into d from public.organization_application_documents x where x.id = p_document_id for update;
  if not found then raise exception 'DOCUMENT_NOT_FOUND'; end if;
  select a.identity_fingerprint into v_fp from public.organization_applications a where a.id = d.application_id;
  update public.organization_application_documents x
     set status = p_decision,
         rejection_reason = case when p_decision = 'rejected' then btrim(p_reason) else null end,
         analysis_result = coalesce(x.analysis_result,'{}'::jsonb)
           || jsonb_build_object('fingerprint', v_fp, 'reviewed_by', auth.uid(), 'reviewed_at', now(), 'analyzer', 'manual'),
         updated_at = now()
   where x.id = p_document_id;
  return true;
end $$;

revoke all on function public.jdvcrm_get_documents_to_review_v1() from public, anon;
revoke all on function public.jdvcrm_review_application_document_v1(uuid, text, text) from public, anon;
grant execute on function public.jdvcrm_get_documents_to_review_v1() to authenticated, service_role;
grant execute on function public.jdvcrm_review_application_document_v1(uuid, text, text) to authenticated, service_role;