import { getAuthContext } from '@/lib/auth/context';

export type ProspecteurAuthResult =
  | { ok: true; userId: string; prospecteurId: string; organizationId: string }
  | { ok: false; reason: string; message: string };

export async function checkCurrentProspecteur(): Promise<ProspecteurAuthResult> {
  try {
    const ctx = await getAuthContext();
    if (!ctx) {
      return { ok: false, reason: 'not_authenticated', message: "Vous n'êtes pas connecté." };
    }
    if (!ctx.prospecteurId) {
      return { ok: false, reason: 'unauthorized', message: 'Accès réservé aux prospecteurs.' };
    }
    if (!ctx.prospecteurOrganizationId) {
      return { ok: false, reason: 'no_organization', message: 'Aucune organisation associée.' };
    }
    return {
      ok: true,
      userId: ctx.userId,
      prospecteurId: ctx.prospecteurId,
      organizationId: ctx.prospecteurOrganizationId,
    };
  } catch {
    return { ok: false, reason: 'error', message: 'Erreur lors de la vérification des droits.' };
  }
}
