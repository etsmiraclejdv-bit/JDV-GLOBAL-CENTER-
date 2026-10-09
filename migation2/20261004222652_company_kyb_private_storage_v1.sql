-- JDV CRM private storage for company verification documents
insert into storage.buckets(id,name,public,file_size_limit,allowed_mime_types)
values('company-kyb-documents','company-kyb-documents',false,10485760,array['application/pdf','image/jpeg','image/png','image/webp'])
on conflict(id) do update set public=false,file_size_limit=10485760,allowed_mime_types=excluded.allowed_mime_types;
drop policy if exists "kyb_docs_owner_upload" on storage.objects;
create policy "kyb_docs_owner_upload" on storage.objects for insert to authenticated with check(bucket_id='company-kyb-documents' and (storage.foldername(name))[1]=(select auth.uid()::text) and exists(select 1 from public.organization_applications a where a.id=((storage.foldername(name))[2])::uuid and a.applicant_user_id=auth.uid()));
drop policy if exists "kyb_docs_owner_read" on storage.objects;
create policy "kyb_docs_owner_read" on storage.objects for select to authenticated using(bucket_id='company-kyb-documents' and ((storage.foldername(name))[1]=(select auth.uid()::text) or private.is_super_admin()));
drop policy if exists "kyb_docs_owner_delete" on storage.objects;
create policy "kyb_docs_owner_delete" on storage.objects for delete to authenticated using(bucket_id='company-kyb-documents' and (storage.foldername(name))[1]=(select auth.uid()::text));