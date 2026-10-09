/**
 * Limiteur de débit en mémoire (fenêtre fixe par identifiant).
 * Valable pour UNE instance : sert de repli quand le limiteur partagé (base de données) est indisponible.
 */
interface RateLimitEntry {
  count: number;
  resetAt: number;
}

export interface RateLimitOptions {
  /** Nombre maximal de requêtes par fenêtre */
  limit: number;
  /** Durée de la fenêtre en millisecondes */
  windowMs: number;
}

export interface RateLimitResult {
  allowed: boolean;
  remaining: number;
  resetAt: number;
}

const store = new Map<string, RateLimitEntry>();

if (typeof setInterval !== 'undefined') {
  const timer = setInterval(() => {
    const now = Date.now();
    store.forEach((entry, key) => {
      if (entry.resetAt < now) store.delete(key);
    });
  }, 5 * 60 * 1000);
  (timer as unknown as { unref?: () => void }).unref?.();
}

export function checkRateLimit(identifier: string, options: RateLimitOptions): RateLimitResult {
  const now = Date.now();
  const existing = store.get(identifier);

  if (!existing || existing.resetAt < now) {
    const entry: RateLimitEntry = { count: 1, resetAt: now + options.windowMs };
    store.set(identifier, entry);
    return { allowed: true, remaining: options.limit - 1, resetAt: entry.resetAt };
  }

  existing.count += 1;
  return {
    allowed: existing.count <= options.limit,
    remaining: Math.max(0, options.limit - existing.count),
    resetAt: existing.resetAt,
  };
}
