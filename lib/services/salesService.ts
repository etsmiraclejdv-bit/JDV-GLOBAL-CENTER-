import { supabase } from '@/lib/supabase/client';
import { trackSaleRecorded } from '@/lib/analytics';
import { newSaleNumber, personName, saleTotal, toCents } from '@/lib/services/compat';

export interface Sale {
  id: string;
  organization_id: string;
  client_id?: string;
  prospecteur_id?: string;
  article_id?: string;
  product_id?: string;
  amount_cents: number;
  status: string;
  sold_at: string;
}

export interface Payment {
  id: string;
  organization_id: string;
  client_id?: string;
  amount_cents: number;
  status: string;
  paid_at: string;
}

type Row = Record<string, unknown>;

async function nameMaps(organizationId: string) {
  const [{ data: clients }, { data: pros }, { data: articles }] = await Promise.all([
    supabase.from('clients').select('id, first_name, last_name, phone').eq('organization_id', organizationId),
    supabase.from('prospecteurs').select('id, first_name, last_name').eq('organization_id', organizationId),
    supabase.from('articles').select('id, name, code').eq('organization_id', organizationId),
  ]);
  const c = new Map<string, Row>();
  ((clients ?? []) as Row[]).forEach((x) =>
    c.set(x.id as string, { id: x.id, full_name: personName(x as never), phone: x.phone })
  );
  const p = new Map<string, Row>();
  ((pros ?? []) as Row[]).forEach((x) => p.set(x.id as string, { id: x.id, full_name: personName(x as never) }));
  const a = new Map<string, Row>();
  ((articles ?? []) as Row[]).forEach((x) => a.set(x.id as string, { id: x.id, name: x.name, sku: x.code }));
  return { c, p, a };
}

function mapSale(s: Row, m: Awaited<ReturnType<typeof nameMaps>>): Row {
  return {
    ...s,
    sold_at: s.sale_date,
    product_id: s.article_id,
    amount_cents: toCents(saleTotal(s as never)),
    clients: s.client_id ? m.c.get(s.client_id as string) ?? null : null,
    profiles: s.prospecteur_id ? m.p.get(s.prospecteur_id as string) ?? null : null,
    products: s.article_id ? m.a.get(s.article_id as string) ?? null : null,
  };
}

export async function fetchSales(
  organizationId: string,
  filters?: { status?: string; prospecteurId?: string; dateFrom?: string; dateTo?: string }
) {
  let query = supabase
    .from('sales')
    .select('*')
    .eq('organization_id', organizationId)
    .order('sale_date', { ascending: false });
  if (filters?.status) query = query.eq('status', filters.status);
  if (filters?.prospecteurId) query = query.eq('prospecteur_id', filters.prospecteurId);
  if (filters?.dateFrom) query = query.gte('sale_date', filters.dateFrom);
  if (filters?.dateTo) query = query.lte('sale_date', filters.dateTo);

  const { data, error } = await query;
  if (error) return { data: null, error };
  const m = await nameMaps(organizationId);
  return { data: ((data ?? []) as Row[]).map((s) => mapSale(s, m)), error: null };
}

export async function fetchSaleById(saleId: string) {
  const { data, error } = await supabase.from('sales').select('*').eq('id', saleId).single();
  if (error || !data) return { data: null, error };
  const m = await nameMaps((data as Row).organization_id as string);
  return { data: mapSale(data as Row, m), error: null };
}

/**
 * Création d'une vente. Le montant se règle par article : cash_price / credit_price.
 * Les champs hérités (amount_cents, sold_at, product_id) sont traduits vers le schéma réel.
 */
export async function createSale(sale: Partial<Sale> & Record<string, unknown>) {
  if (!sale.organization_id) {
    return { data: null, error: new Error('organization_id is required') as unknown as { message: string } };
  }
  const { amount_cents, sold_at, product_id, ...rest } = sale as Row;
  const payload: Row = { sale_number: newSaleNumber(), sale_type: 'cash', quantity: 1, ...rest };
  if (product_id && !payload.article_id) payload.article_id = product_id;
  if (sold_at) payload.sale_date = sold_at;

  // Si un montant est fourni sans prix unitaire, on le répartit sur la quantité.
  if (typeof amount_cents === 'number' && !payload.cash_price && !payload.credit_price && !payload.fixed_price) {
    const qty = Number(payload.quantity) || 1;
    const unit = Math.round(amount_cents / 100 / qty);
    payload.fixed_price = unit;
    payload.cash_price = unit;
    payload.credit_price = unit;
  }

  const { data, error } = await supabase.from('sales').insert(payload).select().single();

  if (!error && data) {
    trackSaleRecorded({
      organizationId: sale.organization_id as string,
      amountCents: typeof amount_cents === 'number' ? amount_cents : toCents(saleTotal(data as never)),
      portal: 'business',
    });

    // Le trigger SQL calcule la commission et crée la file de payout.
    // On déclenche ensuite le versement FedaPay automatiquement côté serveur.
    try {
      const { data: sessionData } = await supabase.auth.getSession();
      const accessToken = sessionData.session?.access_token;
      if (accessToken) {
        await fetch('/api/commissions/payout', {
          method: 'POST',
          headers: {
            Authorization: `Bearer ${accessToken}`,
            'Content-Type': 'application/json',
          },
          body: JSON.stringify({ saleId: data.id }),
        });
      }
    } catch (payoutError) {
      console.error('[commission-payout]', payoutError);
      // La commission reste en file d'attente/échec et pourra être relancée.
    }
  }
  return { data, error };
}

function mapPayment(p: Row, clients?: Map<string, Row>): Row {
  return {
    ...p,
    paid_at: p.payment_date,
    amount_cents: toCents(p.amount),
    clients: clients && p.client_id ? clients.get(p.client_id as string) ?? null : undefined,
  };
}

export async function fetchPaymentsBySale(saleId: string) {
  const { data, error } = await supabase
    .from('payments')
    .select('*')
    .eq('sale_id', saleId)
    .order('payment_date', { ascending: false });
  if (error) return { data: null, error };
  return { data: ((data ?? []) as Row[]).map((p) => mapPayment(p)), error: null };
}

export async function createPayment(payment: Partial<Payment> & Record<string, unknown>) {
  if (!payment.organization_id) {
    return { data: null, error: new Error('organization_id is required') as unknown as { message: string } };
  }
  const { amount_cents, paid_at, ...rest } = payment as Row;
  const payload: Row = { ...rest };
  if (typeof amount_cents === 'number' && payload.amount === undefined) payload.amount = Math.round(amount_cents / 100);
  if (paid_at) payload.payment_date = paid_at;
  const { data, error } = await supabase.from('payments').insert(payload).select().single();
  return { data, error };
}

export async function fetchPaymentsByOrg(organizationId: string) {
  const { data, error } = await supabase
    .from('payments')
    .select('*')
    .eq('organization_id', organizationId)
    .order('payment_date', { ascending: false });
  if (error) return { data: null, error };
  const m = await nameMaps(organizationId);
  return { data: ((data ?? []) as Row[]).map((p) => mapPayment(p, m.c)), error: null };
}
