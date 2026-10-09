'use client';
import React, { useState, useEffect } from 'react';
import { ArrowLeft, User, ShoppingCart, CreditCard, Plus } from 'lucide-react';

import { fetchClientById, fetchClientSales, fetchClientPayments } from '@/lib/services/clientsService';
import Link from 'next/link';
import { useParams } from 'next/navigation';

export default function ClientDetailPage() {
  const params = useParams();
  const clientId = params.id as string;
  const [client, setClient] = useState<Record<string, unknown> | null>(null);
  const [sales, setSales] = useState<Record<string, unknown>[]>([]);
  const [payments, setPayments] = useState<Record<string, unknown>[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  useEffect(() => {
    async function load() {
      const [clientRes, salesRes, paymentsRes] = await Promise.all([
        fetchClientById(clientId),
        fetchClientSales(clientId),
        fetchClientPayments(clientId),
      ]);
      if (clientRes.error) { setError(clientRes.error.message); setLoading(false); return; }
      setClient(clientRes.data as Record<string, unknown>);
      setSales((salesRes.data as Record<string, unknown>[]) ?? []);
      setPayments((paymentsRes.data as Record<string, unknown>[]) ?? []);
      setLoading(false);
    }
    load();
  }, [clientId]);

  if (loading) return <div className="p-8 text-center text-[#A0AEC0]">Chargement...</div>;
  if (error) return <div className="p-8 text-center text-red-400">{error}</div>;
  if (!client) return <div className="p-8 text-center text-[#A0AEC0]">Client introuvable</div>;

  const paymentStatusColors: Record<string, string> = {
    a_jour: 'text-green-400',
    a_surveiller: 'text-yellow-400',
    en_retard: 'text-red-400',
  };

  return (
    <div className="p-6 lg:p-8 space-y-6">
      {/* Header */}
      <div className="flex items-center gap-4">
        <Link href="/business/dashboard/clients" className="p-2 rounded-xl text-[#718096] hover:text-white hover:bg-[#0F2347] transition-all">
          <ArrowLeft size={18} />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-white">{client.full_name as string}</h1>
          <p className="text-sm text-[#A0AEC0]">Fiche client</p>
        </div>
        <div className="ml-auto">
          <Link
            href={`/business/dashboard/ventes/new?client_id=${clientId}`}
            className="flex items-center gap-2 btn-gold px-4 py-2.5 rounded-xl text-sm font-bold"
          >
            <Plus size={14} />
            Nouvelle vente
          </Link>
        </div>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
        {/* Identity */}
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5">
          <div className="flex items-center gap-3 mb-4">
            <div className="w-12 h-12 rounded-full bg-[#0A1628] border border-[#D4AF37]/20 flex items-center justify-center">
              <User size={20} className="text-[#D4AF37]" />
            </div>
            <div>
              <p className="font-semibold text-white">{client.full_name as string}</p>
              <p className={`text-xs font-medium ${paymentStatusColors[client.payment_status as string] ?? 'text-[#A0AEC0]'}`}>
                {client.payment_status === 'a_jour' ? 'À jour' : client.payment_status === 'a_surveiller' ? 'À surveiller' : 'En retard'}
              </p>
            </div>
          </div>
          <div className="space-y-2 text-sm">
            {client.phone && (
              <div className="flex justify-between">
                <span className="text-[#718096]">Téléphone</span>
                <span className="text-white">{client.phone as string}</span>
              </div>
            )}
            <div className="flex justify-between">
              <span className="text-[#718096]">Solde dû</span>
              <span className="text-[#D4AF37] font-semibold">
                {new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(((client.balance_cents as number) ?? 0) / 100)}
              </span>
            </div>
            <div className="flex justify-between">
              <span className="text-[#718096]">Membre depuis</span>
              <span className="text-white">{new Date(client.created_at as string).toLocaleDateString('fr-FR')}</span>
            </div>
          </div>
        </div>

        {/* Sales history */}
        <div className="lg:col-span-2 bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5">
          <div className="flex items-center gap-2 mb-4">
            <ShoppingCart size={16} className="text-[#D4AF37]" />
            <h3 className="font-semibold text-white">Historique des ventes ({sales.length})</h3>
          </div>
          {sales.length === 0 ? (
            <p className="text-[#718096] text-sm text-center py-6">Aucune vente enregistrée</p>
          ) : (
            <div className="space-y-2 max-h-48 overflow-y-auto">
              {sales.map(sale => (
                <div key={sale.id as string} className="flex items-center justify-between py-2 border-b border-[#D4AF37]/5">
                  <div>
                    <p className="text-sm text-white">{new Date(sale.sold_at as string).toLocaleDateString('fr-FR')}</p>
                    <p className="text-xs text-[#718096]">{sale.status as string}</p>
                  </div>
                  <p className="text-sm font-semibold text-[#D4AF37]">
                    {new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(((sale.amount_cents as number) ?? 0) / 100)}
                  </p>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>

      {/* Payments history */}
      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5">
        <div className="flex items-center gap-2 mb-4">
          <CreditCard size={16} className="text-[#D4AF37]" />
          <h3 className="font-semibold text-white">Historique des paiements ({payments.length})</h3>
        </div>
        {payments.length === 0 ? (
          <p className="text-[#718096] text-sm text-center py-6">Aucun paiement enregistré</p>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[#D4AF37]/10">
                  <th className="text-left px-3 py-2 text-xs text-[#718096]">Date</th>
                  <th className="text-left px-3 py-2 text-xs text-[#718096]">Montant</th>
                  <th className="text-left px-3 py-2 text-xs text-[#718096]">Statut</th>
                </tr>
              </thead>
              <tbody>
                {payments.map(p => (
                  <tr key={p.id as string} className="border-b border-[#D4AF37]/5">
                    <td className="px-3 py-2 text-sm text-[#A0AEC0]">{new Date(p.paid_at as string).toLocaleDateString('fr-FR')}</td>
                    <td className="px-3 py-2 text-sm font-semibold text-green-400">
                      {new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(((p.amount_cents as number) ?? 0) / 100)}
                    </td>
                    <td className="px-3 py-2 text-xs text-[#A0AEC0]">{p.status as string}</td>
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
