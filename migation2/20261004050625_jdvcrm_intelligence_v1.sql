create table if not exists public.intelligence_alerts (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations(id) on delete cascade,
  user_id uuid references auth.users(id) on delete cascade,
  prospecteur_id uuid references public.prospecteurs(id) on delete set null,
  severity text not null default 'info' check (severity in ('critical','warning','opportunity','info')),
  category text not null check (category in ('follow_up','stock','return','productivity','sales','system')),
  title text not null,
  message text not null,
  recommendation text,
  entity_type text,
  entity_id uuid,
  fingerprint text not null,
  status text not null default 'open' check (status in ('open','acknowledged','resolved','dismissed')),
  metadata jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  acknowledged_at timestamptz,
  resolved_at timestamptz
);
create unique index if not exists intelligence_alerts_open_fingerprint_idx on public.intelligence_alerts(organization_id,fingerprint) where status in ('open','acknowledged');
create index if not exists intelligence_alerts_org_status_created_idx on public.intelligence_alerts(organization_id,status,created_at desc);
create index if not exists intelligence_alerts_user_status_idx on public.intelligence_alerts(user_id,status,created_at desc);
alter table public.intelligence_alerts enable row level security;
grant select, update on public.intelligence_alerts to authenticated;
drop policy if exists intelligence_alerts_select on public.intelligence_alerts;
create policy intelligence_alerts_select on public.intelligence_alerts for select to authenticated using (user_id=(select auth.uid()) or exists(select 1 from public.organization_members om where om.organization_id=intelligence_alerts.organization_id and om.user_id=(select auth.uid()) and om.status='active' and om.role in ('business_admin','manager','accountant')));
drop policy if exists intelligence_alerts_update on public.intelligence_alerts;
create policy intelligence_alerts_update on public.intelligence_alerts for update to authenticated using (user_id=(select auth.uid()) or exists(select 1 from public.organization_members om where om.organization_id=intelligence_alerts.organization_id and om.user_id=(select auth.uid()) and om.status='active' and om.role in ('business_admin','manager','accountant'))) with check (user_id=intelligence_alerts.user_id and organization_id=intelligence_alerts.organization_id);

create table if not exists public.user_activity_sessions (
 id uuid primary key default gen_random_uuid(),
 organization_id uuid not null references public.organizations(id) on delete cascade,
 user_id uuid not null references auth.users(id) on delete cascade,
 prospecteur_id uuid references public.prospecteurs(id) on delete set null,
 role text,
 started_at timestamptz not null default now(),
 last_seen_at timestamptz not null default now(),
 last_action_at timestamptz not null default now(),
 ended_at timestamptz,
 last_route text,
 action_count integer not null default 0 check(action_count>=0),
 metadata jsonb not null default '{}'::jsonb
);
create index if not exists user_activity_sessions_org_last_seen_idx on public.user_activity_sessions(organization_id,last_seen_at desc);
create index if not exists user_activity_sessions_user_started_idx on public.user_activity_sessions(user_id,started_at desc);
create index if not exists user_activity_sessions_prospecteur_last_seen_idx on public.user_activity_sessions(prospecteur_id,last_seen_at desc);
alter table public.user_activity_sessions enable row level security;
grant select,insert,update on public.user_activity_sessions to authenticated;
drop policy if exists activity_sessions_select on public.user_activity_sessions;
create policy activity_sessions_select on public.user_activity_sessions for select to authenticated using (user_id=(select auth.uid()) or exists(select 1 from public.organization_members om where om.organization_id=user_activity_sessions.organization_id and om.user_id=(select auth.uid()) and om.status='active' and om.role in ('business_admin','manager','accountant')));
drop policy if exists activity_sessions_insert on public.user_activity_sessions;
create policy activity_sessions_insert on public.user_activity_sessions for insert to authenticated with check (user_id=(select auth.uid()) and exists(select 1 from public.organization_members om where om.organization_id=user_activity_sessions.organization_id and om.user_id=(select auth.uid()) and om.status='active'));
drop policy if exists activity_sessions_update on public.user_activity_sessions;
create policy activity_sessions_update on public.user_activity_sessions for update to authenticated using(user_id=(select auth.uid())) with check(user_id=(select auth.uid()));

create or replace function public.jdvcrm_touch_activity_session_v1(p_session_id uuid,p_route text default null)
returns void language sql security invoker set search_path=public as $$
 update public.user_activity_sessions set last_seen_at=now(),last_action_at=now(),last_route=coalesce(p_route,last_route),action_count=action_count+1,ended_at=null where id=p_session_id and user_id=(select auth.uid());
$$;
grant execute on function public.jdvcrm_touch_activity_session_v1(uuid,text) to authenticated;

create or replace function public.jdvcrm_run_intelligence_scan_v1()
returns jsonb language plpgsql security definer set search_path=public as $$
declare
 v_followups integer:=0; v_returns integer:=0; v_stock integer:=0; v_productivity integer:=0; v_rows integer:=0;
begin
 insert into public.intelligence_alerts(organization_id,user_id,prospecteur_id,severity,category,title,message,recommendation,entity_type,entity_id,fingerprint,metadata)
 select p.organization_id,pr.user_id,p.prospecteur_id,case when coalesce(p.temperature,'warm')='hot' then 'critical' else 'warning' end,'follow_up','Relance recommandée : '||coalesce(nullif(trim(p.first_name||' '||p.last_name),''),'Prospect'),'Aucune relance enregistrée depuis '||floor(extract(epoch from(now()-coalesce(p.last_contact_at,p.created_at)))/86400)::int||' jours.','Contacter ce prospect aujourd''hui et programmer la prochaine relance.','prospect',p.id,'prospect-followup-'||p.id::text,jsonb_build_object('days_since_contact',floor(extract(epoch from(now()-coalesce(p.last_contact_at,p.created_at)))/86400)::int,'temperature',p.temperature)
 from public.prospects p join public.prospecteurs pr on pr.id=p.prospecteur_id where p.archived_at is null and p.status not in ('converted','lost','archived') and coalesce(p.last_contact_at,p.created_at)<=now()-interval '14 days'
 on conflict (organization_id,fingerprint) where status in ('open','acknowledged') do nothing;
 get diagnostics v_rows=row_count; v_followups:=v_followups+v_rows;
 insert into public.intelligence_alerts(organization_id,user_id,prospecteur_id,severity,category,title,message,recommendation,entity_type,entity_id,fingerprint,metadata)
 select c.organization_id,pr.user_id,c.prospecteur_id,case when coalesce(c.temperature,'warm')='hot' then 'critical' else 'warning' end,'follow_up','Client à relancer : '||coalesce(nullif(trim(c.first_name||' '||c.last_name),''),'Client'),'Dernier contact il y a '||floor(extract(epoch from(now()-coalesce(c.last_contact_at,c.last_activity_at,c.created_at)))/86400)::int||' jours.','Contacter le client et enregistrer le résultat de la relance.','client',c.id,'client-followup-'||c.id::text,jsonb_build_object('days_since_contact',floor(extract(epoch from(now()-coalesce(c.last_contact_at,c.last_activity_at,c.created_at)))/86400)::int,'temperature',c.temperature)
 from public.clients c join public.prospecteurs pr on pr.id=c.prospecteur_id where c.archived_at is null and coalesce(c.last_contact_at,c.last_activity_at,c.created_at)<=now()-interval '14 days'
 on conflict (organization_id,fingerprint) where status in ('open','acknowledged') do nothing;
 get diagnostics v_rows=row_count; v_followups:=v_followups+v_rows;
 insert into public.intelligence_alerts(organization_id,user_id,prospecteur_id,severity,category,title,message,recommendation,entity_type,entity_id,fingerprint,metadata)
 select h.organization_id,pr.user_id,h.prospecteur_id,case when now()>=h.hard_due_at then 'critical' else 'warning' end,'return',case when now()>=h.hard_due_at then 'Retour J+20 dépassé' else 'Retour J+10 à effectuer' end,'Marchandise non vendue : '||h.remaining_quantity||' unité(s) encore détenue(s) par le prospecteur.','Demander le retour à l''entrepôt avant toute nouvelle attribution.','prospecteur_stock_holding',h.id,'holding-return-'||h.id::text,jsonb_build_object('remaining_quantity',h.remaining_quantity,'return_due_at',h.return_due_at,'hard_due_at',h.hard_due_at)
 from public.prospecteur_stock_holdings h join public.prospecteurs pr on pr.id=h.prospecteur_id where h.remaining_quantity>0 and h.status in('active','overdue') and now()>=h.return_due_at
 on conflict (organization_id,fingerprint) where status in ('open','acknowledged') do nothing;
 get diagnostics v_rows=row_count; v_returns:=v_rows;
 insert into public.intelligence_alerts(organization_id,severity,category,title,message,recommendation,entity_type,entity_id,fingerprint,metadata)
 select s.organization_id,'warning','stock','Stock faible : '||coalesce(a.name,'Article'),'Stock disponible : '||greatest(s.quantity-s.reserved_quantity,0)||', seuil minimum : '||s.minimum_quantity||'.','Préparer un réapprovisionnement ou vérifier les commandes en cours.','stock',s.id,'stock-low-'||s.id::text,jsonb_build_object('available',greatest(s.quantity-s.reserved_quantity,0),'minimum',s.minimum_quantity)
 from public.stocks s join public.articles a on a.id=s.article_id where greatest(s.quantity-s.reserved_quantity,0)<=s.minimum_quantity
 on conflict (organization_id,fingerprint) where status in ('open','acknowledged') do nothing;
 get diagnostics v_rows=row_count; v_stock:=v_rows;
 insert into public.intelligence_alerts(organization_id,user_id,prospecteur_id,severity,category,title,message,recommendation,entity_type,entity_id,fingerprint,metadata)
 select p.organization_id,p.user_id,p.id,case when coalesce(max(s.last_seen_at),p.created_at)<=now()-interval '7 days' then 'critical' else 'warning' end,'productivity','Activité faible : '||trim(p.first_name||' '||p.last_name),'Aucune activité de connexion enregistrée depuis '||floor(extract(epoch from(now()-coalesce(max(s.last_seen_at),p.created_at)))/86400)::int||' jour(s).','Vérifier l''activité commerciale, les relances et les visites terrain.','prospecteur',p.id,'prospecteur-inactive-'||p.id::text,jsonb_build_object('last_seen_at',coalesce(max(s.last_seen_at),p.created_at))
 from public.prospecteurs p left join public.user_activity_sessions s on s.prospecteur_id=p.id where p.status='active' group by p.id,p.organization_id,p.user_id,p.first_name,p.last_name,p.created_at having coalesce(max(s.last_seen_at),p.created_at)<=now()-interval '3 days'
 on conflict (organization_id,fingerprint) where status in ('open','acknowledged') do nothing;
 get diagnostics v_rows=row_count; v_productivity:=v_rows;
 update public.intelligence_alerts ia set status='resolved',resolved_at=now() where ia.status in('open','acknowledged') and ia.category='follow_up' and ((ia.entity_type='prospect' and exists(select 1 from public.prospects p where p.id=ia.entity_id and coalesce(p.last_contact_at,p.created_at)>now()-interval '14 days')) or (ia.entity_type='client' and exists(select 1 from public.clients c where c.id=ia.entity_id and coalesce(c.last_contact_at,c.last_activity_at,c.created_at)>now()-interval '14 days')));
 update public.prospecteur_stock_holdings set status='overdue',updated_at=now() where status='active' and remaining_quantity>0 and now()>=return_due_at;
 return jsonb_build_object('follow_up_alerts',v_followups,'return_alerts',v_returns,'stock_alerts',v_stock,'productivity_alerts',v_productivity);
end;
$$;
revoke all on function public.jdvcrm_run_intelligence_scan_v1() from public,anon,authenticated;
grant execute on function public.jdvcrm_run_intelligence_scan_v1() to service_role;
