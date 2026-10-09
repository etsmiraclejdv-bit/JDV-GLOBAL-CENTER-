import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { checkRateLimitShared, getClientIp } from '@/lib/middleware/rateLimiter';
import { fedapayBaseUrl, unwrapFedapay } from '@/lib/fedapay';

/**
 * POST /api/fedapay/initiate-subscription
 * Corps : { planCode }   En-tête : Authorization: Bearer <jeton de session>
 *
 * Le navigateur n'envoie que le plan choisi. Le montant, la devise et l'entreprise
 * viennent de la base de données et de la session : rien n'est modifiable côté client.
 */
export async function POST(req: NextRequest) {
  const rl = await checkRateLimitShared(`fedapay-initiate:${getClientIp(req)}`, { limit: 20, windowMs: 15 * 60 * 1000 });
  if (!rl.allowed) {
    return NextResponse.json({ error: 'Trop de requêtes. Réessayez dans quelques minutes.' }, { status: 429 });
  }

  const secretKey = process.env.FEDAPAY_SECRET_KEY;
  if (!secretKey) {
    return NextResponse.json({ error: 'FedaPay non configuré côté serveur.' }, { status: 500 });
  }

  const token = (req.headers.get('authorization') ?? '').replace(/^Bearer\s+/i, '').trim();
  if (!token) return NextResponse.json({ error: 'Authentification requise' }, { status: 401 });

  let body: { planCode?: unknown };
  try {
    body = await req.json();
  } catch {
    return NextResponse.json({ error: 'Requête invalide' }, { status: 400 });
  }
  const planCode = typeof body.planCode === 'string' ? body.planCode.trim().toUpperCase().slice(0, 40) : '';
  if (!planCode) return NextResponse.json({ error: 'Plan requis' }, { status: 400 });

  const url = process.env.NEXT_PUBLIC_SUPABASE_URL!;
  const opts = { auth: { autoRefreshToken: false, persistSession: false } };
  const supabaseUser = createClient(url, process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY!, opts);
  const { data: caller, error: callerError } = await supabaseUser.auth.getUser(token);
  if (callerError || !caller.user) return NextResponse.json({ error: 'Session invalide' }, { status: 401 });

  const admin = createClient(url, process.env.SUPABASE_SERVICE_ROLE_KEY!, opts);

  // Entreprise dont l'appelant est administrateur
  const { data: member } = await admin
    .from('organization_members')
    .select('organization_id, role, organizations(name)')
    .eq('user_id', caller.user.id)
    .eq('status', 'active')
    .in('role', ['business_admin', 'admin'])
    .order('created_at', { ascending: true })
    .limit(1)
    .maybeSingle();
  if (!member) {
    return NextResponse.json({ error: 'Seul un administrateur d’entreprise peut payer un abonnement.' }, { status: 403 });
  }
  const organizationId = (member as { organization_id: string }).organization_id;
  const organizationName =
    ((member as unknown as { organizations?: { name?: string } | null }).organizations?.name) ?? 'Entreprise';

  // Paiement en attente créé par la base (montant et plan fixés côté serveur)
  const { data: prepared, error: prepError } = await admin.rpc('jdvcrm_prepare_subscription_payment_v1', {
    p_organization_id: organizationId,
    p_plan_code: planCode,
  });
  const pay = Array.isArray(prepared) ? prepared[0] : prepared;
  if (prepError || !pay) {
    const msg = prepError?.message ?? 'Plan indisponible';
    const known: Record<string, string> = {
      PLAN_NOT_AVAILABLE: 'Ce plan n’est pas disponible.',
      PLAN_FEDAPAY_AMOUNT_NOT_CONFIGURED: 'Le montant de ce plan n’est pas encore configuré.',
    };
    return NextResponse.json({ error: known[msg] ?? msg }, { status: 400 });
  }

  const paymentId = pay.payment_id as string;
  const markFailed = async () => {
    await admin.from('subscription_payments').update({ status: 'failed' }).eq('id', paymentId).eq('status', 'pending');
  };

  const site = process.env.NEXT_PUBLIC_SITE_URL || new URL(req.url).origin;
  const baseUrl = fedapayBaseUrl(secretKey);
  const headers = { Authorization: `Bearer ${secretKey}`, 'Content-Type': 'application/json' };

  try {
    const createRes = await fetch(`${baseUrl}/transactions`, {
      method: 'POST',
      headers,
      body: JSON.stringify({
        description: `Abonnement JDV CRM — ${pay.plan_name} — ${organizationName}`.slice(0, 250),
        amount: Math.round(Number(pay.amount)),
        currency: { iso: 'XOF' },
        callback_url: `${site}/business/dashboard?payment=success`,
        merchant_reference: paymentId,
        custom_metadata: { payment_id: paymentId, organization_id: organizationId, plan_code: pay.plan_code },
        customer: caller.user.email ? { email: caller.user.email } : undefined,
      }),
    });
    const createJson = await createRes.json().catch(() => ({}));
    if (!createRes.ok) {
      await markFailed();
      const msg = (createJson as { message?: string })?.message ?? 'Erreur FedaPay';
      return NextResponse.json({ error: msg }, { status: 400 });
    }
    const tx = unwrapFedapay<{ id?: number | string }>(createJson, 'transaction');
    const transactionId = tx?.id != null ? String(tx.id) : '';
    if (!transactionId) {
      await markFailed();
      return NextResponse.json({ error: 'Identifiant de transaction FedaPay introuvable.' }, { status: 502 });
    }

    // La référence FedaPay est enregistrée tout de suite : le webhook s'appuie dessus.
    const { error: refError } = await admin
      .from('subscription_payments')
      .update({ provider_reference: transactionId })
      .eq('id', paymentId);
    if (refError) {
      await markFailed();
      return NextResponse.json({ error: 'Enregistrement du paiement impossible.' }, { status: 500 });
    }

    const tokenRes = await fetch(`${baseUrl}/transactions/${transactionId}/token`, { method: 'POST', headers });
    const tokenJson = (await tokenRes.json().catch(() => ({}))) as Record<string, unknown>;
    const paymentUrl =
      (typeof tokenJson.url === 'string' && tokenJson.url) ||
      (typeof tokenJson.token === 'string'
        ? `${secretKey.startsWith('sk_live') ? 'https://process.fedapay.com' : 'https://sandbox-process.fedapay.com'}/${tokenJson.token}`
        : '');
    if (!tokenRes.ok || !paymentUrl) {
      await markFailed();
      return NextResponse.json({ error: 'Impossible de générer le lien de paiement FedaPay.' }, { status: 502 });
    }

    return NextResponse.json({ paymentUrl, transactionId });
  } catch (err) {
    await markFailed();
    console.error('[fedapay/initiate-subscription]', err instanceof Error ? err.message : err);
    return NextResponse.json({ error: 'Erreur interne. Réessayez dans un instant.' }, { status: 500 });
  }
}
