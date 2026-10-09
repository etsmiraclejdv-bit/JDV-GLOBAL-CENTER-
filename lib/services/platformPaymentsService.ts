import { supabase } from '@/lib/supabase/client';

export interface PlatformPayment {
  id: string;
  organization_id: string | null;
  amount: number | string;
  currency: string | null;
  provider: string | null;
  provider_reference: string | null;
  payment_method: string | null;
  status: string;
  paid_at: string | null;
  created_at: string;
}

/** Le contenu brut (`payload`) n'est volontairement jamais lu : il contient des données personnelles de clients. */
export interface PlatformWebhook {
  id: string;
  provider: string | null;
  organization_id: string | null;
  external_event_id: string | null;
  event_type: string | null;
  status: string;
  processed_at: string | null;
  error_message: string | null;
  created_at: string;
}

export interface PaymentsOverview {
  payments: PlatformPayment[];
  webhooks: PlatformWebhook[];
  orgNames: Record<string, string>;
}

/**
 * Vue d'ensemble réservée au concepteur (les règles d'accès de la base refusent tout autre utilisateur).
 * `subscription_events` est volontairement absente : cette table n'est lisible que par le serveur (service_role).
 */
export async function fetchPaymentsOverview(): Promise<{ data: PaymentsOverview; error: string | null }> {
  const [p, w, o] = await Promise.all([
    supabase
      .from('subscription_payments')
      .select('id, organization_id, amount, currency, provider, provider_reference, payment_method, status, paid_at, created_at')
      .order('created_at', { ascending: false })
      .limit(100),
    supabase
      .from('payment_webhook_events')
      .select('id, provider, organization_id, external_event_id, event_type, status, processed_at, error_message, created_at')
      .order('created_at', { ascending: false })
      .limit(100),
    supabase.from('organizations').select('id, name'),
  ]);
  const error = p.error?.message || w.error?.message || o.error?.message || null;
  const orgNames: Record<string, string> = {};
  for (const org of (o.data ?? []) as { id: string; name: string | null }[]) orgNames[org.id] = org.name ?? 'Entreprise';
  return {
    data: {
      payments: (p.data ?? []) as PlatformPayment[],
      webhooks: (w.data ?? []) as PlatformWebhook[],
      orgNames,
    },
    error,
  };
}
