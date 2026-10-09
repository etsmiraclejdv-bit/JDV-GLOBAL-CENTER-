-- JDV CRM secure company application/KYB dossier and sector catalog
create table if not exists public.company_sectors (id uuid primary key default gen_random_uuid(),code text not null unique,name text not null,description text,icon text,active boolean not null default true,sort_order integer not null default 0,created_at timestamptz not null default now());
alter table public.company_sectors enable row level security;
drop policy if exists "company_sectors_public_read" on public.company_sectors;
create policy "company_sectors_public_read" on public.company_sectors for select to authenticated,anon using (active=true);
insert into public.company_sectors(code,name,icon,sort_order) values
('industry','Industrie & fabrication','Factory',10),('energy','Énergie & électricité','Zap',20),('construction','BTP & construction','Building2',30),('real_estate','Immobilier','Home',40),('commerce','Commerce & distribution','ShoppingCart',50),('transport','Transport & logistique','Truck',60),('agriculture','Agriculture','Wheat',70),('livestock','Élevage','PawPrint',80),('fishing','Pêche & aquaculture','Fish',90),('technology','Informatique & technologies','Cpu',100),('telecom','Télécommunications','Radio',110),('finance','Banque, finance & assurance','Landmark',120),('health','Santé & pharmacie','HeartPulse',130),('education','Éducation & formation','GraduationCap',140),('hospitality','Hôtellerie & restauration','Hotel',150),('tourism','Tourisme & voyages','Plane',160),('fashion','Mode & textile','Shirt',170),('beauty','Beauté & cosmétique','Sparkles',180),('food','Agroalimentaire','Utensils',190),('mining','Mines & carrières','Pickaxe',200),('environment','Environnement','Leaf',210),('renewable_energy','Énergies renouvelables','Sun',220),('chemistry','Chimie & laboratoire','FlaskConical',230),('legal','Services juridiques','Scale',240),('professional_services','Conseil & services professionnels','BriefcaseBusiness',250),('marketing','Communication & marketing','Megaphone',260),('arts','Arts, culture & création','Palette',270),('media','Médias & divertissement','Film',280),('public_sector','Administration & secteur public','Landmark',290),('ngo','ONG, associations & organisations','UsersRound',300),('research','Recherche & développement','Microscope',310),('services','Services aux entreprises et particuliers','Wrench',320),('ecommerce','E-commerce','Store',330),('maintenance','Maintenance & réparation','Settings',340),('water','Eau & assainissement','Droplets',350),('other','Autre secteur','MoreHorizontal',999)
on conflict(code) do update set name=excluded.name,icon=excluded.icon,sort_order=excluded.sort_order;

create table if not exists public.organization_applications (
id uuid primary key default gen_random_uuid(),applicant_user_id uuid not null references auth.users(id) on delete cascade,professional_email text not null,company_name text not null,legal_name text,legal_form text,company_nature text not null,legal_status text,primary_sector_id uuid references public.company_sectors(id),secondary_sector_ids uuid[] not null default '{}',country text not null,city text,address text,phone text,website text,registration_number text,tax_number text,representative_first_name text not null,representative_last_name text not null,representative_role text not null,representative_phone text,representative_email text not null,representative_birth_date date,representative_nationality text,ownership_count integer,associate_count integer,manager_count integer,people_count integer,company_size text,status text not null default 'draft',analysis_status text not null default 'pending',analysis_score numeric(5,2),analysis_result jsonb not null default '{}'::jsonb,review_notes text,reviewed_by uuid references auth.users(id),reviewed_at timestamptz,approved_at timestamptz,email_verified_at timestamptz,activated_at timestamptz,created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
constraint organization_applications_status_ck check(status in ('draft','submitted','analyzing','under_review','changes_requested','approved_pending_email','email_verified','rejected','activated')),
constraint organization_applications_analysis_ck check(analysis_status in ('pending','processing','completed','needs_review','failed')),
constraint organization_applications_size_ck check(company_size is null or company_size in ('micro','small','medium','large')),
constraint organization_applications_nature_ck check(company_nature in ('sole_proprietorship','company','association','cooperative','public_company','state_entity','ngo','other')));
alter table public.organization_applications enable row level security;

create table if not exists public.organization_application_documents (
id uuid primary key default gen_random_uuid(),application_id uuid not null references public.organization_applications(id) on delete cascade,document_type text not null,document_name text not null,storage_path text not null,mime_type text,file_size bigint,document_number text,issued_at date,expires_at date,status text not null default 'pending',analysis_result jsonb not null default '{}'::jsonb,rejection_reason text,uploaded_by uuid not null references auth.users(id),created_at timestamptz not null default now(),updated_at timestamptz not null default now(),
constraint organization_application_documents_status_ck check(status in ('pending','analyzing','verified','needs_review','rejected','expired')),
constraint organization_application_documents_type_ck check(document_type in ('identity','rccm','ifu','incorporation','statutes','mandate','address_proof','other')));
alter table public.organization_application_documents enable row level security;

create table if not exists public.organization_application_reviews (id uuid primary key default gen_random_uuid(),application_id uuid not null references public.organization_applications(id) on delete cascade,reviewer_user_id uuid not null references auth.users(id),decision text not null,notes text,automatic_analysis jsonb not null default '{}'::jsonb,created_at timestamptz not null default now(),constraint organization_application_reviews_decision_ck check(decision in ('approve','request_changes','reject')));
alter table public.organization_application_reviews enable row level security;

create table if not exists public.organization_application_tokens (id uuid primary key default gen_random_uuid(),application_id uuid not null references public.organization_applications(id) on delete cascade,token_hash text not null unique,purpose text not null default 'professional_email_confirmation',expires_at timestamptz not null,used_at timestamptz,created_at timestamptz not null default now(),constraint organization_application_tokens_purpose_ck check(purpose='professional_email_confirmation'));
alter table public.organization_application_tokens enable row level security;

create index if not exists idx_org_applications_applicant on public.organization_applications(applicant_user_id);
create index if not exists idx_org_applications_status on public.organization_applications(status);
create index if not exists idx_org_applications_sector on public.organization_applications(primary_sector_id);
create index if not exists idx_org_app_docs_application on public.organization_application_documents(application_id);

drop policy if exists "org_applications_owner_read" on public.organization_applications;
create policy "org_applications_owner_read" on public.organization_applications for select to authenticated using(applicant_user_id=auth.uid() or private.is_super_admin());
drop policy if exists "org_applications_owner_insert" on public.organization_applications;
create policy "org_applications_owner_insert" on public.organization_applications for insert to authenticated with check(applicant_user_id=auth.uid());
drop policy if exists "org_applications_owner_update" on public.organization_applications;
create policy "org_applications_owner_update" on public.organization_applications for update to authenticated using(applicant_user_id=auth.uid() or private.is_super_admin()) with check(applicant_user_id=auth.uid() or private.is_super_admin());
drop policy if exists "org_app_docs_owner_read" on public.organization_application_documents;
create policy "org_app_docs_owner_read" on public.organization_application_documents for select to authenticated using(uploaded_by=auth.uid() or private.is_super_admin());
drop policy if exists "org_app_docs_owner_insert" on public.organization_application_documents;
create policy "org_app_docs_owner_insert" on public.organization_application_documents for insert to authenticated with check(uploaded_by=auth.uid() and exists(select 1 from public.organization_applications a where a.id=application_id and a.applicant_user_id=auth.uid()));
drop policy if exists "org_app_reviews_superadmin_read" on public.organization_application_reviews;
create policy "org_app_reviews_superadmin_read" on public.organization_application_reviews for select to authenticated using(private.is_super_admin());
drop policy if exists "org_app_reviews_superadmin_insert" on public.organization_application_reviews;
create policy "org_app_reviews_superadmin_insert" on public.organization_application_reviews for insert to authenticated with check(private.is_super_admin());
drop policy if exists "org_app_tokens_superadmin_read" on public.organization_application_tokens;
create policy "org_app_tokens_superadmin_read" on public.organization_application_tokens for select to authenticated using(private.is_super_admin());

create or replace function public.jdvcrm_submit_company_application_v1(p_company_name text,p_legal_name text,p_legal_form text,p_company_nature text,p_legal_status text,p_primary_sector_id uuid,p_secondary_sector_ids uuid[],p_country text,p_city text,p_address text,p_phone text,p_website text,p_registration_number text,p_tax_number text,p_representative_first_name text,p_representative_last_name text,p_representative_role text,p_representative_phone text,p_representative_email text,p_representative_birth_date date,p_representative_nationality text,p_ownership_count integer,p_associate_count integer,p_manager_count integer,p_people_count integer,p_company_size text)
returns uuid language plpgsql security invoker set search_path=public,private as $$
declare v_id uuid;
begin
if auth.uid() is null then raise exception 'AUTHENTICATION_REQUIRED'; end if;
if lower(trim(coalesce(p_representative_email,'')))='' then raise exception 'PROFESSIONAL_EMAIL_REQUIRED'; end if;
insert into public.organization_applications(applicant_user_id,professional_email,company_name,legal_name,legal_form,company_nature,legal_status,primary_sector_id,secondary_sector_ids,country,city,address,phone,website,registration_number,tax_number,representative_first_name,representative_last_name,representative_role,representative_phone,representative_email,representative_birth_date,representative_nationality,ownership_count,associate_count,manager_count,people_count,company_size,status)
values(auth.uid(),lower(trim(p_representative_email)),trim(p_company_name),nullif(trim(p_legal_name),''),nullif(trim(p_legal_form),''),p_company_nature,nullif(trim(p_legal_status),''),p_primary_sector_id,coalesce(p_secondary_sector_ids,'{}'),trim(p_country),nullif(trim(p_city),''),nullif(trim(p_address),''),nullif(trim(p_phone),''),nullif(trim(p_website),''),nullif(trim(p_registration_number),''),nullif(trim(p_tax_number),''),trim(p_representative_first_name),trim(p_representative_last_name),trim(p_representative_role),nullif(trim(p_representative_phone),''),lower(trim(p_representative_email)),p_representative_birth_date,nullif(trim(p_representative_nationality),''),p_ownership_count,p_associate_count,p_manager_count,p_people_count,p_company_size,'submitted') returning id into v_id;
return v_id;
end $$;
revoke all on function public.jdvcrm_submit_company_application_v1(text,text,text,text,text,uuid,uuid[],text,text,text,text,text,text,text,text,text,text,text,text,date,text,integer,integer,integer,integer,text) from public,anon;
grant execute on function public.jdvcrm_submit_company_application_v1(text,text,text,text,text,uuid,uuid[],text,text,text,text,text,text,text,text,text,text,text,text,date,text,integer,integer,integer,integer,text) to authenticated;

create or replace function public.jdvcrm_get_pending_company_applications_v1()
returns table(application_id uuid,company_name text,legal_name text,professional_email text,company_nature text,legal_form text,legal_status text,sector_name text,country text,city text,company_size text,status text,analysis_status text,analysis_score numeric,created_at timestamptz)
language sql security definer set search_path=public,private as $$
select a.id,a.company_name,a.legal_name,a.professional_email,a.company_nature,a.legal_form,a.legal_status,s.name,a.country,a.city,a.company_size,a.status,a.analysis_status,a.analysis_score,a.created_at
from public.organization_applications a left join public.company_sectors s on s.id=a.primary_sector_id
where private.is_super_admin() and a.status in ('submitted','analyzing','under_review','changes_requested','approved_pending_email') order by a.created_at asc
$$;
revoke all on function public.jdvcrm_get_pending_company_applications_v1() from public,anon;
grant execute on function public.jdvcrm_get_pending_company_applications_v1() to authenticated;

create or replace function public.jdvcrm_platform_review_company_application_v1(p_application_id uuid,p_decision text,p_notes text default null)
returns boolean language plpgsql security definer set search_path=public,private as $$
begin
if not private.is_super_admin() then raise exception 'SUPER_ADMIN_REQUIRED'; end if;
if p_decision not in ('approve','request_changes','reject') then raise exception 'INVALID_DECISION'; end if;
insert into public.organization_application_reviews(application_id,reviewer_user_id,decision,notes,automatic_analysis)
select id,auth.uid(),p_decision,p_notes,analysis_result from public.organization_applications where id=p_application_id;
update public.organization_applications set status=case p_decision when 'approve' then 'approved_pending_email' when 'request_changes' then 'changes_requested' else 'rejected' end,reviewed_by=auth.uid(),reviewed_at=now(),approved_at=case when p_decision='approve' then now() else approved_at end,review_notes=p_notes,updated_at=now() where id=p_application_id;
return found;
end $$;
revoke all on function public.jdvcrm_platform_review_company_application_v1(uuid,text,text) from public,anon;
grant execute on function public.jdvcrm_platform_review_company_application_v1(uuid,text,text) to authenticated;
