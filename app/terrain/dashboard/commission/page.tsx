'use client';
import React, { useState, useEffect } from 'react';
import { TrendingUp, Wallet, Info } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchSales } from '@/lib/services/salesService';
import { fetchOrgProfile } from '@/lib/auth/context';

export default function TerrainCommissionPage() {
  const [totalSales, setTotalSales] = useState(0);
  const [totalAmount, setTotalAmount] = useState(0);
  const [commissionPending, setCommissionPending] = useState(0);
  const [commissionPaid, setCommissionPaid] = useState(0);
  const [loading, setLoading] = useState(true);
  const [orgCurrency, setOrgCurrency] = useState('XOF');

  useEffect(() => {
    supabase?.auth?.getUser()?.then(async ({ data }) => {
      if (!data?.user) return;
      const { data: profile } = await fetchOrgProfile();
      if (profile?.organization_id) {
        const { data: org } = await supabase
          .from('organizations')
          .select('currency')
          .eq('id', profile.organization_id)
          .single();
        if (org?.currency) setOrgCurrency(org.currency);

        if (profile.prospecteur_id) {
          const [{ data: salesData }, { data: comms }] = await Promise.all([
            fetchSales(profile.organization_id, { prospecteurId: profile.prospecteur_id }),
            supabase.from('commissions').select('commission_amount, status').eq('organization_id', profile.organization_id).eq('prospecteur_id', profile.prospecteur_id),
          ]);
          const completed = (salesData ?? [])?.filter(s => s?.status === 'completed');
          setTotalSales(completed?.length);
          setTotalAmount(completed?.reduce((sum, s) => sum + (s?.amount_cents ?? 0), 0));
          const rows = (comms ?? []) as { commission_amount: number | null; status: string }[];
          setCommissionPending(rows.filter(c => c.status !== 'paid').reduce((sum, c) => sum + (Number(c.commission_amount) || 0) * 100, 0));
          setCommissionPaid(rows.filter(c => c.status === 'paid').reduce((sum, c) => sum + (Number(c.commission_amount) || 0) * 100, 0));
        }
      }
      setLoading(false);
    });
  }, []);

  const fmt = (cents: number) =>
    new Intl.NumberFormat('fr-FR', { style: 'currency', currency: orgCurrency, maximumFractionDigits: 0 }).format(cents / 100);

  return (
    <div className="p-5 lg:p-8 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Ma commission</h1>
        <p className="text-sm text-[#A0AEC0] mt-1">Basée sur vos ventes complétées et validées</p>
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5">
          <div className="flex items-center gap-2 mb-3">
            <TrendingUp size={16} className="text-[#D4AF37]" />
            <p className="text-xs text-[#A0AEC0]">Ventes complétées</p>
          </div>
          <p className="text-3xl font-bold text-white">{loading ? '—' : totalSales}</p>
        </div>
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5">
          <div className="flex items-center gap-2 mb-3">
            <Wallet size={16} className="text-[#D4AF37]" />
            <p className="text-xs text-[#A0AEC0]">Chiffre d&apos;affaires généré</p>
          </div>
          <p className="text-3xl font-bold text-[#D4AF37]">
            {loading ? '—' : fmt(totalAmount)}
          </p>
        </div>
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5">
          <p className="text-xs text-[#A0AEC0] mb-3">Commission à recevoir</p>
          <p className="text-3xl font-bold text-white">{loading ? '—' : fmt(commissionPending)}</p>
        </div>
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5">
          <p className="text-xs text-[#A0AEC0] mb-3">Commission déjà payée</p>
          <p className="text-3xl font-bold text-green-400">{loading ? '—' : fmt(commissionPaid)}</p>
        </div>
      </div>

      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5">
        <div className="flex items-center gap-2 mb-3">
          <Info size={16} className="text-[#63B3ED]" />
          <p className="text-sm font-semibold text-white">À propos de votre commission</p>
        </div>
        <p className="text-sm text-[#A0AEC0] leading-relaxed">
          Votre commission est calculée par votre administrateur sur la base de vos ventes complétées et validées.
          Le taux de commission est défini dans les paramètres de votre organisation.
          Contactez votre responsable pour connaître votre taux exact et le calendrier de règlement.
        </p>
      </div>
    </div>
  );
}
