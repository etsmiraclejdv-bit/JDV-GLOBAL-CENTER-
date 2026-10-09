'use client';
import React, { useCallback, useEffect, useState } from 'react';
import Link from 'next/link';
import { UserCheck, Plus, Search, Phone } from 'lucide-react';
import { toast } from 'sonner';
import Modal from '@/components/ui/Modal';
import { fetchOrgProfile } from '@/lib/auth/context';
import { fetchClients, createClient } from '@/lib/services/clientsService';
import { getMyPortfolioId } from '@/lib/services/portfolioService';

type Row = Record<string, unknown>;

const fmt = (cents: number) =>
  new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(cents / 100);

const STATUS: Record<string, { label: string; cls: string }> = {
  a_jour: { label: 'À jour', cls: 'bg-green-500/15 text-green-400 border-green-500/30' },
  a_surveiller: { label: 'À surveiller', cls: 'bg-yellow-500/15 text-yellow-400 border-yellow-500/30' },
  en_retard: { label: 'En retard', cls: 'bg-red-500/15 text-red-400 border-red-500/30' },
};

const inputCls =
  'w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60';

export default function TerrainClientsPage() {
  const [orgId, setOrgId] = useState<string | null>(null);
  const [pid, setPid] = useState<string | null>(null);
  const [clients, setClients] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [open, setOpen] = useState(false);
  const [saving, setSaving] = useState(false);
  const [form, setForm] = useState({ full_name: '', phone: '', city: '', address: '' });

  const load = useCallback(async (oid: string, prospecteurId: string) => {
    const { data } = await fetchClients(oid, { assignedTo: prospecteurId });
    setClients((data ?? []) as Row[]);
    setLoading(false);
  }, []);

  useEffect(() => {
    (async () => {
      const { data: profile } = await fetchOrgProfile();
      if (profile?.organization_id && profile.prospecteur_id) {
        setOrgId(profile.organization_id);
        setPid(profile.prospecteur_id);
        load(profile.organization_id, profile.prospecteur_id);
      } else {
        setLoading(false);
      }
    })();
  }, [load]);

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    if (!orgId || !pid) return;
    if (!form.full_name.trim()) return toast.error('Le nom est requis');
    setSaving(true);
    const pf = await getMyPortfolioId(orgId);
    if (!pf.id) {
      setSaving(false);
      return toast.error(pf.error ?? 'Portefeuille introuvable');
    }
    const { error } = await createClient({
      organization_id: orgId,
      assigned_to: pid,
      portfolio_id: pf.id,
      full_name: form.full_name,
      phone: form.phone || undefined,
      city: form.city || undefined,
      address: form.address || undefined,
      status: 'active',
    } as never);
    setSaving(false);
    if (error) return toast.error(error.message);
    toast.success('Client ajouté');
    setOpen(false);
    setForm({ full_name: '', phone: '', city: '', address: '' });
    load(orgId, pid);
  }

  const filtered = clients.filter(
    (c) =>
      String(c.full_name ?? '').toLowerCase().includes(search.toLowerCase()) ||
      String(c.phone ?? '').includes(search)
  );

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Mes clients</h1>
          <p className="text-sm text-[#A0AEC0] mt-1">{clients.length} client{clients.length !== 1 ? 's' : ''} dans votre portefeuille</p>
        </div>
        <button onClick={() => setOpen(true)} className="flex items-center gap-2 btn-gold px-4 py-2.5 rounded-xl text-sm font-bold">
          <Plus size={14} />
          Nouveau client
        </button>
      </div>

      <div className="relative max-w-sm">
        <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#718096]" />
        <input
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Rechercher un client..."
          className="w-full bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm placeholder-[#718096] focus:outline-none focus:border-[#D4AF37]/60"
        />
      </div>

      {loading ? (
        <div className="py-16 text-center text-[#A0AEC0] text-sm">Chargement...</div>
      ) : !pid ? (
        <div className="py-16 text-center text-red-400 text-sm">Accès réservé aux prospecteurs.</div>
      ) : filtered.length === 0 ? (
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl py-16 text-center">
          <UserCheck size={32} className="mx-auto mb-3 text-[#718096] opacity-50" />
          <p className="text-[#A0AEC0] text-sm">Aucun client pour l’instant</p>
          <p className="text-xs text-[#718096] mt-1">
            Ajoutez un client ou <Link href="/terrain/dashboard/prospects" className="text-[#D4AF37] hover:underline">convertissez un prospect</Link>.
          </p>
        </div>
      ) : (
        <div className="grid grid-cols-1 md:grid-cols-2 gap-3">
          {filtered.map((c) => {
            const st = STATUS[c.payment_status as string] ?? STATUS.a_jour;
            return (
              <div key={c.id as string} className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-4 space-y-2">
                <div className="flex items-start justify-between gap-3">
                  <div>
                    <p className="text-sm font-semibold text-white">{c.full_name as string}</p>
                    <p className="text-xs text-[#718096]">{[c.city, c.code].filter(Boolean).join(' — ')}</p>
                  </div>
                  <span className={`text-xs px-2 py-1 rounded-lg border ${st.cls}`}>{st.label}</span>
                </div>
                <div className="flex items-center justify-between text-sm">
                  <span className="text-[#A0AEC0]">Reste à payer</span>
                  <span className="font-bold text-[#D4AF37]">{fmt(Number(c.balance_cents) || 0)}</span>
                </div>
                {c.phone ? (
                  <a href={`tel:${c.phone as string}`} className="inline-flex items-center gap-1.5 text-xs text-blue-400 hover:underline">
                    <Phone size={12} /> {c.phone as string}
                  </a>
                ) : null}
              </div>
            );
          })}
        </div>
      )}

      <Modal open={open} onClose={() => setOpen(false)} title="Nouveau client" size="md">
        <form onSubmit={handleCreate} className="space-y-4 p-1">
          <div>
            <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Nom complet *</label>
            <input required value={form.full_name} onChange={(e) => setForm((f) => ({ ...f, full_name: e.target.value }))} className={inputCls} />
          </div>
          <div className="grid grid-cols-2 gap-3">
            <div>
              <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Téléphone</label>
              <input value={form.phone} onChange={(e) => setForm((f) => ({ ...f, phone: e.target.value }))} className={inputCls} />
            </div>
            <div>
              <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Ville</label>
              <input value={form.city} onChange={(e) => setForm((f) => ({ ...f, city: e.target.value }))} className={inputCls} />
            </div>
          </div>
          <div>
            <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Adresse</label>
            <input value={form.address} onChange={(e) => setForm((f) => ({ ...f, address: e.target.value }))} className={inputCls} />
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={() => setOpen(false)} className="flex-1 py-2.5 rounded-xl border border-[#D4AF37]/20 text-[#A0AEC0] text-sm hover:text-white transition-colors">Annuler</button>
            <button type="submit" disabled={saving} className="flex-1 btn-gold py-2.5 rounded-xl font-semibold text-sm disabled:opacity-60">{saving ? 'Enregistrement...' : 'Enregistrer'}</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
