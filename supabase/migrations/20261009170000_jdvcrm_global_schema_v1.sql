-- JDV GLOBAL CENTER: additive CRM schema.
-- Shared GLOBAL tables are excluded; their structures and role model remain unchanged.
-- Idempotent table, constraint, index and policy operations.

create table if not exists public.article_categories (
  id uuid default gen_random_uuid() not null,
  organization_id uuid,
  name text not null,
  code text,
  description text,
  active boolean default true not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.article_serial_assignments (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  serial_number_id uuid not null,
  article_id uuid not null,
  prospecteur_id uuid,
  warehouse_id uuid,
  assigned_at timestamp with time zone default now() not null,
  released_at timestamp with time zone,
  active boolean default true not null,
  created_by uuid
);

create table if not exists public.articles (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  code text not null,
  name text not null,
  description text,
  category text,
  unit text default 'unité'::text not null,
  fixed_price numeric(14,2) default 0 not null,
  cash_price numeric(14,2) default 0 not null,
  credit_price numeric(14,2) default 0 not null,
  minimum_deposit numeric(14,2) default 0 not null,
  default_payment_amount numeric(14,2) default 0 not null,
  active boolean default true not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.audit_events (
  id uuid default gen_random_uuid() not null,
  organization_id uuid,
  user_id uuid,
  action text not null,
  entity_type text,
  entity_id uuid,
  old_data jsonb,
  new_data jsonb,
  ip_address inet,
  user_agent text,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.call_center_tasks (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  prospect_id uuid,
  client_id uuid,
  prospecteur_id uuid,
  assigned_to uuid,
  task_type text default 'follow_up'::text not null,
  priority text default 'normal'::text not null,
  due_at timestamp with time zone,
  status text default 'pending'::text not null,
  notes text,
  completed_at timestamp with time zone,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.call_logs (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  prospect_id uuid,
  client_id uuid,
  prospecteur_id uuid,
  caller_user_id uuid,
  call_date timestamp with time zone default now() not null,
  duration_seconds integer,
  result text,
  notes text,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.client_portfolios (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  owner_user_id uuid not null,
  owner_type text not null,
  name text default 'Mon portefeuille clients'::text not null,
  status text default 'active'::text not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.clients (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  prospecteur_id uuid,
  code text not null,
  first_name text not null,
  last_name text,
  phone text,
  whatsapp text,
  email text,
  address text,
  city text,
  country text,
  latitude numeric(10,7),
  longitude numeric(10,7),
  identity_reference text,
  status text default 'active'::text not null,
  temperature text,
  notes text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  last_activity_at timestamp with time zone,
  archived_at timestamp with time zone,
  last_payment_at timestamp with time zone,
  last_contact_at timestamp with time zone,
  portfolio_id uuid
);

create table if not exists public.commissions (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  prospecteur_id uuid not null,
  sale_id uuid,
  payment_id uuid,
  article_id uuid,
  commission_rate numeric(8,2) default 0 not null,
  base_amount numeric(14,2) default 0 not null,
  commission_amount numeric(14,2) default 0 not null,
  status text default 'pending'::text not null,
  paid_at timestamp with time zone,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.company_settings (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  setting_key text not null,
  setting_value jsonb default '{}'::jsonb not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.daily_tokens (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  client_id uuid,
  sale_id uuid,
  prospecteur_id uuid,
  token_date date default CURRENT_DATE not null,
  expected_amount numeric(14,2) default 0 not null,
  paid_amount numeric(14,2) default 0 not null,
  status text default 'pending'::text not null,
  paid_at timestamp with time zone,
  notes text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.document_sequences (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  document_type text not null,
  prefix text,
  current_number bigint default 0 not null,
  padding integer default 6 not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.document_templates (
  id uuid default gen_random_uuid() not null,
  organization_id uuid,
  code text not null,
  name text not null,
  document_type text not null,
  template_content text,
  active boolean default true not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.documents (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  document_type text not null,
  document_number text,
  title text,
  storage_path text,
  related_table text,
  related_id uuid,
  status text default 'active'::text not null,
  metadata jsonb default '{}'::jsonb not null,
  created_by uuid,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.field_visits (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  prospecteur_id uuid not null,
  client_id uuid,
  prospect_id uuid,
  visit_date timestamp with time zone default now() not null,
  latitude numeric(10,7),
  longitude numeric(10,7),
  address text,
  result text,
  notes text,
  next_follow_up_at timestamp with time zone,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.follow_up_reminders (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  prospect_id uuid,
  client_id uuid,
  user_id uuid,
  reminder_at timestamp with time zone not null,
  channel text default 'app'::text not null,
  status text default 'pending'::text not null,
  message text,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.goods_receipt_items (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  receipt_id uuid not null,
  article_id uuid not null,
  quantity_received numeric(14,3) not null,
  unit_cost numeric(14,2),
  created_at timestamp with time zone default now() not null
);

create table if not exists public.goods_receipts (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  purchase_order_id uuid,
  receipt_number text not null,
  receipt_date date default CURRENT_DATE not null,
  received_by uuid,
  status text default 'received'::text not null,
  notes text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.login_security_events (
  id uuid default gen_random_uuid() not null,
  user_id uuid,
  event_type text not null,
  success boolean default false not null,
  ip_address inet,
  user_agent text,
  metadata jsonb default '{}'::jsonb not null,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.notification_events (
  id uuid default gen_random_uuid() not null,
  organization_id uuid,
  user_id uuid,
  notification_type text not null,
  title text not null,
  message text,
  data jsonb default '{}'::jsonb not null,
  channel text default 'in_app'::text not null,
  status text default 'pending'::text not null,
  sent_at timestamp with time zone,
  read_at timestamp with time zone,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.notification_preferences (
  id uuid default gen_random_uuid() not null,
  user_id uuid not null,
  notification_type text not null,
  in_app boolean default true not null,
  email boolean default false not null,
  sms boolean default false not null,
  whatsapp boolean default false not null,
  push boolean default true not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.organization_personalization (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  logo_url text,
  favicon_url text,
  primary_color text,
  secondary_color text,
  accent_color text,
  login_background_url text,
  dashboard_background_url text,
  company_slogan text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.organization_settings (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  settings jsonb default '{}'::jsonb not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.organization_subscriptions (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  plan_id uuid not null,
  status text default 'pending'::text not null,
  started_at timestamp with time zone,
  expires_at timestamp with time zone,
  auto_renew boolean default false not null,
  external_reference text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.payment_provider_accounts (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  provider text not null,
  environment text default 'sandbox'::text not null,
  public_key text,
  secret_key_encrypted text,
  webhook_secret_encrypted text,
  status text default 'not_configured'::text not null,
  last_verified_at timestamp with time zone,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.payment_provider_events (
  id uuid default gen_random_uuid() not null,
  organization_id uuid,
  provider text not null,
  event_type text not null,
  provider_event_id text,
  provider_reference text,
  status text default 'received'::text not null,
  payload jsonb default '{}'::jsonb not null,
  error_message text,
  processed_at timestamp with time zone,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.payment_refunds (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  payment_id uuid not null,
  sale_return_id uuid,
  amount numeric(14,2) not null,
  refund_date timestamp with time zone default now() not null,
  method text,
  provider text,
  provider_reference text,
  status text default 'processed'::text not null,
  created_by uuid,
  notes text,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.payment_schedules (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  sale_id uuid not null,
  installment_number integer not null,
  due_date date not null,
  expected_amount numeric(14,2) not null,
  paid_amount numeric(14,2) default 0 not null,
  status text default 'pending'::text not null,
  paid_at timestamp with time zone,
  reminder_sent boolean default false not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.payment_webhook_events (
  id uuid default gen_random_uuid() not null,
  provider text not null,
  organization_id uuid,
  external_event_id text,
  event_type text,
  payload jsonb default '{}'::jsonb not null,
  status text default 'received'::text not null,
  processed_at timestamp with time zone,
  error_message text,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.payments (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  sale_id uuid,
  schedule_id uuid,
  client_id uuid,
  prospecteur_id uuid,
  amount numeric(14,2) not null,
  currency text default 'XOF'::text not null,
  payment_date timestamp with time zone default now() not null,
  payment_method text,
  provider text,
  provider_reference text,
  status text default 'successful'::text not null,
  notes text,
  recorded_by uuid,
  created_at timestamp with time zone default now() not null,
  provider_transaction_id text,
  merchant_reference text
);

create table if not exists public.prospect_activities (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  prospect_id uuid not null,
  prospecteur_id uuid,
  activity_type text not null,
  activity_date timestamp with time zone default now() not null,
  result text,
  notes text,
  next_follow_up_at timestamp with time zone,
  created_by uuid,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.prospect_assignments (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  prospect_id uuid not null,
  prospecteur_id uuid not null,
  assigned_by uuid,
  assigned_at timestamp with time zone default now() not null,
  released_at timestamp with time zone,
  active boolean default true not null
);

create table if not exists public.prospect_followups (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  prospect_id uuid not null,
  prospecteur_id uuid,
  scheduled_at timestamp with time zone not null,
  completed_at timestamp with time zone,
  type text default 'call'::text not null,
  status text default 'pending'::text not null,
  reminder_sent boolean default false not null,
  notes text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.prospect_status_history (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  prospect_id uuid not null,
  old_status text,
  new_status text,
  changed_by uuid,
  reason text,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.prospecteur_stocks (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  prospecteur_id uuid not null,
  article_id uuid not null,
  quantity integer default 0 not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.prospecteurs (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  user_id uuid,
  code text not null,
  first_name text not null,
  last_name text,
  phone text,
  whatsapp text,
  email text,
  address text,
  city text,
  country text,
  photo_url text,
  status text default 'active'::text not null,
  commission_rate numeric(8,2) default 0,
  hired_at date,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.prospects (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  prospecteur_id uuid,
  client_id uuid,
  first_name text not null,
  last_name text,
  phone text,
  whatsapp text,
  address text,
  city text,
  desired_article text,
  desired_article_id uuid,
  temperature text default 'cold'::text,
  visit_count integer default 0 not null,
  last_contact_at timestamp with time zone,
  next_follow_up_at timestamp with time zone,
  status text default 'new'::text not null,
  notes text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  duplicate_phone_flag boolean default false,
  duplicate_phone_of uuid,
  last_follow_up_at timestamp with time zone,
  archived_at timestamp with time zone,
  category text,
  purchase_date_planned date,
  estimated_amount numeric(12,2),
  portfolio_id uuid
);

create table if not exists public.purchase_order_items (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  purchase_order_id uuid not null,
  article_id uuid not null,
  quantity numeric(14,3) not null,
  unit_cost numeric(14,2) default 0 not null,
  discount_amount numeric(14,2) default 0 not null,
  tax_amount numeric(14,2) default 0 not null,
  total_amount numeric(14,2) default 0 not null,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.purchase_orders (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  supplier_id uuid not null,
  order_number text not null,
  order_date date default CURRENT_DATE not null,
  expected_date date,
  subtotal numeric(14,2) default 0 not null,
  discount_amount numeric(14,2) default 0 not null,
  tax_amount numeric(14,2) default 0 not null,
  total_amount numeric(14,2) default 0 not null,
  status text default 'draft'::text not null,
  notes text,
  created_by uuid,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.sale_items (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  sale_id uuid not null,
  article_id uuid not null,
  quantity numeric(14,3) default 1 not null,
  unit_fixed_price numeric(14,2),
  unit_cash_price numeric(14,2),
  unit_credit_price numeric(14,2),
  discount_amount numeric(14,2) default 0 not null,
  line_total numeric(14,2) default 0 not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.sales (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  client_id uuid,
  prospecteur_id uuid,
  article_id uuid,
  sale_number text not null,
  sale_date timestamp with time zone default now() not null,
  quantity integer default 1 not null,
  fixed_price numeric(14,2) default 0 not null,
  cash_price numeric(14,2) default 0 not null,
  credit_price numeric(14,2) default 0 not null,
  amount_paid numeric(14,2) default 0 not null,
  amount_remaining numeric(14,2) default 0 not null,
  payment_frequency text,
  payment_amount numeric(14,2) default 0 not null,
  deadline_date date,
  sale_type text default 'credit'::text not null,
  status text default 'active'::text not null,
  client_location text,
  client_phone text,
  notes text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  completed_at timestamp with time zone
);

create table if not exists public.sales_return_items (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  return_id uuid not null,
  article_id uuid not null,
  quantity numeric(14,3) not null,
  refund_amount numeric(14,2) default 0 not null,
  created_at timestamp with time zone default now() not null,
  serial_number_id uuid
);

create table if not exists public.sales_returns (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  sale_id uuid not null,
  client_id uuid,
  return_number text not null,
  return_date timestamp with time zone default now() not null,
  reason text,
  refund_amount numeric(14,2) default 0 not null,
  status text default 'pending'::text not null,
  created_by uuid,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.serial_numbers (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  article_id uuid not null,
  serial_number text not null,
  status text default 'in_stock'::text not null,
  purchase_order_id uuid,
  sale_id uuid,
  client_id uuid,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.stock_movements (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  article_id uuid not null,
  prospecteur_id uuid,
  movement_type text not null,
  quantity integer not null,
  reference_type text,
  reference_id uuid,
  source_location text,
  destination_location text,
  notes text,
  created_by uuid,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.stock_transfer_items (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  transfer_id uuid not null,
  article_id uuid not null,
  quantity numeric(14,3) not null,
  received_quantity numeric(14,3) default 0 not null,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.stock_transfers (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  transfer_number text not null,
  source_warehouse_id uuid not null,
  destination_warehouse_id uuid not null,
  transfer_date timestamp with time zone default now() not null,
  status text default 'draft'::text not null,
  created_by uuid,
  received_by uuid,
  notes text,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.stocks (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  article_id uuid not null,
  quantity integer default 0 not null,
  reserved_quantity integer default 0 not null,
  minimum_quantity integer default 0 not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.subscription_events (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  subscription_id uuid,
  event_type text not null,
  provider text,
  provider_reference text,
  amount numeric,
  currency text,
  metadata jsonb default '{}'::jsonb not null,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.subscription_limits (
  id uuid default gen_random_uuid() not null,
  plan_id uuid not null,
  resource_code text not null,
  limit_value bigint,
  unlimited boolean default false not null,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.subscription_payments (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  subscription_id uuid,
  amount numeric(14,2) not null,
  currency text default 'USD'::text not null,
  provider text,
  provider_reference text,
  payment_method text,
  status text default 'pending'::text not null,
  paid_at timestamp with time zone,
  metadata jsonb default '{}'::jsonb not null,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.subscription_plans (
  id uuid default gen_random_uuid() not null,
  code text not null,
  name text not null,
  description text,
  price numeric(14,2) default 0 not null,
  currency text default 'USD'::text not null,
  duration_days integer not null,
  max_admins integer,
  max_prospecteurs integer,
  max_clients integer,
  features jsonb default '{}'::jsonb not null,
  active boolean default true not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  billing_amount_xof numeric(12,2)
);

create table if not exists public.super_admin_modules (
  id uuid default gen_random_uuid() not null,
  user_id uuid not null,
  module_code text not null,
  module_name text not null,
  enabled boolean default true not null,
  subscription_required boolean default false not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.supplier_payments (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  supplier_id uuid not null,
  purchase_order_id uuid,
  amount numeric(14,2) not null,
  currency text default 'XOF'::text not null,
  payment_date timestamp with time zone default now() not null,
  payment_method text,
  provider text,
  provider_reference text,
  status text default 'paid'::text not null,
  recorded_by uuid,
  notes text,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.suppliers (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  code text not null,
  company_name text not null,
  contact_name text,
  phone text,
  whatsapp text,
  email text,
  address text,
  city text,
  country text,
  tax_number text,
  registration_number text,
  payment_terms text,
  notes text,
  status text default 'active'::text not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.user_permissions (
  id uuid default gen_random_uuid() not null,
  user_id uuid not null,
  permission_id uuid not null,
  granted boolean default true not null,
  granted_by uuid,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.user_settings (
  id uuid default gen_random_uuid() not null,
  user_id uuid not null,
  setting_key text not null,
  setting_value jsonb default '{}'::jsonb not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.warehouse_inventory (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  warehouse_id uuid not null,
  article_id uuid not null,
  quantity numeric(14,3) default 0 not null,
  reserved_quantity numeric(14,3) default 0 not null,
  minimum_quantity numeric(14,3) default 0 not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.warehouse_users (
  id uuid default gen_random_uuid() not null,
  warehouse_id uuid not null,
  user_id uuid not null,
  role text default 'staff'::text not null,
  active boolean default true not null,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.warehouses (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  code text not null,
  name text not null,
  address text,
  city text,
  country text,
  manager_user_id uuid,
  active boolean default true not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
);

create table if not exists public.rate_limits (
  key text primary key,
  count integer not null default 0,
  reset_at timestamptz not null
);

do $ddl$ begin if not exists (select 1 from pg_constraint where conname='article_categories_pkey' and conrelid='public.article_categories'::regclass) then alter table article_categories add constraint article_categories_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='article_serial_assignments_pkey' and conrelid='public.article_serial_assignments'::regclass) then alter table article_serial_assignments add constraint article_serial_assignments_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='articles_cash_price_check' and conrelid='public.articles'::regclass) then alter table articles add constraint articles_cash_price_check CHECK ((cash_price >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='articles_credit_price_check' and conrelid='public.articles'::regclass) then alter table articles add constraint articles_credit_price_check CHECK ((credit_price >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='articles_default_payment_amount_check' and conrelid='public.articles'::regclass) then alter table articles add constraint articles_default_payment_amount_check CHECK ((default_payment_amount >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='articles_fixed_price_check' and conrelid='public.articles'::regclass) then alter table articles add constraint articles_fixed_price_check CHECK ((fixed_price >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='articles_minimum_deposit_check' and conrelid='public.articles'::regclass) then alter table articles add constraint articles_minimum_deposit_check CHECK ((minimum_deposit >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='articles_organization_id_code_key' and conrelid='public.articles'::regclass) then alter table articles add constraint articles_organization_id_code_key UNIQUE (organization_id, code); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='articles_pkey' and conrelid='public.articles'::regclass) then alter table articles add constraint articles_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='audit_events_pkey' and conrelid='public.audit_events'::regclass) then alter table audit_events add constraint audit_events_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='call_center_tasks_pkey' and conrelid='public.call_center_tasks'::regclass) then alter table call_center_tasks add constraint call_center_tasks_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='call_center_tasks_priority_check' and conrelid='public.call_center_tasks'::regclass) then alter table call_center_tasks add constraint call_center_tasks_priority_check CHECK ((priority = ANY (ARRAY['low'::text, 'normal'::text, 'high'::text, 'urgent'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='call_center_tasks_status_check' and conrelid='public.call_center_tasks'::regclass) then alter table call_center_tasks add constraint call_center_tasks_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'completed'::text, 'cancelled'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='call_logs_pkey' and conrelid='public.call_logs'::regclass) then alter table call_logs add constraint call_logs_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='client_portfolios_organization_id_owner_type_owner_user_id_key' and conrelid='public.client_portfolios'::regclass) then alter table client_portfolios add constraint client_portfolios_organization_id_owner_type_owner_user_id_key UNIQUE (organization_id, owner_type, owner_user_id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='client_portfolios_owner_type_check' and conrelid='public.client_portfolios'::regclass) then alter table client_portfolios add constraint client_portfolios_owner_type_check CHECK ((owner_type = ANY (ARRAY['prospecteur'::text, 'super_admin'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='client_portfolios_pkey' and conrelid='public.client_portfolios'::regclass) then alter table client_portfolios add constraint client_portfolios_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='client_portfolios_status_check' and conrelid='public.client_portfolios'::regclass) then alter table client_portfolios add constraint client_portfolios_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'archived'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='clients_code_key' and conrelid='public.clients'::regclass) then alter table clients add constraint clients_code_key UNIQUE (code); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='clients_pkey' and conrelid='public.clients'::regclass) then alter table clients add constraint clients_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='clients_status_check' and conrelid='public.clients'::regclass) then alter table clients add constraint clients_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'prospect'::text, 'client'::text, 'debtor'::text, 'completed'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='clients_status_check_jdv_v1' and conrelid='public.clients'::regclass) then alter table clients add constraint clients_status_check_jdv_v1 CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'prospect'::text, 'client'::text, 'debtor'::text, 'completed'::text, 'archived'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='clients_temperature_check' and conrelid='public.clients'::regclass) then alter table clients add constraint clients_temperature_check CHECK ((temperature = ANY (ARRAY['hot'::text, 'warm'::text, 'cold'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='clients_temperature_check_jdv_v1' and conrelid='public.clients'::regclass) then alter table clients add constraint clients_temperature_check_jdv_v1 CHECK (((temperature IS NULL) OR (temperature = ANY (ARRAY['hot'::text, 'warm'::text, 'cold'::text])))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='commissions_base_amount_check' and conrelid='public.commissions'::regclass) then alter table commissions add constraint commissions_base_amount_check CHECK ((base_amount >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='commissions_commission_amount_check' and conrelid='public.commissions'::regclass) then alter table commissions add constraint commissions_commission_amount_check CHECK ((commission_amount >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='commissions_commission_rate_check' and conrelid='public.commissions'::regclass) then alter table commissions add constraint commissions_commission_rate_check CHECK ((commission_rate >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='commissions_pkey' and conrelid='public.commissions'::regclass) then alter table commissions add constraint commissions_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='commissions_status_check' and conrelid='public.commissions'::regclass) then alter table commissions add constraint commissions_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'paid'::text, 'cancelled'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='company_settings_organization_id_setting_key_key' and conrelid='public.company_settings'::regclass) then alter table company_settings add constraint company_settings_organization_id_setting_key_key UNIQUE (organization_id, setting_key); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='company_settings_pkey' and conrelid='public.company_settings'::regclass) then alter table company_settings add constraint company_settings_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='daily_tokens_pkey' and conrelid='public.daily_tokens'::regclass) then alter table daily_tokens add constraint daily_tokens_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='daily_tokens_status_check' and conrelid='public.daily_tokens'::regclass) then alter table daily_tokens add constraint daily_tokens_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'paid'::text, 'partial'::text, 'late'::text, 'missed'::text, 'cancelled'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='document_sequences_organization_id_document_type_key' and conrelid='public.document_sequences'::regclass) then alter table document_sequences add constraint document_sequences_organization_id_document_type_key UNIQUE (organization_id, document_type); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='document_sequences_pkey' and conrelid='public.document_sequences'::regclass) then alter table document_sequences add constraint document_sequences_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='document_templates_organization_id_code_key' and conrelid='public.document_templates'::regclass) then alter table document_templates add constraint document_templates_organization_id_code_key UNIQUE (organization_id, code); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='document_templates_pkey' and conrelid='public.document_templates'::regclass) then alter table document_templates add constraint document_templates_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='documents_pkey' and conrelid='public.documents'::regclass) then alter table documents add constraint documents_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='field_visits_pkey' and conrelid='public.field_visits'::regclass) then alter table field_visits add constraint field_visits_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='follow_up_reminders_pkey' and conrelid='public.follow_up_reminders'::regclass) then alter table follow_up_reminders add constraint follow_up_reminders_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='follow_up_reminders_status_check' and conrelid='public.follow_up_reminders'::regclass) then alter table follow_up_reminders add constraint follow_up_reminders_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'sent'::text, 'completed'::text, 'cancelled'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='goods_receipt_items_pkey' and conrelid='public.goods_receipt_items'::regclass) then alter table goods_receipt_items add constraint goods_receipt_items_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='goods_receipt_items_quantity_received_check' and conrelid='public.goods_receipt_items'::regclass) then alter table goods_receipt_items add constraint goods_receipt_items_quantity_received_check CHECK ((quantity_received > (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='goods_receipts_organization_id_receipt_number_key' and conrelid='public.goods_receipts'::regclass) then alter table goods_receipts add constraint goods_receipts_organization_id_receipt_number_key UNIQUE (organization_id, receipt_number); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='goods_receipts_pkey' and conrelid='public.goods_receipts'::regclass) then alter table goods_receipts add constraint goods_receipts_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='goods_receipts_status_check' and conrelid='public.goods_receipts'::regclass) then alter table goods_receipts add constraint goods_receipts_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'received'::text, 'cancelled'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='login_security_events_pkey' and conrelid='public.login_security_events'::regclass) then alter table login_security_events add constraint login_security_events_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='notification_events_pkey' and conrelid='public.notification_events'::regclass) then alter table notification_events add constraint notification_events_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='notification_events_status_check' and conrelid='public.notification_events'::regclass) then alter table notification_events add constraint notification_events_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'sent'::text, 'read'::text, 'failed'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='notification_preferences_pkey' and conrelid='public.notification_preferences'::regclass) then alter table notification_preferences add constraint notification_preferences_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='notification_preferences_user_id_notification_type_key' and conrelid='public.notification_preferences'::regclass) then alter table notification_preferences add constraint notification_preferences_user_id_notification_type_key UNIQUE (user_id, notification_type); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='organization_personalization_org_unique' and conrelid='public.organization_personalization'::regclass) then alter table organization_personalization add constraint organization_personalization_org_unique UNIQUE (organization_id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='organization_personalization_pkey' and conrelid='public.organization_personalization'::regclass) then alter table organization_personalization add constraint organization_personalization_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='organization_settings_organization_id_key' and conrelid='public.organization_settings'::regclass) then alter table organization_settings add constraint organization_settings_organization_id_key UNIQUE (organization_id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='organization_settings_pkey' and conrelid='public.organization_settings'::regclass) then alter table organization_settings add constraint organization_settings_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='organization_subscriptions_dates_check' and conrelid='public.organization_subscriptions'::regclass) then alter table organization_subscriptions add constraint organization_subscriptions_dates_check CHECK (((expires_at IS NULL) OR (started_at IS NULL) OR (expires_at >= started_at))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='organization_subscriptions_dates_valid' and conrelid='public.organization_subscriptions'::regclass) then alter table organization_subscriptions add constraint organization_subscriptions_dates_valid CHECK (((expires_at IS NULL) OR (started_at IS NULL) OR (expires_at > started_at))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='organization_subscriptions_pkey' and conrelid='public.organization_subscriptions'::regclass) then alter table organization_subscriptions add constraint organization_subscriptions_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='organization_subscriptions_status_check' and conrelid='public.organization_subscriptions'::regclass) then alter table organization_subscriptions add constraint organization_subscriptions_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'trial'::text, 'active'::text, 'past_due'::text, 'expired'::text, 'cancelled'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_provider_accounts_environment_check' and conrelid='public.payment_provider_accounts'::regclass) then alter table payment_provider_accounts add constraint payment_provider_accounts_environment_check CHECK ((environment = ANY (ARRAY['sandbox'::text, 'live'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_provider_accounts_organization_id_provider_key' and conrelid='public.payment_provider_accounts'::regclass) then alter table payment_provider_accounts add constraint payment_provider_accounts_organization_id_provider_key UNIQUE (organization_id, provider); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_provider_accounts_pkey' and conrelid='public.payment_provider_accounts'::regclass) then alter table payment_provider_accounts add constraint payment_provider_accounts_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_provider_accounts_provider_check' and conrelid='public.payment_provider_accounts'::regclass) then alter table payment_provider_accounts add constraint payment_provider_accounts_provider_check CHECK ((provider = 'fedapay'::text)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_provider_accounts_status_check' and conrelid='public.payment_provider_accounts'::regclass) then alter table payment_provider_accounts add constraint payment_provider_accounts_status_check CHECK ((status = ANY (ARRAY['not_configured'::text, 'active'::text, 'error'::text, 'disabled'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_provider_events_pkey' and conrelid='public.payment_provider_events'::regclass) then alter table payment_provider_events add constraint payment_provider_events_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_provider_events_provider_provider_event_id_key' and conrelid='public.payment_provider_events'::regclass) then alter table payment_provider_events add constraint payment_provider_events_provider_provider_event_id_key UNIQUE (provider, provider_event_id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_provider_events_status_check' and conrelid='public.payment_provider_events'::regclass) then alter table payment_provider_events add constraint payment_provider_events_status_check CHECK ((status = ANY (ARRAY['received'::text, 'processed'::text, 'failed'::text, 'ignored'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_refunds_amount_check' and conrelid='public.payment_refunds'::regclass) then alter table payment_refunds add constraint payment_refunds_amount_check CHECK ((amount > (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_refunds_pkey' and conrelid='public.payment_refunds'::regclass) then alter table payment_refunds add constraint payment_refunds_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_refunds_status_check' and conrelid='public.payment_refunds'::regclass) then alter table payment_refunds add constraint payment_refunds_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'processed'::text, 'failed'::text, 'cancelled'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_schedules_amounts_valid' and conrelid='public.payment_schedules'::regclass) then alter table payment_schedules add constraint payment_schedules_amounts_valid CHECK (((expected_amount > (0)::numeric) AND (paid_amount >= (0)::numeric) AND (paid_amount <= expected_amount))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_schedules_expected_amount_check' and conrelid='public.payment_schedules'::regclass) then alter table payment_schedules add constraint payment_schedules_expected_amount_check CHECK ((expected_amount >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_schedules_installment_number_check' and conrelid='public.payment_schedules'::regclass) then alter table payment_schedules add constraint payment_schedules_installment_number_check CHECK ((installment_number > 0)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_schedules_installment_positive' and conrelid='public.payment_schedules'::regclass) then alter table payment_schedules add constraint payment_schedules_installment_positive CHECK ((installment_number > 0)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_schedules_paid_amount_check' and conrelid='public.payment_schedules'::regclass) then alter table payment_schedules add constraint payment_schedules_paid_amount_check CHECK ((paid_amount >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_schedules_pkey' and conrelid='public.payment_schedules'::regclass) then alter table payment_schedules add constraint payment_schedules_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_schedules_sale_id_installment_number_key' and conrelid='public.payment_schedules'::regclass) then alter table payment_schedules add constraint payment_schedules_sale_id_installment_number_key UNIQUE (sale_id, installment_number); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_schedules_status_check' and conrelid='public.payment_schedules'::regclass) then alter table payment_schedules add constraint payment_schedules_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'partial'::text, 'paid'::text, 'late'::text, 'cancelled'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_webhook_events_pkey' and conrelid='public.payment_webhook_events'::regclass) then alter table payment_webhook_events add constraint payment_webhook_events_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payments_amount_check' and conrelid='public.payments'::regclass) then alter table payments add constraint payments_amount_check CHECK ((amount > (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payments_amount_positive' and conrelid='public.payments'::regclass) then alter table payments add constraint payments_amount_positive CHECK ((amount > (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payments_pkey' and conrelid='public.payments'::regclass) then alter table payments add constraint payments_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payments_status_check' and conrelid='public.payments'::regclass) then alter table payments add constraint payments_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'successful'::text, 'failed'::text, 'cancelled'::text, 'refunded'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_activities_pkey' and conrelid='public.prospect_activities'::regclass) then alter table prospect_activities add constraint prospect_activities_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_assignments_pkey' and conrelid='public.prospect_assignments'::regclass) then alter table prospect_assignments add constraint prospect_assignments_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_followups_pkey' and conrelid='public.prospect_followups'::regclass) then alter table prospect_followups add constraint prospect_followups_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_followups_status_check' and conrelid='public.prospect_followups'::regclass) then alter table prospect_followups add constraint prospect_followups_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text, 'missed'::text, 'cancelled'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_status_history_pkey' and conrelid='public.prospect_status_history'::regclass) then alter table prospect_status_history add constraint prospect_status_history_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospecteur_stocks_pkey' and conrelid='public.prospecteur_stocks'::regclass) then alter table prospecteur_stocks add constraint prospecteur_stocks_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospecteur_stocks_prospecteur_id_article_id_key' and conrelid='public.prospecteur_stocks'::regclass) then alter table prospecteur_stocks add constraint prospecteur_stocks_prospecteur_id_article_id_key UNIQUE (prospecteur_id, article_id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospecteur_stocks_quantity_check' and conrelid='public.prospecteur_stocks'::regclass) then alter table prospecteur_stocks add constraint prospecteur_stocks_quantity_check CHECK ((quantity >= 0)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospecteurs_code_key' and conrelid='public.prospecteurs'::regclass) then alter table prospecteurs add constraint prospecteurs_code_key UNIQUE (code); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospecteurs_commission_rate_check' and conrelid='public.prospecteurs'::regclass) then alter table prospecteurs add constraint prospecteurs_commission_rate_check CHECK ((commission_rate >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospecteurs_commission_rate_valid' and conrelid='public.prospecteurs'::regclass) then alter table prospecteurs add constraint prospecteurs_commission_rate_valid CHECK (((commission_rate >= (0)::numeric) AND (commission_rate <= (100)::numeric))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospecteurs_pkey' and conrelid='public.prospecteurs'::regclass) then alter table prospecteurs add constraint prospecteurs_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospecteurs_status_check' and conrelid='public.prospecteurs'::regclass) then alter table prospecteurs add constraint prospecteurs_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'suspended'::text, 'blocked'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospecteurs_status_check_jdv_v1' and conrelid='public.prospecteurs'::regclass) then alter table prospecteurs add constraint prospecteurs_status_check_jdv_v1 CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'suspended'::text, 'blocked'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospecteurs_user_id_key' and conrelid='public.prospecteurs'::regclass) then alter table prospecteurs add constraint prospecteurs_user_id_key UNIQUE (user_id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospects_pkey' and conrelid='public.prospects'::regclass) then alter table prospects add constraint prospects_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospects_status_check' and conrelid='public.prospects'::regclass) then alter table prospects add constraint prospects_status_check CHECK ((status = ANY (ARRAY['new'::text, 'contacted'::text, 'interested'::text, 'converted'::text, 'lost'::text, 'inactive'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospects_status_check_jdv_v1' and conrelid='public.prospects'::regclass) then alter table prospects add constraint prospects_status_check_jdv_v1 CHECK ((status = ANY (ARRAY['new'::text, 'contacted'::text, 'interested'::text, 'converted'::text, 'lost'::text, 'inactive'::text, 'closed'::text, 'archived'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospects_temperature_check' and conrelid='public.prospects'::regclass) then alter table prospects add constraint prospects_temperature_check CHECK ((temperature = ANY (ARRAY['hot'::text, 'warm'::text, 'cold'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospects_temperature_check_jdv_v1' and conrelid='public.prospects'::regclass) then alter table prospects add constraint prospects_temperature_check_jdv_v1 CHECK ((temperature = ANY (ARRAY['hot'::text, 'warm'::text, 'cold'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospects_visit_count_check' and conrelid='public.prospects'::regclass) then alter table prospects add constraint prospects_visit_count_check CHECK ((visit_count >= 0)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospects_visit_count_nonnegative' and conrelid='public.prospects'::regclass) then alter table prospects add constraint prospects_visit_count_nonnegative CHECK ((visit_count >= 0)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='purchase_order_items_pkey' and conrelid='public.purchase_order_items'::regclass) then alter table purchase_order_items add constraint purchase_order_items_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='purchase_order_items_quantity_check' and conrelid='public.purchase_order_items'::regclass) then alter table purchase_order_items add constraint purchase_order_items_quantity_check CHECK ((quantity > (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='purchase_orders_organization_id_order_number_key' and conrelid='public.purchase_orders'::regclass) then alter table purchase_orders add constraint purchase_orders_organization_id_order_number_key UNIQUE (organization_id, order_number); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='purchase_orders_pkey' and conrelid='public.purchase_orders'::regclass) then alter table purchase_orders add constraint purchase_orders_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='purchase_orders_status_check' and conrelid='public.purchase_orders'::regclass) then alter table purchase_orders add constraint purchase_orders_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'sent'::text, 'confirmed'::text, 'partial'::text, 'received'::text, 'cancelled'::text, 'closed'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sale_items_amounts_nonnegative' and conrelid='public.sale_items'::regclass) then alter table sale_items add constraint sale_items_amounts_nonnegative CHECK (((discount_amount >= (0)::numeric) AND (line_total >= (0)::numeric) AND ((unit_fixed_price IS NULL) OR (unit_fixed_price >= (0)::numeric)) AND ((unit_cash_price IS NULL) OR (unit_cash_price >= (0)::numeric)) AND ((unit_credit_price IS NULL) OR (unit_credit_price >= (0)::numeric)))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sale_items_discount_amount_check' and conrelid='public.sale_items'::regclass) then alter table sale_items add constraint sale_items_discount_amount_check CHECK ((discount_amount >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sale_items_pkey' and conrelid='public.sale_items'::regclass) then alter table sale_items add constraint sale_items_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sale_items_prices_nonnegative' and conrelid='public.sale_items'::regclass) then alter table sale_items add constraint sale_items_prices_nonnegative CHECK (((COALESCE(unit_fixed_price, (0)::numeric) >= (0)::numeric) AND (COALESCE(unit_cash_price, (0)::numeric) >= (0)::numeric) AND (COALESCE(unit_credit_price, (0)::numeric) >= (0)::numeric) AND (COALESCE(discount_amount, (0)::numeric) >= (0)::numeric) AND (COALESCE(line_total, (0)::numeric) >= (0)::numeric))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sale_items_quantity_check' and conrelid='public.sale_items'::regclass) then alter table sale_items add constraint sale_items_quantity_check CHECK ((quantity > (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sale_items_quantity_positive' and conrelid='public.sale_items'::regclass) then alter table sale_items add constraint sale_items_quantity_positive CHECK ((quantity > (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_return_items_pkey' and conrelid='public.sales_return_items'::regclass) then alter table sales_return_items add constraint sales_return_items_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_return_items_quantity_check' and conrelid='public.sales_return_items'::regclass) then alter table sales_return_items add constraint sales_return_items_quantity_check CHECK ((quantity > (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_return_items_quantity_positive' and conrelid='public.sales_return_items'::regclass) then alter table sales_return_items add constraint sales_return_items_quantity_positive CHECK ((quantity > (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_return_items_refund_nonnegative' and conrelid='public.sales_return_items'::regclass) then alter table sales_return_items add constraint sales_return_items_refund_nonnegative CHECK ((refund_amount >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_returns_organization_id_return_number_key' and conrelid='public.sales_returns'::regclass) then alter table sales_returns add constraint sales_returns_organization_id_return_number_key UNIQUE (organization_id, return_number); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_returns_pkey' and conrelid='public.sales_returns'::regclass) then alter table sales_returns add constraint sales_returns_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_returns_refund_nonnegative' and conrelid='public.sales_returns'::regclass) then alter table sales_returns add constraint sales_returns_refund_nonnegative CHECK ((refund_amount >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_returns_status_check' and conrelid='public.sales_returns'::regclass) then alter table sales_returns add constraint sales_returns_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'processed'::text, 'cancelled'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_amount_paid_check' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_amount_paid_check CHECK ((amount_paid >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_amount_remaining_check' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_amount_remaining_check CHECK ((amount_remaining >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_amounts_nonnegative' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_amounts_nonnegative CHECK (((amount_paid >= (0)::numeric) AND (amount_remaining >= (0)::numeric) AND (payment_amount >= (0)::numeric))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_payment_amount_check' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_payment_amount_check CHECK ((payment_amount >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_payment_frequency_check' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_payment_frequency_check CHECK ((payment_frequency = ANY (ARRAY['daily'::text, 'weekly'::text, 'biweekly'::text, 'monthly'::text, 'quarterly'::text, 'custom'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_pkey' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_prices_nonnegative' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_prices_nonnegative CHECK (((fixed_price >= (0)::numeric) AND (cash_price >= (0)::numeric) AND (credit_price >= (0)::numeric))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_quantity_check' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_quantity_check CHECK ((quantity > 0)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_quantity_nonnegative' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_quantity_nonnegative CHECK ((quantity >= 0)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_sale_number_key' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_sale_number_key UNIQUE (sale_number); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_sale_type_check' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_sale_type_check CHECK ((sale_type = ANY (ARRAY['cash'::text, 'credit'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_status_check' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'active'::text, 'completed'::text, 'cancelled'::text, 'defaulted'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='serial_numbers_organization_id_serial_number_key' and conrelid='public.serial_numbers'::regclass) then alter table serial_numbers add constraint serial_numbers_organization_id_serial_number_key UNIQUE (organization_id, serial_number); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='serial_numbers_pkey' and conrelid='public.serial_numbers'::regclass) then alter table serial_numbers add constraint serial_numbers_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='serial_numbers_status_check' and conrelid='public.serial_numbers'::regclass) then alter table serial_numbers add constraint serial_numbers_status_check CHECK ((status = ANY (ARRAY['in_stock'::text, 'reserved'::text, 'sold'::text, 'returned'::text, 'damaged'::text, 'lost'::text, 'inactive'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_movements_movement_type_check' and conrelid='public.stock_movements'::regclass) then alter table stock_movements add constraint stock_movements_movement_type_check CHECK ((movement_type = ANY (ARRAY['entry'::text, 'exit'::text, 'transfer_to_prospecteur'::text, 'return_from_prospecteur'::text, 'sale'::text, 'adjustment'::text, 'loss'::text, 'transfer_out'::text, 'transfer_in'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_movements_pkey' and conrelid='public.stock_movements'::regclass) then alter table stock_movements add constraint stock_movements_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_movements_quantity_check' and conrelid='public.stock_movements'::regclass) then alter table stock_movements add constraint stock_movements_quantity_check CHECK ((quantity > 0)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_movements_quantity_positive' and conrelid='public.stock_movements'::regclass) then alter table stock_movements add constraint stock_movements_quantity_positive CHECK ((quantity > 0)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_transfer_items_pkey' and conrelid='public.stock_transfer_items'::regclass) then alter table stock_transfer_items add constraint stock_transfer_items_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_transfer_items_quantity_check' and conrelid='public.stock_transfer_items'::regclass) then alter table stock_transfer_items add constraint stock_transfer_items_quantity_check CHECK ((quantity > (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_transfer_items_received_quantity_check' and conrelid='public.stock_transfer_items'::regclass) then alter table stock_transfer_items add constraint stock_transfer_items_received_quantity_check CHECK ((received_quantity >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_transfers_check' and conrelid='public.stock_transfers'::regclass) then alter table stock_transfers add constraint stock_transfers_check CHECK ((source_warehouse_id <> destination_warehouse_id)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_transfers_organization_id_transfer_number_key' and conrelid='public.stock_transfers'::regclass) then alter table stock_transfers add constraint stock_transfers_organization_id_transfer_number_key UNIQUE (organization_id, transfer_number); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_transfers_pkey' and conrelid='public.stock_transfers'::regclass) then alter table stock_transfers add constraint stock_transfers_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_transfers_status_check' and conrelid='public.stock_transfers'::regclass) then alter table stock_transfers add constraint stock_transfers_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'in_transit'::text, 'received'::text, 'cancelled'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stocks_minimum_quantity_check' and conrelid='public.stocks'::regclass) then alter table stocks add constraint stocks_minimum_quantity_check CHECK ((minimum_quantity >= 0)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stocks_organization_id_article_id_key' and conrelid='public.stocks'::regclass) then alter table stocks add constraint stocks_organization_id_article_id_key UNIQUE (organization_id, article_id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stocks_pkey' and conrelid='public.stocks'::regclass) then alter table stocks add constraint stocks_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stocks_quantities_nonnegative' and conrelid='public.stocks'::regclass) then alter table stocks add constraint stocks_quantities_nonnegative CHECK (((quantity >= 0) AND (reserved_quantity >= 0) AND (minimum_quantity >= 0))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stocks_quantity_check' and conrelid='public.stocks'::regclass) then alter table stocks add constraint stocks_quantity_check CHECK ((quantity >= 0)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stocks_reserved_not_above_quantity' and conrelid='public.stocks'::regclass) then alter table stocks add constraint stocks_reserved_not_above_quantity CHECK ((reserved_quantity <= quantity)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stocks_reserved_quantity_check' and conrelid='public.stocks'::regclass) then alter table stocks add constraint stocks_reserved_quantity_check CHECK ((reserved_quantity >= 0)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_events_pkey' and conrelid='public.subscription_events'::regclass) then alter table subscription_events add constraint subscription_events_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_limits_pkey' and conrelid='public.subscription_limits'::regclass) then alter table subscription_limits add constraint subscription_limits_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_limits_plan_id_resource_code_key' and conrelid='public.subscription_limits'::regclass) then alter table subscription_limits add constraint subscription_limits_plan_id_resource_code_key UNIQUE (plan_id, resource_code); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_payments_amount_check' and conrelid='public.subscription_payments'::regclass) then alter table subscription_payments add constraint subscription_payments_amount_check CHECK ((amount >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_payments_amount_positive' and conrelid='public.subscription_payments'::regclass) then alter table subscription_payments add constraint subscription_payments_amount_positive CHECK ((amount > (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_payments_pkey' and conrelid='public.subscription_payments'::regclass) then alter table subscription_payments add constraint subscription_payments_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_payments_status_check' and conrelid='public.subscription_payments'::regclass) then alter table subscription_payments add constraint subscription_payments_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'successful'::text, 'failed'::text, 'refunded'::text, 'cancelled'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_plans_code_key' and conrelid='public.subscription_plans'::regclass) then alter table subscription_plans add constraint subscription_plans_code_key UNIQUE (code); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_plans_duration_days_check' and conrelid='public.subscription_plans'::regclass) then alter table subscription_plans add constraint subscription_plans_duration_days_check CHECK ((duration_days > 0)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_plans_pkey' and conrelid='public.subscription_plans'::regclass) then alter table subscription_plans add constraint subscription_plans_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_plans_price_check' and conrelid='public.subscription_plans'::regclass) then alter table subscription_plans add constraint subscription_plans_price_check CHECK ((price >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='super_admin_modules_pkey' and conrelid='public.super_admin_modules'::regclass) then alter table super_admin_modules add constraint super_admin_modules_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='super_admin_modules_user_id_module_code_key' and conrelid='public.super_admin_modules'::regclass) then alter table super_admin_modules add constraint super_admin_modules_user_id_module_code_key UNIQUE (user_id, module_code); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='supplier_payments_amount_check' and conrelid='public.supplier_payments'::regclass) then alter table supplier_payments add constraint supplier_payments_amount_check CHECK ((amount > (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='supplier_payments_pkey' and conrelid='public.supplier_payments'::regclass) then alter table supplier_payments add constraint supplier_payments_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='supplier_payments_status_check' and conrelid='public.supplier_payments'::regclass) then alter table supplier_payments add constraint supplier_payments_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'paid'::text, 'failed'::text, 'cancelled'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='suppliers_organization_id_code_key' and conrelid='public.suppliers'::regclass) then alter table suppliers add constraint suppliers_organization_id_code_key UNIQUE (organization_id, code); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='suppliers_pkey' and conrelid='public.suppliers'::regclass) then alter table suppliers add constraint suppliers_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='suppliers_status_check' and conrelid='public.suppliers'::regclass) then alter table suppliers add constraint suppliers_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'blocked'::text]))); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='user_permissions_pkey' and conrelid='public.user_permissions'::regclass) then alter table user_permissions add constraint user_permissions_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='user_permissions_user_id_permission_id_key' and conrelid='public.user_permissions'::regclass) then alter table user_permissions add constraint user_permissions_user_id_permission_id_key UNIQUE (user_id, permission_id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='user_settings_pkey' and conrelid='public.user_settings'::regclass) then alter table user_settings add constraint user_settings_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='user_settings_user_id_setting_key_key' and conrelid='public.user_settings'::regclass) then alter table user_settings add constraint user_settings_user_id_setting_key_key UNIQUE (user_id, setting_key); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='warehouse_inventory_minimum_quantity_check' and conrelid='public.warehouse_inventory'::regclass) then alter table warehouse_inventory add constraint warehouse_inventory_minimum_quantity_check CHECK ((minimum_quantity >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='warehouse_inventory_pkey' and conrelid='public.warehouse_inventory'::regclass) then alter table warehouse_inventory add constraint warehouse_inventory_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='warehouse_inventory_quantity_check' and conrelid='public.warehouse_inventory'::regclass) then alter table warehouse_inventory add constraint warehouse_inventory_quantity_check CHECK ((quantity >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='warehouse_inventory_reserved_quantity_check' and conrelid='public.warehouse_inventory'::regclass) then alter table warehouse_inventory add constraint warehouse_inventory_reserved_quantity_check CHECK ((reserved_quantity >= (0)::numeric)); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='warehouse_inventory_warehouse_id_article_id_key' and conrelid='public.warehouse_inventory'::regclass) then alter table warehouse_inventory add constraint warehouse_inventory_warehouse_id_article_id_key UNIQUE (warehouse_id, article_id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='warehouse_users_pkey' and conrelid='public.warehouse_users'::regclass) then alter table warehouse_users add constraint warehouse_users_pkey PRIMARY KEY (id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='warehouse_users_warehouse_id_user_id_key' and conrelid='public.warehouse_users'::regclass) then alter table warehouse_users add constraint warehouse_users_warehouse_id_user_id_key UNIQUE (warehouse_id, user_id); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='warehouses_organization_id_code_key' and conrelid='public.warehouses'::regclass) then alter table warehouses add constraint warehouses_organization_id_code_key UNIQUE (organization_id, code); end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='warehouses_pkey' and conrelid='public.warehouses'::regclass) then alter table warehouses add constraint warehouses_pkey PRIMARY KEY (id); end if; end $ddl$;

do $ddl$ begin if not exists (select 1 from pg_constraint where conname='article_serial_assignments_article_id_fkey' and conrelid='public.article_serial_assignments'::regclass) then alter table article_serial_assignments add constraint article_serial_assignments_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='article_serial_assignments_organization_id_fkey' and conrelid='public.article_serial_assignments'::regclass) then alter table article_serial_assignments add constraint article_serial_assignments_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='article_serial_assignments_prospecteur_id_fkey' and conrelid='public.article_serial_assignments'::regclass) then alter table article_serial_assignments add constraint article_serial_assignments_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='article_serial_assignments_serial_number_id_fkey' and conrelid='public.article_serial_assignments'::regclass) then alter table article_serial_assignments add constraint article_serial_assignments_serial_number_id_fkey FOREIGN KEY (serial_number_id) REFERENCES serial_numbers(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='article_serial_assignments_warehouse_id_fkey' and conrelid='public.article_serial_assignments'::regclass) then alter table article_serial_assignments add constraint article_serial_assignments_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='articles_organization_id_fkey' and conrelid='public.articles'::regclass) then alter table articles add constraint articles_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='audit_events_organization_id_fkey' and conrelid='public.audit_events'::regclass) then alter table audit_events add constraint audit_events_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='call_center_tasks_client_id_fkey' and conrelid='public.call_center_tasks'::regclass) then alter table call_center_tasks add constraint call_center_tasks_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='call_center_tasks_organization_id_fkey' and conrelid='public.call_center_tasks'::regclass) then alter table call_center_tasks add constraint call_center_tasks_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='call_center_tasks_prospect_id_fkey' and conrelid='public.call_center_tasks'::regclass) then alter table call_center_tasks add constraint call_center_tasks_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='call_center_tasks_prospecteur_id_fkey' and conrelid='public.call_center_tasks'::regclass) then alter table call_center_tasks add constraint call_center_tasks_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='call_logs_client_id_fkey' and conrelid='public.call_logs'::regclass) then alter table call_logs add constraint call_logs_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='call_logs_organization_id_fkey' and conrelid='public.call_logs'::regclass) then alter table call_logs add constraint call_logs_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='call_logs_prospect_id_fkey' and conrelid='public.call_logs'::regclass) then alter table call_logs add constraint call_logs_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='call_logs_prospecteur_id_fkey' and conrelid='public.call_logs'::regclass) then alter table call_logs add constraint call_logs_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='client_portfolios_organization_id_fkey' and conrelid='public.client_portfolios'::regclass) then alter table client_portfolios add constraint client_portfolios_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='clients_organization_id_fkey' and conrelid='public.clients'::regclass) then alter table clients add constraint clients_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='clients_portfolio_id_fkey' and conrelid='public.clients'::regclass) then alter table clients add constraint clients_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES client_portfolios(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='clients_prospecteur_id_fkey' and conrelid='public.clients'::regclass) then alter table clients add constraint clients_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='commissions_article_id_fkey' and conrelid='public.commissions'::regclass) then alter table commissions add constraint commissions_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='commissions_organization_id_fkey' and conrelid='public.commissions'::regclass) then alter table commissions add constraint commissions_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='commissions_payment_id_fkey' and conrelid='public.commissions'::regclass) then alter table commissions add constraint commissions_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='commissions_prospecteur_id_fkey' and conrelid='public.commissions'::regclass) then alter table commissions add constraint commissions_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='commissions_sale_id_fkey' and conrelid='public.commissions'::regclass) then alter table commissions add constraint commissions_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='company_settings_organization_id_fkey' and conrelid='public.company_settings'::regclass) then alter table company_settings add constraint company_settings_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='daily_tokens_client_id_fkey' and conrelid='public.daily_tokens'::regclass) then alter table daily_tokens add constraint daily_tokens_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='daily_tokens_organization_id_fkey' and conrelid='public.daily_tokens'::regclass) then alter table daily_tokens add constraint daily_tokens_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='daily_tokens_prospecteur_id_fkey' and conrelid='public.daily_tokens'::regclass) then alter table daily_tokens add constraint daily_tokens_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='daily_tokens_sale_id_fkey' and conrelid='public.daily_tokens'::regclass) then alter table daily_tokens add constraint daily_tokens_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='document_sequences_organization_id_fkey' and conrelid='public.document_sequences'::regclass) then alter table document_sequences add constraint document_sequences_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='document_templates_organization_id_fkey' and conrelid='public.document_templates'::regclass) then alter table document_templates add constraint document_templates_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='documents_organization_id_fkey' and conrelid='public.documents'::regclass) then alter table documents add constraint documents_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='field_visits_client_id_fkey' and conrelid='public.field_visits'::regclass) then alter table field_visits add constraint field_visits_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='field_visits_organization_id_fkey' and conrelid='public.field_visits'::regclass) then alter table field_visits add constraint field_visits_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='field_visits_prospect_id_fkey' and conrelid='public.field_visits'::regclass) then alter table field_visits add constraint field_visits_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='field_visits_prospecteur_id_fkey' and conrelid='public.field_visits'::regclass) then alter table field_visits add constraint field_visits_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='follow_up_reminders_client_id_fkey' and conrelid='public.follow_up_reminders'::regclass) then alter table follow_up_reminders add constraint follow_up_reminders_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='follow_up_reminders_organization_id_fkey' and conrelid='public.follow_up_reminders'::regclass) then alter table follow_up_reminders add constraint follow_up_reminders_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='follow_up_reminders_prospect_id_fkey' and conrelid='public.follow_up_reminders'::regclass) then alter table follow_up_reminders add constraint follow_up_reminders_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='goods_receipt_items_article_id_fkey' and conrelid='public.goods_receipt_items'::regclass) then alter table goods_receipt_items add constraint goods_receipt_items_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='goods_receipt_items_organization_id_fkey' and conrelid='public.goods_receipt_items'::regclass) then alter table goods_receipt_items add constraint goods_receipt_items_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='goods_receipt_items_receipt_id_fkey' and conrelid='public.goods_receipt_items'::regclass) then alter table goods_receipt_items add constraint goods_receipt_items_receipt_id_fkey FOREIGN KEY (receipt_id) REFERENCES goods_receipts(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='goods_receipts_organization_id_fkey' and conrelid='public.goods_receipts'::regclass) then alter table goods_receipts add constraint goods_receipts_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='goods_receipts_purchase_order_id_fkey' and conrelid='public.goods_receipts'::regclass) then alter table goods_receipts add constraint goods_receipts_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='notification_events_organization_id_fkey' and conrelid='public.notification_events'::regclass) then alter table notification_events add constraint notification_events_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='organization_personalization_organization_id_fkey' and conrelid='public.organization_personalization'::regclass) then alter table organization_personalization add constraint organization_personalization_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='organization_settings_organization_id_fkey' and conrelid='public.organization_settings'::regclass) then alter table organization_settings add constraint organization_settings_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='organization_subscriptions_organization_id_fkey' and conrelid='public.organization_subscriptions'::regclass) then alter table organization_subscriptions add constraint organization_subscriptions_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='organization_subscriptions_plan_id_fkey' and conrelid='public.organization_subscriptions'::regclass) then alter table organization_subscriptions add constraint organization_subscriptions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES subscription_plans(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_provider_accounts_organization_id_fkey' and conrelid='public.payment_provider_accounts'::regclass) then alter table payment_provider_accounts add constraint payment_provider_accounts_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_provider_events_organization_id_fkey' and conrelid='public.payment_provider_events'::regclass) then alter table payment_provider_events add constraint payment_provider_events_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_refunds_organization_id_fkey' and conrelid='public.payment_refunds'::regclass) then alter table payment_refunds add constraint payment_refunds_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_refunds_payment_id_fkey' and conrelid='public.payment_refunds'::regclass) then alter table payment_refunds add constraint payment_refunds_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_refunds_sale_return_id_fkey' and conrelid='public.payment_refunds'::regclass) then alter table payment_refunds add constraint payment_refunds_sale_return_id_fkey FOREIGN KEY (sale_return_id) REFERENCES sales_returns(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_schedules_organization_id_fkey' and conrelid='public.payment_schedules'::regclass) then alter table payment_schedules add constraint payment_schedules_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_schedules_sale_id_fkey' and conrelid='public.payment_schedules'::regclass) then alter table payment_schedules add constraint payment_schedules_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payment_webhook_events_organization_id_fkey' and conrelid='public.payment_webhook_events'::regclass) then alter table payment_webhook_events add constraint payment_webhook_events_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payments_client_id_fkey' and conrelid='public.payments'::regclass) then alter table payments add constraint payments_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payments_organization_id_fkey' and conrelid='public.payments'::regclass) then alter table payments add constraint payments_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payments_prospecteur_id_fkey' and conrelid='public.payments'::regclass) then alter table payments add constraint payments_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payments_sale_id_fkey' and conrelid='public.payments'::regclass) then alter table payments add constraint payments_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='payments_schedule_id_fkey' and conrelid='public.payments'::regclass) then alter table payments add constraint payments_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES payment_schedules(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_activities_organization_id_fkey' and conrelid='public.prospect_activities'::regclass) then alter table prospect_activities add constraint prospect_activities_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_activities_prospect_id_fkey' and conrelid='public.prospect_activities'::regclass) then alter table prospect_activities add constraint prospect_activities_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_activities_prospecteur_id_fkey' and conrelid='public.prospect_activities'::regclass) then alter table prospect_activities add constraint prospect_activities_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_assignments_organization_id_fkey' and conrelid='public.prospect_assignments'::regclass) then alter table prospect_assignments add constraint prospect_assignments_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_assignments_prospect_id_fkey' and conrelid='public.prospect_assignments'::regclass) then alter table prospect_assignments add constraint prospect_assignments_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_assignments_prospecteur_id_fkey' and conrelid='public.prospect_assignments'::regclass) then alter table prospect_assignments add constraint prospect_assignments_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_followups_organization_id_fkey' and conrelid='public.prospect_followups'::regclass) then alter table prospect_followups add constraint prospect_followups_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_followups_prospect_id_fkey' and conrelid='public.prospect_followups'::regclass) then alter table prospect_followups add constraint prospect_followups_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_followups_prospecteur_id_fkey' and conrelid='public.prospect_followups'::regclass) then alter table prospect_followups add constraint prospect_followups_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_status_history_organization_id_fkey' and conrelid='public.prospect_status_history'::regclass) then alter table prospect_status_history add constraint prospect_status_history_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospect_status_history_prospect_id_fkey' and conrelid='public.prospect_status_history'::regclass) then alter table prospect_status_history add constraint prospect_status_history_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospecteur_stocks_article_id_fkey' and conrelid='public.prospecteur_stocks'::regclass) then alter table prospecteur_stocks add constraint prospecteur_stocks_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospecteur_stocks_organization_id_fkey' and conrelid='public.prospecteur_stocks'::regclass) then alter table prospecteur_stocks add constraint prospecteur_stocks_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospecteur_stocks_prospecteur_id_fkey' and conrelid='public.prospecteur_stocks'::regclass) then alter table prospecteur_stocks add constraint prospecteur_stocks_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospecteurs_organization_id_fkey' and conrelid='public.prospecteurs'::regclass) then alter table prospecteurs add constraint prospecteurs_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospects_client_id_fkey' and conrelid='public.prospects'::regclass) then alter table prospects add constraint prospects_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospects_organization_id_fkey' and conrelid='public.prospects'::regclass) then alter table prospects add constraint prospects_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospects_portfolio_id_fkey' and conrelid='public.prospects'::regclass) then alter table prospects add constraint prospects_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES client_portfolios(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='prospects_prospecteur_id_fkey' and conrelid='public.prospects'::regclass) then alter table prospects add constraint prospects_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='purchase_order_items_article_id_fkey' and conrelid='public.purchase_order_items'::regclass) then alter table purchase_order_items add constraint purchase_order_items_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='purchase_order_items_organization_id_fkey' and conrelid='public.purchase_order_items'::regclass) then alter table purchase_order_items add constraint purchase_order_items_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='purchase_order_items_purchase_order_id_fkey' and conrelid='public.purchase_order_items'::regclass) then alter table purchase_order_items add constraint purchase_order_items_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='purchase_orders_organization_id_fkey' and conrelid='public.purchase_orders'::regclass) then alter table purchase_orders add constraint purchase_orders_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='purchase_orders_supplier_id_fkey' and conrelid='public.purchase_orders'::regclass) then alter table purchase_orders add constraint purchase_orders_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sale_items_article_id_fkey' and conrelid='public.sale_items'::regclass) then alter table sale_items add constraint sale_items_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sale_items_organization_id_fkey' and conrelid='public.sale_items'::regclass) then alter table sale_items add constraint sale_items_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sale_items_sale_id_fkey' and conrelid='public.sale_items'::regclass) then alter table sale_items add constraint sale_items_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_return_items_article_id_fkey' and conrelid='public.sales_return_items'::regclass) then alter table sales_return_items add constraint sales_return_items_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_return_items_organization_id_fkey' and conrelid='public.sales_return_items'::regclass) then alter table sales_return_items add constraint sales_return_items_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_return_items_return_id_fkey' and conrelid='public.sales_return_items'::regclass) then alter table sales_return_items add constraint sales_return_items_return_id_fkey FOREIGN KEY (return_id) REFERENCES sales_returns(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_return_items_serial_number_id_fkey' and conrelid='public.sales_return_items'::regclass) then alter table sales_return_items add constraint sales_return_items_serial_number_id_fkey FOREIGN KEY (serial_number_id) REFERENCES serial_numbers(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_returns_client_id_fkey' and conrelid='public.sales_returns'::regclass) then alter table sales_returns add constraint sales_returns_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_returns_organization_id_fkey' and conrelid='public.sales_returns'::regclass) then alter table sales_returns add constraint sales_returns_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_returns_sale_id_fkey' and conrelid='public.sales_returns'::regclass) then alter table sales_returns add constraint sales_returns_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_article_id_fkey' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_client_id_fkey' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_organization_id_fkey' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='sales_prospecteur_id_fkey' and conrelid='public.sales'::regclass) then alter table sales add constraint sales_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='serial_numbers_article_id_fkey' and conrelid='public.serial_numbers'::regclass) then alter table serial_numbers add constraint serial_numbers_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='serial_numbers_client_id_fkey' and conrelid='public.serial_numbers'::regclass) then alter table serial_numbers add constraint serial_numbers_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='serial_numbers_organization_id_fkey' and conrelid='public.serial_numbers'::regclass) then alter table serial_numbers add constraint serial_numbers_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='serial_numbers_purchase_order_id_fkey' and conrelid='public.serial_numbers'::regclass) then alter table serial_numbers add constraint serial_numbers_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='serial_numbers_sale_id_fkey' and conrelid='public.serial_numbers'::regclass) then alter table serial_numbers add constraint serial_numbers_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_movements_article_id_fkey' and conrelid='public.stock_movements'::regclass) then alter table stock_movements add constraint stock_movements_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_movements_organization_id_fkey' and conrelid='public.stock_movements'::regclass) then alter table stock_movements add constraint stock_movements_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_movements_prospecteur_id_fkey' and conrelid='public.stock_movements'::regclass) then alter table stock_movements add constraint stock_movements_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_transfer_items_article_id_fkey' and conrelid='public.stock_transfer_items'::regclass) then alter table stock_transfer_items add constraint stock_transfer_items_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_transfer_items_organization_id_fkey' and conrelid='public.stock_transfer_items'::regclass) then alter table stock_transfer_items add constraint stock_transfer_items_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_transfer_items_transfer_id_fkey' and conrelid='public.stock_transfer_items'::regclass) then alter table stock_transfer_items add constraint stock_transfer_items_transfer_id_fkey FOREIGN KEY (transfer_id) REFERENCES stock_transfers(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_transfers_destination_warehouse_id_fkey' and conrelid='public.stock_transfers'::regclass) then alter table stock_transfers add constraint stock_transfers_destination_warehouse_id_fkey FOREIGN KEY (destination_warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_transfers_organization_id_fkey' and conrelid='public.stock_transfers'::regclass) then alter table stock_transfers add constraint stock_transfers_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stock_transfers_source_warehouse_id_fkey' and conrelid='public.stock_transfers'::regclass) then alter table stock_transfers add constraint stock_transfers_source_warehouse_id_fkey FOREIGN KEY (source_warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stocks_article_id_fkey' and conrelid='public.stocks'::regclass) then alter table stocks add constraint stocks_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='stocks_organization_id_fkey' and conrelid='public.stocks'::regclass) then alter table stocks add constraint stocks_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_events_organization_id_fkey' and conrelid='public.subscription_events'::regclass) then alter table subscription_events add constraint subscription_events_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_events_subscription_id_fkey' and conrelid='public.subscription_events'::regclass) then alter table subscription_events add constraint subscription_events_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES organization_subscriptions(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_limits_plan_id_fkey' and conrelid='public.subscription_limits'::regclass) then alter table subscription_limits add constraint subscription_limits_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES subscription_plans(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_payments_organization_id_fkey' and conrelid='public.subscription_payments'::regclass) then alter table subscription_payments add constraint subscription_payments_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='subscription_payments_subscription_id_fkey' and conrelid='public.subscription_payments'::regclass) then alter table subscription_payments add constraint subscription_payments_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES organization_subscriptions(id) ON DELETE SET NULL; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='supplier_payments_organization_id_fkey' and conrelid='public.supplier_payments'::regclass) then alter table supplier_payments add constraint supplier_payments_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='supplier_payments_purchase_order_id_fkey' and conrelid='public.supplier_payments'::regclass) then alter table supplier_payments add constraint supplier_payments_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='supplier_payments_supplier_id_fkey' and conrelid='public.supplier_payments'::regclass) then alter table supplier_payments add constraint supplier_payments_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='suppliers_organization_id_fkey' and conrelid='public.suppliers'::regclass) then alter table suppliers add constraint suppliers_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='user_permissions_permission_id_fkey' and conrelid='public.user_permissions'::regclass) then alter table user_permissions add constraint user_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='warehouse_inventory_article_id_fkey' and conrelid='public.warehouse_inventory'::regclass) then alter table warehouse_inventory add constraint warehouse_inventory_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='warehouse_inventory_organization_id_fkey' and conrelid='public.warehouse_inventory'::regclass) then alter table warehouse_inventory add constraint warehouse_inventory_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='warehouse_inventory_warehouse_id_fkey' and conrelid='public.warehouse_inventory'::regclass) then alter table warehouse_inventory add constraint warehouse_inventory_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='warehouse_users_warehouse_id_fkey' and conrelid='public.warehouse_users'::regclass) then alter table warehouse_users add constraint warehouse_users_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE; end if; end $ddl$;
do $ddl$ begin if not exists (select 1 from pg_constraint where conname='warehouses_organization_id_fkey' and conrelid='public.warehouses'::regclass) then alter table warehouses add constraint warehouses_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE; end if; end $ddl$;

CREATE INDEX IF NOT EXISTS idx_articles_org ON public.articles USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_audit_events_entity ON public.audit_events USING btree (entity_type, entity_id)
CREATE INDEX IF NOT EXISTS idx_audit_events_org ON public.audit_events USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_audit_events_user ON public.audit_events USING btree (user_id)
CREATE INDEX IF NOT EXISTS idx_client_portfolios_owner ON public.client_portfolios USING btree (owner_type, owner_user_id)
CREATE INDEX IF NOT EXISTS idx_clients_activity ON public.clients USING btree (organization_id, last_activity_at) WHERE (archived_at IS NULL)
CREATE INDEX IF NOT EXISTS idx_clients_archived ON public.clients USING btree (organization_id, archived_at)
CREATE INDEX IF NOT EXISTS idx_clients_last_activity ON public.clients USING btree (organization_id, last_activity_at)
CREATE INDEX IF NOT EXISTS idx_clients_last_activity_at ON public.clients USING btree (last_activity_at)
CREATE INDEX IF NOT EXISTS idx_clients_org ON public.clients USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_clients_org_phone ON public.clients USING btree (organization_id, phone)
CREATE INDEX IF NOT EXISTS idx_clients_org_prospecteur ON public.clients USING btree (organization_id, prospecteur_id)
CREATE INDEX IF NOT EXISTS idx_clients_org_status ON public.clients USING btree (organization_id, status)
CREATE INDEX IF NOT EXISTS idx_clients_portfolio_id ON public.clients USING btree (portfolio_id)
CREATE INDEX IF NOT EXISTS idx_clients_prospecteur ON public.clients USING btree (prospecteur_id)
CREATE INDEX IF NOT EXISTS idx_commissions_org ON public.commissions USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_commissions_prospecteur ON public.commissions USING btree (prospecteur_id)
CREATE INDEX IF NOT EXISTS idx_commissions_sale ON public.commissions USING btree (organization_id, sale_id)
CREATE INDEX IF NOT EXISTS idx_daily_tokens_date ON public.daily_tokens USING btree (token_date)
CREATE INDEX IF NOT EXISTS idx_daily_tokens_org ON public.daily_tokens USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_field_visits_prospect ON public.field_visits USING btree (organization_id, prospect_id)
CREATE INDEX IF NOT EXISTS idx_goods_receipt_items_receipt ON public.goods_receipt_items USING btree (receipt_id)
CREATE INDEX IF NOT EXISTS idx_goods_receipts_org ON public.goods_receipts USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_clients_activity ON public.clients USING btree (organization_id, last_activity_at)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_commissions_report_date ON public.commissions USING btree (organization_id, created_at)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_commissions_status_prospecteur ON public.commissions USING btree (organization_id, prospecteur_id, status)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_org_subscriptions_expiry ON public.organization_subscriptions USING btree (organization_id, expires_at) WHERE (status = ANY (ARRAY['trial'::text, 'active'::text, 'past_due'::text]))
CREATE INDEX IF NOT EXISTS idx_jdvcrm_payment_schedules_late_due ON public.payment_schedules USING btree (organization_id, due_date) WHERE (status = ANY (ARRAY['pending'::text, 'partial'::text, 'late'::text]))
CREATE INDEX IF NOT EXISTS idx_jdvcrm_payments_client ON public.payments USING btree (client_id)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_payments_report_date ON public.payments USING btree (organization_id, payment_date)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_payments_sale ON public.payments USING btree (sale_id)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_payments_sale_status_date ON public.payments USING btree (sale_id, status, payment_date DESC)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_payments_schedule_status ON public.payments USING btree (schedule_id, status)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_prospecteur_stocks_org_prospecteur ON public.prospecteur_stocks USING btree (organization_id, prospecteur_id)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_prospects_activity ON public.prospects USING btree (organization_id, last_contact_at)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_prospects_followup ON public.prospects USING btree (organization_id, last_follow_up_at)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_sale_items_sale ON public.sale_items USING btree (sale_id, organization_id)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_sales_client ON public.sales USING btree (organization_id, client_id)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_sales_org_prospecteur_status ON public.sales USING btree (organization_id, prospecteur_id, status, sale_date DESC)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_sales_prospecteur ON public.sales USING btree (organization_id, prospecteur_id)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_sales_report_date ON public.sales USING btree (organization_id, sale_date)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_schedule_due ON public.payment_schedules USING btree (organization_id, due_date, status)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_schedules_sale_due ON public.payment_schedules USING btree (sale_id, due_date, status)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_stock_movements_article ON public.stock_movements USING btree (organization_id, article_id, created_at)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_stock_movements_org_article_created ON public.stock_movements USING btree (organization_id, article_id, created_at DESC)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_stock_movements_prospecteur ON public.stock_movements USING btree (organization_id, prospecteur_id, created_at DESC) WHERE (prospecteur_id IS NOT NULL)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_stock_movements_reference ON public.stock_movements USING btree (reference_type, reference_id, article_id, movement_type)
CREATE INDEX IF NOT EXISTS idx_jdvcrm_stocks_org_article ON public.stocks USING btree (organization_id, article_id)
CREATE INDEX IF NOT EXISTS idx_login_security_created ON public.login_security_events USING btree (created_at)
CREATE INDEX IF NOT EXISTS idx_login_security_user ON public.login_security_events USING btree (user_id)
CREATE UNIQUE INDEX IF NOT EXISTS idx_org_personalization_org_unique ON public.organization_personalization USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_organization_subscriptions_expires ON public.organization_subscriptions USING btree (expires_at)
CREATE INDEX IF NOT EXISTS idx_organization_subscriptions_org ON public.organization_subscriptions USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_organization_subscriptions_status ON public.organization_subscriptions USING btree (status)
CREATE INDEX IF NOT EXISTS idx_payment_provider_accounts_org ON public.payment_provider_accounts USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_payment_provider_accounts_provider ON public.payment_provider_accounts USING btree (provider)
CREATE INDEX IF NOT EXISTS idx_payment_provider_events_org ON public.payment_provider_events USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_payment_provider_events_org_created ON public.payment_provider_events USING btree (organization_id, created_at DESC)
CREATE INDEX IF NOT EXISTS idx_payment_schedules_due ON public.payment_schedules USING btree (due_date)
CREATE INDEX IF NOT EXISTS idx_payment_schedules_sale ON public.payment_schedules USING btree (sale_id)
CREATE INDEX IF NOT EXISTS idx_payment_schedules_status ON public.payment_schedules USING btree (organization_id, status)
CREATE INDEX IF NOT EXISTS idx_payment_webhook_events_external ON public.payment_webhook_events USING btree (external_event_id)
CREATE INDEX IF NOT EXISTS idx_payment_webhook_events_org ON public.payment_webhook_events USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_payment_webhook_events_org_created ON public.payment_webhook_events USING btree (organization_id, created_at DESC)
CREATE INDEX IF NOT EXISTS idx_payment_webhook_events_status ON public.payment_webhook_events USING btree (status)
CREATE UNIQUE INDEX IF NOT EXISTS idx_payment_webhook_events_unique_external ON public.payment_webhook_events USING btree (provider, external_event_id) WHERE (external_event_id IS NOT NULL)
CREATE INDEX IF NOT EXISTS idx_payments_date ON public.payments USING btree (payment_date)
CREATE INDEX IF NOT EXISTS idx_payments_merchant_reference ON public.payments USING btree (merchant_reference)
CREATE INDEX IF NOT EXISTS idx_payments_org ON public.payments USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_payments_org_client ON public.payments USING btree (organization_id, client_id)
CREATE INDEX IF NOT EXISTS idx_payments_org_sale ON public.payments USING btree (organization_id, sale_id)
CREATE INDEX IF NOT EXISTS idx_payments_provider_transaction ON public.payments USING btree (provider_transaction_id)
CREATE INDEX IF NOT EXISTS idx_prospect_activities_prospect ON public.prospect_activities USING btree (prospect_id)
CREATE INDEX IF NOT EXISTS idx_prospect_followups_date ON public.prospect_followups USING btree (scheduled_at)
CREATE INDEX IF NOT EXISTS idx_prospect_status_history_prospect ON public.prospect_status_history USING btree (prospect_id)
CREATE INDEX IF NOT EXISTS idx_prospecteur_stocks ON public.prospecteur_stocks USING btree (organization_id, prospecteur_id, article_id)
CREATE INDEX IF NOT EXISTS idx_prospecteur_stocks_prospecteur ON public.prospecteur_stocks USING btree (prospecteur_id)
CREATE INDEX IF NOT EXISTS idx_prospecteurs_org ON public.prospecteurs USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_prospecteurs_org_status ON public.prospecteurs USING btree (organization_id, status)
CREATE INDEX IF NOT EXISTS idx_prospecteurs_user ON public.prospecteurs USING btree (user_id)
CREATE INDEX IF NOT EXISTS idx_prospects_first_name ON public.prospects USING btree (first_name)
CREATE INDEX IF NOT EXISTS idx_prospects_follow_up ON public.prospects USING btree (organization_id, next_follow_up_at)
CREATE INDEX IF NOT EXISTS idx_prospects_followup ON public.prospects USING btree (next_follow_up_at)
CREATE INDEX IF NOT EXISTS idx_prospects_last_contact ON public.prospects USING btree (last_contact_at)
CREATE INDEX IF NOT EXISTS idx_prospects_last_name ON public.prospects USING btree (last_name)
CREATE INDEX IF NOT EXISTS idx_prospects_next_follow_up ON public.prospects USING btree (organization_id, next_follow_up_at)
CREATE INDEX IF NOT EXISTS idx_prospects_next_follow_up_at ON public.prospects USING btree (next_follow_up_at)
CREATE INDEX IF NOT EXISTS idx_prospects_org ON public.prospects USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_prospects_org_phone ON public.prospects USING btree (organization_id, phone)
CREATE INDEX IF NOT EXISTS idx_prospects_org_prospecteur ON public.prospects USING btree (organization_id, prospecteur_id)
CREATE INDEX IF NOT EXISTS idx_prospects_org_temperature ON public.prospects USING btree (organization_id, temperature)
CREATE INDEX IF NOT EXISTS idx_prospects_organization_category ON public.prospects USING btree (organization_id, category)
CREATE INDEX IF NOT EXISTS idx_prospects_organization_id ON public.prospects USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_prospects_organization_phone ON public.prospects USING btree (organization_id, phone)
CREATE INDEX IF NOT EXISTS idx_prospects_organization_temperature ON public.prospects USING btree (organization_id, temperature)
CREATE INDEX IF NOT EXISTS idx_prospects_phone ON public.prospects USING btree (phone) WHERE (phone IS NOT NULL)
CREATE INDEX IF NOT EXISTS idx_prospects_portfolio_id ON public.prospects USING btree (portfolio_id)
CREATE INDEX IF NOT EXISTS idx_prospects_prospecteur ON public.prospects USING btree (prospecteur_id)
CREATE INDEX IF NOT EXISTS idx_prospects_prospecteur_id ON public.prospects USING btree (prospecteur_id)
CREATE INDEX IF NOT EXISTS idx_prospects_purchase_date ON public.prospects USING btree (organization_id, purchase_date_planned)
CREATE INDEX IF NOT EXISTS idx_prospects_purchase_date_planned ON public.prospects USING btree (purchase_date_planned)
CREATE INDEX IF NOT EXISTS idx_prospects_status ON public.prospects USING btree (status)
CREATE INDEX IF NOT EXISTS idx_prospects_temperature ON public.prospects USING btree (temperature)
CREATE INDEX IF NOT EXISTS idx_purchase_order_items_order ON public.purchase_order_items USING btree (purchase_order_id)
CREATE INDEX IF NOT EXISTS idx_purchase_orders_org ON public.purchase_orders USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_purchase_orders_supplier ON public.purchase_orders USING btree (supplier_id)
CREATE INDEX IF NOT EXISTS idx_sale_items_article ON public.sale_items USING btree (article_id)
CREATE INDEX IF NOT EXISTS idx_sale_items_org ON public.sale_items USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_sale_items_sale ON public.sale_items USING btree (sale_id)
CREATE INDEX IF NOT EXISTS idx_sales_client ON public.sales USING btree (client_id)
CREATE INDEX IF NOT EXISTS idx_sales_date ON public.sales USING btree (sale_date)
CREATE INDEX IF NOT EXISTS idx_sales_deadline ON public.sales USING btree (organization_id, deadline_date) WHERE (deadline_date IS NOT NULL)
CREATE INDEX IF NOT EXISTS idx_sales_org ON public.sales USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_sales_org_prospecteur ON public.sales USING btree (organization_id, prospecteur_id)
CREATE INDEX IF NOT EXISTS idx_sales_prospecteur ON public.sales USING btree (prospecteur_id)
CREATE INDEX IF NOT EXISTS idx_sales_returns_sale ON public.sales_returns USING btree (sale_id)
CREATE INDEX IF NOT EXISTS idx_sales_status ON public.sales USING btree (organization_id, status)
CREATE INDEX IF NOT EXISTS idx_schedules_due ON public.payment_schedules USING btree (sale_id, due_date)
CREATE INDEX IF NOT EXISTS idx_serial_numbers_article ON public.serial_numbers USING btree (article_id)
CREATE INDEX IF NOT EXISTS idx_serial_numbers_org ON public.serial_numbers USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_stock_movements_article ON public.stock_movements USING btree (article_id)
CREATE INDEX IF NOT EXISTS idx_stock_movements_org ON public.stock_movements USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_stock_movements_prospecteur ON public.stock_movements USING btree (organization_id, prospecteur_id)
CREATE INDEX IF NOT EXISTS idx_stock_transfer_items_transfer ON public.stock_transfer_items USING btree (transfer_id)
CREATE INDEX IF NOT EXISTS idx_stock_transfers_org ON public.stock_transfers USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_stocks_article ON public.stocks USING btree (article_id)
CREATE INDEX IF NOT EXISTS idx_stocks_org ON public.stocks USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_subscription_events_org_created ON public.subscription_events USING btree (organization_id, created_at DESC)
CREATE INDEX IF NOT EXISTS idx_subscription_payments_org_created ON public.subscription_payments USING btree (organization_id, created_at DESC)
CREATE INDEX IF NOT EXISTS idx_subscription_plans_active_code ON public.subscription_plans USING btree (code) WHERE (active = true)
CREATE INDEX IF NOT EXISTS idx_super_admin_modules_code ON public.super_admin_modules USING btree (module_code)
CREATE INDEX IF NOT EXISTS idx_super_admin_modules_user ON public.super_admin_modules USING btree (user_id)
CREATE INDEX IF NOT EXISTS idx_supplier_payments_org ON public.supplier_payments USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_supplier_payments_supplier ON public.supplier_payments USING btree (supplier_id)
CREATE INDEX IF NOT EXISTS idx_suppliers_org ON public.suppliers USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_tokens_org_date ON public.daily_tokens USING btree (organization_id, token_date)
CREATE INDEX IF NOT EXISTS idx_visits_org ON public.field_visits USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_visits_prospecteur ON public.field_visits USING btree (prospecteur_id)
CREATE INDEX IF NOT EXISTS idx_warehouse_inventory_org ON public.warehouse_inventory USING btree (organization_id)
CREATE INDEX IF NOT EXISTS idx_warehouses_org ON public.warehouses USING btree (organization_id)
CREATE INDEX IF NOT EXISTS ix_jdvcrm_clients_org_prospecteur ON public.clients USING btree (organization_id, prospecteur_id) WHERE (archived_at IS NULL)
CREATE INDEX IF NOT EXISTS ix_jdvcrm_field_visits_prospecteur_date ON public.field_visits USING btree (organization_id, prospecteur_id, visit_date DESC)
CREATE INDEX IF NOT EXISTS ix_jdvcrm_prospect_activities_portfolio ON public.prospect_activities USING btree (organization_id, prospect_id, activity_date DESC)
CREATE INDEX IF NOT EXISTS ix_jdvcrm_prospect_assignments_active ON public.prospect_assignments USING btree (organization_id, prospect_id) WHERE (active = true)
CREATE INDEX IF NOT EXISTS ix_jdvcrm_prospect_followups_due ON public.prospect_followups USING btree (organization_id, scheduled_at) WHERE (status = 'pending'::text)
CREATE INDEX IF NOT EXISTS ix_jdvcrm_prospects_contact ON public.prospects USING btree (organization_id, last_contact_at) WHERE (archived_at IS NULL)
CREATE INDEX IF NOT EXISTS ix_jdvcrm_prospects_followup ON public.prospects USING btree (organization_id, next_follow_up_at) WHERE (archived_at IS NULL)
CREATE INDEX IF NOT EXISTS ix_jdvcrm_prospects_org_prospecteur ON public.prospects USING btree (organization_id, prospecteur_id) WHERE (archived_at IS NULL)
CREATE INDEX IF NOT EXISTS ix_jdvcrm_status_history_prospect ON public.prospect_status_history USING btree (organization_id, prospect_id, created_at DESC)
CREATE UNIQUE INDEX IF NOT EXISTS uq_jdvcrm_org_active_subscription ON public.organization_subscriptions USING btree (organization_id) WHERE (status = ANY (ARRAY['pending'::text, 'trial'::text, 'active'::text, 'past_due'::text]))
CREATE UNIQUE INDEX IF NOT EXISTS uq_jdvcrm_provider_merchant_reference ON public.payments USING btree (organization_id, provider, merchant_reference) WHERE ((merchant_reference IS NOT NULL) AND (merchant_reference <> ''::text))
CREATE UNIQUE INDEX IF NOT EXISTS uq_jdvcrm_provider_transaction ON public.payments USING btree (organization_id, provider, provider_transaction_id) WHERE ((provider_transaction_id IS NOT NULL) AND (provider_transaction_id <> ''::text))
CREATE UNIQUE INDEX IF NOT EXISTS uq_jdvcrm_schedule_sale_installment ON public.payment_schedules USING btree (sale_id, installment_number)
CREATE UNIQUE INDEX IF NOT EXISTS uq_jdvcrm_stock_return_movement ON public.stock_movements USING btree (reference_type, reference_id, article_id, movement_type) WHERE ((reference_type = 'sale_return'::text) AND (reference_id IS NOT NULL) AND (movement_type = 'return'::text))
CREATE UNIQUE INDEX IF NOT EXISTS uq_jdvcrm_stock_sale_movement ON public.stock_movements USING btree (reference_type, reference_id, movement_type) WHERE ((reference_type = 'sale'::text) AND (reference_id IS NOT NULL))
CREATE UNIQUE INDEX IF NOT EXISTS uq_jdvcrm_transfer_in_movement ON public.stock_movements USING btree (reference_type, reference_id, movement_type) WHERE ((reference_type = 'stock_transfer'::text) AND (reference_id IS NOT NULL) AND (movement_type = 'transfer_in'::text))
CREATE UNIQUE INDEX IF NOT EXISTS uq_jdvcrm_transfer_out_movement ON public.stock_movements USING btree (reference_type, reference_id, movement_type) WHERE ((reference_type = 'stock_transfer'::text) AND (reference_id IS NOT NULL) AND (movement_type = 'transfer_out'::text))
CREATE UNIQUE INDEX IF NOT EXISTS uq_payment_provider_events_provider_event_id ON public.payment_provider_events USING btree (provider, provider_event_id) WHERE (provider_event_id IS NOT NULL)
CREATE UNIQUE INDEX IF NOT EXISTS uq_payment_schedules_sale_installment ON public.payment_schedules USING btree (sale_id, installment_number)
CREATE UNIQUE INDEX IF NOT EXISTS uq_payment_webhook_events_provider_external_event_id ON public.payment_webhook_events USING btree (provider, external_event_id) WHERE (external_event_id IS NOT NULL)
CREATE UNIQUE INDEX IF NOT EXISTS uq_subscription_limits_plan_resource ON public.subscription_limits USING btree (plan_id, resource_code)
CREATE UNIQUE INDEX IF NOT EXISTS uq_subscription_payments_provider_reference ON public.subscription_payments USING btree (provider, provider_reference) WHERE (provider_reference IS NOT NULL)
CREATE UNIQUE INDEX IF NOT EXISTS ux_jdvcrm_active_serial_assignment ON public.article_serial_assignments USING btree (serial_number_id) WHERE (active = true)
CREATE UNIQUE INDEX IF NOT EXISTS ux_jdvcrm_commission_sale_prospecteur ON public.commissions USING btree (sale_id, prospecteur_id) WHERE ((sale_id IS NOT NULL) AND (prospecteur_id IS NOT NULL))
CREATE UNIQUE INDEX IF NOT EXISTS ux_jdvcrm_serial_number_normalized ON public.serial_numbers USING btree (organization_id, lower(TRIM(BOTH FROM serial_number)))
CREATE UNIQUE INDEX IF NOT EXISTS ux_payment_refunds_payment_processed ON public.payment_refunds USING btree (payment_id) WHERE (status = 'processed'::text)

alter table public.article_categories enable row level security;
alter table public.article_serial_assignments enable row level security;
alter table public.articles enable row level security;
alter table public.audit_events enable row level security;
alter table public.call_center_tasks enable row level security;
alter table public.call_logs enable row level security;
alter table public.client_portfolios enable row level security;
alter table public.clients enable row level security;
alter table public.commissions enable row level security;
alter table public.company_settings enable row level security;
alter table public.daily_tokens enable row level security;
alter table public.document_sequences enable row level security;
alter table public.document_templates enable row level security;
alter table public.documents enable row level security;
alter table public.field_visits enable row level security;
alter table public.follow_up_reminders enable row level security;
alter table public.goods_receipt_items enable row level security;
alter table public.goods_receipts enable row level security;
alter table public.login_security_events enable row level security;
alter table public.notification_events enable row level security;
alter table public.notification_preferences enable row level security;
alter table public.organization_personalization enable row level security;
alter table public.organization_settings enable row level security;
alter table public.organization_subscriptions enable row level security;
alter table public.payment_provider_accounts enable row level security;
alter table public.payment_provider_events enable row level security;
alter table public.payment_refunds enable row level security;
alter table public.payment_schedules enable row level security;
alter table public.payment_webhook_events enable row level security;
alter table public.payments enable row level security;
alter table public.prospect_activities enable row level security;
alter table public.prospect_assignments enable row level security;
alter table public.prospect_followups enable row level security;
alter table public.prospect_status_history enable row level security;
alter table public.prospecteur_stocks enable row level security;
alter table public.prospecteurs enable row level security;
alter table public.prospects enable row level security;
alter table public.purchase_order_items enable row level security;
alter table public.purchase_orders enable row level security;
alter table public.sale_items enable row level security;
alter table public.sales enable row level security;
alter table public.sales_return_items enable row level security;
alter table public.sales_returns enable row level security;
alter table public.serial_numbers enable row level security;
alter table public.stock_movements enable row level security;
alter table public.stock_transfer_items enable row level security;
alter table public.stock_transfers enable row level security;
alter table public.stocks enable row level security;
alter table public.subscription_events enable row level security;
alter table public.subscription_limits enable row level security;
alter table public.subscription_payments enable row level security;
alter table public.subscription_plans enable row level security;
alter table public.super_admin_modules enable row level security;
alter table public.supplier_payments enable row level security;
alter table public.suppliers enable row level security;
alter table public.user_permissions enable row level security;
alter table public.user_settings enable row level security;
alter table public.warehouse_inventory enable row level security;
alter table public.warehouse_users enable row level security;
alter table public.warehouses enable row level security;
alter table public.rate_limits enable row level security;

drop policy if exists jdv_global_crm_member_read on public.article_categories; create policy jdv_global_crm_member_read on public.article_categories for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.article_categories; create policy jdv_global_crm_admin_insert on public.article_categories for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.article_categories; create policy jdv_global_crm_admin_update on public.article_categories for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.article_categories; create policy jdv_global_crm_admin_delete on public.article_categories for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.article_serial_assignments; create policy jdv_global_crm_member_read on public.article_serial_assignments for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.article_serial_assignments; create policy jdv_global_crm_admin_insert on public.article_serial_assignments for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.article_serial_assignments; create policy jdv_global_crm_admin_update on public.article_serial_assignments for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.article_serial_assignments; create policy jdv_global_crm_admin_delete on public.article_serial_assignments for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.articles; create policy jdv_global_crm_member_read on public.articles for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.articles; create policy jdv_global_crm_admin_insert on public.articles for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.articles; create policy jdv_global_crm_admin_update on public.articles for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.articles; create policy jdv_global_crm_admin_delete on public.articles for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.audit_events; create policy jdv_global_crm_member_read on public.audit_events for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.audit_events; create policy jdv_global_crm_admin_insert on public.audit_events for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.audit_events; create policy jdv_global_crm_admin_update on public.audit_events for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.audit_events; create policy jdv_global_crm_admin_delete on public.audit_events for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.call_center_tasks; create policy jdv_global_crm_admin_insert on public.call_center_tasks for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.call_center_tasks; create policy jdv_global_crm_admin_update on public.call_center_tasks for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.call_center_tasks; create policy jdv_global_crm_admin_delete on public.call_center_tasks for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.call_logs; create policy jdv_global_crm_admin_insert on public.call_logs for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.call_logs; create policy jdv_global_crm_admin_update on public.call_logs for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.call_logs; create policy jdv_global_crm_admin_delete on public.call_logs for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.client_portfolios; create policy jdv_global_crm_admin_insert on public.client_portfolios for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.client_portfolios; create policy jdv_global_crm_admin_update on public.client_portfolios for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.client_portfolios; create policy jdv_global_crm_admin_delete on public.client_portfolios for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.clients; create policy jdv_global_crm_admin_insert on public.clients for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.clients; create policy jdv_global_crm_admin_update on public.clients for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.clients; create policy jdv_global_crm_admin_delete on public.clients for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.commissions; create policy jdv_global_crm_admin_insert on public.commissions for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.commissions; create policy jdv_global_crm_admin_update on public.commissions for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.commissions; create policy jdv_global_crm_admin_delete on public.commissions for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.company_settings; create policy jdv_global_crm_member_read on public.company_settings for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.company_settings; create policy jdv_global_crm_admin_insert on public.company_settings for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.company_settings; create policy jdv_global_crm_admin_update on public.company_settings for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.company_settings; create policy jdv_global_crm_admin_delete on public.company_settings for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.daily_tokens; create policy jdv_global_crm_member_read on public.daily_tokens for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.daily_tokens; create policy jdv_global_crm_admin_insert on public.daily_tokens for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.daily_tokens; create policy jdv_global_crm_admin_update on public.daily_tokens for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.daily_tokens; create policy jdv_global_crm_admin_delete on public.daily_tokens for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.document_sequences; create policy jdv_global_crm_member_read on public.document_sequences for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.document_sequences; create policy jdv_global_crm_admin_insert on public.document_sequences for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.document_sequences; create policy jdv_global_crm_admin_update on public.document_sequences for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.document_sequences; create policy jdv_global_crm_admin_delete on public.document_sequences for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.document_templates; create policy jdv_global_crm_member_read on public.document_templates for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.document_templates; create policy jdv_global_crm_admin_insert on public.document_templates for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.document_templates; create policy jdv_global_crm_admin_update on public.document_templates for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.document_templates; create policy jdv_global_crm_admin_delete on public.document_templates for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.documents; create policy jdv_global_crm_member_read on public.documents for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.documents; create policy jdv_global_crm_admin_insert on public.documents for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.documents; create policy jdv_global_crm_admin_update on public.documents for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.documents; create policy jdv_global_crm_admin_delete on public.documents for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.field_visits; create policy jdv_global_crm_admin_insert on public.field_visits for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.field_visits; create policy jdv_global_crm_admin_update on public.field_visits for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.field_visits; create policy jdv_global_crm_admin_delete on public.field_visits for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.follow_up_reminders; create policy jdv_global_crm_member_read on public.follow_up_reminders for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.follow_up_reminders; create policy jdv_global_crm_admin_insert on public.follow_up_reminders for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.follow_up_reminders; create policy jdv_global_crm_admin_update on public.follow_up_reminders for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.follow_up_reminders; create policy jdv_global_crm_admin_delete on public.follow_up_reminders for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.goods_receipt_items; create policy jdv_global_crm_member_read on public.goods_receipt_items for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.goods_receipt_items; create policy jdv_global_crm_admin_insert on public.goods_receipt_items for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.goods_receipt_items; create policy jdv_global_crm_admin_update on public.goods_receipt_items for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.goods_receipt_items; create policy jdv_global_crm_admin_delete on public.goods_receipt_items for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.goods_receipts; create policy jdv_global_crm_member_read on public.goods_receipts for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.goods_receipts; create policy jdv_global_crm_admin_insert on public.goods_receipts for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.goods_receipts; create policy jdv_global_crm_admin_update on public.goods_receipts for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.goods_receipts; create policy jdv_global_crm_admin_delete on public.goods_receipts for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_user_read on public.login_security_events; create policy jdv_global_crm_user_read on public.login_security_events for select to authenticated using (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_user_insert on public.login_security_events; create policy jdv_global_crm_user_insert on public.login_security_events for insert to authenticated with check (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_user_update on public.login_security_events; create policy jdv_global_crm_user_update on public.login_security_events for update to authenticated using (public.is_super_admin() or user_id=auth.uid()) with check (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_member_read on public.notification_events; create policy jdv_global_crm_member_read on public.notification_events for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.notification_events; create policy jdv_global_crm_admin_insert on public.notification_events for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.notification_events; create policy jdv_global_crm_admin_update on public.notification_events for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.notification_events; create policy jdv_global_crm_admin_delete on public.notification_events for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_user_read on public.notification_preferences; create policy jdv_global_crm_user_read on public.notification_preferences for select to authenticated using (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_user_insert on public.notification_preferences; create policy jdv_global_crm_user_insert on public.notification_preferences for insert to authenticated with check (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_user_update on public.notification_preferences; create policy jdv_global_crm_user_update on public.notification_preferences for update to authenticated using (public.is_super_admin() or user_id=auth.uid()) with check (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_member_read on public.organization_personalization; create policy jdv_global_crm_member_read on public.organization_personalization for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.organization_personalization; create policy jdv_global_crm_admin_insert on public.organization_personalization for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.organization_personalization; create policy jdv_global_crm_admin_update on public.organization_personalization for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.organization_personalization; create policy jdv_global_crm_admin_delete on public.organization_personalization for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.organization_settings; create policy jdv_global_crm_member_read on public.organization_settings for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.organization_settings; create policy jdv_global_crm_admin_insert on public.organization_settings for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.organization_settings; create policy jdv_global_crm_admin_update on public.organization_settings for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.organization_settings; create policy jdv_global_crm_admin_delete on public.organization_settings for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.organization_subscriptions; create policy jdv_global_crm_member_read on public.organization_subscriptions for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.organization_subscriptions; create policy jdv_global_crm_admin_insert on public.organization_subscriptions for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.organization_subscriptions; create policy jdv_global_crm_admin_update on public.organization_subscriptions for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.organization_subscriptions; create policy jdv_global_crm_admin_delete on public.organization_subscriptions for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.payment_provider_accounts; create policy jdv_global_crm_member_read on public.payment_provider_accounts for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.payment_provider_accounts; create policy jdv_global_crm_admin_insert on public.payment_provider_accounts for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.payment_provider_accounts; create policy jdv_global_crm_admin_update on public.payment_provider_accounts for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.payment_provider_accounts; create policy jdv_global_crm_admin_delete on public.payment_provider_accounts for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.payment_provider_events; create policy jdv_global_crm_member_read on public.payment_provider_events for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.payment_provider_events; create policy jdv_global_crm_admin_insert on public.payment_provider_events for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.payment_provider_events; create policy jdv_global_crm_admin_update on public.payment_provider_events for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.payment_provider_events; create policy jdv_global_crm_admin_delete on public.payment_provider_events for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.payment_refunds; create policy jdv_global_crm_member_read on public.payment_refunds for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.payment_refunds; create policy jdv_global_crm_admin_insert on public.payment_refunds for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.payment_refunds; create policy jdv_global_crm_admin_update on public.payment_refunds for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.payment_refunds; create policy jdv_global_crm_admin_delete on public.payment_refunds for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.payment_schedules; create policy jdv_global_crm_admin_insert on public.payment_schedules for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.payment_schedules; create policy jdv_global_crm_admin_update on public.payment_schedules for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.payment_schedules; create policy jdv_global_crm_admin_delete on public.payment_schedules for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.payment_webhook_events; create policy jdv_global_crm_member_read on public.payment_webhook_events for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.payment_webhook_events; create policy jdv_global_crm_admin_insert on public.payment_webhook_events for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.payment_webhook_events; create policy jdv_global_crm_admin_update on public.payment_webhook_events for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.payment_webhook_events; create policy jdv_global_crm_admin_delete on public.payment_webhook_events for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.payments; create policy jdv_global_crm_admin_insert on public.payments for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.payments; create policy jdv_global_crm_admin_update on public.payments for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.payments; create policy jdv_global_crm_admin_delete on public.payments for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.prospect_activities; create policy jdv_global_crm_admin_insert on public.prospect_activities for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.prospect_activities; create policy jdv_global_crm_admin_update on public.prospect_activities for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.prospect_activities; create policy jdv_global_crm_admin_delete on public.prospect_activities for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.prospect_assignments; create policy jdv_global_crm_admin_insert on public.prospect_assignments for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.prospect_assignments; create policy jdv_global_crm_admin_update on public.prospect_assignments for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.prospect_assignments; create policy jdv_global_crm_admin_delete on public.prospect_assignments for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.prospect_followups; create policy jdv_global_crm_admin_insert on public.prospect_followups for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.prospect_followups; create policy jdv_global_crm_admin_update on public.prospect_followups for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.prospect_followups; create policy jdv_global_crm_admin_delete on public.prospect_followups for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.prospect_status_history; create policy jdv_global_crm_admin_insert on public.prospect_status_history for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.prospect_status_history; create policy jdv_global_crm_admin_update on public.prospect_status_history for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.prospect_status_history; create policy jdv_global_crm_admin_delete on public.prospect_status_history for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.prospecteur_stocks; create policy jdv_global_crm_member_read on public.prospecteur_stocks for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.prospecteur_stocks; create policy jdv_global_crm_admin_insert on public.prospecteur_stocks for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.prospecteur_stocks; create policy jdv_global_crm_admin_update on public.prospecteur_stocks for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.prospecteur_stocks; create policy jdv_global_crm_admin_delete on public.prospecteur_stocks for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.prospecteurs; create policy jdv_global_crm_admin_insert on public.prospecteurs for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.prospecteurs; create policy jdv_global_crm_admin_update on public.prospecteurs for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.prospecteurs; create policy jdv_global_crm_admin_delete on public.prospecteurs for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.prospects; create policy jdv_global_crm_admin_insert on public.prospects for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.prospects; create policy jdv_global_crm_admin_update on public.prospects for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.prospects; create policy jdv_global_crm_admin_delete on public.prospects for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.purchase_order_items; create policy jdv_global_crm_member_read on public.purchase_order_items for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.purchase_order_items; create policy jdv_global_crm_admin_insert on public.purchase_order_items for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.purchase_order_items; create policy jdv_global_crm_admin_update on public.purchase_order_items for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.purchase_order_items; create policy jdv_global_crm_admin_delete on public.purchase_order_items for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.purchase_orders; create policy jdv_global_crm_member_read on public.purchase_orders for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.purchase_orders; create policy jdv_global_crm_admin_insert on public.purchase_orders for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.purchase_orders; create policy jdv_global_crm_admin_update on public.purchase_orders for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.purchase_orders; create policy jdv_global_crm_admin_delete on public.purchase_orders for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.sale_items; create policy jdv_global_crm_admin_insert on public.sale_items for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.sale_items; create policy jdv_global_crm_admin_update on public.sale_items for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.sale_items; create policy jdv_global_crm_admin_delete on public.sale_items for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.sales; create policy jdv_global_crm_admin_insert on public.sales for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.sales; create policy jdv_global_crm_admin_update on public.sales for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.sales; create policy jdv_global_crm_admin_delete on public.sales for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.sales_return_items; create policy jdv_global_crm_member_read on public.sales_return_items for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.sales_return_items; create policy jdv_global_crm_admin_insert on public.sales_return_items for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.sales_return_items; create policy jdv_global_crm_admin_update on public.sales_return_items for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.sales_return_items; create policy jdv_global_crm_admin_delete on public.sales_return_items for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.sales_returns; create policy jdv_global_crm_member_read on public.sales_returns for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.sales_returns; create policy jdv_global_crm_admin_insert on public.sales_returns for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.sales_returns; create policy jdv_global_crm_admin_update on public.sales_returns for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.sales_returns; create policy jdv_global_crm_admin_delete on public.sales_returns for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.serial_numbers; create policy jdv_global_crm_member_read on public.serial_numbers for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.serial_numbers; create policy jdv_global_crm_admin_insert on public.serial_numbers for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.serial_numbers; create policy jdv_global_crm_admin_update on public.serial_numbers for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.serial_numbers; create policy jdv_global_crm_admin_delete on public.serial_numbers for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.stock_movements; create policy jdv_global_crm_member_read on public.stock_movements for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.stock_movements; create policy jdv_global_crm_admin_insert on public.stock_movements for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.stock_movements; create policy jdv_global_crm_admin_update on public.stock_movements for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.stock_movements; create policy jdv_global_crm_admin_delete on public.stock_movements for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.stock_transfer_items; create policy jdv_global_crm_member_read on public.stock_transfer_items for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.stock_transfer_items; create policy jdv_global_crm_admin_insert on public.stock_transfer_items for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.stock_transfer_items; create policy jdv_global_crm_admin_update on public.stock_transfer_items for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.stock_transfer_items; create policy jdv_global_crm_admin_delete on public.stock_transfer_items for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.stock_transfers; create policy jdv_global_crm_member_read on public.stock_transfers for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.stock_transfers; create policy jdv_global_crm_admin_insert on public.stock_transfers for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.stock_transfers; create policy jdv_global_crm_admin_update on public.stock_transfers for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.stock_transfers; create policy jdv_global_crm_admin_delete on public.stock_transfers for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.stocks; create policy jdv_global_crm_member_read on public.stocks for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.stocks; create policy jdv_global_crm_admin_insert on public.stocks for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.stocks; create policy jdv_global_crm_admin_update on public.stocks for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.stocks; create policy jdv_global_crm_admin_delete on public.stocks for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.subscription_events; create policy jdv_global_crm_member_read on public.subscription_events for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.subscription_events; create policy jdv_global_crm_admin_insert on public.subscription_events for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.subscription_events; create policy jdv_global_crm_admin_update on public.subscription_events for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.subscription_events; create policy jdv_global_crm_admin_delete on public.subscription_events for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.subscription_payments; create policy jdv_global_crm_member_read on public.subscription_payments for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.subscription_payments; create policy jdv_global_crm_admin_insert on public.subscription_payments for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.subscription_payments; create policy jdv_global_crm_admin_update on public.subscription_payments for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.subscription_payments; create policy jdv_global_crm_admin_delete on public.subscription_payments for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_plans_read on public.subscription_plans; create policy jdv_global_crm_plans_read on public.subscription_plans for select to authenticated using (true);
drop policy if exists jdv_global_crm_plans_write on public.subscription_plans; create policy jdv_global_crm_plans_write on public.subscription_plans for all to authenticated using (public.is_super_admin()) with check (public.is_super_admin());
drop policy if exists jdv_global_crm_super_admin_modules_read on public.super_admin_modules; create policy jdv_global_crm_super_admin_modules_read on public.super_admin_modules for select to authenticated using (public.is_super_admin());
drop policy if exists jdv_global_crm_super_admin_modules_write on public.super_admin_modules; create policy jdv_global_crm_super_admin_modules_write on public.super_admin_modules for all to authenticated using (public.is_super_admin()) with check (public.is_super_admin());
drop policy if exists jdv_global_crm_member_read on public.supplier_payments; create policy jdv_global_crm_member_read on public.supplier_payments for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.supplier_payments; create policy jdv_global_crm_admin_insert on public.supplier_payments for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.supplier_payments; create policy jdv_global_crm_admin_update on public.supplier_payments for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.supplier_payments; create policy jdv_global_crm_admin_delete on public.supplier_payments for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_member_read on public.suppliers; create policy jdv_global_crm_member_read on public.suppliers for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.suppliers; create policy jdv_global_crm_admin_insert on public.suppliers for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.suppliers; create policy jdv_global_crm_admin_update on public.suppliers for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.suppliers; create policy jdv_global_crm_admin_delete on public.suppliers for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_user_read on public.user_permissions; create policy jdv_global_crm_user_read on public.user_permissions for select to authenticated using (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_user_insert on public.user_permissions; create policy jdv_global_crm_user_insert on public.user_permissions for insert to authenticated with check (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_user_update on public.user_permissions; create policy jdv_global_crm_user_update on public.user_permissions for update to authenticated using (public.is_super_admin() or user_id=auth.uid()) with check (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_user_read on public.user_settings; create policy jdv_global_crm_user_read on public.user_settings for select to authenticated using (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_user_insert on public.user_settings; create policy jdv_global_crm_user_insert on public.user_settings for insert to authenticated with check (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_user_update on public.user_settings; create policy jdv_global_crm_user_update on public.user_settings for update to authenticated using (public.is_super_admin() or user_id=auth.uid()) with check (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_member_read on public.warehouse_inventory; create policy jdv_global_crm_member_read on public.warehouse_inventory for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.warehouse_inventory; create policy jdv_global_crm_admin_insert on public.warehouse_inventory for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.warehouse_inventory; create policy jdv_global_crm_admin_update on public.warehouse_inventory for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.warehouse_inventory; create policy jdv_global_crm_admin_delete on public.warehouse_inventory for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_user_read on public.warehouse_users; create policy jdv_global_crm_user_read on public.warehouse_users for select to authenticated using (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_user_insert on public.warehouse_users; create policy jdv_global_crm_user_insert on public.warehouse_users for insert to authenticated with check (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_user_update on public.warehouse_users; create policy jdv_global_crm_user_update on public.warehouse_users for update to authenticated using (public.is_super_admin() or user_id=auth.uid()) with check (public.is_super_admin() or user_id=auth.uid());
drop policy if exists jdv_global_crm_member_read on public.warehouses; create policy jdv_global_crm_member_read on public.warehouses for select to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_member(organization_id)));
drop policy if exists jdv_global_crm_admin_insert on public.warehouses; create policy jdv_global_crm_admin_insert on public.warehouses for insert to authenticated with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_update on public.warehouses; create policy jdv_global_crm_admin_update on public.warehouses for update to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id))) with check (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));
drop policy if exists jdv_global_crm_admin_delete on public.warehouses; create policy jdv_global_crm_admin_delete on public.warehouses for delete to authenticated using (public.is_super_admin() or (organization_id is not null and public.is_org_admin(organization_id)));


create or replace function public.is_org_manager(org_id uuid)
returns boolean language sql stable security definer set search_path=pg_catalog,public
as $function$ select exists(select 1 from public.organization_members om join public.roles r on r.id=om.role_id where om.organization_id=org_id and om.user_id=auth.uid() and om.member_status='active' and r.code in ('owner','admin','manager','accountant')); $function$;
revoke all on function public.is_org_manager(uuid) from public,anon;
grant execute on function public.is_org_manager(uuid) to authenticated;
drop policy if exists jdv_global_crm_member_read on public.prospects; drop policy if exists jdv_global_crm_prospects_select on public.prospects; create policy jdv_global_crm_prospects_select on public.prospects for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospects.prospecteur_id and p.organization_id=prospects.organization_id and p.user_id=auth.uid()) or exists(select 1 from public.client_portfolios cp where cp.id=prospects.portfolio_id and cp.owner_user_id=auth.uid() and cp.organization_id=prospects.organization_id));
drop policy if exists jdv_global_crm_member_read on public.clients; drop policy if exists jdv_global_crm_clients_select on public.clients; create policy jdv_global_crm_clients_select on public.clients for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=clients.prospecteur_id and p.organization_id=clients.organization_id and p.user_id=auth.uid()) or exists(select 1 from public.client_portfolios cp where cp.id=clients.portfolio_id and cp.owner_user_id=auth.uid() and cp.organization_id=clients.organization_id));
drop policy if exists jdv_global_crm_member_read on public.client_portfolios; drop policy if exists jdv_global_crm_client_portfolios_select on public.client_portfolios; create policy jdv_global_crm_client_portfolios_select on public.client_portfolios for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or owner_user_id=auth.uid());
drop policy if exists jdv_global_crm_member_read on public.prospecteurs; drop policy if exists jdv_global_crm_prospecteurs_select on public.prospecteurs; create policy jdv_global_crm_prospecteurs_select on public.prospecteurs for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or user_id=auth.uid());
drop policy if exists jdv_global_crm_member_read on public.field_visits; drop policy if exists jdv_global_crm_field_visits_select on public.field_visits; create policy jdv_global_crm_field_visits_select on public.field_visits for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=field_visits.prospecteur_id and p.organization_id=field_visits.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_member_read on public.prospect_activities; drop policy if exists jdv_global_crm_prospect_activities_select on public.prospect_activities; create policy jdv_global_crm_prospect_activities_select on public.prospect_activities for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospect_activities.prospecteur_id and p.organization_id=prospect_activities.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_member_read on public.sales; drop policy if exists jdv_global_crm_sales_select on public.sales; create policy jdv_global_crm_sales_select on public.sales for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=sales.prospecteur_id and p.organization_id=sales.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_member_read on public.sale_items; drop policy if exists jdv_global_crm_sale_items_select on public.sale_items; create policy jdv_global_crm_sale_items_select on public.sale_items for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.sales s join public.prospecteurs p on p.id=s.prospecteur_id where s.id=sale_items.sale_id and s.organization_id=sale_items.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_member_read on public.payments; drop policy if exists jdv_global_crm_payments_select on public.payments; create policy jdv_global_crm_payments_select on public.payments for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=payments.prospecteur_id and p.organization_id=payments.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_member_read on public.payment_schedules; drop policy if exists jdv_global_crm_payment_schedules_select on public.payment_schedules; create policy jdv_global_crm_payment_schedules_select on public.payment_schedules for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.sales s join public.prospecteurs p on p.id=s.prospecteur_id where s.id=payment_schedules.sale_id and s.organization_id=payment_schedules.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_member_read on public.commissions; drop policy if exists jdv_global_crm_commissions_select on public.commissions; create policy jdv_global_crm_commissions_select on public.commissions for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=commissions.prospecteur_id and p.organization_id=commissions.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_member_read on public.prospect_followups; drop policy if exists jdv_global_crm_prospect_followups_select on public.prospect_followups; create policy jdv_global_crm_prospect_followups_select on public.prospect_followups for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospect_followups.prospecteur_id and p.organization_id=prospect_followups.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_member_read on public.prospect_assignments; drop policy if exists jdv_global_crm_prospect_assignments_select on public.prospect_assignments; create policy jdv_global_crm_prospect_assignments_select on public.prospect_assignments for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=prospect_assignments.prospecteur_id and p.organization_id=prospect_assignments.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_member_read on public.prospect_status_history; drop policy if exists jdv_global_crm_prospect_status_history_select on public.prospect_status_history; create policy jdv_global_crm_prospect_status_history_select on public.prospect_status_history for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospects pr join public.prospecteurs p on p.id=pr.prospecteur_id where pr.id=prospect_status_history.prospect_id and pr.organization_id=prospect_status_history.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_member_read on public.call_center_tasks; drop policy if exists jdv_global_crm_call_center_tasks_select on public.call_center_tasks; create policy jdv_global_crm_call_center_tasks_select on public.call_center_tasks for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or assigned_to=auth.uid() or exists(select 1 from public.prospecteurs p where p.id=call_center_tasks.prospecteur_id and p.organization_id=call_center_tasks.organization_id and p.user_id=auth.uid()));
drop policy if exists jdv_global_crm_member_read on public.call_logs; drop policy if exists jdv_global_crm_call_logs_select on public.call_logs; create policy jdv_global_crm_call_logs_select on public.call_logs for select to authenticated using (public.is_super_admin() or public.is_org_manager(organization_id) or exists(select 1 from public.prospecteurs p where p.id=call_logs.prospecteur_id and p.organization_id=call_logs.organization_id and p.user_id=auth.uid()));
