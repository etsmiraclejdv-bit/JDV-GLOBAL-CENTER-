import { getAuthContext } from '@/lib/auth/context';

export type AuthResult =
  | { ok: true; userId: string; organizationId: string; role: string }
  | { ok: false; reason: string; message: string };

export async function checkCurrentBusinessAdmin(): Promise<AuthResult> {
  try {
    const ctx = await getAuthContext();
    if (!ctx) {
      return { ok: false, reason: 'not_authenticated', message: "Vous n'êtes pas connecté." };
    }
    if (!ctx.organizationId || !ctx.orgRole) {
      return { ok: false, reason: 'no_organization', message: 'Aucune organisation associée à ce compte.' };
    }
    if (!ctx.isOrgAdmin) {
      return { ok: false, reason: 'unauthorized', message: 'Accès non autorisé pour ce rôle.' };
    }
    return { ok: true, userId: ctx.userId, organizationId: ctx.organizationId, role: ctx.orgRole };
  } catch {
    return { ok: false, reason: 'error', message: 'Erreur lors de la vérification des droits.' };
  }
}
