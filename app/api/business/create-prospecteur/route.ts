import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { checkRateLimitShared, getClientIp } from '@/lib/middleware/rateLimiter';
import { sanitizeString, sanitizeEmail, sanitizeUUID, sanitizeNumber } from '@/lib/security/sanitize';

export async function POST(req: NextRequest) {
  try {
    // ── Rate limiting: 10 requests per 15 minutes per IP ────────────────────
    const ip = getClientIp(req);
    const rl = await checkRateLimitShared(`create-prospecteur:${ip}`, { limit: 10, windowMs: 15 * 60 * 1000 });
    if (!rl.allowed) {
      return NextResponse.json(
        { error: 'Trop de requêtes. Veuillez réessayer dans quelques minutes.' },
        {
          status: 429,
          headers: {
            'Retry-After': String(Math.ceil((rl.resetAt - Date.now()) / 1000)),
            'X-RateLimit-Remaining': '0',
          },
        }
      );
    }
    const body = await req.json();

    // ── Input sanitization ─────────────────────────────────────────────────
    const firstName = sanitizeString(body.firstName);
    const lastName = sanitizeString(body.lastName);
    const email = sanitizeEmail(body.email);
    const password = typeof body.password === 'string' ? body.password.trim().slice(0, 128) : '';
    const phone = sanitizeString(body.phone);
    const organizationId = sanitizeUUID(body.organizationId);
    const commissionRate = sanitizeNumber(body.commissionRate, 0, 100);
    const warehouseId = body.warehouseId ? sanitizeUUID(body.warehouseId) : null;
    const department = sanitizeString(body.department);
    const workCity = sanitizeString(body.workCity);
    const workZone = sanitizeString(body.workZone);

    if (!email || !password || !organizationId) {
      return NextResponse.json({ error: 'email, password et organizationId sont requis' }, { status: 400 });
    }

    if (password.length < 8) {
      return NextResponse.json({ error: 'Le mot de passe doit contenir au moins 8 caractères' }, { status: 400 });
    }
    if (!firstName) {
      return NextResponse.json({ error: 'Le prénom est requis' }, { status: 400 });
    }

    // ── Identité de l'appelant : jeton de session obligatoire ────────────────
    const token = (req.headers.get('authorization') ?? '').replace(/^Bearer\s+/i, '').trim();
    if (!token) {
      return NextResponse.json({ error: 'Authentification requise' }, { status: 401 });
    }

    const supabaseUrl0 = process.env.NEXT_PUBLIC_SUPABASE_URL;
    const supabaseAnonKey = process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY;
    const supabaseAdminKey = process.env.SUPABASE_SECRET_KEY || process.env.SUPABASE_SERVICE_ROLE_KEY;

    if (!supabaseUrl0 || !supabaseAnonKey || !supabaseAdminKey) {
      console.error('[create-prospecteur] configuration Supabase serveur incomplète', {
        hasUrl: Boolean(supabaseUrl0),
        hasAnonKey: Boolean(supabaseAnonKey),
        hasAdminKey: Boolean(supabaseAdminKey),
      });
      return NextResponse.json(
        { error: 'Configuration serveur Supabase incomplète. Contactez l’administrateur.' },
        { status: 500 }
      );
    }

    // Client « au nom de l'utilisateur » : les règles de sécurité de la base s'appliquent.
    const supabaseUser = createClient(supabaseUrl0, supabaseAnonKey, {
      global: { headers: { Authorization: `Bearer ${token}` } },
      auth: { autoRefreshToken: false, persistSession: false },
    });
    const { data: caller, error: callerError } = await supabaseUser.auth.getUser(token);
    if (callerError || !caller.user) {
      return NextResponse.json({ error: 'Session invalide' }, { status: 401 });
    }

    // Use service role key — never exposed to browser
    const supabaseAdmin = createClient(supabaseUrl0, supabaseAdminKey, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    // Autorisation concepteur : utiliser la même RPC SECURITY DEFINER que
    // le portail concepteur. Ainsi le compte concepteur unique reste reconnu
    // même si une lecture directe de super_admins côté API/session diverge.
    const { data: workspaceBranches, error: workspaceError } = await supabaseUser.rpc(
      'jdvcrm_get_concepteur_workspace_v1'
    );
    const isSuperFromWorkspace =
      !workspaceError &&
      Array.isArray(workspaceBranches) &&
      workspaceBranches.some((row: { branch_code?: string }) => row?.branch_code === 'concepteur');

    // Vérification serveur du Super Admin en premier.
    // Un concepteur autorisé ne doit pas être bloqué par une lecture secondaire
    // de organization_members/organizations.
    const { data: saRows, error: saError } = await supabaseAdmin
      .from('super_admins')
      .select('id, status, actif')
      .eq('user_id', caller.user.id)
      .order('id', { ascending: true })
      .limit(1);

    if (saError) {
      console.error('[create-prospecteur] erreur vérification super admin', {
        saError: saError.message,
        workspaceError: workspaceError?.message,
        callerUserId: caller.user.id,
      });
      return NextResponse.json(
        { error: 'Vérification des droits temporairement indisponible. Veuillez réessayer.' },
        { status: 500 }
      );
    }

    const sa = (saRows ?? [])[0] as { status?: string; actif?: boolean | null } | undefined;
    const isSuperFromTable =
      !!sa &&
      sa.status === 'active' &&
      sa.actif !== false;
    const isSuper = isSuperFromWorkspace || isSuperFromTable;

    let member: { role?: string } | null = null;
    let organization: { id?: string; owner_user_id?: string | null; status?: string | null } | null = null;

    // Si ce n'est pas le concepteur, on vérifie alors l'appartenance/admin de l'entreprise.
    if (!isSuper) {
      const [{ data: memberRow, error: memberError }, { data: organizationRow, error: organizationError }] = await Promise.all([
        supabaseAdmin
          .from('organization_members')
          .select('role')
          .eq('organization_id', organizationId)
          .eq('user_id', caller.user.id)
          .eq('status', 'active')
          .order('created_at', { ascending: true })
          .limit(1)
          .maybeSingle(),
        supabaseAdmin
          .from('organizations')
          .select('id, owner_user_id, status')
          .eq('id', organizationId)
          .maybeSingle(),
      ]);

      if (memberError || organizationError) {
        console.error('[create-prospecteur] erreur vérification entreprise', {
          memberError: memberError?.message,
          organizationError: organizationError?.message,
          workspaceError: workspaceError?.message,
          callerUserId: caller.user.id,
          organizationId,
        });
        return NextResponse.json(
          { error: 'Vérification des droits temporairement indisponible. Veuillez réessayer.' },
          { status: 500 }
        );
      }

      member = memberRow as { role?: string } | null;
      organization = organizationRow as { id?: string; owner_user_id?: string | null; status?: string | null } | null;
    }

    const memberRole = String(member?.role ?? '').toLowerCase();
    const isAdmin = ['business_admin', 'admin'].includes(memberRole);

    const isOwner =
      !!organization &&
      organization.owner_user_id === caller.user.id &&
      organization.status !== 'suspended';

    if (!isSuper && !isAdmin && !isOwner) {
      return NextResponse.json({ error: 'Accès refusé pour cette entreprise' }, { status: 403 });
    }

    // Les concepteurs/Super Admins disposent de leur espace interne sans abonnement.
    // Pour les entreprises classiques, la limite du plan reste contrôlée par la base.
    if (!isSuper) {
      const { data: limit, error: limitError } = await supabaseUser.rpc('jdvcrm_check_subscription_limit_v1', {
        p_organization_id: organizationId,
        p_resource_code: 'prospecteurs',
      });
      if (limitError) {
        return NextResponse.json({ error: limitError.message }, { status: 400 });
      }
      const limitRow = Array.isArray(limit) ? limit[0] : limit;
      if (limitRow && limitRow.allowed === false) {
        return NextResponse.json(
          { error: 'Limite de prospecteurs atteinte pour votre abonnement. Passez à un plan supérieur.' },
          { status: 403 }
        );
      }
    }

    // 1. Compte d'authentification (le profil est créé automatiquement par la base)
    const { data: authData, error: createError } = await supabaseAdmin.auth.admin.createUser({
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
    if (createError) return NextResponse.json({ error: createError.message }, { status: 400 });
    const userId = authData.user.id;

    const rollback = async (message: string) => {
      await supabaseAdmin.from('organization_members').delete().eq('user_id', userId).eq('organization_id', organizationId);
      await supabaseAdmin.from('prospecteurs').delete().eq('user_id', userId).eq('organization_id', organizationId);
      await supabaseAdmin.auth.admin.deleteUser(userId);
      return NextResponse.json({ error: message }, { status: 400 });
    };

    // 2. Rattachement à l'entreprise (nécessaire pour passer le contrôle d'abonnement)
    const { error: createMemberError } = await supabaseAdmin.from('organization_members').insert({
      organization_id: organizationId,
      user_id: userId,
      role: 'prospecteur',
      status: 'active',
    });
    if (createMemberError) return rollback(createMemberError.message);

    // 3. Fiche prospecteur (le code est généré par la base)
    const { data: prosp, error: prospError } = await supabaseAdmin
      .from('prospecteurs')
      .insert({
        organization_id: organizationId,
        user_id: userId,
        first_name: firstName,
        last_name: lastName || null,
        email,
        phone: phone || null,
        commission_rate: commissionRate,
        status: 'active',
      })
      .select('id, code')
      .single();
    if (prospError || !prosp) return rollback(prospError?.message ?? 'Création du prospecteur impossible');

    // 4. Portefeuille clients privé du prospecteur
    await supabaseAdmin.from('client_portfolios').insert({
      organization_id: organizationId,
      owner_user_id: userId,
      owner_type: 'prospecteur',
      name: 'Mon portefeuille clients',
    });
    if (warehouseId) {
      const { data: warehouse } = await supabaseAdmin.from('warehouses').select('id').eq('id', warehouseId).eq('organization_id', organizationId).eq('active', true).maybeSingle();
      if (!warehouse) return rollback('Entrepôt sélectionné introuvable ou inactif');
      const { error: assignmentError } = await supabaseAdmin.from('prospecteur_warehouse_assignments').insert({ organization_id: organizationId, prospecteur_id: (prosp as { id: string }).id, warehouse_id: warehouseId, department: department || null, city: workCity || null, work_zone: workZone || null, is_primary: true, active: true });
      if (assignmentError) return rollback(assignmentError.message);
    }

    const code = (prosp as { code: string }).code;

    // 5. Email d'accueil SANS mot de passe (non bloquant). La fonction vérifie elle-même que l'appelant
    //    est administrateur de l'entreprise et que le destinataire est bien l'un de ses prospecteurs.
    //    Le mot de passe est communiqué à la main par l'administrateur, jamais par email.
    fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/send-email`, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${token}`,
        apikey: process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!,
      },
      body: JSON.stringify({ type: 'prospecteur_welcome', to: email }),
    }).catch(err => console.error('[create-prospecteur] email accueil :', err instanceof Error ? err.message : err));

    return NextResponse.json({
      success: true,
      userId,
      prospecteurId: (prosp as { id: string }).id,
      code,
    });
  } catch (err) {
    console.error('[create-prospecteur]', err instanceof Error ? err.message : err);
    return NextResponse.json({ error: 'Erreur interne' }, { status: 500 });
  }
}
