'use client';
import React, { useState, useEffect } from 'react';
import { ShoppingCart, Search } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchSales } from '@/lib/services/salesService';
import { fetchOrgProfile } from '@/lib/auth/context';


interface Sale {
  id: string;
  amount_cents: number;
  status: string;
  sold_at: string;
  clients?: { full_name: string } | null;
  products?: { name: string } | null;
}

export default function TerrainVentesPage() {
  const [sales, setSales] = useState<Sale[]>([]);
  const [loading, setLoading] = useState(true);
  const [search, setSearch] = useState('');

  useEffect(() => {
    supabase.auth.getUser().then(async ({ data }) => {
      if (!data.user) return;
      const { data: profile } = await fetchOrgProfile();
      if (profile?.organization_id && profile.prospecteur_id) {
        const { data: salesData } = await fetchSales(profile.organization_id, { prospecteurId: profile.prospecteur_id });
        setSales((salesData as Sale[]) ?? []);
      }
      setLoading(false);
    });
  }, []);

  const filtered = sales.filter(s => {
    if (!search) return true;
    return s.clients?.full_name?.toLowerCase().includes(search.toLowerCase());
  });

  return (
    <div className="p-5 lg:p-8 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Mes ventes</h1>
        <p className="text-sm text-[#A0AEC0] mt-1">{sales.length} vente{sales.length !== 1 ? 's' : ''} au total</p>
      </div>

      <div className="relative">
        <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#718096]" />
        <input
          type="text"
          value={search}
          onChange={e => setSearch(e.target.value)}
          placeholder="Rechercher par client..."
          className="w-full bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm placeholder-[#718096] focus:outline-none focus:border-[#D4AF37]/60"
        />
      </div>

      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
        {loading ? (
          <div className="py-16 text-center text-[#A0AEC0] text-sm">Chargement...</div>
        ) : filtered.length === 0 ? (
          <div className="py-16 text-center">
            <ShoppingCart size={32} className="mx-auto mb-3 text-[#718096] opacity-50" />
            <p className="text-[#A0AEC0] text-sm">Aucune vente trouvée</p>
          </div>
        ) : (
          <div className="divide-y divide-[#D4AF37]/5">
            {filtered.map(sale => (
              <div key={sale.id} className="flex items-center justify-between px-4 py-3 hover:bg-[#0A1628]/40 transition-colors">
                <div>
                  <p className="text-sm font-medium text-white">{sale.clients?.full_name ?? 'Client inconnu'}</p>
                  <p className="text-xs text-[#718096]">{new Date(sale.sold_at).toLocaleDateString('fr-FR')}</p>
                </div>
                <div className="flex items-center gap-3">
                  <p className="text-sm font-semibold text-[#D4AF37]">
                    {new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format((sale.amount_cents ?? 0) / 100)}
                  </p>
                  <span className={`text-xs px-2 py-0.5 rounded-lg ${sale.status === 'completed' || sale.status === 'encaissé' ? 'bg-green-500/20 text-green-400' : 'bg-yellow-500/20 text-yellow-400'}`}>
                    {sale.status}
                  </span>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
