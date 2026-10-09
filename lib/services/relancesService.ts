import { supabase } from '@/lib/supabase/client';
import type { Followup } from '@/lib/relances/helpers';

export interface PendingReminder {
  id: string;
  reminder_at: string;
  channel: string;
  status: string;
  message: string | null;
  client_id: string | null;
  client_name: string | null;
  client_phone: string | null;
}

export type ReminderStatus = 'sent' | 'completed' | 'cancelled';

/** Échéances impayées (en retard, partielles ou à venir) visibles par l'utilisateur connecté. */
export async function fetchFollowups(organizationId: string): Promise<{ data: Followup[]; error: string | null }> {
  const { data, error } = await supabase.rpc('jdvcrm_get_payment_followups_v44', {
    p_organization_id: organizationId,
  });
  if (error) return { data: [], error: error.message };
  return { data: (data ?? []) as Followup[], error: null };
}

/** Crée un rappel par client en impayé (au plus un par jour et par client). Réservé aux administrateurs. */
export async function generateReminders(organizationId: string): Promise<{ created: number; error: string | null }> {
  const { data, error } = await supabase.rpc('jdvcrm_create_unpaid_followup_reminders_v1', {
    p_organization_id: organizationId,
  });
  if (error) return { created: 0, error: error.message };
  return { created: Number(data ?? 0), error: null };
}

interface ReminderRow {
  id: string;
  reminder_at: string;
  channel: string;
  status: string;
  message: string | null;
  client_id: string | null;
  clients: { first_name: string | null; last_name: string | null; phone: string | null } | { first_name: string | null; last_name: string | null; phone: string | null }[] | null;
}

export async function fetchPendingReminders(
  organizationId: string
): Promise<{ data: PendingReminder[]; error: string | null }> {
  const { data, error } = await supabase
    .from('follow_up_reminders')
    .select('id, reminder_at, channel, status, message, client_id, clients(first_name, last_name, phone)')
    .eq('organization_id', organizationId)
    .eq('status', 'pending')
    .order('reminder_at', { ascending: false })
    .limit(100);
  if (error) return { data: [], error: error.message };
  const rows = (data ?? []) as unknown as ReminderRow[];
  return {
    data: rows.map((r) => {
      const c = Array.isArray(r.clients) ? r.clients[0] : r.clients;
      return {
        id: r.id,
        reminder_at: r.reminder_at,
        channel: r.channel,
        status: r.status,
        message: r.message,
        client_id: r.client_id,
        client_name: c ? `${c.first_name ?? ''} ${c.last_name ?? ''}`.trim() || null : null,
        client_phone: c?.phone ?? null,
      };
    }),
    error: null,
  };
}

export async function updateReminderStatus(id: string, status: ReminderStatus): Promise<string | null> {
  const { error } = await supabase.from('follow_up_reminders').update({ status }).eq('id', id);
  return error ? error.message : null;
}

/** Noms des prospecteurs de l'entreprise (vue administrateur). */
export async function fetchProspecteurNames(organizationId: string): Promise<Record<string, string>> {
  const { data } = await supabase
    .from('prospecteurs')
    .select('id, first_name, last_name')
    .eq('organization_id', organizationId);
  const map: Record<string, string> = {};
  for (const p of (data ?? []) as { id: string; first_name: string | null; last_name: string | null }[]) {
    map[p.id] = `${p.first_name ?? ''} ${p.last_name ?? ''}`.trim() || 'Prospecteur';
  }
  return map;
}
