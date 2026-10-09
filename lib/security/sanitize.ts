/**
 * Fonctions d'assainissement des entrées utilisateur (sans dépendance : testables isolément).
 */

/** Retire les balises HTML et quelques caractères dangereux, puis tronque. L'apostrophe est conservée (N'Diaye). */
export function sanitizeString(value: unknown): string {
  if (typeof value !== 'string') return '';
  return value
    .replace(/<[^>]*>/g, '')
    .replace(/["`;\\]/g, '')
    .trim()
    .slice(0, 500);
}

export function sanitizeEmail(value: unknown): string {
  if (typeof value !== 'string') return '';
  const trimmed = value.trim().toLowerCase().slice(0, 254);
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(trimmed)) return '';
  return trimmed;
}

export function sanitizeUUID(value: unknown): string {
  if (typeof value !== 'string') return '';
  const trimmed = value.trim();
  if (!/^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(trimmed)) return '';
  return trimmed;
}

export function sanitizeNumber(value: unknown, min = 0, max = 100): number {
  const n = Number(value);
  if (Number.isNaN(n)) return min;
  return Math.min(max, Math.max(min, n));
}
