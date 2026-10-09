'use client';

import React, { useEffect, useState } from 'react';
import { Package, Search, Plus, Edit2 } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchProducts, updateProduct, createProduct } from '@/lib/services/catalogueService';
import Modal from '@/components/ui/Modal';
import { toast } from 'sonner';
import { fetchOrgProfile } from '@/lib/auth/context';

interface Product {
  id: string;
  organization_id: string;
  name: string;
  sku: string;
  stock_quantity: number;
  price_cents: number;
  created_at: string;
  active?: boolean;
}

export default function CataloguePage() {
  const [products, setProducts] = useState<Product[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [orgId, setOrgId] = useState<string | null>(null);
  const [modalOpen, setModalOpen] = useState(false);
  const [editProduct, setEditProduct] = useState<Product | null>(null);
  const [form, setForm] = useState({ name: '', sku: '', price_cents: 0 });
  const [saving, setSaving] = useState(false);

  useEffect(() => {
    supabase.auth.getUser().then(async ({ data }) => {
      if (!data.user) return;
      const { data: profile } = await fetchOrgProfile();
      if (profile?.organization_id) {
        setOrgId(profile.organization_id);
        loadProducts(profile.organization_id);
      }
    });
  }, []);

  async function loadProducts(oid: string) {
    setLoading(true);
    const { data, error: err } = await fetchProducts(oid);
    if (err) setError(err.message);
    else setProducts((data as Product[]) ?? []);
    setLoading(false);
  }

  function openCreate() {
    setEditProduct(null);
    setForm({ name: '', sku: '', price_cents: 0 });
    setModalOpen(true);
  }

  function openEdit(p: Product) {
    setEditProduct(p);
    setForm({ name: p.name, sku: p.sku, price_cents: p.price_cents });
    setModalOpen(true);
  }

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (!orgId) return;
    setSaving(true);

    const result = editProduct
      ? await updateProduct(editProduct.id, form)
      : await createProduct({ ...form, organization_id: orgId });

    if (result.error) toast.error(result.error.message);
    else {
      toast.success(editProduct ? 'Article mis à jour' : 'Article créé');
      setModalOpen(false);
      await loadProducts(orgId);
    }
    setSaving(false);
  }

  const filtered = products.filter(p => {
    const q = search.trim().toLowerCase();
    return !q || p.name.toLowerCase().includes(q) || p.sku.toLowerCase().includes(q);
  });

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Catalogue Articles</h1>
          <p className="text-sm text-[#A0AEC0] mt-1">Le catalogue définit les articles. Le stock est géré dans Stock et Entrepôts.</p>
        </div>
        <button onClick={openCreate} className="flex items-center gap-2 btn-gold px-4 py-2.5 rounded-xl text-sm font-bold">
          <Plus size={14} /> Nouvel article
        </button>
      </div>

      <div className="relative">
        <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#718096]" />
        <input value={search} onChange={e => setSearch(e.target.value)} placeholder="Rechercher par nom, code..." className="w-full bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm placeholder-[#718096] focus:outline-none focus:border-[#D4AF37]/60" />
      </div>

      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
        {loading ? <div className="py-16 text-center text-[#A0AEC0] text-sm">Chargement...</div> :
         error ? <div className="py-16 text-center text-red-400 text-sm">{error}</div> :
         filtered.length === 0 ? <div className="py-16 text-center text-[#A0AEC0] text-sm">Aucun article trouvé</div> :
         <div className="overflow-x-auto"><table className="w-full">
          <thead><tr className="border-b border-[#D4AF37]/10">
            <th className="text-left px-4 py-3 text-xs text-[#718096] uppercase">Code</th>
            <th className="text-left px-4 py-3 text-xs text-[#718096] uppercase">Article</th>
            <th className="text-left px-4 py-3 text-xs text-[#718096] uppercase">Prix</th>
            <th className="text-left px-4 py-3 text-xs text-[#718096] uppercase">Stock entrepôts</th>
            <th className="px-4 py-3"></th>
          </tr></thead>
          <tbody>{filtered.map(p => <tr key={p.id} className="border-b border-[#D4AF37]/5">
            <td className="px-4 py-3 text-xs font-mono text-[#D4AF37]">{p.sku}</td>
            <td className="px-4 py-3 text-sm font-medium text-white">{p.name}</td>
            <td className="px-4 py-3 text-sm text-[#A0AEC0]">{new Intl.NumberFormat('fr-FR',{style:'currency',currency:'XOF',maximumFractionDigits:0}).format((p.price_cents??0)/100)}</td>
            <td className="px-4 py-3 text-sm font-semibold text-white">{p.stock_quantity}</td>
            <td className="px-4 py-3"><button onClick={() => openEdit(p)} className="p-1.5 rounded-lg text-[#718096] hover:text-[#D4AF37]"><Edit2 size={14}/></button></td>
          </tr>)}</tbody>
         </table></div>}
      </div>

      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title={editProduct ? "Modifier l'article" : 'Nouvel article'} size="md">
        <form onSubmit={handleSave} className="space-y-4 p-1">
          <div><label className="block text-xs text-[#A0AEC0] mb-1.5">Nom de l'article</label>
            <input required value={form.name} onChange={e=>setForm(f=>({...f,name:e.target.value}))} className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm" /></div>
          <div><label className="block text-xs text-[#A0AEC0] mb-1.5">Code article</label>
            <input value={form.sku} onChange={e=>setForm(f=>({...f,sku:e.target.value}))} placeholder="Généré si vide" className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm" /></div>
          <div><label className="block text-xs text-[#A0AEC0] mb-1.5">Prix comptant (XOF)</label>
            <input type="number" min={0} value={Math.round(form.price_cents/100)} onChange={e=>setForm(f=>({...f,price_cents:(parseInt(e.target.value)||0)*100}))} className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm" /></div>
          <p className="text-xs text-[#718096]">Pour ajouter du stock, utilisez la page Stock. Cela garantit la traçabilité Stock central → Entrepôt → Prospecteur.</p>
          <div className="flex gap-3 pt-2"><button type="button" onClick={()=>setModalOpen(false)} className="flex-1 py-2.5 rounded-xl border border-[#D4AF37]/20 text-[#A0AEC0]">Annuler</button>
            <button type="submit" disabled={saving} className="flex-1 btn-gold py-2.5 rounded-xl font-semibold disabled:opacity-60">{saving?'Enregistrement...':'Enregistrer'}</button></div>
        </form>
      </Modal>
    </div>
  );
}
