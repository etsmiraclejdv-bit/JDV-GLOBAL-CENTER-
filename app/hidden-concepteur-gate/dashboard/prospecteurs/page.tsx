'use client';
import React, { useState, useEffect } from 'react';
import { Users, Search, RefreshCw } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { personName } from '@/lib/services/compat';

interface ProspecteurRow {
  id: string;
  full_name: string;
  phone: string | null;
  city: string | null;
  role: string;
  created_at: string;
  organization_id: string | null;
  org_name?: string;
}

export default function SuperAdminProspecteursPage() {
  const [prospecteurs, setProspecteurs] = useState<ProspecteurRow[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');
  const [roleFilter, setRoleFilter] = useState<'all' | 'prospecteur' | 'admin'>('all');

  async function loadProspecteurs() {
    setLoading(true);
    const { data: rows } = await supabase
      .from('prospecteurs')
      .select('id, first_name, last_name, phone, city, created_at, organization_id')
      .order('created_at', { ascending: false });
    const profiles = ((rows ?? []) as Record<string, unknown>[]).map(r => ({
      id: r.id as string,
      full_name: personName(r as never) || 'Sans nom',
      phone: (r.phone as string) ?? null,
      city: (r.city as string) ?? null,
      role: 'prospecteur',
      created_at: r.created_at as string,
      organization_id: (r.organization_id as string) ?? null,
    }));

    if (profiles.length === 0) { setProspecteurs([]); setLoading(false); return; }

    const orgIds = [...new Set(profiles.map(p => p.organization_id).filter(Boolean))] as string[];
    let orgMap: Record<string, string> = {};
    if (orgIds.length > 0) {
      const { data: orgs } = await supabase.from('organizations').select('id, name').in('id', orgIds);
      (orgs ?? []).forEach(o => { orgMap[o.id] = o.name; });
    }

    setProspecteurs(profiles.map(p => ({ ...p, org_name: p.organization_id ? (orgMap[p.organization_id] ?? '—') : '—' })));
    setLoading(false);
  }

  useEffect(() => { loadProspecteurs(); }, []);

  const filtered = prospecteurs.filter(p => {
    const matchSearch = p.full_name.toLowerCase().includes(search.toLowerCase()) ||
      (p.phone ?? '').includes(search) ||
      (p.org_name ?? '').toLowerCase().includes(search.toLowerCase());
    const matchRole = roleFilter === 'all' || p.role === roleFilter;
    return matchSearch && matchRole;
  });

  const formatDate = (iso: string) => {
    const d = new Date(iso);
    return `${d.getDate().toString().padStart(2,'0')}/${(d.getMonth()+1).toString().padStart(2,'0')}/${d.getFullYear()}`;
  };

  const roleLabel: Record<string, string> = { prospecteur: 'Prospecteur', admin: 'Admin', super_admin: 'Super Admin' };
  const roleColor: Record<string, string> = {
    prospecteur: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
    admin: 'bg-[#D4AF37]/20 text-[#D4AF37] border-[#D4AF37]/30',
    super_admin: 'bg-purple-500/20 text-purple-400 border-purple-500/30',
  };

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Prospecteurs & Utilisateurs</h1>
          <p className="text-sm text-[#A0AEC0] mt-1">{prospecteurs.length} utilisateur{prospecteurs.length !== 1 ? 's' : ''} sur la plateforme</p>
        </div>
        <button onClick={loadProspecteurs} className="flex items-center gap-2 px-4 py-2 rounded-xl border border-[#D4AF37]/20 text-[#A0AEC0] hover:text-white text-sm transition-colors">
          <RefreshCw size={14} />
          Actualiser
        </button>
      </div>

      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1 max-w-sm">
          <Search size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#718096]" />
          <input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Rechercher un utilisateur..."
            className="w-full bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl pl-10 pr-4 py-2.5 text-white placeholder-[#718096] text-sm focus:outline-none focus:border-[#D4AF37]/60 transition-colors"
          />
        </div>
        <div className="flex gap-1 bg-[#0A1628] rounded-xl p-1">
          {(['all', 'prospecteur', 'admin'] as const).map(r => (
            <button
              key={r}
              onClick={() => setRoleFilter(r)}
              className={`px-3 py-1.5 rounded-lg text-xs font-medium transition-all ${
                roleFilter === r ? 'bg-[#D4AF37] text-[#0B1B3D]' : 'text-[#A0AEC0] hover:text-white'
              }`}
            >
              {r === 'all' ? 'Tous' : r === 'prospecteur' ? 'Prospecteurs' : 'Admins'}
            </button>
          ))}
        </div>
      </div>

      <div className="bg-[#0F2347] border border-[#D4AF37]/15 rounded-2xl overflow-hidden">
        {loading ? (
          <div className="p-8 space-y-3">
            {[1,2,3,4].map(i => <div key={i} className="h-12 bg-[#0A1628] rounded-xl animate-pulse" />)}
          </div>
        ) : filtered.length === 0 ? (
          <div className="p-12 text-center">
            <Users size={32} className="text-[#718096] mx-auto mb-3" />
            <p className="text-[#A0AEC0] text-sm">Aucun utilisateur trouvé</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[#D4AF37]/10">
                  <th className="text-left text-xs font-semibold text-[#718096] uppercase tracking-wider px-6 py-4">Nom</th>
                  <th className="text-left text-xs font-semibold text-[#718096] uppercase tracking-wider px-6 py-4">Téléphone</th>
                  <th className="text-left text-xs font-semibold text-[#718096] uppercase tracking-wider px-6 py-4">Entreprise</th>
                  <th className="text-left text-xs font-semibold text-[#718096] uppercase tracking-wider px-6 py-4">Ville</th>
                  <th className="text-left text-xs font-semibold text-[#718096] uppercase tracking-wider px-6 py-4">Rôle</th>
                  <th className="text-left text-xs font-semibold text-[#718096] uppercase tracking-wider px-6 py-4">Inscrit le</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#D4AF37]/5">
                {filtered.map(p => (
                  <tr key={p.id} className="hover:bg-[#0A1628]/50 transition-colors">
                    <td className="px-6 py-4">
                      <div className="flex items-center gap-3">
                        <div className="w-8 h-8 rounded-full bg-[#D4AF37]/10 flex items-center justify-center text-[#D4AF37] text-xs font-bold">
                          {p.full_name.charAt(0).toUpperCase()}
                        </div>
                        <span className="text-sm font-medium text-white">{p.full_name}</span>
                      </div>
                    </td>
                    <td className="px-6 py-4 text-sm text-[#A0AEC0]">{p.phone ?? '—'}</td>
                    <td className="px-6 py-4 text-sm text-[#A0AEC0]">{p.org_name}</td>
                    <td className="px-6 py-4 text-sm text-[#A0AEC0]">{p.city ?? '—'}</td>
                    <td className="px-6 py-4">
                      <span className={`text-xs px-2.5 py-1 rounded-lg border ${roleColor[p.role] ?? 'bg-gray-500/20 text-gray-400 border-gray-500/30'}`}>
                        {roleLabel[p.role] ?? p.role}
                      </span>
                    </td>
                    <td className="px-6 py-4 text-sm text-[#A0AEC0]">{formatDate(p.created_at)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </div>
  );
}
