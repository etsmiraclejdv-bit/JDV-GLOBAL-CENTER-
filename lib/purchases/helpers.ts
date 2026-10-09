/**
 * Logique pure du module « Fournisseurs et achats » (aucune dépendance : testable isolément).
 * Les règles décisives (quantités, plafonds de paiement, droits) sont rejouées par la base de données ;
 * ces fonctions servent à guider l'utilisateur et à éviter des allers-retours inutiles.
 */

const num = (v: unknown): number => {
  const n = typeof v === 'number' ? v : Number(v);
  return Number.isFinite(n) ? n : 0;
};
const round2 = (n: number) => Math.round(n * 100) / 100;

/* ---------- Statuts ---------- */

export const ORDER_STATUS_LABELS: Record<string, string> = {
  draft: 'Brouillon',
  sent: 'Envoyée',
  confirmed: 'Confirmée',
  partial: 'Partiellement reçue',
  received: 'Reçue',
  cancelled: 'Annulée',
  closed: 'Clôturée',
};

export function orderStatusLabel(status: string): string {
  return ORDER_STATUS_LABELS[status] ?? status;
}

export const SUPPLIER_STATUS_LABELS: Record<string, string> = {
  active: 'Actif',
  inactive: 'Inactif',
  blocked: 'Bloqué',
};

/** Une commande peut recevoir de la marchandise tant qu'elle n'est ni complète, ni annulée, ni clôturée. */
export function canReceive(status: string): boolean {
  return ['draft', 'sent', 'confirmed', 'partial'].includes(status);
}

/** Indication d'interface : la base refusera de toute façon l'annulation si de la marchandise est reçue ou un paiement fait. */
export function canCancelOrder(status: string, paidAmount: number): boolean {
  return ['draft', 'sent', 'confirmed'].includes(status) && paidAmount <= 0;
}

export function canPay(status: string, remaining: number): boolean {
  return status !== 'cancelled' && remaining > 0;
}

export const PAYMENT_METHODS = [
  { value: 'cash', label: 'Espèces' },
  { value: 'mobile_money', label: 'Mobile Money' },
  { value: 'bank_transfer', label: 'Virement bancaire' },
  { value: 'cheque', label: 'Chèque' },
  { value: 'other', label: 'Autre' },
] as const;

export function paymentMethodLabel(value: string | null | undefined): string {
  return PAYMENT_METHODS.find((m) => m.value === value)?.label ?? (value || '—');
}

/* ---------- Fournisseurs ---------- */

/** Prochain code fournisseur « F-0001 », « F-0002 »… à partir des codes existants (les autres formats sont ignorés). */
export function nextSupplierCode(existing: string[]): string {
  let max = 0;
  for (const code of existing) {
    const m = /^F-(\d+)$/i.exec((code ?? '').trim());
    if (m) max = Math.max(max, Number(m[1]));
  }
  return `F-${String(max + 1).padStart(4, '0')}`;
}

/* ---------- Lignes de commande ---------- */

export interface OrderLineInput {
  article_id: string;
  quantity: string | number;
  unit_cost: string | number;
}

export function lineTotal(line: Pick<OrderLineInput, 'quantity' | 'unit_cost'>): number {
  return round2(num(line.quantity) * num(line.unit_cost));
}

export function orderTotal(lines: OrderLineInput[]): number {
  return round2(lines.reduce((sum, l) => sum + lineTotal(l), 0));
}

/** Renvoie un message d'erreur en français, ou null si les lignes sont valides. */
export function validateOrderLines(lines: OrderLineInput[]): string | null {
  if (lines.length === 0) return 'Ajoutez au moins un article à la commande.';
  if (lines.length > 200) return 'Une commande ne peut pas dépasser 200 lignes.';
  const seen = new Set<string>();
  for (const [i, l] of lines.entries()) {
    const n = i + 1;
    if (!l.article_id) return `Ligne ${n} : choisissez un article.`;
    if (seen.has(l.article_id)) return `Ligne ${n} : cet article est déjà dans la commande.`;
    seen.add(l.article_id);
    const qty = Number(l.quantity);
    const cost = l.unit_cost === '' ? NaN : Number(l.unit_cost);
    if (!Number.isFinite(qty) || qty <= 0) return `Ligne ${n} : la quantité doit être supérieure à 0.`;
    if (!Number.isFinite(cost) || cost < 0) return `Ligne ${n} : le coût unitaire est invalide.`;
  }
  return null;
}

export function toOrderItemsPayload(lines: OrderLineInput[]): { article_id: string; quantity: number; unit_cost: number }[] {
  return lines.map((l) => ({ article_id: l.article_id, quantity: Number(l.quantity), unit_cost: Number(l.unit_cost) }));
}

/* ---------- Réceptions ---------- */

export interface OrderItemRow {
  article_id: string;
  quantity: number | string;
}

export interface ReceiptRow {
  status: string;
  goods_receipt_items: { article_id: string; quantity_received: number | string }[] | null;
}

/** Quantités déjà reçues par article (seules les réceptions au statut « received » comptent). */
export function receivedByArticle(receipts: ReceiptRow[]): Record<string, number> {
  const out: Record<string, number> = {};
  for (const r of receipts) {
    if (r.status !== 'received') continue;
    for (const it of r.goods_receipt_items ?? []) {
      out[it.article_id] = (out[it.article_id] ?? 0) + num(it.quantity_received);
    }
  }
  return out;
}

export function orderedByArticle(items: OrderItemRow[]): Record<string, number> {
  const out: Record<string, number> = {};
  for (const it of items) out[it.article_id] = (out[it.article_id] ?? 0) + num(it.quantity);
  return out;
}

/** Reste à recevoir par article (jamais négatif). */
export function remainingByArticle(items: OrderItemRow[], receipts: ReceiptRow[]): Record<string, number> {
  const ordered = orderedByArticle(items);
  const received = receivedByArticle(receipts);
  const out: Record<string, number> = {};
  for (const id of Object.keys(ordered)) out[id] = Math.max(0, round2(ordered[id] - (received[id] ?? 0)));
  return out;
}

/** Avancement de la réception en pourcentage (0–100) sur l'ensemble des articles commandés. */
export function receiptProgress(items: OrderItemRow[], receipts: ReceiptRow[]): number {
  const ordered = orderedByArticle(items);
  const received = receivedByArticle(receipts);
  let total = 0;
  let done = 0;
  for (const id of Object.keys(ordered)) {
    total += ordered[id];
    done += Math.min(ordered[id], received[id] ?? 0);
  }
  return total <= 0 ? 0 : Math.round((done / total) * 100);
}

export interface ReceiptValidation {
  error: string | null;
  items: { article_id: string; quantity_received: number }[];
}

/** Les champs vides ou à 0 sont ignorés ; chaque quantité saisie doit tenir dans le reste à recevoir. */
export function validateReceiptInputs(remaining: Record<string, number>, inputs: Record<string, string>): ReceiptValidation {
  const items: { article_id: string; quantity_received: number }[] = [];
  for (const [article_id, raw] of Object.entries(inputs)) {
    const text = (raw ?? '').trim();
    if (text === '') continue;
    const qty = Number(text.replace(',', '.'));
    if (!Number.isFinite(qty) || qty < 0) return { error: 'Une quantité saisie est invalide.', items: [] };
    if (qty === 0) continue;
    if (qty > (remaining[article_id] ?? 0)) {
      return { error: 'Une quantité dépasse le reste à recevoir pour cet article.', items: [] };
    }
    items.push({ article_id, quantity_received: qty });
  }
  if (items.length === 0) return { error: 'Indiquez au moins une quantité reçue.', items: [] };
  return { error: null, items };
}

/* ---------- Paiements ---------- */

export interface PaymentRow {
  amount: number | string;
  status: string;
}

export function paidTotal(payments: PaymentRow[]): number {
  return round2(payments.reduce((s, p) => (p.status === 'paid' ? s + num(p.amount) : s), 0));
}

export function remainingToPay(total: unknown, payments: PaymentRow[]): number {
  return Math.max(0, round2(num(total) - paidTotal(payments)));
}

export type PaymentState = 'unpaid' | 'partial' | 'paid';

export const PAYMENT_STATE_LABELS: Record<PaymentState, string> = {
  unpaid: 'Non payée',
  partial: 'Partiellement payée',
  paid: 'Payée',
};

export function paymentState(total: unknown, payments: PaymentRow[]): PaymentState {
  const paid = paidTotal(payments);
  if (paid <= 0) return 'unpaid';
  return paid >= num(total) ? 'paid' : 'partial';
}

export interface PaymentValidation {
  error: string | null;
  amount: number;
}

export function validatePaymentAmount(raw: string, remaining: number): PaymentValidation {
  const amount = Number((raw ?? '').trim().replace(/\s/g, '').replace(',', '.'));
  if (!Number.isFinite(amount) || amount <= 0) return { error: 'Saisissez un montant supérieur à 0.', amount: 0 };
  if (amount > remaining) return { error: 'Le montant dépasse le reste à payer.', amount: 0 };
  return { error: null, amount: round2(amount) };
}

/* ---------- Soldes fournisseurs ---------- */

export interface OrderBalanceRow {
  id: string;
  supplier_id: string;
  total_amount: number | string;
  status: string;
}

export interface SupplierPaymentRow {
  supplier_id: string;
  purchase_order_id: string | null;
  amount: number | string;
  status: string;
}

/** Montant restant dû à chaque fournisseur (commandes annulées exclues, paiements « payés » seulement). */
export function balancesBySupplier(orders: OrderBalanceRow[], payments: SupplierPaymentRow[]): Record<string, number> {
  const live = new Set(orders.filter((o) => o.status !== 'cancelled').map((o) => o.id));
  const due: Record<string, number> = {};
  for (const o of orders) {
    if (o.status === 'cancelled') continue;
    due[o.supplier_id] = (due[o.supplier_id] ?? 0) + num(o.total_amount);
  }
  for (const p of payments) {
    if (p.status !== 'paid' || !p.purchase_order_id || !live.has(p.purchase_order_id)) continue;
    due[p.supplier_id] = (due[p.supplier_id] ?? 0) - num(p.amount);
  }
  const out: Record<string, number> = {};
  for (const [id, v] of Object.entries(due)) out[id] = Math.max(0, round2(v));
  return out;
}

/* ---------- Messages d'erreur ---------- */

/** Remplace les identifiants d'articles cités par la base par leur nom, pour un message lisible. */
export function friendlyDbError(message: string, articleNames: Record<string, string>): string {
  return (message ?? '').replace(/[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}/gi, (id) => {
    const name = articleNames[id.toLowerCase()] ?? articleNames[id];
    return name ? `« ${name} »` : 'cet article';
  });
}
