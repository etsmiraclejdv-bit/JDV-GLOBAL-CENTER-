/**
 * Logique pure du module « Finances et commissions » (aucune dépendance : testable isolément).
 */

const num = (v: unknown): number => {
  const n = typeof v === 'number' ? v : Number(v);
  return Number.isFinite(n) ? n : 0;
};

export type PeriodPreset = 'month' | 'lastMonth' | 'last3Months' | 'year';

export const PRESET_LABELS: Record<PeriodPreset, string> = {
  month: 'Ce mois',
  lastMonth: 'Mois dernier',
  last3Months: '3 derniers mois',
  year: 'Cette année',
};

const pad = (n: number) => String(n).padStart(2, '0');
const iso = (y: number, m: number, d: number) => `${y}-${pad(m)}-${pad(d)}`;

/** Bornes (YYYY-MM-DD, jours inclus) d'une période prédéfinie, calculées sur la date locale fournie. */
export function periodForPreset(preset: PeriodPreset, today: Date): { start: string; end: string } {
  const y = today.getFullYear();
  const m = today.getMonth() + 1;
  const d = today.getDate();
  const todayIso = iso(y, m, d);
  switch (preset) {
    case 'month':
      return { start: iso(y, m, 1), end: todayIso };
    case 'lastMonth': {
      const ly = m === 1 ? y - 1 : y;
      const lm = m === 1 ? 12 : m - 1;
      const lastDay = new Date(ly, lm, 0).getDate();
      return { start: iso(ly, lm, 1), end: iso(ly, lm, lastDay) };
    }
    case 'last3Months': {
      const total = y * 12 + (m - 1) - 2;
      return { start: iso(Math.floor(total / 12), (total % 12) + 1, 1), end: todayIso };
    }
    case 'year':
      return { start: iso(y, 1, 1), end: todayIso };
  }
}

/** Vrai si les deux dates sont au format YYYY-MM-DD, réelles, dans l'ordre et sur 5 ans au plus. */
export function isValidPeriod(start: string, end: string): boolean {
  const parse = (s: string): number | null => {
    const m = /^(\d{4})-(\d{2})-(\d{2})$/.exec(s);
    if (!m) return null;
    const t = Date.UTC(Number(m[1]), Number(m[2]) - 1, Number(m[3]));
    const back = new Date(t);
    const ok = back.getUTCFullYear() === Number(m[1]) && back.getUTCMonth() === Number(m[2]) - 1 && back.getUTCDate() === Number(m[3]);
    return ok ? t : null;
  };
  const a = parse(start);
  const b = parse(end);
  if (a === null || b === null || b < a) return false;
  return (b - a) / 86_400_000 <= 366 * 5;
}

export interface FinancialDashboard {
  periodStart: string;
  periodEnd: string;
  salesCount: number;
  salesTotal: number;
  cashCollected: number;
  creditOutstanding: number;
  overdueAmount: number;
  overdueSchedules: number;
  commissionTotal: number;
  commissionUnpaid: number;
  commissionPaid: number;
}

/** Convertit le JSON renvoyé par la base en valeurs sûres (0 par défaut si un champ manque). */
export function parseDashboard(raw: unknown): FinancialDashboard {
  const o = (raw && typeof raw === 'object' ? raw : {}) as Record<string, unknown>;
  return {
    periodStart: typeof o.period_start === 'string' ? o.period_start : '',
    periodEnd: typeof o.period_end === 'string' ? o.period_end : '',
    salesCount: num(o.sales_count),
    salesTotal: num(o.sales_total),
    cashCollected: num(o.cash_collected),
    creditOutstanding: num(o.credit_outstanding),
    overdueAmount: num(o.overdue_amount),
    overdueSchedules: num(o.overdue_schedules),
    commissionTotal: num(o.commission_total),
    commissionUnpaid: num(o.commission_unpaid),
    commissionPaid: num(o.commission_paid),
  };
}

export interface ProspecteurRow {
  prospecteur_id: string | null;
  sales_count: number | string;
  sales_total: number | string;
  collected: number | string;
  outstanding: number | string;
  commission_total: number | string;
  commission_paid: number | string;
  commission_unpaid: number | string;
}

export interface ProspecteurTotals {
  salesCount: number;
  salesTotal: number;
  collected: number;
  outstanding: number;
  commissionTotal: number;
  commissionPaid: number;
  commissionUnpaid: number;
}

export function totalsByProspecteur(rows: ProspecteurRow[]): ProspecteurTotals {
  const t: ProspecteurTotals = { salesCount: 0, salesTotal: 0, collected: 0, outstanding: 0, commissionTotal: 0, commissionPaid: 0, commissionUnpaid: 0 };
  for (const r of rows) {
    t.salesCount += num(r.sales_count);
    t.salesTotal += num(r.sales_total);
    t.collected += num(r.collected);
    t.outstanding += num(r.outstanding);
    t.commissionTotal += num(r.commission_total);
    t.commissionPaid += num(r.commission_paid);
    t.commissionUnpaid += num(r.commission_unpaid);
  }
  return t;
}

/** Les plus gros vendeurs en premier ; à total égal, le nombre de ventes puis l'identifiant (ordre stable). */
export function sortProspecteurRows(rows: ProspecteurRow[]): ProspecteurRow[] {
  return [...rows].sort(
    (a, b) =>
      num(b.sales_total) - num(a.sales_total) ||
      num(b.sales_count) - num(a.sales_count) ||
      (a.prospecteur_id ?? '').localeCompare(b.prospecteur_id ?? '')
  );
}

/** Pourcentage entier borné à 0–100 ; 0 quand le dénominateur est nul. */
export function percent(part: unknown, whole: unknown): number {
  const w = num(whole);
  if (w <= 0) return 0;
  return Math.max(0, Math.min(100, Math.round((num(part) / w) * 100)));
}

export type CommissionStatus = 'pending' | 'approved' | 'paid' | 'cancelled';

export const COMMISSION_LABELS: Record<string, string> = {
  pending: 'En attente',
  approved: 'Approuvée',
  paid: 'Payée',
  cancelled: 'Annulée',
};

export function commissionLabel(status: string): string {
  return COMMISSION_LABELS[status] ?? status;
}

/** Une commission ne peut être réglée que si elle est en attente ou approuvée. */
export function canSettle(status: string): boolean {
  return status === 'pending' || status === 'approved';
}

export interface CommissionRow {
  commission_id: string;
  prospecteur_id: string | null;
  sale_id: string | null;
  rate: number | string;
  base_amount: number | string;
  commission_amount: number | string;
  status: string;
  paid_at: string | null;
}

/** Total des commissions encore à payer (en attente ou approuvées) dans une liste. */
export function unpaidCommissionTotal(rows: CommissionRow[]): number {
  return rows.reduce((sum, r) => (canSettle(r.status) ? sum + num(r.commission_amount) : sum), 0);
}

/** Taux affiché en pourcentage : accepte 0.05 (fraction) comme 5 (pourcent). */
export function formatRate(rate: unknown): string {
  const r = num(rate);
  const pct = r > 0 && r <= 1 ? r * 100 : r;
  return `${Number.isInteger(pct) ? pct : pct.toFixed(1).replace('.', ',')} %`;
}
