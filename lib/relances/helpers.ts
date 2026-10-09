/**
 * Logique pure du module « Relances et impayés » (aucune dépendance : testable isolément).
 */

export interface Followup {
  schedule_id: string;
  sale_id: string;
  installment_number: number;
  due_date: string; // YYYY-MM-DD
  expected_amount: number | string;
  paid_amount: number | string;
  remaining_amount: number | string;
  status: string;
  client_id: string | null;
  client_name: string | null;
  client_phone: string | null;
  prospecteur_id: string | null;
  days_late: number;
}

export type FollowupFilter = 'all' | 'overdue' | 'partial' | 'upcoming';
export type DisplayStatus = 'overdue' | 'partial' | 'upcoming';

export function toNumber(value: unknown): number {
  const n = typeof value === 'number' ? value : Number(value);
  return Number.isFinite(n) ? n : 0;
}

/** « 1 500 000 XOF » (séparateur de milliers français). */
export function formatXof(value: unknown): string {
  return `${new Intl.NumberFormat('fr-FR').format(Math.round(toNumber(value)))} XOF`;
}

/** « 2026-10-12 » -> « 12/10/2026 » sans passer par Date (pas de décalage de fuseau horaire). */
export function formatDateFr(iso: string | null | undefined): string {
  const m = /^(\d{4})-(\d{2})-(\d{2})/.exec(iso ?? '');
  return m ? `${m[3]}/${m[2]}/${m[1]}` : '—';
}

/**
 * Le retard est calculé à partir de la date (days_late), plus fiable que le statut
 * stocké, qui n'est mis à jour que par une tâche périodique.
 */
export function displayStatus(f: Pick<Followup, 'days_late' | 'status'>): DisplayStatus {
  if (toNumber(f.days_late) > 0) return 'overdue';
  if (f.status === 'partial') return 'partial';
  return 'upcoming';
}

export const STATUS_LABELS: Record<DisplayStatus, string> = {
  overdue: 'En retard',
  partial: 'Partiel',
  upcoming: 'À venir',
};

export interface FollowupSummary {
  count: number;
  overdueCount: number;
  totalRemaining: number;
  overdueRemaining: number;
  clients: number;
  maxDaysLate: number;
}

export function summarize(list: Followup[]): FollowupSummary {
  const clients = new Set<string>();
  let overdueCount = 0;
  let totalRemaining = 0;
  let overdueRemaining = 0;
  let maxDaysLate = 0;
  for (const f of list) {
    const remaining = toNumber(f.remaining_amount);
    const late = toNumber(f.days_late);
    totalRemaining += remaining;
    if (late > 0) {
      overdueCount += 1;
      overdueRemaining += remaining;
      if (late > maxDaysLate) maxDaysLate = late;
    }
    if (f.client_id) clients.add(f.client_id);
  }
  return { count: list.length, overdueCount, totalRemaining, overdueRemaining, clients: clients.size, maxDaysLate };
}

/** Filtre par statut affiché et par recherche (nom ou téléphone), triés du plus en retard au moins en retard. */
export function filterFollowups(list: Followup[], opts: { search?: string; filter?: FollowupFilter }): Followup[] {
  const q = (opts.search ?? '').trim().toLowerCase();
  const qDigits = q.replace(/\D/g, '');
  const filter = opts.filter ?? 'all';
  return list
    .filter((f) => (filter === 'all' ? true : displayStatus(f) === filter))
    .filter((f) => {
      if (!q) return true;
      const name = (f.client_name ?? '').toLowerCase();
      const phoneDigits = (f.client_phone ?? '').replace(/\D/g, '');
      return name.includes(q) || (qDigits.length >= 3 && phoneDigits.includes(qDigits));
    })
    .sort((a, b) => toNumber(b.days_late) - toNumber(a.days_late) || a.due_date.localeCompare(b.due_date));
}

/** Lien « appeler » ; chaîne vide si le numéro est inutilisable. */
export function toTelHref(raw: string | null | undefined): string {
  const value = (raw ?? '').trim();
  const digits = value.replace(/\D/g, '');
  if (digits.length < 6) return '';
  return `tel:${value.startsWith('+') ? '+' : ''}${digits}`;
}

/**
 * Lien WhatsApp (format international, sans « + »).
 * Un numéro local commençant par 0 reçoit l'indicatif pays fourni (ex. « 229 » pour le Bénin) ;
 * sans indicatif fourni, il est laissé tel quel et WhatsApp peut ne pas le reconnaître.
 */
export function toWhatsAppHref(raw: string | null | undefined, message: string, defaultCountryPrefix = ''): string {
  let digits = (raw ?? '').replace(/\D/g, '');
  if (digits.startsWith('00')) digits = digits.slice(2);
  const prefix = defaultCountryPrefix.replace(/\D/g, '');
  if (prefix && digits.startsWith('0') && !(raw ?? '').trim().startsWith('+')) digits = prefix + digits.replace(/^0+/, '');
  if (digits.length < 8) return '';
  return `https://wa.me/${digits}?text=${encodeURIComponent(message)}`;
}

export function buildReminderMessage(f: Followup): string {
  const name = (f.client_name ?? '').trim();
  const hello = name ? `Bonjour ${name}` : 'Bonjour';
  const status = displayStatus(f);
  const when =
    status === 'overdue'
      ? `était attendue le ${formatDateFr(f.due_date)}`
      : `est prévue le ${formatDateFr(f.due_date)}`;
  return `${hello}, petit rappel : votre échéance n°${f.installment_number} ${when}. Reste à régler : ${formatXof(f.remaining_amount)}. Merci de votre confiance.`;
}
