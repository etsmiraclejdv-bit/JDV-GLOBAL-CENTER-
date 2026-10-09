# Supabase – JDV CRM

Projet Supabase `CRM JDV` (eu-west-1, Postgres 17). Export du 2026-10-01.

| Dossier | Rôle |
|---|---|
| `schema/00_baseline_public_schema.sql` | Instantané complet du schéma `public` (77 tables, contraintes, FK, index, RLS, 124 fonctions, 14 vues, triggers, policies). **Source pour recréer la base.** |
| `migrations/` | Historique exact des 80 migrations appliquées en base (référence). Ne crée pas les tables initiales : ne pas rejouer seul sur une base vide. |
| `legacy_local_migrations/` | Anciens brouillons du dépôt. **Différents de ce qui est appliqué en base, ne pas exécuter.** Gardés pour mémoire. |
| `functions/` | Edge Functions (`send-email`). |

## Volontairement exclus
Migration de données de démo, migration d'un super admin nommé, toute donnée de table, toute clé ou secret.

## Recréer le schéma
```bash
psql "$DATABASE_URL" -f supabase/schema/00_baseline_public_schema.sql
```
Les schémas `auth` et `storage` sont gérés par Supabase.
