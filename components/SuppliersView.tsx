'use client';
import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Edit2, Plus, RefreshCw, Search, Truck } from 'lucide-react';
import { toast } from 'sonner';
import { getAdminOrganization } from '@/lib/auth/admin-org';
import { fetchSupplierBalances, fetchSuppliers, saveSupplier, type Supplier, type SupplierInput } from '@/lib/services/purchasesService';
import { SUPPLIER_STATUS_LABELS } from '@/lib/purchases/helpers';
import { formatXof } from '@/lib/relances/helpers';
import { inputClass, labelClass } from '@/lib/ui/forms';
import Modal from '@/components/ui/Modal';
import LoadingState from '@/components/ui/LoadingState';
import ErrorState from '@/components/ui/ErrorState';

interface FormState {
  company_name: string;
  contact_name: string;
  phone: string;
  whatsapp: string;
  email: string;
  address: string;
  city: string;
  country: string;
  payment_terms: string;
  notes: string;
  status: string;
}

const EMPTY_FORM: FormState = {
  company_name: '',
  contact_name: '',
  phone: '',
  whatsapp: '',
  email: '',
  address: '',
  city: '',
  country: '',
  payment_terms: '',
  notes: '',
  status: 'active',
};

const STATUS_CLASSES: Record<string, string> = {
  active: 'bg-green-500/20 text-green-400 border-green-500/30',
  inactive: 'bg-gray-500/20 text-gray-300 border-gray-500/30',
  blocked: 'bg-red-500/20 text-red-400 border-red-500/30',
};

const orNull = (v: string): string | null => (v.trim() === '' ? null : v.trim());

function toInput(f: FormState): SupplierInput {
  return {
    company_name: f.company_name.trim(),
    contact_name: orNull(f.contact_name),
    phone: orNull(f.phone),
    whatsapp: orNull(f.whatsapp),
    email: orNull(f.email),
    address: orNull(f.address),
    city: orNull(f.city),
    country: orNull(f.country),
    payment_terms: orNull(f.payment_terms),
    notes: orNull(f.notes),
    status: f.status,
  };
}

export default function SuppliersView() {
  const [orgId, setOrgId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [suppliers, setSuppliers] = useState<Supplier[]>([]);
  const [balances, setBalances] = useState<Record<string, number>>({});
  const [search, setSearch] = useState('');
  const [open, setOpen] = useState(false);
  const [editing, setEditing] = useState<Supplier | null>(null);
  const [form, setForm] = useState<FormState>(EMPTY_FORM);
  const [formError, setFormError] = useState('');
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    const { orgId: org, error: guardError } = await getAdminOrganization();
    if (!org) {
      setError(guardError ?? 'Accès impossible.');
      setLoading(false);
      return;
    }
    setOrgId(org);
    const [s, b] = await Promise.all([fetchSuppliers(org), fetchSupplierBalances(org)]);
    if (s.error || b.error) setError(s.error || b.error || '');
    setSuppliers(s.data);
    setBalances(b.data);
    setLoading(false);
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const visible = useMemo(() => {
    const q = search.trim().toLowerCase();
    if (!q) return suppliers;
    const qDigits = q.replace(/\D/g, '');
    return suppliers.filter(
      (s) =>
        s.company_name.toLowerCase().includes(q) ||
        s.code.toLowerCase().includes(q) ||
        (s.contact_name ?? '').toLowerCase().includes(q) ||
        (qDigits.length >= 3 && (s.phone ?? '').replace(/\D/g, '').includes(qDigits))
    );
  }, [suppliers, search]);

  function openCreate() {
    setEditing(null);
    setForm(EMPTY_FORM);
    setFormError('');
    setOpen(true);
  }

  function openEdit(s: Supplier) {
    setEditing(s);
    setForm({
      company_name: s.company_name,
      contact_name: s.contact_name ?? '',
      phone: s.phone ?? '',
      whatsapp: s.whatsapp ?? '',
      email: s.email ?? '',
      address: s.address ?? '',
      city: s.city ?? '',
      country: s.country ?? '',
      payment_terms: s.payment_terms ?? '',
      notes: s.notes ?? '',
      status: s.status,
    });
    setFormError('');
    setOpen(true);
  }

  const set = (key: keyof FormState) => (e: React.ChangeEvent<HTMLInputElement | HTMLTextAreaElement | HTMLSelectElement>) =>
    setForm((prev) => ({ ...prev, [key]: e.target.value }));

  async function handleSave() {
    if (!orgId || saving) return;
    if (form.company_name.trim().length < 2) {
      setFormError('Le nom du fournisseur est obligatoire.');
      return;
    }
    if (form.email.trim() !== '' && !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(form.email.trim())) {
      setFormError("L'adresse email n'est pas valide.");
      return;
    }
    setSaving(true);
    const { error: err } = await saveSupplier(orgId, toInput(form), editing?.id);
    setSaving(false);
    if (err) {
      setFormError(err);
      return;
    }
    toast.success(editing ? 'Fournisseur modifié.' : 'Fournisseur ajouté.');
    setOpen(false);
    void load();
  }

  if (loading && suppliers.length === 0 && !error) return <LoadingState message="Chargement des fournisseurs…" />;
  if (error && suppliers.length === 0) {
    return <ErrorState message={error} action={{ label: 'Réessayer', onClick: () => void load() }} />;
  }

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-white">Fournisseurs</h1>
          <p className="text-sm text-[#A0AEC0] mt-1">{suppliers.length} fournisseur(s) enregistré(s)</p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => void load()}
            disabled={loading}
            aria-label="Actualiser la liste"
            className="flex items-center gap-2 btn-outline-gold px-4 py-2.5 rounded-xl text-sm font-semibold disabled:opacity-50"
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
            Actualiser
          </button>
          <button onClick={openCreate} className="flex items-center gap-2 btn-gold px-4 py-2.5 rounded-xl text-sm font-bold">
            <Plus size={14} />
            Nouveau fournisseur
          </button>
        </div>
      </div>

      {error && (
        <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300" role="alert">
          {error}
        </div>
      )}

      <div className="relative">
        <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#718096]" />
        <input
          type="text"
          value={search}
          onChange={(e) => setSearch(e.target.value)}
          placeholder="Rechercher par nom, code, contact ou téléphone…"
          aria-label="Rechercher un fournisseur"
          className="w-full bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm placeholder-[#718096] focus:outline-none focus:border-[#D4AF37]/60"
        />
      </div>

      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
        {visible.length === 0 ? (
          <div className="py-16 text-center px-6">
            <Truck size={32} className="mx-auto mb-3 text-[#D4AF37] opacity-60" />
            <p className="text-white text-sm font-semibold mb-1">
              {suppliers.length === 0 ? 'Aucun fournisseur' : 'Aucun résultat'}
            </p>
            <p className="text-[#A0AEC0] text-sm">
              {suppliers.length === 0
                ? 'Ajoutez votre premier fournisseur pour pouvoir passer des commandes.'
                : 'Modifiez votre recherche.'}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[#D4AF37]/10">
                  {['Code', 'Fournisseur', 'Téléphone', 'Ville', 'Solde dû', 'Statut', ''].map((h, i) => (
                    <th key={i} className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider whitespace-nowrap">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {visible.map((s) => (
                  <tr key={s.id} className="border-b border-[#D4AF37]/5 hover:bg-[#0B1B3D]/50">
                    <td className="px-4 py-3 text-sm text-[#A0AEC0] whitespace-nowrap">{s.code}</td>
                    <td className="px-4 py-3">
                      <p className="text-sm font-medium text-white">{s.company_name}</p>
                      {s.contact_name && <p className="text-xs text-[#718096]">{s.contact_name}</p>}
                    </td>
                    <td className="px-4 py-3 text-sm text-[#A0AEC0] whitespace-nowrap">{s.phone || '—'}</td>
                    <td className="px-4 py-3 text-sm text-[#A0AEC0] whitespace-nowrap">{s.city || '—'}</td>
                    <td className="px-4 py-3 text-sm whitespace-nowrap">
                      {(balances[s.id] ?? 0) > 0 ? (
                        <span className="font-semibold text-[#F6AD55]">{formatXof(balances[s.id])}</span>
                      ) : (
                        <span className="text-[#718096]">—</span>
                      )}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap">
                      <span className={`inline-flex text-xs font-semibold px-2.5 py-1 rounded-full border ${STATUS_CLASSES[s.status] ?? STATUS_CLASSES.inactive}`}>
                        {SUPPLIER_STATUS_LABELS[s.status] ?? s.status}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <button
                        onClick={() => openEdit(s)}
                        aria-label={`Modifier ${s.company_name}`}
                        className="p-2 rounded-lg bg-[#0B1B3D] border border-[#D4AF37]/20 text-[#D4AF37] hover:bg-[#D4AF37]/10"
                      >
                        <Edit2 size={14} />
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <Modal open={open} onClose={() => !saving && setOpen(false)} title={editing ? `Modifier ${editing.code}` : 'Nouveau fournisseur'} size="xl">
        <div className="space-y-4">
          {formError && (
            <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300" role="alert">
              {formError}
            </div>
          )}
          <div>
            <label className={labelClass} htmlFor="sup-name">Nom du fournisseur *</label>
            <input id="sup-name" value={form.company_name} onChange={set('company_name')} maxLength={200} className={inputClass} />
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className={labelClass} htmlFor="sup-contact">Personne à contacter</label>
              <input id="sup-contact" value={form.contact_name} onChange={set('contact_name')} maxLength={200} className={inputClass} />
            </div>
            <div>
              <label className={labelClass} htmlFor="sup-email">Email</label>
              <input id="sup-email" type="email" value={form.email} onChange={set('email')} maxLength={254} className={inputClass} />
            </div>
            <div>
              <label className={labelClass} htmlFor="sup-phone">Téléphone</label>
              <input id="sup-phone" value={form.phone} onChange={set('phone')} maxLength={40} className={inputClass} />
            </div>
            <div>
              <label className={labelClass} htmlFor="sup-wa">WhatsApp</label>
              <input id="sup-wa" value={form.whatsapp} onChange={set('whatsapp')} maxLength={40} className={inputClass} />
            </div>
            <div>
              <label className={labelClass} htmlFor="sup-city">Ville</label>
              <input id="sup-city" value={form.city} onChange={set('city')} maxLength={120} className={inputClass} />
            </div>
            <div>
              <label className={labelClass} htmlFor="sup-country">Pays</label>
              <input id="sup-country" value={form.country} onChange={set('country')} maxLength={120} className={inputClass} />
            </div>
          </div>
          <div>
            <label className={labelClass} htmlFor="sup-address">Adresse</label>
            <input id="sup-address" value={form.address} onChange={set('address')} maxLength={300} className={inputClass} />
          </div>
          <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
            <div>
              <label className={labelClass} htmlFor="sup-terms">Conditions de paiement</label>
              <input id="sup-terms" value={form.payment_terms} onChange={set('payment_terms')} maxLength={200} placeholder="ex. 30 jours" className={inputClass} />
            </div>
            <div>
              <label className={labelClass} htmlFor="sup-status">Statut</label>
              <select id="sup-status" value={form.status} onChange={set('status')} className={inputClass}>
                {Object.entries(SUPPLIER_STATUS_LABELS).map(([v, l]) => (
                  <option key={v} value={v}>{l}</option>
                ))}
              </select>
            </div>
          </div>
          <div>
            <label className={labelClass} htmlFor="sup-notes">Notes</label>
            <textarea id="sup-notes" value={form.notes} onChange={set('notes')} maxLength={1000} rows={3} className={inputClass} />
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <button
              onClick={() => setOpen(false)}
              disabled={saving}
              className="px-4 py-2.5 rounded-xl text-sm font-semibold bg-[#0B1B3D] text-[#A0AEC0] border border-[#D4AF37]/20 hover:text-white disabled:opacity-50"
            >
              Annuler
            </button>
            <button
              onClick={() => void handleSave()}
              disabled={saving}
              className="btn-gold px-5 py-2.5 rounded-xl text-sm font-bold disabled:opacity-50"
            >
              {saving ? 'Enregistrement…' : 'Enregistrer'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
