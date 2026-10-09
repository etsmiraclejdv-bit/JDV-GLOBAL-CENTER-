/**
 * Aides communes aux routes FedaPay (côté serveur uniquement).
 */
export function fedapayBaseUrl(secretKey: string): string {
  return secretKey.startsWith('sk_live') ? 'https://api.fedapay.com/v1' : 'https://sandbox-api.fedapay.com/v1';
}

/**
 * L'API FedaPay enveloppe les objets sous une clé de type « v1/transaction ».
 * Cette fonction accepte aussi les formes « v1: { transaction } », « transaction » ou l'objet direct.
 */
export function unwrapFedapay<T = Record<string, unknown>>(json: unknown, key: string): T | null {
  if (!json || typeof json !== 'object') return null;
  const obj = json as Record<string, unknown>;
  const candidates = [obj[`v1/${key}`], (obj.v1 as Record<string, unknown> | undefined)?.[key], obj[key], obj];
  for (const c of candidates) {
    if (c && typeof c === 'object') return c as T;
  }
  return null;
}
