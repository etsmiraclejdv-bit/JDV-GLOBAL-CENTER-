'use client';
import React, { useState, useEffect } from 'react';
import { Users, Plus, Search, Phone, UserCheck, MessageCircle, Calendar, ChevronDown, ChevronUp, Filter } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import Modal from '@/components/ui/Modal';
import { toast } from 'sonner';
import { fetchOrgProfile } from '@/lib/auth/context';
import { getMyPortfolioId, convertProspectToClient } from '@/lib/services/portfolioService';

interface Prospect {
  id: string;
  full_name: string;
  phone?: string;
  phone2?: string;
  address?: string;
  city?: string;
  quartier?: string;
  lieu_rencontre?: string;
  notes?: string;
  desired_product?: string;
  desired_quantity?: number;
  proposed_price?: number;
  interest_level?: string;
  temperature?: string;
  next_contact_date?: string;
  appointment_date?: string;
  appointment_time?: string;
  appointment_location?: string;
  is_prospect?: boolean;
  created_at: string;
}

const TEMP_COLORS: Record<string, string> = {
  hot: 'bg-[#FC8181]/20 text-[#FC8181] border-[#FC8181]/30',
  warm: 'bg-[#F6E05E]/20 text-[#F6E05E] border-[#F6E05E]/30',
  cold: 'bg-[#63B3ED]/20 text-[#63B3ED] border-[#63B3ED]/30',
};

const TEMP_LABELS: Record<string, string> = { hot: 'Chaud', warm: 'Tiède', cold: 'Froid' };

const INTEREST_LABELS: Record<string, string> = { low: 'Faible', medium: 'Moyen', high: 'Élevé' };

type FilterType = 'all' | 'hot' | 'warm' | 'cold' | 'today' | 'appointment_today' | 'no_contact';

export default function TerrainProspectsPage() {
  const [prospects, setProspects] = useState<Prospect[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [filter, setFilter] = useState<FilterType>('all');
  const [modalOpen, setModalOpen] = useState(false);
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [form, setForm] = useState({
    full_name: '', phone: '', phone2: '', address: '', city: '', quartier: '',
    lieu_rencontre: '', notes: '', desired_product: '', desired_quantity: 1,
    proposed_price: 0, interest_level: 'medium', temperature: 'cold',
    next_contact_date: '', appointment_date: '', appointment_time: '',
    appointment_location: '',
  });
  const [submitting, setSubmitting] = useState(false);
  const [orgId, setOrgId] = useState<string | null>(null);
  const [userId, setUserId] = useState<string | null>(null);
  const [orgName, setOrgName] = useState('');
  const [prospecteurName, setProspecteurName] = useState('');

  useEffect(() => {
    supabase.auth.getUser().then(async ({ data }) => {
      if (!data.user) return;
      const { data: profile } = await fetchOrgProfile();
      setUserId(profile?.prospecteur_id ?? null);
      if (profile?.organization_id && profile.prospecteur_id) {
        setOrgId(profile.organization_id);
        setProspecteurName(profile.full_name ?? '');
        const { data: org } = await supabase.from('organizations').select('name').eq('id', profile.organization_id).single();
        if (org) setOrgName(org.name ?? '');
        loadProspects(profile.organization_id, profile.prospecteur_id);
      }
    });
  }, []);

  async function loadProspects(oid: string, pid: string) {
    setLoading(true);
    const { data } = await supabase
      .from('prospects')
      .select('*')
      .eq('organization_id', oid)
      .eq('prospecteur_id', pid)
      .not('status', 'in', '(converted,archived)')
      .order('created_at', { ascending: false });
    setProspects(
      ((data ?? []) as Record<string, unknown>[]).map(r => ({
        id: r.id as string,
        full_name: `${(r.first_name as string) ?? ''} ${(r.last_name as string) ?? ''}`.trim() || 'Sans nom',
        phone: (r.phone as string) ?? undefined,
        city: (r.city as string) ?? undefined,
        address: (r.address as string) ?? undefined,
        notes: (r.notes as string) ?? undefined,
        desired_product: (r.desired_article as string) ?? undefined,
        proposed_price: r.estimated_amount ? Math.round(Number(r.estimated_amount) * 100) : 0,
        temperature: (r.temperature as string) ?? undefined,
        next_contact_date: r.next_follow_up_at ? String(r.next_follow_up_at).split('T')[0] : undefined,
        appointment_date: (r.purchase_date_planned as string) ?? undefined,
        is_prospect: true,
        created_at: r.created_at as string,
      })) as Prospect[]
    );
    setLoading(false);
  }

  async function handleCreate(e: React.FormEvent) {
    e.preventDefault();
    if (!orgId || !userId) return;
    setSubmitting(true);
    const parts = form.full_name.trim().split(/\s+/);
    const first = parts.shift() ?? '';
    const details = [
      form.quartier && `Quartier : ${form.quartier}`,
      form.lieu_rencontre && `Lieu de rencontre : ${form.lieu_rencontre}`,
      form.phone2 && `Second numéro : ${form.phone2}`,
      form.desired_quantity > 1 && `Quantité souhaitée : ${form.desired_quantity}`,
      form.appointment_time && `RDV à ${form.appointment_time}`,
      form.appointment_location && `RDV à : ${form.appointment_location}`,
      form.notes,
    ].filter(Boolean).join('\n');
    const pf = await getMyPortfolioId(orgId);
    if (!pf.id) {
      setSubmitting(false);
      toast.error(pf.error ?? 'Portefeuille introuvable');
      return;
    }
    const { error } = await supabase.from('prospects').insert({
      organization_id: orgId,
      portfolio_id: pf.id,
      prospecteur_id: userId,
      first_name: first,
      last_name: parts.length ? parts.join(' ') : null,
      phone: form.phone || null,
      address: form.address || null,
      city: form.city || null,
      desired_article: form.desired_product || null,
      estimated_amount: form.proposed_price ? Math.round(form.proposed_price) : null,
      temperature: form.temperature,
      next_follow_up_at: form.next_contact_date ? new Date(form.next_contact_date).toISOString() : null,
      purchase_date_planned: form.appointment_date || null,
      notes: details || null,
      status: 'new',
    });
    setSubmitting(false);
    if (error) {
      toast.error(error.message);
    } else {
      toast.success('Prospect ajouté avec succès');
      setModalOpen(false);
      setForm({
        full_name: '', phone: '', phone2: '', address: '', city: '', quartier: '',
        lieu_rencontre: '', notes: '', desired_product: '', desired_quantity: 1,
        proposed_price: 0, interest_level: 'medium', temperature: 'cold',
        next_contact_date: '', appointment_date: '', appointment_time: '',
        appointment_location: '',
      });
      if (orgId && userId) loadProspects(orgId, userId);
    }
  }

  async function handleConvert(prospectId: string) {
    if (!orgId || !userId) return;
    const { error } = await convertProspectToClient(prospectId);
    if (error) {
      toast.error(error);
      return;
    }
    toast.success('Prospect converti en client');
    loadProspects(orgId, userId);
  }

  function handleCall(phone: string) {
    window.location.href = `tel:${phone}`;
  }

  function handleWhatsApp(phone: string, prospect: Prospect) {
    const cleanPhone = phone.replace(/\D/g, '');
    const firstName = prospect.full_name?.split(' ')[0] ?? prospect.full_name;
    const product = prospect.desired_product ? ` concernant ${prospect.desired_product}` : '';
    const message = encodeURIComponent(
      `Bonjour ${firstName}, c'est ${prospecteurName} de ${orgName}. Je reviens vers vous${product}.`
    );
    window.open(`https://wa.me/${cleanPhone}?text=${message}`, '_blank');
  }

  const today = new Date().toISOString().split('T')[0];

  const filtered = prospects.filter(p => {
    const matchSearch = !search ||
      p.full_name?.toLowerCase().includes(search.toLowerCase()) ||
      p.phone?.includes(search) ||
      p.desired_product?.toLowerCase().includes(search.toLowerCase());

    let matchFilter = true;
    if (filter === 'hot') matchFilter = p.temperature === 'hot';
    else if (filter === 'warm') matchFilter = p.temperature === 'warm';
    else if (filter === 'cold') matchFilter = p.temperature === 'cold';
    else if (filter === 'today') matchFilter = p.next_contact_date === today;
    else if (filter === 'appointment_today') matchFilter = p.appointment_date === today;
    else if (filter === 'no_contact') {
      const sevenDaysAgo = new Date();
      sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
      matchFilter = new Date(p.created_at) < sevenDaysAgo && !p.next_contact_date;
    }

    return matchSearch && matchFilter;
  });

  const filterButtons: { id: FilterType; label: string; count?: number }[] = [
    { id: 'all', label: 'Tous', count: prospects.length },
    { id: 'hot', label: '🔥 Chauds', count: prospects.filter(p => p.temperature === 'hot').length },
    { id: 'warm', label: '🌤 Tièdes', count: prospects.filter(p => p.temperature === 'warm').length },
    { id: 'cold', label: '❄️ Froids', count: prospects.filter(p => p.temperature === 'cold').length },
    { id: 'today', label: 'À relancer', count: prospects.filter(p => p.next_contact_date === today).length },
    { id: 'appointment_today', label: 'RDV aujourd\'hui', count: prospects.filter(p => p.appointment_date === today).length },
  ];

  return (
    <div className="p-5 lg:p-8 space-y-5">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Mes prospects</h1>
          <p className="text-sm text-[#A0AEC0] mt-1">{prospects.length} prospect{prospects.length !== 1 ? 's' : ''}</p>
        </div>
        <button onClick={() => setModalOpen(true)} className="flex items-center gap-2 btn-gold px-4 py-2.5 rounded-xl text-sm font-bold">
          <Plus size={14} />
          Nouveau
        </button>
      </div>

      {/* Filter chips */}
      <div className="flex gap-2 overflow-x-auto pb-1 scrollbar-hide">
        {filterButtons.map(btn => (
          <button
            key={btn.id}
            onClick={() => setFilter(btn.id)}
            className={`flex-shrink-0 flex items-center gap-1.5 px-3 py-1.5 rounded-xl text-xs font-medium transition-all ${
              filter === btn.id
                ? 'bg-[#D4AF37] text-[#0B1B3D]'
                : 'bg-[#0F2347] border border-[#D4AF37]/20 text-[#A0AEC0] hover:text-white'
            }`}
          >
            {btn.label}
            {btn.count !== undefined && btn.count > 0 && (
              <span className={`text-[10px] px-1.5 py-0.5 rounded-full ${filter === btn.id ? 'bg-[#0B1B3D]/20' : 'bg-[#D4AF37]/20 text-[#D4AF37]'}`}>
                {btn.count}
              </span>
            )}
          </button>
        ))}
      </div>

      {/* Search */}
      <div className="relative">
        <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#718096]" />
        <input
          type="text"
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Rechercher par nom, téléphone, article..."
          className="w-full bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm placeholder-[#718096] focus:outline-none focus:border-[#D4AF37]/60"
        />
      </div>

      {/* Prospect list */}
      <div className="space-y-2">
        {loading ? (
          <div className="py-16 text-center text-[#A0AEC0] text-sm">Chargement...</div>
        ) : filtered.length === 0 ? (
          <div className="py-16 text-center">
            <Users size={32} className="mx-auto mb-3 text-[#718096] opacity-50" />
            <p className="text-[#A0AEC0] text-sm">Aucun prospect</p>
          </div>
        ) : (
          filtered.map(p => (
            <div key={p.id} className="bg-[#0F2347] border border-[#D4AF37]/15 rounded-2xl overflow-hidden">
              {/* Card header */}
              <div className="flex items-center justify-between px-4 py-3">
                <div className="flex items-center gap-3 flex-1 min-w-0">
                  <div className="w-9 h-9 rounded-full bg-[#0A1628] border border-[#D4AF37]/20 flex items-center justify-center text-sm font-bold text-[#D4AF37] flex-shrink-0">
                    {p.full_name?.charAt(0).toUpperCase()}
                  </div>
                  <div className="min-w-0">
                    <p className="text-sm font-semibold text-white truncate">{p.full_name}</p>
                    <p className="text-xs text-[#718096]">{p.phone ?? '—'}</p>
                  </div>
                </div>
                <div className="flex items-center gap-2 flex-shrink-0">
                  {p.temperature && (
                    <span className={`text-xs px-2 py-0.5 rounded-lg border ${TEMP_COLORS[p.temperature] ?? 'bg-gray-500/20 text-gray-400 border-gray-500/30'}`}>
                      {TEMP_LABELS[p.temperature] ?? p.temperature}
                    </span>
                  )}
                  <button
                    onClick={() => setExpandedId(expandedId === p.id ? null : p.id)}
                    className="p-1 text-[#718096] hover:text-white transition-colors"
                  >
                    {expandedId === p.id ? <ChevronUp size={14} /> : <ChevronDown size={14} />}
                  </button>
                </div>
              </div>

              {/* Action buttons */}
              <div className="flex gap-2 px-4 pb-3">
                {p.phone && (
                  <button
                    onClick={() => handleCall(p.phone!)}
                    className="flex items-center gap-1.5 px-3 py-1.5 bg-blue-500/10 border border-blue-500/30 rounded-lg text-blue-400 text-xs font-medium hover:bg-blue-500/20 transition-colors"
                  >
                    <Phone size={12} />
                    Appeler
                  </button>
                )}
                {p.phone && (
                  <button
                    onClick={() => handleWhatsApp(p.phone!, p)}
                    className="flex items-center gap-1.5 px-3 py-1.5 bg-green-500/10 border border-green-500/30 rounded-lg text-green-400 text-xs font-medium hover:bg-green-500/20 transition-colors"
                  >
                    <MessageCircle size={12} />
                    WhatsApp
                  </button>
                )}
                <button
                  onClick={() => handleConvert(p.id)}
                  className="flex items-center gap-1.5 px-3 py-1.5 bg-[#D4AF37]/10 border border-[#D4AF37]/30 rounded-lg text-[#D4AF37] text-xs font-medium hover:bg-[#D4AF37]/20 transition-colors"
                >
                  <UserCheck size={12} />
                  Convertir en client
                </button>
                {p.appointment_date && (
                  <div className="flex items-center gap-1.5 px-3 py-1.5 bg-[#D4AF37]/10 border border-[#D4AF37]/30 rounded-lg text-[#D4AF37] text-xs">
                    <Calendar size={12} />
                    RDV {new Date(p.appointment_date).toLocaleDateString('fr-FR')}
                  </div>
                )}
              </div>

              {/* Expanded details */}
              {expandedId === p.id && (
                <div className="border-t border-[#D4AF37]/10 px-4 py-3 space-y-2">
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    {p.desired_product && (
                      <div>
                        <span className="text-[#718096]">Article désiré : </span>
                        <span className="text-white">{p.desired_product}</span>
                        {p.desired_quantity && p.desired_quantity > 1 && (
                          <span className="text-[#A0AEC0]"> × {p.desired_quantity}</span>
                        )}
                      </div>
                    )}
                    {p.proposed_price && p.proposed_price > 0 && (
                      <div>
                        <span className="text-[#718096]">Prix proposé : </span>
                        <span className="text-[#D4AF37] font-semibold">
                          {new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(p.proposed_price / 100)}
                        </span>
                      </div>
                    )}
                    {p.interest_level && (
                      <div>
                        <span className="text-[#718096]">Intérêt : </span>
                        <span className="text-white">{INTEREST_LABELS[p.interest_level] ?? p.interest_level}</span>
                      </div>
                    )}
                    {p.city && (
                      <div>
                        <span className="text-[#718096]">Ville : </span>
                        <span className="text-white">{p.city}{p.quartier ? `, ${p.quartier}` : ''}</span>
                      </div>
                    )}
                    {p.lieu_rencontre && (
                      <div>
                        <span className="text-[#718096]">Lieu rencontre : </span>
                        <span className="text-white">{p.lieu_rencontre}</span>
                      </div>
                    )}
                    {p.next_contact_date && (
                      <div>
                        <span className="text-[#718096]">Prochain contact : </span>
                        <span className={`font-medium ${p.next_contact_date === today ? 'text-[#D4AF37]' : 'text-white'}`}>
                          {new Date(p.next_contact_date).toLocaleDateString('fr-FR')}
                          {p.next_contact_date === today && ' (Aujourd\'hui)'}
                        </span>
                      </div>
                    )}
                    {p.appointment_date && (
                      <div>
                        <span className="text-[#718096]">RDV : </span>
                        <span className="text-white">
                          {new Date(p.appointment_date).toLocaleDateString('fr-FR')}
                          {p.appointment_time && ` à ${p.appointment_time.slice(0, 5)}`}
                          {p.appointment_location && ` — ${p.appointment_location}`}
                        </span>
                      </div>
                    )}
                    {p.phone2 && (
                      <div>
                        <span className="text-[#718096]">Tél 2 : </span>
                        <span className="text-white">{p.phone2}</span>
                      </div>
                    )}
                  </div>
                  {p.notes && (
                    <div className="mt-2 p-2 bg-[#0A1628] rounded-lg">
                      <p className="text-xs text-[#A0AEC0]">{p.notes}</p>
                    </div>
                  )}
                </div>
              )}
            </div>
          ))
        )}
      </div>

      {/* Create Prospect Modal */}
      <Modal open={modalOpen} onClose={() => setModalOpen(false)} title="Nouveau prospect" size="lg">
        <form onSubmit={handleCreate} className="space-y-4 p-1 max-h-[70vh] overflow-y-auto">
          {/* Identity */}
          <div>
            <p className="text-xs font-semibold text-[#D4AF37] uppercase tracking-wider mb-3">Identité</p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="sm:col-span-2">
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Nom complet *</label>
                <input
                  type="text"
                  value={form.full_name}
                  onChange={e => setForm(f => ({ ...f, full_name: e.target.value }))}
                  required
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                  placeholder="Nom et prénom"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Téléphone principal</label>
                <input
                  type="tel"
                  value={form.phone}
                  onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                  placeholder="+225 07 00 00 00"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Téléphone 2</label>
                <input
                  type="tel"
                  value={form.phone2}
                  onChange={e => setForm(f => ({ ...f, phone2: e.target.value }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                  placeholder="+225 07 00 00 00"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Ville</label>
                <input
                  type="text"
                  value={form.city}
                  onChange={e => setForm(f => ({ ...f, city: e.target.value }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                  placeholder="Abidjan"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Quartier</label>
                <input
                  type="text"
                  value={form.quartier}
                  onChange={e => setForm(f => ({ ...f, quartier: e.target.value }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                  placeholder="Cocody"
                />
              </div>
              <div className="sm:col-span-2">
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Lieu de rencontre</label>
                <input
                  type="text"
                  value={form.lieu_rencontre}
                  onChange={e => setForm(f => ({ ...f, lieu_rencontre: e.target.value }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                  placeholder="Marché, boutique, domicile..."
                />
              </div>
            </div>
          </div>

          {/* Commercial info */}
          <div>
            <p className="text-xs font-semibold text-[#D4AF37] uppercase tracking-wider mb-3">Informations commerciales</p>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-3">
              <div className="sm:col-span-2">
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Article désiré</label>
                <input
                  type="text"
                  value={form.desired_product}
                  onChange={e => setForm(f => ({ ...f, desired_product: e.target.value }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                  placeholder="Nom de l'article"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Quantité</label>
                <input
                  type="number"
                  value={form.desired_quantity}
                  onChange={e => setForm(f => ({ ...f, desired_quantity: parseInt(e.target.value) || 1 }))}
                  min={1}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Prix proposé (XOF)</label>
                <input
                  type="number"
                  value={form.proposed_price}
                  onChange={e => setForm(f => ({ ...f, proposed_price: parseFloat(e.target.value) || 0 }))}
                  min={0}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                  placeholder="0"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Niveau d&apos;intérêt</label>
                <select
                  value={form.interest_level}
                  onChange={e => setForm(f => ({ ...f, interest_level: e.target.value }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                >
                  <option value="low">Faible</option>
                  <option value="medium">Moyen</option>
                  <option value="high">Élevé</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Température</label>
                <select
                  value={form.temperature}
                  onChange={e => setForm(f => ({ ...f, temperature: e.target.value }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                >
                  <option value="cold">❄️ Froid</option>
                  <option value="warm">🌤 Tiède</option>
                  <option value="hot">🔥 Chaud</option>
                </select>
              </div>
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Prochain contact</label>
                <input
                  type="date"
                  value={form.next_contact_date}
                  onChange={e => setForm(f => ({ ...f, next_contact_date: e.target.value }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                />
              </div>
            </div>
          </div>

          {/* Appointment */}
          <div>
            <p className="text-xs font-semibold text-[#D4AF37] uppercase tracking-wider mb-3">Rendez-vous</p>
            <div className="grid grid-cols-1 sm:grid-cols-3 gap-3">
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Date RDV</label>
                <input
                  type="date"
                  value={form.appointment_date}
                  onChange={e => setForm(f => ({ ...f, appointment_date: e.target.value }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Heure RDV</label>
                <input
                  type="time"
                  value={form.appointment_time}
                  onChange={e => setForm(f => ({ ...f, appointment_time: e.target.value }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Lieu RDV</label>
                <input
                  type="text"
                  value={form.appointment_location}
                  onChange={e => setForm(f => ({ ...f, appointment_location: e.target.value }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                  placeholder="Lieu du rendez-vous"
                />
              </div>
            </div>
          </div>

          {/* Notes */}
          <div>
            <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Observations / Besoin du client</label>
            <textarea
              value={form.notes}
              onChange={e => setForm(f => ({ ...f, notes: e.target.value }))}
              rows={3}
              className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60 resize-none"
              placeholder="Besoin du client, observations, remarques..."
            />
          </div>

          <div className="flex gap-3 pt-2">
            <button type="button" onClick={() => setModalOpen(false)} className="flex-1 py-2.5 rounded-xl border border-[#D4AF37]/20 text-[#A0AEC0] text-sm hover:text-white transition-colors">
              Annuler
            </button>
            <button type="submit" disabled={submitting} className="flex-1 btn-gold py-2.5 rounded-xl font-semibold text-sm disabled:opacity-60">
              {submitting ? 'Enregistrement...' : 'Ajouter le prospect'}
            </button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
