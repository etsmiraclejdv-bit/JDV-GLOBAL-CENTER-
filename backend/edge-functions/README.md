# Edge Functions JDV

Code source des 3 Edge Functions déployées sur le projet Supabase `lncgghdbnkehdcyhqdfo` (JDV GLOBAL CENTER FINAL), exporté le 2026-10-09.

| Fonction | Version | verify_jwt | Rôle |
|---|---|---|---|
| `jdv-ai-chat` | 9 | oui | Assistant JDV IA (politique, quota, rate limit, journalisation) |
| `jdv-tontine-payout-worker` | 2 | oui | Mise en file et envoi des paiements de tontine via FedaPay |
| `jdv-tontine-fedapay-webhook` | 3 | non (webhook) | Statuts FedaPay ; signature HMAC SHA-256 vérifiée dans le code |

## Secrets requis (jamais dans Git)
`OPENAI_API_KEY`, `FEDAPAY_API_KEY`, `FEDAPAY_WEBHOOK_SECRET`, et facultativement `FEDAPAY_PAYOUT_MODE`, `FEDAPAY_API_BASE_URL`.

## Déploiement
```bash
supabase functions deploy jdv-ai-chat --project-ref lncgghdbnkehdcyhqdfo
supabase functions deploy jdv-tontine-payout-worker --project-ref lncgghdbnkehdcyhqdfo
supabase functions deploy jdv-tontine-fedapay-webhook --no-verify-jwt --project-ref lncgghdbnkehdcyhqdfo
```
