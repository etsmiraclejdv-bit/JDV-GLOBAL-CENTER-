import { createClient, type SupabaseClient } from '@supabase/supabase-js';
import { checkRateLimit, type RateLimitOptions, type RateLimitResult } from './memoryRateLimit';

export { checkRateLimit } from './memoryRateLimit';
export type { RateLimitOptions, RateLimitResult } from './memoryRateLimit';
export { getClientIp } from './clientIp';

const SHARED_TIMEOUT_MS = 2000;
let adminClient: SupabaseClient | null = null;

function getAdminClient(): SupabaseClient | null {
  const url = process.env.NEXT_PUBLIC_SUPABASE_URL;
  const key = process.env.SUPABASE_SERVICE_ROLE_KEY;
  if (!url || !key) return null;
  if (!adminClient) {
    adminClient = createClient(url, key, { auth: { autoRefreshToken: false, persistSession: false } });
  }
  return adminClient;
}

/**
 * Limiteur partagé entre toutes les instances (fonction SQL `jdvcrm_rate_limit_check_v1`).
 * En cas d'indisponibilité (variable manquante, erreur, délai dépassé), on retombe sur le limiteur
 * en mémoire plutôt que de bloquer les requêtes légitimes (notamment les webhooks de paiement).
 */
export async function checkRateLimitShared(
  identifier: string,
  options: RateLimitOptions
): Promise<RateLimitResult> {
  const client = getAdminClient();
  if (!client) return checkRateLimit(identifier, options);

  let timer: ReturnType<typeof setTimeout> | undefined;
  try {
    const timeout = new Promise<never>((_, reject) => {
      timer = setTimeout(() => reject(new Error('rate_limit_timeout')), SHARED_TIMEOUT_MS);
    });
    const { data, error } = await Promise.race([
      client.rpc('jdvcrm_rate_limit_check_v1', {
        p_key: identifier.slice(0, 200),
        p_limit: options.limit,
        p_window_seconds: Math.max(1, Math.ceil(options.windowMs / 1000)),
      }),
      timeout,
    ]);
    const row = Array.isArray(data) ? data[0] : data;
    if (error || !row || typeof row.allowed !== 'boolean') return checkRateLimit(identifier, options);
    return {
      allowed: row.allowed,
      remaining: Number(row.remaining ?? 0),
      resetAt: new Date(row.retry_at).getTime(),
    };
  } catch {
    return checkRateLimit(identifier, options);
  } finally {
    if (timer) clearTimeout(timer);
  }
}
