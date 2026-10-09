'use client';
import React, { useState, useEffect } from 'react';
import { Users, Search, Eye } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchClients } from '@/lib/services/clientsService';
import Link from 'next/link';
import { fetchOrgProfile } from '@/lib/auth/context';

interface Client {
  id: string;
  organization_id: string;
  assigned_to?: string;
  full_name: string;
  phone?: string;
  payment_status: string;
  balance_cents: number;
  created_at: string;
  profiles?: { id: string; full_name: string } | null;
}

const PAYMENT_STATUS_COLORS: Record<string, string> = {
  a_jour: 'bg-green-500/20 text-green-400 border-green-500/30',
  a_surveiller: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  en_retard: 'bg-red-500/20 text-red-400 border-red-500/30',
};

const PAYMENT_STATUS_LABELS: Record<string, string> = {
  a_jour: 'À jour',
  a_surveiller: 'À surveiller',
  en_retard: 'En retard',
};

export default function BusinessClientsPage() {
  const [clients, setClients] = useState<Client[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [search, setSearch] = useState('');
  const [statusFilter, setStatusFilter] = useState('');

  useEffect(() => {
    supabase.auth.getUser().then(async ({ data }) => {
      if (!data.user) return;
      const { data: profile } = await fetchOrgProfile();
      if (profile?.organization_id) {
        const { data: clientsData, error: clientsError } = await fetchClients(profile.organization_id, {
          paymentStatus: statusFilter || undefined,
        });
        if (clientsError) setError(clientsError.message);
        else setClients((clientsData as Client[]) ?? []);
        setLoading(false);
      }
    });
  }, [statusFilter]);

  const filtered = clients.filter(c => {
    if (!search) return true;
    const q = search.toLowerCase();
    return c.full_name?.toLowerCase().includes(q) || c.phone?.toLowerCase().includes(q);
  });

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div className="flex items-center justify-between">
        <div>
          <h1 className="text-2xl font-bold text-white">Clients</h1>
          <p className="text-sm text-[#A0AEC0] mt-1">{clients.length} client{clients.length !== 1 ? 's' : ''} au total</p>
        </div>
      </div>

      {/* KPI */}
      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-4">
          <p className="text-xs text-[#A0AEC0] mb-1">Total clients</p>
          <p className="text-2xl font-bold text-white">{clients.length}</p>
        </div>
        <div className="bg-[#0F2347] border border-green-500/20 rounded-2xl p-4">
          <p className="text-xs text-[#A0AEC0] mb-1">À jour</p>
          <p className="text-2xl font-bold text-green-400">{clients.filter(c => c.payment_status === 'a_jour').length}</p>
        </div>
        <div className="bg-[#0F2347] border border-red-500/20 rounded-2xl p-4">
          <p className="text-xs text-[#A0AEC0] mb-1">En retard</p>
          <p className="text-2xl font-bold text-red-400">{clients.filter(c => c.payment_status === 'en_retard').length}</p>
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
            placeholder="Rechercher par nom, téléphone..."
            className="w-full bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm placeholder-[#718096] focus:outline-none focus:border-[#D4AF37]/60"
          />
        </div>
        <select
          value={statusFilter}
          onChange={e => setStatusFilter(e.target.value)}
          className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-[#A0AEC0] text-sm focus:outline-none focus:border-[#D4AF37]/60"
        >
          <option value="">Tous les statuts</option>
          <option value="a_jour">À jour</option>
          <option value="a_surveiller">À surveiller</option>
          <option value="en_retard">En retard</option>
        </select>
      </div>

      {/* Table */}
      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
        {loading ? (
          <div className="py-16 text-center text-[#A0AEC0] text-sm">Chargement des clients...</div>
        ) : error ? (
          <div className="py-16 text-center text-red-400 text-sm">{error}</div>
        ) : filtered.length === 0 ? (
          <div className="py-16 text-center">
            <Users size={32} className="mx-auto mb-3 text-[#718096] opacity-50" />
            <p className="text-[#A0AEC0] text-sm">Aucun client visible</p>
            <p className="text-xs text-[#718096] mt-2 max-w-md mx-auto">Les clients et prospects sont privés : chaque prospecteur gère son propre portefeuille depuis son espace terrain. Vous suivez ici les ventes, les paiements et les résultats de l’équipe.</p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[#D4AF37]/10">
                  <th className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider">Client</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider">Téléphone</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider">Prospecteur</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider">Solde</th>
                  <th className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider">Statut paiement</th>
                  <th className="px-4 py-3"></th>
                </tr>
              </thead>
              <tbody>
                {filtered.map(client => (
                  <tr key={client.id} className="border-b border-[#D4AF37]/5 hover:bg-[#0A1628]/40 transition-colors">
                    <td className="px-4 py-3">
                      <p className="text-sm font-medium text-white">{client.full_name}</p>
                    </td>
                    <td className="px-4 py-3 text-sm text-[#A0AEC0]">{client.phone ?? '—'}</td>
                    <td className="px-4 py-3 text-sm text-[#A0AEC0]">{client.profiles?.full_name ?? '—'}</td>
                    <td className="px-4 py-3 text-sm font-semibold text-[#D4AF37]">
                      {new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format((client.balance_cents ?? 0) / 100)}
                    </td>
                    <td className="px-4 py-3">
                      <span className={`inline-flex items-center px-2.5 py-1 rounded-lg text-xs font-medium border ${PAYMENT_STATUS_COLORS[client.payment_status] ?? 'bg-gray-500/20 text-gray-400 border-gray-500/30'}`}>
                        {PAYMENT_STATUS_LABELS[client.payment_status] ?? client.payment_status}
                      </span>
                    </td>
                    <td className="px-4 py-3">
                      <Link
                        href={`/business/dashboard/clients/${client.id}`}
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
