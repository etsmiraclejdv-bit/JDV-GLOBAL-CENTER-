import { supabase } from '@/lib/supabase/client';

export type SuperAdminAuthResult =
  | { ok: true; userId: string }
  | { ok: false; reason: string; message: string };

export async function checkCurrentSuperAdmin(): Promise<SuperAdminAuthResult> {
  try {
    const { data: { user }, error: userError } = await supabase.auth.getUser();
    if (userError || !user) {
      return { ok: false, reason: 'not_authenticated', message: "Vous n'êtes pas connecté." };
    }

    // Autorisation vérifiée côté base via SECURITY DEFINER/RLS-aware RPC.
    // Cela évite de dépendre d'un SELECT direct sur super_admins côté navigateur.
    const { data, error } = await supabase.rpc('jdvcrm_get_concepteur_workspace_v1');

    if (error) {
      const message = error.message || '';
      if (/AUTHENTICATION_REQUIRED|JWT|not authenticated/i.test(message)) {
        return { ok: false, reason: 'not_authenticated', message: "Votre session n'est pas active." };
      }
      if (/CONCEPTEUR_ONLY|permission|not authorized|forbidden/i.test(message)) {
        return { ok: false, reason: 'unauthorized', message: 'Compte non autorisé pour ce portail.' };
      }
      return { ok: false, reason: 'error', message: 'Erreur lors de la vérification des droits.' };
    }

    const branches = Array.isArray(data) ? data : [];
    const hasConcepteurBranch = branches.some(
      (row: { branch_code?: string }) => row?.branch_code === 'concepteur'
    );

    if (!hasConcepteurBranch) {
      return { ok: false, reason: 'unauthorized', message: 'Compte non autorisé pour ce portail.' };
    }

    return { ok: true, userId: user.id };
  } catch {
    return { ok: false, reason: 'error', message: 'Erreur lors de la vérification.' };
  }
}
