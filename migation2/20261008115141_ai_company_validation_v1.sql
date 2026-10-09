-- Validation d'entreprise par JDV IA (sans e-mail, sans intervention du concepteur)

-- 1. Résultat de l'étape 1 (identité) + empreinte de l'identité
alter table public.organization_applications
  add column if not exists ai_identity_status text not null default 'pending',
  add column if not exists ai_identity_reasons jsonb not null default '[]'::jsonb,
  add column if not exists ai_identity_attempts integer not null default 0,
  add column if not exists ai_identity_checked_at timestamptz;

alter table public.organization_applications
  drop constraint if exists organization_applications_ai_identity_status_chk;
alter table public.organization_applications
  add constraint organization_applications_ai_identity_status_chk
  check (ai_identity_status in ('pending','approved','refused'));

alter table public.organization_applications
  add column if not exists identity_fingerprint text generated always as (md5(
    coalesce(lower(btrim(company_name)),'')||'|'||coalesce(lower(btrim(legal_name)),'')||'|'||
    coalesce(lower(btrim(legal_form)),'')||'|'||coalesce(company_nature,'')||'|'||
    coalesce(lower(btrim(country)),'')||'|'||coalesce(lower(btrim(registration_number)),'')||'|'||
    coalesce(lower(btrim(tax_number)),'')||'|'||coalesce(lower(btrim(representative_first_name)),'')||'|'||
    coalesce(lower(btrim(representative_last_name)),'')||'|'||coalesce(primary_sector_id::text,'')
  )) stored;

-- 2. Verrou : un candidat ne peut pas se valider lui-même
create or replace function public.jdvcrm_guard_application_write_v1()
returns trigger language plpgsql set search_path = public, private as $$
begin
  if current_user in ('authenticated','anon') and not coalesce(private.is_super_admin(), false) then
    if tg_op = 'INSERT' then
      if NEW.status not in ('draft','submitted') then
        raise exception 'PROTECTED_STATUS' using errcode = '42501';
      end if;
      NEW.ai_identity_status := 'pending';
      NEW.ai_identity_reasons := '[]'::jsonb;
      NEW.ai_identity_attempts := 0;
      NEW.ai_identity_checked_at := null;
      NEW.reviewed_by := null; NEW.reviewed_at := null; NEW.approved_at := null;
      NEW.email_verified_at := null; NEW.activated_at := null;
    else
      if NEW.applicant_user_id is distinct from OLD.applicant_user_id
         or NEW.reviewed_by is distinct from OLD.reviewed_by
         or NEW.reviewed_at is distinct from OLD.reviewed_at
         or NEW.approved_at is distinct from OLD.approved_at
         or NEW.email_verified_at is distinct from OLD.email_verified_at
         or NEW.activated_at is distinct from OLD.activated_at
         or NEW.ai_identity_status is distinct from OLD.ai_identity_status
         or NEW.ai_identity_reasons is distinct from OLD.ai_identity_reasons
         or NEW.ai_identity_attempts is distinct from OLD.ai_identity_attempts
         or NEW.ai_identity_checked_at is distinct from OLD.ai_identity_checked_at then
        raise exception 'PROTECTED_COLUMNS' using errcode = '42501';
      end if;
      if NEW.status is distinct from OLD.status and NEW.status in ('approved_pending_email','email_verified','activated') then
        raise exception 'PROTECTED_STATUS' using errcode = '42501';
      end if;
      -- Si l'identité change, l'étape 1 est à refaire
      if (NEW.company_name, NEW.legal_name, NEW.legal_form, NEW.company_nature, NEW.country, NEW.registration_number,
          NEW.tax_number, NEW.representative_first_name, NEW.representative_last_name, NEW.primary_sector_id)
         is distinct from
         (OLD.company_name, OLD.legal_name, OLD.legal_form, OLD.company_nature, OLD.country, OLD.registration_number,
          OLD.tax_number, OLD.representative_first_name, OLD.representative_last_name, OLD.primary_sector_id) then
        NEW.ai_identity_status := 'pending';
        NEW.ai_identity_reasons := '[]'::jsonb;
      end if;
    end if;
  end if;
  return NEW;
end $$;

drop trigger if exists jdvcrm_guard_application_write on public.organization_applications;
create trigger jdvcrm_guard_application_write
  before insert or update on public.organization_applications
  for each row execute function public.jdvcrm_guard_application_write_v1();

-- 3. Verrou documents : le statut n'est écrit que par JDV IA (service)
create or replace function public.jdvcrm_guard_application_document_v1()
returns trigger language plpgsql set search_path = public, private as $$
declare v_count integer;
begin
  if current_user in ('authenticated','anon') and not coalesce(private.is_super_admin(), false) then
    select count(*) into v_count from public.organization_application_documents d where d.application_id = NEW.application_id;
    if v_count >= 24 then raise exception 'TOO_MANY_DOCUMENTS'; end if;
    NEW.status := 'pending';
    NEW.analysis_result := null;
    NEW.rejection_reason := null;
  end if;
  return NEW;
end $$;

drop trigger if exists jdvcrm_guard_application_document on public.organization_application_documents;
create trigger jdvcrm_guard_application_document
  before insert on public.organization_application_documents
  for each row execute function public.jdvcrm_guard_application_document_v1();

-- 4. État de la validation (écran du candidat : flèches vertes / rouges)
create or replace function public.jdvcrm_my_company_validation_v1(p_application_id uuid)
returns jsonb language plpgsql security definer set search_path = public, private as $$
declare
  a public.organization_applications%rowtype;
  req text[];
  docs jsonb;
  v_docs_ok boolean;
begin
  if auth.uid() is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
  select * into a from public.organization_applications x where x.id = p_application_id and x.applicant_user_id = auth.uid();
  if not found then raise exception 'APPLICATION_NOT_FOUND'; end if;

  req := case
    when a.company_nature = 'sole_proprietorship' then array['identity','rccm','ifu','address_proof']
    when a.company_nature in ('company','cooperative') then array['identity','rccm','ifu','statutes','address_proof']
    else array['identity','statutes','address_proof']
  end;

  select coalesce(jsonb_agg(jsonb_build_object(
      'type', r.t,
      'status', case
          when d.id is null then 'missing'
          when d.status = 'verified' and coalesce(d.analysis_result->>'fingerprint','') <> coalesce(a.identity_fingerprint,'') then 'stale'
          else d.status end,
      'reason', case
          when d.id is not null and d.status = 'verified' and coalesce(d.analysis_result->>'fingerprint','') <> coalesce(a.identity_fingerprint,'')
            then 'L''identité de l''entreprise a changé : renvoyez ce document.'
          else d.rejection_reason end,
      'document_id', d.id,
      'name', d.document_name
    ) order by r.ord), '[]'::jsonb)
  into docs
  from unnest(req) with ordinality as r(t, ord)
  left join lateral (
    select x.* from public.organization_application_documents x
    where x.application_id = a.id and x.document_type = r.t
    order by x.created_at desc limit 1
  ) d on true;

  select coalesce(bool_and(e->>'status' = 'verified'), false) into v_docs_ok from jsonb_array_elements(docs) e;

  return jsonb_build_object(
    'application_status', a.status,
    'identity', jsonb_build_object('status', a.ai_identity_status, 'reasons', a.ai_identity_reasons, 'attempts', a.ai_identity_attempts),
    'required', to_jsonb(req),
    'documents', docs,
    'can_validate', (a.ai_identity_status = 'approved' and v_docs_ok)
  );
end $$;

-- 5. Étape 3 : « Valider mon entreprise »
create or replace function public.jdvcrm_validate_my_company_v1(p_application_id uuid)
returns table(organization_id uuid, status text, trial_expires_at timestamptz)
language plpgsql security definer set search_path = public, private as $$
#variable_conflict use_column
declare v jsonb; st text;
begin
  if auth.uid() is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
  select a.status into st from public.organization_applications a
  where a.id = p_application_id and a.applicant_user_id = auth.uid();
  if st is null then raise exception 'APPLICATION_NOT_FOUND'; end if;

  if st not in ('activated','approved_pending_email') then
    v := public.jdvcrm_my_company_validation_v1(p_application_id);
    if coalesce((v->>'can_validate')::boolean, false) is not true then
      raise exception 'VALIDATION_INCOMPLETE';
    end if;
    update public.organization_applications a
       set status = 'approved_pending_email', approved_at = now(), reviewed_at = now(),
           review_notes = 'Validation automatique JDV IA', analysis_status = 'completed', updated_at = now()
     where a.id = p_application_id;
  end if;

  return query select f.organization_id, f.status, f.trial_expires_at
               from public.jdvcrm_finalize_company_application_v1(p_application_id) f;
end $$;

revoke all on function public.jdvcrm_my_company_validation_v1(uuid) from public, anon;
revoke all on function public.jdvcrm_validate_my_company_v1(uuid) from public, anon;
grant execute on function public.jdvcrm_my_company_validation_v1(uuid) to authenticated, service_role;
grant execute on function public.jdvcrm_validate_my_company_v1(uuid) to authenticated, service_role;