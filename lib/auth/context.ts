import { supabase } from '@/lib/supabase/client';

/**
 * Auth context aligned with the live Supabase schema:
 * - super admins: super_admins.admin_status
 * - organization membership: organization_members.member_status + roles.code
 * - organization ownership: organizations.owner_id
 * - profile label: profiles.full_name / first_name / last_name
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

type MembershipRow = { organization_id: string; role_id: string };
type RoleRow = { code: string };
type ProspecteurRow = { id: string; organization_id: string };
type ProfileRow = { full_name?: string | null; first_name?: string | null; last_name?: string | null };
type OrganizationRow = { id: string };

export async function getAuthContext(): Promise<AuthContextData | null> {
  const { data: { user }, error: userError } = await supabase.auth.getUser();
  if (userError || !user) return null;

  const [superRes, memberRes, prospRes, profileRes, ownedRes] = await Promise.all([
    supabase.from('super_admins').select('id, admin_status').eq('user_id', user.id).maybeSingle(),
    supabase.from('organization_members')
      .select('organization_id, role_id')
      .eq('user_id', user.id)
      .eq('member_status', 'active')
      .order('joined_at', { ascending: true })
      .limit(1),
    supabase.from('prospecteurs')
      .select('id, organization_id')
      .eq('user_id', user.id)
      .eq('status', 'active')
      .limit(1),
    supabase.from('profiles')
      .select('full_name, first_name, last_name')
      .eq('id', user.id)
      .maybeSingle(),
    supabase.from('organizations')
      .select('id')
      .eq('owner_id', user.id)
      .order('created_at', { ascending: true })
      .limit(1),
  ]);

  // Do not silently turn schema/permission errors into "no organization".
  const criticalErrors = [superRes.error, memberRes.error, prospRes.error, ownedRes.error].filter(Boolean);
  if (criticalErrors.length) {
    throw new Error('Impossible de charger les droits et rattachements du compte.');
  }

  const sa = superRes.data as { admin_status?: string } | null;
  const isSuperAdmin = sa?.admin_status === 'active';
  const member = ((memberRes.data ?? []) as MembershipRow[])[0] ?? null;
  const prosp = ((prospRes.data ?? []) as ProspecteurRow[])[0] ?? null;
  const owned = ((ownedRes.data ?? []) as OrganizationRow[])[0] ?? null;
  const profile = profileRes.data as ProfileRow | null;

  let memberRole: string | null = null;
  if (member?.role_id) {
    const { data: roleData, error: roleError } = await supabase
      .from('roles')
      .select('code')
      .eq('id', member.role_id)
      .maybeSingle();
    if (roleError) throw new Error('Impossible de charger le rôle du compte.');
    memberRole = (roleData as RoleRow | null)?.code ?? null;
  }

  const displayName =
    profile?.full_name?.trim() ||
    `${profile?.first_name ?? ''} ${profile?.last_name ?? ''}`.trim() ||
    user.email ||
    'Utilisateur';

  const memberOwnsOrganization = !!member && !!owned && member.organization_id === owned.id;
  const ownerFallback = !member && !prosp && !!owned;
  const isOrgAdmin =
    (!!memberRole && ORG_ADMIN_ROLES.includes(memberRole.toLowerCase())) ||
    (memberRole?.toLowerCase() === 'owner' && memberOwnsOrganization) ||
    ownerFallback;

  return {
    userId: user.id,
    email: user.email ?? null,
    displayName,
    isSuperAdmin,
    organizationId: member?.organization_id ?? prosp?.organization_id ?? owned?.id ?? null,
    orgRole: memberRole ?? (ownerFallback ? 'business_admin' : null),
    isOrgAdmin,
    prospecteurId: prosp?.id ?? null,
    prospecteurOrganizationId: prosp?.organization_id ?? null,
  };
}

export async function getCurrentOrgId(): Promise<string | null> {
  const ctx = await getAuthContext();
  return ctx?.organizationId ?? null;
}

export function fullName(p?: { first_name?: string | null; last_name?: string | null } | null): string {
  return `${p?.first_name ?? ''} ${p?.last_name ?? ''}`.trim();
}

export async function fetchOrgProfile(): Promise<{
  data: { id: string; organization_id: string | null; role: string | null; full_name: string; prospecteur_id: string | null } | null;
  error: null;
}> {
  const ctx = await getAuthContext();
  if (!ctx) return { data: null, error: null };
  return {
    data: {
      id: ctx.userId,
      organization_id: ctx.organizationId,
      role: ctx.isSuperAdmin ? 'super_admin' : ctx.isOrgAdmin ? 'admin' : ctx.prospecteurId ? 'prospecteur' : ctx.orgRole,
      full_name: ctx.displayName,
      prospecteur_id: ctx.prospecteurId,
    },
    error: null,
  };
}
