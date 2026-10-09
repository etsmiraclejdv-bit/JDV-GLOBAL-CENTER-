# Schéma Supabase JDV GLOBAL CENTER FINAL (état au 2026-10-09)

Projet `lncgghdbnkehdcyhqdfo`, Postgres 17, région ca-central-1. **254 tables dans `public`, RLS activé sur toutes.**
Vue `payment_providers_catalog` (sur `payment_providers`). Fonction `transport_reserve_seat` en 2 surcharges volontaires (la version à 4 paramètres appelle celle à 5).

| Module | Préfixe des tables |
|---|---|
| Socle | countries, currencies, languages, modules, roles, permissions, role_permissions, organizations, organization_*, profiles, super_admins, system_settings, user_*, notifications, audit_logs |
| JDV PAY | wallets, wallet_transactions, payment_*, transfers, transfer_events, exchange_*, fee_rules, transaction_*, kyc_*, billers, bill_payments, cashback_*, webhook_events, pay_beneficiaries |
| Tontine (10) | tontines, tontine_* |
| Assurance (10) | insurance_ |
| Business / ERP (14) | business_ |
| Marketplace (21) | marketplace_ |
| CRM / Prospecteur (14) | crm_ |
| Immo (19) | immo_ |
| Travel (23) | travel_, travelers |
| Transport / Delivery (23) | transport_ |
| Transit (21) | transit_ |
| Health (19) | health_ |
| Agri (6) | agri_ |
| Energy (5) | energy_ |
| Academy (6) | academy_ |
| Pub / ADS (6) | pub_ |
| Media (5) | media_ |
| Social (5) | social_ |
| IA (7) | ai_ |

## Modules (table `modules`)
jdv_academy, jdv_agriculture, jdv_ai, jdv_business, jdv_core, jdv_crm, jdv_energy, jdv_health, jdv_immo, jdv_insurance, jdv_marketplace, jdv_media, jdv_pay, jdv_pub, jdv_social, jdv_tontine, jdv_transit, jdv_transport, jdv_travel.

## Pôles du README sans tables
Bank, Construction, Mobility, Automotive, Industry, Cloud, Blockchain, Analytics, Legal, E-City, Security, HR, International, Support.
