-- jdvcrm_generate_sale_schedules_v42 n'a aucun contrôle d'accès interne et n'est appelée que par
-- jdvcrm_process_sale_v42 (SECURITY DEFINER, non exécutable par les utilisateurs).
-- On retire donc l'exécution directe aux utilisateurs pour empêcher la génération d'échéanciers
-- sur la vente d'une autre entreprise.
-- NOTE: déjà appliquée sur Supabase (version 20261005181627).
revoke all on function public.jdvcrm_generate_sale_schedules_v42(uuid) from public, anon, authenticated;
grant execute on function public.jdvcrm_generate_sale_schedules_v42(uuid) to service_role;