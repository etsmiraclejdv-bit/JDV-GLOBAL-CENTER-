/**
 * Logique pure du suivi des paiements côté concepteur (aucune dépendance : testable isolément).
 */

const num = (v: unknown): number => {
  const n = typeof v === 'number' ? v : Number(v);
  return Number.isFinite(n) ? n : 0;
};

export const PAYMENT_STATUS_LABELS: Record<string, string> = {
  pending: 'En attente',
  successful: 'Réussi',
  failed: 'Échoué',
  refunded: 'Remboursé',
  cancelled: 'Annulé',
};

export const WEBHOOK_STATUS_LABELS: Record<string, string> = {
  received: 'Reçu',
  processed: 'Traité',
  ignored: 'Ignoré',
  failed: 'Échec',
};

export const EVENT_TYPE_LABELS: Record<string, string> = {
  'transaction.approved': 'Paiement approuvé',
  'transaction.declined': 'Paiement refusé',
  'transaction.canceled': 'Paiement annulé',
  'transaction.cancelled': 'Paiement annulé',
  'transaction.pending': 'Paiement en attente',
  'transaction.created': 'Transaction créée',
  'transaction.transferred': 'Fonds transférés',
};

export function paymentStatusLabel(status: string): string {
  return PAYMENT_STATUS_LABELS[status] ?? status;
}
export function webhookStatusLabel(status: string): string {
  return WEBHOOK_STATUS_LABELS[status] ?? status;
}
export function eventTypeLabel(type: string | null | undefined): string {
  return type ? (EVENT_TYPE_LABELS[type] ?? type) : '—';
}

export interface PaymentRow {
  status: string;
  amount: number | string;
  currency: string | null;
}

export interface PaymentSummary {
  total: number;
  successful: number;
  pending: number;
  failed: number;
  /** Somme des paiements réussis, en XOF uniquement (les autres devises ne sont pas additionnées). */
  successfulAmountXof: number;
  otherCurrencies: boolean;
}

export function summarizePayments(rows: PaymentRow[]): PaymentSummary {
  const s: PaymentSummary = { total: rows.length, successful: 0, pending: 0, failed: 0, successfulAmountXof: 0, otherCurrencies: false };
  for (const r of rows) {
    if (r.status === 'successful') {
      s.successful += 1;
      if ((r.currency ?? 'XOF').toUpperCase() === 'XOF') s.successfulAmountXof += num(r.amount);
      else s.otherCurrencies = true;
    } else if (r.status === 'pending') s.pending += 1;
    else if (r.status === 'failed') s.failed += 1;
  }
  return s;
}

export interface WebhookRow {
  status: string;
  created_at: string;
}

export interface WebhookSummary {
  total: number;
  processed: number;
  ignored: number;
  failed: number;
  lastReceivedAt: string | null;
}

export function summarizeWebhooks(rows: WebhookRow[]): WebhookSummary {
  const s: WebhookSummary = { total: rows.length, processed: 0, ignored: 0, failed: 0, lastReceivedAt: null };
  for (const r of rows) {
    if (r.status === 'processed') s.processed += 1;
    else if (r.status === 'ignored') s.ignored += 1;
    else if (r.status === 'failed') s.failed += 1;
    if (!s.lastReceivedAt || r.created_at > s.lastReceivedAt) s.lastReceivedAt = r.created_at;
  }
  return s;
}

export type WebhookHealth = 'none' | 'errors' | 'ok';

/** Diagnostic simple, utile pendant la mise en service de FedaPay. */
export function webhookHealth(s: WebhookSummary): { state: WebhookHealth; message: string } {
  if (s.total === 0) {
    return {
      state: 'none',
      message:
        "Aucun webhook reçu pour l'instant. Si vous venez de configurer FedaPay, vérifiez l'adresse du webhook et le secret dans FedaPay, puis faites un paiement de test.",
    };
  }
  if (s.failed > 0) {
    return { state: 'errors', message: `${s.failed} webhook(s) en échec : ouvrez la liste ci-dessous pour lire le message d'erreur.` };
  }
  return { state: 'ok', message: 'Les webhooks reçus ont tous été traités ou ignorés volontairement.' };
}

/** Raccourcit un identifiant externe pour l'affichage. */
export function shortId(value: string | null | undefined, keep = 10): string {
  const v = (value ?? '').trim();
  if (!v) return '—';
  return v.length <= keep + 1 ? v : `${v.slice(0, keep)}…`;
}

export function formatMoney(amount: unknown, currency: string | null | undefined): string {
  const code = (currency ?? 'XOF').toUpperCase();
  const n = num(amount);
  if (code === 'XOF') return `${new Intl.NumberFormat('fr-FR').format(Math.round(n))} XOF`;
  return `${new Intl.NumberFormat('fr-FR', { maximumFractionDigits: 2 }).format(n)} ${code}`;
}

/** « 03/10/2026 14:05 » ; fuseau du navigateur par défaut. */
export function formatDateTimeFr(iso: string | null | undefined, timeZone?: string): string {
  if (!iso) return '—';
  const d = new Date(iso);
  if (Number.isNaN(d.getTime())) return '—';
  return new Intl.DateTimeFormat('fr-FR', { dateStyle: 'short', timeStyle: 'short', timeZone }).format(d).replace(',', '');
}
