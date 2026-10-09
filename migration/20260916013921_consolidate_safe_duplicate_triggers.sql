BEGIN;

-- Un seul mécanisme updated_at par table : private.set_updated_at().
DROP TRIGGER IF EXISTS trg_jdvcrm_clients_updated_at ON public.clients;
DROP TRIGGER IF EXISTS trg_jdvcrm_commissions_updated_at ON public.commissions;
DROP TRIGGER IF EXISTS trg_jdvcrm_payment_schedules_updated_at ON public.payment_schedules;
DROP TRIGGER IF EXISTS trg_jdvcrm_prospecteur_stocks_updated_at ON public.prospecteur_stocks;
DROP TRIGGER IF EXISTS trg_jdvcrm_prospects_updated_at ON public.prospects;
DROP TRIGGER IF EXISTS trg_jdvcrm_sales_updated_at ON public.sales;
DROP TRIGGER IF EXISTS trg_jdvcrm_stocks_updated_at ON public.stocks;

-- Un seul déclencheur de création de commission après insertion d'une vente.
-- La version jdvcrm_create_sale_commission vérifie déjà l'existence et le taux.
DROP TRIGGER IF EXISTS trg_jdv_create_sale_commission ON public.sales;

-- Protection anti-réaffectation : conserver la version jdvcrm, plus complète.
DROP TRIGGER IF EXISTS trg_jdv_protect_prospect_assignment ON public.prospects;

-- Détection téléphone : conserver la version v41 avec verrou advisory transactionnel.
DROP TRIGGER IF EXISTS trg_jdv_check_duplicate_prospect_phone ON public.prospects;
DROP TRIGGER IF EXISTS trg_jdvcrm_duplicate_prospect_phone ON public.prospects;

COMMIT;
