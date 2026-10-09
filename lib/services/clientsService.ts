import { supabase } from '@/lib/supabase/client';
import { personName, saleTotal, toCents, splitName } from '@/lib/services/compat';

export interface Client {
  id: string;
  organization_id: string;
  assigned_to?: string;
  full_name: string;
  phone?: string;
  payment_status: 'a_jour' | 'a_surveiller' | 'en_retard';
  balance_cents: number;
  created_at: string;
  profiles?: { id: string; full_name: string; phone?: string } | null;
}

type Row = Record<string, unknown>;

async function prospecteurMap(organizationId: string): Promise<Map<string, { id: string; full_name: string; phone?: string }>> {
  const { data } = await supabase
    .from('prospecteurs')
    .select('id, first_name, last_name, phone')
    .eq('organization_id', organizationId);
  const map = new Map<string, { id: string; full_name: string; phone?: string }>();
  ((data ?? []) as Row[]).forEach((p) =>
    map.set(p.id as string, { id: p.id as string, full_name: personName(p as never), phone: (p.phone as string) ?? undefined })
  );
  return map;
}

function mapClient(c: Row, pros: Map<string, { id: string; full_name: string; phone?: string }>, balance: number, late: boolean): Row {
  const paymentStatus = late ? 'en_retard' : balance > 0 ? 'a_surveiller' : 'a_jour';
  return {
    ...c,
    full_name: personName(c as never),
    assigned_to: (c.prospecteur_id as string) ?? undefined,
    payment_status: paymentStatus,
    balance_cents: toCents(balance),
    profiles: c.prospecteur_id ? pros.get(c.prospecteur_id as string) ?? null : null,
  };
}

/** Solde restant et retards par client pour toute l'organisation. */
async function balances(organizationId: string): Promise<{ balance: Map<string, number>; late: Set<string> }> {
  const [{ data: sales }, { data: late }] = await Promise.all([
    supabase
      .from('sales')
      .select('id, client_id, amount_remaining, status')
      .eq('organization_id', organizationId)
      .not('status', 'in', '(cancelled,completed)'),
    supabase.from('payment_schedules').select('sale_id').eq('organization_id', organizationId).eq('status', 'late'),
  ]);
  const balance = new Map<string, number>();
  const saleClient = new Map<string, string>();
  ((sales ?? []) as Row[]).forEach((s) => {
    if (!s.client_id) return;
    saleClient.set(s.id as string, s.client_id as string);
    balance.set(s.client_id as string, (balance.get(s.client_id as string) ?? 0) + (Number(s.amount_remaining) || 0));
  });
  const lateClients = new Set<string>();
  ((late ?? []) as Row[]).forEach((l) => {
    const c = saleClient.get(l.sale_id as string);
    if (c) lateClients.add(c);
  });
  return { balance, late: lateClients };
}

export async function fetchClients(
  organizationId: string,
  filters?: { paymentStatus?: string; assignedTo?: string }
) {
  let query = supabase
    .from('clients')
    .select('*')
    .eq('organization_id', organizationId)
    .neq('status', 'archived')
    .order('created_at', { ascending: false });
  if (filters?.assignedTo) query = query.eq('prospecteur_id', filters.assignedTo);

  const { data, error } = await query;
  if (error) return { data: null, error };

  const [pros, { balance, late }] = await Promise.all([prospecteurMap(organizationId), balances(organizationId)]);
  let rows = ((data ?? []) as Row[]).map((c) =>
    mapClient(c, pros, balance.get(c.id as string) ?? 0, late.has(c.id as string))
  );
  if (filters?.paymentStatus) rows = rows.filter((r) => r.payment_status === filters.paymentStatus);
  return { data: rows, error: null };
}

export async function fetchClientById(clientId: string) {
  const { data, error } = await supabase.from('clients').select('*').eq('id', clientId).single();
  if (error || !data) return { data: null, error };
  const c = data as Row;
  const orgId = c.organization_id as string;
  const [pros, { balance, late }] = await Promise.all([prospecteurMap(orgId), balances(orgId)]);
  return { data: mapClient(c, pros, balance.get(clientId) ?? 0, late.has(clientId)), error: null };
}

export async function createClient(client: Partial<Client> & Record<string, unknown>) {
  if (!client.organization_id) {
    return { data: null, error: new Error('organization_id is required') as unknown as { message: string } };
  }
  const { full_name, assigned_to, payment_status, balance_cents, profiles, ...rest } = client as Row;
  void payment_status; void balance_cents; void profiles;
  const names = typeof full_name === 'string' ? splitName(full_name) : {};
  const payload: Row = { ...rest, ...names };
  if (assigned_to) payload.prospecteur_id = assigned_to;
  const { data, error } = await supabase.from('clients').insert(payload).select().single();
  return { data, error };
}

export async function updateClient(clientId: string, updates: Partial<Client> & Record<string, unknown>) {
  const { organization_id, full_name, assigned_to, payment_status, balance_cents, profiles, ...rest } = updates as Row;
  void organization_id; void payment_status; void balance_cents; void profiles;
  const payload: Row = { ...rest };
  if (typeof full_name === 'string') Object.assign(payload, splitName(full_name));
  if (assigned_to !== undefined) payload.prospecteur_id = assigned_to;
  const { data, error } = await supabase.from('clients').update(payload).eq('id', clientId).select().single();
  return { data, error };
}

export async function fetchClientSales(clientId: string) {
  const { data, error } = await supabase
    .from('sales')
    .select('*')
    .eq('client_id', clientId)
    .order('sale_date', { ascending: false });
  if (error) return { data: null, error };
  return {
    data: ((data ?? []) as Row[]).map((s) => ({ ...s, sold_at: s.sale_date, amount_cents: toCents(saleTotal(s as never)) })),
    error: null,
  };
}

export async function fetchClientPayments(clientId: string) {
  const { data, error } = await supabase
    .from('payments')
    .select('*')
    .eq('client_id', clientId)
    .order('payment_date', { ascending: false });
  if (error) return { data: null, error };
  return {
    data: ((data ?? []) as Row[]).map((p) => ({ ...p, paid_at: p.payment_date, amount_cents: toCents(p.amount) })),
    error: null,
  };
}
