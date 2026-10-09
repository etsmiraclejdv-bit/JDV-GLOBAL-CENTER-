'use client';
import React, { useState, useEffect, useRef } from 'react';
import { ShoppingCart, TrendingUp, Users, Wallet, Plus, Clock } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchSales, createSale } from '@/lib/services/salesService';
import { fetchClients } from '@/lib/services/clientsService';
import { fetchProducts } from '@/lib/services/catalogueService';
import Link from 'next/link';
import Modal from '@/components/ui/Modal';
import { fetchOrgProfile } from '@/lib/auth/context';

export default function TerrainDashboardPage() {
  const [userName, setUserName] = useState('');
  const [salesCount, setSalesCount] = useState(0);
  const [totalAmount, setTotalAmount] = useState(0);
  const [prospectsCount, setProspectsCount] = useState(0);
  const [loading, setLoading] = useState(true);
  const [saleModalOpen, setSaleModalOpen] = useState(false);
  const [newSaleForm, setNewSaleForm] = useState({ client_id: '', article_id: '', sale_type: 'cash', quantity: 1, unit_price: 0, amount_paid: 0 });
  const [submitting, setSubmitting] = useState(false);
  const [submitError, setSubmitError] = useState('');
  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null);
  const userIdRef = useRef<string | null>(null);
  const prospecteurIdRef = useRef<string | null>(null);
  const [clients, setClients] = useState<Record<string, unknown>[]>([]);
  const [articles, setArticles] = useState<Record<string, unknown>[]>([]);
  const orgIdRef = useRef<string | null>(null);

  async function loadKPIs(oid: string, pid: string | null) {
    if (!pid) { setSalesCount(0); setTotalAmount(0); setProspectsCount(0); return; }
    const { data: salesData } = await fetchSales(oid, { prospecteurId: pid });
    const today = new Date()?.toDateString();
    const todaySales = (salesData ?? [])?.filter(s => new Date(s.sold_at)?.toDateString() === today);
    setSalesCount(todaySales?.length);
    setTotalAmount(todaySales?.reduce((sum, s) => sum + (s?.amount_cents ?? 0), 0));

    const { count } = await supabase
      .from('prospects')
      .select('id', { count: 'exact', head: true })
      .eq('organization_id', oid)
      .eq('prospecteur_id', pid)
      .not('status', 'in', '(converted,lost,archived)');
    setProspectsCount(count ?? 0);
  }

  useEffect(() => {
    supabase?.auth?.getUser()?.then(async ({ data }) => {
      if (!data?.user) return;
      const uid = data.user.id;
      userIdRef.current = uid;
      const { data: profile } = await fetchOrgProfile();
      if (profile) {
        setUserName(profile?.full_name ?? '');
        if (profile?.organization_id) {
          const oid = profile.organization_id;
          orgIdRef.current = oid;
          const pid = profile.prospecteur_id;
          prospecteurIdRef.current = pid;
          await loadKPIs(oid, pid);
          fetchClients(oid, { assignedTo: pid ?? undefined }).then(r => setClients((r.data ?? []) as Record<string, unknown>[]));
          fetchProducts(oid).then(r => setArticles(((r.data ?? []) as Record<string, unknown>[]).filter(a => a.active !== false)));

          const channel = supabase
            .channel(`terrain-kpi-${uid}`)
            .on('postgres_changes', { event: '*', schema: 'public', table: 'sales', filter: `organization_id=eq.${oid}` }, () => { loadKPIs(oid, pid); })
            .on('postgres_changes', { event: '*', schema: 'public', table: 'clients', filter: `organization_id=eq.${oid}` }, () => { loadKPIs(oid, pid); })
            .subscribe();

          channelRef.current = channel;
        }
      }
      setLoading(false);
    });

    return () => {
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current);
        channelRef.current = null;
      }
    };
  }, []);

  const firstName = userName?.split(' ')?.[0] || 'Prospecteur';

  return (
    <div className="p-5 lg:p-8 space-y-6">
      {/* Greeting */}
      <div>
        <h1 className="text-2xl font-bold text-white">Bonjour, {firstName} 👋</h1>
        <div className="flex items-center gap-4 mt-1">
          <div className="flex items-center gap-1 text-xs text-[#A0AEC0]">
            <Clock size={11} />
            <span>{new Date()?.toLocaleDateString('fr-FR', { weekday: 'long', day: 'numeric', month: 'long' })}</span>
          </div>
        </div>
      </div>

      {/* KPI Cards */}
      <div className="grid grid-cols-2 gap-4">
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-4">
          <div className="flex items-center gap-2 mb-2">
            <ShoppingCart size={16} className="text-[#D4AF37]" />
            <p className="text-xs text-[#A0AEC0]">Ventes aujourd&apos;hui</p>
          </div>
          <p className="text-2xl font-bold text-white">{loading ? '—' : salesCount}</p>
        </div>
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-4">
          <div className="flex items-center gap-2 mb-2">
            <Wallet size={16} className="text-[#D4AF37]" />
            <p className="text-xs text-[#A0AEC0]">Encaissé aujourd&apos;hui</p>
          </div>
          <p className="text-2xl font-bold text-[#D4AF37]">
            {loading ? '—' : new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 })?.format(totalAmount / 100)}
          </p>
        </div>
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-4 col-span-2">
          <div className="flex items-center gap-2 mb-2">
            <Users size={16} className="text-[#63B3ED]" />
            <p className="text-xs text-[#A0AEC0]">Mes prospects</p>
          </div>
          <p className="text-2xl font-bold text-[#63B3ED]">{loading ? '—' : prospectsCount}</p>
        </div>
      </div>

      {/* Quick Actions */}
      <div className="grid grid-cols-2 gap-3">
        <button
          onClick={() => setSaleModalOpen(true)}
          className="flex flex-col items-center gap-2 p-4 bg-[#D4AF37]/10 border border-[#D4AF37]/30 rounded-2xl hover:bg-[#D4AF37]/20 transition-all"
        >
          <Plus size={20} className="text-[#D4AF37]" />
          <span className="text-sm font-semibold text-white">Nouvelle vente</span>
        </button>
        <Link
          href="/terrain/dashboard/prospects"
          className="flex flex-col items-center gap-2 p-4 bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl hover:bg-[#0A1628] transition-all"
        >
          <Users size={20} className="text-[#63B3ED]" />
          <span className="text-sm font-semibold text-white">Mes prospects</span>
        </Link>
      </div>

      {/* Navigation links */}
      <div className="space-y-2">
        <Link href="/terrain/dashboard/ventes" className="flex items-center justify-between p-4 bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl hover:bg-[#0A1628] transition-all">
          <div className="flex items-center gap-3">
            <ShoppingCart size={16} className="text-[#D4AF37]" />
            <span className="text-sm font-medium text-white">Mes ventes</span>
          </div>
          <span className="text-xs text-[#718096]">→</span>
        </Link>
        <Link href="/terrain/dashboard/commission" className="flex items-center justify-between p-4 bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl hover:bg-[#0A1628] transition-all">
          <div className="flex items-center gap-3">
            <TrendingUp size={16} className="text-[#D4AF37]" />
            <span className="text-sm font-medium text-white">Ma commission</span>
          </div>
          <span className="text-xs text-[#718096]">→</span>
        </Link>
      </div>

      {/* Quick Sale Modal */}
      <Modal open={saleModalOpen} onClose={() => setSaleModalOpen(false)} title="Enregistrer une vente" size="md">
        <form
          onSubmit={async e => {
            e?.preventDefault();
            setSubmitError('');
            const oid = orgIdRef.current;
            const pid = prospecteurIdRef.current;
            if (!oid || !pid) { setSubmitError('Compte prospecteur introuvable'); return; }
            const article = articles.find(a => a.id === newSaleForm.article_id);
            if (!newSaleForm.client_id) { setSubmitError('Choisissez un client'); return; }
            if (!article) { setSubmitError('Choisissez un article'); return; }
            if (newSaleForm.unit_price <= 0) { setSubmitError('Le prix doit être supérieur à 0'); return; }
            setSubmitting(true);
            const total = newSaleForm.unit_price * newSaleForm.quantity;
            const credit = newSaleForm.sale_type === 'credit';
            const { data, error } = await createSale({
              organization_id: oid,
              prospecteur_id: pid,
              client_id: newSaleForm.client_id,
              article_id: article.id as string,
              quantity: newSaleForm.quantity,
              sale_type: newSaleForm.sale_type,
              fixed_price: Number(article.fixed_price) || newSaleForm.unit_price,
              cash_price: credit ? Number(article.cash_price) || newSaleForm.unit_price : newSaleForm.unit_price,
              credit_price: credit ? newSaleForm.unit_price : Number(article.credit_price) || newSaleForm.unit_price,
              amount_paid: credit ? Math.min(newSaleForm.amount_paid, total) : total,
              status: 'active',
            });
            setSubmitting(false);
            if (error || !data) { setSubmitError(error?.message ?? 'Vente non enregistrée'); return; }
            setSaleModalOpen(false);
            setNewSaleForm({ client_id: '', article_id: '', sale_type: 'cash', quantity: 1, unit_price: 0, amount_paid: 0 });
            loadKPIs(oid, pid);
          }}
          className="space-y-4 p-1"
        >
          {submitError && <div className="p-3 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-sm">{submitError}</div>}
          <div>
            <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Client</label>
            <select
              value={newSaleForm.client_id}
              onChange={e => setNewSaleForm(f => ({ ...f, client_id: e.target.value }))}
              required
              className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
            >
              <option value="">Choisir un client…</option>
              {clients.map(c => <option key={c.id as string} value={c.id as string}>{c.full_name as string}</option>)}
            </select>
            {clients.length === 0 && <p className="text-xs text-[#718096] mt-1">Aucun client. Convertissez d&apos;abord un prospect.</p>}
          </div>
          <div>
            <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Article</label>
            <select
              value={newSaleForm.article_id}
              onChange={e => {
                const a = articles.find(x => x.id === e.target.value);
                setNewSaleForm(f => ({
                  ...f,
                  article_id: e.target.value,
                  unit_price: a ? (f.sale_type === 'credit' ? Number(a.credit_price) || Number(a.fixed_price) : Number(a.cash_price) || Number(a.fixed_price)) || 0 : 0,
                }));
              }}
              required
              className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
            >
              <option value="">Choisir un article…</option>
              {articles.map(a => <option key={a.id as string} value={a.id as string}>{a.name as string}</option>)}
            </select>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Type</label>
              <select
                value={newSaleForm.sale_type}
                onChange={e => {
                  const a = articles.find(x => x.id === newSaleForm.article_id);
                  const t = e.target.value;
                  setNewSaleForm(f => ({ ...f, sale_type: t, unit_price: a ? (t === 'credit' ? Number(a.credit_price) || Number(a.fixed_price) : Number(a.cash_price) || Number(a.fixed_price)) || f.unit_price : f.unit_price }));
                }}
                className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none"
              >
                <option value="cash">Comptant</option>
                <option value="credit">À crédit</option>
              </select>
            </div>
            <div>
              <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Quantité</label>
              <input type="number" min={1} value={newSaleForm.quantity}
                onChange={e => setNewSaleForm(f => ({ ...f, quantity: Math.max(1, parseInt(e.target.value) || 1) }))}
                className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none" />
            </div>
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Prix unitaire (XOF)</label>
              <input type="number" min={0} value={newSaleForm.unit_price}
                onChange={e => setNewSaleForm(f => ({ ...f, unit_price: Math.max(0, parseInt(e.target.value) || 0) }))}
                className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none" />
            </div>
            {newSaleForm.sale_type === 'credit' && (
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Acompte (XOF)</label>
                <input type="number" min={0} value={newSaleForm.amount_paid}
                  onChange={e => setNewSaleForm(f => ({ ...f, amount_paid: Math.max(0, parseInt(e.target.value) || 0) }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none" />
              </div>
            )}
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={() => setSaleModalOpen(false)} className="flex-1 py-2.5 rounded-xl border border-[#D4AF37]/20 text-[#A0AEC0] text-sm">Annuler</button>
            <button type="submit" disabled={submitting} className="flex-1 btn-gold py-2.5 rounded-xl font-semibold text-sm disabled:opacity-60">
              {submitting ? 'Enregistrement...' : 'Enregistrer'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
