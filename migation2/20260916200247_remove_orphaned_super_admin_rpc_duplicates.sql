-- Ces 3 fonctions faisaient toutes la même vérification (existence d'une ligne
-- active dans super_admins pour auth.uid()). Aucune n'est appelée par le code
-- applicatif actuel, aucune n'est référencée par une policy RLS ni par une
-- autre fonction. La vérification super admin passe désormais uniquement par
-- checkCurrentSuperAdmin() côté TypeScript (lib/auth/super-admin.ts), qui lit
-- directement la table super_admins via RLS.
drop function if exists public.is_current_super_admin();
drop function if exists public.is_current_user_super_admin();
drop function if exists public.verify_current_super_admin();
