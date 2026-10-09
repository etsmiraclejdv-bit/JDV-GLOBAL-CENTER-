#!/usr/bin/env bash
# Synchronise GitHub avec Supabase (migrations + fonction company-ai-review).
# À lancer depuis la racine d'un clone de JDV-CORRIGER-FINAL, branche main à jour :
#   git checkout main && git pull
#   bash chemin/vers/sync_supabase_github.sh
set -euo pipefail
cd "$(git rev-parse --show-toplevel)"
HERE="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
M=supabase/migrations

# 1) Aligner les noms de fichiers GitHub sur les versions réellement appliquées dans Supabase
rename() {
  if [ -f "$M/$1" ]; then git mv "$M/$1" "$M/$2"; echo "renommé : $1 -> $2"; else echo "ignoré (déjà fait ou absent) : $1"; fi
}
rename 20261007130000_fix_organization_applications_authenticated_grants_v1.sql 20261007124229_fix_organization_applications_authenticated_grants_v1.sql
rename 20261007143000_finalize_company_application_v1.sql 20261007131402_finalize_company_application_v1.sql
rename 20261008200000_warehouse_subwarehouses_admin_v1.sql 20261008183819_warehouse_subwarehouses_admin_v1.sql
rename 20261008200500_harden_warehouse_subwarehouses_admin_v1.sql 20261008183835_harden_warehouse_subwarehouses_admin_v1.sql
rename 20261008201000_preserve_warehouse_subwarehouse_history_v1.sql 20261008183922_preserve_warehouse_subwarehouse_history_v1.sql
rename 20261008210000_warehouse_stock_journal_inventory_closure_v1.sql 20261008184729_warehouse_stock_journal_inventory_closure_v1.sql
rename 20261008220000_link_stock_to_subwarehouses_v1.sql 20261008185008_link_stock_to_subwarehouses_v1.sql
rename 20261008230000_subwarehouse_stock_journal_closure_v1.sql 20261008185724_subwarehouse_stock_journal_closure_v1.sql
rename 20261008240000_return_traceability_agent_prospecteur_v1.sql 20261008185937_return_traceability_agent_prospecteur_v1.sql
rename 20261008250000_ai_jdv_crm_sector_knowledge_v1.sql 20261008200212_ai_jdv_crm_sector_knowledge_v1_retry.sql
rename 20261008260000_ai_jdv_crm_operational_sections_v1.sql 20261008200533_ai_jdv_crm_operational_sections_v1.sql

# 2) Ajouter les 4 migrations déjà appliquées dans Supabase mais absentes de GitHub
cp -n "$HERE"/supabase/migrations/*.sql "$M"/

# 3) Récupérer le code de la fonction déjà déployée dans Supabase (optionnel, nécessite la CLI Supabase connectée)
if command -v supabase >/dev/null 2>&1; then
  supabase functions download company-ai-review --project-ref arxhppptxeeyeexkdyjv --use-api \
    || echo "Téléchargement de la fonction impossible : faites 'supabase login' puis relancez cette étape."
else
  echo "CLI Supabase absente : étape 3 ignorée (la fonction company-ai-review reste à ajouter dans supabase/functions/)."
fi

git add supabase
git status --short
echo
echo "Vérifiez la liste ci-dessus, puis : git commit -m 'chore(supabase): aligner les migrations GitHub sur Supabase' && git push origin main"
echo "Attention : ce push lancera le workflow 'Deploy Supabase migrations'. Il doit se terminer sans rien appliquer."
