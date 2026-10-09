'use client';
import React, { useCallback, useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { AlertTriangle, Calendar, Check, CheckCircle, RefreshCw, ShoppingCart, TrendingUp, Users, Wallet, X } from 'lucide-react';
import { toast } from 'sonner';
import { getAuthContext } from '@/lib/auth/context';
import { fetchProspecteurNames } from '@/lib/services/relancesService';
import { fetchByProspecteur, fetchCommissions, fetchDashboard, settleCommission } from '@/lib/services/financeService';
import { formatDateFr, formatXof } from '@/lib/relances/helpers';
import {
  PRESET_LABELS,
  canSettle,
  commissionLabel,
  formatRate,
  isValidPeriod,
  percent,
  periodForPreset,
  sortProspecteurRows,
  totalsByProspecteur,
  unpaidCommissionTotal,
  type CommissionRow,
  type FinancialDashboard,
  type PeriodPreset,
  type ProspecteurRow,
} from '@/lib/finances/helpers';
import MetricCard from '@/components/ui/MetricCard';
import LoadingState from '@/components/ui/LoadingState';
import ErrorState from '@/components/ui/ErrorState';

const PRESETS = Object.keys(PRESET_LABELS) as PeriodPreset[];

const STATUS_CLASSES: Record<string, string> = {
  pending: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  approved: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
  paid: 'bg-green-500/20 text-green-400 border-green-500/30',
  cancelled: 'bg-red-500/20 text-red-400 border-red-500/30',
};

export default function FinancesView() {
  const initial = useMemo(() => periodForPreset('month', new Date()), []);
  const [orgId, setOrgId] = useState<string | null>(null);
  const [preset, setPreset] = useState<PeriodPreset | 'custom'>('month');
  const [start, setStart] = useState(initial.start);
  const [end, setEnd] = useState(initial.end);
  const [range, setRange] = useState(initial);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [dashboard, setDashboard] = useState<FinancialDashboard | null>(null);
  const [rows, setRows] = useState<ProspecteurRow[]>([]);
  const [commissions, setCommissions] = useState<CommissionRow[]>([]);
  const [names, setNames] = useState<Record<string, string>>({});
  const [onlyUnpaid, setOnlyUnpaid] = useState(true);
  const [confirmId, setConfirmId] = useState<string | null>(null);
  const [busyId, setBusyId] = useState<string | null>(null);

  const load = useCallback(async (organizationId: string | null, from: string, to: string) => {
    setLoading(true);
    setError('');
    let org = organizationId;
    if (!org) {
      const ctx = await getAuthContext();
      if (!ctx) {
        setError("Vous n'êtes pas connecté.");
        setLoading(false);
        return;
      }
      if (!ctx.organizationId || !ctx.isOrgAdmin) {
        setError("Cette page est réservée à l'administrateur de l'entreprise.");
        setLoading(false);
        return;
      }
      org = ctx.organizationId;
      setOrgId(org);
    }
    const [d, p, c, n] = await Promise.all([
      fetchDashboard(org, from, to),
      fetchByProspecteur(org, from, to),
      fetchCommissions(org, from, to),
      fetchProspecteurNames(org),
    ]);
    const firstError = d.error || p.error || c.error;
    if (firstError) setError(firstError);
    setDashboard(d.data);
    setRows(p.data);
    setCommissions(c.data);
    setNames(n);
    setConfirmId(null);
    setLoading(false);
  }, []);

  useEffect(() => {
    void load(null, initial.start, initial.end);
  }, [load, initial]);

  function applyPreset(next: PeriodPreset) {
    const p = periodForPreset(next, new Date());
    setPreset(next);
    setStart(p.start);
    setEnd(p.end);
    setRange(p);
    void load(orgId, p.start, p.end);
  }

  function applyCustom() {
    if (!isValidPeriod(start, end)) {
      toast.error('Période invalide : la date de fin doit suivre la date de début (5 ans maximum).');
      return;
    }
    setPreset('custom');
    setRange({ start, end });
    void load(orgId, start, end);
  }

  async function handleSettle(id: string) {
    setBusyId(id);
    const { paidAt, error: err } = await settleCommission(id);
    setBusyId(null);
    setConfirmId(null);
    if (err) {
      toast.error(err);
      return;
    }
    toast.success('Commission marquée comme payée.');
    setCommissions((prev) => prev.map((c) => (c.commission_id === id ? { ...c, status: 'paid', paid_at: paidAt } : c)));
    void load(orgId, range.start, range.end);
  }

  const sortedRows = useMemo(() => sortProspecteurRows(rows), [rows]);
  const totals = useMemo(() => totalsByProspecteur(rows), [rows]);
  const visibleCommissions = useMemo(
    () => (onlyUnpaid ? commissions.filter((c) => canSettle(c.status)) : commissions),
    [commissions, onlyUnpaid]
  );
  const prospecteurName = (id: string | null) => (id ? names[id] || 'Prospecteur' : 'Sans prospecteur');

  if (loading && !dashboard) return <LoadingState message="Chargement des chiffres…" />;
  if (error && !dashboard) {
    return <ErrorState message={error} action={{ label: 'Réessayer', onClick: () => void load(orgId, range.start, range.end) }} />;
  }

  return (
    <div className="p-6 lg:p-8 space-y-6">
      {/* En-tête */}
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-white">Finances et commissions</h1>
          <p className="text-sm text-[#A0AEC0] mt-1">
            Période du {formatDateFr(range.start)} au {formatDateFr(range.end)}
          </p>
        </div>
        <button
          onClick={() => void load(orgId, range.start, range.end)}
          disabled={loading}
          className="flex items-center gap-2 btn-outline-gold px-4 py-2.5 rounded-xl text-sm font-semibold disabled:opacity-50"
          aria-label="Actualiser les chiffres"
        >
          <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
          Actualiser
        </button>
      </div>

      {error && (
        <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300" role="alert">
          {error}
        </div>
      )}

      {/* Période */}
      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-4 flex flex-col xl:flex-row xl:items-end gap-4">
        <div className="flex flex-wrap gap-2" role="group" aria-label="Période prédéfinie">
          {PRESETS.map((p) => (
            <button
              key={p}
              onClick={() => applyPreset(p)}
              aria-pressed={preset === p}
              className={`px-3.5 py-2 rounded-xl text-sm font-medium border transition-all ${
                preset === p
                  ? 'bg-[#D4AF37]/15 text-[#D4AF37] border-[#D4AF37]/50'
                  : 'bg-[#0B1B3D] text-[#A0AEC0] border-[#D4AF37]/20 hover:text-white'
              }`}
            >
              {PRESET_LABELS[p]}
            </button>
          ))}
        </div>
        <div className="flex flex-wrap items-end gap-3 xl:ml-auto">
          <label className="text-xs text-[#A0AEC0]">
            Du
            <input
              type="date"
              value={start}
              onChange={(e) => setStart(e.target.value)}
              className="mt-1 block bg-[#0B1B3D] border border-[#D4AF37]/20 rounded-xl px-3 py-2 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
            />
          </label>
          <label className="text-xs text-[#A0AEC0]">
            Au
            <input
              type="date"
              value={end}
              onChange={(e) => setEnd(e.target.value)}
              className="mt-1 block bg-[#0B1B3D] border border-[#D4AF37]/20 rounded-xl px-3 py-2 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
            />
          </label>
          <button
            onClick={applyCustom}
            className="flex items-center gap-2 btn-gold px-4 py-2.5 rounded-xl text-sm font-bold"
          >
            <Calendar size={14} />
            Appliquer
          </button>
        </div>
      </div>

      {/* Indicateurs */}
      {dashboard && (
        <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-3 gap-4">
          <MetricCard
            title="Ventes de la période"
            value={formatXof(dashboard.salesTotal)}
            subtitle={`${dashboard.salesCount} vente(s)`}
            icon={<ShoppingCart size={18} />}
            variant="gold"
          />
          <MetricCard
            title="Encaissé sur la période"
            value={formatXof(dashboard.cashCollected)}
            subtitle="paiements réussis, toutes ventes confondues"
            icon={<TrendingUp size={18} />}
            variant="success"
          />
          <MetricCard
            title="Crédit en cours"
            value={formatXof(dashboard.creditOutstanding)}
            subtitle="restant dû sur les ventes à crédit ouvertes"
            icon={<Wallet size={18} />}
            variant="default"
          />
          <MetricCard
            title="Impayés en retard"
            value={formatXof(dashboard.overdueAmount)}
            subtitle={`${dashboard.overdueSchedules} échéance(s), état actuel`}
            icon={<AlertTriangle size={18} />}
            variant={dashboard.overdueSchedules > 0 ? 'danger' : 'success'}
          >
            {dashboard.overdueSchedules > 0 && (
              <Link href="/business/dashboard/relances" className="text-xs text-[#D4AF37] hover:underline mt-2 inline-block">
                Voir les relances
              </Link>
            )}
          </MetricCard>
          <MetricCard
            title="Commissions à payer"
            value={formatXof(dashboard.commissionUnpaid)}
            subtitle="en attente ou approuvées, état actuel"
            icon={<Users size={18} />}
            variant={dashboard.commissionUnpaid > 0 ? 'warning' : 'success'}
          />
          <MetricCard
            title="Commissions payées"
            value={formatXof(dashboard.commissionPaid)}
            subtitle={`réglées sur la période (total généré : ${formatXof(dashboard.commissionTotal)})`}
            icon={<CheckCircle size={18} />}
            variant="default"
          />
        </div>
      )}

      {/* Par prospecteur */}
      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
        <div className="px-5 py-4 border-b border-[#D4AF37]/10">
          <h2 className="text-sm font-semibold text-white">Résultats par prospecteur</h2>
        </div>
        {sortedRows.length === 0 ? (
          <p className="px-5 py-10 text-sm text-[#A0AEC0] text-center">Aucune vente sur cette période.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[#D4AF37]/10">
                  {['Prospecteur', 'Ventes', 'Total', 'Encaissé', 'Reste', 'Commission', 'Payée', 'À payer'].map((h) => (
                    <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider whitespace-nowrap">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {sortedRows.map((r) => (
                  <tr key={r.prospecteur_id ?? 'aucun'} className="border-b border-[#D4AF37]/5 hover:bg-[#0B1B3D]/50">
                    <td className="px-4 py-3 text-sm font-medium text-white whitespace-nowrap">{prospecteurName(r.prospecteur_id)}</td>
                    <td className="px-4 py-3 text-sm text-[#A0AEC0]">{Number(r.sales_count)}</td>
                    <td className="px-4 py-3 text-sm text-white whitespace-nowrap">{formatXof(r.sales_total)}</td>
                    <td className="px-4 py-3 whitespace-nowrap">
                      <p className="text-sm text-[#68D391]">{formatXof(r.collected)}</p>
                      <div className="mt-1 h-1.5 w-24 rounded-full bg-[#0B1B3D] overflow-hidden" aria-hidden="true">
                        <div className="h-full bg-[#68D391]" style={{ width: `${percent(r.collected, r.sales_total)}%` }} />
                      </div>
                    </td>
                    <td className="px-4 py-3 text-sm text-[#F6AD55] whitespace-nowrap">{formatXof(r.outstanding)}</td>
                    <td className="px-4 py-3 text-sm text-white whitespace-nowrap">{formatXof(r.commission_total)}</td>
                    <td className="px-4 py-3 text-sm text-[#A0AEC0] whitespace-nowrap">{formatXof(r.commission_paid)}</td>
                    <td className="px-4 py-3 text-sm font-semibold text-[#D4AF37] whitespace-nowrap">{formatXof(r.commission_unpaid)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot>
                <tr className="border-t border-[#D4AF37]/20 bg-[#0B1B3D]/40">
                  <td className="px-4 py-3 text-sm font-bold text-white">Total</td>
                  <td className="px-4 py-3 text-sm font-semibold text-white">{totals.salesCount}</td>
                  <td className="px-4 py-3 text-sm font-semibold text-white whitespace-nowrap">{formatXof(totals.salesTotal)}</td>
                  <td className="px-4 py-3 text-sm font-semibold text-[#68D391] whitespace-nowrap">{formatXof(totals.collected)}</td>
                  <td className="px-4 py-3 text-sm font-semibold text-[#F6AD55] whitespace-nowrap">{formatXof(totals.outstanding)}</td>
                  <td className="px-4 py-3 text-sm font-semibold text-white whitespace-nowrap">{formatXof(totals.commissionTotal)}</td>
                  <td className="px-4 py-3 text-sm font-semibold text-[#A0AEC0] whitespace-nowrap">{formatXof(totals.commissionPaid)}</td>
                  <td className="px-4 py-3 text-sm font-bold text-[#D4AF37] whitespace-nowrap">{formatXof(totals.commissionUnpaid)}</td>
                </tr>
              </tfoot>
            </table>
          </div>
        )}
      </div>

      {/* Commissions */}
      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
        <div className="px-5 py-4 border-b border-[#D4AF37]/10 flex flex-col sm:flex-row sm:items-center justify-between gap-3">
          <div>
            <h2 className="text-sm font-semibold text-white">Commissions de la période</h2>
            <p className="text-xs text-[#718096] mt-0.5">
              Encore à payer dans cette liste : {formatXof(unpaidCommissionTotal(commissions))}
            </p>
          </div>
          <div className="flex gap-2" role="group" aria-label="Filtrer les commissions">
            {[
              { v: true, label: 'À régler' },
              { v: false, label: 'Toutes' },
            ].map((f) => (
              <button
                key={String(f.v)}
                onClick={() => setOnlyUnpaid(f.v)}
                aria-pressed={onlyUnpaid === f.v}
                className={`px-3.5 py-1.5 rounded-xl text-xs font-medium border transition-all ${
                  onlyUnpaid === f.v
                    ? 'bg-[#D4AF37]/15 text-[#D4AF37] border-[#D4AF37]/50'
                    : 'bg-[#0B1B3D] text-[#A0AEC0] border-[#D4AF37]/20 hover:text-white'
                }`}
              >
                {f.label}
              </button>
            ))}
          </div>
        </div>
        {visibleCommissions.length === 0 ? (
          <div className="py-12 text-center px-6">
            <CheckCircle size={30} className="mx-auto mb-3 text-[#68D391] opacity-70" />
            <p className="text-sm text-[#A0AEC0]">
              {commissions.length === 0 ? 'Aucune commission sur cette période.' : 'Aucune commission à régler : tout est payé.'}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[#D4AF37]/10">
                  {['Prospecteur', 'Vente', 'Base', 'Taux', 'Commission', 'Statut', 'Action'].map((h) => (
                    <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider whitespace-nowrap">
                      {h}
                    </th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {visibleCommissions.map((c) => (
                  <tr key={c.commission_id} className="border-b border-[#D4AF37]/5 hover:bg-[#0B1B3D]/50">
                    <td className="px-4 py-3 text-sm text-white whitespace-nowrap">{prospecteurName(c.prospecteur_id)}</td>
                    <td className="px-4 py-3 text-sm whitespace-nowrap">
                      {c.sale_id ? (
                        <Link href={`/business/dashboard/ventes/${c.sale_id}`} className="text-[#D4AF37] hover:underline">
                          Voir la vente
                        </Link>
                      ) : (
                        <span className="text-[#718096]">—</span>
                      )}
                    </td>
                    <td className="px-4 py-3 text-sm text-[#A0AEC0] whitespace-nowrap">{formatXof(c.base_amount)}</td>
                    <td className="px-4 py-3 text-sm text-[#A0AEC0] whitespace-nowrap">{formatRate(c.rate)}</td>
                    <td className="px-4 py-3 text-sm font-semibold text-white whitespace-nowrap">{formatXof(c.commission_amount)}</td>
                    <td className="px-4 py-3 whitespace-nowrap">
                      <span className={`inline-flex items-center text-xs font-semibold px-2.5 py-1 rounded-full border ${STATUS_CLASSES[c.status] ?? 'bg-gray-500/20 text-gray-300 border-gray-500/30'}`}>
                        {commissionLabel(c.status)}
                      </span>
                      {c.status === 'paid' && c.paid_at && (
                        <p className="text-xs text-[#718096] mt-0.5">le {formatDateFr(c.paid_at)}</p>
                      )}
                    </td>
                    <td className="px-4 py-3 whitespace-nowrap">
                      {canSettle(c.status) ? (
                        confirmId === c.commission_id ? (
                          <div className="flex items-center gap-2">
                            <button
                              onClick={() => void handleSettle(c.commission_id)}
                              disabled={busyId === c.commission_id}
                              className="flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-bold bg-[#D4AF37] text-[#0B1B3D] hover:opacity-90 disabled:opacity-50"
                            >
                              <Check size={12} />
                              {busyId === c.commission_id ? 'En cours…' : 'Confirmer'}
                            </button>
                            <button
                              onClick={() => setConfirmId(null)}
                              disabled={busyId === c.commission_id}
                              aria-label="Annuler le règlement"
                              className="p-1.5 rounded-lg bg-[#0B1B3D] text-[#A0AEC0] border border-[#D4AF37]/20 hover:text-white"
                            >
                              <X size={12} />
                            </button>
                          </div>
                        ) : (
                          <button
                            onClick={() => setConfirmId(c.commission_id)}
                            className="px-3 py-1.5 rounded-lg text-xs font-semibold bg-[#D4AF37]/10 text-[#D4AF37] border border-[#D4AF37]/30 hover:bg-[#D4AF37]/20"
                          >
                            Marquer payée
                          </button>
                        )
                      ) : (
                        <span className="text-xs text-[#718096]">—</span>
                      )}
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
