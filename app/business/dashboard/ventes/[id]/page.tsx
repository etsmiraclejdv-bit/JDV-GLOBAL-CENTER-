'use client';
import React, { useCallback, useEffect, useState } from 'react';
import Link from 'next/link';
import { useParams } from 'next/navigation';
import { ArrowLeft, Plus, Wallet } from 'lucide-react';
import { toast } from 'sonner';
import { fetchSaleById, fetchPaymentsBySale, createPayment } from '@/lib/services/salesService';
import { saleTotal } from '@/lib/services/compat';
import Modal from '@/components/ui/Modal';

type Row = Record<string, unknown>;

const STATUS_LABELS: Record<string, string> = {
  pending: 'En attente',
  active: 'En cours',
  completed: 'Soldée',
  cancelled: 'Annulée',
  defaulted: 'Impayée',
};
const METHOD_LABELS: Record<string, string> = { cash: 'Espèces', mobile_money: 'Mobile money', bank_transfer: 'Virement', card: 'Carte' };

const fmt = (n: number) =>
  new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(n);

export default function SaleDetailPage() {
  const params = useParams();
  const saleId = params.id as string;
  const [sale, setSale] = useState<Row | null>(null);
  const [payments, setPayments] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [open, setOpen] = useState(false);
  const [amount, setAmount] = useState(0);
  const [method, setMethod] = useState('cash');
  const [saving, setSaving] = useState(false);

  const load = useCallback(async () => {
    const [s, p] = await Promise.all([fetchSaleById(saleId), fetchPaymentsBySale(saleId)]);
    if (s.error || !s.data) setError(s.error?.message ?? 'Vente introuvable');
    else setSale(s.data as Row);
    setPayments((p.data ?? []) as Row[]);
    setLoading(false);
  }, [saleId]);

  useEffect(() => {
    load();
  }, [load]);

  async function handlePayment(e: React.FormEvent) {
    e.preventDefault();
    if (!sale) return;
    if (amount <= 0) return toast.error('Le montant doit être supérieur à 0');
    setSaving(true);
    const { error: err } = await createPayment({
      organization_id: sale.organization_id as string,
      sale_id: saleId,
      client_id: (sale.client_id as string) ?? undefined,
      prospecteur_id: (sale.prospecteur_id as string) ?? undefined,
      amount,
      currency: 'XOF',
      payment_method: method,
      status: 'successful',
    } as never);
    setSaving(false);
    if (err) return toast.error(err.message);
    toast.success('Paiement enregistré');
    setOpen(false);
    setAmount(0);
    load();
  }

  if (loading) return <div className="p-8 text-center text-[#A0AEC0]">Chargement...</div>;
  if (error || !sale) {
    return (
      <div className="p-8 text-center space-y-3">
        <p className="text-red-400 text-sm">{error || 'Vente introuvable'}</p>
        <Link href="/business/dashboard/ventes" className="text-[#D4AF37] text-sm hover:underline">Retour aux ventes</Link>
      </div>
    );
  }

  const total = saleTotal(sale as never);
  const paid = Number(sale.amount_paid) || 0;
  const remaining = Number(sale.amount_remaining) || 0;
  const client = sale.clients as Row | null;
  const product = sale.products as Row | null;
  const seller = sale.profiles as Row | null;
  const canPay = remaining > 0 && sale.status !== 'cancelled';

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div className="flex items-center gap-4">
        <Link href="/business/dashboard/ventes" className="p-2 rounded-xl text-[#718096] hover:text-white hover:bg-[#0F2347] transition-all">
          <ArrowLeft size={18} />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-white">Vente {sale.sale_number as string}</h1>
          <p className="text-sm text-[#A0AEC0]">
            {new Date(sale.sale_date as string).toLocaleDateString('fr-FR')} — {STATUS_LABELS[sale.status as string] ?? (sale.status as string)}
          </p>
        </div>
        {canPay && (
          <button
            onClick={() => { setAmount(remaining); setOpen(true); }}
            className="ml-auto flex items-center gap-2 btn-gold px-4 py-2.5 rounded-xl text-sm font-bold"
          >
            <Plus size={14} />
            Encaisser un paiement
          </button>
        )}
      </div>

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-4">
        {[
          { label: 'Total', value: fmt(total), cls: 'text-white' },
          { label: 'Déjà payé', value: fmt(paid), cls: 'text-green-400' },
          { label: 'Reste à payer', value: fmt(remaining), cls: 'text-[#D4AF37]' },
        ].map((k) => (
          <div key={k.label} className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-4">
            <p className="text-xs text-[#A0AEC0] mb-1">{k.label}</p>
            <p className={`text-2xl font-bold ${k.cls}`}>{k.value}</p>
          </div>
        ))}
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-6">
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5 space-y-3 text-sm">
          <h2 className="font-semibold text-white">Détails</h2>
          <div className="flex justify-between"><span className="text-[#718096]">Client</span>
            {client ? <Link href={`/business/dashboard/clients/${client.id as string}`} className="text-[#D4AF37] hover:underline">{client.full_name as string}</Link> : <span className="text-white">—</span>}
          </div>
          <div className="flex justify-between"><span className="text-[#718096]">Article</span><span className="text-white">{(product?.name as string) ?? '—'}</span></div>
          <div className="flex justify-between"><span className="text-[#718096]">Quantité</span><span className="text-white">{sale.quantity as number}</span></div>
          <div className="flex justify-between"><span className="text-[#718096]">Type</span><span className="text-white">{sale.sale_type === 'credit' ? 'À crédit' : 'Comptant'}</span></div>
          <div className="flex justify-between"><span className="text-[#718096]">Prospecteur</span><span className="text-white">{(seller?.full_name as string) ?? '—'}</span></div>
          {sale.sale_type === 'credit' && (
            <div className="flex justify-between"><span className="text-[#718096]">Versement</span><span className="text-white">{fmt(Number(sale.payment_amount) || 0)} / {String(sale.payment_frequency ?? '—')}</span></div>
          )}
          {sale.deadline_date ? (
            <div className="flex justify-between"><span className="text-[#718096]">Date limite</span><span className="text-white">{new Date(sale.deadline_date as string).toLocaleDateString('fr-FR')}</span></div>
          ) : null}
        </div>

        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5">
          <h2 className="font-semibold text-white mb-3 flex items-center gap-2"><Wallet size={16} className="text-[#D4AF37]" /> Paiements</h2>
          {payments.length === 0 ? (
            <p className="text-sm text-[#A0AEC0]">Aucun paiement enregistré.</p>
          ) : (
            <table className="w-full text-sm">
              <tbody>
                {payments.map((p) => (
                  <tr key={p.id as string} className="border-b border-[#D4AF37]/5">
                    <td className="py-2 text-[#A0AEC0]">{new Date(p.payment_date as string).toLocaleDateString('fr-FR')}</td>
                    <td className="py-2 text-[#A0AEC0]">{METHOD_LABELS[p.payment_method as string] ?? (p.payment_method as string) ?? '—'}</td>
                    <td className="py-2 text-right font-semibold text-white">{fmt(Number(p.amount) || 0)}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>

      <Modal open={open} onClose={() => setOpen(false)} title="Encaisser un paiement" size="sm">
        <form onSubmit={handlePayment} className="space-y-4 p-1">
          <div>
            <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Montant (XOF)</label>
            <input type="number" min={1} max={remaining} value={amount} onChange={(e) => setAmount(Math.min(remaining, Math.max(0, parseInt(e.target.value) || 0)))}
              className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60" />
          </div>
          <div>
            <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Moyen de paiement</label>
            <select value={method} onChange={(e) => setMethod(e.target.value)}
              className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none">
              {Object.entries(METHOD_LABELS).map(([k, v]) => <option key={k} value={k}>{v}</option>)}
            </select>
          </div>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={() => setOpen(false)} className="flex-1 py-2.5 rounded-xl border border-[#D4AF37]/20 text-[#A0AEC0] text-sm hover:text-white transition-colors">Annuler</button>
            <button type="submit" disabled={saving} className="flex-1 btn-gold py-2.5 rounded-xl font-semibold text-sm disabled:opacity-60">{saving ? 'Enregistrement...' : 'Enregistrer'}</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
