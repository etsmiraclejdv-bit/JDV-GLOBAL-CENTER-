import { supabase } from '@/lib/supabase/client';

/**
 * Contexte d'authentification aligné sur le schéma réel de la base :
 *  - concepteur (super admin) : table `super_admins`
 *  - rattachement à l'entreprise et rôle : table `organization_members`
 *  - prospecteur terrain : table `prospecteurs`
 *  - repli : entreprise dont l'utilisateur est propriétaire (`organizations.owner_user_id`)
 */
export interface AuthContextData {
  userId: string;
  email: string | null;
  displayName: string;
  isSuperAdmin: boolean;
  organizationId: string | null;
  orgRole: string | null;
  isOrgAdmin: boolean;
  prospecteurId: string | null;
  prospecteurOrganizationId: string | null;
}
const ORG_ADMIN_ROLES = ['business_admin', 'admin'];

export async function getAuthContext(): Promise<AuthContextData | null> {
  const { data: { user }, error } = await supabase.auth.getUser();
  if (error || !user) return null;

  const [superRes, memberRes, prospRes, profileRes, ownedRes] = await Promise.all([
    supabase.from('super_admins').select('id, status, actif').eq('user_id', user.id).maybeSingle(),
    supabase.from('organization_members').select('organization_id, role').eq('user_id', user.id).eq('status', 'active').order('created_at', { ascending: true }).limit(1),
    supabase.from('prospecteurs').select('id, organization_id').eq('user_id', user.id).eq('status', 'active').limit(1),
    supabase.from('profiles').select('display_name, first_name, last_name').eq('id', user.id).maybeSingle(),
    supabase.from('organizations').select('id').eq('owner_user_id', user.id).order('created_at', { ascending: true }).limit(1),
  ]);

  const sa = superRes.data as { status?: string; actif?: boolean | null } | null;
  const isSuperAdmin = !!sa && sa.status === 'active' && sa.actif !== false;
  const member = ((memberRes.data ?? []) as { organization_id: string; role: string }[])[0] ?? null;
  const prosp = ((prospRes.data ?? []) as { id: string; organization_id: string }[])[0] ?? null;
  const owned = ((ownedRes.data ?? []) as { id: string }[])[0] ?? null;
  const profile = profileRes.data as { display_name?: string | null; first_name?: string | null; last_name?: string | null } | null;
  const displayName = profile?.display_name?.trim() || `${profile?.first_name ?? ''} ${profile?.last_name ?? ''}`.trim() || user.email || 'Utilisateur';
  const ownerFallback = !member && !prosp && !!owned;

  return {
    userId:user.id, email:user.email??null, displayName, isSuperAdmin,
    organizationId:member?.organization_id ?? prosp?.organization_id ?? owned?.id ?? null,
    orgRole:member?.role ?? (ownerFallback?'business_admin':null),
    isOrgAdmin:(!!member && ORG_ADMIN_ROLES.includes(member.role.toLowerCase())) || ownerFallback,
    prospecteurId:prosp?.id ?? null,
    prospecteurOrganizationId:prosp?.organization_id ?? null,
  };
}
export async function getCurrentOrgId(): Promise<string | null> { const ctx=await getAuthContext(); return ctx?.organizationId??null; }
export function fullName(p?: {first_name?:string|null;last_name?:string|null}|null): string { return `${p?.first_name??''} ${p?.last_name??''}`.trim(); }
export async function fetchOrgProfile(): Promise<{data:{id:string;organization_id:string|null;role:string|null;full_name:string;prospecteur_id:string|null}|null;error:null}> {
  const ctx=await getAuthContext();
  if(!ctx) return {data:null,error:null};
  return {data:{id:ctx.userId,organization_id:ctx.organizationId,role:ctx.isSuperAdmin?'super_admin':ctx.isOrgAdmin?'admin':ctx.prospecteurId?'prospecteur':ctx.orgRole,full_name:ctx.displayName,prospecteur_id:ctx.prospecteurId},error:null};
}