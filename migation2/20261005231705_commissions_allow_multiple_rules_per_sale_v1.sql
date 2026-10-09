-- L'ancien index (sale_id, prospecteur_id) interdisait plusieurs commissions pour une même vente,
-- ce qui faisait échouer la création de toute vente couverte par 2 règles cumulables.
-- Le bon verrou existe déjà : commissions_sale_rule_prospecteur_uq (sale_id, rule_id, prospecteur_id).
drop index if exists public.ux_jdvcrm_commission_sale_prospecteur;

-- Une seule commission « taux personnel » (sans règle) par vente et par prospecteur.
create unique index if not exists commissions_sale_prospecteur_no_rule_uq
  on public.commissions (sale_id, prospecteur_id)
  where sale_id is not null and prospecteur_id is not null and rule_id is null;