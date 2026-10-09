# Index des migrations appliquées sur Supabase (133 au 2026-10-09)

Le SQL de chaque migration est stocké dans Supabase (`supabase_migrations.schema_migrations`). Pour le versionner ici :
`supabase link --project-ref lncgghdbnkehdcyhqdfo` puis `supabase db pull`.

Séquence principale : crm_01..06 (20260918) ; immo_01..05, travel_01..05, transport_01..05, transit_01..06 (20260919) ;
health_01..05 ; jdv_pay_* ; jdv_ai_* (v1..v12) ; jdv_tontine_* (foundation, phases 2 à 4f) ; jdv_*_harden_* (sécurité) ;
foundations agriculture, energy, academy, pub, media, social (20260920) ; activations de modules (crm, immo, travel) ;
dédoublonnage 20261009 (voir les fichiers .sql de ce dossier).
