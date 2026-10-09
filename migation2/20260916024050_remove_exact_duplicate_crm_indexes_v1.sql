-- BLOCK 15: remove only indexes proven to be exact duplicates.
-- No data is changed; unique constraints/indexes are preserved.

drop index if exists public.idx_jdvcrm_clients_last_activity;
drop index if exists public.idx_jdvcrm_clients_status;
drop index if exists public.idx_clients_phone;

drop index if exists public.idx_payments_client;
drop index if exists public.idx_payments_sale;
drop index if exists public.idx_payments_org_date;
drop index if exists public.idx_payments_provider_transaction_id;

drop index if exists public.idx_sales_org_client;
drop index if exists public.idx_sales_org_date;

drop index if exists public.idx_stocks_org_article;

drop index if exists public.idx_prospects_org_followup;
drop index if exists public.idx_jdvcrm_prospects_phone;

-- uq_jdvcrm_org_active_subscription already enforces one organization
-- subscription across pending/trial/active/past_due, making this narrower
-- overlapping unique index redundant.
drop index if exists public.uq_org_current_subscription;
