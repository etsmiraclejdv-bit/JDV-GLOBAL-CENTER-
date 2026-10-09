'use client';
import React, { useState, useEffect, useRef } from 'react';
import { Users, ShoppingCart, Wallet, TrendingUp, AlertTriangle, UserCheck } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchClients } from '@/lib/services/clientsService';
import { fetchSales } from '@/lib/services/salesService';
import Link from 'next/link';
import { fetchOrgProfile } from '@/lib/auth/context';

interface DashboardStats {
  clients: number;
  sales: number;
  revenue: number;
  overdue: number;
}

export default function BusinessDashboardPage() {
  const [orgName, setOrgName] = useState('');
  const [orgId, setOrgId] = useState<string | null>(null);
  const [stats, setStats] = useState<DashboardStats>({ clients: 0, sales: 0, revenue: 0, overdue: 0 });
  const [loading, setLoading] = useState(true);
  const channelRef = useRef<ReturnType<typeof supabase.channel> | null>(null);

  async function loadStats(oid: string) {
    const [clientsRes, salesRes] = await Promise.all([
      fetchClients(oid),
      fetchSales(oid),
    ]);
    const clients = clientsRes.data ?? [];
    const sales = salesRes.data ?? [];
    const revenue = sales.reduce((sum: number, s: Record<string, unknown>) => sum + ((s.amount_cents as number) ?? 0), 0);
    const overdue = (clients as Record<string, unknown>[]).filter(c => c.payment_status === 'en_retard').length;
    setStats({ clients: clients.length, sales: sales.length, revenue, overdue });
  }

  useEffect(() => {
    supabase.auth.getUser().then(async ({ data }) => {
      if (!data.user) return;
      const { data: profile } = await fetchOrgProfile();
      if (!profile?.organization_id) { setLoading(false); return; }
      const oid = profile.organization_id;
      setOrgId(oid);

      const { data: org } = await supabase.from('organizations').select('name').eq('id', oid).single();
      if (org) setOrgName(org.name ?? '');

      await loadStats(oid);
      setLoading(false);

      // Real-time subscription for KPI cards
      const channel = supabase
        .channel(`business-kpi-${oid}`)
        .on(
          'postgres_changes',
          { event: '*', schema: 'public', table: 'sales', filter: `organization_id=eq.${oid}` },
          () => { loadStats(oid); }
        )
        .on(
          'postgres_changes',
          { event: '*', schema: 'public', table: 'payments', filter: `organization_id=eq.${oid}` },
          () => { loadStats(oid); }
        )
        .on(
          'postgres_changes',
          { event: '*', schema: 'public', table: 'clients', filter: `organization_id=eq.${oid}` },
          () => { loadStats(oid); }
        )
        .subscribe();

      channelRef.current = channel;
    });

    return () => {
      if (channelRef.current) {
        supabase.removeChannel(channelRef.current);
        channelRef.current = null;
      }
    };
  }, []);

  const kpis = [
    { label: 'Clients', value: stats.clients, icon: <Users size={20} />, color: 'text-[#63B3ED]', href: '/business/dashboard/clients' },
    { label: 'Ventes', value: stats.sales, icon: <ShoppingCart size={20} />, color: 'text-[#D4AF37]', href: '/business/dashboard/ventes' },
    { label: 'Chiffre d\'affaires', value: new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(stats.revenue / 100), icon: <Wallet size={20} />, color: 'text-green-400', href: '/business/dashboard/ventes' },
    { label: 'Clients en retard', value: stats.overdue, icon: <AlertTriangle size={20} />, color: 'text-red-400', href: '/business/dashboard/clients' },
  ];

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Tableau de bord</h1>
        {orgName && <p className="text-sm text-[#A0AEC0] mt-1">{orgName}</p>}
      </div>

      {/* KPI Grid */}
      <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
        {kpis.map(kpi => (
          <Link key={kpi.label} href={kpi.href} className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5 hover:border-[#D4AF37]/40 transition-all">
            <div className={`mb-3 ${kpi.color}`}>{kpi.icon}</div>
            <p className="text-xs text-[#A0AEC0] mb-1">{kpi.label}</p>
            <p className={`text-2xl font-bold ${kpi.color}`}>{loading ? '—' : kpi.value}</p>
          </Link>
        ))}
      </div>

      {/* Quick Links */}
      <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4">
        {[
          { label: 'Gérer les clients', href: '/business/dashboard/clients', icon: <Users size={16} />, desc: 'Voir et gérer vos clients' },
          { label: 'Voir les ventes', href: '/business/dashboard/ventes', icon: <ShoppingCart size={16} />, desc: 'Historique des ventes' },
          { label: 'Catalogue articles', href: '/business/dashboard/catalogue', icon: <TrendingUp size={16} />, desc: 'Gérer vos produits' },
          { label: 'Rapports', href: '/business/dashboard/reports', icon: <TrendingUp size={16} />, desc: 'Analyses et statistiques' },
          { label: 'Journal d\'audit', href: '/business/dashboard/audit', icon: <UserCheck size={16} />, desc: 'Traçabilité des actions' },
          { label: 'Paramètres', href: '/business/dashboard/settings', icon: <UserCheck size={16} />, desc: 'Configuration de l\'organisation' },
        ].map(link => (
          <Link
            key={link.href}
            href={link.href}
            className="flex items-center gap-4 p-4 bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl hover:border-[#D4AF37]/40 hover:bg-[#0A1628] transition-all"
          >
            <div className="w-10 h-10 rounded-xl bg-[#D4AF37]/10 flex items-center justify-center text-[#D4AF37] flex-shrink-0">
              {link.icon}
            </div>
            <div>
              <p className="text-sm font-semibold text-white">{link.label}</p>
              <p className="text-xs text-[#718096]">{link.desc}</p>
            </div>
          </Link>
        ))}
      </div>
    </div>
  );
}
