-- Indexes for operational portfolio and follow-up queries
create index if not exists ix_jdvcrm_clients_org_prospecteur on public.clients(organization_id,prospecteur_id) where archived_at is null;
create index if not exists ix_jdvcrm_prospects_org_prospecteur on public.prospects(organization_id,prospecteur_id) where archived_at is null;
create index if not exists ix_jdvcrm_prospects_followup on public.prospects(organization_id,next_follow_up_at) where archived_at is null;
create index if not exists ix_jdvcrm_prospects_contact on public.prospects(organization_id,last_contact_at) where archived_at is null;
create index if not exists ix_jdvcrm_prospect_activities_portfolio on public.prospect_activities(organization_id,prospect_id,activity_date desc);
create index if not exists ix_jdvcrm_prospect_followups_due on public.prospect_followups(organization_id,scheduled_at) where status='pending';
create index if not exists ix_jdvcrm_prospect_assignments_active on public.prospect_assignments(organization_id,prospect_id) where active=true;
create index if not exists ix_jdvcrm_status_history_prospect on public.prospect_status_history(organization_id,prospect_id,created_at desc);
create index if not exists ix_jdvcrm_field_visits_prospecteur_date on public.field_visits(organization_id,prospecteur_id,visit_date desc);

-- Supporting tables must be usable by admins and the assigned prospecteur, not only SUPER ADMIN.
alter table public.prospect_activities enable row level security;
alter table public.prospect_followups enable row level security;
alter table public.prospect_status_history enable row level security;
alter table public.prospect_assignments enable row level security;
alter table public.field_visits enable row level security;
alter table public.follow_up_reminders enable row level security;

drop policy if exists super_admin_full_access on public.prospect_activities;
drop policy if exists super_admin_full_access on public.prospect_followups;
drop policy if exists super_admin_full_access on public.prospect_status_history;
drop policy if exists super_admin_full_access on public.prospect_assignments;
drop policy if exists super_admin_full_access on public.follow_up_reminders;

create policy prospect_activities_super_admin on public.prospect_activities for all to authenticated using (private.is_super_admin()) with check (private.is_super_admin());
create policy prospect_activities_org_admin on public.prospect_activities for all to authenticated using (private.is_org_admin(organization_id)) with check (private.is_org_admin(organization_id));
create policy prospect_activities_prospecteur on public.prospect_activities for select to authenticated using (private.is_prospecteur(organization_id) and prospecteur_id in (select p.id from public.prospecteurs p where p.user_id=(select auth.uid()) and p.organization_id=prospect_activities.organization_id and p.status='active'));
create policy prospect_activities_prospecteur_insert on public.prospect_activities for insert to authenticated with check (private.is_prospecteur(organization_id) and prospecteur_id in (select p.id from public.prospecteurs p where p.user_id=(select auth.uid()) and p.organization_id=prospect_activities.organization_id and p.status='active'));

create policy prospect_followups_super_admin on public.prospect_followups for all to authenticated using (private.is_super_admin()) with check (private.is_super_admin());
create policy prospect_followups_org_admin on public.prospect_followups for all to authenticated using (private.is_org_admin(organization_id)) with check (private.is_org_admin(organization_id));
create policy prospect_followups_prospecteur on public.prospect_followups for all to authenticated using (private.is_prospecteur(organization_id) and prospecteur_id in (select p.id from public.prospecteurs p where p.user_id=(select auth.uid()) and p.organization_id=prospect_followups.organization_id and p.status='active')) with check (private.is_prospecteur(organization_id) and prospecteur_id in (select p.id from public.prospecteurs p where p.user_id=(select auth.uid()) and p.organization_id=prospect_followups.organization_id and p.status='active'));

create policy prospect_status_history_super_admin on public.prospect_status_history for all to authenticated using (private.is_super_admin()) with check (private.is_super_admin());
create policy prospect_status_history_org_admin on public.prospect_status_history for all to authenticated using (private.is_org_admin(organization_id)) with check (private.is_org_admin(organization_id));
create policy prospect_status_history_prospecteur on public.prospect_status_history for select to authenticated using (private.is_prospecteur(organization_id) and prospect_id in (select p.id from public.prospects p join public.prospecteurs pr on pr.id=p.prospecteur_id where p.organization_id=prospect_status_history.organization_id and pr.user_id=(select auth.uid()) and pr.status='active'));

create policy prospect_assignments_super_admin on public.prospect_assignments for all to authenticated using (private.is_super_admin()) with check (private.is_super_admin());
create policy prospect_assignments_org_admin on public.prospect_assignments for all to authenticated using (private.is_org_admin(organization_id)) with check (private.is_org_admin(organization_id));
create policy prospect_assignments_prospecteur on public.prospect_assignments for select to authenticated using (private.is_prospecteur(organization_id) and prospecteur_id in (select p.id from public.prospecteurs p where p.user_id=(select auth.uid()) and p.organization_id=prospect_assignments.organization_id and p.status='active'));

create policy follow_up_reminders_super_admin on public.follow_up_reminders for all to authenticated using (private.is_super_admin()) with check (private.is_super_admin());
create policy follow_up_reminders_org_admin on public.follow_up_reminders for all to authenticated using (private.is_org_admin(organization_id)) with check (private.is_org_admin(organization_id));
create policy follow_up_reminders_prospecteur on public.follow_up_reminders for all to authenticated using (private.is_prospecteur(organization_id) and ((user_id=(select auth.uid())) or prospect_id in (select p.id from public.prospects p join public.prospecteurs pr on pr.id=p.prospecteur_id where p.organization_id=follow_up_reminders.organization_id and pr.user_id=(select auth.uid()) and pr.status='active'))) with check (private.is_prospecteur(organization_id) and ((user_id=(select auth.uid())) or prospect_id in (select p.id from public.prospects p join public.prospecteurs pr on pr.id=p.prospecteur_id where p.organization_id=follow_up_reminders.organization_id and pr.user_id=(select auth.uid()) and pr.status='active')));

-- Field visits: restrict prospecteurs to their own visits and enforce reference ownership.
drop policy if exists field_visits_insert on public.field_visits;
drop policy if exists field_visits_select on public.field_visits;
create policy field_visits_super_admin on public.field_visits for all to authenticated using (private.is_super_admin()) with check (private.is_super_admin());
create policy field_visits_org_admin on public.field_visits for all to authenticated using (private.is_org_admin(organization_id)) with check (private.is_org_admin(organization_id));
create policy field_visits_prospecteur_select on public.field_visits for select to authenticated using (private.is_prospecteur(organization_id) and prospecteur_id in (select p.id from public.prospecteurs p where p.user_id=(select auth.uid()) and p.organization_id=field_visits.organization_id and p.status='active'));
create policy field_visits_prospecteur_insert on public.field_visits for insert to authenticated with check (private.is_prospecteur(organization_id) and prospecteur_id in (select p.id from public.prospecteurs p where p.user_id=(select auth.uid()) and p.organization_id=field_visits.organization_id and p.status='active'));

-- Consolidate duplicate assignment audit triggers: keep the richer version only.
drop trigger if exists trg_jdv_audit_prospect_assignment on public.prospects;

-- Automatic status history.
create or replace function public.jdvcrm_record_prospect_status_history_v1()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
 if tg_op='UPDATE' and old.status is distinct from new.status then
   insert into public.prospect_status_history(organization_id,prospect_id,old_status,new_status,changed_by,reason)
   values(new.organization_id,new.id,old.status,new.status,auth.uid(),null);
 end if;
 return new;
end $$;
drop trigger if exists trg_jdvcrm_record_prospect_status_history on public.prospects;
create trigger trg_jdvcrm_record_prospect_status_history after update of status on public.prospects for each row execute function public.jdvcrm_record_prospect_status_history_v1();

-- Activity/visit automatically refresh the prospect contact date and counters.
create or replace function public.jdvcrm_refresh_prospect_activity_v1()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
 if new.prospect_id is not null then
   update public.prospects set last_contact_at=greatest(coalesce(last_contact_at,'epoch'::timestamptz),coalesce(new.activity_date,now())), last_follow_up_at=greatest(coalesce(last_follow_up_at,'epoch'::timestamptz),coalesce(new.activity_date,now())), next_follow_up_at=coalesce(new.next_follow_up_at,next_follow_up_at), updated_at=now() where id=new.prospect_id and organization_id=new.organization_id;
 end if;
 return new;
end $$;
drop trigger if exists trg_jdvcrm_refresh_prospect_activity on public.prospect_activities;
create trigger trg_jdvcrm_refresh_prospect_activity after insert on public.prospect_activities for each row execute function public.jdvcrm_refresh_prospect_activity_v1();

create or replace function public.jdvcrm_refresh_prospect_visit_v1()
returns trigger language plpgsql security definer set search_path=public
as $$
begin
 if new.prospect_id is not null then
   update public.prospects set visit_count=visit_count+1,last_contact_at=greatest(coalesce(last_contact_at,'epoch'::timestamptz),coalesce(new.visit_date,now())),next_follow_up_at=coalesce(new.next_follow_up_at,next_follow_up_at),updated_at=now() where id=new.prospect_id and organization_id=new.organization_id;
 end if;
 if new.client_id is not null then
   update public.clients set last_contact_at=greatest(coalesce(last_contact_at,'epoch'::timestamptz),coalesce(new.visit_date,now())),last_activity_at=greatest(coalesce(last_activity_at,'epoch'::timestamptz),coalesce(new.visit_date,now())),updated_at=now() where id=new.client_id and organization_id=new.organization_id;
 end if;
 return new;
end $$;
drop trigger if exists trg_jdvcrm_refresh_prospect_visit on public.field_visits;
create trigger trg_jdvcrm_refresh_prospect_visit after insert on public.field_visits for each row execute function public.jdvcrm_refresh_prospect_visit_v1();

-- Safe conversion prospect -> client, preserving assignment.
create or replace function public.jdvcrm_convert_prospect_to_client_v1(p_prospect_id uuid)
returns uuid language plpgsql security definer set search_path=public
as $$
declare pr public.prospects%rowtype; c_id uuid;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 select * into pr from public.prospects where id=p_prospect_id for update;
 if not found then raise exception 'Prospect introuvable'; end if;
 if not(private.is_super_admin() or private.is_org_admin(pr.organization_id) or (private.is_prospecteur(pr.organization_id) and exists(select 1 from public.prospecteurs p where p.id=pr.prospecteur_id and p.user_id=auth.uid() and p.status='active'))) then raise exception 'Accès refusé'; end if;
 if pr.client_id is not null then return pr.client_id; end if;
 insert into public.clients(organization_id,prospecteur_id,first_name,last_name,phone,whatsapp,address,city,status,temperature,notes,last_contact_at,last_activity_at)
 values(pr.organization_id,pr.prospecteur_id,pr.first_name,pr.last_name,pr.phone,pr.whatsapp,pr.address,pr.city,'active',pr.temperature,pr.notes,coalesce(pr.last_contact_at,now()),now()) returning id into c_id;
 update public.prospects set client_id=c_id,status='converted',updated_at=now() where id=pr.id;
 return c_id;
end $$;
revoke execute on function public.jdvcrm_convert_prospect_to_client_v1(uuid) from public,anon;
grant execute on function public.jdvcrm_convert_prospect_to_client_v1(uuid) to authenticated;

-- Restrict archival helpers to authenticated admins/SUPER ADMIN when called manually.
revoke execute on function public.jdvcrm_archive_old_prospects(uuid) from public,anon,authenticated;
revoke execute on function public.jdvcrm_archive_inactive_clients(uuid) from public,anon,authenticated;
