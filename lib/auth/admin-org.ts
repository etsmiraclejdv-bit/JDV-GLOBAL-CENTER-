import { getAuthContext } from '@/lib/auth/context';

/** Entreprise de l'utilisateur connecté, à condition qu'il en soit administrateur. */
export async function getAdminOrganization(): Promise<{ orgId: string | null; error: string | null }> {
  const ctx = await getAuthContext();
  if (!ctx) return { orgId: null, error: "Vous n'êtes pas connecté." };
  if (!ctx.organizationId || !ctx.isOrgAdmin) {
    return { orgId: null, error: "Cette page est réservée à l'administrateur de l'entreprise." };
  }
  return { orgId: ctx.organizationId, error: null };
}
