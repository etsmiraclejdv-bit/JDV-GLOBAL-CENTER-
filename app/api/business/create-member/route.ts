import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { checkRateLimitShared, getClientIp } from '@/lib/middleware/rateLimiter';
import { sanitizeString, sanitizeEmail, sanitizeUUID } from '@/lib/security/sanitize';

export const dynamic = 'force-dynamic';

// Aligné sur le schéma JDV Global Center : roles.code, organization_members.role_id/member_status,
// organizations.owner_id et super_admins.admin_status. Aucun changement de schéma n'est requis.
const ROLE_MAP: Record<string, string> = {
  business_admin: 'admin',
  manager: 'manager',
  supervisor: 'staff',
  accountant: 'accountant',
  commercial: 'agent',
  viewer: 'viewer',
};

export async function POST(req: NextRequest) {
  try {
    const ip = getClientIp(req);
    const rate = await checkRateLimitShared(`create-member:${ip}`, { limit: 10, windowMs: 15 * 60 * 1000 });
    if (!rate.allowed) return NextResponse.json({ error: 'Trop de requêtes. Réessayez dans quelques minutes.' }, { status: 429 });

    const body = await req.json();
    const organizationId = sanitizeUUID(body.organizationId);
    const email = sanitizeEmail(body.email);
    const password = typeof body.password === 'string' ? body.password.trim().slice(0, 128) : '';
    const firstName = sanitizeString(body.firstName);
    const lastName = sanitizeString(body.lastName);
    const phone = sanitizeString(body.phone);
    const requestedRole = String(body.role ?? '');
    const roleCode = ROLE_MAP[requestedRole];

    if (!organizationId || !email || !password) return NextResponse.json({ error: 'E-mail, mot de passe et entreprise sont requis.' }, { status: 400 });
    if (password.length < 8) return NextResponse.json({ error: 'Le mot de passe doit contenir au moins 8 caractères.' }, { status: 400 });
    if (!firstName) return NextResponse.json({ error: 'Le prénom est requis.' }, { status: 400 });
    if (!roleCode) return NextResponse.json({ error: 'Rôle invalide.' }, { status: 400 });

    const token = (req.headers.get('authorization') ?? '').replace(/^Bearer\\s+/i, '').trim();
    if (!token) return NextResponse.json({ error: 'Authentification requise.' }, { status: 401 });

    const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const anon = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    const serviceKey = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;
    if (!url || !anon || !serviceKey) {
      console.error('[create-member] Configuration Supabase serveur incomplète.');
      return NextResponse.json({ error: 'Configuration serveur incomplète. Contactez l’administrateur.' }, { status: 500 });
    }

    const userClient = createClient(url, anon, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: authData, error: authError } = await userClient.auth.getUser(token);
    if (authError || !authData.user) return NextResponse.json({ error: 'Session invalide. Reconnectez-vous.' }, { status: 401 });

    const admin = createClient(url, serviceKey, { auth: { autoRefreshToken: false, persistSession: false } });
    const callerId = authData.user.id;

    const [superRes, memberRes, orgRes, roleRes] = await Promise.all([
      admin.from('super_admins').select('admin_status').eq('user_id', callerId).maybeSingle(),
      admin.from('organization_members').select('role_id, member_status').eq('organization_id', organizationId).eq('user_id', callerId).eq('member_status', 'active').maybeSingle(),
      admin.from('organizations').select('id, owner_id, status').eq('id', organizationId).maybeSingle(),
      admin.from('roles').select('id, code').eq('code', roleCode).maybeSingle(),
    ]);
    if (superRes.error || memberRes.error || orgRes.error || roleRes.error) {
      console.error('[create-member] Schema/authorization lookup failed.');
      return NextResponse.json({ error: 'Impossible de vérifier les autorisations ou le rôle. Vérifiez la configuration Supabase.' }, { status: 500 });
    }

    const isSuperAdmin = superRes.data?.admin_status === 'active';
    const org = orgRes.data as { id: string; owner_id: string | null; status?: string | null } | null;
    const membership = memberRes.data as { role_id: string; member_status: string } | null;
    const callerRoleId = membership?.role_id;
    let callerRoleCode: string | null = null;
    if (callerRoleId) {
      const { data: callerRole, error } = await admin.from('roles').select('code').eq('id', callerRoleId).maybeSingle();
      if (error) return NextResponse.json({ error: 'Impossible de vérifier le rôle du compte.' }, { status: 500 });
      callerRoleCode = callerRole?.code ?? null;
    }
    const isOrgAdmin = callerRoleCode === 'admin' || callerRoleCode === 'business_admin';
    const isOwner = org?.owner_id === callerId && org?.status !== 'suspended';
    if (!org) return NextResponse.json({ error: 'Entreprise introuvable.' }, { status: 404 });
    if (!isSuperAdmin && !isOrgAdmin && !isOwner) return NextResponse.json({ error: 'Action réservée aux administrateurs.' }, { status: 403 });
    if (!roleRes.data?.id) return NextResponse.json({ error: `Le rôle requis (${roleCode}) n’existe pas dans la table roles.` }, { status: 409 });

    if (requestedRole === 'business_admin' && !isSuperAdmin) {
      const { data: limit, error } = await userClient.rpc('jdvcrm_check_subscription_limit_v1', {
        p_organization_id: organizationId,
        p_resource_code: 'admins',
      });
      if (error) return NextResponse.json({ error: error.message }, { status: 400 });
      const row = Array.isArray(limit) ? limit[0] : limit;
      if (row && row.allowed === false) return NextResponse.json({ error: 'Le nombre maximal d’administrateurs de votre abonnement est atteint.' }, { status: 403 });
    }

    const { data: created, error: createError } = await admin.auth.admin.createUser({
      email,
      password,
      email_confirm: true,
      user_metadata: {
        first_name: firstName,
        last_name: lastName || null,
        display_name: `${firstName} ${lastName}`.trim(),
        phone: phone || null,
      },
    });
    if (createError || !created.user) return NextResponse.json({ error: createError?.message ?? 'Création du compte impossible.' }, { status: 400 });

    const { error: insertError } = await admin.from('organization_members').insert({
      organization_id: organizationId,
      user_id: created.user.id,
      role_id: roleRes.data.id,
      member_status: 'active',
    });
    if (insertError) {
      await admin.auth.admin.deleteUser(created.user.id);
      console.error('[create-member] Membership insert failed:', insertError.message);
      return NextResponse.json({ error: 'Le compte n’a pas été rattaché à l’entreprise. Aucun membre n’a été créé.' }, { status: 400 });
    }

    return NextResponse.json({ success: true, userId: created.user.id });
  } catch (err) {
    console.error('[create-member]', err instanceof Error ? err.message : 'Unknown error');
    return NextResponse.json({ error: 'Erreur interne lors de la création du membre.' }, { status: 500 });
  }
}
