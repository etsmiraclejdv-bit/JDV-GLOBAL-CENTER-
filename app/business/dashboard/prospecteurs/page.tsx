'use client';
import React, { useState, useEffect } from 'react';
import { Users, Search, RefreshCw, ShoppingCart, Plus, Eye, EyeOff } from 'lucide-react';
import { toast } from 'sonner';
import Modal from '@/components/ui/Modal';
import { supabase } from '@/lib/supabase/client';
import { getAuthContext } from '@/lib/auth/context';
import { personName, saleTotal, toCents } from '@/lib/services/compat';

interface ProspecteurRow {
  id: string;
  full_name: string;
  phone: string | null;
  city: string | null;
  created_at: string;
  sales_count?: number;
  sales_amount?: number;
}

export default function BusinessProspecteursPage() {
  const [prospecteurs, setProspecteurs] = useState<ProspecteurRow[]>([]);
  const [warehouses, setWarehouses] = useState<{id:string;name:string;code:string;city:string|null}[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [orgId, setOrgId] = useState<string | null>(null);
  const [orgName, setOrgName] = useState('');
  const [modalOpen, setModalOpen] = useState(false);
  const [submitting, setSubmitting] = useState(false);
  const [showPwd, setShowPwd] = useState(false);
  const emptyForm = { firstName: '', lastName: '', email: '', phone: '', password: '', commissionRate: 10, warehouseId: '', department: '', workCity: '', workZone: '' };
  const [form, setForm] = useState(emptyForm);

  useEffect(() => {
    supabase.auth.getUser().then(async ({ data }) => {
      if (!data.user) return;
      const ctx = await getAuthContext();
      const resolvedOrgId = ctx?.organizationId ?? null;
      if (resolvedOrgId) {
        setOrgId(resolvedOrgId);
        loadProspecteurs(resolvedOrgId);
        supabase.from('warehouses').select('id,name,code,city').eq('organization_id', resolvedOrgId).eq('active', true).order('name').then(({ data }) => setWarehouses((data ?? []) as {id:string;name:string;code:string;city:string|null}[]));
        supabase.from('organizations').select('name').eq('id', resolvedOrgId).maybeSingle().then(({ data: o }) => {
          setOrgName(((o as { name?: string } | null)?.name) ?? '');
        });
      } else {
        setLoading(false);
      }
    });
  }, []);

  async function loadProspecteurs(oid: string) {
    setLoading(true);
    const { data: rows } = await supabase
      .from('prospecteurs')
      .select('id, first_name, last_name, phone, city, created_at')
      .eq('organization_id', oid)
      .order('created_at', { ascending: false });

    if (!rows || rows.length === 0) {
      setProspecteurs([]);
      setLoading(false);
      return;
    }

    const profiles = (rows as Record<string, unknown>[]).map(r => ({
      id: r.id as string,
      full_name: personName(r as never) || 'Sans nom',
      phone: (r.phone as string) ?? null,
      city: (r.city as string) ?? null,
      created_at: r.created_at as string,
    }));
    const ids = profiles.map(p => p.id);

    const { data: salesRows } = await supabase
      .from('sales')
      .select('prospecteur_id, sale_type, cash_price, credit_price, fixed_price, quantity')
      .eq('organization_id', oid)
      .in('prospecteur_id', ids);
    const salesRes = { data: salesRows };

    const salesCountMap: Record<string, number> = {};
    const salesAmountMap: Record<string, number> = {};
    ((salesRes.data ?? []) as Record<string, unknown>[]).forEach(s => {
      const pid = s.prospecteur_id as string | null;
      if (pid) {
        salesCountMap[pid] = (salesCountMap[pid] ?? 0) + 1;
        salesAmountMap[pid] = (salesAmountMap[pid] ?? 0) + toCents(saleTotal(s as never));
      }
    });

    setProspecteurs(profiles.map(p => ({
      ...p,
      sales_count: salesCountMap[p.id] ?? 0,
      sales_amount: salesAmountMap[p.id] ?? 0,
    })));
    setLoading(false);
  }

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    if (!orgId) return;
    setSubmitting(true);
    try {
      const { data: sess } = await supabase.auth.getSession();
      const token = sess.session?.access_token;
      if (!token) {
        toast.error('Session expirée, reconnectez-vous');
        return;
      }
      const res = await fetch('/api/business/create-prospecteur', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${token}` },
        body: JSON.stringify({ ...form, organizationId: orgId, organizationName: orgName }),
      });
      const json = await res.json().catch(() => ({}));
      if (!res.ok) {
        toast.error(json.error ?? 'Création impossible');
        return;
      }
      toast.success(`Prospecteur créé (${json.code ?? 'code généré'}). Communiquez-lui son mot de passe de vive voix ou par un canal sûr : il n'est jamais envoyé par email.`, { duration: 9000 });
      setModalOpen(false);
      setForm(emptyForm);
      loadProspecteurs(orgId);
    } finally {
      setSubmitting(false);
    }
  }

  const filtered = prospecteurs.filter(p =>
    !search ||
    p.full_name.toLowerCase().includes(search.toLowerCase()) ||
    (p.phone ?? '').includes(search)
  );

  const fmt = (cents: number) =>
    new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(cents / 100);

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Prospecteurs</h1>
          <p className="text-sm text-[#A0AEC0] mt-1">{prospecteurs.length} prospecteur{prospecteurs.length !== 1 ? 's' : ''}</p>
        </div>
        <div className="flex items-center gap-2">
          <button onClick={() => orgId && loadProspecteurs(orgId)} className="flex items-center gap-2 px-4 py-2 rounded-xl border border-[#D4AF37]/20 text-[#A0AEC0] hover:text-white text-sm transition-colors">
            <RefreshCw size={14} />
            Actualiser
          </button>
          <button onClick={() => setModalOpen(true)} className="flex items-center gap-2 btn-gold px-4 py-2 rounded-xl text-sm font-bold">
            <Plus size={14} />
            Nouveau prospecteur
          </button>
        </div>
      </div>

      <div className="relative max-w-sm">
        <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#718096]" />
        <input
          type="text"
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Rechercher un prospecteur..."
          className="w-full bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm placeholder-[#718096] focus:outline-none focus:border-[#D4AF37]/60"
        />
      </div>

      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
        {loading ? (
          <div className="py-16 text-center text-[#A0AEC0] text-sm">Chargement...</div>
        ) : filtered.length === 0 ? (
          <div className="py-16 text-center">
            <Users size={32} className="mx-auto mb-3 text-[#718096] opacity-50" />
            <p className="text-[#A0AEC0] text-sm">Aucun prospecteur trouvé</p>
            <p className="text-xs text-[#718096] mt-1">Cliquez sur « Nouveau prospecteur » pour créer un compte terrain</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[#D4AF37]/10">
                  <th className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase">Prospecteur</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase">Téléphone</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase">Ventes</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase">CA généré</th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(p => (
                  <tr key={p.id} className="border-b border-[#D4AF37]/5 hover:bg-[#0A1628]/40 transition-colors">
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-[#D4AF37]/10 flex items-center justify-center text-[#D4AF37] text-xs font-bold">
                          {p.full_name.charAt(0).toUpperCase()}
                        </div>
                        <div>
                          <p className="text-sm font-medium text-white">{p.full_name}</p>
                          {p.city && <p className="text-xs text-[#718096]">{p.city}</p>}
                        </div>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm text-[#A0AEC0]">{p.phone ?? '—'}</td>
                    <td className="px-4 py-3">
                      <div className="flex items-center gap-1.5">
                        <ShoppingCart size={12} className="text-[#D4AF37]" />
                        <span className="text-sm font-semibold text-white">{p.sales_count ?? 0}</span>
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm font-semibold text-[#D4AF37]">
                      {fmt(p.sales_amount ?? 0)}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title="Nouveau prospecteur" size="md">
        <form onSubmit={handleCreate} className="space-y-4 p-1">
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Prénom *</label>
              <input required value={form.firstName} onChange={e => setForm(f => ({ ...f, firstName: e.target.value }))}
                className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60" />
            </div>
            <div>
              <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Nom</label>
              <input value={form.lastName} onChange={e => setForm(f => ({ ...f, lastName: e.target.value }))}
                className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60" />
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Email de connexion *</label>
            <input required type="email" value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))}
              className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60" />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Téléphone</label>
              <input value={form.phone} onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
                className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60" />
            </div>
            <div>
              <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Commission (%)</label>
              <input type="number" min={0} max={100} step="0.5" value={form.commissionRate}
                onChange={e => setForm(f => ({ ...f, commissionRate: Math.min(100, Math.max(0, Number(e.target.value) || 0)) }))}
                className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60" />
            </div>
          </div>
          <div className="space-y-3 rounded-xl border border-[#D4AF37]/10 p-4">
            <p className="text-xs font-semibold text-[#D4AF37]">Affectation terrain (définie par l’administrateur)</p>
            <select value={form.warehouseId} onChange={e => setForm(f => ({ ...f, warehouseId: e.target.value }))} className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm">
              <option value="">Aucun entrepôt pour le moment</option>
              {warehouses.map(w => <option key={w.id} value={w.id}>{w.name} — {w.code}{w.city ? ` — ${w.city}` : ''}</option>)}
            </select>
            <div className="grid grid-cols-3 gap-3">
              <input placeholder="Département" value={form.department} onChange={e => setForm(f => ({ ...f, department: e.target.value }))} className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm" />
              <input placeholder="Ville de travail" value={form.workCity} onChange={e => setForm(f => ({ ...f, workCity: e.target.value }))} className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm" />
              <input placeholder="Zone / secteur" value={form.workZone} onChange={e => setForm(f => ({ ...f, workZone: e.target.value }))} className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm" />
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Mot de passe provisoire * (8 caractères minimum)</label>
            <div className="relative">
              <input required minLength={8} type={showPwd ? 'text' : 'password'} value={form.password}
                onChange={e => setForm(f => ({ ...f, password: e.target.value }))}
                className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 pr-10 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60" />
              <button type="button" onClick={() => setShowPwd(v => !v)} className="absolute right-3 top-1/2 -translate-y-1/2 text-[#718096] hover:text-white">
                {showPwd ? <EyeOff size={14} /> : <Eye size={14} />}
              </button>
            </div>
            <p className="text-xs text-[#718096] mt-1">Les identifiants sont envoyés par email au prospecteur.</p>
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={() => setModalOpen(false)} className="flex-1 py-2.5 rounded-xl border border-[#D4AF37]/20 text-[#A0AEC0] text-sm hover:text-white transition-colors">Annuler</button>
            <button type="submit" disabled={submitting} className="flex-1 btn-gold py-2.5 rounded-xl font-semibold text-sm disabled:opacity-60">
              {submitting ? 'Création...' : 'Créer le compte'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
