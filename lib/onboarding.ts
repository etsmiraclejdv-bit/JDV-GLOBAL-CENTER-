import { supabase } from '@/lib/supabase/client';

export interface OnboardingPayload { [key: string]: unknown; }

const KEY = 'jdv_pending_company_application';

function isPayload(v: unknown): v is OnboardingPayload {
  return !!v && typeof v === 'object';
}

async function clearPending() {
  try { localStorage.removeItem(KEY); } catch {}
  try { await supabase.auth.updateUser({ data: { pending_company_application: null } }); } catch {}
}

/** Soumet le dossier d'entreprise sans créer d'organisation active. */
export async function runOnboarding(userId: string, payload: OnboardingPayload) {
  void userId;
  return await supabase.rpc('jdvcrm_submit_company_application_v1', payload);
}

/** Après confirmation de l'email, soumet le dossier conservé localement. */
export async function completePendingOnboarding(userId: string, email: string): Promise<boolean> {
  let p: unknown = null;
  try {
    const raw = localStorage.getItem(KEY);
    p = raw ? JSON.parse(raw) : null;
  } catch {}
  if (!isPayload(p)) return false;
  const payload = p;
  const professionalEmail = typeof payload.p_representative_email === 'string' ? payload.p_representative_email : '';
  if (!professionalEmail || professionalEmail.toLowerCase() !== email.toLowerCase()) return false;
  const { data: existing } = await supabase.from('organization_applications').select('id').eq('applicant_user_id', userId).eq('professional_email', email.toLowerCase()).limit(1);
  if (existing && existing.length > 0) { await clearPending(); return true; }
  const { error } = await runOnboarding(userId, payload);
  if (error) return false;
  await clearPending();
  return true;
}
