import { supabase } from '@/lib/supabase/client';
import { personName, splitName } from '@/lib/services/compat';

export interface OrganizationSettings {
  notifications?: {
    email_on_late_payment?: boolean;
    sms_on_sale?: boolean;
  };
  sales?: {
    default_payment_frequency?: string;
    require_deposit?: boolean;
  };
  stock?: {
    low_stock_alert_threshold_percent?: number;
  };
}

type Row = Record<string, unknown>;

export async function fetchOrganization(organizationId: string) {
  const { data, error } = await supabase.from('organizations').select('*').eq('id', organizationId).single();
  if (error || !data) return { data: null, error };
  // « org_status » est l'ancien nom de la colonne « status ».
  return { data: { ...(data as Row), org_status: (data as Row).status }, error: null };
}

/** Réglages libres stockés en JSON dans organization_settings.settings. */
export async function fetchOrganizationSettings(organizationId: string) {
  const { data, error } = await supabase
    .from('organization_settings')
    .select('settings')
    .eq('organization_id', organizationId)
    .maybeSingle();
  return { data: ((data as Row | null)?.settings ?? {}) as OrganizationSettings & Row, error };
}

export async function saveOrganizationSettings(organizationId: string, settings: Row) {
  const { data: existing } = await supabase
    .from('organization_settings')
    .select('id, settings')
    .eq('organization_id', organizationId)
    .maybeSingle();
  if (existing) {
    const merged = { ...(((existing as Row).settings as Row) ?? {}), ...settings };
    const { error } = await supabase
      .from('organization_settings')
      .update({ settings: merged })
      .eq('id', (existing as Row).id as string);
    return { error };
  }
  const { error } = await supabase.from('organization_settings').insert({ organization_id: organizationId, settings });
  return { error };
}

export async function updateOrganization(organizationId: string, updates: Record<string, unknown>) {
  // Le statut et l'abonnement ne se modifient que par le concepteur.
  const { status, subscription_status, org_status, owner_user_id, ...safe } = updates;
  void status; void subscription_status; void org_status; void owner_user_id;
  const { data, error } = await supabase
    .from('organizations')
    .update({ ...safe, updated_at: new Date().toISOString() })
    .eq('id', organizationId)
    .select()
    .single();
  return { data, error };
}

export async function fetchProfile(userId: string) {
  const { data, error } = await supabase.from('profiles').select('*').eq('id', userId).single();
  if (error || !data) return { data: null, error };
  return { data: { ...(data as Row), full_name: (data as Row).display_name || personName(data as never) }, error: null };
}

export async function updateProfile(userId: string, updates: Record<string, unknown>) {
  // Seules les colonnes réellement présentes dans `profiles` sont envoyées.
  const { full_name, phone, preferred_language, avatar_url, country } = updates as Row;
  const payload: Row = { updated_at: new Date().toISOString() };
  if (phone !== undefined) payload.phone = phone || null;
  if (preferred_language !== undefined) payload.preferred_language = preferred_language;
  if (avatar_url !== undefined) payload.avatar_url = avatar_url;
  if (country !== undefined) payload.country = country;
  if (typeof full_name === 'string') {
    Object.assign(payload, splitName(full_name), { display_name: full_name.trim() });
  }
  const { data, error } = await supabase.from('profiles').update(payload).eq('id', userId).select().single();
  return { data, error };
}
