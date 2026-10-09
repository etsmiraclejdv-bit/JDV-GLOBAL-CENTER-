# Checklist avant lancement public

Ce qui ne peut PAS être fait par le code : à faire à la main, dans l'ordre.

## 1. Synchroniser le lockfile (bloquant pour la CI)
`fedapay` est dans `package.json` mais absent de `package-lock.json`, et sa version est `latest`.
```bash
npm install fedapay@latest --save-exact   # fige la version ET met à jour le lockfile
git add package.json package-lock.json
git commit -m "Fige fedapay et synchronise le lockfile"
```

## 2. Test de paiement de bout en bout (sandbox FedaPay) — jamais exécuté à ce jour
Prérequis : clés **sandbox** (`sk_sandbox_…`) dans `FEDAPAY_SECRET_KEY` et `FEDAPAY_WEBHOOK_SECRET`,
webhook FedaPay pointé sur `https://<ton-domaine>/api/fedapay-webhook` (événement `transaction.approved`).

| # | Action | Résultat attendu |
|---|--------|------------------|
| 1 | Compte administrateur d'entreprise, plan MONTHLY (30 000 XOF) | Redirection vers la page FedaPay |
| 2 | Payer avec un numéro de test | Retour sur `/business/dashboard?payment=success` |
| 3 | `select status from subscription_payments order by created_at desc limit 1;` | `paid` |
| 4 | `select * from organization_subscriptions where organization_id = '<id>';` | abonnement actif, date de fin cohérente |
| 5 | `select count(*) from payment_webhook_events;` | 1 événement tracé |
| 6 | Rejouer le même webhook depuis le tableau de bord FedaPay | Aucun doublon (idempotent), pas de double prolongation |
| 7 | Envoyer un faux webhook (mauvaise signature) avec curl | HTTP 400 `Invalid signature` |
| 8 | Paiement refusé / annulé | Paiement `failed`, abonnement inchangé |

## 3. Auth Supabase
- Dashboard Supabase → Authentication → Providers/Policies : activer **Leaked password protection**
  (selon ton plan Supabase, l'option peut nécessiter une offre supérieure).
- Vérifier que l'URL du site et les URL de redirection autorisées sont celles de production.

## 4. Email d'accueil des prospecteurs (facultatif)
Les identifiants ne sont plus jamais envoyés par email. L'email d'accueil (sans mot de passe) est optionnel :
```bash
supabase secrets set RESEND_API_KEY=... SITE_URL=https://ton-domaine EMAIL_FROM="JDV CRM <noreply@ton-domaine>"
supabase functions deploy send-email        # la vérification JWT reste activée
```
Sans domaine vérifié chez Resend, l'expéditeur de test `onboarding@resend.dev` ne peut écrire qu'au propriétaire du compte Resend.

## 5. Build strict
Quand `npm run type-check` et `npm run lint` passent sans erreur en local, définir `STRICT_BUILD=true`
dans les variables d'environnement du déploiement : les erreurs bloqueront alors la mise en production.

## 6. Hébergement
- Utiliser `npm run build` puis `npm run serve` / `npm start` (le script `start` lance désormais `next start`).
- Les cartes sources (source maps) sont désactivées en production.
