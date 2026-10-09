/**
 * Règles de choix d'un nouveau mot de passe (aucune dépendance : testable isolément).
 * 72 octets est la limite de l'algorithme bcrypt utilisé par Supabase : au-delà, la fin serait ignorée.
 */
export const PASSWORD_MIN_LENGTH = 10;
const BCRYPT_MAX_BYTES = 72;

/** Renvoie un message d'erreur en français, ou null si le nouveau mot de passe est acceptable. */
export function validateNewPassword(current: string, next: string, confirm: string): string | null {
  if (!current) return 'Saisissez votre mot de passe actuel.';
  if (next.length < PASSWORD_MIN_LENGTH) return `Le nouveau mot de passe doit contenir au moins ${PASSWORD_MIN_LENGTH} caractères.`;
  if (new TextEncoder().encode(next).length > BCRYPT_MAX_BYTES) return 'Le nouveau mot de passe est trop long (72 caractères maximum).';
  if (!/[A-Za-z]/.test(next) || !/[0-9]/.test(next)) return 'Le nouveau mot de passe doit contenir au moins une lettre et un chiffre.';
  if (next === current) return "Le nouveau mot de passe doit être différent de l'actuel.";
  if (next !== confirm) return 'La confirmation ne correspond pas au nouveau mot de passe.';
  return null;
}

/** Traduit les erreurs d'authentification Supabase en messages compréhensibles, sans divulguer de détail technique. */
export function friendlyAuthError(message: string | null | undefined): string {
  const m = (message ?? '').toLowerCase();
  if (m.includes('invalid login credentials')) return 'Mot de passe actuel incorrect.';
  if (m.includes('different from the old')) return "Le nouveau mot de passe doit être différent de l'actuel.";
  if (m.includes('weak') || m.includes('pwned') || m.includes('should contain')) return 'Mot de passe refusé : choisissez-en un plus robuste.';
  if (m.includes('rate limit') || m.includes('too many')) return 'Trop de tentatives. Réessayez dans quelques minutes.';
  return 'Impossible de changer le mot de passe pour le moment. Réessayez.';
}
