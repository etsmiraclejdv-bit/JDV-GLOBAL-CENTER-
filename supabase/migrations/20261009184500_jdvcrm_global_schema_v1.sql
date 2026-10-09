-- Additive JDV CRM schema for JDV GLOBAL CENTER.
-- Shared GLOBAL tables are deliberately excluded because their column/role models differ from standalone CRM.
-- This migration is idempotent for tables, constraints, indexes and named RLS policies.


drop policy if exists jdv_global_crm_prospects_select on public.prospects;
create policy jdv_global_crm_prospects_select on public.prospects for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospects.prospecteur_id and p.organization_id=prospects.organization_id and p.user_id=auth.uid()) or exists(select 1 from public.client_portfolios cp where cp.id=prospects.portfolio_id and cp.owner_user_id=auth.uid() and cp.organization_id=prospects.organization_id));
drop policy if exists jdv_global_crm_clients_select on public.clients;
create policy jdv_global_crm_clients_select on public.clients for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=clients.prospecteur_id and p.organization_id=clients.organization_id and p.user_id=auth.uid()) or exists(select 1 from public.client_portfolios cp where cp.id=clients.portfolio_id and cp.owner_user_id=auth.uid() and cp.organization_id=clients.organization_id));
drop policy if exists jdv_global_crm_portfolios_select on public.client_portfolios;
create policy jdv_global_crm_portfolios_select on public.client_portfolios for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or owner_user_id=auth.uid());
drop policy if exists jdv_global_crm_prospecteurs_select on public.prospecteurs;
create policy jdv_global_crm_prospecteurs_select on public.prospecteurs for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or user_id=auth.uid());
drop policy if exists jdv_global_crm_field_visits_select on public.field_visits;
create policy jdv_global_crm_field_visits_select on public.field_visits for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=field_visits.prospecteur_id and p.organization_id=field_visits.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_prospect_activities_select on public.prospect_activities;
create policy jdv_global_crm_prospect_activities_select on public.prospect_activities for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospect_activities.prospecteur_id and p.organization_id=prospect_activities.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_sales_select on public.sales;
create policy jdv_global_crm_sales_select on public.sales for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=sales.prospecteur_id and p.organization_id=sales.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_sale_items_select on public.sale_items;
create policy jdv_global_crm_sale_items_select on public.sale_items for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.sales s join public.prospecteurs p on p.id=s.prospecteur_id where s.id=sale_items.sale_id and s.organization_id=sale_items.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_payments_select on public.payments;
create policy jdv_global_crm_payments_select on public.payments for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=payments.prospecteur_id and p.organization_id=payments.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_payment_schedules_select on public.payment_schedules;
create policy jdv_global_crm_payment_schedules_select on public.payment_schedules for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.sales s join public.prospecteurs p on p.id=s.prospecteur_id where s.id=payment_schedules.sale_id and s.organization_id=payment_schedules.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_commissions_select on public.commissions;
create policy jdv_global_crm_commissions_select on public.commissions for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=commissions.prospecteur_id and p.organization_id=commissions.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_followups_select on public.prospect_followups;
create policy jdv_global_crm_followups_select on public.prospect_followups for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospect_followups.prospecteur_id and p.organization_id=prospect_followups.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_assignments_select on public.prospect_assignments;
create policy jdv_global_crm_assignments_select on public.prospect_assignments for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospect_assignments.prospecteur_id and p.organization_id=prospect_assignments.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_status_history_select on public.prospect_status_history;
create policy jdv_global_crm_status_history_select on public.prospect_status_history for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospects pr join public.prospecteurs p on p.id=pr.prospecteur_id where pr.id=prospect_status_history.prospect_id and pr.organization_id=prospect_status_history.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_call_tasks_select on public.call_center_tasks;
create policy jdv_global_crm_call_tasks_select on public.call_center_tasks for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or assigned_to=auth.uid() or exists(select 1 from public.prospecteurs p where p.id=call_center_tasks.prospecteur_id and p.organization_id=call_center_tasks.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_call_logs_select on public.call_logs;
create policy jdv_global_crm_call_logs_select on public.call_logs for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=call_logs.prospecteur_id and p.organization_id=call_logs.organization_id and p.user_id=auth.uid()));
