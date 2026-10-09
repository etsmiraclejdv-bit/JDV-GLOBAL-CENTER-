'use client';
import React, { useCallback, useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { ArrowLeft, CheckCircle, Package, RefreshCw, Wallet, XCircle } from 'lucide-react';
import { toast } from 'sonner';
import { getAdminOrganization } from '@/lib/auth/admin-org';
import {
  cancelPurchaseOrder,
  fetchOrderDetail,
  payPurchaseOrder,
  receivePurchaseOrder,
  type OrderDetail,
} from '@/lib/services/purchasesService';
import {
  PAYMENT_METHODS,
  PAYMENT_STATE_LABELS,
  canCancelOrder,
  canPay,
  canReceive,
  friendlyDbError,
  orderStatusLabel,
  paidTotal,
  paymentMethodLabel,
  paymentState,
  receiptProgress,
  receivedByArticle,
  remainingByArticle,
  remainingToPay,
  validatePaymentAmount,
  validateReceiptInputs,
} from '@/lib/purchases/helpers';
import { formatDateFr, formatXof } from '@/lib/relances/helpers';
import { inputClass, labelClass } from '@/lib/ui/forms';
import Modal from '@/components/ui/Modal';
import MetricCard from '@/components/ui/MetricCard';
import LoadingState from '@/components/ui/LoadingState';
import ErrorState from '@/components/ui/ErrorState';

const STATUS_CLASSES: Record<string, string> = {
  draft: 'bg-gray-500/20 text-gray-300 border-gray-500/30',
  sent: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
  confirmed: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
  partial: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  received: 'bg-green-500/20 text-green-400 border-green-500/30',
  cancelled: 'bg-red-500/20 text-red-400 border-red-500/30',
  closed: 'bg-gray-500/20 text-gray-300 border-gray-500/30',
};

const btnGhost =
  'px-4 py-2.5 rounded-xl text-sm font-semibold bg-[#0B1B3D] text-[#A0AEC0] border border-[#D4AF37]/20 hover:text-white disabled:opacity-50';

export default function PurchaseOrderDetailView({ orderId }: { orderId: string }) {
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [detail, setDetail] = useState<OrderDetail | null>(null);

  const [receiveOpen, setReceiveOpen] = useState(false);
  const [receiveInputs, setReceiveInputs] = useState<Record<string, string>>({});
  const [receiveNotes, setReceiveNotes] = useState('');
  const [payOpen, setPayOpen] = useState(false);
  const [payAmount, setPayAmount] = useState('');
  const [payMethod, setPayMethod] = useState<string>('cash');
  const [payRef, setPayRef] = useState('');
  const [payNotes, setPayNotes] = useState('');
  const [cancelOpen, setCancelOpen] = useState(false);
  const [modalError, setModalError] = useState('');
  const [busy, setBusy] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    const { orgId, error: guardError } = await getAdminOrganization();
    if (!orgId) {
      setError(guardError ?? 'Accès impossible.');
      setLoading(false);
      return;
    }
    const res = await fetchOrderDetail(orderId);
    if (res.error || !res.data) setError(res.error ?? 'Commande introuvable.');
    setDetail(res.data);
    setLoading(false);
  }, [orderId]);

  useEffect(() => {
    void load();
  }, [load]);

  const computed = useMemo(() => {
    if (!detail) return null;
    const remaining = remainingByArticle(detail.items, detail.receipts);
    const received = receivedByArticle(detail.receipts);
    const paid = paidTotal(detail.payments);
    const toPay = remainingToPay(detail.total_amount, detail.payments);
    const names: Record<string, string> = {};
    for (const it of detail.items) names[it.article_id.toLowerCase()] = it.article_name;
    return {
      remaining,
      received,
      paid,
      toPay,
      names,
      progress: receiptProgress(detail.items, detail.receipts),
      state: paymentState(detail.total_amount, detail.payments),
    };
  }, [detail]);

  function openReceive() {
    if (!detail || !computed) return;
    const inputs: Record<string, string> = {};
    for (const it of detail.items) inputs[it.article_id] = '';
    setReceiveInputs(inputs);
    setReceiveNotes('');
    setModalError('');
    setReceiveOpen(true);
  }

  function receiveAll() {
    if (!computed) return;
    const inputs: Record<string, string> = {};
    for (const [id, qty] of Object.entries(computed.remaining)) inputs[id] = qty > 0 ? String(qty) : '';
    setReceiveInputs(inputs);
  }

  async function handleReceive() {
    if (!detail || !computed || busy) return;
    const v = validateReceiptInputs(computed.remaining, receiveInputs);
    if (v.error) {
      setModalError(v.error);
      return;
    }
    setBusy(true);
    const res = await receivePurchaseOrder(detail.id, v.items, receiveNotes);
    setBusy(false);
    if (res.error) {
      setModalError(friendlyDbError(res.error, computed.names));
      return;
    }
    toast.success(`Réception ${res.receiptNumber ?? ''} enregistrée : le stock a été mis à jour.`);
    setReceiveOpen(false);
    void load();
  }

  function openPay() {
    if (!computed) return;
    setPayAmount(String(computed.toPay));
    setPayMethod('cash');
    setPayRef('');
    setPayNotes('');
    setModalError('');
    setPayOpen(true);
  }

  async function handlePay() {
    if (!detail || !computed || busy) return;
    const v = validatePaymentAmount(payAmount, computed.toPay);
    if (v.error) {
      setModalError(v.error);
      return;
    }
    setBusy(true);
    const res = await payPurchaseOrder(detail.id, v.amount, payMethod, payRef, payNotes);
    setBusy(false);
    if (res.error) {
      setModalError(res.error);
      return;
    }
    toast.success(res.remaining === 0 ? 'Paiement enregistré : la commande est soldée.' : 'Paiement enregistré.');
    setPayOpen(false);
    void load();
  }

  async function handleCancel() {
    if (!detail || busy) return;
    setBusy(true);
    const res = await cancelPurchaseOrder(detail.id);
    setBusy(false);
    if (res.error) {
      setModalError(res.error);
      return;
    }
    toast.success('Commande annulée.');
    setCancelOpen(false);
    void load();
  }

  if (loading && !detail) return <LoadingState message="Chargement de la commande…" />;
  if (error && !detail) {
    return <ErrorState message={error} action={{ label: 'Réessayer', onClick: () => void load() }} />;
  }
  if (!detail || !computed) return null;

  const showReceive = canReceive(detail.status);
  const showPay = canPay(detail.status, computed.toPay);
  const showCancel = canCancelOrder(detail.status, computed.paid);

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <Link href="/business/dashboard/achats" className="inline-flex items-center gap-1.5 text-sm text-[#A0AEC0] hover:text-white">
        <ArrowLeft size={14} />
        Retour aux achats
      </Link>

      <div className="flex flex-col lg:flex-row lg:items-start justify-between gap-4">
        <div>
          <div className="flex items-center gap-3 flex-wrap">
            <h1 className="text-2xl font-bold text-white">{detail.order_number}</h1>
            <span className={`inline-flex text-xs font-semibold px-2.5 py-1 rounded-full border ${STATUS_CLASSES[detail.status] ?? STATUS_CLASSES.closed}`}>
              {orderStatusLabel(detail.status)}
            </span>
          </div>
          <p className="text-sm text-[#A0AEC0] mt-1">
            {detail.supplier_name} · commandée le {formatDateFr(detail.order_date)}
            {detail.expected_date ? ` · livraison prévue le ${formatDateFr(detail.expected_date)}` : ''}
          </p>
          {detail.notes && <p className="text-sm text-[#718096] mt-1 break-words">{detail.notes}</p>}
        </div>
        <div className="flex flex-wrap items-center gap-2">
          <button onClick={() => void load()} disabled={loading} aria-label="Actualiser" className="p-2.5 rounded-xl btn-outline-gold disabled:opacity-50">
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
          </button>
          {showReceive && (
            <button onClick={openReceive} className="flex items-center gap-2 btn-gold px-4 py-2.5 rounded-xl text-sm font-bold">
              <Package size={14} />
              Réceptionner
            </button>
          )}
          {showPay && (
            <button onClick={openPay} className="flex items-center gap-2 btn-outline-gold px-4 py-2.5 rounded-xl text-sm font-semibold">
              <Wallet size={14} />
              Enregistrer un paiement
            </button>
          )}
          {showCancel && (
            <button
              onClick={() => { setModalError(''); setCancelOpen(true); }}
              className="flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold bg-red-500/10 text-red-300 border border-red-500/30 hover:bg-red-500/20"
            >
              <XCircle size={14} />
              Annuler
            </button>
          )}
        </div>
      </div>

      {error && (
        <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300" role="alert">
          {error}
        </div>
      )}

      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-4">
        <MetricCard title="Montant de la commande" value={formatXof(detail.total_amount)} subtitle={`${detail.items.length} article(s)`} icon={<Wallet size={18} />} variant="gold" />
        <MetricCard title="Déjà payé" value={formatXof(computed.paid)} subtitle={PAYMENT_STATE_LABELS[computed.state]} icon={<CheckCircle size={18} />} variant="success" />
        <MetricCard title="Reste à payer" value={formatXof(computed.toPay)} subtitle={computed.toPay > 0 ? 'à régler au fournisseur' : 'rien à régler'} icon={<Wallet size={18} />} variant={computed.toPay > 0 ? 'warning' : 'success'} />
        <MetricCard title="Réception" value={`${computed.progress} %`} subtitle="des quantités commandées" icon={<Package size={18} />} variant={computed.progress >= 100 ? 'success' : 'default'} />
      </div>

      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
        <div className="px-5 py-4 border-b border-[#D4AF37]/10">
          <h2 className="text-sm font-semibold text-white">Articles</h2>
        </div>
        <div className="overflow-x-auto">
          <table className="w-full">
            <thead>
              <tr className="border-b border-[#D4AF37]/10">
                {['Article', 'Commandé', 'Reçu', 'Reste', 'Coût unit.', 'Total'].map((h) => (
                  <th key={h} className="text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider whitespace-nowrap">{h}</th>
                ))}
              </tr>
            </thead>
            <tbody>
              {detail.items.map((it) => (
                <tr key={it.id} className="border-b border-[#D4AF37]/5">
                  <td className="px-4 py-3">
                    <p className="text-sm font-medium text-white">{it.article_name}</p>
                    {it.article_code && <p className="text-xs text-[#718096]">{it.article_code}</p>}
                  </td>
                  <td className="px-4 py-3 text-sm text-white">{Number(it.quantity)}</td>
                  <td className="px-4 py-3 text-sm text-[#68D391]">{computed.received[it.article_id] ?? 0}</td>
                  <td className="px-4 py-3 text-sm text-[#F6AD55]">{computed.remaining[it.article_id] ?? 0}</td>
                  <td className="px-4 py-3 text-sm text-[#A0AEC0] whitespace-nowrap">{formatXof(it.unit_cost)}</td>
                  <td className="px-4 py-3 text-sm text-white whitespace-nowrap">{formatXof(it.total_amount)}</td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="grid grid-cols-1 xl:grid-cols-2 gap-6">
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
          <div className="px-5 py-4 border-b border-[#D4AF37]/10">
            <h2 className="text-sm font-semibold text-white">Réceptions</h2>
          </div>
          {detail.receipts.length === 0 ? (
            <p className="px-5 py-8 text-sm text-[#A0AEC0] text-center">Aucune réception pour l&apos;instant.</p>
          ) : (
            <ul className="divide-y divide-[#D4AF37]/5">
              {detail.receipts.map((r) => (
                <li key={r.id} className="px-5 py-3">
                  <div className="flex items-center justify-between gap-2">
                    <p className="text-sm font-medium text-white">{r.receipt_number}</p>
                    <p className="text-xs text-[#718096]">{formatDateFr(r.receipt_date)}{r.status !== 'received' ? ` · ${r.status === 'cancelled' ? 'annulée' : 'brouillon'}` : ''}</p>
                  </div>
                  <p className="text-xs text-[#A0AEC0] mt-0.5">
                    {(r.goods_receipt_items ?? [])
                      .map((i) => `${computed.names[i.article_id.toLowerCase()] ?? 'Article'} × ${Number(i.quantity_received)}`)
                      .join(' · ') || '—'}
                  </p>
                  {r.notes && <p className="text-xs text-[#718096] mt-0.5 break-words">{r.notes}</p>}
                </li>
              ))}
            </ul>
          )}
        </div>

        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
          <div className="px-5 py-4 border-b border-[#D4AF37]/10">
            <h2 className="text-sm font-semibold text-white">Paiements</h2>
          </div>
          {detail.payments.length === 0 ? (
            <p className="px-5 py-8 text-sm text-[#A0AEC0] text-center">Aucun paiement enregistré.</p>
          ) : (
            <ul className="divide-y divide-[#D4AF37]/5">
              {detail.payments.map((p) => (
                <li key={p.id} className="px-5 py-3 flex items-center justify-between gap-3">
                  <div className="min-w-0">
                    <p className="text-sm text-white">{paymentMethodLabel(p.payment_method)}{p.provider_reference ? ` · ${p.provider_reference}` : ''}</p>
                    <p className="text-xs text-[#718096]">{formatDateFr(p.payment_date)}{p.status !== 'paid' ? ` · ${p.status}` : ''}</p>
                    {p.notes && <p className="text-xs text-[#718096] break-words">{p.notes}</p>}
                  </div>
                  <p className="text-sm font-semibold text-white whitespace-nowrap">{formatXof(p.amount)}</p>
                </li>
              ))}
            </ul>
          )}
        </div>
      </div>

      {/* Réception */}
      <Modal open={receiveOpen} onClose={() => !busy && setReceiveOpen(false)} title="Réceptionner des marchandises" size="xl">
        <div className="space-y-4">
          {modalError && (
            <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300" role="alert">{modalError}</div>
          )}
          <p className="text-sm text-[#A0AEC0]">
            Saisissez les quantités effectivement reçues. Le stock sera mis à jour immédiatement.
          </p>
          <div className="space-y-2">
            {detail.items.map((it) => {
              const rest = computed.remaining[it.article_id] ?? 0;
              return (
                <div key={it.id} className="grid grid-cols-12 gap-2 items-center">
                  <div className="col-span-12 sm:col-span-7">
                    <p className="text-sm text-white">{it.article_name}</p>
                    <p className="text-xs text-[#718096]">Reste à recevoir : {rest}</p>
                  </div>
                  <input
                    type="number" min="0" max={rest} step="any" inputMode="decimal"
                    value={receiveInputs[it.article_id] ?? ''}
                    onChange={(e) => setReceiveInputs((prev) => ({ ...prev, [it.article_id]: e.target.value }))}
                    disabled={rest <= 0}
                    aria-label={`Quantité reçue pour ${it.article_name}`}
                    placeholder="0"
                    className={`${inputClass} col-span-12 sm:col-span-5 disabled:opacity-40`}
                  />
                </div>
              );
            })}
          </div>
          <button onClick={receiveAll} className="text-sm text-[#D4AF37] hover:underline">Tout recevoir</button>
          <div>
            <label className={labelClass} htmlFor="rcv-notes">Notes</label>
            <textarea id="rcv-notes" value={receiveNotes} onChange={(e) => setReceiveNotes(e.target.value)} maxLength={1000} rows={2} className={inputClass} />
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <button onClick={() => setReceiveOpen(false)} disabled={busy} className={btnGhost}>Annuler</button>
            <button onClick={() => void handleReceive()} disabled={busy} className="btn-gold px-5 py-2.5 rounded-xl text-sm font-bold disabled:opacity-50">
              {busy ? 'Enregistrement…' : 'Valider la réception'}
            </button>
          </div>
        </div>
      </Modal>

      {/* Paiement */}
      <Modal open={payOpen} onClose={() => !busy && setPayOpen(false)} title="Enregistrer un paiement" size="md">
        <div className="space-y-4">
          {modalError && (
            <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300" role="alert">{modalError}</div>
          )}
          <p className="text-sm text-[#A0AEC0]">Reste à payer : <span className="text-white font-semibold">{formatXof(computed.toPay)}</span></p>
          <div>
            <label className={labelClass} htmlFor="pay-amount">Montant (XOF) *</label>
            <input id="pay-amount" type="number" min="0" step="any" inputMode="decimal" value={payAmount} onChange={(e) => setPayAmount(e.target.value)} className={inputClass} />
          </div>
          <div>
            <label className={labelClass} htmlFor="pay-method">Mode de paiement</label>
            <select id="pay-method" value={payMethod} onChange={(e) => setPayMethod(e.target.value)} className={inputClass}>
              {PAYMENT_METHODS.map((m) => (
                <option key={m.value} value={m.value}>{m.label}</option>
              ))}
            </select>
          </div>
          <div>
            <label className={labelClass} htmlFor="pay-ref">Référence (facultatif)</label>
            <input id="pay-ref" value={payRef} onChange={(e) => setPayRef(e.target.value)} maxLength={120} className={inputClass} />
          </div>
          <div>
            <label className={labelClass} htmlFor="pay-notes">Notes</label>
            <textarea id="pay-notes" value={payNotes} onChange={(e) => setPayNotes(e.target.value)} maxLength={1000} rows={2} className={inputClass} />
          </div>
          <div className="flex justify-end gap-2 pt-2">
            <button onClick={() => setPayOpen(false)} disabled={busy} className={btnGhost}>Annuler</button>
            <button onClick={() => void handlePay()} disabled={busy} className="btn-gold px-5 py-2.5 rounded-xl text-sm font-bold disabled:opacity-50">
              {busy ? 'Enregistrement…' : 'Enregistrer'}
            </button>
          </div>
        </div>
      </Modal>

      {/* Annulation */}
      <Modal open={cancelOpen} onClose={() => !busy && setCancelOpen(false)} title="Annuler la commande" size="sm">
        <div className="space-y-4">
          {modalError && (
            <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300" role="alert">{modalError}</div>
          )}
          <p className="text-sm text-[#A0AEC0]">
            Annuler la commande <span className="text-white font-semibold">{detail.order_number}</span> ? Cette action est impossible
            si des marchandises ont déjà été reçues ou des paiements enregistrés.
          </p>
          <div className="flex justify-end gap-2 pt-2">
            <button onClick={() => setCancelOpen(false)} disabled={busy} className={btnGhost}>Conserver</button>
            <button
              onClick={() => void handleCancel()}
              disabled={busy}
              className="px-5 py-2.5 rounded-xl text-sm font-bold bg-red-500/80 text-white hover:bg-red-500 disabled:opacity-50"
            >
              {busy ? 'Annulation…' : 'Annuler la commande'}
            </button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
