'use client';
import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { AlertTriangle, CheckCircle, Clock, CreditCard, RefreshCw } from 'lucide-react';
import { fetchPaymentsOverview, type PaymentsOverview } from '@/lib/services/platformPaymentsService';
import {
  eventTypeLabel,
  formatDateTimeFr,
  formatMoney,
  paymentStatusLabel,
  shortId,
  summarizePayments,
  summarizeWebhooks,
  webhookHealth,
  webhookStatusLabel,
} from '@/lib/platform/paymentsHelpers';
import MetricCard from '@/components/ui/MetricCard';
import LoadingState from '@/components/ui/LoadingState';
import ErrorState from '@/components/ui/ErrorState';

const PAYMENT_CLASSES: Record<string, string> = {
  successful: 'bg-green-500/20 text-green-400 border-green-500/30',
  pending: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  failed: 'bg-red-500/20 text-red-400 border-red-500/30',
  refunded: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
  cancelled: 'bg-gray-500/20 text-gray-300 border-gray-500/30',
};

const WEBHOOK_CLASSES: Record<string, string> = {
  processed: 'bg-green-500/20 text-green-400 border-green-500/30',
  ignored: 'bg-gray-500/20 text-gray-300 border-gray-500/30',
  failed: 'bg-red-500/20 text-red-400 border-red-500/30',
  received: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
};

const HEALTH_CLASSES = {
  none: 'border-yellow-500/30 bg-yellow-500/10 text-yellow-200',
  errors: 'border-red-500/30 bg-red-500/10 text-red-300',
  ok: 'border-green-500/30 bg-green-500/10 text-green-300',
} as const;

const TH = 'text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider whitespace-nowrap';

export default function PlatformPaymentsView() {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [data, setData] = useState<PaymentsOverview | null>(null);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    const res = await fetchPaymentsOverview();
    if (res.error) setError(res.error);
    setData(res.data);
    setLoading(false);
  }, []);

  useEffect(() => {
    void load();
  }, [load]);

  const payments = useMemo(() => summarizePayments(data?.payments ?? []), [data]);
  const webhooks = useMemo(() => summarizeWebhooks(data?.webhooks ?? []), [data]);
  const health = useMemo(() => webhookHealth(webhooks), [webhooks]);
  const orgName = (id: string | null) => (id && data?.orgNames[id]) || '—';

  if (loading && !data) return <LoadingState message="Chargement des paiements…" />;
  if (error && !data) return <ErrorState message={error} action={{ label: 'Réessayer', onClick: () => void load() }} />;
  if (!data) return null;

  const failedWebhooks = data.webhooks.filter((w) => w.status === 'failed');

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-white">Paiements et webhooks</h1>
          <p className="text-sm text-[#A0AEC0] mt-1">Suivi des abonnements payés et des notifications reçues de FedaPay</p>
        </div>
        <button
          onClick={() => void load()}
          disabled={loading}
          aria-label="Actualiser"
          className="flex items-center gap-2 btn-outline-gold px-4 py-2.5 rounded-xl text-sm font-semibold disabled:opacity-50"
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

      <div className={`rounded-xl border px-4 py-3 text-sm ${HEALTH_CLASSES[health.state]}`} role="status">
        <p>{health.message}</p>
        {webhooks.lastReceivedAt && (
          <p className="text-xs opacity-80 mt-1">Dernier webhook reçu : {formatDateTimeFr(webhooks.lastReceivedAt)}</p>
        )}
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <MetricCard
          title="Paiements réussis"
          value={String(payments.successful)}
          subtitle={`${formatMoney(payments.successfulAmountXof, 'XOF')}${payments.otherCurrencies ? ' (hors autres devises)' : ''}`}
          icon={<CheckCircle size={18} />}
          variant="success"
        />
        <MetricCard title="En attente" value={String(payments.pending)} subtitle="paiements non finalisés" icon={<Clock size={18} />} variant={payments.pending > 0 ? 'warning' : 'default'} />
        <MetricCard title="Échoués" value={String(payments.failed)} subtitle="paiements refusés ou en erreur" icon={<AlertTriangle size={18} />} variant={payments.failed > 0 ? 'danger' : 'default'} />
        <MetricCard title="Webhooks reçus" value={String(webhooks.total)} subtitle={`${webhooks.processed} traité(s) · ${webhooks.failed} en échec`} icon={<CreditCard size={18} />} variant={webhooks.failed > 0 ? 'danger' : 'gold'} />
      </div>

      {failedWebhooks.length > 0 && (
        <div className="bg-[#0F2347] border border-red-500/30 rounded-2xl overflow-hidden">
          <div className="px-5 py-4 border-b border-red-500/20">
            <h2 className="text-sm font-semibold text-red-300">Webhooks en échec ({failedWebhooks.length})</h2>
          </div>
          <ul className="divide-y divide-[#D4AF37]/5">
            {failedWebhooks.slice(0, 10).map((w) => (
              <li key={w.id} className="px-5 py-3">
                <p className="text-sm text-white">
                  {eventTypeLabel(w.event_type)} · <span className="text-[#718096]">{formatDateTimeFr(w.created_at)}</span>
                </p>
                <p className="text-xs text-red-300 mt-0.5 break-words">{w.error_message || 'Aucun message d’erreur enregistré.'}</p>
              </li>
            ))}
          </ul>
        </div>
      )}

      {/* Paiements */}
      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
        <div className="px-5 py-4 border-b border-[#D4AF37]/10">
          <h2 className="text-sm font-semibold text-white">Paiements d’abonnement</h2>
          <p className="text-xs text-[#718096] mt-0.5">100 plus récents</p>
        </div>
        {data.payments.length === 0 ? (
          <p className="px-5 py-10 text-sm text-[#A0AEC0] text-center">Aucun paiement enregistré.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[#D4AF37]/10">
                  {['Date', 'Entreprise', 'Montant', 'Mode', 'Référence', 'Statut'].map((h) => (
                    <th key={h} className={TH}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {data.payments.map((p) => (
                  <tr key={p.id} className="border-b border-[#D4AF37]/5 hover:bg-[#0B1B3D]/50">
                    <td className="px-4 py-3 text-sm text-[#A0AEC0] whitespace-nowrap">{formatDateTimeFr(p.paid_at ?? p.created_at)}</td>
                    <td className="px-4 py-3 text-sm text-white">{orgName(p.organization_id)}</td>
                    <td className="px-4 py-3 text-sm font-semibold text-white whitespace-nowrap">{formatMoney(p.amount, p.currency)}</td>
                    <td className="px-4 py-3 text-sm text-[#A0AEC0] whitespace-nowrap">{p.payment_method || p.provider || '—'}</td>
                    <td className="px-4 py-3 text-xs text-[#718096] whitespace-nowrap" title={p.provider_reference ?? undefined}>{shortId(p.provider_reference, 14)}</td>
                    <td className="px-4 py-3 whitespace-nowrap">
                      <span className={`inline-flex text-xs font-semibold px-2.5 py-1 rounded-full border ${PAYMENT_CLASSES[p.status] ?? PAYMENT_CLASSES.cancelled}`}>
                        {paymentStatusLabel(p.status)}
                      </span>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {/* Webhooks */}
      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
        <div className="px-5 py-4 border-b border-[#D4AF37]/10">
          <h2 className="text-sm font-semibold text-white">Webhooks reçus</h2>
          <p className="text-xs text-[#718096] mt-0.5">100 plus récents · le contenu brut n’est pas affiché (données personnelles)</p>
        </div>
        {data.webhooks.length === 0 ? (
          <p className="px-5 py-10 text-sm text-[#A0AEC0] text-center">Aucun webhook reçu.</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[#D4AF37]/10">
                  {['Reçu le', 'Événement', 'Entreprise', 'Identifiant', 'Statut', 'Message'].map((h) => (
                    <th key={h} className={TH}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {data.webhooks.map((w) => (
                  <tr key={w.id} className="border-b border-[#D4AF37]/5 hover:bg-[#0B1B3D]/50">
                    <td className="px-4 py-3 text-sm text-[#A0AEC0] whitespace-nowrap">{formatDateTimeFr(w.created_at)}</td>
                    <td className="px-4 py-3 text-sm text-white whitespace-nowrap">{eventTypeLabel(w.event_type)}</td>
                    <td className="px-4 py-3 text-sm text-[#A0AEC0]">{orgName(w.organization_id)}</td>
                    <td className="px-4 py-3 text-xs text-[#718096] whitespace-nowrap" title={w.external_event_id ?? undefined}>{shortId(w.external_event_id)}</td>
                    <td className="px-4 py-3 whitespace-nowrap">
                      <span className={`inline-flex text-xs font-semibold px-2.5 py-1 rounded-full border ${WEBHOOK_CLASSES[w.status] ?? WEBHOOK_CLASSES.ignored}`}>
                        {webhookStatusLabel(w.status)}
                      </span>
                    </td>
                    <td className="px-4 py-3 text-xs text-[#A0AEC0] max-w-xs break-words">{w.error_message || '—'}</td>
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
