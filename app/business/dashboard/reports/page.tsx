'use client';
import React, { useState, useEffect } from 'react';
import { TrendingUp, Wallet, ShoppingCart, BarChart2 } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchSales } from '@/lib/services/salesService';
import { fetchClients } from '@/lib/services/clientsService';
import { fetchOrgProfile } from '@/lib/auth/context';

export default function BusinessReportsPage() {
  const [loading, setLoading] = useState(true);
  const [stats, setStats] = useState({
    totalRevenue: 0,
    totalSales: 0,
    totalClients: 0,
    completedSales: 0,
    pendingSales: 0,
    overdueClients: 0,
    totalBalance: 0,
  });
  const [monthlySales, setMonthlySales] = useState<{ month: string; amount: number; count: number }[]>([]);

  useEffect(() => {
    supabase.auth.getUser().then(async ({ data }) => {
      if (!data.user) return;
      const { data: profile } = await fetchOrgProfile();
      if (!profile?.organization_id) { setLoading(false); return; }
      const oid = profile.organization_id;

      const [salesRes, clientsRes] = await Promise.all([
        fetchSales(oid),
        fetchClients(oid),
      ]);

      const sales = salesRes.data ?? [];
      const clients = clientsRes.data ?? [];

      const totalRevenue = sales.reduce((sum, s) => sum + (s.amount_cents ?? 0), 0);
      const completedSales = sales.filter(s => s.status === 'completed' || s.status === 'encaissé').length;
      const pendingSales = sales.filter(s => s.status === 'pending').length;
      const overdueClients = (clients as { payment_status: string }[]).filter(c => c.payment_status === 'en_retard').length;
      const totalBalance = (clients as { balance_cents: number }[]).reduce((sum, c) => sum + (c.balance_cents ?? 0), 0);

      // Monthly breakdown
      const monthMap: Record<string, { amount: number; count: number }> = {};
      sales.forEach(s => {
        const d = new Date(s.sold_at);
        const key = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}`;
        if (!monthMap[key]) monthMap[key] = { amount: 0, count: 0 };
        monthMap[key].amount += s.amount_cents ?? 0;
        monthMap[key].count += 1;
      });

      const monthly = Object.entries(monthMap)
        .sort(([a], [b]) => b.localeCompare(a))
        .slice(0, 6)
        .map(([month, data]) => ({
          month: new Date(month + '-01').toLocaleDateString('fr-FR', { month: 'long', year: 'numeric' }),
          ...data,
        }));

      setStats({ totalRevenue, totalSales: sales.length, totalClients: clients.length, completedSales, pendingSales, overdueClients, totalBalance });
      setMonthlySales(monthly);
      setLoading(false);
    });
  }, []);

  const fmt = (cents: number) =>
    new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(cents / 100);

  const maxAmount = Math.max(...monthlySales.map(m => m.amount), 1);

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Rapports</h1>
        <p className="text-sm text-[#A0AEC0] mt-1">Statistiques et analyses de votre organisation</p>
      </div>

      {/* KPI Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {[
          { label: 'Chiffre d\'affaires', value: loading ? '—' : fmt(stats.totalRevenue), icon: <Wallet size={18} />, color: 'text-[#D4AF37]' },
          { label: 'Total ventes', value: loading ? '—' : stats.totalSales, icon: <ShoppingCart size={18} />, color: 'text-blue-400' },
          { label: 'Clients actifs', value: loading ? '—' : stats.totalClients, icon: <TrendingUp size={18} />, color: 'text-green-400' },
          { label: 'Clients en retard', value: loading ? '—' : stats.overdueClients, icon: <BarChart2 size={18} />, color: 'text-red-400' },
        ].map((kpi, i) => (
          <div key={i} className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5">
            <div className={`mb-3 ${kpi.color}`}>{kpi.icon}</div>
            <p className={`text-2xl font-bold ${kpi.color}`}>{kpi.value}</p>
            <p className="text-xs text-[#718096] mt-1">{kpi.label}</p>
          </div>
        ))}
      </div>

      {/* Sales status breakdown */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-6">
          <h2 className="text-base font-semibold text-white mb-4">Statut des ventes</h2>
          <div className="space-y-3">
            {[
              { label: 'Complétées', value: stats.completedSales, color: 'bg-green-400', total: stats.totalSales },
              { label: 'En attente', value: stats.pendingSales, color: 'bg-yellow-400', total: stats.totalSales },
            ].map((item, i) => (
              <div key={i}>
                <div className="flex justify-between text-xs mb-1">
                  <span className="text-[#A0AEC0]">{item.label}</span>
                  <span className="text-white font-medium">{loading ? '—' : item.value}</span>
                </div>
                <div className="h-2 bg-[#0A1628] rounded-full overflow-hidden">
                  <div
                    className={`h-full ${item.color} rounded-full transition-all`}
                    style={{ width: loading || item.total === 0 ? '0%' : `${(item.value / item.total) * 100}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>

        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-6">
          <h2 className="text-base font-semibold text-white mb-4">Soldes clients</h2>
          <div className="space-y-3">
            <div className="flex justify-between items-center p-3 bg-[#0A1628] rounded-xl">
              <span className="text-sm text-[#A0AEC0]">Total soldes dus</span>
              <span className="text-sm font-bold text-[#D4AF37]">{loading ? '—' : fmt(stats.totalBalance)}</span>
            </div>
            <div className="flex justify-between items-center p-3 bg-[#0A1628] rounded-xl">
              <span className="text-sm text-[#A0AEC0]">Clients en retard</span>
              <span className="text-sm font-bold text-red-400">{loading ? '—' : stats.overdueClients}</span>
            </div>
          </div>
        </div>
      </div>

      {/* Monthly chart */}
      {monthlySales.length > 0 && (
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-6">
          <h2 className="text-base font-semibold text-white mb-5">Ventes par mois (6 derniers mois)</h2>
          <div className="space-y-3">
            {monthlySales.map((m, i) => (
              <div key={i}>
                <div className="flex justify-between text-xs mb-1">
                  <span className="text-[#A0AEC0] capitalize">{m.month}</span>
                  <span className="text-white font-medium">{fmt(m.amount)} <span className="text-[#718096]">({m.count} vente{m.count !== 1 ? 's' : ''})</span></span>
                </div>
                <div className="h-2 bg-[#0A1628] rounded-full overflow-hidden">
                  <div
                    className="h-full bg-[#D4AF37] rounded-full transition-all"
                    style={{ width: `${(m.amount / maxAmount) * 100}%` }}
                  />
                </div>
              </div>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
