import { supabase } from '@/lib/supabase/client';
import { newArticleCode, toCents } from '@/lib/services/compat';

export interface Product {
  id: string;
  organization_id: string;
  name: string;
  sku: string;
  stock_quantity: number;
  price_cents: number;
  created_at: string;
  active?: boolean;
  minimum_quantity?: number;
}

type Row = Record<string, unknown>;

function mapProduct(a: Row, stockQuantity = 0, minimumQuantity = 0): Product {
  return {
    ...(a as Product),
    sku: String(a.code ?? ''),
    price_cents: toCents(a.cash_price ?? a.fixed_price),
    stock_quantity: Number(stockQuantity),
    minimum_quantity: Number(minimumQuantity),
  };
}

/**
 * Catalogue = définition des articles.
 * Le stock opérationnel est exclusivement porté par warehouse_inventory.
 */
export async function fetchProducts(organizationId: string, filters?: { search?: string }) {
  let query = supabase
    .from('articles')
    .select('*')
    .eq('organization_id', organizationId)
    .order('name', { ascending: true });

  if (filters?.search) {
    const s = filters.search.replace(/[%,()]/g, ' ');
    query = query.or(`name.ilike.%${s}%,code.ilike.%${s}%`);
  }

  const { data, error } = await query;
  if (error) return { data: null, error };

  const { data: inventory } = await supabase
    .from('warehouse_inventory')
    .select('article_id, quantity, minimum_quantity')
    .eq('organization_id', organizationId);

  const byArticle = new Map<string, { quantity: number; minimum: number }>();
  for (const row of (inventory ?? []) as Row[]) {
    const id = String(row.article_id);
    const current = byArticle.get(id) ?? { quantity: 0, minimum: 0 };
    current.quantity += Number(row.quantity ?? 0);
    current.minimum = Math.max(current.minimum, Number(row.minimum_quantity ?? 0));
    byArticle.set(id, current);
  }

  return {
    data: ((data ?? []) as Row[]).map(a => {
      const s = byArticle.get(String(a.id));
      return mapProduct(a, s?.quantity ?? 0, s?.minimum ?? 0);
    }),
    error: null,
  };
}

export async function fetchProductById(productId: string) {
  const { data, error } = await supabase.from('articles').select('*').eq('id', productId).single();
  if (error || !data) return { data: null, error };

  const { data: inventory } = await supabase
    .from('warehouse_inventory')
    .select('quantity, minimum_quantity')
    .eq('article_id', productId);

  const quantity = ((inventory ?? []) as Row[]).reduce((n, r) => n + Number(r.quantity ?? 0), 0);
  const minimum = ((inventory ?? []) as Row[]).reduce((n, r) => Math.max(n, Number(r.minimum_quantity ?? 0)), 0);
  return { data: mapProduct(data as Row, quantity, minimum), error: null };
}

export async function createProduct(product: Partial<Product>) {
  if (!product.organization_id) {
    return { data: null, error: new Error('organization_id is required') as unknown as { message: string } };
  }

  const price = Math.round((product.price_cents ?? 0) / 100);
  const { data, error } = await supabase
    .from('articles')
    .insert({
      organization_id: product.organization_id,
      code: (product.sku ?? '').trim() || newArticleCode(),
      name: product.name,
      fixed_price: price,
      cash_price: price,
      credit_price: price,
      active: true,
    })
    .select()
    .single();

  if (error || !data) return { data: null, error };
  return { data: mapProduct(data as Row), error: null };
}

export async function updateProduct(productId: string, updates: Partial<Product>) {
  const patch: Row = { updated_at: new Date().toISOString() };
  if (updates.name !== undefined) patch.name = updates.name;
  if (updates.sku !== undefined && updates.sku.trim()) patch.code = updates.sku.trim();
  if (updates.active !== undefined) patch.active = updates.active;
  if (updates.price_cents !== undefined) {
    const price = Math.round(updates.price_cents / 100);
    patch.fixed_price = price;
    patch.cash_price = price;
    patch.credit_price = price;
  }

  const { data, error } = await supabase.from('articles').update(patch).eq('id', productId).select().single();
  if (error || !data) return { data: null, error };
  return { data: mapProduct(data as Row), error: null };
}
