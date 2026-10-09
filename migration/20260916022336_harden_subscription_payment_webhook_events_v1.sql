-- BLOC 2 : paiements d'abonnement / événements provider / webhooks
-- Aucun secret provider n'est exposé aux utilisateurs ordinaires.

create unique index if not exists uq_payment_provider_events_provider_event_id
on public.payment_provider_events(provider, provider_event_id)
where provider_event_id is not null;

create unique index if not exists uq_payment_webhook_events_provider_external_event_id
on public.payment_webhook_events(provider, external_event_id)
where external_event_id is not null;

create index if not exists idx_payment_provider_events_org_created
on public.payment_provider_events(organization_id, created_at desc);

create index if not exists idx_payment_webhook_events_org_created
on public.payment_webhook_events(organization_id, created_at desc);

create index if not exists idx_subscription_payments_org_created
on public.subscription_payments(organization_id, created_at desc);

create index if not exists idx_subscription_events_org_created
on public.subscription_events(organization_id, created_at desc);

-- Les comptes provider peuvent contenir des secrets chiffrés : aucun accès direct
-- en lecture/écriture pour les utilisateurs d'entreprise.
drop policy if exists payment_provider_accounts_select on public.payment_provider_accounts;
drop policy if exists payment_provider_accounts_insert on public.payment_provider_accounts;
drop policy if exists payment_provider_accounts_update on public.payment_provider_accounts;

create policy payment_provider_accounts_super_admin_only
on public.payment_provider_accounts
for all to authenticated
using (private.is_super_admin())
with check (private.is_super_admin());

-- Les événements provider sont des journaux techniques : lecture réservée au SUPER ADMIN.
drop policy if exists super_admin_full_access on public.payment_provider_events;
create policy payment_provider_events_super_admin_only
on public.payment_provider_events
for all to authenticated
using (private.is_super_admin())
with check (private.is_super_admin());

-- Les webhooks sont des événements techniques ; aucun accès direct client.
drop policy if exists super_admin_full_access on public.payment_webhook_events;
create policy payment_webhook_events_super_admin_only
on public.payment_webhook_events
for all to authenticated
using (private.is_super_admin())
with check (private.is_super_admin());

-- Empêche les paiements d'abonnement d'être enregistrés avec des montants non positifs.
alter table public.subscription_payments
  drop constraint if exists subscription_payments_amount_positive;
alter table public.subscription_payments
  add constraint subscription_payments_amount_positive check (amount > 0);

-- Montants et périodes d'abonnement restent cohérents avec un plan actif.
create index if not exists idx_subscription_plans_active_code
on public.subscription_plans(code)
where active = true;
