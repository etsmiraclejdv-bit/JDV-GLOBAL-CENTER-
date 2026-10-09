/**
 * Logique pure du module « Visites terrain » (aucune dépendance : testable isolément).
 */

export const VISIT_RESULTS = [
  { value: 'interested', label: 'Intéressé' },
  { value: 'to_follow_up', label: 'À relancer' },
  { value: 'sold', label: 'Vente conclue' },
  { value: 'not_interested', label: 'Pas intéressé' },
  { value: 'absent', label: 'Absent / injoignable' },
  { value: 'other', label: 'Autre' },
] as const;

export function visitResultLabel(value: string | null | undefined): string {
  return VISIT_RESULTS.find((r) => r.value === value)?.label ?? (value || '—');
}

export interface VisitInput {
  prospect_id: string;
  visit_date: string;
  result: string;
  notes: string;
  next_follow_up_at: string;
  address: string;
  latitude: number | null;
  longitude: number | null;
}

const MAX_NOTES = 2000;
const FUTURE_TOLERANCE_MS = 5 * 60 * 1000;

export function validateVisit(v: VisitInput, now: Date): string | null {
  if (!v.prospect_id) return 'Choisissez le prospect visité.';
  const when = new Date(v.visit_date);
  if (Number.isNaN(when.getTime())) return 'La date de la visite est invalide.';
  if (when.getTime() > now.getTime() + FUTURE_TOLERANCE_MS) return 'La date de la visite ne peut pas être dans le futur.';
  if (!VISIT_RESULTS.some((r) => r.value === v.result)) return 'Choisissez le résultat de la visite.';
  if (v.notes.length > MAX_NOTES) return `Les notes sont trop longues (${MAX_NOTES} caractères maximum).`;
  if (v.next_follow_up_at) {
    const next = new Date(v.next_follow_up_at);
    if (Number.isNaN(next.getTime())) return 'La date de relance est invalide.';
    if (next.getTime() <= when.getTime()) return 'La prochaine relance doit être postérieure à la visite.';
  }
  const hasLat = v.latitude !== null;
  const hasLng = v.longitude !== null;
  if (hasLat !== hasLng) return 'La position GPS est incomplète.';
  if (hasLat && hasLng) {
    if (!Number.isFinite(v.latitude) || Math.abs(v.latitude as number) > 90) return 'La latitude est invalide.';
    if (!Number.isFinite(v.longitude) || Math.abs(v.longitude as number) > 180) return 'La longitude est invalide.';
  }
  return null;
}

export interface VisitRow {
  visit_date: string;
  prospect_id: string | null;
  result: string | null;
}

export interface VisitSummary {
  total: number;
  thisMonth: number;
  last7Days: number;
  distinctProspects: number;
  byResult: Record<string, number>;
}

export function summarizeVisits(rows: VisitRow[], now: Date): VisitSummary {
  const monthStart = new Date(now.getFullYear(), now.getMonth(), 1).getTime();
  const weekStart = now.getTime() - 7 * 86_400_000;
  const prospects = new Set<string>();
  const byResult: Record<string, number> = {};
  let thisMonth = 0;
  let last7Days = 0;
  for (const r of rows) {
    const t = new Date(r.visit_date).getTime();
    if (Number.isNaN(t)) continue;
    if (t >= monthStart && t <= now.getTime() + FUTURE_TOLERANCE_MS) thisMonth += 1;
    if (t >= weekStart && t <= now.getTime() + FUTURE_TOLERANCE_MS) last7Days += 1;
    if (r.prospect_id) prospects.add(r.prospect_id);
    const key = r.result || 'other';
    byResult[key] = (byResult[key] ?? 0) + 1;
  }
  return { total: rows.length, thisMonth, last7Days, distinctProspects: prospects.size, byResult };
}

export interface FollowUpProspect {
  id: string;
  status: string;
  next_follow_up_at: string | null;
}

const CLOSED_STATUSES = ['converted', 'lost', 'inactive', 'closed', 'archived'];

export function prospectsDueForFollowUp<T extends FollowUpProspect>(prospects: T[], now: Date): T[] {
  return prospects
    .filter((p) => !CLOSED_STATUSES.includes(p.status) && p.next_follow_up_at && new Date(p.next_follow_up_at).getTime() <= now.getTime())
    .sort((a, b) => (a.next_follow_up_at as string).localeCompare(b.next_follow_up_at as string));
}

export function mapsUrl(lat: unknown, lng: unknown): string {
  if (lat === null || lat === undefined || lng === null || lng === undefined || lat === '' || lng === '') return '';
  const la = Number(lat);
  const lo = Number(lng);
  if (!Number.isFinite(la) || !Number.isFinite(lo) || Math.abs(la) > 90 || Math.abs(lo) > 180) return '';
  return `https://www.google.com/maps?q=${la},${lo}`;
}

export function toDatetimeLocal(d: Date): string {
  const p = (n: number) => String(n).padStart(2, '0');
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}T${p(d.getHours())}:${p(d.getMinutes())}`;
}

export function fromDatetimeLocal(value: string): string {
  if (!value) return '';
  const d = new Date(value);
  return Number.isNaN(d.getTime()) ? '' : d.toISOString();
}