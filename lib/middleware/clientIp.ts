type HeaderReader = { headers: { get: (key: string) => string | null } };

/**
 * En-têtes posés par la plateforme d'hébergement (ils écrasent ceux envoyés par le client),
 * donc plus fiables que `x-forwarded-for`, que n'importe quel client peut forger.
 */
const PLATFORM_HEADERS = ['x-nf-client-connection-ip', 'x-vercel-forwarded-for', 'x-real-ip'];

export function getClientIp(req: HeaderReader): string {
  for (const name of PLATFORM_HEADERS) {
    const value = req.headers.get(name)?.split(',')[0]?.trim();
    if (value) return value;
  }
  const forwarded = req.headers.get('x-forwarded-for')?.split(',')[0]?.trim();
  return forwarded || 'unknown';
}
