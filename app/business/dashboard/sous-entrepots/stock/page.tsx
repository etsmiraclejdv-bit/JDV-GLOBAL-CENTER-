'use client';

import { useEffect, useState } from 'react';
import { getAuthContext, type AuthContextData } from '@/lib/auth/context';
import { supabase } from '@/lib/supabase/client';

type Location = { id: string; name: string; code: string; warehouse_id: string; kind: 'warehouse' | 'subwarehouse' };
type Article = { id: string; code: string; name: string };
type Stock = { inventory_id: string; warehouse_id: string; warehouse_name: string; warehouse_code: string; subwarehouse_id: string | null; subwarehouse_name: string | null; subwarehouse_code: string | null; article_id: string; article_code: string; article_name: string; quantity: number; minimum_quantity: number };

export default function SousEntrepotsStockPage() {
  const [ctx, setCtx] = useState<AuthContextData | null>(null);
  const [locations, setLocations] = useState<Location[]>([]);
  const [articles, setArticles] = useState<Article[]>([]);
  const [stock, setStock] = useState<Stock[]>([]);
  const [source, setSource] = useState('');
  const [destination, setDestination] = useState('');
  const [article, setArticle] = useState('');
  const [quantity, setQuantity] = useState('');
  const [notes, setNotes] = useState('');
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [message, setMessage] = useState('');

  async function load(orgId: string) {
    const [w, sw, a, s] = await Promise.all([
      supabase.from('warehouses').select('id,name,code').eq('organization_id', orgId).eq('active', true).order('name'),
      supabase.from('warehouse_subwarehouses').select('id,name,code,parent_warehouse_id').eq('organization_id', orgId).eq('active', true).order('name'),
      supabase.from('articles').select('id,name,code').eq('organization_id', orgId).eq('active', true).order('code'),
      supabase.from('jdvcrm_subwarehouse_stock_v1').select('*').eq('organization_id', orgId).order('warehouse_name').order('subwarehouse_name').order('article_code'),
    ]);
    if (w.error || sw.error || a.error || s.error) throw w.error || sw.error || a.error || s.error;
    const warehouses = (w.data ?? []).map((x) => ({ id:x.id,name:x.name,code:x.code,warehouse_id:x.id,kind:'warehouse' as const }));
    const subs = (sw.data ?? []).map((x) => ({ id:x.id,name:x.name,code:x.code,warehouse_id:x.parent_warehouse_id,kind:'subwarehouse' as const }));
    setLocations([...warehouses, ...subs]);
    setArticles((a.data ?? []) as Article[]);
    setStock((s.data ?? []) as Stock[]);
  }

  useEffect(() => {
    let mounted = true;
    (async () => {
      try {
        const c = await getAuthContext();
        if (!mounted) return;
        setCtx(c);
        if (c?.organizationId) await load(c.organizationId);
      } catch (e) { if (mounted) setMessage(e instanceof Error ? e.message : 'Chargement impossible.'); }
      finally { if (mounted) setLoading(false); }
    })();
    return () => { mounted = false; };
  }, []);

  async function transfer() {
    if (!ctx?.organizationId || !source || !destination || !article || Number(quantity) <= 0) {
      setMessage('Source, destination, article et quantité sont obligatoires.');
      return;
    }
    const src = locations.find((x) => x.id === source);
    const dst = locations.find((x) => x.id === destination);
    if (!src || !dst) return;
    setSaving(true); setMessage('');
    const { data, error } = await supabase.rpc('jdvcrm_transfer_stock_location_v1', {
      p_article_id: article,
      p_quantity: Number(quantity),
      p_source_warehouse_id: src.warehouse_id,
      p_source_subwarehouse_id: src.kind === 'subwarehouse' ? src.id : null,
      p_destination_warehouse_id: dst.warehouse_id,
      p_destination_subwarehouse_id: dst.kind === 'subwarehouse' ? dst.id : null,
      p_notes: notes || null,
    });
    if (error) setMessage(error.message);
    else {
      setMessage('Transfert enregistré. Les deux mouvements sont tracés dans le journal.');
      setQuantity(''); setNotes('');
      await load(ctx.organizationId);
    }
    setSaving(false);
  }

  if (loading) return <div className="p-6 text-slate-300">Chargement du stock…</div>;

  return (
    <div className="min-h-full space-y-6 p-6 text-white">
      <div>
        <p className="text-xs font-semibold uppercase tracking-[0.2em] text-[#D4AF37]">Stock décentralisé</p>
        <h1 className="mt-1 text-3xl font-bold">Stock des sous-entrepôts</h1>
        <p className="mt-2 text-sm text-slate-400">Le stock central et les sous-entrepôts utilisent la même source de vérité. Un transfert produit automatiquement une sortie et une entrée liées.</p>
      </div>

      {message && <div className="rounded-xl border border-white/10 bg-[#08152f] p-4 text-sm">{message}</div>}

      <section className="rounded-2xl border border-[#D4AF37]/20 bg-[#08152f] p-5">
        <h2 className="text-xl font-semibold text-[#D4AF37]">Transfert de stock</h2>
        <div className="mt-4 grid gap-4 md:grid-cols-2 lg:grid-cols-4">
          <select value={source} onChange={(e)=>setSource(e.target.value)} className="rounded-xl border border-white/10 bg-[#0F2347] p-3"><option value="">Source</option>{locations.map(x=><option key={x.kind+x.id} value={x.id}>{x.name} · {x.code}</option>)}</select>
          <select value={destination} onChange={(e)=>setDestination(e.target.value)} className="rounded-xl border border-white/10 bg-[#0F2347] p-3"><option value="">Destination</option>{locations.map(x=><option key={x.kind+x.id} value={x.id}>{x.name} · {x.code}</option>)}</select>
          <select value={article} onChange={(e)=>setArticle(e.target.value)} className="rounded-xl border border-white/10 bg-[#0F2347] p-3"><option value="">Article</option>{articles.map(x=><option key={x.id} value={x.id}>{x.code} · {x.name}</option>)}</select>
          <input type="number" min="1" step="1" value={quantity} onChange={(e)=>setQuantity(e.target.value)} placeholder="Quantité" className="rounded-xl border border-white/10 bg-[#0F2347] p-3" />
        </div>
        <div className="mt-4 flex gap-3">
          <input value={notes} onChange={(e)=>setNotes(e.target.value)} placeholder="Motif / référence" className="flex-1 rounded-xl border border-white/10 bg-[#0F2347] p-3" />
          <button disabled={saving} onClick={()=>void transfer()} className="rounded-xl bg-[#D4AF37] px-6 py-3 font-semibold text-[#07142c] disabled:opacity-50">{saving ? 'Transfert…' : 'Transférer'}</button>
        </div>
      </section>

      <section className="overflow-hidden rounded-2xl border border-white/10 bg-[#08152f]">
        <div className="border-b border-white/10 p-5"><h2 className="text-xl font-semibold">État des stocks</h2></div>
        <div className="overflow-x-auto">
          <table className="w-full min-w-[900px] text-sm">
            <thead><tr className="border-b border-white/10 text-left text-slate-400">
              <th className="p-3">Entrepôt</th><th className="p-3">Sous-entrepôt</th><th className="p-3">Code</th><th className="p-3">Article</th><th className="p-3 text-right">Quantité</th><th className="p-3 text-right">Minimum</th>
            </tr></thead>
            <tbody>{stock.map(x=><tr key={x.inventory_id} className="border-b border-white/5">
              <td className="p-3">{x.warehouse_name} <span className="text-slate-500">({x.warehouse_code})</span></td>
              <td className="p-3">{x.subwarehouse_name ?? <span className="text-slate-500">Stock central</span>}</td>
              <td className="p-3 font-mono text-[#D4AF37]">{x.article_code}</td><td className="p-3">{x.article_name}</td>
              <td className="p-3 text-right font-semibold">{x.quantity}</td><td className="p-3 text-right text-slate-400">{x.minimum_quantity}</td>
            </tr>)}</tbody>
          </table>
        </div>
      </section>
    </div>
  );
}
