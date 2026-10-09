'use client';
import React, { useState, useEffect } from 'react';
import { UserCheck, Search, ChevronDown, ChevronUp } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchOrgProfile } from '@/lib/auth/context';
import { personName } from '@/lib/services/compat';

interface Prospect {
  id: string;
  full_name: string;
  phone?: string;
  temperature?: string;
  interest_level?: string;
  desired_product?: string;
  next_contact_date?: string;
  appointment_date?: string;
  city?: string;
  notes?: string;
  is_prospect?: boolean;
  created_at: string;
  assigned_profile?: { full_name: string } | null;
}

const TEMP_COLORS: Record<string, string> = {
  hot: 'bg-[#FC8181]/20 text-[#FC8181] border-[#FC8181]/30',
  warm: 'bg-[#F6E05E]/20 text-[#F6E05E] border-[#F6E05E]/30',
  cold: 'bg-[#63B3ED]/20 text-[#63B3ED] border-[#63B3ED]/30',
};
const TEMP_LABELS: Record<string, string> = { hot: 'Chaud', warm: 'Tiède', cold: 'Froid' };

export default function BusinessProspectsPage() {
  const [prospects, setProspects] = useState<Prospect[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [tempFilter, setTempFilter] = useState('');
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [orgId, setOrgId] = useState<string | null>(null);

  useEffect(() => {
    supabase.auth.getUser().then(async ({ data }) => {
      if (!data.user) return;
      const { data: profile } = await fetchOrgProfile();
      if (profile?.organization_id) {
        setOrgId(profile.organization_id);
        loadProspects(profile.organization_id);
      }
    });
  }, []);

  async function loadProspects(oid: string) {
    setLoading(true);
    const [{ data }, { data: pros }] = await Promise.all([
      supabase
        .from('prospects')
        .select('*')
        .eq('organization_id', oid)
        .neq('status', 'archived')
        .order('created_at', { ascending: false }),
      supabase.from('prospecteurs').select('id, first_name, last_name').eq('organization_id', oid),
    ]);
    const names = new Map<string, string>();
    ((pros ?? []) as Record<string, unknown>[]).forEach(x => names.set(x.id as string, personName(x as never)));
    setProspects(
      ((data ?? []) as Record<string, unknown>[]).map(r => ({
        id: r.id as string,
        full_name: personName(r as never) || 'Sans nom',
        phone: (r.phone as string) ?? undefined,
        temperature: (r.temperature as string) ?? undefined,
        desired_product: (r.desired_article as string) ?? undefined,
        next_contact_date: r.next_follow_up_at ? String(r.next_follow_up_at).split('T')[0] : undefined,
        appointment_date: (r.purchase_date_planned as string) ?? undefined,
        city: (r.city as string) ?? undefined,
        notes: (r.notes as string) ?? undefined,
        is_prospect: true,
        created_at: r.created_at as string,
        assigned_profile: r.prospecteur_id ? { full_name: names.get(r.prospecteur_id as string) ?? '' } : null,
      }))
    );
    setLoading(false);
  }

  const today = new Date().toISOString().split('T')[0];

  const filtered = prospects.filter(p => {
    const matchSearch = !search ||
      p.full_name?.toLowerCase().includes(search.toLowerCase()) ||
      p.phone?.includes(search) ||
      p.desired_product?.toLowerCase().includes(search.toLowerCase());
    const matchTemp = !tempFilter || p.temperature === tempFilter;
    return matchSearch && matchTemp;
  });

  const stats = {
    total: prospects.length,
    hot: prospects.filter(p => p.temperature === 'hot').length,
    warm: prospects.filter(p => p.temperature === 'warm').length,
    cold: prospects.filter(p => p.temperature === 'cold').length,
    todayContact: prospects.filter(p => p.next_contact_date === today).length,
  };

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Prospects</h1>
        <p className="text-sm text-[#A0AEC0] mt-1">Tous les prospects de votre organisation</p>
      </div>

      {/* Stats */}
      <div className="grid grid-cols-2 sm:grid-cols-5 gap-3">
        {[
          { label: 'Total', value: stats.total, color: 'text-white' },
          { label: '🔥 Chauds', value: stats.hot, color: 'text-[#FC8181]' },
          { label: '🌤 Tièdes', value: stats.warm, color: 'text-[#F6E05E]' },
          { label: '❄️ Froids', value: stats.cold, color: 'text-[#63B3ED]' },
          { label: 'À relancer', value: stats.todayContact, color: 'text-[#D4AF37]' },
        ].map((s, i) => (
          <div key={i} className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl p-3 text-center">
            <p className={`text-xl font-bold ${s.color}`}>{loading ? '—' : s.value}</p>
            <p className="text-xs text-[#718096] mt-0.5">{s.label}</p>
          </div>
        ))}
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#718096]" />
          <input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Rechercher par nom, téléphone, article..."
            className="w-full bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm placeholder-[#718096] focus:outline-none focus:border-[#D4AF37]/60"
          />
        </div>
        <select
          value={tempFilter}
          onChange={e => setTempFilter(e.target.value)}
          className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-[#A0AEC0] text-sm focus:outline-none focus:border-[#D4AF37]/60"
        >
          <option value="">Toutes températures</option>
          <option value="hot">🔥 Chaud</option>
          <option value="warm">🌤 Tiède</option>
          <option value="cold">❄️ Froid</option>
        </select>
      </div>

      {/* List */}
      <div className="space-y-2">
        {loading ? (
          <div className="py-16 text-center text-[#A0AEC0] text-sm">Chargement...</div>
        ) : filtered.length === 0 ? (
          <div className="py-16 text-center">
            <UserCheck size={32} className="mx-auto mb-3 text-[#718096] opacity-50" />
            <p className="text-[#A0AEC0] text-sm">Aucun prospect visible</p>
            <p className="text-xs text-[#718096] mt-2 max-w-md mx-auto">Les clients et prospects sont privés : chaque prospecteur gère son propre portefeuille depuis son espace terrain. Vous suivez ici les ventes, les paiements et les résultats de l’équipe.</p>
          </div>
        ) : (
          filtered.map(p => (
            <div key={p.id} className="bg-[#0F2347] border border-[#D4AF37]/15 rounded-2xl overflow-hidden">
              <div className="flex items-center justify-between px-4 py-3">
                <div className="flex items-center gap-3 flex-1 min-w-0">
                  <div className="w-9 h-9 rounded-full bg-[#0A1628] border border-[#D4AF37]/20 flex items-center justify-center text-sm font-bold text-[#D4AF37] flex-shrink-0">
                    {p.full_name?.charAt(0).toUpperCase()}
                  </div>
                  <div className="min-w-0">
                    <p className="text-sm font-semibold text-white truncate">{p.full_name}</p>
                    <p className="text-xs text-[#718096]">
                      {p.phone ?? '—'}
                      {p.assigned_profile?.full_name && (
                        <span className="ml-2 text-[#D4AF37]/70">• {p.assigned_profile.full_name}</span>
                      )}
                    </p>
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

              {expandedId === p.id && (
                <div className="border-t border-[#D4AF37]/10 px-4 py-3 space-y-2">
                  <div className="grid grid-cols-2 gap-2 text-xs">
                    {p.desired_product && (
                      <div><span className="text-[#718096]">Article : </span><span className="text-white">{p.desired_product}</span></div>
                    )}
                    {p.city && (
                      <div><span className="text-[#718096]">Ville : </span><span className="text-white">{p.city}</span></div>
                    )}
                    {p.next_contact_date && (
                      <div>
                        <span className="text-[#718096]">Prochain contact : </span>
                        <span className={p.next_contact_date === today ? 'text-[#D4AF37] font-medium' : 'text-white'}>
                          {new Date(p.next_contact_date).toLocaleDateString('fr-FR')}
                        </span>
                      </div>
                    )}
                    {p.appointment_date && (
                      <div><span className="text-[#718096]">RDV : </span><span className="text-white">{new Date(p.appointment_date).toLocaleDateString('fr-FR')}</span></div>
                    )}
                  </div>
                  {p.notes && (
                    <div className="p-2 bg-[#0A1628] rounded-lg">
                      <p className="text-xs text-[#A0AEC0]">{p.notes}</p>
                    </div>
                  )}
                </div>
              )}
            </div>
          ))
        )}
      </div>
    </div>
  );
}
