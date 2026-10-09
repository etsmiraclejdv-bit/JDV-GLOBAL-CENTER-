# JDV GLOBAL CENTER

JDV GLOBAL CENTER est le point d’entrée principal de l’écosystème Joie de Vivre. Les branches spécialisées conservent leurs espaces et fonctions propres ; elles ne remplacent pas l’accueil central.

## Branches

- **JDV CRM** — branche indépendante accessible depuis la route `/crm`. Elle conserve son expérience CRM dédiée.
- **JDV PAY**, **JDV BUSINESS**, **JDV ACADEMY** — secteurs prévus, à développer séparément. Ils ne sont pas présentés comme opérationnels tant que leurs modules ne sont pas construits.

## Développement

Application Next.js 15, React 19, TypeScript et Tailwind CSS. Le serveur de développement utilise le port 4028.

```bash
npm install
npm run dev
```

## Règle d’architecture

La page racine `/` appartient à JDV GLOBAL CENTER. La page commerciale JDV CRM se trouve à `/crm`. Les routes métier existantes du CRM, ses composants et les migrations Supabase sont conservés. Les données et règles de sécurité Supabase ne sont pas modifiées par cette séparation de navigation.
