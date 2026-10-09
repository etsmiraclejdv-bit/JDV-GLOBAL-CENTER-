-- JDV CRM - instantané du schéma public (généré depuis Supabase le 2026-10-01)
-- À appliquer sur une base vide : tables -> contraintes -> FK -> index -> RLS -> fonctions -> vues -> triggers -> policies

-- ===== tables (73) =====

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

create table if not exists public.audit_logs (
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

create table if not exists public.countries (
  id uuid default gen_random_uuid() not null,
  code text not null,
  name text not null,
  currency_code text,
  phone_prefix text,
  active boolean default true not null
);

create table if not exists public.currencies (
  id uuid default gen_random_uuid() not null,
  code text not null,
  name text not null,
  symbol text,
  decimals integer default 2 not null,
  active boolean default true not null
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

create table if not exists public.exchange_rates (
  id uuid default gen_random_uuid() not null,
  base_currency text not null,
  quote_currency text not null,
  rate numeric(20,8) not null,
  effective_at timestamp with time zone default now() not null,
  source text,
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

create table if not exists public.languages (
  id uuid default gen_random_uuid() not null,
  code text not null,
  name text not null,
  native_name text,
  active boolean default true not null
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

create table if not exists public.notifications (
  id uuid default gen_random_uuid() not null,
  organization_id uuid,
  user_id uuid,
  title text not null,
  message text not null,
  type text default 'info'::text not null,
  read_at timestamp with time zone,
  metadata jsonb default '{}'::jsonb not null,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.organization_members (
  id uuid default gen_random_uuid() not null,
  organization_id uuid not null,
  user_id uuid not null,
  role text not null,
  status text default 'active'::text not null,
  joined_at timestamp with time zone default now() not null,
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

create table if not exists public.organizations (
  id uuid default gen_random_uuid() not null,
  name text not null,
  legal_name text,
  registration_number text,
  tax_number text,
  email text,
  phone text,
  whatsapp text,
  country text default 'Bénin'::text not null,
  currency text default 'XOF'::text not null,
  timezone text default 'Africa/Porto-Novo'::text not null,
  language text default 'fr'::text not null,
  address text,
  city text,
  logo_url text,
  status text default 'pending'::text not null,
  subscription_status text default 'inactive'::text not null,
  owner_user_id uuid,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  website text,
  primary_color text default '#0B1B3D'::text,
  secondary_color text default '#D4AF37'::text,
  tax_id text
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

create table if not exists public.permissions (
  id uuid default gen_random_uuid() not null,
  code text not null,
  name text not null,
  description text,
  module text,
  created_at timestamp with time zone default now() not null
);

create table if not exists public.profiles (
  id uuid not null,
  first_name text,
  last_name text,
  display_name text,
  phone text,
  avatar_url text,
  preferred_language text default 'fr'::text not null,
  country text,
  status text default 'active'::text not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null
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

create table if not exists public.role_permissions (
  id uuid default gen_random_uuid() not null,
  role text not null,
  permission_id uuid not null,
  created_at timestamp with time zone default now() not null
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

create table if not exists public.super_admins (
  id uuid default gen_random_uuid() not null,
  user_id uuid not null,
  status text default 'active'::text not null,
  created_at timestamp with time zone default now() not null,
  updated_at timestamp with time zone default now() not null,
  actif boolean default true
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

-- ===== constraints_pk_unique_check (224) =====

alter table article_categories add constraint article_categories_organization_id_name_key UNIQUE (organization_id, name);

alter table article_categories add constraint article_categories_pkey PRIMARY KEY (id);

alter table article_serial_assignments add constraint article_serial_assignments_pkey PRIMARY KEY (id);

alter table articles add constraint articles_cash_price_check CHECK ((cash_price >= (0)::numeric));

alter table articles add constraint articles_credit_price_check CHECK ((credit_price >= (0)::numeric));

alter table articles add constraint articles_default_payment_amount_check CHECK ((default_payment_amount >= (0)::numeric));

alter table articles add constraint articles_fixed_price_check CHECK ((fixed_price >= (0)::numeric));

alter table articles add constraint articles_minimum_deposit_check CHECK ((minimum_deposit >= (0)::numeric));

alter table articles add constraint articles_organization_id_code_key UNIQUE (organization_id, code);

alter table articles add constraint articles_pkey PRIMARY KEY (id);

alter table audit_events add constraint audit_events_pkey PRIMARY KEY (id);

alter table audit_logs add constraint audit_logs_pkey PRIMARY KEY (id);

alter table call_center_tasks add constraint call_center_tasks_pkey PRIMARY KEY (id);

alter table call_center_tasks add constraint call_center_tasks_priority_check CHECK ((priority = ANY (ARRAY['low'::text, 'normal'::text, 'high'::text, 'urgent'::text])));

alter table call_center_tasks add constraint call_center_tasks_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'in_progress'::text, 'completed'::text, 'cancelled'::text])));

alter table call_logs add constraint call_logs_pkey PRIMARY KEY (id);

alter table client_portfolios add constraint client_portfolios_organization_id_owner_type_owner_user_id_key UNIQUE (organization_id, owner_type, owner_user_id);

alter table client_portfolios add constraint client_portfolios_owner_type_check CHECK ((owner_type = ANY (ARRAY['prospecteur'::text, 'super_admin'::text])));

alter table client_portfolios add constraint client_portfolios_pkey PRIMARY KEY (id);

alter table client_portfolios add constraint client_portfolios_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'archived'::text])));

alter table clients add constraint clients_code_key UNIQUE (code);

alter table clients add constraint clients_pkey PRIMARY KEY (id);

alter table clients add constraint clients_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'prospect'::text, 'client'::text, 'debtor'::text, 'completed'::text])));

alter table clients add constraint clients_status_check_jdv_v1 CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'prospect'::text, 'client'::text, 'debtor'::text, 'completed'::text, 'archived'::text])));

alter table clients add constraint clients_temperature_check CHECK ((temperature = ANY (ARRAY['hot'::text, 'warm'::text, 'cold'::text])));

alter table clients add constraint clients_temperature_check_jdv_v1 CHECK (((temperature IS NULL) OR (temperature = ANY (ARRAY['hot'::text, 'warm'::text, 'cold'::text]))));

alter table commissions add constraint commissions_base_amount_check CHECK ((base_amount >= (0)::numeric));

alter table commissions add constraint commissions_commission_amount_check CHECK ((commission_amount >= (0)::numeric));

alter table commissions add constraint commissions_commission_rate_check CHECK ((commission_rate >= (0)::numeric));

alter table commissions add constraint commissions_pkey PRIMARY KEY (id);

alter table commissions add constraint commissions_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'paid'::text, 'cancelled'::text])));

alter table company_settings add constraint company_settings_organization_id_setting_key_key UNIQUE (organization_id, setting_key);

alter table company_settings add constraint company_settings_pkey PRIMARY KEY (id);

alter table countries add constraint countries_code_key UNIQUE (code);

alter table countries add constraint countries_pkey PRIMARY KEY (id);

alter table currencies add constraint currencies_code_key UNIQUE (code);

alter table currencies add constraint currencies_pkey PRIMARY KEY (id);

alter table daily_tokens add constraint daily_tokens_pkey PRIMARY KEY (id);

alter table daily_tokens add constraint daily_tokens_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'paid'::text, 'partial'::text, 'late'::text, 'missed'::text, 'cancelled'::text])));








alter table document_sequences add constraint document_sequences_organization_id_document_type_key UNIQUE (organization_id, document_type);

alter table document_sequences add constraint document_sequences_pkey PRIMARY KEY (id);

alter table document_templates add constraint document_templates_organization_id_code_key UNIQUE (organization_id, code);

alter table document_templates add constraint document_templates_pkey PRIMARY KEY (id);

alter table documents add constraint documents_pkey PRIMARY KEY (id);

alter table exchange_rates add constraint exchange_rates_base_currency_quote_currency_effective_at_key UNIQUE (base_currency, quote_currency, effective_at);

alter table exchange_rates add constraint exchange_rates_pkey PRIMARY KEY (id);

alter table exchange_rates add constraint exchange_rates_rate_check CHECK ((rate > (0)::numeric));

alter table field_visits add constraint field_visits_pkey PRIMARY KEY (id);

alter table follow_up_reminders add constraint follow_up_reminders_pkey PRIMARY KEY (id);

alter table follow_up_reminders add constraint follow_up_reminders_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'sent'::text, 'completed'::text, 'cancelled'::text])));

alter table goods_receipt_items add constraint goods_receipt_items_pkey PRIMARY KEY (id);

alter table goods_receipt_items add constraint goods_receipt_items_quantity_received_check CHECK ((quantity_received > (0)::numeric));

alter table goods_receipts add constraint goods_receipts_organization_id_receipt_number_key UNIQUE (organization_id, receipt_number);

alter table goods_receipts add constraint goods_receipts_pkey PRIMARY KEY (id);

alter table goods_receipts add constraint goods_receipts_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'received'::text, 'cancelled'::text])));

alter table languages add constraint languages_code_key UNIQUE (code);

alter table languages add constraint languages_pkey PRIMARY KEY (id);

alter table login_security_events add constraint login_security_events_pkey PRIMARY KEY (id);

alter table notification_events add constraint notification_events_pkey PRIMARY KEY (id);

alter table notification_events add constraint notification_events_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'sent'::text, 'read'::text, 'failed'::text])));

alter table notification_preferences add constraint notification_preferences_pkey PRIMARY KEY (id);

alter table notification_preferences add constraint notification_preferences_user_id_notification_type_key UNIQUE (user_id, notification_type);

alter table notifications add constraint notifications_pkey PRIMARY KEY (id);

alter table organization_members add constraint organization_members_organization_id_user_id_key UNIQUE (organization_id, user_id);

alter table organization_members add constraint organization_members_pkey PRIMARY KEY (id);

alter table organization_members add constraint organization_members_role_check CHECK ((role = ANY (ARRAY['business_admin'::text, 'manager'::text, 'prospecteur'::text, 'accountant'::text, 'viewer'::text])));

alter table organization_members add constraint organization_members_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'suspended'::text])));

alter table organization_personalization add constraint organization_personalization_org_unique UNIQUE (organization_id);

alter table organization_personalization add constraint organization_personalization_pkey PRIMARY KEY (id);

alter table organization_settings add constraint organization_settings_organization_id_key UNIQUE (organization_id);

alter table organization_settings add constraint organization_settings_pkey PRIMARY KEY (id);

alter table organization_subscriptions add constraint organization_subscriptions_dates_check CHECK (((expires_at IS NULL) OR (started_at IS NULL) OR (expires_at >= started_at)));

alter table organization_subscriptions add constraint organization_subscriptions_dates_valid CHECK (((expires_at IS NULL) OR (started_at IS NULL) OR (expires_at > started_at)));

alter table organization_subscriptions add constraint organization_subscriptions_pkey PRIMARY KEY (id);

alter table organization_subscriptions add constraint organization_subscriptions_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'trial'::text, 'active'::text, 'past_due'::text, 'expired'::text, 'cancelled'::text])));

alter table organizations add constraint organizations_pkey PRIMARY KEY (id);

alter table organizations add constraint organizations_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'active'::text, 'suspended'::text, 'blocked'::text, 'trial'::text, 'expired'::text])));

alter table organizations add constraint organizations_subscription_status_check CHECK ((subscription_status = ANY (ARRAY['inactive'::text, 'trial'::text, 'active'::text, 'past_due'::text, 'cancelled'::text, 'expired'::text])));

alter table payment_provider_accounts add constraint payment_provider_accounts_environment_check CHECK ((environment = ANY (ARRAY['sandbox'::text, 'live'::text])));

alter table payment_provider_accounts add constraint payment_provider_accounts_organization_id_provider_key UNIQUE (organization_id, provider);

alter table payment_provider_accounts add constraint payment_provider_accounts_pkey PRIMARY KEY (id);

alter table payment_provider_accounts add constraint payment_provider_accounts_provider_check CHECK ((provider = 'fedapay'::text));

alter table payment_provider_accounts add constraint payment_provider_accounts_status_check CHECK ((status = ANY (ARRAY['not_configured'::text, 'active'::text, 'error'::text, 'disabled'::text])));

alter table payment_provider_events add constraint payment_provider_events_pkey PRIMARY KEY (id);

alter table payment_provider_events add constraint payment_provider_events_provider_provider_event_id_key UNIQUE (provider, provider_event_id);

alter table payment_provider_events add constraint payment_provider_events_status_check CHECK ((status = ANY (ARRAY['received'::text, 'processed'::text, 'failed'::text, 'ignored'::text])));

alter table payment_refunds add constraint payment_refunds_amount_check CHECK ((amount > (0)::numeric));

alter table payment_refunds add constraint payment_refunds_pkey PRIMARY KEY (id);

alter table payment_refunds add constraint payment_refunds_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'processed'::text, 'failed'::text, 'cancelled'::text])));

alter table payment_schedules add constraint payment_schedules_amounts_valid CHECK (((expected_amount > (0)::numeric) AND (paid_amount >= (0)::numeric) AND (paid_amount <= expected_amount)));

alter table payment_schedules add constraint payment_schedules_expected_amount_check CHECK ((expected_amount >= (0)::numeric));

alter table payment_schedules add constraint payment_schedules_installment_number_check CHECK ((installment_number > 0));

alter table payment_schedules add constraint payment_schedules_installment_positive CHECK ((installment_number > 0));

alter table payment_schedules add constraint payment_schedules_paid_amount_check CHECK ((paid_amount >= (0)::numeric));

alter table payment_schedules add constraint payment_schedules_pkey PRIMARY KEY (id);

alter table payment_schedules add constraint payment_schedules_sale_id_installment_number_key UNIQUE (sale_id, installment_number);

alter table payment_schedules add constraint payment_schedules_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'partial'::text, 'paid'::text, 'late'::text, 'cancelled'::text])));

alter table payment_webhook_events add constraint payment_webhook_events_pkey PRIMARY KEY (id);

alter table payments add constraint payments_amount_check CHECK ((amount > (0)::numeric));

alter table payments add constraint payments_amount_positive CHECK ((amount > (0)::numeric));

alter table payments add constraint payments_pkey PRIMARY KEY (id);

alter table payments add constraint payments_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'successful'::text, 'failed'::text, 'cancelled'::text, 'refunded'::text])));

alter table permissions add constraint permissions_code_key UNIQUE (code);

alter table permissions add constraint permissions_pkey PRIMARY KEY (id);

alter table profiles add constraint profiles_pkey PRIMARY KEY (id);

alter table profiles add constraint profiles_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'suspended'::text, 'blocked'::text])));

alter table prospect_activities add constraint prospect_activities_pkey PRIMARY KEY (id);

alter table prospect_assignments add constraint prospect_assignments_pkey PRIMARY KEY (id);

alter table prospect_followups add constraint prospect_followups_pkey PRIMARY KEY (id);

alter table prospect_followups add constraint prospect_followups_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'completed'::text, 'missed'::text, 'cancelled'::text])));

alter table prospect_status_history add constraint prospect_status_history_pkey PRIMARY KEY (id);

alter table prospecteur_stocks add constraint prospecteur_stocks_pkey PRIMARY KEY (id);

alter table prospecteur_stocks add constraint prospecteur_stocks_prospecteur_id_article_id_key UNIQUE (prospecteur_id, article_id);

alter table prospecteur_stocks add constraint prospecteur_stocks_quantity_check CHECK ((quantity >= 0));

alter table prospecteurs add constraint prospecteurs_code_key UNIQUE (code);

alter table prospecteurs add constraint prospecteurs_commission_rate_check CHECK ((commission_rate >= (0)::numeric));

alter table prospecteurs add constraint prospecteurs_commission_rate_valid CHECK (((commission_rate >= (0)::numeric) AND (commission_rate <= (100)::numeric)));

alter table prospecteurs add constraint prospecteurs_pkey PRIMARY KEY (id);

alter table prospecteurs add constraint prospecteurs_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'suspended'::text, 'blocked'::text])));

alter table prospecteurs add constraint prospecteurs_status_check_jdv_v1 CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'suspended'::text, 'blocked'::text])));

alter table prospecteurs add constraint prospecteurs_user_id_key UNIQUE (user_id);

alter table prospects add constraint prospects_pkey PRIMARY KEY (id);

alter table prospects add constraint prospects_status_check CHECK ((status = ANY (ARRAY['new'::text, 'contacted'::text, 'interested'::text, 'converted'::text, 'lost'::text, 'inactive'::text])));

alter table prospects add constraint prospects_status_check_jdv_v1 CHECK ((status = ANY (ARRAY['new'::text, 'contacted'::text, 'interested'::text, 'converted'::text, 'lost'::text, 'inactive'::text, 'closed'::text, 'archived'::text])));

alter table prospects add constraint prospects_temperature_check CHECK ((temperature = ANY (ARRAY['hot'::text, 'warm'::text, 'cold'::text])));

alter table prospects add constraint prospects_temperature_check_jdv_v1 CHECK ((temperature = ANY (ARRAY['hot'::text, 'warm'::text, 'cold'::text])));

alter table prospects add constraint prospects_visit_count_check CHECK ((visit_count >= 0));

alter table prospects add constraint prospects_visit_count_nonnegative CHECK ((visit_count >= 0));

alter table purchase_order_items add constraint purchase_order_items_pkey PRIMARY KEY (id);

alter table purchase_order_items add constraint purchase_order_items_quantity_check CHECK ((quantity > (0)::numeric));

alter table purchase_orders add constraint purchase_orders_organization_id_order_number_key UNIQUE (organization_id, order_number);

alter table purchase_orders add constraint purchase_orders_pkey PRIMARY KEY (id);

alter table purchase_orders add constraint purchase_orders_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'sent'::text, 'confirmed'::text, 'partial'::text, 'received'::text, 'cancelled'::text, 'closed'::text])));

alter table role_permissions add constraint role_permissions_pkey PRIMARY KEY (id);

alter table role_permissions add constraint role_permissions_role_permission_id_key UNIQUE (role, permission_id);

alter table sale_items add constraint sale_items_amounts_nonnegative CHECK (((discount_amount >= (0)::numeric) AND (line_total >= (0)::numeric) AND ((unit_fixed_price IS NULL) OR (unit_fixed_price >= (0)::numeric)) AND ((unit_cash_price IS NULL) OR (unit_cash_price >= (0)::numeric)) AND ((unit_credit_price IS NULL) OR (unit_credit_price >= (0)::numeric))));

alter table sale_items add constraint sale_items_discount_amount_check CHECK ((discount_amount >= (0)::numeric));

alter table sale_items add constraint sale_items_pkey PRIMARY KEY (id);

alter table sale_items add constraint sale_items_prices_nonnegative CHECK (((COALESCE(unit_fixed_price, (0)::numeric) >= (0)::numeric) AND (COALESCE(unit_cash_price, (0)::numeric) >= (0)::numeric) AND (COALESCE(unit_credit_price, (0)::numeric) >= (0)::numeric) AND (COALESCE(discount_amount, (0)::numeric) >= (0)::numeric) AND (COALESCE(line_total, (0)::numeric) >= (0)::numeric)));

alter table sale_items add constraint sale_items_quantity_check CHECK ((quantity > (0)::numeric));

alter table sale_items add constraint sale_items_quantity_positive CHECK ((quantity > (0)::numeric));

alter table sales_return_items add constraint sales_return_items_pkey PRIMARY KEY (id);

alter table sales_return_items add constraint sales_return_items_quantity_check CHECK ((quantity > (0)::numeric));

alter table sales_return_items add constraint sales_return_items_quantity_positive CHECK ((quantity > (0)::numeric));

alter table sales_return_items add constraint sales_return_items_refund_nonnegative CHECK ((refund_amount >= (0)::numeric));

alter table sales_returns add constraint sales_returns_organization_id_return_number_key UNIQUE (organization_id, return_number);

alter table sales_returns add constraint sales_returns_pkey PRIMARY KEY (id);

alter table sales_returns add constraint sales_returns_refund_nonnegative CHECK ((refund_amount >= (0)::numeric));

alter table sales_returns add constraint sales_returns_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'approved'::text, 'processed'::text, 'cancelled'::text])));

alter table sales add constraint sales_amount_paid_check CHECK ((amount_paid >= (0)::numeric));

alter table sales add constraint sales_amount_remaining_check CHECK ((amount_remaining >= (0)::numeric));

alter table sales add constraint sales_amounts_nonnegative CHECK (((amount_paid >= (0)::numeric) AND (amount_remaining >= (0)::numeric) AND (payment_amount >= (0)::numeric)));

alter table sales add constraint sales_payment_amount_check CHECK ((payment_amount >= (0)::numeric));

alter table sales add constraint sales_payment_frequency_check CHECK ((payment_frequency = ANY (ARRAY['daily'::text, 'weekly'::text, 'biweekly'::text, 'monthly'::text, 'quarterly'::text, 'custom'::text])));

alter table sales add constraint sales_pkey PRIMARY KEY (id);

alter table sales add constraint sales_prices_nonnegative CHECK (((fixed_price >= (0)::numeric) AND (cash_price >= (0)::numeric) AND (credit_price >= (0)::numeric)));

alter table sales add constraint sales_quantity_check CHECK ((quantity > 0));

alter table sales add constraint sales_quantity_nonnegative CHECK ((quantity >= 0));

alter table sales add constraint sales_sale_number_key UNIQUE (sale_number);

alter table sales add constraint sales_sale_type_check CHECK ((sale_type = ANY (ARRAY['cash'::text, 'credit'::text])));

alter table sales add constraint sales_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'active'::text, 'completed'::text, 'cancelled'::text, 'defaulted'::text])));

alter table serial_numbers add constraint serial_numbers_organization_id_serial_number_key UNIQUE (organization_id, serial_number);

alter table serial_numbers add constraint serial_numbers_pkey PRIMARY KEY (id);

alter table serial_numbers add constraint serial_numbers_status_check CHECK ((status = ANY (ARRAY['in_stock'::text, 'reserved'::text, 'sold'::text, 'returned'::text, 'damaged'::text, 'lost'::text, 'inactive'::text])));

alter table stock_movements add constraint stock_movements_movement_type_check CHECK ((movement_type = ANY (ARRAY['entry'::text, 'exit'::text, 'transfer_to_prospecteur'::text, 'return_from_prospecteur'::text, 'sale'::text, 'adjustment'::text, 'loss'::text, 'transfer_out'::text, 'transfer_in'::text])));

alter table stock_movements add constraint stock_movements_pkey PRIMARY KEY (id);

alter table stock_movements add constraint stock_movements_quantity_check CHECK ((quantity > 0));

alter table stock_movements add constraint stock_movements_quantity_positive CHECK ((quantity > 0));

alter table stock_transfer_items add constraint stock_transfer_items_pkey PRIMARY KEY (id);

alter table stock_transfer_items add constraint stock_transfer_items_quantity_check CHECK ((quantity > (0)::numeric));

alter table stock_transfer_items add constraint stock_transfer_items_received_quantity_check CHECK ((received_quantity >= (0)::numeric));

alter table stock_transfers add constraint stock_transfers_check CHECK ((source_warehouse_id <> destination_warehouse_id));

alter table stock_transfers add constraint stock_transfers_organization_id_transfer_number_key UNIQUE (organization_id, transfer_number);

alter table stock_transfers add constraint stock_transfers_pkey PRIMARY KEY (id);

alter table stock_transfers add constraint stock_transfers_status_check CHECK ((status = ANY (ARRAY['draft'::text, 'in_transit'::text, 'received'::text, 'cancelled'::text])));

alter table stocks add constraint stocks_minimum_quantity_check CHECK ((minimum_quantity >= 0));

alter table stocks add constraint stocks_organization_id_article_id_key UNIQUE (organization_id, article_id);

alter table stocks add constraint stocks_pkey PRIMARY KEY (id);

alter table stocks add constraint stocks_quantities_nonnegative CHECK (((quantity >= 0) AND (reserved_quantity >= 0) AND (minimum_quantity >= 0)));

alter table stocks add constraint stocks_quantity_check CHECK ((quantity >= 0));

alter table stocks add constraint stocks_reserved_not_above_quantity CHECK ((reserved_quantity <= quantity));

alter table stocks add constraint stocks_reserved_quantity_check CHECK ((reserved_quantity >= 0));

alter table subscription_events add constraint subscription_events_pkey PRIMARY KEY (id);

alter table subscription_limits add constraint subscription_limits_pkey PRIMARY KEY (id);

alter table subscription_limits add constraint subscription_limits_plan_id_resource_code_key UNIQUE (plan_id, resource_code);

alter table subscription_payments add constraint subscription_payments_amount_check CHECK ((amount >= (0)::numeric));

alter table subscription_payments add constraint subscription_payments_amount_positive CHECK ((amount > (0)::numeric));

alter table subscription_payments add constraint subscription_payments_pkey PRIMARY KEY (id);

alter table subscription_payments add constraint subscription_payments_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'successful'::text, 'failed'::text, 'refunded'::text, 'cancelled'::text])));

alter table subscription_plans add constraint subscription_plans_code_key UNIQUE (code);

alter table subscription_plans add constraint subscription_plans_duration_days_check CHECK ((duration_days > 0));

alter table subscription_plans add constraint subscription_plans_pkey PRIMARY KEY (id);

alter table subscription_plans add constraint subscription_plans_price_check CHECK ((price >= (0)::numeric));

alter table super_admin_modules add constraint super_admin_modules_pkey PRIMARY KEY (id);

alter table super_admin_modules add constraint super_admin_modules_user_id_module_code_key UNIQUE (user_id, module_code);

alter table super_admins add constraint super_admins_pkey PRIMARY KEY (id);

alter table super_admins add constraint super_admins_status_check CHECK ((status = ANY (ARRAY['active'::text, 'suspended'::text, 'blocked'::text])));

alter table super_admins add constraint super_admins_user_id_key UNIQUE (user_id);

alter table supplier_payments add constraint supplier_payments_amount_check CHECK ((amount > (0)::numeric));

alter table supplier_payments add constraint supplier_payments_pkey PRIMARY KEY (id);

alter table supplier_payments add constraint supplier_payments_status_check CHECK ((status = ANY (ARRAY['pending'::text, 'paid'::text, 'failed'::text, 'cancelled'::text])));

alter table suppliers add constraint suppliers_organization_id_code_key UNIQUE (organization_id, code);

alter table suppliers add constraint suppliers_pkey PRIMARY KEY (id);

alter table suppliers add constraint suppliers_status_check CHECK ((status = ANY (ARRAY['active'::text, 'inactive'::text, 'blocked'::text])));

alter table user_permissions add constraint user_permissions_pkey PRIMARY KEY (id);

alter table user_permissions add constraint user_permissions_user_id_permission_id_key UNIQUE (user_id, permission_id);

alter table user_settings add constraint user_settings_pkey PRIMARY KEY (id);

alter table user_settings add constraint user_settings_user_id_setting_key_key UNIQUE (user_id, setting_key);

alter table warehouse_inventory add constraint warehouse_inventory_minimum_quantity_check CHECK ((minimum_quantity >= (0)::numeric));

alter table warehouse_inventory add constraint warehouse_inventory_pkey PRIMARY KEY (id);

alter table warehouse_inventory add constraint warehouse_inventory_quantity_check CHECK ((quantity >= (0)::numeric));

alter table warehouse_inventory add constraint warehouse_inventory_reserved_quantity_check CHECK ((reserved_quantity >= (0)::numeric));

alter table warehouse_inventory add constraint warehouse_inventory_warehouse_id_article_id_key UNIQUE (warehouse_id, article_id);

alter table warehouse_users add constraint warehouse_users_pkey PRIMARY KEY (id);

alter table warehouse_users add constraint warehouse_users_warehouse_id_user_id_key UNIQUE (warehouse_id, user_id);

alter table warehouses add constraint warehouses_organization_id_code_key UNIQUE (organization_id, code);

alter table warehouses add constraint warehouses_pkey PRIMARY KEY (id);

-- ===== foreign_keys (173) =====

alter table article_categories add constraint article_categories_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table article_serial_assignments add constraint article_serial_assignments_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT;

alter table article_serial_assignments add constraint article_serial_assignments_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);

alter table article_serial_assignments add constraint article_serial_assignments_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table article_serial_assignments add constraint article_serial_assignments_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL;

alter table article_serial_assignments add constraint article_serial_assignments_serial_number_id_fkey FOREIGN KEY (serial_number_id) REFERENCES serial_numbers(id) ON DELETE CASCADE;

alter table article_serial_assignments add constraint article_serial_assignments_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE SET NULL;

alter table articles add constraint articles_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table audit_events add constraint audit_events_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE SET NULL;

alter table audit_events add constraint audit_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

alter table audit_logs add constraint audit_logs_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE SET NULL;

alter table audit_logs add constraint audit_logs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

alter table call_center_tasks add constraint call_center_tasks_assigned_to_fkey FOREIGN KEY (assigned_to) REFERENCES auth.users(id);

alter table call_center_tasks add constraint call_center_tasks_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;

alter table call_center_tasks add constraint call_center_tasks_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table call_center_tasks add constraint call_center_tasks_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE CASCADE;

alter table call_center_tasks add constraint call_center_tasks_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL;

alter table call_logs add constraint call_logs_caller_user_id_fkey FOREIGN KEY (caller_user_id) REFERENCES auth.users(id);

alter table call_logs add constraint call_logs_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;

alter table call_logs add constraint call_logs_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table call_logs add constraint call_logs_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE SET NULL;

alter table call_logs add constraint call_logs_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL;

alter table client_portfolios add constraint client_portfolios_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table client_portfolios add constraint client_portfolios_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES auth.users(id) ON DELETE RESTRICT;

alter table clients add constraint clients_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table clients add constraint clients_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES client_portfolios(id) ON DELETE RESTRICT;

alter table clients add constraint clients_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL;

alter table commissions add constraint commissions_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE SET NULL;

alter table commissions add constraint commissions_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table commissions add constraint commissions_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE SET NULL;

alter table commissions add constraint commissions_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE CASCADE;

alter table commissions add constraint commissions_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE SET NULL;

alter table company_settings add constraint company_settings_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table daily_tokens add constraint daily_tokens_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;

alter table daily_tokens add constraint daily_tokens_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table daily_tokens add constraint daily_tokens_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL;

alter table daily_tokens add constraint daily_tokens_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE SET NULL;



alter table document_sequences add constraint document_sequences_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table document_templates add constraint document_templates_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table documents add constraint documents_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);

alter table documents add constraint documents_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table field_visits add constraint field_visits_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;

alter table field_visits add constraint field_visits_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table field_visits add constraint field_visits_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE SET NULL;

alter table field_visits add constraint field_visits_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE CASCADE;

alter table follow_up_reminders add constraint follow_up_reminders_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE CASCADE;

alter table follow_up_reminders add constraint follow_up_reminders_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table follow_up_reminders add constraint follow_up_reminders_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE CASCADE;

alter table follow_up_reminders add constraint follow_up_reminders_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id);

alter table goods_receipt_items add constraint goods_receipt_items_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT;

alter table goods_receipt_items add constraint goods_receipt_items_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table goods_receipt_items add constraint goods_receipt_items_receipt_id_fkey FOREIGN KEY (receipt_id) REFERENCES goods_receipts(id) ON DELETE CASCADE;

alter table goods_receipts add constraint goods_receipts_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table goods_receipts add constraint goods_receipts_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE RESTRICT;

alter table goods_receipts add constraint goods_receipts_received_by_fkey FOREIGN KEY (received_by) REFERENCES auth.users(id);

alter table login_security_events add constraint login_security_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

alter table notification_events add constraint notification_events_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table notification_events add constraint notification_events_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table notification_preferences add constraint notification_preferences_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table notifications add constraint notifications_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table notifications add constraint notifications_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table organization_members add constraint organization_members_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table organization_members add constraint organization_members_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table organization_personalization add constraint organization_personalization_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table organization_settings add constraint organization_settings_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table organization_subscriptions add constraint organization_subscriptions_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table organization_subscriptions add constraint organization_subscriptions_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES subscription_plans(id) ON DELETE RESTRICT;

alter table organizations add constraint organizations_owner_user_id_fkey FOREIGN KEY (owner_user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

alter table payment_provider_accounts add constraint payment_provider_accounts_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table payment_provider_events add constraint payment_provider_events_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE SET NULL;

alter table payment_refunds add constraint payment_refunds_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);

alter table payment_refunds add constraint payment_refunds_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table payment_refunds add constraint payment_refunds_payment_id_fkey FOREIGN KEY (payment_id) REFERENCES payments(id) ON DELETE RESTRICT;

alter table payment_refunds add constraint payment_refunds_sale_return_id_fkey FOREIGN KEY (sale_return_id) REFERENCES sales_returns(id) ON DELETE SET NULL;

alter table payment_schedules add constraint payment_schedules_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table payment_schedules add constraint payment_schedules_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE CASCADE;

alter table payment_webhook_events add constraint payment_webhook_events_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE SET NULL;

alter table payments add constraint payments_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;

alter table payments add constraint payments_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table payments add constraint payments_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL;

alter table payments add constraint payments_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES auth.users(id) ON DELETE SET NULL;

alter table payments add constraint payments_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE SET NULL;

alter table payments add constraint payments_schedule_id_fkey FOREIGN KEY (schedule_id) REFERENCES payment_schedules(id) ON DELETE SET NULL;

alter table profiles add constraint profiles_id_fkey FOREIGN KEY (id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table prospect_activities add constraint prospect_activities_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);

alter table prospect_activities add constraint prospect_activities_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table prospect_activities add constraint prospect_activities_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE CASCADE;

alter table prospect_activities add constraint prospect_activities_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL;

alter table prospect_assignments add constraint prospect_assignments_assigned_by_fkey FOREIGN KEY (assigned_by) REFERENCES auth.users(id);

alter table prospect_assignments add constraint prospect_assignments_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table prospect_assignments add constraint prospect_assignments_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE CASCADE;

alter table prospect_assignments add constraint prospect_assignments_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE CASCADE;

alter table prospect_followups add constraint prospect_followups_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table prospect_followups add constraint prospect_followups_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE CASCADE;

alter table prospect_followups add constraint prospect_followups_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL;

alter table prospect_status_history add constraint prospect_status_history_changed_by_fkey FOREIGN KEY (changed_by) REFERENCES auth.users(id);

alter table prospect_status_history add constraint prospect_status_history_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table prospect_status_history add constraint prospect_status_history_prospect_id_fkey FOREIGN KEY (prospect_id) REFERENCES prospects(id) ON DELETE CASCADE;

alter table prospecteur_stocks add constraint prospecteur_stocks_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE;

alter table prospecteur_stocks add constraint prospecteur_stocks_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table prospecteur_stocks add constraint prospecteur_stocks_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE CASCADE;

alter table prospecteurs add constraint prospecteurs_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table prospecteurs add constraint prospecteurs_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE SET NULL;

alter table prospects add constraint prospects_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;

alter table prospects add constraint prospects_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table prospects add constraint prospects_portfolio_id_fkey FOREIGN KEY (portfolio_id) REFERENCES client_portfolios(id) ON DELETE RESTRICT;

alter table prospects add constraint prospects_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL;

alter table purchase_order_items add constraint purchase_order_items_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT;

alter table purchase_order_items add constraint purchase_order_items_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table purchase_order_items add constraint purchase_order_items_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE CASCADE;

alter table purchase_orders add constraint purchase_orders_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);

alter table purchase_orders add constraint purchase_orders_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table purchase_orders add constraint purchase_orders_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT;

alter table role_permissions add constraint role_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;

alter table sale_items add constraint sale_items_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT;

alter table sale_items add constraint sale_items_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table sale_items add constraint sale_items_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE RESTRICT;

alter table sales_return_items add constraint sales_return_items_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT;

alter table sales_return_items add constraint sales_return_items_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table sales_return_items add constraint sales_return_items_return_id_fkey FOREIGN KEY (return_id) REFERENCES sales_returns(id) ON DELETE CASCADE;

alter table sales_return_items add constraint sales_return_items_serial_number_id_fkey FOREIGN KEY (serial_number_id) REFERENCES serial_numbers(id) ON DELETE RESTRICT;

alter table sales_returns add constraint sales_returns_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;

alter table sales_returns add constraint sales_returns_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);

alter table sales_returns add constraint sales_returns_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table sales_returns add constraint sales_returns_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE RESTRICT;

alter table sales add constraint sales_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE SET NULL;

alter table sales add constraint sales_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;

alter table sales add constraint sales_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table sales add constraint sales_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL;

alter table serial_numbers add constraint serial_numbers_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT;

alter table serial_numbers add constraint serial_numbers_client_id_fkey FOREIGN KEY (client_id) REFERENCES clients(id) ON DELETE SET NULL;

alter table serial_numbers add constraint serial_numbers_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table serial_numbers add constraint serial_numbers_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE SET NULL;

alter table serial_numbers add constraint serial_numbers_sale_id_fkey FOREIGN KEY (sale_id) REFERENCES sales(id) ON DELETE SET NULL;

alter table stock_movements add constraint stock_movements_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT;

alter table stock_movements add constraint stock_movements_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id) ON DELETE SET NULL;

alter table stock_movements add constraint stock_movements_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table stock_movements add constraint stock_movements_prospecteur_id_fkey FOREIGN KEY (prospecteur_id) REFERENCES prospecteurs(id) ON DELETE SET NULL;

alter table stock_transfer_items add constraint stock_transfer_items_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT;

alter table stock_transfer_items add constraint stock_transfer_items_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table stock_transfer_items add constraint stock_transfer_items_transfer_id_fkey FOREIGN KEY (transfer_id) REFERENCES stock_transfers(id) ON DELETE CASCADE;

alter table stock_transfers add constraint stock_transfers_created_by_fkey FOREIGN KEY (created_by) REFERENCES auth.users(id);

alter table stock_transfers add constraint stock_transfers_destination_warehouse_id_fkey FOREIGN KEY (destination_warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT;

alter table stock_transfers add constraint stock_transfers_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table stock_transfers add constraint stock_transfers_received_by_fkey FOREIGN KEY (received_by) REFERENCES auth.users(id);

alter table stock_transfers add constraint stock_transfers_source_warehouse_id_fkey FOREIGN KEY (source_warehouse_id) REFERENCES warehouses(id) ON DELETE RESTRICT;

alter table stocks add constraint stocks_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE CASCADE;

alter table stocks add constraint stocks_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table subscription_events add constraint subscription_events_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table subscription_events add constraint subscription_events_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES organization_subscriptions(id) ON DELETE SET NULL;

alter table subscription_limits add constraint subscription_limits_plan_id_fkey FOREIGN KEY (plan_id) REFERENCES subscription_plans(id) ON DELETE CASCADE;

alter table subscription_payments add constraint subscription_payments_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table subscription_payments add constraint subscription_payments_subscription_id_fkey FOREIGN KEY (subscription_id) REFERENCES organization_subscriptions(id) ON DELETE SET NULL;

alter table super_admin_modules add constraint super_admin_modules_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table super_admins add constraint super_admins_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table supplier_payments add constraint supplier_payments_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table supplier_payments add constraint supplier_payments_purchase_order_id_fkey FOREIGN KEY (purchase_order_id) REFERENCES purchase_orders(id) ON DELETE RESTRICT;

alter table supplier_payments add constraint supplier_payments_recorded_by_fkey FOREIGN KEY (recorded_by) REFERENCES auth.users(id);

alter table supplier_payments add constraint supplier_payments_supplier_id_fkey FOREIGN KEY (supplier_id) REFERENCES suppliers(id) ON DELETE RESTRICT;

alter table suppliers add constraint suppliers_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table user_permissions add constraint user_permissions_granted_by_fkey FOREIGN KEY (granted_by) REFERENCES auth.users(id);

alter table user_permissions add constraint user_permissions_permission_id_fkey FOREIGN KEY (permission_id) REFERENCES permissions(id) ON DELETE CASCADE;

alter table user_permissions add constraint user_permissions_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table user_settings add constraint user_settings_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table warehouse_inventory add constraint warehouse_inventory_article_id_fkey FOREIGN KEY (article_id) REFERENCES articles(id) ON DELETE RESTRICT;

alter table warehouse_inventory add constraint warehouse_inventory_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

alter table warehouse_inventory add constraint warehouse_inventory_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE;

alter table warehouse_users add constraint warehouse_users_user_id_fkey FOREIGN KEY (user_id) REFERENCES auth.users(id) ON DELETE CASCADE;

alter table warehouse_users add constraint warehouse_users_warehouse_id_fkey FOREIGN KEY (warehouse_id) REFERENCES warehouses(id) ON DELETE CASCADE;

alter table warehouses add constraint warehouses_manager_user_id_fkey FOREIGN KEY (manager_user_id) REFERENCES auth.users(id);

alter table warehouses add constraint warehouses_organization_id_fkey FOREIGN KEY (organization_id) REFERENCES organizations(id) ON DELETE CASCADE;

-- ===== indexes (184) =====

CREATE INDEX idx_article_categories_org ON public.article_categories USING btree (organization_id);

CREATE INDEX idx_articles_org ON public.articles USING btree (organization_id);

CREATE INDEX idx_audit_events_entity ON public.audit_events USING btree (entity_type, entity_id);

CREATE INDEX idx_audit_events_org ON public.audit_events USING btree (organization_id);

CREATE INDEX idx_audit_events_user ON public.audit_events USING btree (user_id);

CREATE INDEX idx_audit_logs_org_entity ON public.audit_logs USING btree (organization_id, entity_type, entity_id);

CREATE INDEX idx_audit_org ON public.audit_logs USING btree (organization_id);

CREATE INDEX idx_audit_org_date ON public.audit_logs USING btree (organization_id, created_at);

CREATE INDEX idx_audit_user ON public.audit_logs USING btree (user_id);

CREATE INDEX idx_client_portfolios_owner ON public.client_portfolios USING btree (owner_type, owner_user_id);

CREATE INDEX idx_clients_activity ON public.clients USING btree (organization_id, last_activity_at) WHERE (archived_at IS NULL);

CREATE INDEX idx_clients_archived ON public.clients USING btree (organization_id, archived_at);

CREATE INDEX idx_clients_last_activity ON public.clients USING btree (organization_id, last_activity_at);

CREATE INDEX idx_clients_last_activity_at ON public.clients USING btree (last_activity_at);

CREATE INDEX idx_clients_org ON public.clients USING btree (organization_id);

CREATE INDEX idx_clients_org_phone ON public.clients USING btree (organization_id, phone);

CREATE INDEX idx_clients_org_prospecteur ON public.clients USING btree (organization_id, prospecteur_id);

CREATE INDEX idx_clients_org_status ON public.clients USING btree (organization_id, status);

CREATE INDEX idx_clients_portfolio_id ON public.clients USING btree (portfolio_id);

CREATE INDEX idx_clients_prospecteur ON public.clients USING btree (prospecteur_id);

CREATE INDEX idx_commissions_org ON public.commissions USING btree (organization_id);

CREATE INDEX idx_commissions_prospecteur ON public.commissions USING btree (prospecteur_id);

CREATE INDEX idx_commissions_sale ON public.commissions USING btree (organization_id, sale_id);

CREATE INDEX idx_daily_tokens_date ON public.daily_tokens USING btree (token_date);

CREATE INDEX idx_daily_tokens_org ON public.daily_tokens USING btree (organization_id);

CREATE INDEX idx_field_visits_prospect ON public.field_visits USING btree (organization_id, prospect_id);

CREATE INDEX idx_goods_receipt_items_receipt ON public.goods_receipt_items USING btree (receipt_id);

CREATE INDEX idx_goods_receipts_org ON public.goods_receipts USING btree (organization_id);

CREATE INDEX idx_jdvcrm_clients_activity ON public.clients USING btree (organization_id, last_activity_at);

CREATE INDEX idx_jdvcrm_commissions_report_date ON public.commissions USING btree (organization_id, created_at);

CREATE INDEX idx_jdvcrm_commissions_status_prospecteur ON public.commissions USING btree (organization_id, prospecteur_id, status);

CREATE INDEX idx_jdvcrm_notifications_user ON public.notifications USING btree (user_id, read_at);

CREATE INDEX idx_jdvcrm_org_subscriptions_expiry ON public.organization_subscriptions USING btree (organization_id, expires_at) WHERE (status = ANY (ARRAY['trial'::text, 'active'::text, 'past_due'::text]));

CREATE INDEX idx_jdvcrm_payment_schedules_late_due ON public.payment_schedules USING btree (organization_id, due_date) WHERE (status = ANY (ARRAY['pending'::text, 'partial'::text, 'late'::text]));

CREATE INDEX idx_jdvcrm_payments_client ON public.payments USING btree (client_id);

CREATE INDEX idx_jdvcrm_payments_report_date ON public.payments USING btree (organization_id, payment_date);

CREATE INDEX idx_jdvcrm_payments_sale ON public.payments USING btree (sale_id);

CREATE INDEX idx_jdvcrm_payments_sale_status_date ON public.payments USING btree (sale_id, status, payment_date DESC);

CREATE INDEX idx_jdvcrm_payments_schedule_status ON public.payments USING btree (schedule_id, status);

CREATE INDEX idx_jdvcrm_prospecteur_stocks_org_prospecteur ON public.prospecteur_stocks USING btree (organization_id, prospecteur_id);

CREATE INDEX idx_jdvcrm_prospects_activity ON public.prospects USING btree (organization_id, last_contact_at);

CREATE INDEX idx_jdvcrm_prospects_followup ON public.prospects USING btree (organization_id, last_follow_up_at);

CREATE INDEX idx_jdvcrm_sale_items_sale ON public.sale_items USING btree (sale_id, organization_id);

CREATE INDEX idx_jdvcrm_sales_client ON public.sales USING btree (organization_id, client_id);

CREATE INDEX idx_jdvcrm_sales_org_prospecteur_status ON public.sales USING btree (organization_id, prospecteur_id, status, sale_date DESC);

CREATE INDEX idx_jdvcrm_sales_prospecteur ON public.sales USING btree (organization_id, prospecteur_id);

CREATE INDEX idx_jdvcrm_sales_report_date ON public.sales USING btree (organization_id, sale_date);

CREATE INDEX idx_jdvcrm_schedule_due ON public.payment_schedules USING btree (organization_id, due_date, status);

CREATE INDEX idx_jdvcrm_schedules_sale_due ON public.payment_schedules USING btree (sale_id, due_date, status);

CREATE INDEX idx_jdvcrm_stock_movements_article ON public.stock_movements USING btree (organization_id, article_id, created_at);

CREATE INDEX idx_jdvcrm_stock_movements_org_article_created ON public.stock_movements USING btree (organization_id, article_id, created_at DESC);

CREATE INDEX idx_jdvcrm_stock_movements_prospecteur ON public.stock_movements USING btree (organization_id, prospecteur_id, created_at DESC) WHERE (prospecteur_id IS NOT NULL);

CREATE INDEX idx_jdvcrm_stock_movements_reference ON public.stock_movements USING btree (reference_type, reference_id, article_id, movement_type);

CREATE INDEX idx_jdvcrm_stocks_org_article ON public.stocks USING btree (organization_id, article_id);

CREATE INDEX idx_login_security_created ON public.login_security_events USING btree (created_at);

CREATE INDEX idx_login_security_user ON public.login_security_events USING btree (user_id);

CREATE INDEX idx_members_org ON public.organization_members USING btree (organization_id, status);

CREATE INDEX idx_members_user ON public.organization_members USING btree (user_id, status);

CREATE INDEX idx_notifications_user ON public.notifications USING btree (user_id);

CREATE INDEX idx_org_members_org ON public.organization_members USING btree (organization_id);

CREATE INDEX idx_org_members_org_status ON public.organization_members USING btree (organization_id, status);

CREATE INDEX idx_org_members_user ON public.organization_members USING btree (user_id);

CREATE INDEX idx_org_members_user_status ON public.organization_members USING btree (user_id, status);

CREATE UNIQUE INDEX idx_org_personalization_org_unique ON public.organization_personalization USING btree (organization_id);

CREATE INDEX idx_organization_members_user_org ON public.organization_members USING btree (user_id, organization_id);

CREATE INDEX idx_organization_subscriptions_expires ON public.organization_subscriptions USING btree (expires_at);

CREATE INDEX idx_organization_subscriptions_org ON public.organization_subscriptions USING btree (organization_id);

CREATE INDEX idx_organization_subscriptions_status ON public.organization_subscriptions USING btree (status);

CREATE INDEX idx_payment_provider_accounts_org ON public.payment_provider_accounts USING btree (organization_id);

CREATE INDEX idx_payment_provider_accounts_provider ON public.payment_provider_accounts USING btree (provider);

CREATE INDEX idx_payment_provider_events_org ON public.payment_provider_events USING btree (organization_id);

CREATE INDEX idx_payment_provider_events_org_created ON public.payment_provider_events USING btree (organization_id, created_at DESC);

CREATE INDEX idx_payment_schedules_due ON public.payment_schedules USING btree (due_date);

CREATE INDEX idx_payment_schedules_sale ON public.payment_schedules USING btree (sale_id);

CREATE INDEX idx_payment_schedules_status ON public.payment_schedules USING btree (organization_id, status);

CREATE INDEX idx_payment_webhook_events_external ON public.payment_webhook_events USING btree (external_event_id);

CREATE INDEX idx_payment_webhook_events_org ON public.payment_webhook_events USING btree (organization_id);

CREATE INDEX idx_payment_webhook_events_org_created ON public.payment_webhook_events USING btree (organization_id, created_at DESC);

CREATE INDEX idx_payment_webhook_events_status ON public.payment_webhook_events USING btree (status);

CREATE UNIQUE INDEX idx_payment_webhook_events_unique_external ON public.payment_webhook_events USING btree (provider, external_event_id) WHERE (external_event_id IS NOT NULL);

CREATE INDEX idx_payments_date ON public.payments USING btree (payment_date);

CREATE INDEX idx_payments_merchant_reference ON public.payments USING btree (merchant_reference);

CREATE INDEX idx_payments_org ON public.payments USING btree (organization_id);

CREATE INDEX idx_payments_org_client ON public.payments USING btree (organization_id, client_id);

CREATE INDEX idx_payments_org_sale ON public.payments USING btree (organization_id, sale_id);

CREATE INDEX idx_payments_provider_transaction ON public.payments USING btree (provider_transaction_id);

CREATE INDEX idx_profiles_phone ON public.profiles USING btree (phone);

CREATE INDEX idx_prospect_activities_prospect ON public.prospect_activities USING btree (prospect_id);

CREATE INDEX idx_prospect_followups_date ON public.prospect_followups USING btree (scheduled_at);

CREATE INDEX idx_prospect_status_history_prospect ON public.prospect_status_history USING btree (prospect_id);

CREATE INDEX idx_prospecteur_stocks ON public.prospecteur_stocks USING btree (organization_id, prospecteur_id, article_id);

CREATE INDEX idx_prospecteur_stocks_prospecteur ON public.prospecteur_stocks USING btree (prospecteur_id);

CREATE INDEX idx_prospecteurs_org ON public.prospecteurs USING btree (organization_id);

CREATE INDEX idx_prospecteurs_org_status ON public.prospecteurs USING btree (organization_id, status);

CREATE INDEX idx_prospecteurs_user ON public.prospecteurs USING btree (user_id);

CREATE INDEX idx_prospects_first_name ON public.prospects USING btree (first_name);

CREATE INDEX idx_prospects_follow_up ON public.prospects USING btree (organization_id, next_follow_up_at);

CREATE INDEX idx_prospects_followup ON public.prospects USING btree (next_follow_up_at);

CREATE INDEX idx_prospects_last_contact ON public.prospects USING btree (last_contact_at);

CREATE INDEX idx_prospects_last_name ON public.prospects USING btree (last_name);

CREATE INDEX idx_prospects_next_follow_up ON public.prospects USING btree (organization_id, next_follow_up_at);

CREATE INDEX idx_prospects_next_follow_up_at ON public.prospects USING btree (next_follow_up_at);

CREATE INDEX idx_prospects_org ON public.prospects USING btree (organization_id);

CREATE INDEX idx_prospects_org_phone ON public.prospects USING btree (organization_id, phone);

CREATE INDEX idx_prospects_org_prospecteur ON public.prospects USING btree (organization_id, prospecteur_id);

CREATE INDEX idx_prospects_org_temperature ON public.prospects USING btree (organization_id, temperature);

CREATE INDEX idx_prospects_organization_category ON public.prospects USING btree (organization_id, category);

CREATE INDEX idx_prospects_organization_id ON public.prospects USING btree (organization_id);

CREATE INDEX idx_prospects_organization_phone ON public.prospects USING btree (organization_id, phone);

CREATE INDEX idx_prospects_organization_temperature ON public.prospects USING btree (organization_id, temperature);

CREATE INDEX idx_prospects_phone ON public.prospects USING btree (phone) WHERE (phone IS NOT NULL);

CREATE INDEX idx_prospects_portfolio_id ON public.prospects USING btree (portfolio_id);

CREATE INDEX idx_prospects_prospecteur ON public.prospects USING btree (prospecteur_id);

CREATE INDEX idx_prospects_prospecteur_id ON public.prospects USING btree (prospecteur_id);

CREATE INDEX idx_prospects_purchase_date ON public.prospects USING btree (organization_id, purchase_date_planned);

CREATE INDEX idx_prospects_purchase_date_planned ON public.prospects USING btree (purchase_date_planned);

CREATE INDEX idx_prospects_status ON public.prospects USING btree (status);

CREATE INDEX idx_prospects_temperature ON public.prospects USING btree (temperature);

CREATE INDEX idx_purchase_order_items_order ON public.purchase_order_items USING btree (purchase_order_id);

CREATE INDEX idx_purchase_orders_org ON public.purchase_orders USING btree (organization_id);

CREATE INDEX idx_purchase_orders_supplier ON public.purchase_orders USING btree (supplier_id);

CREATE INDEX idx_sale_items_article ON public.sale_items USING btree (article_id);

CREATE INDEX idx_sale_items_org ON public.sale_items USING btree (organization_id);

CREATE INDEX idx_sale_items_sale ON public.sale_items USING btree (sale_id);

CREATE INDEX idx_sales_client ON public.sales USING btree (client_id);

CREATE INDEX idx_sales_date ON public.sales USING btree (sale_date);

CREATE INDEX idx_sales_deadline ON public.sales USING btree (organization_id, deadline_date) WHERE (deadline_date IS NOT NULL);

CREATE INDEX idx_sales_org ON public.sales USING btree (organization_id);

CREATE INDEX idx_sales_org_prospecteur ON public.sales USING btree (organization_id, prospecteur_id);

CREATE INDEX idx_sales_prospecteur ON public.sales USING btree (prospecteur_id);

CREATE INDEX idx_sales_returns_sale ON public.sales_returns USING btree (sale_id);

CREATE INDEX idx_sales_status ON public.sales USING btree (organization_id, status);

CREATE INDEX idx_schedules_due ON public.payment_schedules USING btree (sale_id, due_date);

CREATE INDEX idx_serial_numbers_article ON public.serial_numbers USING btree (article_id);

CREATE INDEX idx_serial_numbers_org ON public.serial_numbers USING btree (organization_id);

CREATE INDEX idx_stock_movements_article ON public.stock_movements USING btree (article_id);

CREATE INDEX idx_stock_movements_org ON public.stock_movements USING btree (organization_id);

CREATE INDEX idx_stock_movements_prospecteur ON public.stock_movements USING btree (organization_id, prospecteur_id);

CREATE INDEX idx_stock_transfer_items_transfer ON public.stock_transfer_items USING btree (transfer_id);

CREATE INDEX idx_stock_transfers_org ON public.stock_transfers USING btree (organization_id);

CREATE INDEX idx_stocks_article ON public.stocks USING btree (article_id);

CREATE INDEX idx_stocks_org ON public.stocks USING btree (organization_id);

CREATE INDEX idx_subscription_events_org_created ON public.subscription_events USING btree (organization_id, created_at DESC);

CREATE INDEX idx_subscription_payments_org_created ON public.subscription_payments USING btree (organization_id, created_at DESC);

CREATE INDEX idx_subscription_plans_active_code ON public.subscription_plans USING btree (code) WHERE (active = true);

CREATE INDEX idx_super_admin_modules_code ON public.super_admin_modules USING btree (module_code);

CREATE INDEX idx_super_admin_modules_user ON public.super_admin_modules USING btree (user_id);

CREATE INDEX idx_super_admin_user ON public.super_admins USING btree (user_id);

CREATE INDEX idx_super_admins_user_actif ON public.super_admins USING btree (user_id, actif);

CREATE INDEX idx_super_admins_user_status ON public.super_admins USING btree (user_id, status);

CREATE INDEX idx_supplier_payments_org ON public.supplier_payments USING btree (organization_id);

CREATE INDEX idx_supplier_payments_supplier ON public.supplier_payments USING btree (supplier_id);

CREATE INDEX idx_suppliers_org ON public.suppliers USING btree (organization_id);

CREATE INDEX idx_tokens_org_date ON public.daily_tokens USING btree (organization_id, token_date);

CREATE INDEX idx_visits_org ON public.field_visits USING btree (organization_id);

CREATE INDEX idx_visits_prospecteur ON public.field_visits USING btree (prospecteur_id);

CREATE INDEX idx_warehouse_inventory_org ON public.warehouse_inventory USING btree (organization_id);

CREATE INDEX idx_warehouses_org ON public.warehouses USING btree (organization_id);

CREATE INDEX ix_jdvcrm_clients_org_prospecteur ON public.clients USING btree (organization_id, prospecteur_id) WHERE (archived_at IS NULL);

CREATE INDEX ix_jdvcrm_field_visits_prospecteur_date ON public.field_visits USING btree (organization_id, prospecteur_id, visit_date DESC);

CREATE INDEX ix_jdvcrm_prospect_activities_portfolio ON public.prospect_activities USING btree (organization_id, prospect_id, activity_date DESC);

CREATE INDEX ix_jdvcrm_prospect_assignments_active ON public.prospect_assignments USING btree (organization_id, prospect_id) WHERE (active = true);

CREATE INDEX ix_jdvcrm_prospect_followups_due ON public.prospect_followups USING btree (organization_id, scheduled_at) WHERE (status = 'pending'::text);

CREATE INDEX ix_jdvcrm_prospects_contact ON public.prospects USING btree (organization_id, last_contact_at) WHERE (archived_at IS NULL);

CREATE INDEX ix_jdvcrm_prospects_followup ON public.prospects USING btree (organization_id, next_follow_up_at) WHERE (archived_at IS NULL);

CREATE INDEX ix_jdvcrm_prospects_org_prospecteur ON public.prospects USING btree (organization_id, prospecteur_id) WHERE (archived_at IS NULL);

CREATE INDEX ix_jdvcrm_status_history_prospect ON public.prospect_status_history USING btree (organization_id, prospect_id, created_at DESC);

CREATE UNIQUE INDEX uq_jdvcrm_org_active_subscription ON public.organization_subscriptions USING btree (organization_id) WHERE (status = ANY (ARRAY['pending'::text, 'trial'::text, 'active'::text, 'past_due'::text]));

CREATE UNIQUE INDEX uq_jdvcrm_provider_merchant_reference ON public.payments USING btree (organization_id, provider, merchant_reference) WHERE ((merchant_reference IS NOT NULL) AND (merchant_reference <> ''::text));

CREATE UNIQUE INDEX uq_jdvcrm_provider_transaction ON public.payments USING btree (organization_id, provider, provider_transaction_id) WHERE ((provider_transaction_id IS NOT NULL) AND (provider_transaction_id <> ''::text));

CREATE UNIQUE INDEX uq_jdvcrm_schedule_sale_installment ON public.payment_schedules USING btree (sale_id, installment_number);

CREATE UNIQUE INDEX uq_jdvcrm_stock_return_movement ON public.stock_movements USING btree (reference_type, reference_id, article_id, movement_type) WHERE ((reference_type = 'sale_return'::text) AND (reference_id IS NOT NULL) AND (movement_type = 'return'::text));

CREATE UNIQUE INDEX uq_jdvcrm_stock_sale_movement ON public.stock_movements USING btree (reference_type, reference_id, movement_type) WHERE ((reference_type = 'sale'::text) AND (reference_id IS NOT NULL));

CREATE UNIQUE INDEX uq_jdvcrm_transfer_in_movement ON public.stock_movements USING btree (reference_type, reference_id, movement_type) WHERE ((reference_type = 'stock_transfer'::text) AND (reference_id IS NOT NULL) AND (movement_type = 'transfer_in'::text));

CREATE UNIQUE INDEX uq_jdvcrm_transfer_out_movement ON public.stock_movements USING btree (reference_type, reference_id, movement_type) WHERE ((reference_type = 'stock_transfer'::text) AND (reference_id IS NOT NULL) AND (movement_type = 'transfer_out'::text));

CREATE UNIQUE INDEX uq_payment_provider_events_provider_event_id ON public.payment_provider_events USING btree (provider, provider_event_id) WHERE (provider_event_id IS NOT NULL);

CREATE UNIQUE INDEX uq_payment_schedules_sale_installment ON public.payment_schedules USING btree (sale_id, installment_number);

CREATE UNIQUE INDEX uq_payment_webhook_events_provider_external_event_id ON public.payment_webhook_events USING btree (provider, external_event_id) WHERE (external_event_id IS NOT NULL);

CREATE UNIQUE INDEX uq_subscription_limits_plan_resource ON public.subscription_limits USING btree (plan_id, resource_code);

CREATE UNIQUE INDEX uq_subscription_payments_provider_reference ON public.subscription_payments USING btree (provider, provider_reference) WHERE (provider_reference IS NOT NULL);

CREATE UNIQUE INDEX ux_jdvcrm_active_serial_assignment ON public.article_serial_assignments USING btree (serial_number_id) WHERE (active = true);

CREATE UNIQUE INDEX ux_jdvcrm_commission_sale_prospecteur ON public.commissions USING btree (sale_id, prospecteur_id) WHERE ((sale_id IS NOT NULL) AND (prospecteur_id IS NOT NULL));

CREATE UNIQUE INDEX ux_jdvcrm_serial_number_normalized ON public.serial_numbers USING btree (organization_id, lower(TRIM(BOTH FROM serial_number)));

CREATE UNIQUE INDEX ux_payment_refunds_payment_processed ON public.payment_refunds USING btree (payment_id) WHERE (status = 'processed'::text);

-- ===== enable_rls (76) =====

alter table public.article_categories enable row level security;

alter table public.article_serial_assignments enable row level security;

alter table public.articles enable row level security;

alter table public.audit_events enable row level security;

alter table public.audit_logs enable row level security;

alter table public.call_center_tasks enable row level security;

alter table public.call_logs enable row level security;

alter table public.client_portfolios enable row level security;

alter table public.clients enable row level security;

alter table public.commissions enable row level security;

alter table public.company_settings enable row level security;

alter table public.countries enable row level security;

alter table public.currencies enable row level security;

alter table public.daily_tokens enable row level security;





alter table public.document_sequences enable row level security;

alter table public.document_templates enable row level security;

alter table public.documents enable row level security;

alter table public.exchange_rates enable row level security;

alter table public.field_visits enable row level security;

alter table public.follow_up_reminders enable row level security;

alter table public.goods_receipt_items enable row level security;

alter table public.goods_receipts enable row level security;

alter table public.languages enable row level security;

alter table public.login_security_events enable row level security;

alter table public.notification_events enable row level security;

alter table public.notification_preferences enable row level security;

alter table public.notifications enable row level security;

alter table public.organization_members enable row level security;

alter table public.organization_personalization enable row level security;

alter table public.organization_settings enable row level security;

alter table public.organization_subscriptions enable row level security;

alter table public.organizations enable row level security;

alter table public.payment_provider_accounts enable row level security;

alter table public.payment_provider_events enable row level security;

alter table public.payment_refunds enable row level security;

alter table public.payment_schedules enable row level security;

alter table public.payment_webhook_events enable row level security;

alter table public.payments enable row level security;

alter table public.permissions enable row level security;

alter table public.profiles enable row level security;

alter table public.prospect_activities enable row level security;

alter table public.prospect_assignments enable row level security;

alter table public.prospect_followups enable row level security;

alter table public.prospect_status_history enable row level security;

alter table public.prospecteur_stocks enable row level security;

alter table public.prospecteurs enable row level security;

alter table public.prospects enable row level security;

alter table public.purchase_order_items enable row level security;

alter table public.purchase_orders enable row level security;

alter table public.role_permissions enable row level security;

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

alter table public.super_admins enable row level security;

alter table public.supplier_payments enable row level security;

alter table public.suppliers enable row level security;

alter table public.user_permissions enable row level security;

alter table public.user_settings enable row level security;

alter table public.warehouse_inventory enable row level security;

alter table public.warehouse_users enable row level security;

alter table public.warehouses enable row level security;

-- ===== functions (119) =====

CREATE OR REPLACE FUNCTION public.check_organization_access(p_organization_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
DECLARE v_user_id uuid; v_org_status text; v_subscription_status text; v_subscription_id uuid; v_plan_code text; v_subscription_state text; v_started_at timestamptz; v_expires_at timestamptz; v_days_remaining integer; v_is_member boolean; v_is_super_admin boolean;
BEGIN
 v_user_id:=auth.uid();
 IF v_user_id IS NULL THEN RETURN jsonb_build_object('access',false,'status','unauthenticated','days_remaining',0); END IF;
 SELECT EXISTS(SELECT 1 FROM public.super_admins sa WHERE sa.user_id=v_user_id AND sa.status='active' AND COALESCE(sa.actif,true)=true) INTO v_is_super_admin;
 SELECT EXISTS(SELECT 1 FROM public.organization_members om WHERE om.organization_id=p_organization_id AND om.user_id=v_user_id AND om.status='active') INTO v_is_member;
 IF NOT v_is_member AND NOT v_is_super_admin THEN RETURN jsonb_build_object('access',false,'status','forbidden','days_remaining',0); END IF;
 SELECT o.status,o.subscription_status INTO v_org_status,v_subscription_status FROM public.organizations o WHERE o.id=p_organization_id;
 IF v_org_status IS NULL THEN RETURN jsonb_build_object('access',false,'status','organization_not_found','days_remaining',0); END IF;
 IF v_org_status IN('suspended','blocked') THEN RETURN jsonb_build_object('access',false,'status',v_org_status,'days_remaining',0); END IF;
 SELECT os.id,sp.code,os.status,os.started_at,os.expires_at INTO v_subscription_id,v_plan_code,v_subscription_state,v_started_at,v_expires_at
 FROM public.organization_subscriptions os JOIN public.subscription_plans sp ON sp.id=os.plan_id
 WHERE os.organization_id=p_organization_id ORDER BY os.created_at DESC LIMIT 1;
 IF v_subscription_id IS NULL THEN RETURN jsonb_build_object('access',false,'status','inactive','days_remaining',0,'subscription_id',null,'plan_code',null); END IF;
 IF v_expires_at IS NOT NULL AND now()>=v_expires_at AND v_subscription_state IN('active','past_due','trial') THEN
  UPDATE public.organization_subscriptions SET status='expired',updated_at=now() WHERE id=v_subscription_id;
  UPDATE public.organizations SET subscription_status='expired',status='expired',updated_at=now() WHERE id=p_organization_id;
  RETURN jsonb_build_object('access',false,'status','expired','days_remaining',0,'subscription_id',v_subscription_id,'plan_code',v_plan_code,'started_at',v_started_at,'expires_at',v_expires_at);
 END IF;
 IF v_subscription_state='active' THEN
  v_days_remaining:=CASE WHEN v_expires_at IS NULL THEN 0 ELSE GREATEST(0,CEIL(EXTRACT(EPOCH FROM(v_expires_at-now()))/86400))::integer END;
  IF v_plan_code='TRIAL' THEN
   UPDATE public.organizations SET status='trial',subscription_status='trial',updated_at=now() WHERE id=p_organization_id AND status NOT IN('suspended','blocked');
   RETURN jsonb_build_object('access',true,'status','trial','days_remaining',v_days_remaining,'subscription_id',v_subscription_id,'plan_code',v_plan_code,'started_at',v_started_at,'expires_at',v_expires_at);
  END IF;
  UPDATE public.organizations SET status='active',subscription_status='active',updated_at=now() WHERE id=p_organization_id AND status NOT IN('suspended','blocked');
  RETURN jsonb_build_object('access',true,'status','active','days_remaining',v_days_remaining,'subscription_id',v_subscription_id,'plan_code',v_plan_code,'started_at',v_started_at,'expires_at',v_expires_at);
 END IF;
 RETURN jsonb_build_object('access',false,'status',COALESCE(v_subscription_state,'inactive'),'days_remaining',0,'subscription_id',v_subscription_id,'plan_code',v_plan_code,'started_at',v_started_at,'expires_at',v_expires_at);
END;
$function$
;

CREATE OR REPLACE FUNCTION public.create_company_onboarding(p_user_id uuid, p_company_name text, p_legal_name text, p_email text, p_phone text, p_country text, p_city text, p_address text, p_website text, p_industry text, p_team_size text, p_plan_code text, p_first_name text, p_last_name text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
DECLARE
  v_org uuid;
  v_plan uuid;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'AUTHENTICATION_REQUIRED';
  END IF;

  IF auth.uid() <> p_user_id AND NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'ACCESS_DENIED';
  END IF;

  IF p_company_name IS NULL OR trim(p_company_name) = '' THEN
    RAISE EXCEPTION 'COMPANY_NAME_REQUIRED';
  END IF;

  SELECT id INTO v_plan
  FROM public.subscription_plans
  WHERE code = upper(trim(p_plan_code))
    AND active = true
  LIMIT 1;

  IF v_plan IS NULL THEN
    RAISE EXCEPTION 'PLAN_NOT_FOUND';
  END IF;

  INSERT INTO public.organizations(
    name, legal_name, email, phone, country, city, address, website,
    status, subscription_status, language, currency, timezone, owner_user_id
  )
  VALUES(
    trim(p_company_name), p_legal_name, p_email, p_phone,
    coalesce(nullif(trim(p_country), ''), 'Bénin'), p_city, p_address, p_website,
    'trial', 'trial', 'fr', 'XOF', 'Africa/Porto-Novo', p_user_id
  )
  RETURNING id INTO v_org;

  INSERT INTO public.profiles(
    id, first_name, last_name, display_name, phone, country,
    preferred_language, status
  )
  VALUES(
    p_user_id, p_first_name, p_last_name,
    trim(coalesce(p_first_name,'') || ' ' || coalesce(p_last_name,'')),
    p_phone, p_country, 'fr', 'active'
  )
  ON CONFLICT(id) DO UPDATE SET
    first_name = excluded.first_name,
    last_name = excluded.last_name,
    display_name = excluded.display_name,
    phone = excluded.phone,
    country = excluded.country,
    preferred_language = 'fr',
    status = 'active',
    updated_at = now();

  INSERT INTO public.organization_members(organization_id, user_id, role, status)
  VALUES(v_org, p_user_id, 'business_admin', 'active');

  INSERT INTO public.organization_settings(organization_id, settings)
  VALUES(
    v_org,
    jsonb_build_object(
      'industry', coalesce(p_industry,''),
      'team_size', coalesce(p_team_size,''),
      'address', coalesce(p_address,''),
      'website', coalesce(p_website,''),
      'language', 'fr',
      'currency', 'XOF',
      'timezone', 'Africa/Porto-Novo'
    )
  );

  INSERT INTO public.organization_subscriptions(
    organization_id, plan_id, status, started_at, expires_at, auto_renew
  )
  SELECT v_org, id, 'trial', now(), now() + interval '14 days', false
  FROM public.subscription_plans
  WHERE code = 'TRIAL' AND active = true
  LIMIT 1
  ON CONFLICT DO NOTHING;

  RETURN v_org;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.ensure_organization_personalization(p_organization_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$

DECLARE
    v_id UUID;

BEGIN

    IF NOT (
        private.is_super_admin()
        OR private.is_org_admin(p_organization_id)
    ) THEN

        RAISE EXCEPTION 'Accès refusé';

    END IF;


    INSERT INTO public.organization_personalization (
        organization_id
    )
    VALUES (
        p_organization_id
    )
    ON CONFLICT (organization_id)
    DO NOTHING
    RETURNING id INTO v_id;


    IF v_id IS NULL THEN

        SELECT id
        INTO v_id
        FROM public.organization_personalization
        WHERE organization_id = p_organization_id;

    END IF;


    RETURN v_id;

END;

$function$
;

CREATE OR REPLACE FUNCTION public.generate_client_code()
 RETURNS text
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  next_number integer;
  generated_code text;
begin

  select coalesce(
    max(
      case
        when c.code ~ '^CLI-[0-9]+$'
        then substring(c.code from 5)::integer
        else 0
      end
    ),
    0
  ) + 1
  into next_number
  from public.clients c;

  generated_code :=
    'CLI-' || lpad(next_number::text, 6, '0');

  return generated_code;

end;
$function$
;

CREATE OR REPLACE FUNCTION public.generate_prospecteur_code()
 RETURNS text
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
declare
  next_number integer;
  generated_code text;
begin

  select coalesce(
    max(
      case
        when p.code ~ '^PROS-[0-9]+$'
        then substring(p.code from 6)::integer
        else 0
      end
    ),
    0
  ) + 1
  into next_number
  from public.prospecteurs p;

  generated_code :=
    'PROS-' || lpad(next_number::text, 4, '0');

  return generated_code;

end;
$function$
;

CREATE OR REPLACE FUNCTION public.handle_new_user()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'extensions'
AS $function$
BEGIN
  INSERT INTO public.profiles(id,first_name,last_name,display_name,phone,country,preferred_language,status)
  VALUES(NEW.id,NEW.raw_user_meta_data->>'first_name',NEW.raw_user_meta_data->>'last_name',COALESCE(NEW.raw_user_meta_data->>'display_name',split_part(COALESCE(NEW.email,''),'@',1)),NEW.raw_user_meta_data->>'phone',COALESCE(NEW.raw_user_meta_data->>'country','Bénin'),'fr','active')
  ON CONFLICT(id) DO NOTHING;
  RETURN NEW;
END; $function$
;

CREATE OR REPLACE FUNCTION public.jdv_apply_successful_payment_to_sale()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
DECLARE
  v_paid numeric(14,2);
  v_remaining numeric(14,2);
BEGIN

  IF NEW.sale_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF lower(coalesce(NEW.status, '')) NOT IN (
    'successful',
    'paid',
    'completed',
    'approved'
  ) THEN
    RETURN NEW;
  END IF;

  IF TG_OP = 'UPDATE'
     AND lower(coalesce(OLD.status, '')) IN (
       'successful',
       'paid',
       'completed',
       'approved'
     )
  THEN
    RETURN NEW;
  END IF;

  SELECT
    greatest(0, coalesce(s.amount_paid, 0) + NEW.amount),
    greatest(
      0,
      coalesce(s.amount_remaining, 0) - NEW.amount
    )
  INTO
    v_paid,
    v_remaining
  FROM public.sales s
  WHERE s.id = NEW.sale_id
    AND s.organization_id = NEW.organization_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RETURN NEW;
  END IF;

  UPDATE public.sales
  SET amount_paid = v_paid,
      amount_remaining = v_remaining,
      status = CASE
        WHEN v_remaining <= 0 THEN 'paid'
        WHEN v_paid > 0 THEN 'partial'
        ELSE status
      END,
      updated_at = now()
  WHERE id = NEW.sale_id
    AND organization_id = NEW.organization_id;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdv_archive_inactive_clients()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
DECLARE
  v_count integer;
BEGIN

  WITH archived AS (
    UPDATE public.clients
    SET status = 'archived',
        archived_at = coalesce(archived_at, now()),
        updated_at = now()
    WHERE coalesce(status, '') NOT IN (
      'archived',
      'deleted'
    )
    AND (
      last_activity_at IS NULL
      OR last_activity_at <= now() - interval '3 months'
    )
    RETURNING id
  )
  SELECT count(*)
  INTO v_count
  FROM archived;

  RETURN v_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdv_audit_payment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
BEGIN

  INSERT INTO public.audit_logs (
    organization_id,
    user_id,
    action,
    entity_type,
    entity_id,
    old_data,
    new_data
  )
  VALUES (
    NEW.organization_id,
    COALESCE(NEW.recorded_by, auth.uid()),
    CASE
      WHEN TG_OP = 'INSERT' THEN 'payment_created'
      WHEN TG_OP = 'UPDATE' THEN 'payment_updated'
      ELSE 'payment_changed'
    END,
    'payment',
    NEW.id,
    CASE
      WHEN TG_OP = 'UPDATE'
        THEN to_jsonb(OLD)
      ELSE NULL
    END,
    to_jsonb(NEW)
  );

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdv_business_integrity_report()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
DECLARE
  v_negative_stocks integer;
  v_duplicate_prospects integer;
  v_overdue_schedules integer;
  v_archived_clients integer;
BEGIN

  SELECT count(*)
  INTO v_negative_stocks
  FROM public.stocks
  WHERE quantity < 0
     OR reserved_quantity < 0
     OR reserved_quantity > quantity;

  SELECT count(*)
  INTO v_duplicate_prospects
  FROM public.prospects
  WHERE duplicate_phone_flag = true;

  SELECT count(*)
  INTO v_overdue_schedules
  FROM public.payment_schedules
  WHERE due_date < CURRENT_DATE
    AND paid_amount < expected_amount
    AND coalesce(status, '') NOT IN ('paid', 'cancelled');

  SELECT count(*)
  INTO v_archived_clients
  FROM public.clients
  WHERE status = 'archived';

  RETURN jsonb_build_object(
    'generated_at', now(),
    'negative_or_invalid_stocks', v_negative_stocks,
    'duplicate_prospects_flagged', v_duplicate_prospects,
    'overdue_payment_schedules', v_overdue_schedules,
    'archived_clients', v_archived_clients
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdv_process_prospect_followups()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
DECLARE
  v_count integer := 0;
BEGIN

  WITH candidates AS (
    SELECT
      p.id,
      p.organization_id,
      p.prospecteur_id,
      p.first_name,
      p.last_name
    FROM public.prospects p
    WHERE coalesce(p.status, '') NOT IN (
      'converted',
      'archived',
      'closed',
      'deleted'
    )
    AND (
      p.last_contact_at IS NULL
      OR p.last_contact_at <= now() - interval '14 days'
    )
    AND (
      p.last_follow_up_at IS NULL
      OR p.last_follow_up_at <= now() - interval '14 days'
    )
  ),
  inserted AS (
    INSERT INTO public.notifications (
      user_id,
      organization_id,
      type,
      title,
      message
    )
    SELECT
      pr.user_id,
      c.organization_id,
      'prospect_follow_up',
      'Prospect à relancer',
      'Le prospect '
        || trim(coalesce(c.first_name, '') || ' ' || coalesce(c.last_name, ''))
        || ' n''a pas eu de contact depuis au moins 14 jours.'
    FROM candidates c
    JOIN public.prospecteurs pr
      ON pr.id = c.prospecteur_id
     AND pr.organization_id = c.organization_id
    WHERE pr.user_id IS NOT NULL
    RETURNING id
  )
  SELECT count(*)
  INTO v_count
  FROM inserted;

  UPDATE public.prospects p
  SET last_follow_up_at = now(),
      updated_at = now()
  WHERE (
    p.last_contact_at IS NULL
    OR p.last_contact_at <= now() - interval '14 days'
  )
  AND (
    p.last_follow_up_at IS NULL
    OR p.last_follow_up_at <= now() - interval '14 days'
  )
  AND coalesce(p.status, '') NOT IN (
    'converted',
    'archived',
    'closed',
    'deleted'
  );

  RETURN v_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdv_refresh_payment_schedule_from_payment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
DECLARE
  v_schedule_id uuid;
BEGIN

  IF NEW.sale_id IS NULL THEN
    RETURN NEW;
  END IF;

  IF lower(coalesce(NEW.status, '')) NOT IN (
    'successful',
    'paid',
    'completed',
    'approved'
  ) THEN
    RETURN NEW;
  END IF;

  IF NEW.token_id IS NOT NULL THEN
    RETURN NEW;
  END IF;

  /*
    On affecte le paiement aux échéances impayées
    dans l'ordre chronologique.
  */
  WITH target AS (
    SELECT ps.id
    FROM public.payment_schedules ps
    WHERE ps.sale_id = NEW.sale_id
      AND ps.paid_amount < ps.expected_amount
    ORDER BY ps.due_date, ps.installment_number
    LIMIT 1
  )
  UPDATE public.payment_schedules ps
  SET paid_amount = least(
        ps.expected_amount,
        ps.paid_amount + NEW.amount
      ),
      status = CASE
        WHEN ps.paid_amount + NEW.amount >= ps.expected_amount
          THEN 'paid'
        WHEN ps.paid_amount + NEW.amount > 0
          THEN 'partial'
        ELSE ps.status
      END,
      updated_at = now()
  FROM target t
  WHERE ps.id = t.id;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdv_run_daily_business_maintenance()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
DECLARE
  v_followups integer := 0;
  v_archived integer := 0;
BEGIN

  SELECT public.jdv_process_prospect_followups()
  INTO v_followups;

  SELECT public.jdv_archive_inactive_clients()
  INTO v_archived;

  RETURN jsonb_build_object(
    'executed_at', now(),
    'prospect_followups_created', v_followups,
    'clients_archived', v_archived
  );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdv_update_client_activity_from_payment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
BEGIN

  IF NEW.client_id IS NOT NULL
     AND lower(coalesce(NEW.status, '')) IN (
       'successful',
       'paid',
       'completed',
       'approved'
     )
  THEN

    UPDATE public.clients
    SET last_activity_at = coalesce(NEW.payment_date, now()),
        status = CASE
          WHEN status = 'archived' THEN 'active'
          ELSE status
        END,
        archived_at = CASE
          WHEN status = 'archived' THEN NULL
          ELSE archived_at
        END,
        updated_at = now()
    WHERE id = NEW.client_id
      AND organization_id = NEW.organization_id;

  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdv_validate_stock_quantity()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'private', 'auth'
AS $function$
BEGIN

  IF NEW.quantity < 0 THEN
    RAISE EXCEPTION
      'Stock impossible : la quantité ne peut pas être négative.';
  END IF;

  IF NEW.reserved_quantity < 0 THEN
    RAISE EXCEPTION
      'Stock impossible : la quantité réservée ne peut pas être négative.';
  END IF;

  IF NEW.reserved_quantity > NEW.quantity THEN
    RAISE EXCEPTION
      'Stock impossible : la quantité réservée dépasse la quantité disponible.';
  END IF;

  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_activate_subscription_v1(p_subscription_id uuid, p_provider text DEFAULT NULL::text, p_provider_reference text DEFAULT NULL::text, p_started_at timestamp with time zone DEFAULT now())
 RETURNS organization_subscriptions
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare v_sub public.organization_subscriptions;
        v_plan public.subscription_plans;
        v_end timestamptz;
begin
  if auth.uid() is null or not private.is_super_admin() then
    raise exception 'SUPER_ADMIN_REQUIRED';
  end if;

  select * into v_sub
  from public.organization_subscriptions
  where id = p_subscription_id
  for update;

  if not found then
    raise exception 'SUBSCRIPTION_NOT_FOUND';
  end if;

  select * into v_plan from public.subscription_plans where id = v_sub.plan_id and active = true;
  if not found then
    raise exception 'PLAN_NOT_FOUND';
  end if;

  v_end := p_started_at + make_interval(days => v_plan.duration_days);

  update public.organization_subscriptions
     set status = 'active',
         started_at = p_started_at,
         expires_at = v_end,
         external_reference = coalesce(p_provider_reference, external_reference),
         updated_at = now()
   where id = v_sub.id
   returning * into v_sub;

  update public.organizations
     set subscription_status = 'active', updated_at = now()
   where id = v_sub.organization_id;

  return v_sub;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_after_payment_recalculate()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

BEGIN

    IF NEW.sale_id IS NOT NULL
       AND NEW.status = 'completed'
    THEN

        PERFORM public.jdvcrm_recalculate_sale(
            NEW.sale_id
        );

    END IF;


    RETURN NEW;

END;

$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_after_payment_schedule_refresh()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

BEGIN

    IF NEW.sale_id IS NOT NULL
       AND NEW.status = 'completed'
    THEN

        PERFORM public.jdvcrm_refresh_payment_schedule(
            NEW.sale_id
        );

    END IF;


    RETURN NEW;

END;

$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_after_payment_v43()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN

    PERFORM public.jdvcrm_process_payment_v43(NEW.id);

    RETURN NEW;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_after_sale_v42()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN

    PERFORM public.jdvcrm_process_sale_v42(NEW.id);

    RETURN NEW;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_archive_cold_clients()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

DECLARE
    v_count INTEGER;

BEGIN

    UPDATE public.clients c

    SET
        status = 'archived',
        archived_at = COALESCE(c.archived_at, now()),
        updated_at = now()

    WHERE c.status NOT IN (
        'archived',
        'deleted'
    )

    AND COALESCE(
        c.last_activity_at,
        c.last_payment_at,
        c.created_at
    ) <= now() - INTERVAL '3 months';


    GET DIAGNOSTICS v_count = ROW_COUNT;


    RETURN v_count;

END;

$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_archive_inactive_clients(p_organization_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public', 'private', 'auth'
AS $function$
DECLARE
    v_count integer;
BEGIN

    UPDATE public.clients
    SET
        status = 'archived',
        archived_at = COALESCE(archived_at, now()),
        updated_at = now()
    WHERE organization_id = p_organization_id
      AND archived_at IS NULL
      AND COALESCE(
            last_activity_at,
            created_at
          ) <= now() - interval '3 months'
      AND COALESCE(status, '') NOT IN
          ('archived', 'inactive');


    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN v_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_archive_inactive_clients_v1(p_organization_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare v_count integer;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 if not(private.is_super_admin() or private.is_org_admin(p_organization_id)) then raise exception 'Accès refusé'; end if;
 update public.clients set status='archived',archived_at=coalesce(archived_at,now()),updated_at=now()
 where organization_id=p_organization_id and archived_at is null and coalesce(last_activity_at,created_at)<=now()-interval '3 months' and coalesce(status,'') not in ('archived','inactive');
 get diagnostics v_count=row_count; return v_count;
end $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_archive_old_prospects(p_organization_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public', 'private', 'auth'
AS $function$
DECLARE
    v_count integer;
BEGIN

    UPDATE public.prospects
    SET
        status = 'archived',
        archived_at = COALESCE(archived_at, now()),
        updated_at = now()
    WHERE organization_id = p_organization_id
      AND archived_at IS NULL
      AND COALESCE(
            last_contact_at,
            created_at
          ) <= now() - interval '3 months'
      AND COALESCE(status, '') NOT IN
          ('converted', 'archived', 'closed');


    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN v_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_archive_old_prospects_v1(p_organization_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare v_count integer;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 if not(private.is_super_admin() or private.is_org_admin(p_organization_id)) then raise exception 'Accès refusé'; end if;
 update public.prospects set status='archived',archived_at=coalesce(archived_at,now()),updated_at=now()
 where organization_id=p_organization_id and archived_at is null and coalesce(last_contact_at,created_at)<=now()-interval '3 months' and coalesce(status,'') not in ('converted','archived','closed');
 get diagnostics v_count=row_count; return v_count;
end $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_audit_organization_member()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
begin
  insert into public.audit_logs (
    organization_id,
    user_id,
    action,
    entity_type,
    entity_id,
    old_data,
    new_data
  )
  values (
    coalesce(new.organization_id, old.organization_id),
    auth.uid(),
    case
      when tg_op = 'INSERT' then 'organization_member_created'
      when tg_op = 'UPDATE' then
        case
          when old.role is distinct from new.role then 'organization_member_role_changed'
          when old.status is distinct from new.status then 'organization_member_status_changed'
          when old.user_id is distinct from new.user_id then 'organization_member_user_changed'
          else 'organization_member_updated'
        end
      when tg_op = 'DELETE' then 'organization_member_deleted'
    end,
    'organization_member',
    coalesce(new.id, old.id),
    case when tg_op in ('UPDATE','DELETE') then to_jsonb(old) else null end,
    case when tg_op in ('INSERT','UPDATE') then to_jsonb(new) else null end
  );

  return coalesce(new, old);
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_audit_prospect_assignment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

BEGIN

    IF NEW.prospecteur_id IS DISTINCT FROM OLD.prospecteur_id THEN

        INSERT INTO public.audit_logs (
            organization_id,
            user_id,
            action,
            entity_type,
            entity_id,
            before_data,
            after_data
        )

        VALUES (
            NEW.organization_id,
            auth.uid(),
            'prospecteur_assignment_changed',
            'prospect',
            NEW.id,
            jsonb_build_object(
                'prospecteur_id',
                OLD.prospecteur_id
            ),
            jsonb_build_object(
                'prospecteur_id',
                NEW.prospecteur_id
            )
        );

    END IF;


    RETURN NEW;

END;

$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_audit_sale()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare
    v_user_id uuid;
begin
    v_user_id := auth.uid();
    insert into public.audit_logs (organization_id,user_id,action,entity_type,entity_id,old_data,new_data)
    values (new.organization_id,v_user_id,case when tg_op='INSERT' then 'sale_created' else 'sale_updated' end,'sale',new.id,case when tg_op='UPDATE' then to_jsonb(old) else null end,to_jsonb(new));
    return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_audit_stock_movement()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
begin
    insert into public.audit_logs (organization_id,user_id,action,entity_type,entity_id,new_data)
    values (new.organization_id,new.created_by,'stock_movement_created','stock_movement',new.id,to_jsonb(new));
    return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_block_duplicate_client_phone_v41()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_phone text;
    v_existing uuid;
BEGIN

    v_phone := regexp_replace(
        COALESCE(NEW.phone, ''),
        '[^0-9]',
        '',
        'g'
    );


    IF length(v_phone) < 6 THEN
        RETURN NEW;
    END IF;


    PERFORM pg_advisory_xact_lock(
        hashtextextended(
            NEW.organization_id::text
            || ':client-phone:'
            || v_phone,
            0
        )
    );


    SELECT c.id

    INTO v_existing

    FROM public.clients c

    WHERE c.organization_id = NEW.organization_id

      AND c.id <> COALESCE(
          NEW.id,
          '00000000-0000-0000-0000-000000000000'::uuid
      )

      AND c.archived_at IS NULL

      AND regexp_replace(
          COALESCE(c.phone, ''),
          '[^0-9]',
          '',
          'g'
      ) = v_phone

    ORDER BY c.created_at

    LIMIT 1;


    IF v_existing IS NOT NULL THEN

        RAISE EXCEPTION
            'Un client avec ce numéro existe déjà dans cette organisation. Client existant : %',
            v_existing;

    END IF;


    RETURN NEW;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_check_subscription_limit_v1(p_organization_id uuid, p_resource_code text)
 RETURNS TABLE(allowed boolean, resource_code text, current_count bigint, limit_value bigint, unlimited boolean, subscription_status text, plan_code text, reason text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare
  v_plan_id uuid;
  v_status text;
  v_plan_code text;
  v_limit bigint;
  v_unlimited boolean;
  v_count bigint := 0;
begin
  if auth.uid() is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if not private.is_super_admin() and not private.is_org_admin(p_organization_id) then
    raise exception 'ACCESS_DENIED';
  end if;

  select os.plan_id, os.status, sp.code
    into v_plan_id, v_status, v_plan_code
  from public.organization_subscriptions os
  join public.subscription_plans sp on sp.id=os.plan_id
  where os.organization_id=p_organization_id
    and os.status in ('trial','active','past_due')
    and (os.expires_at is null or os.expires_at > now())
  order by case os.status when 'active' then 1 when 'trial' then 2 else 3 end,
           coalesce(os.expires_at,'infinity'::timestamptz) desc
  limit 1;

  if private.is_super_admin() then
    return query select true,p_resource_code,0::bigint,null::bigint,true,
      coalesce(v_status,'super_admin'),coalesce(v_plan_code,'SUPER_ADMIN'),'SUPER_ADMIN_UNLIMITED';
    return;
  end if;

  if v_plan_id is null then
    return query select false,p_resource_code,0::bigint,0::bigint,false,
      'inactive',null::text,'SUBSCRIPTION_REQUIRED';
    return;
  end if;

  select sl.limit_value, sl.unlimited
    into v_limit,v_unlimited
  from public.subscription_limits sl
  where sl.plan_id=v_plan_id and sl.resource_code=lower(trim(p_resource_code));

  if lower(trim(p_resource_code))='admins' then
    select count(*) into v_count
    from public.organization_members om
    where om.organization_id=p_organization_id
      and om.status='active'
      and om.role in ('business_admin','admin','administrateur');
  elsif lower(trim(p_resource_code))='prospecteurs' then
    select count(*) into v_count
    from public.prospecteurs p
    where p.organization_id=p_organization_id
      and p.status='active';
  elsif lower(trim(p_resource_code))='clients' then
    select count(*) into v_count
    from public.clients c
    where c.organization_id=p_organization_id
      and c.archived_at is null;
  else
    raise exception 'UNKNOWN_RESOURCE_CODE';
  end if;

  if coalesce(v_unlimited,false) then
    return query select true,lower(trim(p_resource_code)),v_count,v_limit,true,
      v_status,v_plan_code,'UNLIMITED';
  end if;

  return query select (v_count < coalesce(v_limit,0)),lower(trim(p_resource_code)),v_count,
    coalesce(v_limit,0),false,v_status,v_plan_code,
    case when v_count < coalesce(v_limit,0) then 'LIMIT_AVAILABLE' else 'LIMIT_REACHED' end;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_confirm_subscription_payment_v1(p_subscription_id uuid, p_amount numeric, p_currency text, p_provider text, p_provider_reference text, p_payment_method text DEFAULT NULL::text, p_metadata jsonb DEFAULT '{}'::jsonb)
 RETURNS subscription_payments
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
DECLARE
  v_sub public.organization_subscriptions;
  v_plan public.subscription_plans;
  v_payment public.subscription_payments;
  v_existing_payment public.subscription_payments;
  v_start timestamptz;
  v_end timestamptz;
  v_now timestamptz := now();
  v_currency text;
  v_provider text;
  v_provider_reference text;
  v_plan_amount_xof numeric;
BEGIN
  IF coalesce(auth.role(), '') <> 'service_role'
     AND (
       auth.uid() IS NULL
       OR NOT private.is_super_admin()
     )
  THEN
    RAISE EXCEPTION 'SERVICE_ROLE_OR_SUPER_ADMIN_REQUIRED';
  END IF;

  IF p_amount IS NULL OR p_amount <= 0 THEN
    RAISE EXCEPTION 'INVALID_AMOUNT';
  END IF;

  IF NULLIF(trim(p_provider), '') IS NULL THEN
    RAISE EXCEPTION 'PROVIDER_REQUIRED';
  END IF;

  IF NULLIF(trim(p_provider_reference), '') IS NULL THEN
    RAISE EXCEPTION 'PROVIDER_REFERENCE_REQUIRED';
  END IF;

  IF NULLIF(trim(p_currency), '') IS NULL THEN
    RAISE EXCEPTION 'CURRENCY_REQUIRED';
  END IF;

  v_provider := lower(trim(p_provider));
  v_currency := upper(trim(p_currency));
  v_provider_reference := trim(p_provider_reference);

  SELECT * INTO v_sub
  FROM public.organization_subscriptions
  WHERE id = p_subscription_id
  FOR UPDATE;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'SUBSCRIPTION_NOT_FOUND';
  END IF;

  SELECT * INTO v_plan
  FROM public.subscription_plans
  WHERE id = v_sub.plan_id
    AND active = true;

  IF NOT FOUND THEN
    RAISE EXCEPTION 'PLAN_NOT_FOUND';
  END IF;

  IF v_provider = 'fedapay' THEN
    IF v_currency <> 'XOF' THEN
      RAISE EXCEPTION 'FEDAPAY_CURRENCY_MUST_BE_XOF';
    END IF;

    v_plan_amount_xof := v_plan.billing_amount_xof;

    IF v_plan_amount_xof IS NULL OR v_plan_amount_xof <= 0 THEN
      RAISE EXCEPTION 'PLAN_FEDAPAY_AMOUNT_NOT_CONFIGURED';
    END IF;

    IF p_amount <> v_plan_amount_xof THEN
      RAISE EXCEPTION 'FEDAPAY_AMOUNT_MISMATCH';
    END IF;
  END IF;

  SELECT * INTO v_existing_payment
  FROM public.subscription_payments
  WHERE provider = v_provider
    AND provider_reference = v_provider_reference
  LIMIT 1
  FOR UPDATE;

  IF FOUND THEN
    IF v_existing_payment.subscription_id IS DISTINCT FROM p_subscription_id THEN
      RAISE EXCEPTION 'PAYMENT_SUBSCRIPTION_MISMATCH';
    END IF;

    IF v_existing_payment.organization_id IS DISTINCT FROM v_sub.organization_id THEN
      RAISE EXCEPTION 'PAYMENT_ORGANIZATION_MISMATCH';
    END IF;

    IF v_existing_payment.status = 'successful' THEN
      RETURN v_existing_payment;
    END IF;

    IF v_existing_payment.status IN ('refunded', 'cancelled') THEN
      RAISE EXCEPTION 'PAYMENT_ALREADY_CLOSED';
    END IF;

    UPDATE public.subscription_payments
    SET
      amount = p_amount,
      currency = v_currency,
      provider = v_provider,
      provider_reference = v_provider_reference,
      payment_method = COALESCE(p_payment_method, payment_method),
      status = 'successful',
      paid_at = v_now,
      metadata = COALESCE(metadata, '{}'::jsonb)
        || COALESCE(p_metadata, '{}'::jsonb)
        || jsonb_build_object(
          'confirmed_at', v_now,
          'confirmation_source', 'jdvcrm_confirm_subscription_payment_v1'
        )
    WHERE id = v_existing_payment.id
    RETURNING * INTO v_payment;
  ELSE
    INSERT INTO public.subscription_payments(
      organization_id,
      subscription_id,
      amount,
      currency,
      provider,
      provider_reference,
      payment_method,
      status,
      paid_at,
      metadata
    )
    VALUES(
      v_sub.organization_id,
      p_subscription_id,
      p_amount,
      v_currency,
      v_provider,
      v_provider_reference,
      p_payment_method,
      'successful',
      v_now,
      COALESCE(p_metadata, '{}'::jsonb)
        || jsonb_build_object(
          'confirmed_at', v_now,
          'confirmation_source', 'jdvcrm_confirm_subscription_payment_v1'
        )
    )
    RETURNING * INTO v_payment;
  END IF;

  v_start := CASE
    WHEN v_sub.status IN ('active', 'trial', 'past_due')
      AND v_sub.expires_at IS NOT NULL
      AND v_sub.expires_at > v_now
    THEN v_sub.expires_at
    ELSE v_now
  END;

  v_end := v_start + make_interval(days => v_plan.duration_days);

  UPDATE public.organization_subscriptions
  SET
    status = 'active',
    started_at = COALESCE(started_at, v_now),
    expires_at = v_end,
    external_reference = v_provider_reference,
    updated_at = v_now
  WHERE id = p_subscription_id;

  UPDATE public.organization_subscriptions
  SET
    status = 'cancelled',
    auto_renew = false,
    updated_at = v_now
  WHERE organization_id = v_sub.organization_id
    AND status = 'trial'
    AND id <> p_subscription_id;

  UPDATE public.organizations
  SET
    status = 'active',
    subscription_status = 'active',
    updated_at = v_now
  WHERE id = v_sub.organization_id;

  INSERT INTO public.subscription_events(
    organization_id,
    subscription_id,
    event_type,
    provider,
    provider_reference,
    amount,
    currency,
    metadata
  )
  VALUES(
    v_sub.organization_id,
    p_subscription_id,
    'payment_succeeded',
    v_provider,
    v_provider_reference,
    p_amount,
    v_currency,
    COALESCE(p_metadata, '{}'::jsonb)
      || jsonb_build_object(
        'confirmed_at', v_now,
        'plan_code', v_plan.code,
        'plan_name', v_plan.name,
        'expires_at', v_end
      )
  );

  RETURN v_payment;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_convert_prospect_to_client_v1(p_prospect_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  pr public.prospects%ROWTYPE;
  c_id uuid;
  v_portfolio uuid;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentification requise'; END IF;
  SELECT * INTO pr FROM public.prospects WHERE id = p_prospect_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Prospect introuvable'; END IF;
  IF NOT (
    private.is_super_admin()
    OR private.is_org_admin(pr.organization_id)
    OR (private.is_prospecteur(pr.organization_id)
        AND EXISTS (SELECT 1 FROM public.prospecteurs p
                    WHERE p.id = pr.prospecteur_id AND p.user_id = auth.uid() AND p.status = 'active'))
  ) THEN
    RAISE EXCEPTION 'Accès refusé';
  END IF;
  IF pr.client_id IS NOT NULL THEN RETURN pr.client_id; END IF;

  v_portfolio := pr.portfolio_id;
  IF v_portfolio IS NULL AND pr.prospecteur_id IS NOT NULL THEN
    SELECT cp.id INTO v_portfolio
    FROM public.client_portfolios cp
    JOIN public.prospecteurs p ON p.user_id = cp.owner_user_id
    WHERE p.id = pr.prospecteur_id AND cp.organization_id = pr.organization_id AND cp.status = 'active'
    ORDER BY cp.created_at LIMIT 1;
  END IF;

  INSERT INTO public.clients(organization_id, prospecteur_id, portfolio_id, first_name, last_name, phone, whatsapp,
                             address, city, status, temperature, notes, last_contact_at, last_activity_at)
  VALUES (pr.organization_id, pr.prospecteur_id, v_portfolio, pr.first_name, pr.last_name, pr.phone, pr.whatsapp,
          pr.address, pr.city, 'active', pr.temperature, pr.notes, COALESCE(pr.last_contact_at, now()), now())
  RETURNING id INTO c_id;

  UPDATE public.prospects SET client_id = c_id, status = 'converted', updated_at = now() WHERE id = pr.id;
  RETURN c_id;
END $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_create_followup_notifications(p_organization_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SET search_path TO 'public', 'private', 'auth'
AS $function$
DECLARE
    v_count integer;
BEGIN

    INSERT INTO public.notifications (
        organization_id,
        user_id,
        title,
        message,
        type,
        metadata
    )
    SELECT
        p.organization_id,
        om.user_id,
        'Prospect à relancer',
        'Le prospect ' ||
            trim(
                coalesce(p.first_name, '') ||
                ' ' ||
                coalesce(p.last_name, '')
            ) ||
            ' nécessite une relance.',
        'follow_up',
        jsonb_build_object(
            'prospect_id', p.id,
            'prospecteur_id', p.prospecteur_id,
            'next_follow_up_at', p.next_follow_up_at
        )
    FROM public.prospects p
    JOIN public.organization_members om
      ON om.organization_id = p.organization_id
     AND om.role = 'prospecteur'
     AND om.status = 'active'
     AND om.user_id IS NOT NULL
    WHERE p.organization_id = p_organization_id
      AND p.archived_at IS NULL
      AND p.prospecteur_id IS NOT NULL
      AND om.user_id = (
          SELECT pr.user_id
          FROM public.prospecteurs pr
          WHERE pr.id = p.prospecteur_id
          LIMIT 1
      )
      AND COALESCE(
            p.next_follow_up_at,
            p.last_contact_at,
            p.created_at
          ) <= now()
      AND NOT EXISTS (
          SELECT 1
          FROM public.notifications n
          WHERE n.organization_id = p.organization_id
            AND n.user_id = om.user_id
            AND n.type = 'follow_up'
            AND n.metadata ->> 'prospect_id' = p.id::text
            AND n.created_at >= now() - interval '24 hours'
      );


    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN v_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_create_sale_commission()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_rate NUMERIC(8,2);
    v_base NUMERIC(14,2);
BEGIN
    IF NEW.prospecteur_id IS NULL THEN
        RETURN NEW;
    END IF;

    SELECT commission_rate
    INTO v_rate
    FROM public.prospecteurs
    WHERE id = NEW.prospecteur_id
      AND organization_id = NEW.organization_id;

    v_rate := COALESCE(v_rate, 0);

    IF v_rate <= 0 THEN
        RETURN NEW;
    END IF;

    v_base := CASE
        WHEN lower(COALESCE(NEW.sale_type, 'cash')) = 'credit'
        THEN COALESCE(NEW.credit_price, 0) * COALESCE(NEW.quantity, 1)
        ELSE COALESCE(NEW.cash_price, 0) * COALESCE(NEW.quantity, 1)
    END;

    INSERT INTO public.commissions (
        organization_id,
        prospecteur_id,
        sale_id,
        article_id,
        commission_rate,
        base_amount,
        commission_amount,
        status
    )
    SELECT
        NEW.organization_id,
        NEW.prospecteur_id,
        NEW.id,
        NEW.article_id,
        v_rate,
        v_base,
        ROUND(v_base * v_rate / 100, 2),
        'pending'
    WHERE NOT EXISTS (
        SELECT 1
        FROM public.commissions c
        WHERE c.sale_id = NEW.id
          AND c.prospecteur_id = NEW.prospecteur_id
    );

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_create_unpaid_followup_reminders_v1(p_organization_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare v_count integer:=0; r record;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 if not (private.is_super_admin() or private.is_org_admin(p_organization_id)) then raise exception 'Accès refusé'; end if;
 for r in select ps.id schedule_id,s.client_id,s.prospecteur_id,ps.due_date,greatest(ps.expected_amount-ps.paid_amount,0) remaining from public.payment_schedules ps join public.sales s on s.id=ps.sale_id where ps.organization_id=p_organization_id and ps.status in ('late','partial') and ps.paid_amount<ps.expected_amount loop
   if not exists(select 1 from public.follow_up_reminders f where f.organization_id=p_organization_id and f.client_id=r.client_id and f.reminder_at::date=current_date and f.status='pending' and coalesce(f.message,'') like 'Échéance%') then
     insert into public.follow_up_reminders(organization_id,client_id,user_id,reminder_at,channel,status,message)
     values(p_organization_id,r.client_id,(select p.user_id from public.prospecteurs p where p.id=r.prospecteur_id),now(),'app','pending',format('Échéance impayée : reste %s XOF, échéance du %s.',r.remaining,r.due_date));
     v_count:=v_count+1;
   end if;
 end loop; return v_count;
end; $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_daily_maintenance_v41()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_overdue integer;
    v_notifications integer;
BEGIN

    v_overdue :=
        public.jdvcrm_refresh_overdue_schedules_v41();


    v_notifications :=
        public.jdvcrm_overdue_notifications_v41();


    RETURN jsonb_build_object(

        'overdue_schedules',
        v_overdue,

        'notifications_created',
        v_notifications,

        'executed_at',
        now()

    );

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_detect_duplicate_prospect_phone_v41()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_phone text;
    v_existing uuid;
BEGIN

    v_phone := regexp_replace(
        COALESCE(NEW.phone, ''),
        '[^0-9]',
        '',
        'g'
    );


    IF length(v_phone) < 6 THEN

        NEW.duplicate_phone_flag := false;
        NEW.duplicate_phone_of := NULL;

        RETURN NEW;

    END IF;


    PERFORM pg_advisory_xact_lock(
        hashtextextended(
            NEW.organization_id::text
            || ':prospect-phone:'
            || v_phone,
            0
        )
    );


    SELECT p.id

    INTO v_existing

    FROM public.prospects p

    WHERE p.organization_id = NEW.organization_id

      AND p.id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)

      AND p.archived_at IS NULL

      AND regexp_replace(
          COALESCE(p.phone, ''),
          '[^0-9]',
          '',
          'g'
      ) = v_phone

    ORDER BY p.created_at

    LIMIT 1;


    IF v_existing IS NOT NULL THEN

        NEW.duplicate_phone_flag := true;
        NEW.duplicate_phone_of := v_existing;

    ELSE

        NEW.duplicate_phone_flag := false;
        NEW.duplicate_phone_of := NULL;

    END IF;


    RETURN NEW;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_ensure_my_portfolio_v1(p_organization_id uuid)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
DECLARE
  v_id uuid;
  v_type text;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'AUTHENTICATION_REQUIRED';
  END IF;
  IF private.is_super_admin() THEN
    v_type := 'super_admin';
  ELSIF private.is_prospecteur(p_organization_id) THEN
    v_type := 'prospecteur';
  ELSE
    RAISE EXCEPTION 'ACCESS_DENIED';
  END IF;

  SELECT id INTO v_id
  FROM public.client_portfolios
  WHERE organization_id = p_organization_id
    AND owner_user_id = auth.uid()
    AND status = 'active'
  ORDER BY created_at
  LIMIT 1;

  IF v_id IS NULL THEN
    INSERT INTO public.client_portfolios(organization_id, owner_user_id, owner_type, name)
    VALUES (
      p_organization_id, auth.uid(), v_type,
      CASE WHEN v_type = 'super_admin' THEN 'Portefeuille concepteur' ELSE 'Mon portefeuille clients' END
    )
    RETURNING id INTO v_id;
  END IF;
  RETURN v_id;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_expire_subscriptions_v1()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare v_count integer;
begin
  if auth.uid() is null or not private.is_super_admin() then
    raise exception 'SUPER_ADMIN_REQUIRED';
  end if;

  update public.organization_subscriptions
     set status = 'expired', updated_at = now()
   where status in ('trial','active','past_due')
     and expires_at is not null
     and expires_at <= now();

  get diagnostics v_count = row_count;

  update public.organizations o
     set subscription_status = 'expired', updated_at = now()
   where o.id in (
     select os.organization_id
     from public.organization_subscriptions os
     where os.status = 'expired'
   )
   and o.subscription_status in ('trial','active','past_due');

  return v_count;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_financial_dashboard_by_prospecteur_v1(p_organization_id uuid, p_start_date date DEFAULT NULL::date, p_end_date date DEFAULT NULL::date)
 RETURNS TABLE(prospecteur_id uuid, sales_count bigint, sales_total numeric, collected numeric, outstanding numeric, commission_total numeric, commission_paid numeric, commission_unpaid numeric)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
 select p.id,
 coalesce((select count(*) from sales s where s.prospecteur_id=p.id and s.organization_id=p_organization_id and s.sale_date::date between coalesce(p_start_date,date_trunc('month',current_date)::date) and coalesce(p_end_date,current_date)),0),
 coalesce((select sum(case when lower(s.sale_type)='credit' then s.credit_price else s.cash_price end*s.quantity) from sales s where s.prospecteur_id=p.id and s.organization_id=p_organization_id and s.sale_date::date between coalesce(p_start_date,date_trunc('month',current_date)::date) and coalesce(p_end_date,current_date)),0),
 coalesce((select sum(x.amount) from payments x where x.prospecteur_id=p.id and x.organization_id=p_organization_id and x.status='successful' and x.payment_date::date between coalesce(p_start_date,date_trunc('month',current_date)::date) and coalesce(p_end_date,current_date)),0),
 coalesce((select sum(s.amount_remaining) from sales s where s.prospecteur_id=p.id and s.organization_id=p_organization_id and s.status not in ('cancelled','completed')),0),
 coalesce((select sum(c.commission_amount) from commissions c where c.prospecteur_id=p.id and c.organization_id=p_organization_id and c.status<>'cancelled' and c.created_at::date between coalesce(p_start_date,date_trunc('month',current_date)::date) and coalesce(p_end_date,current_date)),0),
 coalesce((select sum(c.commission_amount) from commissions c where c.prospecteur_id=p.id and c.organization_id=p_organization_id and c.status='paid' and c.paid_at::date between coalesce(p_start_date,date_trunc('month',current_date)::date) and coalesce(p_end_date,current_date)),0),
 coalesce((select sum(c.commission_amount) from commissions c where c.prospecteur_id=p.id and c.organization_id=p_organization_id and c.status in ('pending','approved')),0)
 from prospecteurs p where p.organization_id=p_organization_id and (private.is_super_admin() or private.is_org_admin(p_organization_id));
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_financial_dashboard_v1(p_organization_id uuid, p_start_date date DEFAULT NULL::date, p_end_date date DEFAULT NULL::date)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare v_start date:=coalesce(p_start_date,date_trunc('month',current_date)::date); v_end date:=coalesce(p_end_date,current_date); v jsonb;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 if not (private.is_super_admin() or private.is_org_admin(p_organization_id)) then raise exception 'Accès refusé'; end if;
 if v_end<v_start then raise exception 'Période invalide'; end if;
 select jsonb_build_object('period_start',v_start,'period_end',v_end,'sales_count',coalesce((select count(*) from sales s where s.organization_id=p_organization_id and s.sale_date::date between v_start and v_end),0),'sales_total',coalesce((select sum(case when lower(s.sale_type)='credit' then s.credit_price else s.cash_price end*s.quantity) from sales s where s.organization_id=p_organization_id and s.sale_date::date between v_start and v_end),0),'cash_collected',coalesce((select sum(p.amount) from payments p where p.organization_id=p_organization_id and p.status='successful' and p.payment_date::date between v_start and v_end),0),'credit_outstanding',coalesce((select sum(s.amount_remaining) from sales s where s.organization_id=p_organization_id and s.status not in ('cancelled','completed') and lower(s.sale_type)='credit'),0),'overdue_amount',coalesce((select sum(greatest(ps.expected_amount-ps.paid_amount,0)) from payment_schedules ps where ps.organization_id=p_organization_id and ps.status in ('late','partial') and ps.paid_amount<ps.expected_amount),0),'overdue_schedules',coalesce((select count(*) from payment_schedules ps where ps.organization_id=p_organization_id and ps.status in ('late','partial') and ps.paid_amount<ps.expected_amount),0),'commission_total',coalesce((select sum(c.commission_amount) from commissions c where c.organization_id=p_organization_id and c.created_at::date between v_start and v_end and c.status<>'cancelled'),0),'commission_unpaid',coalesce((select sum(c.commission_amount) from commissions c where c.organization_id=p_organization_id and c.status in ('pending','approved')),0),'commission_paid',coalesce((select sum(c.commission_amount) from commissions c where c.organization_id=p_organization_id and c.status='paid' and c.paid_at::date between v_start and v_end),0)) into v; return v;
end; $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_generate_followup_notifications()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

DECLARE
    v_count INTEGER := 0;

    r RECORD;

BEGIN

    FOR r IN
        SELECT
            p.id,
            p.organization_id,
            p.prospecteur_id,
            p.first_name,
            p.last_name,
            p.phone,
            p.last_contact_at,
            pr.user_id AS prospecteur_user_id

        FROM public.prospects p

        LEFT JOIN public.prospecteurs pr
          ON pr.id = p.prospecteur_id

        WHERE p.status NOT IN (
            'converted',
            'archived',
            'closed'
        )

        AND COALESCE(
            p.last_contact_at,
            p.created_at
        ) <= now() - INTERVAL '14 days'

        AND (
            p.last_follow_up_at IS NULL
            OR p.last_follow_up_at <= now() - INTERVAL '14 days'
        )

    LOOP

        IF r.prospecteur_user_id IS NOT NULL THEN

            INSERT INTO public.notifications (
                user_id,
                organization_id,
                type,
                title,
                message
            )
            SELECT
                r.prospecteur_user_id,
                r.organization_id,
                'prospect_followup',
                'Prospect à relancer',
                'Le prospect ' ||
                COALESCE(
                    NULLIF(trim(r.first_name || ' ' || r.last_name), ''),
                    r.phone,
                    'sans nom'
                ) ||
                ' est sans activité depuis au moins 14 jours.'
            WHERE NOT EXISTS (
                SELECT 1
                FROM public.notifications n
                WHERE n.user_id = r.prospecteur_user_id
                  AND n.organization_id = r.organization_id
                  AND n.type = 'prospect_followup'
                  AND n.created_at >= now() - INTERVAL '14 days'
                  AND n.message LIKE
                      '%' || COALESCE(r.phone, 'sans nom') || '%'
            );


            UPDATE public.prospects
            SET last_follow_up_at = now(),
                updated_at = now()
            WHERE id = r.id;


            v_count := v_count + 1;

        END IF;

    END LOOP;


    RETURN v_count;

END;

$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_generate_sale_schedules_v42(p_sale_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_sale public.sales%ROWTYPE;
    v_total NUMERIC(14,2);
    v_payment NUMERIC(14,2);
    v_remaining NUMERIC(14,2);
    v_installments INTEGER;
    v_i INTEGER;
    v_expected NUMERIC(14,2);
    v_due_date DATE;
    v_created INTEGER := 0;
    v_base_date DATE;
BEGIN
    SELECT * INTO v_sale
    FROM public.sales
    WHERE id = p_sale_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Vente introuvable : %', p_sale_id;
    END IF;

    IF lower(COALESCE(v_sale.sale_type, 'credit')) <> 'credit' THEN
        RETURN 0;
    END IF;

    v_total := COALESCE(v_sale.credit_price, 0) * COALESCE(v_sale.quantity, 0);
    IF v_total <= 0 THEN
        RAISE EXCEPTION 'Montant crédit invalide pour la vente %', p_sale_id;
    END IF;

    v_payment := COALESCE(v_sale.payment_amount, 0);

    IF lower(COALESCE(v_sale.payment_frequency, 'daily')) = 'custom' THEN
        -- Une fréquence personnalisée est planifiée manuellement par l'administrateur.
        RETURN 0;
    END IF;

    IF v_payment <= 0 THEN
        RAISE EXCEPTION 'Le montant de paiement doit être supérieur à 0. Vente : %', p_sale_id;
    END IF;

    IF EXISTS (SELECT 1 FROM public.payment_schedules WHERE sale_id = p_sale_id) THEN
        SELECT COUNT(*) INTO v_created
        FROM public.payment_schedules
        WHERE sale_id = p_sale_id;
        RETURN v_created;
    END IF;

    v_installments := CEIL(v_total / v_payment)::INTEGER;
    v_base_date := COALESCE(v_sale.sale_date::date, CURRENT_DATE) + 1;
    v_remaining := v_total;

    FOR v_i IN 1..v_installments LOOP
        v_expected := LEAST(v_payment, v_remaining);

        CASE lower(COALESCE(v_sale.payment_frequency, 'daily'))
            WHEN 'daily' THEN
                v_due_date := v_base_date + (v_i - 1);
            WHEN 'weekly' THEN
                v_due_date := v_base_date + ((v_i - 1) * 7);
            WHEN 'biweekly' THEN
                v_due_date := v_base_date + ((v_i - 1) * 14);
            WHEN 'monthly' THEN
                v_due_date := (v_base_date + ((v_i - 1) || ' month')::interval)::date;
            WHEN 'quarterly' THEN
                v_due_date := (v_base_date + ((v_i - 1) || ' quarter')::interval)::date;
            ELSE
                RAISE EXCEPTION 'Fréquence de paiement non supportée : %', v_sale.payment_frequency;
        END CASE;

        IF v_sale.deadline_date IS NOT NULL AND v_due_date > v_sale.deadline_date THEN
            v_due_date := v_sale.deadline_date;
        END IF;

        INSERT INTO public.payment_schedules (
            organization_id, sale_id, installment_number, due_date,
            expected_amount, paid_amount, status, paid_at,
            reminder_sent, created_at, updated_at
        ) VALUES (
            v_sale.organization_id, v_sale.id, v_i, v_due_date,
            v_expected, 0, 'pending', NULL, false, now(), now()
        );

        v_created := v_created + 1;
        v_remaining := v_remaining - v_expected;
    END LOOP;

    RETURN v_created;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_get_business_access_v1(p_organization_id uuid DEFAULT NULL::uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare
  v_org_id uuid := coalesce(p_organization_id, private.current_org_id());
  v_is_super boolean;
  v_is_admin boolean;
  v_is_member boolean;
  v_sub record;
begin
  if auth.uid() is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  v_is_super := private.is_super_admin();
  v_is_admin := case when v_org_id is not null then private.is_org_admin(v_org_id) else false end;
  v_is_member := case when v_org_id is not null then private.is_org_member(v_org_id) else false end;

  if v_org_id is null then
    return jsonb_build_object(
      'organization_id', null,
      'is_super_admin', v_is_super,
      'is_admin', false,
      'is_member', false,
      'business_access', v_is_super,
      'reason', case when v_is_super then 'SUPER_ADMIN_UNLIMITED' else 'ORGANIZATION_REQUIRED' end
    );
  end if;

  if v_is_super then
    return jsonb_build_object(
      'organization_id', v_org_id,
      'is_super_admin', true,
      'is_admin', v_is_admin,
      'is_member', v_is_member,
      'business_access', true,
      'unlimited', true,
      'reason', 'SUPER_ADMIN_UNLIMITED'
    );
  end if;

  if not v_is_member then
    return jsonb_build_object(
      'organization_id', v_org_id,
      'is_super_admin', false,
      'is_admin', false,
      'is_member', false,
      'business_access', false,
      'unlimited', false,
      'reason', 'ORGANIZATION_ACCESS_REQUIRED'
    );
  end if;

  select os.status, os.started_at, os.expires_at, sp.code plan_code, sp.name plan_name
    into v_sub
  from public.organization_subscriptions os
  join public.subscription_plans sp on sp.id = os.plan_id
  where os.organization_id = v_org_id
    and os.status in ('trial','active','past_due')
    and (os.expires_at is null or os.expires_at > now())
  order by case os.status when 'active' then 1 when 'trial' then 2 when 'past_due' then 3 else 4 end,
           os.expires_at desc nulls last
  limit 1;

  if v_sub is null then
    return jsonb_build_object(
      'organization_id', v_org_id,
      'is_super_admin', false,
      'is_admin', v_is_admin,
      'is_member', true,
      'business_access', false,
      'unlimited', false,
      'reason', 'SUBSCRIPTION_REQUIRED'
    );
  end if;

  return jsonb_build_object(
    'organization_id', v_org_id,
    'is_super_admin', false,
    'is_admin', v_is_admin,
    'is_member', true,
    'business_access', true,
    'unlimited', false,
    'reason', 'SUBSCRIPTION_ACTIVE',
    'subscription_status', v_sub.status,
    'plan_code', v_sub.plan_code,
    'plan_name', v_sub.plan_name,
    'started_at', v_sub.started_at,
    'expires_at', v_sub.expires_at
  );
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_get_current_subscription_v1(p_organization_id uuid)
 RETURNS TABLE(subscription_id uuid, organization_id uuid, plan_id uuid, plan_code text, plan_name text, status text, started_at timestamp with time zone, expires_at timestamp with time zone, auto_renew boolean, is_effectively_active boolean)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
begin
  if auth.uid() is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if not private.is_super_admin() and not private.is_org_admin(p_organization_id) then
    raise exception 'ACCESS_DENIED';
  end if;

  return query
  select os.id, os.organization_id, os.plan_id, sp.code, sp.name,
         case
           when os.status in ('trial','active','past_due')
                and (os.expires_at is null or os.expires_at > now())
             then os.status
           when os.status in ('trial','active','past_due')
                and os.expires_at <= now()
             then 'expired'
           else os.status
         end,
         os.started_at, os.expires_at, os.auto_renew,
         (os.status in ('trial','active','past_due') and (os.expires_at is null or os.expires_at > now()))
  from public.organization_subscriptions os
  join public.subscription_plans sp on sp.id = os.plan_id
  where os.organization_id = p_organization_id
  order by case os.status when 'active' then 1 when 'trial' then 2 when 'past_due' then 3 when 'pending' then 4 else 5 end,
           coalesce(os.expires_at, 'infinity'::timestamptz) desc
  limit 1;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_get_inactive_clients(p_organization_id uuid)
 RETURNS TABLE(client_id uuid, prospecteur_id uuid, first_name text, last_name text, phone text, temperature text, last_activity_at timestamp with time zone, days_without_activity integer)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'private', 'auth'
AS $function$
    SELECT
        c.id,
        c.prospecteur_id,
        c.first_name,
        c.last_name,
        c.phone,
        c.temperature,
        c.last_activity_at,
        EXTRACT(
            DAY FROM (
                now() -
                COALESCE(
                    c.last_activity_at,
                    c.created_at
                )
            )
        )::integer
    FROM public.clients c
    WHERE c.organization_id = p_organization_id
      AND c.archived_at IS NULL
      AND COALESCE(
            c.last_activity_at,
            c.created_at
          ) <= now() - interval '3 months'
      AND COALESCE(c.status, '') NOT IN
          ('archived', 'inactive')
    ORDER BY
        COALESCE(c.last_activity_at, c.created_at) ASC;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_get_payment_followups_v43(p_organization_id uuid)
 RETURNS TABLE(schedule_id uuid, sale_id uuid, installment_number integer, due_date date, expected_amount numeric, paid_amount numeric, remaining_amount numeric, status text, client_id uuid)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
    SELECT
        ps.id,
        ps.sale_id,
        ps.installment_number,
        ps.due_date,
        ps.expected_amount,
        ps.paid_amount,
        GREATEST(
            ps.expected_amount - ps.paid_amount,
            0
        ) AS remaining_amount,
        ps.status,
        s.client_id
    FROM public.payment_schedules ps
    JOIN public.sales s
      ON s.id = ps.sale_id
    WHERE ps.organization_id = p_organization_id
      AND ps.status IN ('partial', 'late', 'pending')
      AND ps.paid_amount < ps.expected_amount
    ORDER BY
        ps.due_date ASC,
        ps.installment_number ASC;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_get_payment_followups_v44(p_organization_id uuid)
 RETURNS TABLE(schedule_id uuid, sale_id uuid, installment_number integer, due_date date, expected_amount numeric, paid_amount numeric, remaining_amount numeric, status text, client_id uuid, client_name text, client_phone text, prospecteur_id uuid, days_late integer)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
 select ps.id,ps.sale_id,ps.installment_number,ps.due_date,ps.expected_amount,ps.paid_amount,
 greatest(ps.expected_amount-ps.paid_amount,0),ps.status,s.client_id,
 trim(concat(c.first_name,' ',coalesce(c.last_name,''))),c.phone,s.prospecteur_id,
 greatest(current_date-ps.due_date,0)
 from public.payment_schedules ps join public.sales s on s.id=ps.sale_id
 left join public.clients c on c.id=s.client_id and c.organization_id=s.organization_id
 where ps.organization_id=p_organization_id and ps.status in ('partial','late','pending') and ps.paid_amount<ps.expected_amount
 and (private.is_super_admin() or private.is_org_admin(p_organization_id) or (private.is_prospecteur(p_organization_id) and exists(select 1 from public.prospecteurs p where p.id=s.prospecteur_id and p.user_id=auth.uid() and p.status='active')))
 order by ps.due_date,ps.installment_number;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_get_prospects_to_follow_up(p_organization_id uuid)
 RETURNS TABLE(prospect_id uuid, prospecteur_id uuid, first_name text, last_name text, phone text, temperature text, last_contact_at timestamp with time zone, next_follow_up_at timestamp with time zone, days_without_contact integer)
 LANGUAGE sql
 STABLE
 SET search_path TO 'public', 'private', 'auth'
AS $function$
    SELECT
        p.id,
        p.prospecteur_id,
        p.first_name,
        p.last_name,
        p.phone,
        p.temperature,
        p.last_contact_at,
        p.next_follow_up_at,
        EXTRACT(
            DAY FROM (
                now() -
                COALESCE(
                    p.last_contact_at,
                    p.created_at
                )
            )
        )::integer
    FROM public.prospects p
    WHERE p.organization_id = p_organization_id
      AND p.archived_at IS NULL
      AND COALESCE(
            p.last_contact_at,
            p.created_at
          ) <= now() - interval '14 days'
      AND COALESCE(p.status, '') NOT IN
          ('converted', 'archived', 'closed')
    ORDER BY
        COALESCE(p.last_contact_at, p.created_at) ASC;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_integrity_report(p_organization_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE
 SET search_path TO 'public', 'private', 'auth'
AS $function$
DECLARE
    v_duplicate_prospects integer;
    v_negative_stocks integer;
    v_invalid_sales integer;
    v_overdue_schedules integer;
    v_unpaid_sales integer;
BEGIN

    SELECT count(*)
    INTO v_duplicate_prospects
    FROM public.prospects
    WHERE organization_id = p_organization_id
      AND duplicate_phone_flag = true
      AND archived_at IS NULL;


    SELECT count(*)
    INTO v_negative_stocks
    FROM public.stocks
    WHERE organization_id = p_organization_id
      AND (
          quantity < 0
          OR reserved_quantity < 0
          OR reserved_quantity > quantity
      );


    SELECT count(*)
    INTO v_invalid_sales
    FROM public.sales
    WHERE organization_id = p_organization_id
      AND (
          quantity < 1
          OR amount_paid < 0
          OR amount_remaining < 0
      );


    SELECT count(*)
    INTO v_overdue_schedules
    FROM public.payment_schedules
    WHERE organization_id = p_organization_id
      AND due_date < CURRENT_DATE
      AND paid_amount < expected_amount
      AND status NOT IN ('paid', 'completed', 'cancelled');


    SELECT count(*)
    INTO v_unpaid_sales
    FROM public.sales
    WHERE organization_id = p_organization_id
      AND lower(coalesce(sale_type, 'credit')) = 'credit'
      AND amount_remaining > 0
      AND status NOT IN ('completed', 'cancelled');


    RETURN jsonb_build_object(
        'organization_id', p_organization_id,
        'duplicate_prospects', v_duplicate_prospects,
        'invalid_stocks', v_negative_stocks,
        'invalid_sales', v_invalid_sales,
        'overdue_schedules', v_overdue_schedules,
        'unpaid_credit_sales', v_unpaid_sales,
        'checked_at', now()
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_mark_late_schedules_v43()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_count INTEGER := 0;
BEGIN

    UPDATE public.payment_schedules
    SET
        status = 'late',
        updated_at = now()
    WHERE due_date < CURRENT_DATE
      AND status IN ('pending', 'partial')
      AND paid_amount < expected_amount;

    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN v_count;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_mark_late_schedules_v44()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
DECLARE v_count integer:=0;
BEGIN
  IF auth.uid() IS NULL THEN
    RAISE EXCEPTION 'AUTHENTICATION_REQUIRED';
  END IF;
  IF NOT private.is_super_admin() THEN
    RAISE EXCEPTION 'SUPER_ADMIN_REQUIRED';
  END IF;
  UPDATE public.payment_schedules ps
  SET status='late', updated_at=now()
  WHERE ps.due_date < current_date
    AND ps.status IN ('pending','partial')
    AND ps.paid_amount < ps.expected_amount;
  GET DIAGNOSTICS v_count=row_count;
  RETURN v_count;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_normalize_phone(p_phone text)
 RETURNS text
 LANGUAGE sql
 IMMUTABLE
 SET search_path TO 'public', 'private', 'auth'
AS $function$

    SELECT NULLIF(
        regexp_replace(
            lower(trim(COALESCE(p_phone, ''))),
            '[^0-9+]',
            '',
            'g'
        ),
        ''
    );

$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_overdue_notifications_v41()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_count integer;
BEGIN

    INSERT INTO public.notifications (
        organization_id,
        user_id,
        title,
        message,
        type,
        metadata
    )

    SELECT

        s.organization_id,

        pr.user_id,

        'Paiement en retard',

        'La vente '
        || s.sale_number
        || ' présente un montant restant de '
        || s.amount_remaining::text
        || ' XOF.',

        'warning',

        jsonb_build_object(
            'sale_id', s.id,
            'client_id', s.client_id,
            'prospecteur_id', s.prospecteur_id,
            'deadline_date', s.deadline_date,
            'amount_remaining', s.amount_remaining
        )

    FROM public.sales s

    JOIN public.prospecteurs pr
        ON pr.id = s.prospecteur_id

    WHERE lower(COALESCE(s.sale_type, '')) = 'credit'

      AND s.amount_remaining > 0

      AND lower(COALESCE(s.status, '')) NOT IN (
          'cancelled',
          'completed'
      )

      AND s.deadline_date IS NOT NULL

      AND s.deadline_date < CURRENT_DATE

      AND pr.user_id IS NOT NULL

      AND NOT EXISTS (

          SELECT 1

          FROM public.notifications n

          WHERE n.organization_id = s.organization_id

            AND n.user_id = pr.user_id

            AND n.type = 'warning'

            AND n.metadata->>'sale_id' =
                s.id::text

            AND n.created_at::date =
                CURRENT_DATE
      );


    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN v_count;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_prepare_subscription_payment_v1(p_organization_id uuid, p_plan_code text)
 RETURNS TABLE(payment_id uuid, subscription_id uuid, amount numeric, currency text, plan_code text, plan_name text)
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_plan public.subscription_plans;
  v_sub public.organization_subscriptions;
  v_pay public.subscription_payments;
BEGIN
  IF coalesce(auth.role(), '') <> 'service_role' THEN
    RAISE EXCEPTION 'SERVICE_ROLE_REQUIRED';
  END IF;

  SELECT * INTO v_plan FROM public.subscription_plans
  WHERE code = upper(trim(p_plan_code)) AND active = true;
  IF NOT FOUND OR v_plan.code = 'TRIAL' THEN
    RAISE EXCEPTION 'PLAN_NOT_AVAILABLE';
  END IF;
  IF coalesce(v_plan.billing_amount_xof, 0) <= 0 THEN
    RAISE EXCEPTION 'PLAN_FEDAPAY_AMOUNT_NOT_CONFIGURED';
  END IF;

  PERFORM 1 FROM public.organizations WHERE id = p_organization_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'ORGANIZATION_NOT_FOUND'; END IF;

  SELECT * INTO v_sub FROM public.organization_subscriptions os
  WHERE os.organization_id = p_organization_id
    AND os.status IN ('pending', 'trial', 'active', 'past_due')
  ORDER BY os.created_at DESC
  LIMIT 1
  FOR UPDATE;

  IF NOT FOUND THEN
    INSERT INTO public.organization_subscriptions(organization_id, plan_id, status)
    VALUES (p_organization_id, v_plan.id, 'pending')
    RETURNING * INTO v_sub;
  END IF;

  INSERT INTO public.subscription_payments(organization_id, subscription_id, amount, currency, provider, status, metadata)
  VALUES (
    p_organization_id, v_sub.id, v_plan.billing_amount_xof, 'XOF', 'fedapay', 'pending',
    jsonb_build_object('plan_code', v_plan.code, 'plan_id', v_plan.id, 'source', 'payment_wall')
  )
  RETURNING * INTO v_pay;

  RETURN QUERY SELECT v_pay.id, v_sub.id, v_pay.amount, v_pay.currency, v_plan.code, v_plan.name;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_process_goods_receipt_v1(p_receipt_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare r goods_receipts%rowtype; i record; s stocks%rowtype; po purchase_orders%rowtype; v_count integer:=0; v_total_received numeric:=0; v_order_qty numeric; v_received_before numeric; v_new_status text;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 select * into r from goods_receipts where id=p_receipt_id for update;
 if not found then raise exception 'Réception introuvable'; end if;
 if not (private.is_super_admin() or private.is_org_admin(r.organization_id)) then raise exception 'Accès refusé'; end if;
 if r.status<>'received' then raise exception 'La réception doit être au statut received'; end if;
 select * into po from purchase_orders where id=r.purchase_order_id for update;
 if not found or po.organization_id<>r.organization_id then raise exception 'Commande fournisseur incompatible'; end if;
 for i in select * from goods_receipt_items where receipt_id=r.id order by id loop
   select coalesce(sum(quantity_received),0) into v_received_before
   from goods_receipt_items gri join goods_receipts gr on gr.id=gri.receipt_id
   where gr.purchase_order_id=r.purchase_order_id and gr.organization_id=r.organization_id and gri.article_id=i.article_id and gr.id<>r.id and gr.status='received';
   select coalesce(sum(quantity),0) into v_order_qty from purchase_order_items where purchase_order_id=r.purchase_order_id and organization_id=r.organization_id and article_id=i.article_id;
   if v_order_qty=0 then raise exception 'Article % absent de la commande fournisseur',i.article_id; end if;
   if v_received_before+i.quantity_received>v_order_qty then raise exception 'Réception supérieure à la quantité commandée pour l''article %',i.article_id; end if;
   if exists(select 1 from stock_movements where organization_id=r.organization_id and reference_type='goods_receipt' and reference_id=r.id and article_id=i.article_id) then continue; end if;
   select * into s from stocks where organization_id=r.organization_id and article_id=i.article_id for update;
   if found then update stocks set quantity=quantity+i.quantity_received,updated_at=now() where id=s.id;
   else insert into stocks(organization_id,article_id,quantity,reserved_quantity,minimum_quantity,updated_at) values(r.organization_id,i.article_id,i.quantity_received,0,0,now()); end if;
   insert into stock_movements(organization_id,article_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
   values(r.organization_id,i.article_id,'entry',i.quantity_received,'goods_receipt',r.id,'supplier','stock_principal','Entrée liée à la réception '||r.receipt_number,coalesce(r.received_by,auth.uid()),now());
   v_count:=v_count+1; v_total_received:=v_total_received+i.quantity_received;
 end loop;
 update purchase_orders po2 set status=case when not exists(select 1 from purchase_order_items poi where poi.purchase_order_id=po2.id and poi.organization_id=po2.organization_id and poi.quantity>(select coalesce(sum(gri.quantity_received),0) from goods_receipt_items gri join goods_receipts gr on gr.id=gri.receipt_id where gr.purchase_order_id=po2.id and gr.organization_id=po2.organization_id and gr.status='received' and gri.article_id=poi.article_id)) then 'received' when exists(select 1 from goods_receipt_items gri join goods_receipts gr on gr.id=gri.receipt_id where gr.purchase_order_id=po2.id and gr.organization_id=po2.organization_id and gr.status='received') then 'partial' else po2.status end,updated_at=now() where po2.id=r.purchase_order_id;
 return jsonb_build_object('success',true,'receipt_id',r.id,'processed_items',v_count,'quantity_added',v_total_received);
end $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_process_payment_v43(p_payment_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_payment public.payments%ROWTYPE; v_remaining numeric(14,2); v_total numeric(14,2); v_paid numeric(14,2); v_schedule_count integer:=0;
BEGIN
 SELECT * INTO v_payment FROM public.payments WHERE id=p_payment_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Paiement introuvable : %',p_payment_id; END IF;
 IF v_payment.sale_id IS NULL THEN RETURN jsonb_build_object('success',true,'payment_id',p_payment_id,'financially_applied',false,'reason','no_sale'); END IF;
 IF lower(coalesce(v_payment.status,''))='successful' THEN
  IF v_payment.schedule_id IS NOT NULL THEN PERFORM public.jdvcrm_refresh_schedule_v43(v_payment.schedule_id); END IF;
  v_schedule_count:=public.jdvcrm_refresh_sale_schedules_v43(v_payment.sale_id);
 END IF;
 PERFORM public.jdvcrm_recalculate_sale(v_payment.sale_id);
 SELECT CASE WHEN lower(coalesce(sale_type,'credit'))='credit' THEN coalesce(credit_price,0)*coalesce(quantity,0) ELSE coalesce(cash_price,0)*coalesce(quantity,0) END,coalesce(amount_paid,0),coalesce(amount_remaining,0) INTO v_total,v_paid,v_remaining FROM public.sales WHERE id=v_payment.sale_id;
 RETURN jsonb_build_object('success',true,'payment_id',p_payment_id,'financially_applied',lower(coalesce(v_payment.status,''))='successful','sale_id',v_payment.sale_id,'schedule_id',v_payment.schedule_id,'schedule_count',v_schedule_count,'sale_total',v_total,'sale_paid',v_paid,'sale_remaining',v_remaining);
END $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_process_sale_return(p_return_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
DECLARE
  r public.sales_returns%ROWTYPE;
  v_sale public.sales%ROWTYPE;
  i record;
  v_stock_id uuid;
  v_stock_qty integer;
  v_ps_id uuid;
  v_ps_qty integer;
  v_existing boolean;
  v_serial_org uuid;
  v_serial_article uuid;
  v_serial_sale uuid;
  v_serial_client uuid;
  v_serial_status text;
BEGIN
  IF auth.uid() IS NULL THEN RAISE EXCEPTION 'Authentification requise'; END IF;
  SELECT * INTO r FROM public.sales_returns WHERE id=p_return_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'Retour introuvable'; END IF;
  IF NOT (private.is_super_admin() OR private.is_org_admin(r.organization_id)) THEN
    RAISE EXCEPTION 'Accès refusé : administrateur ou concepteur requis';
  END IF;
  SELECT * INTO v_sale FROM public.sales WHERE id=r.sale_id FOR UPDATE;
  IF NOT FOUND OR v_sale.organization_id<>r.organization_id THEN RAISE EXCEPTION 'Vente incompatible avec le retour'; END IF;
  IF r.status='processed' THEN RETURN true; END IF;
  IF r.status<>'approved' THEN RAISE EXCEPTION 'Le retour doit être approuvé avant traitement'; END IF;

  FOR i IN SELECT * FROM public.sales_return_items WHERE return_id=r.id ORDER BY id LOOP
    SELECT EXISTS(
      SELECT 1 FROM public.stock_movements
      WHERE organization_id=r.organization_id AND reference_type='sale_return'
        AND reference_id=r.id AND article_id=i.article_id AND movement_type='return'
        AND ((i.serial_number_id IS NULL AND notes NOT LIKE '%serial:%') OR (i.serial_number_id IS NOT NULL AND notes LIKE '%serial:'||i.serial_number_id::text||'%'))
    ) INTO v_existing;
    IF v_existing THEN CONTINUE; END IF;

    IF i.serial_number_id IS NOT NULL THEN
      SELECT organization_id, article_id, sale_id, client_id, status
        INTO v_serial_org, v_serial_article, v_serial_sale, v_serial_client, v_serial_status
      FROM public.serial_numbers WHERE id=i.serial_number_id FOR UPDATE;
      IF NOT FOUND OR v_serial_org<>r.organization_id OR v_serial_article<>i.article_id OR v_serial_sale<>r.sale_id THEN
        RAISE EXCEPTION 'Numéro de série incompatible avec le retour';
      END IF;
      IF v_sale.client_id IS NOT NULL AND v_serial_client IS NOT NULL AND v_serial_client<>v_sale.client_id THEN
        RAISE EXCEPTION 'Client incompatible avec le numéro de série';
      END IF;
      IF v_serial_status NOT IN ('sold','returned') THEN RAISE EXCEPTION 'Numéro de série non retournable'; END IF;
    END IF;

    IF v_sale.prospecteur_id IS NOT NULL THEN
      SELECT id, quantity INTO v_ps_id, v_ps_qty
      FROM public.prospecteur_stocks
      WHERE organization_id=r.organization_id AND prospecteur_id=v_sale.prospecteur_id AND article_id=i.article_id
      FOR UPDATE;
      IF NOT FOUND THEN
        INSERT INTO public.prospecteur_stocks(organization_id,prospecteur_id,article_id,quantity,updated_at)
        VALUES(r.organization_id,v_sale.prospecteur_id,i.article_id,i.quantity,now())
        RETURNING id,quantity INTO v_ps_id,v_ps_qty;
      ELSE
        UPDATE public.prospecteur_stocks SET quantity=quantity+i.quantity,updated_at=now() WHERE id=v_ps_id;
      END IF;
      INSERT INTO public.stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
      VALUES(r.organization_id,i.article_id,v_sale.prospecteur_id,'return',i.quantity,'sale_return',r.id,'client','stock_prospecteur','Réintégration retour '||r.return_number||CASE WHEN i.serial_number_id IS NOT NULL THEN ' serial:'||i.serial_number_id::text ELSE '' END,auth.uid(),now());
    ELSE
      SELECT id,quantity INTO v_stock_id,v_stock_qty FROM public.stocks
      WHERE organization_id=r.organization_id AND article_id=i.article_id FOR UPDATE;
      IF NOT FOUND THEN
        INSERT INTO public.stocks(organization_id,article_id,quantity,reserved_quantity,minimum_quantity,updated_at)
        VALUES(r.organization_id,i.article_id,i.quantity,0,0,now());
      ELSE
        UPDATE public.stocks SET quantity=quantity+i.quantity,updated_at=now() WHERE id=v_stock_id;
      END IF;
      INSERT INTO public.stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
      VALUES(r.organization_id,i.article_id,NULL,'return',i.quantity,'sale_return',r.id,'client','stock_principal','Réintégration retour '||r.return_number||CASE WHEN i.serial_number_id IS NOT NULL THEN ' serial:'||i.serial_number_id::text ELSE '' END,auth.uid(),now());
    END IF;

    IF i.serial_number_id IS NOT NULL THEN
      UPDATE public.article_serial_assignments
      SET active=false,released_at=now()
      WHERE serial_number_id=i.serial_number_id AND active=true;
      UPDATE public.serial_numbers
      SET status='returned', client_id=NULL, updated_at=now()
      WHERE id=i.serial_number_id;
      IF v_sale.prospecteur_id IS NOT NULL THEN
        INSERT INTO public.article_serial_assignments(organization_id,serial_number_id,article_id,prospecteur_id,warehouse_id,assigned_at,released_at,active,created_by)
        VALUES(r.organization_id,i.serial_number_id,i.article_id,v_sale.prospecteur_id,NULL,now(),NULL,true,auth.uid());
      END IF;
    END IF;
  END LOOP;
  UPDATE public.sales_returns SET status='processed',updated_at=now() WHERE id=r.id;
  RETURN true;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_process_sale_stock_v42(p_sale_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_sale public.sales%ROWTYPE; v_stock_id uuid; v_stock_quantity numeric; v_ps_id uuid; v_ps_qty numeric; v_qty numeric; v_existing boolean;
BEGIN
 SELECT * INTO v_sale FROM public.sales WHERE id=p_sale_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Vente introuvable : %',p_sale_id; END IF;
 v_qty:=COALESCE(v_sale.quantity,0); IF v_qty<=0 THEN RAISE EXCEPTION 'Quantité de vente invalide : %',v_qty; END IF;
 IF v_sale.article_id IS NULL THEN RAISE EXCEPTION 'La vente ne possède aucun article'; END IF;
 SELECT EXISTS(SELECT 1 FROM stock_movements WHERE organization_id=v_sale.organization_id AND reference_type='sale' AND reference_id=v_sale.id AND movement_type='sale') INTO v_existing;
 IF v_existing THEN RETURN true; END IF;
 IF v_sale.prospecteur_id IS NOT NULL THEN
   SELECT id,quantity INTO v_ps_id,v_ps_qty FROM prospecteur_stocks WHERE organization_id=v_sale.organization_id AND prospecteur_id=v_sale.prospecteur_id AND article_id=v_sale.article_id FOR UPDATE;
   IF NOT FOUND THEN RAISE EXCEPTION 'Aucun stock prospecteur disponible pour cette vente'; END IF;
   IF v_ps_qty<v_qty THEN RAISE EXCEPTION 'Stock prospecteur insuffisant. Disponible : %, demandé : %',v_ps_qty,v_qty; END IF;
   UPDATE prospecteur_stocks SET quantity=quantity-v_qty,updated_at=now() WHERE id=v_ps_id;
   INSERT INTO stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
   VALUES(v_sale.organization_id,v_sale.article_id,v_sale.prospecteur_id,'sale',v_qty,'sale',v_sale.id,'stock_prospecteur','client','Sortie automatique du stock prospecteur liée à la vente '||v_sale.sale_number,auth.uid(),now());
 ELSE
   SELECT id,quantity INTO v_stock_id,v_stock_quantity FROM stocks WHERE organization_id=v_sale.organization_id AND article_id=v_sale.article_id FOR UPDATE;
   IF NOT FOUND THEN RAISE EXCEPTION 'Aucun stock trouvé pour l''article dans l''organisation'; END IF;
   IF v_stock_quantity<v_qty THEN RAISE EXCEPTION 'Stock insuffisant. Disponible : %, demandé : %',v_stock_quantity,v_qty; END IF;
   UPDATE stocks SET quantity=quantity-v_qty,updated_at=now() WHERE id=v_stock_id;
   INSERT INTO stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
   VALUES(v_sale.organization_id,v_sale.article_id,NULL,'sale',v_qty,'sale',v_sale.id,'stock_principal','client','Sortie automatique du stock principal liée à la vente '||v_sale.sale_number,auth.uid(),now());
 END IF;
 RETURN true;
END; $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_process_sale_v42(p_sale_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_sale public.sales%ROWTYPE;

    v_schedule_count INTEGER := 0;
    v_stock_processed BOOLEAN := false;
BEGIN

    SELECT *
    INTO v_sale
    FROM public.sales
    WHERE id = p_sale_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Vente introuvable : %', p_sale_id;
    END IF;


    /* --------------------------------------------------------
       Stock
       -------------------------------------------------------- */

    v_stock_processed :=
        public.jdvcrm_process_sale_stock_v42(p_sale_id);


    /* --------------------------------------------------------
       Échéances
       -------------------------------------------------------- */

    IF lower(COALESCE(v_sale.sale_type, 'credit')) = 'credit' THEN

        v_schedule_count :=
            public.jdvcrm_generate_sale_schedules_v42(p_sale_id);

    END IF;


    RETURN jsonb_build_object(
        'success', true,
        'sale_id', p_sale_id,
        'stock_processed', v_stock_processed,
        'schedule_count', v_schedule_count
    );

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_process_subscription_webhook_v1(p_provider text, p_external_event_id text, p_event_type text, p_subscription_id uuid, p_amount numeric, p_currency text, p_provider_reference text, p_payment_method text DEFAULT NULL::text, p_payload jsonb DEFAULT '{}'::jsonb)
 RETURNS subscription_payments
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare
  v_event public.payment_webhook_events;
  v_payment public.subscription_payments;
  v_sub public.organization_subscriptions;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;

  if nullif(trim(p_provider),'') is null then raise exception 'PROVIDER_REQUIRED'; end if;
  if nullif(trim(p_external_event_id),'') is null then raise exception 'EXTERNAL_EVENT_ID_REQUIRED'; end if;
  if nullif(trim(p_event_type),'') is null then raise exception 'EVENT_TYPE_REQUIRED'; end if;
  if nullif(trim(p_provider_reference),'') is null then raise exception 'PROVIDER_REFERENCE_REQUIRED'; end if;

  insert into public.payment_webhook_events(
    provider, external_event_id, event_type, payload, status
  ) values (
    trim(p_provider), trim(p_external_event_id), trim(p_event_type), coalesce(p_payload,'{}'::jsonb), 'received'
  )
  on conflict (provider, external_event_id) where external_event_id is not null
  do update set payload=excluded.payload, event_type=excluded.event_type
  returning * into v_event;

  if v_event.status = 'processed' then
    select * into v_payment
    from public.subscription_payments
    where provider=trim(p_provider)
      and provider_reference=trim(p_provider_reference)
    limit 1;
    if found then return v_payment; end if;
    raise exception 'WEBHOOK_ALREADY_PROCESSED_PAYMENT_NOT_FOUND';
  end if;

  if lower(trim(p_event_type)) not in ('payment.success','payment.succeeded','payment.completed','transaction.approved','approved') then
    update public.payment_webhook_events
       set status='ignored', processed_at=now(), error_message=null
     where id=v_event.id;
    return null;
  end if;

  select * into v_sub
  from public.organization_subscriptions
  where id=p_subscription_id
  for update;
  if not found then raise exception 'SUBSCRIPTION_NOT_FOUND'; end if;

  begin
    v_payment := public.jdvcrm_confirm_subscription_payment_v1(
      p_subscription_id,
      p_amount,
      p_currency,
      p_provider,
      p_provider_reference,
      p_payment_method,
      p_payload
    );
  exception when others then
    update public.payment_webhook_events
       set status='failed', error_message=sqlerrm
     where id=v_event.id;
    raise;
  end;

  update public.payment_webhook_events
     set status='processed', processed_at=now(), error_message=null
   where id=v_event.id;

  insert into public.payment_provider_events(
    organization_id, provider, event_type, provider_event_id, provider_reference,
    status, payload, processed_at
  ) values (
    v_sub.organization_id, trim(p_provider), trim(p_event_type), trim(p_external_event_id),
    trim(p_provider_reference), 'processed', coalesce(p_payload,'{}'::jsonb), now()
  )
  on conflict (provider, provider_event_id) where provider_event_id is not null do nothing;

  return v_payment;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_process_supplier_payment_v1(p_payment_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare p supplier_payments%rowtype; po purchase_orders%rowtype; v_paid numeric; v_total numeric;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 select * into p from supplier_payments where id=p_payment_id for update;
 if not found then raise exception 'Paiement fournisseur introuvable'; end if;
 if not(private.is_super_admin() or private.is_org_admin(p.organization_id)) then raise exception 'Accès refusé'; end if;
 if p.status<>'paid' then raise exception 'Le paiement doit être au statut paid'; end if;
 select * into po from purchase_orders where id=p.purchase_order_id for update;
 if not found or po.organization_id<>p.organization_id or po.supplier_id<>p.supplier_id then raise exception 'Commande fournisseur incompatible'; end if;
 select coalesce(sum(amount),0) into v_paid from supplier_payments where purchase_order_id=p.purchase_order_id and organization_id=p.organization_id and status='paid' and id<>p.id;
 v_total:=coalesce(po.total_amount,0);
 if v_paid+p.amount>v_total then raise exception 'Le total des paiements dépasse le montant de la commande'; end if;
 return jsonb_build_object('success',true,'payment_id',p.id,'paid_total',v_paid+p.amount,'order_total',v_total,'remaining',greatest(v_total-(v_paid+p.amount),0));
end $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_protect_prospect_assignment()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$

BEGIN

    /*
      Création :
      un prospect peut être affecté normalement.
    */

    IF TG_OP = 'INSERT' THEN
        RETURN NEW;
    END IF;


    /*
      Si aucun changement de prospecteur :
      rien à contrôler.
    */

    IF NEW.prospecteur_id IS NOT DISTINCT FROM OLD.prospecteur_id THEN
        RETURN NEW;
    END IF;


    /*
      SUPER ADMIN :
      autorisé à réaffecter.
    */

    IF private.is_super_admin() THEN
        RETURN NEW;
    END IF;


    /*
      ADMIN de l'organisation :
      autorisé à réaffecter.
    */

    IF private.is_org_admin(NEW.organization_id) THEN
        RETURN NEW;
    END IF;


    /*
      Un prospecteur ne peut pas prendre le prospect
      d'un autre prospecteur.
    */

    RAISE EXCEPTION
        'Protection anti-poaching : seul un administrateur peut réaffecter ce prospect.';

END;

$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_recalculate_sale(p_sale_id uuid)
 RETURNS numeric
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_paid numeric(14,2); v_total numeric(14,2); v_remaining numeric(14,2); v_status text;
BEGIN
 SELECT CASE WHEN lower(coalesce(sale_type,'credit'))='credit' THEN coalesce(credit_price,0)*coalesce(quantity,0) ELSE coalesce(cash_price,0)*coalesce(quantity,0) END INTO v_total FROM public.sales WHERE id=p_sale_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Vente introuvable : %',p_sale_id; END IF;
 SELECT coalesce(sum(amount),0) INTO v_paid FROM public.payments WHERE sale_id=p_sale_id AND lower(coalesce(status,''))='successful';
 v_remaining:=greatest(v_total-v_paid,0);
 IF v_paid>=v_total AND v_total>0 THEN v_status:='completed'; ELSIF v_paid>0 THEN v_status:='active'; ELSE v_status:='pending'; END IF;
 UPDATE public.sales SET amount_paid=v_paid,amount_remaining=v_remaining,status=v_status,completed_at=CASE WHEN v_status='completed' THEN coalesce(completed_at,now()) ELSE NULL END,updated_at=now() WHERE id=p_sale_id;
 RETURN v_remaining;
END $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_receive_stock_transfer_v1(p_transfer_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_transfer public.stock_transfers%rowtype;
  v_item record;
  v_inv public.warehouse_inventory%rowtype;
  v_existing boolean;
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  select * into v_transfer from public.stock_transfers where id=p_transfer_id for update;
  if not found then raise exception 'Transfert introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(v_transfer.organization_id)) then raise exception 'Accès refusé'; end if;
  if v_transfer.status='received' then return true; end if;
  if v_transfer.status<>'in_transit' then raise exception 'Le transfert doit être en transit avant réception'; end if;

  for v_item in select * from public.stock_transfer_items where transfer_id=v_transfer.id order by id loop
    select exists(select 1 from public.stock_movements where organization_id=v_transfer.organization_id and reference_type='stock_transfer' and reference_id=v_transfer.id and article_id=v_item.article_id and movement_type='transfer_in') into v_existing;
    if not v_existing then
      select * into v_inv from public.warehouse_inventory
        where organization_id=v_transfer.organization_id and warehouse_id=v_transfer.destination_warehouse_id and article_id=v_item.article_id
        for update;
      if found then
        update public.warehouse_inventory set quantity=quantity+v_item.quantity, updated_at=now() where id=v_inv.id;
      else
        insert into public.warehouse_inventory(organization_id,warehouse_id,article_id,quantity,reserved_quantity,minimum_quantity,updated_at)
        values(v_transfer.organization_id,v_transfer.destination_warehouse_id,v_item.article_id,v_item.quantity,0,0,now());
      end if;
      insert into public.stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
      values(v_transfer.organization_id,v_item.article_id,null,'transfer_in',v_item.quantity,'stock_transfer',v_transfer.id,'warehouse:'||v_transfer.source_warehouse_id::text,'warehouse:'||v_transfer.destination_warehouse_id::text,'Réception transfert '||v_transfer.transfer_number,auth.uid(),now());
    end if;
    update public.stock_transfer_items set received_quantity=quantity where id=v_item.id;
  end loop;
  update public.stock_transfers set status='received',received_by=auth.uid(),updated_at=now() where id=v_transfer.id;
  return true;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_record_prospect_status_history_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if tg_op='UPDATE' and old.status is distinct from new.status then
   insert into public.prospect_status_history(organization_id,prospect_id,old_status,new_status,changed_by,reason)
   values(new.organization_id,new.id,old.status,new.status,auth.uid(),null);
 end if;
 return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_refresh_client_activity_v41(p_client_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_last_payment timestamptz;
    v_last_sale timestamptz;
    v_last_contact timestamptz;
    v_created timestamptz;
BEGIN

    SELECT
        created_at,
        last_contact_at

    INTO
        v_created,
        v_last_contact

    FROM public.clients

    WHERE id = p_client_id;


    IF NOT FOUND THEN
        RETURN;
    END IF;


    SELECT MAX(payment_date)
    INTO v_last_payment

    FROM public.payments

    WHERE client_id = p_client_id

      AND lower(COALESCE(status, '')) IN (
          'successful',
          'completed'
      );


    SELECT MAX(sale_date)
    INTO v_last_sale

    FROM public.sales

    WHERE client_id = p_client_id;


    UPDATE public.clients

    SET
        last_payment_at = v_last_payment,

        last_activity_at = GREATEST(
            COALESCE(v_last_payment, v_created),
            COALESCE(v_last_sale, v_created),
            COALESCE(v_last_contact, v_created)
        ),

        updated_at = now()

    WHERE id = p_client_id;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_refresh_overdue_schedules_v41()
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_count integer;
BEGIN

    UPDATE public.payment_schedules

    SET
        status = 'overdue',
        updated_at = now()

    WHERE due_date < CURRENT_DATE

      AND paid_amount < expected_amount

      AND status NOT IN (
          'paid',
          'cancelled'
      );


    GET DIAGNOSTICS v_count = ROW_COUNT;

    RETURN v_count;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_refresh_payment_schedule(p_sale_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

BEGIN

    UPDATE public.payment_schedules ps

    SET
        paid_amount = COALESCE(
            (
                SELECT SUM(p.amount)
                FROM public.payments p
                WHERE p.sale_id = ps.sale_id
                  AND p.status = 'completed'
                  AND (
                      p.schedule_id = ps.id
                      OR p.schedule_id IS NULL
                  )
            ),
            0
        ),

        status =
            CASE
                WHEN COALESCE(
                    (
                        SELECT SUM(p.amount)
                        FROM public.payments p
                        WHERE p.sale_id = ps.sale_id
                          AND p.status = 'completed'
                          AND (
                              p.schedule_id = ps.id
                              OR p.schedule_id IS NULL
                          )
                    ),
                    0
                ) >= ps.expected_amount
                THEN 'paid'

                WHEN COALESCE(
                    (
                        SELECT SUM(p.amount)
                        FROM public.payments p
                        WHERE p.sale_id = ps.sale_id
                          AND p.status = 'completed'
                          AND (
                              p.schedule_id = ps.id
                              OR p.schedule_id IS NULL
                          )
                    ),
                    0
                ) > 0
                THEN 'partial'

                WHEN ps.due_date < CURRENT_DATE
                THEN 'overdue'

                ELSE 'pending'
            END,

        updated_at = now()

    WHERE ps.sale_id = p_sale_id;

END;

$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_refresh_prospect_activity_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if new.prospect_id is not null then
   update public.prospects set last_contact_at=greatest(coalesce(last_contact_at,'epoch'::timestamptz),coalesce(new.activity_date,now())), last_follow_up_at=greatest(coalesce(last_follow_up_at,'epoch'::timestamptz),coalesce(new.activity_date,now())), next_follow_up_at=coalesce(new.next_follow_up_at,next_follow_up_at), updated_at=now() where id=new.prospect_id and organization_id=new.organization_id;
 end if;
 return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_refresh_prospect_visit_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
 if new.prospect_id is not null then
   update public.prospects set visit_count=visit_count+1,last_contact_at=greatest(coalesce(last_contact_at,'epoch'::timestamptz),coalesce(new.visit_date,now())),next_follow_up_at=coalesce(new.next_follow_up_at,next_follow_up_at),updated_at=now() where id=new.prospect_id and organization_id=new.organization_id;
 end if;
 if new.client_id is not null then
   update public.clients set last_contact_at=greatest(coalesce(last_contact_at,'epoch'::timestamptz),coalesce(new.visit_date,now())),last_activity_at=greatest(coalesce(last_activity_at,'epoch'::timestamptz),coalesce(new.visit_date,now())),updated_at=now() where id=new.client_id and organization_id=new.organization_id;
 end if;
 return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_refresh_sale_schedules_v43(p_sale_id uuid)
 RETURNS integer
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_count INTEGER := 0;
    v_schedule RECORD;
BEGIN

    FOR v_schedule IN
        SELECT id
        FROM public.payment_schedules
        WHERE sale_id = p_sale_id
        ORDER BY installment_number
    LOOP

        PERFORM public.jdvcrm_refresh_schedule_v43(
            v_schedule.id
        );

        v_count := v_count + 1;

    END LOOP;


    RETURN v_count;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_refresh_schedule_v41(p_schedule_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_expected NUMERIC(14,2);
    v_paid NUMERIC(14,2);
    v_due DATE;
    v_status TEXT;
BEGIN

    SELECT
        expected_amount,
        due_date
    INTO
        v_expected,
        v_due
    FROM public.payment_schedules
    WHERE id = p_schedule_id
    FOR UPDATE;


    IF NOT FOUND THEN
        RETURN;
    END IF;


    SELECT COALESCE(
        SUM(
            CASE
                WHEN lower(COALESCE(status, '')) IN
                    ('successful', 'completed', 'paid', 'approved')
                THEN COALESCE(amount, 0)
                ELSE 0
            END
        ),
        0
    )
    INTO v_paid
    FROM public.payments
    WHERE schedule_id = p_schedule_id;


    IF v_paid >= v_expected AND v_expected > 0 THEN

        v_status := 'paid';

    ELSIF v_paid > 0 THEN

        IF v_due < CURRENT_DATE THEN
            v_status := 'late';
        ELSE
            v_status := 'partial';
        END IF;

    ELSE

        IF v_due < CURRENT_DATE THEN
            v_status := 'late';
        ELSE
            v_status := 'pending';
        END IF;

    END IF;


    UPDATE public.payment_schedules
    SET
        paid_amount = v_paid,
        status = v_status,
        paid_at =
            CASE
                WHEN v_status = 'paid'
                THEN COALESCE(paid_at, now())
                ELSE NULL
            END,
        updated_at = now()
    WHERE id = p_schedule_id
      AND status <> 'cancelled';

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_refresh_schedule_v43(p_schedule_id uuid)
 RETURNS void
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_expected NUMERIC(14,2);
    v_paid NUMERIC(14,2);
    v_due DATE;
    v_status TEXT;
BEGIN

    SELECT
        expected_amount,
        paid_amount,
        due_date
    INTO
        v_expected,
        v_paid,
        v_due
    FROM public.payment_schedules
    WHERE id = p_schedule_id
    FOR UPDATE;

    IF NOT FOUND THEN
        RETURN;
    END IF;


    /* Une échéance annulée ne doit jamais être modifiée */
    IF EXISTS (
        SELECT 1
        FROM public.payment_schedules
        WHERE id = p_schedule_id
          AND status = 'cancelled'
    ) THEN
        RETURN;
    END IF;


    /*
       On recalcule à partir des paiements réellement
       enregistrés pour éviter les doubles comptages.
    */
    SELECT COALESCE(
        SUM(
            CASE
                WHEN lower(COALESCE(status, '')) = 'successful'
                THEN COALESCE(amount, 0)
                ELSE 0
            END
        ),
        0
    )
    INTO v_paid
    FROM public.payments
    WHERE schedule_id = p_schedule_id;


    /* --------------------------------------------------------
       Détermination du statut
       -------------------------------------------------------- */

    IF v_paid >= v_expected
       AND v_expected > 0
    THEN
        v_status := 'paid';

    ELSIF v_paid > 0 THEN

        IF v_due < CURRENT_DATE THEN
            v_status := 'late';
        ELSE
            v_status := 'partial';
        END IF;

    ELSE

        IF v_due < CURRENT_DATE THEN
            v_status := 'late';
        ELSE
            v_status := 'pending';
        END IF;

    END IF;


    UPDATE public.payment_schedules
    SET
        paid_amount = LEAST(v_paid, v_expected),
        status = v_status,
        paid_at =
            CASE
                WHEN v_status = 'paid'
                THEN COALESCE(paid_at, now())
                ELSE NULL
            END,
        updated_at = now()
    WHERE id = p_schedule_id
      AND status <> 'cancelled';

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_report_commissions_v1(p_organization_id uuid, p_start_date date, p_end_date date)
 RETURNS TABLE(commission_id uuid, prospecteur_id uuid, sale_id uuid, article_id uuid, rate numeric, base_amount numeric, commission_amount numeric, status text, paid_at timestamp with time zone)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
 select c.id,c.prospecteur_id,c.sale_id,c.article_id,c.commission_rate,c.base_amount,c.commission_amount,c.status,c.paid_at
 from commissions c where c.organization_id=p_organization_id and c.created_at::date between p_start_date and p_end_date
 and (private.is_super_admin() or private.is_org_admin(p_organization_id)) order by c.created_at desc;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_report_overdue_v1(p_organization_id uuid)
 RETURNS TABLE(schedule_id uuid, sale_id uuid, client_id uuid, due_date date, expected_amount numeric, paid_amount numeric, remaining_amount numeric, status text, days_late integer)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
 select ps.id,ps.sale_id,s.client_id,ps.due_date,ps.expected_amount,ps.paid_amount,greatest(ps.expected_amount-ps.paid_amount,0),ps.status,greatest(current_date-ps.due_date,0)::integer
 from payment_schedules ps join sales s on s.id=ps.sale_id
 where ps.organization_id=p_organization_id and ps.status in ('late','partial','pending') and ps.paid_amount<ps.expected_amount
 and (private.is_super_admin() or private.is_org_admin(p_organization_id)) order by ps.due_date;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_report_payments_v1(p_organization_id uuid, p_start_date date, p_end_date date)
 RETURNS TABLE(payment_date date, payment_id uuid, sale_id uuid, client_id uuid, prospecteur_id uuid, amount numeric, currency text, payment_method text, provider text, status text)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
 select p.payment_date::date,p.id,p.sale_id,p.client_id,p.prospecteur_id,p.amount,p.currency,p.payment_method,p.provider,p.status
 from payments p where p.organization_id=p_organization_id and p.payment_date::date between p_start_date and p_end_date
 and (private.is_super_admin() or private.is_org_admin(p_organization_id)) order by p.payment_date desc;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_report_sales_v1(p_organization_id uuid, p_start_date date, p_end_date date)
 RETURNS TABLE(sale_date date, sale_number text, client_id uuid, prospecteur_id uuid, sale_type text, status text, quantity numeric, total_amount numeric, amount_paid numeric, amount_remaining numeric)
 LANGUAGE sql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
 select s.sale_date::date,s.sale_number,s.client_id,s.prospecteur_id,s.sale_type,s.status,s.quantity,
 (case when lower(s.sale_type)='credit' then s.credit_price else s.cash_price end*s.quantity)::numeric,s.amount_paid,s.amount_remaining
 from sales s where s.organization_id=p_organization_id and s.sale_date::date between p_start_date and p_end_date
 and (private.is_super_admin() or private.is_org_admin(p_organization_id)) order by s.sale_date desc;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_run_daily_automations()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$

DECLARE

    v_followups INTEGER := 0;
    v_archived INTEGER := 0;

BEGIN

    v_followups :=
        public.jdvcrm_generate_followup_notifications();


    v_archived :=
        public.jdvcrm_archive_cold_clients();


    /*
      Les échéances en retard sont automatiquement marquées.
    */

    UPDATE public.payment_schedules

    SET
        status = 'overdue',
        updated_at = now()

    WHERE due_date < CURRENT_DATE
      AND status IN ('pending', 'partial');


    RETURN jsonb_build_object(
        'success', TRUE,
        'followups_created', v_followups,
        'clients_archived', v_archived,
        'executed_at', now()
    );

END;

$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_run_maintenance(p_organization_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SET search_path TO 'public', 'private', 'auth'
AS $function$
DECLARE
    v_archived_clients integer := 0;
    v_archived_prospects integer := 0;
    v_notifications integer := 0;
BEGIN

    v_archived_clients :=
        public.jdvcrm_archive_inactive_clients(
            p_organization_id
        );


    v_archived_prospects :=
        public.jdvcrm_archive_old_prospects(
            p_organization_id
        );


    v_notifications :=
        public.jdvcrm_create_followup_notifications(
            p_organization_id
        );


    RETURN jsonb_build_object(
        'success', true,
        'organization_id', p_organization_id,
        'clients_archived', v_archived_clients,
        'prospects_archived', v_archived_prospects,
        'followup_notifications_created', v_notifications,
        'executed_at', now()
    );
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_sale_client_activity_v41()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN

    IF TG_OP IN ('UPDATE', 'DELETE')
       AND OLD.client_id IS NOT NULL
    THEN

        PERFORM public.jdvcrm_refresh_client_activity_v41(
            OLD.client_id
        );

    END IF;


    IF TG_OP IN ('INSERT', 'UPDATE')
       AND NEW.client_id IS NOT NULL
    THEN

        PERFORM public.jdvcrm_refresh_client_activity_v41(
            NEW.client_id
        );

    END IF;


    RETURN COALESCE(NEW, OLD);

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_send_stock_transfer_v1(p_transfer_id uuid)
 RETURNS boolean
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare
  v_transfer public.stock_transfers%rowtype;
  v_item record;
  v_inv public.warehouse_inventory%rowtype;
  v_existing boolean;
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  select * into v_transfer from public.stock_transfers where id=p_transfer_id for update;
  if not found then raise exception 'Transfert introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(v_transfer.organization_id)) then raise exception 'Accès refusé'; end if;
  if v_transfer.status='in_transit' or v_transfer.status='received' then return true; end if;
  if v_transfer.status<>'draft' then raise exception 'Le transfert doit être en brouillon avant expédition'; end if;
  if not exists(select 1 from public.stock_transfer_items where transfer_id=v_transfer.id) then raise exception 'Le transfert ne contient aucun article'; end if;

  for v_item in select * from public.stock_transfer_items where transfer_id=v_transfer.id order by id loop
    select * into v_inv from public.warehouse_inventory
      where organization_id=v_transfer.organization_id and warehouse_id=v_transfer.source_warehouse_id and article_id=v_item.article_id
      for update;
    if not found then raise exception 'Stock source introuvable pour l''article %',v_item.article_id; end if;
    if v_inv.quantity - v_inv.reserved_quantity < v_item.quantity then
      raise exception 'Stock disponible insuffisant dans l''entrepôt source pour l''article %',v_item.article_id;
    end if;
    select exists(select 1 from public.stock_movements where organization_id=v_transfer.organization_id and reference_type='stock_transfer' and reference_id=v_transfer.id and article_id=v_item.article_id and movement_type='transfer_out') into v_existing;
    if not v_existing then
      update public.warehouse_inventory set quantity=quantity-v_item.quantity, updated_at=now() where id=v_inv.id;
      insert into public.stock_movements(organization_id,article_id,prospecteur_id,movement_type,quantity,reference_type,reference_id,source_location,destination_location,notes,created_by,created_at)
      values(v_transfer.organization_id,v_item.article_id,null,'transfer_out',v_item.quantity,'stock_transfer',v_transfer.id,'warehouse:'||v_transfer.source_warehouse_id::text,'warehouse:'||v_transfer.destination_warehouse_id::text,'Expédition transfert '||v_transfer.transfer_number,auth.uid(),now());
    end if;
  end loop;
  update public.stock_transfers set status='in_transit', updated_at=now() where id=v_transfer.id;
  return true;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_set_updated_at()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'private', 'auth'
AS $function$
BEGIN
    NEW.updated_at = now();
    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_settle_commission_v1(p_commission_id uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare v public.commissions%rowtype;
begin
 if auth.uid() is null then raise exception 'Authentification requise'; end if;
 select * into v from public.commissions where id=p_commission_id for update;
 if not found then raise exception 'Commission introuvable'; end if;
 if not (private.is_super_admin() or private.is_org_admin(v.organization_id)) then raise exception 'Accès refusé'; end if;
 if v.status='cancelled' then raise exception 'Commission annulée'; end if;
 update public.commissions set status='paid',paid_at=coalesce(paid_at,now()),updated_at=now() where id=v.id;
 return jsonb_build_object('success',true,'commission_id',v.id,'status','paid','paid_at',coalesce(v.paid_at,now()));
end; $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_settle_fedapay_payment_v1(p_payment_id uuid, p_transaction_id text, p_amount numeric, p_currency text, p_event_id text, p_event_type text, p_payload jsonb)
 RETURNS subscription_payments
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_pay public.subscription_payments;
  v_plan_id uuid;
  v_result public.subscription_payments;
BEGIN
  IF coalesce(auth.role(), '') <> 'service_role' THEN
    RAISE EXCEPTION 'SERVICE_ROLE_REQUIRED';
  END IF;

  SELECT * INTO v_pay FROM public.subscription_payments WHERE id = p_payment_id FOR UPDATE;
  IF NOT FOUND THEN RAISE EXCEPTION 'PAYMENT_NOT_FOUND'; END IF;
  IF v_pay.provider IS DISTINCT FROM 'fedapay' THEN RAISE EXCEPTION 'PAYMENT_PROVIDER_MISMATCH'; END IF;
  IF v_pay.provider_reference IS DISTINCT FROM trim(p_transaction_id) THEN
    RAISE EXCEPTION 'PAYMENT_REFERENCE_MISMATCH';
  END IF;

  -- Déjà réglé : on ne refait rien (les webhooks peuvent arriver plusieurs fois).
  IF v_pay.status = 'successful' THEN
    RETURN v_pay;
  END IF;

  -- Le plan choisi au moment du paiement est appliqué à l'abonnement de l'entreprise.
  v_plan_id := nullif(v_pay.metadata->>'plan_id', '')::uuid;
  IF v_plan_id IS NOT NULL THEN
    UPDATE public.organization_subscriptions
       SET plan_id = v_plan_id, updated_at = now()
     WHERE id = v_pay.subscription_id
       AND status IN ('pending', 'trial', 'active', 'past_due')
       AND plan_id <> v_plan_id;
  END IF;

  v_result := public.jdvcrm_process_subscription_webhook_v1(
    'fedapay', p_event_id, p_event_type, v_pay.subscription_id,
    p_amount, p_currency, trim(p_transaction_id), NULL, p_payload
  );
  RETURN v_result;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_sync_payment_financials_v41()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN

    -- --------------------------------------------------------
    -- ANCIENNE ÉCHÉANCE
    -- --------------------------------------------------------

    IF TG_OP IN ('UPDATE', 'DELETE')
       AND OLD.schedule_id IS NOT NULL
    THEN

        IF TG_OP = 'DELETE'
           OR OLD.schedule_id IS DISTINCT FROM NEW.schedule_id
        THEN

            PERFORM public.jdvcrm_refresh_schedule_v41(
                OLD.schedule_id
            );

        END IF;

    END IF;


    -- --------------------------------------------------------
    -- NOUVELLE ÉCHÉANCE
    -- --------------------------------------------------------

    IF TG_OP IN ('INSERT', 'UPDATE')
       AND NEW.schedule_id IS NOT NULL
    THEN

        PERFORM public.jdvcrm_refresh_schedule_v41(
            NEW.schedule_id
        );

    END IF;


    -- --------------------------------------------------------
    -- ANCIENNE VENTE
    -- --------------------------------------------------------

    IF TG_OP IN ('UPDATE', 'DELETE')
       AND OLD.sale_id IS NOT NULL
    THEN

        IF TG_OP = 'DELETE'
           OR OLD.sale_id IS DISTINCT FROM NEW.sale_id
        THEN

            PERFORM public.jdvcrm_recalculate_sale(
                OLD.sale_id
            );

        END IF;

    END IF;


    -- --------------------------------------------------------
    -- NOUVELLE VENTE
    -- --------------------------------------------------------

    IF TG_OP IN ('INSERT', 'UPDATE')
       AND NEW.sale_id IS NOT NULL
    THEN

        PERFORM public.jdvcrm_recalculate_sale(
            NEW.sale_id
        );

    END IF;


    RETURN COALESCE(NEW, OLD);

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_sync_payment_sale()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'private', 'auth'
AS $function$
DECLARE
    v_total_paid numeric;
    v_remaining numeric;
BEGIN

    IF NEW.sale_id IS NULL THEN
        RETURN NEW;
    END IF;


    IF lower(coalesce(NEW.status, '')) NOT IN
       ('successful', 'success', 'paid', 'completed') THEN
        RETURN NEW;
    END IF;


    SELECT COALESCE(SUM(p.amount), 0)
    INTO v_total_paid
    FROM public.payments p
    WHERE p.sale_id = NEW.sale_id
      AND p.organization_id = NEW.organization_id
      AND lower(coalesce(p.status, '')) IN
          ('successful', 'success', 'paid', 'completed');


    UPDATE public.sales s
    SET
        amount_paid = v_total_paid,
        amount_remaining =
            GREATEST(
                (
                    CASE
                        WHEN lower(coalesce(s.sale_type, 'credit')) = 'cash'
                            THEN COALESCE(s.cash_price, 0)
                        WHEN COALESCE(s.credit_price, 0) > 0
                            THEN s.credit_price
                        ELSE COALESCE(s.fixed_price, 0)
                    END
                    * COALESCE(s.quantity, 1)
                ) - v_total_paid,
                0
            ),
        completed_at =
            CASE
                WHEN
                    GREATEST(
                        (
                            CASE
                                WHEN lower(coalesce(s.sale_type, 'credit')) = 'cash'
                                    THEN COALESCE(s.cash_price, 0)
                                WHEN COALESCE(s.credit_price, 0) > 0
                                    THEN s.credit_price
                                ELSE COALESCE(s.fixed_price, 0)
                            END
                            * COALESCE(s.quantity, 1)
                        ) - v_total_paid,
                        0
                    ) = 0
                THEN COALESCE(s.completed_at, now())
                ELSE NULL
            END,
        status =
            CASE
                WHEN
                    GREATEST(
                        (
                            CASE
                                WHEN lower(coalesce(s.sale_type, 'credit')) = 'cash'
                                    THEN COALESCE(s.cash_price, 0)
                                WHEN COALESCE(s.credit_price, 0) > 0
                                    THEN s.credit_price
                                ELSE COALESCE(s.fixed_price, 0)
                            END
                            * COALESCE(s.quantity, 1)
                        ) - v_total_paid,
                        0
                    ) = 0
                THEN 'completed'
                ELSE 'active'
            END,
        updated_at = now()
    WHERE s.id = NEW.sale_id
      AND s.organization_id = NEW.organization_id;


    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_sync_payment_schedule()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'private', 'auth'
AS $function$
DECLARE
    v_paid numeric;
    v_expected numeric;
BEGIN

    /* Seulement les paiements considérés comme réussis */
    IF lower(coalesce(NEW.status, '')) NOT IN
       ('successful', 'success', 'paid', 'completed') THEN
        RETURN NEW;
    END IF;


    IF NEW.schedule_id IS NOT NULL THEN

        SELECT
            expected_amount,
            paid_amount
        INTO
            v_expected,
            v_paid
        FROM public.payment_schedules
        WHERE id = NEW.schedule_id
          AND organization_id = NEW.organization_id
        FOR UPDATE;


        IF FOUND THEN

            v_paid :=
                COALESCE(v_paid, 0)
                + COALESCE(NEW.amount, 0);


            UPDATE public.payment_schedules
            SET
                paid_amount = LEAST(
                    v_paid,
                    COALESCE(v_expected, v_paid)
                ),
                status =
                    CASE
                        WHEN v_paid >= COALESCE(v_expected, 0)
                        THEN 'paid'
                        WHEN v_paid > 0
                        THEN 'partial'
                        ELSE status
                    END,
                paid_at =
                    CASE
                        WHEN v_paid >= COALESCE(v_expected, 0)
                        THEN COALESCE(paid_at, NEW.payment_date)
                        ELSE paid_at
                    END,
                updated_at = now()
            WHERE id = NEW.schedule_id
              AND organization_id = NEW.organization_id;

        END IF;

    END IF;


    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_sync_subscription_status_v1(p_organization_id uuid)
 RETURNS text
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare
  v_status text;
  v_expiry timestamptz;
  v_effective text;
begin
  if current_setting('request.jwt.claim.role', true) = 'service_role' then
    null;
  elsif auth.uid() is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  elsif not (private.is_super_admin() or private.is_org_admin(p_organization_id)) then
    raise exception 'ACCESS_DENIED';
  end if;

  if p_organization_id is null then
    raise exception 'ORGANIZATION_REQUIRED';
  end if;

  select os.status, os.expires_at
    into v_status, v_expiry
  from public.organization_subscriptions os
  where os.organization_id = p_organization_id
  order by case os.status
             when 'active' then 1
             when 'trial' then 2
             when 'past_due' then 3
             when 'pending' then 4
             else 5
           end,
           coalesce(os.expires_at, 'infinity'::timestamptz) desc
  limit 1;

  if v_status is null then
    update public.organizations
       set subscription_status = 'inactive',
           updated_at = now()
     where id = p_organization_id;
    return 'inactive';
  end if;

  if v_status in ('trial','active','past_due')
     and v_expiry is not null
     and v_expiry <= now()
  then
    update public.organization_subscriptions
       set status = 'expired',
           updated_at = now()
     where organization_id = p_organization_id
       and status in ('trial','active','past_due')
       and expires_at is not null
       and expires_at <= now();

    v_effective := 'expired';
  else
    v_effective := v_status;
  end if;

  update public.organizations
     set subscription_status = v_effective,
         updated_at = now()
   where id = p_organization_id;

  return v_effective;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_update_client_payment_activity()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
begin
  if new.client_id is not null
     and lower(coalesce(new.status,'')) = 'successful' then
    update public.clients
    set last_payment_at = greatest(coalesce(last_payment_at, new.payment_date), new.payment_date),
        last_activity_at = greatest(coalesce(last_activity_at, new.payment_date), new.payment_date),
        status = case
          when status = 'debtor' and not exists (
            select 1
            from public.payment_schedules ps
            join public.sales s on s.id = ps.sale_id
            where s.client_id = new.client_id
              and ps.organization_id = new.organization_id
              and ps.status = 'late'
              and ps.paid_amount < ps.expected_amount
          ) then 'active'
          else status
        end,
        updated_at = now()
    where id = new.client_id
      and organization_id = new.organization_id;
  end if;
  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_update_client_sale_activity()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'private', 'auth'
AS $function$
BEGIN

    IF NEW.client_id IS NOT NULL THEN

        UPDATE public.clients
        SET
            last_activity_at =
                GREATEST(
                    COALESCE(last_activity_at, NEW.sale_date),
                    NEW.sale_date
                ),
            updated_at = now()
        WHERE id = NEW.client_id
          AND organization_id = NEW.organization_id;

    END IF;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_commission_v41()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_org uuid;
BEGIN

    IF NEW.prospecteur_id IS NOT NULL THEN

        SELECT organization_id
        INTO v_org

        FROM public.prospecteurs

        WHERE id = NEW.prospecteur_id;


        IF NOT FOUND OR v_org <> NEW.organization_id THEN

            RAISE EXCEPTION
                'Le prospecteur de la commission n''appartient pas à cette organisation.';

        END IF;

    END IF;


    IF NEW.sale_id IS NOT NULL THEN

        SELECT organization_id
        INTO v_org

        FROM public.sales

        WHERE id = NEW.sale_id;


        IF NOT FOUND OR v_org <> NEW.organization_id THEN

            RAISE EXCEPTION
                'La vente de la commission n''appartient pas à cette organisation.';

        END IF;

    END IF;


    IF NEW.payment_id IS NOT NULL THEN

        SELECT organization_id
        INTO v_org

        FROM public.payments

        WHERE id = NEW.payment_id;


        IF NOT FOUND OR v_org <> NEW.organization_id THEN

            RAISE EXCEPTION
                'Le paiement de la commission n''appartient pas à cette organisation.';

        END IF;

    END IF;


    IF NEW.commission_rate < 0
       OR NEW.commission_rate > 100
    THEN

        RAISE EXCEPTION
            'Le taux de commission doit être compris entre 0 et 100.';

    END IF;


    IF NEW.base_amount < 0
       OR NEW.commission_amount < 0
    THEN

        RAISE EXCEPTION
            'Les montants de commission ne peuvent pas être négatifs.';

    END IF;


    RETURN NEW;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_goods_receipt_item_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare v_org uuid; v_article_org uuid; v_status text;
begin
 select organization_id,status into v_org,v_status from goods_receipts where id=new.receipt_id;
 select organization_id into v_article_org from articles where id=new.article_id;
 if v_org is null or v_org<>new.organization_id then raise exception 'Ligne de réception incompatible avec la réception'; end if;
 if v_article_org is not null and v_article_org<>new.organization_id then raise exception 'Article incompatible avec la réception'; end if;
 if new.quantity_received<=0 then raise exception 'Quantité reçue invalide'; end if;
 if v_status='cancelled' then raise exception 'Impossible d''ajouter une ligne à une réception annulée'; end if;
 return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_goods_receipt_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_org uuid;
BEGIN
  SELECT organization_id INTO v_org FROM purchase_orders WHERE id=NEW.purchase_order_id;
  IF v_org IS NULL OR v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Réception incompatible avec la commande fournisseur'; END IF;
  IF NEW.received_by IS NULL AND NEW.status='received' THEN NEW.received_by:=auth.uid(); END IF;
  RETURN NEW;
END; $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_payment_v43()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare
  v_sale_org uuid;
  v_sale_client uuid;
  v_sale_prospecteur uuid;
  v_schedule_sale uuid;
  v_schedule_org uuid;
  v_schedule_status text;
  v_sale_total numeric(14,2);
  v_existing_paid numeric(14,2);
begin
  if auth.uid() is null then
    raise exception 'Authentification requise';
  end if;

  if new.amount is null or new.amount <= 0 then
    raise exception 'Le montant du paiement doit être supérieur à 0.';
  end if;

  if new.organization_id is null then
    raise exception 'organization_id obligatoire pour un paiement.';
  end if;

  if new.schedule_id is not null then
    select sale_id, organization_id, status
      into v_schedule_sale, v_schedule_org, v_schedule_status
    from public.payment_schedules
    where id = new.schedule_id
    for update;

    if not found then
      raise exception 'Échéance introuvable : %', new.schedule_id;
    end if;

    if v_schedule_org <> new.organization_id then
      raise exception 'L''échéance et le paiement appartiennent à des organisations différentes.';
    end if;

    if v_schedule_status = 'cancelled' then
      raise exception 'Impossible d''enregistrer un paiement sur une échéance annulée.';
    end if;

    if new.sale_id is null then
      new.sale_id := v_schedule_sale;
    elsif new.sale_id <> v_schedule_sale then
      raise exception 'L''échéance ne correspond pas à la vente.';
    end if;
  end if;

  if new.sale_id is not null then
    select
      organization_id,
      client_id,
      prospecteur_id,
      case
        when lower(coalesce(sale_type,'credit')) = 'credit'
          then coalesce(credit_price,0) * coalesce(quantity,0)
        else coalesce(cash_price,0) * coalesce(quantity,0)
      end
    into v_sale_org, v_sale_client, v_sale_prospecteur, v_sale_total
    from public.sales
    where id = new.sale_id
    for update;

    if not found then
      raise exception 'Vente introuvable : %', new.sale_id;
    end if;

    if v_sale_org <> new.organization_id then
      raise exception 'Le paiement et la vente appartiennent à des organisations différentes.';
    end if;

    if new.client_id is null then
      new.client_id := v_sale_client;
    elsif v_sale_client is not null and new.client_id <> v_sale_client then
      raise exception 'Le client du paiement ne correspond pas à celui de la vente.';
    end if;

    if new.prospecteur_id is null then
      new.prospecteur_id := v_sale_prospecteur;
    elsif v_sale_prospecteur is not null and new.prospecteur_id <> v_sale_prospecteur then
      raise exception 'Le prospecteur du paiement ne correspond pas au prospecteur de la vente.';
    end if;

    if lower(coalesce(new.status,'')) = 'successful' then
      select coalesce(sum(amount),0)
        into v_existing_paid
      from public.payments
      where sale_id = new.sale_id
        and lower(coalesce(status,'')) = 'successful'
        and id is distinct from new.id;

      if v_existing_paid + new.amount > v_sale_total then
        raise exception 'Paiement refusé : cumul %.2f supérieur au total de la vente %.2f.',
          v_existing_paid + new.amount, v_sale_total;
      end if;
    end if;
  end if;

  if new.client_id is not null and not exists (
    select 1 from public.clients c
    where c.id = new.client_id
      and c.organization_id = new.organization_id
  ) then
    raise exception 'Le client du paiement n''appartient pas à cette organisation.';
  end if;

  if new.prospecteur_id is not null and not exists (
    select 1 from public.prospecteurs p
    where p.id = new.prospecteur_id
      and p.organization_id = new.organization_id
  ) then
    raise exception 'Le prospecteur du paiement n''appartient pas à cette organisation.';
  end if;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_prospect()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'private', 'auth'
AS $function$
DECLARE
    v_duplicate_id uuid;
    v_phone text;
BEGIN

    /* ---------------------------------------------
       Validation du nombre de visites
       --------------------------------------------- */
    IF NEW.visit_count IS NULL THEN
        NEW.visit_count := 0;
    END IF;

    IF NEW.visit_count < 0 THEN
        RAISE EXCEPTION
            'JDV CRM: visit_count ne peut pas être négatif';
    END IF;


    /* ---------------------------------------------
       Normalisation légère du téléphone
       --------------------------------------------- */
    IF NEW.phone IS NOT NULL THEN
        NEW.phone := NULLIF(trim(NEW.phone), '');
    END IF;


    /* ---------------------------------------------
       Détection des doublons dans la même organisation
       --------------------------------------------- */
    NEW.duplicate_phone_flag := false;
    NEW.duplicate_phone_of := NULL;

    IF NEW.phone IS NOT NULL THEN

        SELECT p.id
        INTO v_duplicate_id
        FROM public.prospects p
        WHERE p.organization_id = NEW.organization_id
          AND p.phone IS NOT NULL
          AND regexp_replace(p.phone, '\D', '', 'g')
              = regexp_replace(NEW.phone, '\D', '', 'g')
          AND p.id <> COALESCE(NEW.id, '00000000-0000-0000-0000-000000000000'::uuid)
          AND p.archived_at IS NULL
        ORDER BY p.created_at ASC
        LIMIT 1;

        IF v_duplicate_id IS NOT NULL THEN
            NEW.duplicate_phone_flag := true;
            NEW.duplicate_phone_of := v_duplicate_id;
        END IF;

    END IF;


    /* ---------------------------------------------
       Température par défaut
       --------------------------------------------- */
    IF NEW.temperature IS NULL OR trim(NEW.temperature) = '' THEN
        NEW.temperature := 'cold';
    END IF;


    /* ---------------------------------------------
       Si un prospect est archivé,
       conserver archived_at
       --------------------------------------------- */
    IF NEW.status = 'archived'
       AND NEW.archived_at IS NULL THEN
        NEW.archived_at := now();
    END IF;


    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_prospecteur_reference_v41()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
BEGIN

    IF NEW.prospecteur_id IS NOT NULL THEN

        IF NOT EXISTS (
            SELECT 1

            FROM public.prospecteurs p

            WHERE p.id = NEW.prospecteur_id
              AND p.organization_id = NEW.organization_id
        ) THEN

            RAISE EXCEPTION
                'Le prospecteur % n''appartient pas à l''organisation %.',
                NEW.prospecteur_id,
                NEW.organization_id;

        END IF;

    END IF;


    -- Protection anti-réaffectation sauvage.
    -- Un prospecteur ne peut pas voler/réaffecter un prospect
    -- appartenant à un autre prospecteur.
    IF TG_TABLE_NAME = 'prospects'
       AND TG_OP = 'UPDATE'
       AND OLD.prospecteur_id IS DISTINCT FROM NEW.prospecteur_id
       AND auth.uid() IS NOT NULL
    THEN

        IF NOT private.is_super_admin()
           AND NOT private.is_org_admin(NEW.organization_id)
        THEN

            RAISE EXCEPTION
                'Réaffectation interdite : seul un administrateur autorisé peut changer le prospecteur.';

        END IF;

    END IF;


    RETURN NEW;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_prospecteur_stock()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'private', 'auth'
AS $function$
BEGIN

    IF NEW.quantity IS NULL THEN
        NEW.quantity := 0;
    END IF;


    IF NEW.quantity < 0 THEN
        RAISE EXCEPTION
            'JDV CRM: le stock du prospecteur ne peut pas être négatif';
    END IF;


    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_purchase_order_item_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_org uuid;
BEGIN
  SELECT organization_id INTO v_org FROM purchase_orders WHERE id=NEW.purchase_order_id;
  IF v_org IS NULL OR v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Ligne commande incompatible avec l''organisation'; END IF;
  SELECT organization_id INTO v_org FROM articles WHERE id=NEW.article_id;
  IF v_org IS NOT NULL AND v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Article incompatible avec l''organisation'; END IF;
  IF NEW.quantity IS NULL OR NEW.quantity<=0 THEN RAISE EXCEPTION 'Quantité commandée invalide'; END IF;
  IF COALESCE(NEW.unit_cost,0)<0 OR COALESCE(NEW.discount_amount,0)<0 OR COALESCE(NEW.tax_amount,0)<0 OR COALESCE(NEW.total_amount,0)<0 THEN RAISE EXCEPTION 'Montants de commande invalides'; END IF;
  RETURN NEW;
END; $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_purchase_order_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_org uuid;
BEGIN
  IF NEW.organization_id IS NULL OR NEW.supplier_id IS NULL THEN RAISE EXCEPTION 'Commande fournisseur: organisation et fournisseur obligatoires'; END IF;
  SELECT organization_id INTO v_org FROM suppliers WHERE id=NEW.supplier_id;
  IF v_org IS NULL OR v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Fournisseur incompatible avec l''organisation'; END IF;
  RETURN NEW;
END; $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_return_header()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_sale public.sales%ROWTYPE;
BEGIN
 SELECT * INTO v_sale FROM public.sales WHERE id=NEW.sale_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Vente introuvable'; END IF;
 IF NEW.organization_id <> v_sale.organization_id THEN RAISE EXCEPTION 'Organisation incohérente'; END IF;
 IF NEW.client_id IS NOT NULL AND NEW.client_id <> v_sale.client_id THEN RAISE EXCEPTION 'Client incohérent avec la vente'; END IF;
 IF NEW.status NOT IN ('pending','approved','processed','cancelled') THEN RAISE EXCEPTION 'Statut de retour invalide'; END IF;
 RETURN NEW;
END $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_sale()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'private', 'auth'
AS $function$
DECLARE
    v_unit_price numeric;
    v_total numeric;
BEGIN

    /* Quantité */
    IF NEW.quantity IS NULL OR NEW.quantity < 1 THEN
        RAISE EXCEPTION
            'JDV CRM: la quantité d''une vente doit être supérieure ou égale à 1';
    END IF;


    /* ---------------------------------------------
       Choix du prix selon le type de vente
       --------------------------------------------- */

    IF lower(coalesce(NEW.sale_type, 'credit')) = 'cash' THEN

        v_unit_price :=
            CASE
                WHEN NEW.cash_price > 0 THEN NEW.cash_price
                WHEN NEW.fixed_price > 0 THEN NEW.fixed_price
                ELSE 0
            END;

    ELSE

        v_unit_price :=
            CASE
                WHEN NEW.credit_price > 0 THEN NEW.credit_price
                WHEN NEW.fixed_price > 0 THEN NEW.fixed_price
                ELSE 0
            END;

    END IF;


    v_total := COALESCE(v_unit_price, 0)
               * COALESCE(NEW.quantity, 1);


    /* ---------------------------------------------
       Paiement déjà effectué
       --------------------------------------------- */

    IF NEW.amount_paid IS NULL OR NEW.amount_paid < 0 THEN
        NEW.amount_paid := 0;
    END IF;


    /* Ne jamais dépasser le montant total */
    IF v_total > 0 AND NEW.amount_paid > v_total THEN
        NEW.amount_paid := v_total;
    END IF;


    /* ---------------------------------------------
       Solde restant
       --------------------------------------------- */

    IF v_total > 0 THEN
        NEW.amount_remaining :=
            GREATEST(v_total - NEW.amount_paid, 0);
    ELSE
        NEW.amount_remaining :=
            GREATEST(COALESCE(NEW.amount_remaining, 0), 0);
    END IF;


    /* ---------------------------------------------
       Vente cash
       --------------------------------------------- */

    IF lower(coalesce(NEW.sale_type, 'credit')) = 'cash'
       AND v_total > 0 THEN

        NEW.amount_paid := v_total;
        NEW.amount_remaining := 0;

    END IF;


    /* ---------------------------------------------
       Vente terminée
       --------------------------------------------- */

    IF NEW.amount_remaining = 0 THEN

        IF NEW.completed_at IS NULL THEN
            NEW.completed_at := now();
        END IF;

        IF NEW.status = 'active' THEN
            NEW.status := 'completed';
        END IF;

    ELSE

        /* Une vente non soldée ne doit pas être marquée
           completed par erreur */
        IF NEW.status = 'completed' THEN
            NEW.status := 'active';
        END IF;

    END IF;


    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_sale_prospecteur_v41()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public', 'private'
AS $function$
declare
  v_org uuid;
begin
  if new.prospecteur_id is not null then
    select organization_id into v_org
    from public.prospecteurs
    where id = new.prospecteur_id;

    if not found or v_org <> new.organization_id then
      raise exception 'Le prospecteur de la vente n''appartient pas à cette organisation.';
    end if;
  end if;

  if new.client_id is not null then
    if not exists (
      select 1 from public.clients c
      where c.id = new.client_id
        and c.organization_id = new.organization_id
    ) then
      raise exception 'Le client de la vente n''appartient pas à cette organisation.';
    end if;
  end if;

  if new.article_id is not null then
    if not exists (
      select 1 from public.articles a
      where a.id = new.article_id
        and a.organization_id = new.organization_id
    ) then
      raise exception 'L''article de la vente n''appartient pas à cette organisation.';
    end if;
  end if;

  return new;
end;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_sale_return()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_sale public.sales%ROWTYPE; v_returned numeric;
BEGIN
 IF NEW.quantity IS NULL OR NEW.quantity <= 0 THEN RAISE EXCEPTION 'Quantité de retour invalide'; END IF;
 SELECT * INTO v_sale FROM public.sales WHERE id=NEW.sale_id FOR UPDATE;
 IF NOT FOUND THEN RAISE EXCEPTION 'Vente introuvable'; END IF;
 IF v_sale.organization_id <> NEW.organization_id THEN RAISE EXCEPTION 'Organisation incohérente'; END IF;
 IF NEW.client_id IS NOT NULL AND NEW.client_id <> v_sale.client_id THEN RAISE EXCEPTION 'Client incohérent avec la vente'; END IF;
 SELECT COALESCE(SUM(i.quantity),0) INTO v_returned FROM public.sales_return_items i JOIN public.sales_returns r ON r.id=i.return_id WHERE r.sale_id=NEW.sale_id AND r.status IN ('approved','processed') AND i.article_id=NEW.article_id AND r.id<>COALESCE(NEW.return_id,r.id);
 IF v_returned + NEW.quantity > COALESCE(v_sale.quantity,0) THEN RAISE EXCEPTION 'Quantité retournée supérieure à la quantité vendue'; END IF;
 RETURN NEW;
END $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_sale_return_item_serial_v2()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
  v_return_org uuid;
  v_sale_id uuid;
  v_sale_org uuid;
  v_sale_article uuid;
  v_sale_client uuid;
  v_serial_org uuid;
  v_serial_article uuid;
  v_serial_sale uuid;
  v_serial_client uuid;
  v_serial_status text;
BEGIN
  SELECT organization_id, sale_id INTO v_return_org, v_sale_id
  FROM public.sales_returns WHERE id = NEW.return_id;
  IF NOT FOUND THEN RAISE EXCEPTION 'Retour introuvable'; END IF;
  IF v_return_org <> NEW.organization_id THEN RAISE EXCEPTION 'Article de retour incompatible avec l''organisation'; END IF;

  SELECT organization_id, article_id, client_id INTO v_sale_org, v_sale_article, v_sale_client
  FROM public.sales WHERE id = v_sale_id;
  IF NOT FOUND OR v_sale_org <> NEW.organization_id THEN RAISE EXCEPTION 'Vente incompatible avec le retour'; END IF;
  IF NEW.article_id <> v_sale_article THEN RAISE EXCEPTION 'Article retourné différent de l''article vendu'; END IF;

  IF NEW.serial_number_id IS NOT NULL THEN
    IF NEW.quantity <> 1 THEN RAISE EXCEPTION 'Un retour avec numéro de série doit avoir une quantité égale à 1'; END IF;
    SELECT organization_id, article_id, sale_id, client_id, status
      INTO v_serial_org, v_serial_article, v_serial_sale, v_serial_client, v_serial_status
    FROM public.serial_numbers WHERE id = NEW.serial_number_id;
    IF NOT FOUND THEN RAISE EXCEPTION 'Numéro de série introuvable'; END IF;
    IF v_serial_org <> NEW.organization_id OR v_serial_article <> NEW.article_id THEN
      RAISE EXCEPTION 'Numéro de série incompatible avec l''article ou l''organisation';
    END IF;
    IF v_serial_sale IS DISTINCT FROM v_sale_id THEN RAISE EXCEPTION 'Le numéro de série n''est pas lié à cette vente'; END IF;
    IF v_sale_client IS NOT NULL AND v_serial_client IS NOT NULL AND v_serial_client <> v_sale_client THEN
      RAISE EXCEPTION 'Numéro de série incompatible avec le client de la vente';
    END IF;
    IF v_serial_status NOT IN ('sold','returned') THEN
      RAISE EXCEPTION 'Le numéro de série n''est pas dans un état retournable';
    END IF;
  END IF;
  RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_schedule_v41()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE
    v_sale_org uuid;
BEGIN

    SELECT organization_id
    INTO v_sale_org

    FROM public.sales

    WHERE id = NEW.sale_id;


    IF NOT FOUND THEN

        RAISE EXCEPTION
            'La vente liée à l''échéance est introuvable.';

    END IF;


    IF v_sale_org <> NEW.organization_id THEN

        RAISE EXCEPTION
            'La vente et l''échéance appartiennent à des organisations différentes.';

    END IF;


    IF NEW.expected_amount <= 0 THEN

        RAISE EXCEPTION
            'Le montant attendu de l''échéance doit être supérieur à zéro.';

    END IF;


    IF NEW.paid_amount < 0 THEN

        RAISE EXCEPTION
            'Le montant payé d''une échéance ne peut pas être négatif.';

    END IF;


    RETURN NEW;

END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_serial_assignment_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_org uuid; v_article uuid; v_serial_status text; v_prospect_org uuid; v_wh_org uuid;
BEGIN
 SELECT organization_id,article_id,status INTO v_org,v_article,v_serial_status FROM public.serial_numbers WHERE id=NEW.serial_number_id;
 IF NOT FOUND THEN RAISE EXCEPTION 'Numéro de série introuvable'; END IF;
 IF v_org<>NEW.organization_id OR v_article<>NEW.article_id THEN RAISE EXCEPTION 'Affectation incompatible avec le numéro de série'; END IF;
 IF NEW.prospecteur_id IS NOT NULL THEN
   SELECT organization_id INTO v_prospect_org FROM public.prospecteurs WHERE id=NEW.prospecteur_id;
   IF NOT FOUND OR v_prospect_org<>NEW.organization_id THEN RAISE EXCEPTION 'Prospecteur incompatible avec l''affectation'; END IF;
 END IF;
 IF NEW.warehouse_id IS NOT NULL THEN
   SELECT organization_id INTO v_wh_org FROM public.warehouses WHERE id=NEW.warehouse_id;
   IF NOT FOUND OR v_wh_org<>NEW.organization_id THEN RAISE EXCEPTION 'Entrepôt incompatible avec l''affectation'; END IF;
 END IF;
 IF NEW.active AND v_serial_status IN ('sold','lost','damaged','inactive') THEN RAISE EXCEPTION 'Ce numéro de série ne peut pas être affecté dans son état actuel'; END IF;
 IF NEW.released_at IS NOT NULL AND NEW.released_at<NEW.assigned_at THEN RAISE EXCEPTION 'released_at ne peut pas précéder assigned_at'; END IF;
 RETURN NEW;
END $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_serial_number_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_org uuid; v_article uuid; v_client uuid;
BEGIN
 IF NEW.organization_id IS NULL OR NEW.article_id IS NULL OR NULLIF(trim(NEW.serial_number),'') IS NULL THEN RAISE EXCEPTION 'Numéro de série, article et organisation obligatoires'; END IF;
 SELECT organization_id INTO v_org FROM public.articles WHERE id=NEW.article_id;
 IF v_org IS NOT NULL AND v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Article et numéro de série appartiennent à des organisations différentes'; END IF;
 IF NEW.status NOT IN ('in_stock','reserved','sold','returned','damaged','lost','inactive') THEN RAISE EXCEPTION 'Statut de numéro de série invalide'; END IF;
 IF NEW.status='sold' AND NEW.sale_id IS NULL THEN RAISE EXCEPTION 'Un numéro de série vendu doit être lié à une vente'; END IF;
 IF NEW.sale_id IS NOT NULL THEN
   SELECT organization_id,article_id,client_id INTO v_org,v_article,v_client FROM public.sales WHERE id=NEW.sale_id;
   IF NOT FOUND OR v_org<>NEW.organization_id OR v_article<>NEW.article_id THEN RAISE EXCEPTION 'Vente incompatible avec le numéro de série'; END IF;
   IF NEW.client_id IS NOT NULL AND v_client IS NOT NULL AND NEW.client_id<>v_client THEN RAISE EXCEPTION 'Client incompatible avec la vente'; END IF;
 END IF;
 IF NEW.client_id IS NOT NULL THEN
   SELECT organization_id INTO v_org FROM public.clients WHERE id=NEW.client_id;
   IF NOT FOUND OR v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Client incompatible avec le numéro de série'; END IF;
 END IF;
 RETURN NEW;
END $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_stock()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'private', 'auth'
AS $function$
BEGIN

    IF NEW.quantity IS NULL THEN
        NEW.quantity := 0;
    END IF;

    IF NEW.reserved_quantity IS NULL THEN
        NEW.reserved_quantity := 0;
    END IF;

    IF NEW.minimum_quantity IS NULL THEN
        NEW.minimum_quantity := 0;
    END IF;


    IF NEW.quantity < 0 THEN
        RAISE EXCEPTION
            'JDV CRM: le stock disponible ne peut pas être négatif';
    END IF;


    IF NEW.reserved_quantity < 0 THEN
        RAISE EXCEPTION
            'JDV CRM: le stock réservé ne peut pas être négatif';
    END IF;


    IF NEW.minimum_quantity < 0 THEN
        RAISE EXCEPTION
            'JDV CRM: le stock minimum ne peut pas être négatif';
    END IF;


    IF NEW.reserved_quantity > NEW.quantity THEN
        RAISE EXCEPTION
            'JDV CRM: le stock réservé (%) dépasse le stock disponible (%)',
            NEW.reserved_quantity,
            NEW.quantity;
    END IF;


    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_stock_movement()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO 'public', 'private', 'auth'
AS $function$
DECLARE
    v_article_org uuid;
    v_prospecteur_org uuid;
BEGIN
    IF NEW.quantity IS NULL OR NEW.quantity <= 0 THEN
        RAISE EXCEPTION 'JDV CRM: la quantité d''un mouvement de stock doit être supérieure à zéro';
    END IF;

    IF NEW.organization_id IS NULL THEN
        RAISE EXCEPTION 'JDV CRM: organization_id obligatoire pour un mouvement de stock';
    END IF;

    IF NEW.article_id IS NULL THEN
        RAISE EXCEPTION 'JDV CRM: article_id obligatoire pour un mouvement de stock';
    END IF;

    SELECT organization_id INTO v_article_org
    FROM public.articles
    WHERE id = NEW.article_id;

    IF NOT FOUND OR v_article_org <> NEW.organization_id THEN
        RAISE EXCEPTION 'JDV CRM: l''article et le mouvement doivent appartenir à la même organisation';
    END IF;

    IF NEW.prospecteur_id IS NOT NULL THEN
        SELECT organization_id INTO v_prospecteur_org
        FROM public.prospecteurs
        WHERE id = NEW.prospecteur_id;

        IF NOT FOUND OR v_prospecteur_org <> NEW.organization_id THEN
            RAISE EXCEPTION 'JDV CRM: le prospecteur et le mouvement doivent appartenir à la même organisation';
        END IF;
    END IF;

    RETURN NEW;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_stock_transfer_item_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_org uuid; v_aorg uuid;
BEGIN
  SELECT organization_id INTO v_org FROM stock_transfers WHERE id=NEW.transfer_id;
  SELECT organization_id INTO v_aorg FROM articles WHERE id=NEW.article_id;
  IF v_org IS NULL OR v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Ligne de transfert incompatible avec le transfert'; END IF;
  IF v_aorg IS NOT NULL AND v_aorg<>NEW.organization_id THEN RAISE EXCEPTION 'Article de transfert incompatible avec l''organisation'; END IF;
  IF NEW.quantity<=0 OR NEW.received_quantity<0 OR NEW.received_quantity>NEW.quantity THEN RAISE EXCEPTION 'Quantités de transfert invalides'; END IF;
  RETURN NEW;
END; $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_stock_transfer_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE vo uuid; vd uuid;
BEGIN
  SELECT organization_id INTO vo FROM warehouses WHERE id=NEW.source_warehouse_id;
  SELECT organization_id INTO vd FROM warehouses WHERE id=NEW.destination_warehouse_id;
  IF vo IS NULL OR vd IS NULL OR vo<>NEW.organization_id OR vd<>NEW.organization_id THEN RAISE EXCEPTION 'Entrepôts incompatibles avec l''organisation'; END IF;
  IF NEW.source_warehouse_id=NEW.destination_warehouse_id THEN RAISE EXCEPTION 'Source et destination doivent être différents'; END IF;
  RETURN NEW;
END; $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_supplier_payment_v2()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare po_org uuid; sup_org uuid;
begin
 if new.amount<=0 then raise exception 'Montant du paiement fournisseur invalide'; end if;
 select organization_id,supplier_id into po_org,sup_org from purchase_orders where id=new.purchase_order_id;
 if po_org is null or po_org<>new.organization_id then raise exception 'Commande fournisseur incompatible avec l''organisation'; end if;
 if sup_org<>new.supplier_id then raise exception 'Fournisseur incompatible avec la commande'; end if;
 if not exists(select 1 from suppliers where id=new.supplier_id and organization_id=new.organization_id) then raise exception 'Fournisseur incompatible avec l''organisation'; end if;
 return new;
end $function$
;

CREATE OR REPLACE FUNCTION public.jdvcrm_validate_warehouse_inventory_v1()
 RETURNS trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
DECLARE v_org uuid;
BEGIN
  SELECT organization_id INTO v_org FROM warehouses WHERE id=NEW.warehouse_id;
  IF v_org IS NULL OR v_org<>NEW.organization_id THEN RAISE EXCEPTION 'Inventaire entrepôt incompatible avec l''organisation'; END IF;
  IF NEW.quantity<0 OR NEW.reserved_quantity<0 OR NEW.minimum_quantity<0 THEN RAISE EXCEPTION 'Quantités d''entrepôt invalides'; END IF;
  IF NEW.reserved_quantity>NEW.quantity THEN RAISE EXCEPTION 'Stock réservé supérieur au stock disponible'; END IF;
  RETURN NEW;
END; $function$
;

CREATE OR REPLACE FUNCTION public.register_company(p_name text, p_phone text DEFAULT NULL::text, p_email text DEFAULT NULL::text, p_country text DEFAULT 'Bénin'::text, p_city text DEFAULT NULL::text)
 RETURNS uuid
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO ''
AS $function$
declare
  v_user_id uuid;
  v_org_id uuid;
begin

  v_user_id := (select auth.uid());

  if v_user_id is null then
    raise exception 'AUTHENTICATION_REQUIRED';
  end if;

  if p_name is null or trim(p_name) = '' then
    raise exception 'COMPANY_NAME_REQUIRED';
  end if;


  insert into public.organizations (
    name,
    email,
    phone,
    country,
    city,
    owner_user_id,
    status,
    subscription_status
  )
  values (
    trim(p_name),
    p_email,
    p_phone,
    coalesce(nullif(trim(p_country), ''), 'Bénin'),
    p_city,
    v_user_id,
    'pending',
    'inactive'
  )
  returning id into v_org_id;


  insert into public.organization_members (
    organization_id,
    user_id,
    role,
    status
  )
  values (
    v_org_id,
    v_user_id,
    'business_admin',
    'active'
  );


  insert into public.organization_settings (
    organization_id,
    settings
  )
  values (
    v_org_id,
    '{}'::jsonb
  );


  return v_org_id;

end;
$function$
;

CREATE OR REPLACE FUNCTION public.rls_auto_enable()
 RETURNS event_trigger
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'pg_catalog'
AS $function$
DECLARE
  cmd record;
BEGIN
  FOR cmd IN
    SELECT *
    FROM pg_event_trigger_ddl_commands()
    WHERE command_tag IN ('CREATE TABLE', 'CREATE TABLE AS', 'SELECT INTO')
      AND object_type IN ('table','partitioned table')
  LOOP
     IF cmd.schema_name IS NOT NULL AND cmd.schema_name IN ('public') AND cmd.schema_name NOT IN ('pg_catalog','information_schema') AND cmd.schema_name NOT LIKE 'pg_toast%' AND cmd.schema_name NOT LIKE 'pg_temp%' THEN
      BEGIN
        EXECUTE format('alter table if exists %s enable row level security', cmd.object_identity);
        RAISE LOG 'rls_auto_enable: enabled RLS on %', cmd.object_identity;
      EXCEPTION
        WHEN OTHERS THEN
          RAISE LOG 'rls_auto_enable: failed to enable RLS on %', cmd.object_identity;
      END;
     ELSE
        RAISE LOG 'rls_auto_enable: skip % (either system schema or not in enforced list: %.)', cmd.object_identity, cmd.schema_name;
     END IF;
  END LOOP;
END;
$function$
;

CREATE OR REPLACE FUNCTION public.set_client_code()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin

  if new.code is null or trim(new.code) = '' then
    new.code := public.generate_client_code();
  end if;

  return new;

end;
$function$
;

CREATE OR REPLACE FUNCTION public.set_prospecteur_code()
 RETURNS trigger
 LANGUAGE plpgsql
 SET search_path TO ''
AS $function$
begin

  if new.code is null or trim(new.code) = '' then
    new.code := public.generate_prospecteur_code();
  end if;

  return new;

end;
$function$
;

-- ===== views (14) =====

create or replace view public.jdv_super_admin_modules as  SELECT id,
    module_code,
    module_name,
    enabled,
    subscription_required
   FROM super_admin_modules m
  WHERE (enabled = true);


create or replace view public.jdvcrm_clients_overdue as  SELECT DISTINCT c.id AS client_id,
    c.organization_id,
    c.code,
    c.first_name,
    c.last_name,
    c.phone,
    c.whatsapp,
    c.address,
    c.city,
    c.prospecteur_id
   FROM (clients c
     JOIN sales s ON ((s.client_id = c.id)))
  WHERE ((c.archived_at IS NULL) AND (lower(COALESCE(s.sale_type, ''::text)) = 'credit'::text) AND (s.amount_remaining > (0)::numeric) AND (lower(COALESCE(s.status, ''::text)) <> ALL (ARRAY['cancelled'::text, 'completed'::text])) AND ((s.deadline_date IS NULL) OR (s.deadline_date < CURRENT_DATE)));


create or replace view public.jdvcrm_clients_to_reactivate as  SELECT id,
    organization_id,
    prospecteur_id,
    code,
    first_name,
    last_name,
    phone,
    whatsapp,
    email,
    address,
    city,
    country,
    latitude,
    longitude,
    identity_reference,
    status,
    temperature,
    notes,
    created_at,
    updated_at,
    last_activity_at,
    archived_at,
    last_payment_at,
    last_contact_at
   FROM clients c
  WHERE ((archived_at IS NULL) AND ((last_activity_at IS NULL) OR (last_activity_at <= (now() - '90 days'::interval))));


create or replace view public.jdvcrm_collections_monthly_v1 as  SELECT organization_id,
    (date_trunc('month'::text, payment_date))::date AS month,
    COALESCE(sum(amount) FILTER (WHERE (status = 'successful'::text)), (0)::numeric) AS collected_total,
    count(*) FILTER (WHERE (status = 'successful'::text)) AS payment_count
   FROM payments p
  GROUP BY organization_id, ((date_trunc('month'::text, payment_date))::date);


create or replace view public.jdvcrm_commissions_monthly_v1 as  SELECT organization_id,
    (date_trunc('month'::text, created_at))::date AS month,
    COALESCE(sum(commission_amount) FILTER (WHERE (status <> 'cancelled'::text)), (0)::numeric) AS commission_total,
    COALESCE(sum(commission_amount) FILTER (WHERE (status = ANY (ARRAY['pending'::text, 'approved'::text]))), (0)::numeric) AS commission_unpaid,
    COALESCE(sum(commission_amount) FILTER (WHERE (status = 'paid'::text)), (0)::numeric) AS commission_paid
   FROM commissions c
  GROUP BY organization_id, ((date_trunc('month'::text, created_at))::date);


create or replace view public.jdvcrm_financial_kpi_monthly_v1 as  SELECT organization_id,
    (date_trunc('month'::text, sale_date))::date AS month,
    count(*) AS sales_count,
    COALESCE(sum((
        CASE
            WHEN (lower(sale_type) = 'credit'::text) THEN credit_price
            ELSE cash_price
        END * (quantity)::numeric)), (0)::numeric) AS sales_total,
    COALESCE(sum(amount_paid), (0)::numeric) AS amount_paid,
    COALESCE(sum(amount_remaining), (0)::numeric) AS amount_remaining
   FROM sales s
  WHERE (status <> 'cancelled'::text)
  GROUP BY organization_id, ((date_trunc('month'::text, sale_date))::date);


create or replace view public.jdvcrm_followup_queue as  SELECT id,
    organization_id,
    prospecteur_id,
    first_name,
    last_name,
    phone,
    temperature,
    status,
    last_contact_at,
    next_follow_up_at,
    last_follow_up_at,
    (EXTRACT(day FROM (now() - COALESCE(last_contact_at, created_at))))::integer AS days_without_contact
   FROM prospects p
  WHERE ((archived_at IS NULL) AND (COALESCE(next_follow_up_at, last_contact_at, created_at) <= now()) AND (COALESCE(status, ''::text) <> ALL (ARRAY['converted'::text, 'archived'::text, 'closed'::text])));


create or replace view public.jdvcrm_low_stocks as  SELECT id,
    organization_id,
    article_id,
    quantity,
    reserved_quantity,
    minimum_quantity,
    GREATEST((quantity - reserved_quantity), 0) AS available_quantity
   FROM stocks s
  WHERE ((quantity - reserved_quantity) <= minimum_quantity);


create or replace view public.jdvcrm_overdue_credit_sales as  SELECT id,
    organization_id,
    sale_number,
    sale_date,
    client_id,
    prospecteur_id,
    article_id,
    quantity,
    fixed_price,
    cash_price,
    credit_price,
    amount_paid,
    amount_remaining,
    payment_frequency,
    payment_amount,
    deadline_date,
    client_location,
    client_phone,
        CASE
            WHEN (deadline_date IS NOT NULL) THEN (CURRENT_DATE - deadline_date)
            ELSE NULL::integer
        END AS days_overdue
   FROM sales s
  WHERE ((lower(COALESCE(sale_type, ''::text)) = 'credit'::text) AND (amount_remaining > (0)::numeric) AND (lower(COALESCE(status, ''::text)) <> ALL (ARRAY['cancelled'::text, 'completed'::text])) AND (deadline_date IS NOT NULL) AND (deadline_date < CURRENT_DATE));


create or replace view public.jdvcrm_overdue_payment_schedules as  SELECT id,
    organization_id,
    sale_id,
    installment_number,
    due_date,
    expected_amount,
    paid_amount,
    GREATEST((expected_amount - paid_amount), (0)::numeric) AS remaining_amount,
    status,
    reminder_sent,
    created_at,
    updated_at
   FROM payment_schedules ps
  WHERE ((due_date < CURRENT_DATE) AND (COALESCE(paid_amount, (0)::numeric) < COALESCE(expected_amount, (0)::numeric)) AND (COALESCE(status, ''::text) <> ALL (ARRAY['paid'::text, 'completed'::text, 'cancelled'::text])));


create or replace view public.jdvcrm_pending_commissions as  SELECT id,
    organization_id,
    prospecteur_id,
    sale_id,
    payment_id,
    article_id,
    commission_rate,
    base_amount,
    commission_amount,
    status,
    paid_at,
    created_at,
    updated_at
   FROM commissions c
  WHERE (lower(COALESCE(status, 'pending'::text)) = ANY (ARRAY['pending'::text, 'approved'::text, 'payable'::text]));


create or replace view public.jdvcrm_prospecteur_followup_queue as  SELECT id,
    organization_id,
    prospecteur_id,
    first_name,
    last_name,
    phone,
    whatsapp,
    address,
    city,
    desired_article,
    desired_article_id,
    temperature,
    visit_count,
    last_contact_at,
    next_follow_up_at,
    last_follow_up_at,
        CASE
            WHEN (last_contact_at IS NULL) THEN 999999
            ELSE (EXTRACT(day FROM (now() - last_contact_at)))::integer
        END AS days_without_contact
   FROM prospects p
  WHERE ((archived_at IS NULL) AND (lower(COALESCE(status, 'new'::text)) <> ALL (ARRAY['converted'::text, 'closed'::text, 'lost'::text, 'archived'::text])) AND ((next_follow_up_at <= now()) OR (last_contact_at IS NULL) OR (last_contact_at <= (now() - '14 days'::interval))))
  ORDER BY
        CASE lower(COALESCE(temperature, 'cold'::text))
            WHEN 'hot'::text THEN 1
            WHEN 'warm'::text THEN 2
            ELSE 3
        END, last_contact_at NULLS FIRST;


create or replace view public.jdvcrm_prospecteur_stock_status as  SELECT ps.id,
    ps.organization_id,
    ps.prospecteur_id,
    ps.article_id,
    ps.quantity,
    p.code AS prospecteur_code,
    p.first_name AS prospecteur_first_name,
    p.last_name AS prospecteur_last_name
   FROM (prospecteur_stocks ps
     JOIN prospecteurs p ON ((p.id = ps.prospecteur_id)));


create or replace view public.jdvcrm_prospects_to_followup as  SELECT id,
    organization_id,
    prospecteur_id,
    client_id,
    first_name,
    last_name,
    phone,
    whatsapp,
    address,
    city,
    desired_article,
    desired_article_id,
    temperature,
    visit_count,
    last_contact_at,
    next_follow_up_at,
    status,
    notes,
    created_at,
    updated_at,
    duplicate_phone_flag,
    duplicate_phone_of,
    last_follow_up_at,
    archived_at
   FROM prospects p
  WHERE ((archived_at IS NULL) AND (lower(COALESCE(status, 'new'::text)) <> ALL (ARRAY['converted'::text, 'closed'::text, 'lost'::text, 'archived'::text])) AND ((next_follow_up_at <= now()) OR (last_contact_at IS NULL) OR (last_contact_at <= (now() - '14 days'::interval))));


-- ===== triggers (83) =====

CREATE TRIGGER trg_article_categories_updated_at BEFORE UPDATE ON public.article_categories FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER trg_jdvcrm_validate_serial_assignment_v1 BEFORE INSERT OR UPDATE ON public.article_serial_assignments FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_serial_assignment_v1();

CREATE TRIGGER articles_updated_at BEFORE UPDATE ON public.articles FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER trg_call_center_tasks_updated_at BEFORE UPDATE ON public.call_center_tasks FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER before_client_code BEFORE INSERT ON public.clients FOR EACH ROW EXECUTE FUNCTION set_client_code();

CREATE TRIGGER clients_updated_at BEFORE UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER trg_jdvcrm_duplicate_client_phone_v41 BEFORE INSERT OR UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION jdvcrm_block_duplicate_client_phone_v41();

CREATE TRIGGER trg_jdvcrm_validate_client_prospecteur_v41 BEFORE INSERT OR UPDATE ON public.clients FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_prospecteur_reference_v41();

CREATE TRIGGER commissions_updated_at BEFORE UPDATE ON public.commissions FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER trg_jdvcrm_validate_commission_v41 BEFORE INSERT OR UPDATE ON public.commissions FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_commission_v41();

CREATE TRIGGER trg_company_settings_updated_at BEFORE UPDATE ON public.company_settings FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER daily_tokens_updated_at BEFORE UPDATE ON public.daily_tokens FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER trg_document_sequences_updated_at BEFORE UPDATE ON public.document_sequences FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER trg_document_templates_updated_at BEFORE UPDATE ON public.document_templates FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER trg_jdvcrm_refresh_prospect_visit AFTER INSERT ON public.field_visits FOR EACH ROW EXECUTE FUNCTION jdvcrm_refresh_prospect_visit_v1();

CREATE TRIGGER trg_jdvcrm_validate_goods_receipt_item_v2 BEFORE INSERT OR UPDATE ON public.goods_receipt_items FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_goods_receipt_item_v1();

CREATE TRIGGER trg_goods_receipts_updated_at BEFORE UPDATE ON public.goods_receipts FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER trg_jdvcrm_validate_goods_receipt_v1 BEFORE INSERT OR UPDATE ON public.goods_receipts FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_goods_receipt_v1();

CREATE TRIGGER trg_notification_preferences_updated_at BEFORE UPDATE ON public.notification_preferences FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER organization_members_updated_at BEFORE UPDATE ON public.organization_members FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER trg_guard_membership_user_change BEFORE UPDATE OF user_id ON public.organization_members FOR EACH ROW EXECUTE FUNCTION private.guard_membership_user_change();

CREATE TRIGGER trg_jdvcrm_audit_organization_member AFTER INSERT OR DELETE OR UPDATE ON public.organization_members FOR EACH ROW EXECUTE FUNCTION jdvcrm_audit_organization_member();

CREATE TRIGGER trg_organization_personalization_updated_at BEFORE UPDATE ON public.organization_personalization FOR EACH ROW EXECUTE FUNCTION jdvcrm_set_updated_at();

CREATE TRIGGER organization_settings_updated_at BEFORE UPDATE ON public.organization_settings FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER organization_subscriptions_updated_at BEFORE UPDATE ON public.organization_subscriptions FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER force_initial_organization_status BEFORE INSERT ON public.organizations FOR EACH ROW EXECUTE FUNCTION private.force_initial_organization_status();

CREATE TRIGGER guard_organization_platform_fields BEFORE UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION private.guard_organization_platform_fields();

CREATE TRIGGER organizations_updated_at BEFORE UPDATE ON public.organizations FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER trg_guard_organization_owner_change BEFORE UPDATE OF owner_user_id ON public.organizations FOR EACH ROW EXECUTE FUNCTION private.guard_organization_owner_change();

CREATE TRIGGER trg_start_organization_trial AFTER INSERT ON public.organizations FOR EACH ROW EXECUTE FUNCTION private.start_organization_trial();

CREATE TRIGGER trg_payment_provider_accounts_updated_at BEFORE UPDATE ON public.payment_provider_accounts FOR EACH ROW EXECUTE FUNCTION jdvcrm_set_updated_at();

CREATE TRIGGER payment_schedules_updated_at BEFORE UPDATE ON public.payment_schedules FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER trg_jdvcrm_validate_schedule_v41 BEFORE INSERT OR UPDATE ON public.payment_schedules FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_schedule_v41();

CREATE TRIGGER trg_jdv_audit_payment AFTER INSERT OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION jdv_audit_payment();

CREATE TRIGGER trg_jdv_update_client_activity_payment AFTER INSERT OR UPDATE OF status, payment_date, client_id ON public.payments FOR EACH ROW EXECUTE FUNCTION jdvcrm_update_client_payment_activity();

CREATE TRIGGER trg_jdvcrm_after_payment_v43 AFTER INSERT OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION jdvcrm_after_payment_v43();

CREATE TRIGGER trg_jdvcrm_validate_payment_v43 BEFORE INSERT OR UPDATE ON public.payments FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_payment_v43();

CREATE TRIGGER profiles_updated_at BEFORE UPDATE ON public.profiles FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER trg_jdvcrm_refresh_prospect_activity AFTER INSERT ON public.prospect_activities FOR EACH ROW EXECUTE FUNCTION jdvcrm_refresh_prospect_activity_v1();

CREATE TRIGGER trg_prospect_followups_updated_at BEFORE UPDATE ON public.prospect_followups FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER prospecteur_stocks_updated_at BEFORE UPDATE ON public.prospecteur_stocks FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER trg_jdvcrm_validate_prospecteur_stock BEFORE INSERT OR UPDATE ON public.prospecteur_stocks FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_prospecteur_stock();

CREATE TRIGGER before_prospecteur_code BEFORE INSERT ON public.prospecteurs FOR EACH ROW EXECUTE FUNCTION set_prospecteur_code();

CREATE TRIGGER prospecteurs_updated_at BEFORE UPDATE ON public.prospecteurs FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER prospects_updated_at BEFORE UPDATE ON public.prospects FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER trg_jdvcrm_audit_prospect_assignment AFTER UPDATE OF prospecteur_id ON public.prospects FOR EACH ROW EXECUTE FUNCTION jdvcrm_audit_prospect_assignment();

CREATE TRIGGER trg_jdvcrm_duplicate_prospect_phone_v41 BEFORE INSERT OR UPDATE ON public.prospects FOR EACH ROW EXECUTE FUNCTION jdvcrm_detect_duplicate_prospect_phone_v41();

CREATE TRIGGER trg_jdvcrm_prospect_assignment_protection BEFORE UPDATE OF prospecteur_id ON public.prospects FOR EACH ROW EXECUTE FUNCTION jdvcrm_protect_prospect_assignment();

CREATE TRIGGER trg_jdvcrm_record_prospect_status_history AFTER UPDATE OF status ON public.prospects FOR EACH ROW EXECUTE FUNCTION jdvcrm_record_prospect_status_history_v1();

CREATE TRIGGER trg_jdvcrm_validate_prospect BEFORE INSERT OR UPDATE ON public.prospects FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_prospect();

CREATE TRIGGER trg_jdvcrm_validate_prospect_prospecteur_v41 BEFORE INSERT OR UPDATE ON public.prospects FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_prospecteur_reference_v41();

CREATE TRIGGER trg_jdvcrm_validate_purchase_order_item_v1 BEFORE INSERT OR UPDATE ON public.purchase_order_items FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_purchase_order_item_v1();

CREATE TRIGGER trg_jdvcrm_validate_purchase_order_v1 BEFORE INSERT OR UPDATE ON public.purchase_orders FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_purchase_order_v1();

CREATE TRIGGER trg_purchase_orders_updated_at BEFORE UPDATE ON public.purchase_orders FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER trg_jdvcrm_validate_sale_return_item BEFORE INSERT OR UPDATE ON public.sales_return_items FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_sale_return();

CREATE TRIGGER trg_jdvcrm_validate_sale_return_item_serial_v2 BEFORE INSERT OR UPDATE ON public.sales_return_items FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_sale_return_item_serial_v2();

CREATE TRIGGER trg_jdvcrm_validate_sale_return_header BEFORE INSERT OR UPDATE ON public.sales_returns FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_return_header();

CREATE TRIGGER trg_sales_returns_updated_at BEFORE UPDATE ON public.sales_returns FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER sales_updated_at BEFORE UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER trg_jdvcrm_after_sale_v42 AFTER INSERT ON public.sales FOR EACH ROW EXECUTE FUNCTION jdvcrm_after_sale_v42();

CREATE TRIGGER trg_jdvcrm_audit_sale AFTER INSERT OR UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION jdvcrm_audit_sale();

CREATE TRIGGER trg_jdvcrm_client_sale_activity AFTER INSERT OR UPDATE OF client_id, sale_date ON public.sales FOR EACH ROW EXECUTE FUNCTION jdvcrm_update_client_sale_activity();

CREATE TRIGGER trg_jdvcrm_sale_client_activity_v41 AFTER INSERT OR DELETE OR UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION jdvcrm_sale_client_activity_v41();

CREATE TRIGGER trg_jdvcrm_sale_commission AFTER INSERT ON public.sales FOR EACH ROW EXECUTE FUNCTION jdvcrm_create_sale_commission();

CREATE TRIGGER trg_jdvcrm_validate_sale BEFORE INSERT OR UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_sale();

CREATE TRIGGER trg_jdvcrm_validate_sale_prospecteur_v41 BEFORE INSERT OR UPDATE ON public.sales FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_prospecteur_reference_v41();

CREATE TRIGGER trg_jdvcrm_validate_serial_number_v1 BEFORE INSERT OR UPDATE ON public.serial_numbers FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_serial_number_v1();

CREATE TRIGGER trg_serial_numbers_updated_at BEFORE UPDATE ON public.serial_numbers FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER trg_jdvcrm_audit_stock_movement AFTER INSERT ON public.stock_movements FOR EACH ROW EXECUTE FUNCTION jdvcrm_audit_stock_movement();

CREATE TRIGGER trg_jdvcrm_validate_stock_movement BEFORE INSERT ON public.stock_movements FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_stock_movement();

CREATE TRIGGER trg_jdvcrm_validate_stock_transfer_item_v1 BEFORE INSERT OR UPDATE ON public.stock_transfer_items FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_stock_transfer_item_v1();

CREATE TRIGGER trg_jdvcrm_validate_stock_transfer_v1 BEFORE INSERT OR UPDATE ON public.stock_transfers FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_stock_transfer_v1();

CREATE TRIGGER trg_stock_transfers_updated_at BEFORE UPDATE ON public.stock_transfers FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER stocks_updated_at BEFORE UPDATE ON public.stocks FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER trg_jdvcrm_validate_stock BEFORE INSERT OR UPDATE ON public.stocks FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_stock();

CREATE TRIGGER subscription_plans_updated_at BEFORE UPDATE ON public.subscription_plans FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER trg_super_admin_modules_updated_at BEFORE UPDATE ON public.super_admin_modules FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER super_admins_updated_at BEFORE UPDATE ON public.super_admins FOR EACH ROW EXECUTE FUNCTION private.set_updated_at();

CREATE TRIGGER trg_jdvcrm_validate_supplier_payment_v2 BEFORE INSERT OR UPDATE ON public.supplier_payments FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_supplier_payment_v2();

CREATE TRIGGER trg_suppliers_updated_at BEFORE UPDATE ON public.suppliers FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER trg_user_settings_updated_at BEFORE UPDATE ON public.user_settings FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

CREATE TRIGGER trg_jdvcrm_validate_warehouse_inventory_v1 BEFORE INSERT OR UPDATE ON public.warehouse_inventory FOR EACH ROW EXECUTE FUNCTION jdvcrm_validate_warehouse_inventory_v1();

CREATE TRIGGER trg_warehouses_updated_at BEFORE UPDATE ON public.warehouses FOR EACH ROW EXECUTE FUNCTION private.jdv_set_updated_at();

-- ===== rls_policies (229) =====

create policy admin_full_access on public.article_categories as PERMISSIVE for ALL to authenticated using ((private.is_org_admin(organization_id) OR private.is_super_admin())) with check ((private.is_org_admin(organization_id) OR private.is_super_admin()));

create policy subscription_access_guard on public.article_categories as RESTRICTIVE for ALL to authenticated using (private.has_active_subscription(organization_id)) with check (private.has_active_subscription(organization_id));

create policy super_admin_full_access on public.article_categories as PERMISSIVE for ALL to authenticated using (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin)) with check (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin));

create policy admin_full_access on public.article_serial_assignments as PERMISSIVE for ALL to authenticated using (private.is_org_admin(organization_id)) with check (private.is_org_admin(organization_id));

create policy prospecteur_read_own on public.article_serial_assignments as PERMISSIVE for SELECT to authenticated using (((prospecteur_id = ( SELECT prospecteurs.id
   FROM prospecteurs
  WHERE (prospecteurs.user_id = auth.uid()))) AND (organization_id = private.current_org_id())));

create policy subscription_access_guard on public.article_serial_assignments as RESTRICTIVE for ALL to authenticated using (private.has_active_subscription(organization_id)) with check (private.has_active_subscription(organization_id));

create policy super_admin_full_access on public.article_serial_assignments as PERMISSIVE for ALL to authenticated using (private.is_super_admin()) with check (private.is_super_admin());

create policy "JDV Super Admin Full Access articles" on public.articles as PERMISSIVE for ALL to authenticated using (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin)) with check (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin));

create policy articles_insert on public.articles as PERMISSIVE for INSERT to authenticated with check ((private.is_org_admin(organization_id) OR private.is_super_admin()));

create policy articles_select on public.articles as PERMISSIVE for SELECT to authenticated using ((private.is_org_member(organization_id) OR private.is_super_admin()));

create policy articles_update on public.articles as PERMISSIVE for UPDATE to authenticated using ((private.is_org_admin(organization_id) OR private.is_super_admin())) with check ((private.is_org_admin(organization_id) OR private.is_super_admin()));

create policy subscription_access_guard on public.articles as RESTRICTIVE for ALL to authenticated using (private.has_active_subscription(organization_id)) with check (private.has_active_subscription(organization_id));

create policy super_admin_full_access on public.audit_events as PERMISSIVE for ALL to authenticated using (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin)) with check (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin));

create policy audit_logs_super_admin on public.audit_logs as PERMISSIVE for SELECT to authenticated using (private.is_super_admin());

create policy audit_select on public.audit_logs as PERMISSIVE for SELECT to authenticated using ((private.is_org_admin(organization_id) OR private.is_super_admin()));

create policy subscription_access_guard on public.call_center_tasks as RESTRICTIVE for ALL to authenticated using (private.has_active_subscription(organization_id)) with check (private.has_active_subscription(organization_id));

create policy super_admin_full_access on public.call_center_tasks as PERMISSIVE for ALL to authenticated using (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin)) with check (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin));

create policy subscription_access_guard on public.call_logs as RESTRICTIVE for ALL to authenticated using (private.has_active_subscription(organization_id)) with check (private.has_active_subscription(organization_id));

create policy super_admin_full_access on public.call_logs as PERMISSIVE for ALL to authenticated using (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin)) with check (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin));

create policy client_portfolios_insert_own on public.client_portfolios as PERMISSIVE for INSERT to authenticated with check (((owner_user_id = ( SELECT auth.uid() AS uid)) AND (((owner_type = 'super_admin'::text) AND private.is_super_admin()) OR ((owner_type = 'prospecteur'::text) AND private.is_prospecteur(organization_id)))));

create policy client_portfolios_select_own on public.client_portfolios as PERMISSIVE for SELECT to authenticated using ((owner_user_id = ( SELECT auth.uid() AS uid)));

create policy client_portfolios_update_own on public.client_portfolios as PERMISSIVE for UPDATE to authenticated using ((owner_user_id = ( SELECT auth.uid() AS uid))) with check ((owner_user_id = ( SELECT auth.uid() AS uid)));

create policy clients_portfolio_insert on public.clients as PERMISSIVE for INSERT to authenticated with check ((((portfolio_id IN ( SELECT client_portfolios.id
   FROM client_portfolios
  WHERE (client_portfolios.owner_user_id = ( SELECT auth.uid() AS uid)))) AND private.has_active_subscription(organization_id)) OR (private.is_super_admin() AND (portfolio_id IN ( SELECT client_portfolios.id
   FROM client_portfolios
  WHERE ((client_portfolios.owner_user_id = ( SELECT auth.uid() AS uid)) AND (client_portfolios.owner_type = 'super_admin'::text))))) OR ((NOT private.is_super_admin()) AND private.is_org_admin(organization_id))));

create policy clients_portfolio_select on public.clients as PERMISSIVE for SELECT to authenticated using ((((portfolio_id IN ( SELECT client_portfolios.id
   FROM client_portfolios
  WHERE (client_portfolios.owner_user_id = ( SELECT auth.uid() AS uid)))) AND private.has_active_subscription(organization_id)) OR (private.is_super_admin() AND (portfolio_id IN ( SELECT client_portfolios.id
   FROM client_portfolios
  WHERE ((client_portfolios.owner_user_id = ( SELECT auth.uid() AS uid)) AND (client_portfolios.owner_type = 'super_admin'::text))))) OR ((NOT private.is_super_admin()) AND private.is_org_admin(organization_id))));

create policy clients_portfolio_update on public.clients as PERMISSIVE for UPDATE to authenticated using ((((portfolio_id IN ( SELECT client_portfolios.id
   FROM client_portfolios
  WHERE (client_portfolios.owner_user_id = ( SELECT auth.uid() AS uid)))) AND private.has_active_subscription(organization_id)) OR (private.is_super_admin() AND (portfolio_id IN ( SELECT client_portfolios.id
   FROM client_portfolios
  WHERE ((client_portfolios.owner_user_id = ( SELECT auth.uid() AS uid)) AND (client_portfolios.owner_type = 'super_admin'::text))))) OR ((NOT private.is_super_admin()) AND private.is_org_admin(organization_id)))) with check ((((portfolio_id IN ( SELECT client_portfolios.id
   FROM client_portfolios
  WHERE (client_portfolios.owner_user_id = ( SELECT auth.uid() AS uid)))) AND private.has_active_subscription(organization_id)) OR (private.is_super_admin() AND (portfolio_id IN ( SELECT client_portfolios.id
   FROM client_portfolios
  WHERE ((client_portfolios.owner_user_id = ( SELECT auth.uid() AS uid)) AND (client_portfolios.owner_type = 'super_admin'::text))))) OR ((NOT private.is_super_admin()) AND private.is_org_admin(organization_id))));

create policy "JDV Super Admin Full Access commissions" on public.commissions as PERMISSIVE for ALL to authenticated using (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin)) with check (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin));

create policy commissions_admin_all on public.commissions as PERMISSIVE for ALL to authenticated using (private.is_org_admin(organization_id)) with check (private.is_org_admin(organization_id));

create policy commissions_prospecteur_select on public.commissions as PERMISSIVE for SELECT to authenticated using ((private.is_prospecteur(organization_id) AND (EXISTS ( SELECT 1
   FROM prospecteurs p
  WHERE ((p.id = commissions.prospecteur_id) AND (p.organization_id = commissions.organization_id) AND (p.user_id = auth.uid()) AND (p.status = 'active'::text))))));

create policy commissions_super_admin_all on public.commissions as PERMISSIVE for ALL to authenticated using (private.is_super_admin()) with check (private.is_super_admin());

create policy subscription_access_guard on public.commissions as RESTRICTIVE for ALL to authenticated using (private.has_active_subscription(organization_id)) with check (private.has_active_subscription(organization_id));

create policy super_admin_full_access on public.company_settings as PERMISSIVE for ALL to authenticated using (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin)) with check (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin));

create policy super_admin_full_access on public.countries as PERMISSIVE for ALL to authenticated using (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin)) with check (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin));

create policy super_admin_full_access on public.currencies as PERMISSIVE for ALL to authenticated using (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin)) with check (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin));

create policy "JDV Super Admin Full Access daily_tokens" on public.daily_tokens as PERMISSIVE for ALL to authenticated using (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin)) with check (( SELECT private.jdv_is_super_admin() AS jdv_is_super_admin));

create policy daily_tokens_insert on public.daily_tokens as PERMISSIVE for INSERT to authenticated with check ((private.is_org_admin(organization_id) OR private.is_prospecteur(organization_id) OR private.is_super_admin()));

create policy daily_tokens_select on public.daily_tokens as PERMISSIVE for SELECT to authenticated using ((private.is_org_admin(organization_id) OR (private.is_prospecteur(organization_id) AND (prospecteur_id IN ( SELECT p.id
   FROM prospecteurs p
  WHERE (p.user_id = ( SELECT auth.uid() AS uid))))) OR private.is_super_admin()));

create policy daily_tokens_update on public.daily_tokens as PERMISSIVE for UPDATE to authenticated using ((private.is_org_admin(organization_id) OR private.is_prospecteur(organization_id) OR private.is_super_admin())) with check ((private.is_org_admin(organization_id) OR private.is_prospecteur(organization_id) OR private.is_super_admin()));

create policy subscription_access_guard on public.daily_tokens as RESTRICTIVE for ALL to authenticated using (private.has_active_subscription(organization_id)) with check (private.has_active_subscription(organization_id));


alter table public.rate_limits enable row level security;
revoke all on table public.rate_limits from anon, authenticated;

create or replace function public.jdvcrm_rate_limit_check_v1(
  p_key text,
  p_limit integer,
  p_window_seconds integer
)
returns table(allowed boolean, remaining integer, retry_at timestamptz)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer;
  v_reset timestamptz;
begin
  if coalesce(auth.role(), '') <> 'service_role' then
    raise exception 'SERVICE_ROLE_REQUIRED';
  end if;
  if p_key is null or length(p_key) = 0 or length(p_key) > 200 then
    raise exception 'INVALID_KEY';
  end if;
  if p_limit is null or p_limit < 1 or p_window_seconds is null or p_window_seconds < 1 then
    raise exception 'INVALID_LIMIT';
  end if;

  insert into public.rate_limits as r (key, count, reset_at)
  values (p_key, 1, now() + make_interval(secs => p_window_seconds))
  on conflict (key) do update
    set count = case when r.reset_at < now() then 1 else r.count + 1 end,
        reset_at = case when r.reset_at < now()
                        then now() + make_interval(secs => p_window_seconds)
                        else r.reset_at end
  returning r.count, r.reset_at into v_count, v_reset;

  -- Nettoyage occasionnel des fenêtres expirées depuis plus d'une heure
  if random() < 0.02 then
    delete from public.rate_limits where reset_at < now() - interval '1 hour';
  end if;

  return query select (v_count <= p_limit), greatest(0, p_limit - v_count), v_reset;
end;
$$;

revoke all on function public.jdvcrm_rate_limit_check_v1(text, integer, integer) from public, anon, authenticated;
grant execute on function public.jdvcrm_rate_limit_check_v1(text, integer, integer) to service_role;

-- ===== ajout 20261002184025_performance_dedupe_and_fk_indexes_v1 =====

-- 1) Supprime les index strictement identiques (mêmes colonnes, classes, prédicat, unicité).
--    On garde toujours un exemplaire : celui adossé à une contrainte s'il existe, sinon le premier par nom.
--    Aucun index lié à une clé primaire ou à une contrainte n'est supprimé.
-- 2) Crée un index sur chaque clé étrangère du schéma public qui n'en a pas.
do $$
declare
  r record;
begin
  for r in
    with idx as (
      select i.indexrelid, c.relname as idx, i.indisprimary,
             exists (select 1 from pg_constraint k where k.conindid = i.indexrelid) as sert_contrainte,
             i.indrelid, i.indkey::text as cols, i.indclass::text as cls, i.indisunique,
             coalesce(pg_get_expr(i.indpred, i.indrelid), '') as pred,
             coalesce(pg_get_expr(i.indexprs, i.indrelid), '') as expr
      from pg_index i
      join pg_class c on c.oid = i.indexrelid
      where c.relnamespace = 'public'::regnamespace and i.indisvalid
    ),
    ranked as (
      select idx, sert_contrainte, indisprimary,
             row_number() over (
               partition by indrelid, cols, cls, pred, expr, indisunique
               order by (sert_contrainte or indisprimary) desc, idx
             ) as rang
      from idx
    )
    select idx from ranked where rang > 1 and not sert_contrainte and not indisprimary
  loop
    execute format('drop index if exists public.%I', r.idx);
  end loop;

  for r in
    with fk as (
      select c.conrelid, c.conkey, cl.relname as tbl,
             (select string_agg(quote_ident(a.attname), ', ' order by k.ord)
                from unnest(c.conkey) with ordinality k(attnum, ord)
                join pg_attribute a on a.attrelid = c.conrelid and a.attnum = k.attnum) as cols,
             (select string_agg(a.attname, '_' order by k.ord)
                from unnest(c.conkey) with ordinality k(attnum, ord)
                join pg_attribute a on a.attrelid = c.conrelid and a.attnum = k.attnum) as cols_nom
      from pg_constraint c
      join pg_class cl on cl.oid = c.conrelid
      where c.contype = 'f' and c.connamespace = 'public'::regnamespace
    )
    select tbl, cols,
           case when length('idx_fk_' || tbl || '_' || cols_nom) > 63
                then left('idx_fk_' || tbl || '_' || cols_nom, 54) || '_' || left(md5('idx_fk_' || tbl || '_' || cols_nom), 8)
                else 'idx_fk_' || tbl || '_' || cols_nom end as nom
    from fk
    where not exists (
      select 1 from pg_index i
      where i.indrelid = fk.conrelid and i.indisvalid
        and (string_to_array(i.indkey::text, ' ')::int2[])[1:cardinality(fk.conkey)] = fk.conkey
    )
  loop
    execute format('create index if not exists %I on public.%I (%s)', r.nom, r.tbl, r.cols);
  end loop;
end
$$;

-- ===== ajout 20261003044456_add_atomic_purchasing_functions_v1 =====

-- Achats fournisseurs : fonctions ATOMIQUES (tout est enregistré, ou rien).
-- Chacune vérifie que l'appelant est administrateur de l'entreprise (ou concepteur), puis s'appuie sur
-- les contrôles existants (jdvcrm_process_goods_receipt_v1 / jdvcrm_process_supplier_payment_v1) : si l'un
-- d'eux refuse, toute la transaction est annulée et aucune réception ni aucun paiement « fantôme » ne subsiste.

-- 1) Créer une commande fournisseur avec ses lignes
create or replace function public.jdvcrm_create_purchase_order_v1(
  p_supplier_id uuid,
  p_expected_date date,
  p_notes text,
  p_items jsonb
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_org uuid;
  v_status text;
  v_item jsonb;
  v_article uuid;
  v_qty numeric;
  v_cost numeric;
  v_total numeric := 0;
  v_po uuid;
  v_prefix text;
  v_seq integer;
  v_number text;
  v_lines integer := 0;
  v_seen uuid[] := '{}';
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  select organization_id, status into v_org, v_status from public.suppliers where id = p_supplier_id;
  if v_org is null then raise exception 'Fournisseur introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(v_org)) then raise exception 'Accès refusé'; end if;
  if v_status <> 'active' then raise exception 'Ce fournisseur n''est pas actif'; end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'La commande doit contenir au moins une ligne';
  end if;
  if jsonb_array_length(p_items) > 200 then raise exception 'Trop de lignes (200 maximum)'; end if;
  if p_expected_date is not null and p_expected_date < current_date then
    raise exception 'La date de livraison prévue est dans le passé';
  end if;

  -- Contrôle des lignes et calcul du total
  for v_item in select value from jsonb_array_elements(p_items) loop
    begin
      v_article := (v_item ->> 'article_id')::uuid;
      v_qty := (v_item ->> 'quantity')::numeric;
      v_cost := coalesce((v_item ->> 'unit_cost')::numeric, 0);
    exception when others then
      raise exception 'Ligne de commande invalide';
    end;
    if v_article is null or v_qty is null or v_qty <= 0 or v_cost < 0 then raise exception 'Ligne de commande invalide'; end if;
    if v_qty > 1000000000 or v_cost > 100000000000 then raise exception 'Valeur trop élevée dans une ligne de commande'; end if;
    if v_article = any (v_seen) then raise exception 'Un article apparaît deux fois dans la commande'; end if;
    v_seen := v_seen || v_article;
    if not exists (select 1 from public.articles where id = v_article and organization_id = v_org) then
      raise exception 'Article introuvable dans cette entreprise';
    end if;
    v_total := v_total + round(v_qty * v_cost, 2);
  end loop;

  -- Numérotation CF-AAAAMMJJ-001, protégée contre deux créations simultanées
  perform pg_advisory_xact_lock(hashtext('jdvcrm_po:' || v_org::text));
  v_prefix := 'CF-' || to_char(current_date, 'YYYYMMDD') || '-';
  select coalesce(max((substring(order_number from '(\d+)$'))::integer), 0) + 1
    into v_seq
    from public.purchase_orders
   where organization_id = v_org and order_number like v_prefix || '%';
  v_number := v_prefix || lpad(v_seq::text, 3, '0');

  insert into public.purchase_orders
    (organization_id, supplier_id, order_number, order_date, expected_date,
     subtotal, discount_amount, tax_amount, total_amount, status, notes, created_by)
  values
    (v_org, p_supplier_id, v_number, current_date, p_expected_date,
     v_total, 0, 0, v_total, 'confirmed', nullif(left(trim(coalesce(p_notes, '')), 1000), ''), auth.uid())
  returning id into v_po;

  for v_item in select value from jsonb_array_elements(p_items) loop
    v_qty := (v_item ->> 'quantity')::numeric;
    v_cost := coalesce((v_item ->> 'unit_cost')::numeric, 0);
    insert into public.purchase_order_items
      (organization_id, purchase_order_id, article_id, quantity, unit_cost, discount_amount, tax_amount, total_amount)
    values
      (v_org, v_po, (v_item ->> 'article_id')::uuid, v_qty, v_cost, 0, 0, round(v_qty * v_cost, 2));
    v_lines := v_lines + 1;
  end loop;

  return jsonb_build_object('success', true, 'purchase_order_id', v_po, 'order_number', v_number,
                            'total_amount', v_total, 'lines', v_lines);
end;
$$;

-- 2) Réceptionner (totalement ou partiellement) une commande : entrée en stock
create or replace function public.jdvcrm_receive_purchase_order_v1(
  p_purchase_order_id uuid,
  p_items jsonb,
  p_notes text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  po public.purchase_orders%rowtype;
  v_item jsonb;
  v_article uuid;
  v_qty numeric;
  v_cost numeric;
  v_receipt uuid;
  v_prefix text;
  v_seq integer;
  v_number text;
  v_res jsonb;
  v_new_status text;
  v_seen uuid[] := '{}';
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  select * into po from public.purchase_orders where id = p_purchase_order_id for update;
  if not found then raise exception 'Commande fournisseur introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(po.organization_id)) then raise exception 'Accès refusé'; end if;
  if po.status not in ('draft', 'sent', 'confirmed', 'partial') then
    raise exception 'Cette commande ne peut plus être réceptionnée (statut : %)', po.status;
  end if;
  if p_items is null or jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Indiquez au moins une quantité reçue';
  end if;
  if jsonb_array_length(p_items) > 200 then raise exception 'Trop de lignes (200 maximum)'; end if;

  perform pg_advisory_xact_lock(hashtext('jdvcrm_br:' || po.organization_id::text));
  v_prefix := 'BR-' || to_char(current_date, 'YYYYMMDD') || '-';
  select coalesce(max((substring(receipt_number from '(\d+)$'))::integer), 0) + 1
    into v_seq
    from public.goods_receipts
   where organization_id = po.organization_id and receipt_number like v_prefix || '%';
  v_number := v_prefix || lpad(v_seq::text, 3, '0');

  insert into public.goods_receipts
    (organization_id, purchase_order_id, receipt_number, receipt_date, status, notes, received_by)
  values
    (po.organization_id, po.id, v_number, current_date, 'received',
     nullif(left(trim(coalesce(p_notes, '')), 1000), ''), auth.uid())
  returning id into v_receipt;

  for v_item in select value from jsonb_array_elements(p_items) loop
    begin
      v_article := (v_item ->> 'article_id')::uuid;
      v_qty := (v_item ->> 'quantity_received')::numeric;
    exception when others then
      raise exception 'Ligne de réception invalide';
    end;
    if v_article is null or v_qty is null or v_qty <= 0 then raise exception 'Quantité reçue invalide'; end if;
    if v_qty > 1000000000 then raise exception 'Quantité reçue trop élevée'; end if;
    -- un même article deux fois contournerait le contrôle de quantité commandée
    if v_article = any (v_seen) then raise exception 'Un article apparaît deux fois dans la réception'; end if;
    v_seen := v_seen || v_article;
    select unit_cost into v_cost
      from public.purchase_order_items
     where purchase_order_id = po.id and article_id = v_article
     order by created_at limit 1;
    if not found then raise exception 'Article absent de la commande fournisseur'; end if;
    insert into public.goods_receipt_items (organization_id, receipt_id, article_id, quantity_received, unit_cost)
    values (po.organization_id, v_receipt, v_article, v_qty, v_cost);
  end loop;

  -- Contrôle des quantités et entrée en stock (lève une erreur, donc annule tout, si la réception dépasse la commande)
  v_res := public.jdvcrm_process_goods_receipt_v1(v_receipt);
  select status into v_new_status from public.purchase_orders where id = po.id;

  return jsonb_build_object('success', true, 'receipt_id', v_receipt, 'receipt_number', v_number,
                            'order_status', v_new_status, 'quantity_added', v_res -> 'quantity_added');
end;
$$;

-- 3) Enregistrer un paiement fournisseur sur une commande
create or replace function public.jdvcrm_pay_purchase_order_v1(
  p_purchase_order_id uuid,
  p_amount numeric,
  p_method text,
  p_reference text,
  p_notes text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  po public.purchase_orders%rowtype;
  v_payment uuid;
  v_res jsonb;
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  select * into po from public.purchase_orders where id = p_purchase_order_id for update;
  if not found then raise exception 'Commande fournisseur introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(po.organization_id)) then raise exception 'Accès refusé'; end if;
  if po.status = 'cancelled' then raise exception 'Cette commande est annulée'; end if;
  if p_amount is null or p_amount <= 0 or p_amount > 100000000000 then raise exception 'Montant du paiement invalide'; end if;
  if p_method is null or p_method not in ('cash', 'mobile_money', 'bank_transfer', 'cheque', 'other') then
    raise exception 'Mode de paiement invalide';
  end if;

  insert into public.supplier_payments
    (organization_id, supplier_id, purchase_order_id, amount, currency, payment_method,
     provider_reference, status, recorded_by, notes)
  values
    (po.organization_id, po.supplier_id, po.id, round(p_amount, 2), 'XOF', p_method,
     nullif(left(trim(coalesce(p_reference, '')), 120), ''), 'paid', auth.uid(),
     nullif(left(trim(coalesce(p_notes, '')), 1000), ''))
  returning id into v_payment;

  -- Lève une erreur (et annule tout) si le total payé dépasse le montant de la commande
  v_res := public.jdvcrm_process_supplier_payment_v1(v_payment);

  return jsonb_build_object('success', true, 'payment_id', v_payment,
                            'paid_total', v_res -> 'paid_total', 'remaining', v_res -> 'remaining');
end;
$$;

-- 4) Annuler une commande (impossible si des marchandises ont été reçues ou des paiements enregistrés)
create or replace function public.jdvcrm_cancel_purchase_order_v1(p_purchase_order_id uuid)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  po public.purchase_orders%rowtype;
begin
  if auth.uid() is null then raise exception 'Authentification requise'; end if;
  select * into po from public.purchase_orders where id = p_purchase_order_id for update;
  if not found then raise exception 'Commande fournisseur introuvable'; end if;
  if not (private.is_super_admin() or private.is_org_admin(po.organization_id)) then raise exception 'Accès refusé'; end if;
  if po.status = 'cancelled' then raise exception 'Cette commande est déjà annulée'; end if;
  if exists (select 1 from public.goods_receipts where purchase_order_id = po.id and status = 'received') then
    raise exception 'Impossible d''annuler : des marchandises ont déjà été reçues';
  end if;
  if exists (select 1 from public.supplier_payments where purchase_order_id = po.id and status = 'paid') then
    raise exception 'Impossible d''annuler : des paiements ont déjà été enregistrés';
  end if;
  update public.purchase_orders set status = 'cancelled' where id = po.id;
  return jsonb_build_object('success', true, 'status', 'cancelled');
end;
$$;

revoke all on function public.jdvcrm_create_purchase_order_v1(uuid, date, text, jsonb) from public, anon;
revoke all on function public.jdvcrm_receive_purchase_order_v1(uuid, jsonb, text) from public, anon;
revoke all on function public.jdvcrm_pay_purchase_order_v1(uuid, numeric, text, text, text) from public, anon;
revoke all on function public.jdvcrm_cancel_purchase_order_v1(uuid) from public, anon;
grant execute on function public.jdvcrm_create_purchase_order_v1(uuid, date, text, jsonb) to authenticated;
grant execute on function public.jdvcrm_receive_purchase_order_v1(uuid, jsonb, text) to authenticated;
grant execute on function public.jdvcrm_pay_purchase_order_v1(uuid, numeric, text, text, text) to authenticated;
grant execute on function public.jdvcrm_cancel_purchase_order_v1(uuid) to authenticated;
