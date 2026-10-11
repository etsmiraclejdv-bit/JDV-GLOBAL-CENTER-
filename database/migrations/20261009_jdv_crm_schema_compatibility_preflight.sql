-- JDV GLOBAL CENTER / CRM integration preflight
-- Read-only diagnostic. Does not alter any schema, rows, policies, or functions.
-- Run before generating the additive migration so shared GLOBAL tables are never overwritten.

with expected(table_name) as (
  values
  ('prospecteurs'),('clients'),('prospects'),('articles'),('stocks'),
  ('prospecteur_stocks'),('stock_movements'),('sales'),('payment_schedules'),
  ('payments'),('daily_tokens'),('commissions'),('field_visits'),
  ('organization_settings'),('super_admin_modules'),('article_categories'),
  ('sale_items'),('suppliers'),('purchase_orders'),('purchase_order_items'),
  ('goods_receipts'),('goods_receipt_items'),('supplier_payments'),
  ('warehouses'),('warehouse_users'),('warehouse_inventory'),
  ('stock_transfers'),('stock_transfer_items'),('prospect_activities'),
  ('prospect_followups'),('prospect_status_history'),('prospect_assignments'),
  ('sales_returns'),('sales_return_items'),('payment_refunds'),
  ('user_permissions'),('subscription_limits'),('documents'),
  ('document_templates'),('document_sequences'),('call_center_tasks'),
  ('call_logs'),('follow_up_reminders'),('notification_preferences'),
  ('notification_events'),('serial_numbers'),('article_serial_assignments'),
  ('company_settings'),('user_settings'),('login_security_events'),
  ('audit_events'),('payment_provider_events'),('payment_provider_accounts'),
  ('payment_webhook_events'),('organization_personalization'),
  ('client_portfolios'),('subscription_events'),('prospecteur_warehouse_assignments'),
  ('prospecteur_supply_requests'),('prospecteur_supply_request_items'),
  ('prospecteur_stock_holdings'),('commission_types'),('commission_rules'),
  ('commission_adjustments'),('commission_payouts'),('intelligence_alerts'),
  ('user_activity_sessions'),('company_sectors'),('organization_applications'),
  ('organization_application_documents'),('organization_application_reviews'),
  ('organization_application_tokens'),('warehouse_managers'),('warehouse_tickets'),
  ('warehouse_ticket_notes'),('warehouse_supply_requests'),
  ('warehouse_supply_request_items'),('warehouse_day_closures'),
  ('organization_teams'),('organization_team_members'),('warehouse_subwarehouses'),
  ('warehouse_stock_daily_closures'),('warehouse_stock_daily_closure_lines'),
  ('warehouse_subwarehouse_daily_closures'),
  ('warehouse_subwarehouse_daily_closure_lines'),('ai_jdv_knowledge')
)
select e.table_name,
       case when t.table_name is null then 'MISSING' else 'EXISTS' end as global_public_status
from expected e
left join information_schema.tables t
  on t.table_schema='public' and t.table_name=e.table_name
order by 1;

-- Shared tables are intentionally not migrated by this preflight:
-- organizations, profiles, organization_members, super_admins,
-- notifications, audit_logs, permissions, role_permissions,
-- countries, currencies, languages, exchange_rates.
-- The standalone CRM and GLOBAL CENTER use different columns/role models on these tables.
