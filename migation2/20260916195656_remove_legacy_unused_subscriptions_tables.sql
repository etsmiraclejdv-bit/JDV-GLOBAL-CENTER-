-- Tables legacy jamais utilisées par le code applicatif.
-- Le seul schéma d'abonnement réel est organization_subscriptions
-- (utilisé dans business/login, api/enterprise/*, payment-wall,
-- hidden-concepteur-gate, superAdminService).
drop table if exists public.subscription_events;
drop table if exists public.subscriptions;
