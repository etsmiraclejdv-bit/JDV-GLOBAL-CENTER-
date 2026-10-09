import { supabase } from '@/lib/supabase/client';
import {
  balancesBySupplier,
  nextSupplierCode,
  type OrderItemRow,
  type PaymentRow,
  type ReceiptRow,
} from '@/lib/purchases/helpers';

export interface Supplier {
  id: string;
  code: string;
  company_name: string;
  contact_name: string | null;
  phone: string | null;
  whatsapp: string | null;
  email: string | null;
  address: string | null;
  city: string | null;
  country: string | null;
  payment_terms: string | null;
  notes: string | null;
  status: string;
}

export type SupplierInput = Omit<Supplier, 'id' | 'code'>;

export interface PurchaseOrderRow {
  id: string;
  supplier_id: string;
  order_number: string;
  order_date: string;
  expected_date: string | null;
  total_amount: number;
  status: string;
  supplier_name: string;
  paid_amount: number;
}

export interface ArticleOption {
  id: string;
  code: string;
  name: string;
}

type Result<T> = { data: T; error: string | null };

const SUPPLIER_COLUMNS =
  'id, code, company_name, contact_name, phone, whatsapp, email, address, city, country, payment_terms, notes, status';

/* ---------- Fournisseurs ---------- */

export async function fetchSuppliers(organizationId: string): Promise<Result<Supplier[]>> {
  const { data, error } = await supabase
    .from('suppliers')
    .select(SUPPLIER_COLUMNS)
    .eq('organization_id', organizationId)
    .order('company_name', { ascending: true });
  if (error) return { data: [], error: error.message };
  return { data: (data ?? []) as Supplier[], error: null };
}

export async function fetchSupplierBalances(organizationId: string): Promise<Result<Record<string, number>>> {
  const [orders, payments] = await Promise.all([
    supabase.from('purchase_orders').select('id, supplier_id, total_amount, status').eq('organization_id', organizationId),
    supabase
      .from('supplier_payments')
      .select('supplier_id, purchase_order_id, amount, status')
      .eq('organization_id', organizationId),
  ]);
  const error = orders.error?.message || payments.error?.message || null;
  if (error) return { data: {}, error };
  return {
    data: balancesBySupplier(
      (orders.data ?? []) as { id: string; supplier_id: string; total_amount: number; status: string }[],
      (payments.data ?? []) as { supplier_id: string; purchase_order_id: string | null; amount: number; status: string }[]
    ),
    error: null,
  };
}

/** Crée (sans `id`) ou modifie (avec `id`) un fournisseur. Le code F-0001… est attribué automatiquement. */
export async function saveSupplier(
  organizationId: string,
  input: SupplierInput,
  id?: string
): Promise<{ error: string | null }> {
  if (id) {
    const { error } = await supabase.from('suppliers').update(input).eq('id', id);
    return { error: error ? error.message : null };
  }
  // Deux créations simultanées peuvent viser le même code : on recalcule et on réessaie.
  for (let attempt = 0; attempt < 3; attempt++) {
    const { data: existing } = await supabase.from('suppliers').select('code').eq('organization_id', organizationId);
    const code = nextSupplierCode(((existing ?? []) as { code: string }[]).map((s) => s.code));
    const { error } = await supabase.from('suppliers').insert({ ...input, organization_id: organizationId, code });
    if (!error) return { error: null };
    if (error.code !== '23505') return { error: error.message };
  }
  return { error: 'Impossible d\u2019attribuer un code fournisseur. Réessayez.' };
}

/* ---------- Articles ---------- */

export async function fetchArticles(organizationId: string): Promise<Result<ArticleOption[]>> {
  const { data, error } = await supabase
    .from('articles')
    .select('id, code, name')
    .eq('organization_id', organizationId)
    .eq('active', true)
    .order('name', { ascending: true });
  if (error) return { data: [], error: error.message };
  return { data: (data ?? []) as ArticleOption[], error: null };
}

/* ---------- Commandes ---------- */

interface OrderRowRaw {
  id: string;
  supplier_id: string;
  order_number: string;
  order_date: string;
  expected_date: string | null;
  total_amount: number | string;
  status: string;
  suppliers: { company_name: string } | { company_name: string }[] | null;
}

export async function fetchPurchaseOrders(organizationId: string): Promise<Result<PurchaseOrderRow[]>> {
  const [orders, payments] = await Promise.all([
    supabase
      .from('purchase_orders')
      .select('id, supplier_id, order_number, order_date, expected_date, total_amount, status, suppliers(company_name)')
      .eq('organization_id', organizationId)
      .order('created_at', { ascending: false })
      .limit(500),
    supabase
      .from('supplier_payments')
      .select('purchase_order_id, amount, status')
      .eq('organization_id', organizationId)
      .eq('status', 'paid'),
  ]);
  const error = orders.error?.message || payments.error?.message || null;
  if (error) return { data: [], error };
  const paid: Record<string, number> = {};
  for (const p of (payments.data ?? []) as { purchase_order_id: string | null; amount: number | string }[]) {
    if (p.purchase_order_id) paid[p.purchase_order_id] = (paid[p.purchase_order_id] ?? 0) + Number(p.amount);
  }
  const rows = (orders.data ?? []) as unknown as OrderRowRaw[];
  return {
    data: rows.map((o) => {
      const s = Array.isArray(o.suppliers) ? o.suppliers[0] : o.suppliers;
      return {
        id: o.id,
        supplier_id: o.supplier_id,
        order_number: o.order_number,
        order_date: o.order_date,
        expected_date: o.expected_date,
        total_amount: Number(o.total_amount),
        status: o.status,
        supplier_name: s?.company_name ?? 'Fournisseur',
        paid_amount: paid[o.id] ?? 0,
      };
    }),
    error: null,
  };
}

export interface OrderDetail {
  id: string;
  order_number: string;
  order_date: string;
  expected_date: string | null;
  total_amount: number;
  status: string;
  notes: string | null;
  supplier_id: string;
  supplier_name: string;
  items: (OrderItemRow & { id: string; unit_cost: number; total_amount: number; article_name: string; article_code: string })[];
  receipts: (ReceiptRow & { id: string; receipt_number: string; receipt_date: string; notes: string | null })[];
  payments: (PaymentRow & { id: string; payment_date: string; payment_method: string | null; provider_reference: string | null; notes: string | null })[];
}

interface DetailRaw {
  id: string;
  order_number: string;
  order_date: string;
  expected_date: string | null;
  total_amount: number | string;
  status: string;
  notes: string | null;
  supplier_id: string;
  suppliers: { company_name: string } | { company_name: string }[] | null;
  purchase_order_items:
    | {
        id: string;
        article_id: string;
        quantity: number | string;
        unit_cost: number | string | null;
        total_amount: number | string | null;
        articles: { code: string; name: string } | { code: string; name: string }[] | null;
      }[]
    | null;
}

export async function fetchOrderDetail(id: string): Promise<Result<OrderDetail | null>> {
  const [order, receipts, payments] = await Promise.all([
    supabase
      .from('purchase_orders')
      .select(
        'id, order_number, order_date, expected_date, total_amount, status, notes, supplier_id, suppliers(company_name), purchase_order_items(id, article_id, quantity, unit_cost, total_amount, articles(code, name))'
      )
      .eq('id', id)
      .maybeSingle(),
    supabase
      .from('goods_receipts')
      .select('id, receipt_number, receipt_date, status, notes, goods_receipt_items(article_id, quantity_received)')
      .eq('purchase_order_id', id)
      .order('created_at', { ascending: false }),
    supabase
      .from('supplier_payments')
      .select('id, amount, status, payment_date, payment_method, provider_reference, notes')
      .eq('purchase_order_id', id)
      .order('payment_date', { ascending: false }),
  ]);
  const error = order.error?.message || receipts.error?.message || payments.error?.message || null;
  if (error) return { data: null, error };
  const o = order.data as unknown as DetailRaw | null;
  if (!o) return { data: null, error: 'Commande introuvable.' };
  const s = Array.isArray(o.suppliers) ? o.suppliers[0] : o.suppliers;
  return {
    data: {
      id: o.id,
      order_number: o.order_number,
      order_date: o.order_date,
      expected_date: o.expected_date,
      total_amount: Number(o.total_amount),
      status: o.status,
      notes: o.notes,
      supplier_id: o.supplier_id,
      supplier_name: s?.company_name ?? 'Fournisseur',
      items: (o.purchase_order_items ?? []).map((it) => {
        const a = Array.isArray(it.articles) ? it.articles[0] : it.articles;
        return {
          id: it.id,
          article_id: it.article_id,
          quantity: Number(it.quantity),
          unit_cost: Number(it.unit_cost ?? 0),
          total_amount: Number(it.total_amount ?? 0),
          article_name: a?.name ?? 'Article',
          article_code: a?.code ?? '',
        };
      }),
      receipts: ((receipts.data ?? []) as unknown as OrderDetail['receipts']),
      payments: ((payments.data ?? []) as unknown as OrderDetail['payments']),
    },
    error: null,
  };
}

/* ---------- Actions atomiques (fonctions de la base) ---------- */

export async function createPurchaseOrder(
  supplierId: string,
  expectedDate: string | null,
  notes: string,
  items: { article_id: string; quantity: number; unit_cost: number }[]
): Promise<{ orderNumber: string | null; orderId: string | null; error: string | null }> {
  const { data, error } = await supabase.rpc('jdvcrm_create_purchase_order_v1', {
    p_supplier_id: supplierId,
    p_expected_date: expectedDate || null,
    p_notes: notes,
    p_items: items,
  });
  if (error) return { orderNumber: null, orderId: null, error: error.message };
  const r = (data ?? {}) as { order_number?: string; purchase_order_id?: string };
  return { orderNumber: r.order_number ?? null, orderId: r.purchase_order_id ?? null, error: null };
}

export async function receivePurchaseOrder(
  orderId: string,
  items: { article_id: string; quantity_received: number }[],
  notes: string
): Promise<{ receiptNumber: string | null; orderStatus: string | null; error: string | null }> {
  const { data, error } = await supabase.rpc('jdvcrm_receive_purchase_order_v1', {
    p_purchase_order_id: orderId,
    p_items: items,
    p_notes: notes,
  });
  if (error) return { receiptNumber: null, orderStatus: null, error: error.message };
  const r = (data ?? {}) as { receipt_number?: string; order_status?: string };
  return { receiptNumber: r.receipt_number ?? null, orderStatus: r.order_status ?? null, error: null };
}

export async function payPurchaseOrder(
  orderId: string,
  amount: number,
  method: string,
  reference: string,
  notes: string
): Promise<{ remaining: number | null; error: string | null }> {
  const { data, error } = await supabase.rpc('jdvcrm_pay_purchase_order_v1', {
    p_purchase_order_id: orderId,
    p_amount: amount,
    p_method: method,
    p_reference: reference,
    p_notes: notes,
  });
  if (error) return { remaining: null, error: error.message };
  const r = (data ?? {}) as { remaining?: number | string };
  return { remaining: r.remaining === undefined ? null : Number(r.remaining), error: null };
}

export async function cancelPurchaseOrder(orderId: string): Promise<{ error: string | null }> {
  const { error } = await supabase.rpc('jdvcrm_cancel_purchase_order_v1', { p_purchase_order_id: orderId });
  return { error: error ? error.message : null };
}
