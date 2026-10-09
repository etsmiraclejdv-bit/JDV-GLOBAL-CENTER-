/**
 * Couche de compatibilité entre le schéma réel de la base et les formes de données
 * attendues par les pages.
 *
 * Convention : les pages affichent les montants avec `(amount_cents ?? 0) / 100` en XOF.
 * La base stocke les montants en XOF entiers (sans centimes). Les services exposent donc
 * `amount_cents` = montant XOF × 100 pour l'affichage, sans jamais réécrire cette valeur en base.
 */
export const toCents = (n: unknown): number => Math.round((Number(n) || 0) * 100);
export const fromCents = (n: unknown): number => Math.round((Number(n) || 0) / 100);

export function personName(p?: { first_name?: string | null; last_name?: string | null } | null): string {
  return `${p?.first_name ?? ''} ${p?.last_name ?? ''}`.trim();
}

/** Sépare « Prénom Nom » en first_name / last_name. */
export function splitName(full: string): { first_name: string; last_name: string | null } {
  const parts = full.trim().split(/\s+/);
  const first = parts.shift() ?? '';
  return { first_name: first, last_name: parts.length ? parts.join(' ') : null };
}

export interface RawSale {
  sale_type?: string | null;
  cash_price?: number | string | null;
  credit_price?: number | string | null;
  fixed_price?: number | string | null;
  quantity?: number | string | null;
}

/** Montant total d'une vente en XOF (même règle que les rapports SQL). */
export function saleTotal(s: RawSale): number {
  const credit = String(s.sale_type ?? 'cash').toLowerCase() === 'credit';
  const unit = credit ? Number(s.credit_price) || Number(s.fixed_price) || 0 : Number(s.cash_price) || Number(s.fixed_price) || 0;
  return unit * (Number(s.quantity) || 1);
}

/** Numéro de vente unique lisible : VTE-AAAAMMJJ-XXXXXX. */
export function newSaleNumber(): string {
  const d = new Date();
  const ymd = `${d.getFullYear()}${String(d.getMonth() + 1).padStart(2, '0')}${String(d.getDate()).padStart(2, '0')}`;
  return `VTE-${ymd}-${Math.random().toString(36).slice(2, 8).toUpperCase()}`;
}

/** Code article unique : ART-XXXXXXXX. */
export function newArticleCode(): string {
  return `ART-${Date.now().toString(36).toUpperCase()}${Math.random().toString(36).slice(2, 4).toUpperCase()}`;
}
