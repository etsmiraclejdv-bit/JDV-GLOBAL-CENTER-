'use client';
import React, { useState, useEffect } from 'react';
import { ShoppingCart, Search, Plus, Eye } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchSales } from '@/lib/services/salesService';
import Link from 'next/link';
import { fetchOrgProfile } from '@/lib/auth/context';

interface Sale {
  id: string;
  organization_id: string;
  client_id?: string;
  prospecteur_id?: string;
  product_id?: string;
  amount_cents: number;
  status: string;
  sold_at: string;
  clients?: { id: string; full_name: string; phone?: string } | null;
  profiles?: { id: string; full_name: string } | null;
  products?: { id: string; name: string; sku: string } | null;
}

const STATUS_COLORS: Record<string, string> = {
  pending: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  active: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
  completed: 'bg-green-500/20 text-green-400 border-green-500/30',
  cancelled: 'bg-red-500/20 text-red-400 border-red-500/30',
  encaissé: 'bg-green-500/20 text-green-400 border-green-500/30',
};

const STATUS_LABELS: Record<string, string> = {
  pending: 'En attente',
  active: 'Actif',
  completed: 'Terminé',
  cancelled: 'Annulé',
  encaissé: 'Encaissé',
};

export default function BusinessVentesPage() {
  const [sales, setSales] = useState<Sale[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');
  const [orgId, setOrgId] = useState<string | null>(null);

  useEffect(() => {
    supabase.auth.getUser().then(async ({ data }) => {
      if (!data.user) return;
      const { data: profile } = await fetchOrgProfile();
      if (profile?.organization_id) {
        setOrgId(profile.organization_id);
        const { data: salesData, error: salesError } = await fetchSales(profile.organization_id, {
          status: statusFilter || undefined,
        });
        if (salesError) setError(salesError.message);
        else setSales((salesData as Sale[]) ?? []);
        setLoading(false);
      }
    });
  }, [statusFilter]);

  const filtered = sales.filter(s => {
    if (!search) return true;
    const q = search.toLowerCase();
    return (
      s.clients?.full_name?.toLowerCase().includes(q) ||
      s.products?.name?.toLowerCase().includes(q) ||
      s.id.toLowerCase().includes(q)
    );
  });

  const totalRevenue = sales.reduce((sum, s) => sum + (s.amount_cents ?? 0), 0);

  return (
    <div className="p-6 lg:p-8 space-y-6">
      {/* Header */}
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Ventes</h1>
          <p className="text-sm text-[#A0AEC0] mt-1">Toutes les ventes de votre organisation</p>
        </div>
        <Link
          href="/business/dashboard/ventes/new"
          className="flex items-center gap-2 btn-gold px-4 py-2.5 rounded-xl text-sm font-bold"
        >
          <Plus size={14} />
          Nouvelle vente
        </Link>
      </div>

      {/* KPI */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-4">
          <p className="text-xs text-[#A0AEC0] mb-1">Total ventes</p>
          <p className="text-2xl font-bold text-white">{sales.length}</p>
        </div>
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-4">
          <p className="text-xs text-[#A0AEC0] mb-1">Chiffre d&apos;affaires</p>
          <p className="text-2xl font-bold text-[#D4AF37]">
            {new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(totalRevenue / 100)}
          </p>
        </div>
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-4">
          <p className="text-xs text-[#A0AEC0] mb-1">En attente</p>
          <p className="text-2xl font-bold text-yellow-400">{sales.filter(s => s.status === 'pending').length}</p>
        </div>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <div className="relative flex-1">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#718096]" />
          <input
            type="text"
            value={search}
            onChange={e => setSearch(e.target.value)}
            placeholder="Rechercher par client, produit..."
            className="w-full bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm placeholder-[#718096] focus:outline-none focus:border-[#D4AF37]/60"
          />
        </div>
        <select
          value={statusFilter}
          onChange={e => setStatusFilter(e.target.value)}
          className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-[#A0AEC0] text-sm focus:outline-none focus:border-[#D4AF37]/60"
        >
          <option value="">Tous les statuts</option>
          <option value="pending">En attente</option>
          <option value="active">Actif</option>
          <option value="completed">Terminé</option>
          <option value="cancelled">Annulé</option>
        </select>
      </div>

      {/* Table */}
      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
        {loading ? (
          <div className="py-16 text-center text-[#A0AEC0] text-sm">Chargement des ventes...</div>
        ) : error ? (
          <div className="py-16 text-center text-red-400 text-sm">{error}</div>
        ) : filtered.length === 0 ? (
          <div className="py-16 text-center">
            <ShoppingCart size={32} className="mx-auto mb-3 text-[#718096] opacity-50" />
            <p className="text-[#A0AEC0] text-sm">Aucune vente trouvée</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[#D4AF37]/10">
                  <th className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider">Client</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider">Produit</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider">Montant</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider">Statut</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider">Date</th>
                  <th className="px-4 py-3"></th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(sale => (
                  <tr key={sale.id} className="border-b border-[#D4AF37]/5 hover:bg-[#0A1628]/40 transition-colors">
                    <td className="px-4 py-3">
                      <p className="text-sm font-medium text-white">{sale.clients?.full_name ?? '—'}</p>
                      <p className="text-xs text-[#718096]">{sale.clients?.phone ?? ''}</p>
                    </td>
                    <td className="px-4 py-3 text-sm text-[#A0AEC0]">{sale.products?.name ?? '—'}</td>
                    <td className="px-4 py-3 text-sm font-semibold text-[#D4AF37]">
                      {new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format((sale.amount_cents ?? 0) / 100)}
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-medium border ${STATUS_COLORS[sale.status] ?? 'bg-gray-500/20 text-gray-400 border-gray-500/30'}`}>
                        {STATUS_LABELS[sale.status] ?? sale.status}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-[#718096]">
                      {new Date(sale.sold_at).toLocaleDateString('fr-FR')}
                    </td>
                    <td className="px-4 py-3">
                      <Link
                        href={`/business/dashboard/ventes/${sale.id}`}
                        className="p-1.5 rounded-lg text-[#718096] hover:text-[#D4AF37] hover:bg-[#D4AF37]/10 transition-all inline-flex"
                      >
                        <Eye size={14} />
                      </Link>
                    </td>
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
