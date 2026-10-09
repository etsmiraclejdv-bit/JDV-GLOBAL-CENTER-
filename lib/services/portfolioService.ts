import { supabase } from '@/lib/supabase/client';

/**
 * Portefeuille clients de l'utilisateur connecté (créé automatiquement s'il n'existe pas).
 * Chaque prospecteur ne voit que les clients et prospects de son propre portefeuille.
 */
export async function getMyPortfolioId(organizationId: string): Promise<{ id: string | null; error: string | null }> {
  const { data, error } = await supabase.rpc('jdvcrm_ensure_my_portfolio_v1', { p_organization_id: organizationId });
  if (error || !data) return { id: null, error: error?.message ?? 'Portefeuille introuvable' };
  return { id: data as string, error: null };
}

/** Convertit un prospect en client (la fiche client garde le même portefeuille). */
export async function convertProspectToClient(prospectId: string): Promise<{ clientId: string | null; error: string | null }> {
  const { data, error } = await supabase.rpc('jdvcrm_convert_prospect_to_client_v1', { p_prospect_id: prospectId });
  if (error) return { clientId: null, error: error.message };
  return { clientId: data as string, error: null };
}
