import { NextRequest, NextResponse } from 'next/server';
import { createClient } from '@supabase/supabase-js';
import { checkRateLimitShared, getClientIp } from '@/lib/middleware/rateLimiter';
import { isFedaPayIp } from '@/lib/middleware/ipWhitelist';
import { fedapayBaseUrl, unwrapFedapay } from '@/lib/fedapay';

/**
 * POST /api/fedapay-webhook
 * Protégé par : (1) liste d'IP facultative, (2) limitation de débit,
 * (3) signature officielle FedaPay, (4) relecture de la transaction auprès de FedaPay,
 * (5) contrôles de montant et de référence dans la base.
 *
 * Aucune donnée du webhook n'est crue sur parole : l'état et le montant viennent de l'API FedaPay,
 * le paiement est retrouvé par sa référence enregistrée côté serveur.
 */
const PERMANENT_ERRORS = [
  'FEDAPAY_AMOUNT_MISMATCH',
  'PAYMENT_REFERENCE_MISMATCH',
  'PAYMENT_NOT_FOUND',
  'PAYMENT_PROVIDER_MISMATCH',
  'PAYMENT_ALREADY_CLOSED',
  'PLAN_NOT_FOUND',
  'SUBSCRIPTION_NOT_FOUND',
];

export async function POST(req: NextRequest) {
  const ip = getClientIp(req);

  if (!isFedaPayIp(ip)) {
    console.warn(`[fedapay-webhook] IP refusée : ${ip}`);
    return NextResponse.json({ error: 'Forbidden' }, { status: 403 });
  }

  const rl = await checkRateLimitShared(`fedapay-webhook:${ip}`, { limit: 120, windowMs: 60 * 1000 });
  if (!rl.allowed) return NextResponse.json({ error: 'Too many requests' }, { status: 429 });

  const webhookSecret = process.env.FEDAPAY_WEBHOOK_SECRET;
  const secretKey = process.env.FEDAPAY_SECRET_KEY;
  if (!webhookSecret || !secretKey) {
    console.error('[fedapay-webhook] FEDAPAY_WEBHOOK_SECRET ou FEDAPAY_SECRET_KEY manquant');
    return NextResponse.json({ error: 'Webhook non configuré' }, { status: 500 });
  }

  const rawBody = await req.text();
  const signature = req.headers.get('x-fedapay-signature') ?? '';

  // Signature : bibliothèque officielle FedaPay (vérifie aussi l'horodatage)
  let event: Record<string, unknown>;
  try {
    const { Webhook } = await import('fedapay');
    event = Webhook.constructEvent(rawBody, signature, webhookSecret) as Record<string, unknown>;
  } catch (err) {
    console.warn('[fedapay-webhook] signature invalide :', err instanceof Error ? err.message : err);
    return NextResponse.json({ error: 'Invalid signature' }, { status: 400 });
  }

  const eventName = String(event.name ?? '');
  if (eventName !== 'transaction.approved') {
    return NextResponse.json({ received: true, ignored: eventName });
  }

  const entity = (event.entity ?? (event.data as Record<string, unknown> | undefined)?.object ?? {}) as Record<string, unknown>;
  const transactionId = entity.id != null ? String(entity.id) : '';
  if (!transactionId) return NextResponse.json({ error: 'Transaction manquante' }, { status: 400 });

  try {
    // Relecture auprès de FedaPay : l'état et le montant réels font foi
    const txRes = await fetch(`${fedapayBaseUrl(secretKey)}/transactions/${transactionId}`, {
      headers: { Authorization: `Bearer ${secretKey}`, 'Content-Type': 'application/json' },
    });
    if (!txRes.ok) {
      console.error('[fedapay-webhook] lecture transaction impossible', txRes.status);
      return NextResponse.json({ error: 'Transaction introuvable chez FedaPay' }, { status: 502 });
    }
    const tx = unwrapFedapay<{ status?: string; amount?: number }>(await txRes.json(), 'transaction');
    if (!tx || tx.status !== 'approved') {
      return NextResponse.json({ received: true, processed: false, reason: 'not_approved' });
    }

    const admin = createClient(process.env.NEXT_PUBLIC_SUPABASE_URL!, process.env.SUPABASE_SERVICE_ROLE_KEY!, {
      auth: { autoRefreshToken: false, persistSession: false },
    });

    const { data: payment } = await admin
      .from('subscription_payments')
      .select('id')
      .eq('provider', 'fedapay')
      .eq('provider_reference', transactionId)
      .maybeSingle();
    if (!payment) {
      console.error('[fedapay-webhook] paiement inconnu pour la transaction', transactionId);
      return NextResponse.json({ received: true, processed: false, reason: 'payment_not_found' });
    }

    const { error } = await admin.rpc('jdvcrm_settle_fedapay_payment_v1', {
      p_payment_id: (payment as { id: string }).id,
      p_transaction_id: transactionId,
      p_amount: Number(tx.amount),
      p_currency: 'XOF',
      p_event_id: event.id != null ? String(event.id) : `${eventName}:${transactionId}`,
      p_event_type: eventName,
      p_payload: event,
    });

    if (error) {
      console.error('[fedapay-webhook] règlement refusé :', error.message);
      // Erreur définitive : inutile de faire réessayer FedaPay (l'événement est tracé en base).
      if (PERMANENT_ERRORS.some((code) => error.message.includes(code))) {
        return NextResponse.json({ received: true, processed: false, reason: error.message });
      }
      return NextResponse.json({ error: 'Traitement impossible' }, { status: 500 });
    }

    return NextResponse.json({ received: true, processed: true });
  } catch (err) {
    console.error('[fedapay-webhook]', err instanceof Error ? err.message : err);
    return NextResponse.json({ error: 'Erreur interne' }, { status: 500 });
  }
}
