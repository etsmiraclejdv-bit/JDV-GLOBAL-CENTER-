'use client';
import React, { Suspense, useEffect, useMemo, useState } from 'react';
import Link from 'next/link';
import { useRouter, useSearchParams } from 'next/navigation';
import { ArrowLeft, Save } from 'lucide-react';
import { toast } from 'sonner';
import { getCurrentOrgId } from '@/lib/auth/context';
import { fetchClients } from '@/lib/services/clientsService';
import { fetchProducts } from '@/lib/services/catalogueService';
import { createSale } from '@/lib/services/salesService';
import { supabase } from '@/lib/supabase/client';
import { personName } from '@/lib/services/compat';

type Row = Record<string, unknown>;

const inputCls =
  'w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60';
const labelCls = 'block text-xs font-medium text-[#A0AEC0] mb-1.5';

function NewSaleForm() {
  const router = useRouter();
  const params = useSearchParams();
  const [orgId, setOrgId] = useState<string | null>(null);
  const [clients, setClients] = useState<Row[]>([]);
  const [articles, setArticles] = useState<Row[]>([]);
  const [prospecteurs, setProspecteurs] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);

  const [clientId, setClientId] = useState(params.get('client_id') ?? '');
  const [articleId, setArticleId] = useState('');
  const [prospecteurId, setProspecteurId] = useState('');
  const [saleType, setSaleType] = useState<'cash' | 'credit'>('cash');
  const [quantity, setQuantity] = useState(1);
  const [unitPrice, setUnitPrice] = useState(0);
  const [amountPaid, setAmountPaid] = useState(0);
  const [frequency, setFrequency] = useState('weekly');
  const [installment, setInstallment] = useState(0);
  const [deadline, setDeadline] = useState('');

  useEffect(() => {
    let cancelled = false;
    (async () => {
      const oid = await getCurrentOrgId();
      if (cancelled) return;
      if (!oid) {
        setLoading(false);
        return;
      }
      setOrgId(oid);
      const [c, a, p] = await Promise.all([
        fetchClients(oid),
        fetchProducts(oid),
        supabase.from('prospecteurs').select('id, first_name, last_name').eq('organization_id', oid).eq('status', 'active'),
      ]);
      if (cancelled) return;
      setClients((c.data ?? []) as Row[]);
      setArticles(((a.data ?? []) as Row[]).filter((x) => x.active !== false));
      setProspecteurs((p.data ?? []) as Row[]);
      setLoading(false);
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  const article = useMemo(() => articles.find((a) => a.id === articleId), [articles, articleId]);

  // Prix proposé selon l'article et le type de vente ; modifiable ensuite.
  useEffect(() => {
    if (!article) return;
    const price = saleType === 'credit' ? Number(article.credit_price) || Number(article.fixed_price) : Number(article.cash_price) || Number(article.fixed_price);
    setUnitPrice(price || 0);
  }, [article, saleType]);

  const total = unitPrice * quantity;
  const remaining = saleType === 'cash' ? 0 : Math.max(total - amountPaid, 0);
  useEffect(() => { if (frequency === 'four_installments' && remaining > 0) setInstallment(Math.ceil(remaining / 4)); }, [frequency, remaining]);
  const fmt = (n: number) =>
    new Intl.NumberFormat('fr-FR', { style: 'currency', currency: 'XOF', maximumFractionDigits: 0 }).format(n);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (!orgId) return;
    if (!clientId) return toast.error('Choisissez un client');
    if (!article) return toast.error('Choisissez un article');
    if (quantity < 1) return toast.error('La quantité doit être au moins 1');
    if (unitPrice <= 0) return toast.error('Le prix unitaire doit être supérieur à 0');
    if (saleType === 'credit' && installment <= 0) return toast.error('Indiquez le montant de chaque versement');

    setSaving(true);
    const { data, error } = await createSale({
      organization_id: orgId,
      client_id: clientId,
      article_id: article.id as string,
      prospecteur_id: prospecteurId || undefined,
      quantity,
      sale_type: saleType,
      fixed_price: Number(article.fixed_price) || unitPrice,
      cash_price: saleType === 'cash' ? unitPrice : Number(article.cash_price) || unitPrice,
      credit_price: saleType === 'credit' ? unitPrice : Number(article.credit_price) || unitPrice,
      amount_paid: saleType === 'cash' ? total : Math.min(amountPaid, total),
      payment_frequency: saleType === 'credit' ? frequency : undefined,
      payment_amount: saleType === 'credit' ? installment : 0,
      deadline_date: saleType === 'credit' && deadline ? deadline : undefined,
      client_phone: (clients.find((c) => c.id === clientId)?.phone as string) || undefined,
      status: 'active',
    });
    setSaving(false);
    if (error || !data) {
      toast.error(error?.message ?? 'La vente n’a pas pu être enregistrée');
      return;
    }
    toast.success('Vente enregistrée');
    router.push(`/business/dashboard/ventes/${(data as Row).id as string}`);
  }

  if (loading) return <div className="p-8 text-center text-[#A0AEC0]">Chargement...</div>;
  if (!orgId) return <div className="p-8 text-center text-red-400 text-sm">Aucune organisation associée à ce compte.</div>;

  return (
    <div className="p-6 lg:p-8 space-y-6 max-w-2xl">
      <div className="flex items-center gap-4">
        <Link href="/business/dashboard/ventes" className="p-2 rounded-xl text-[#718096] hover:text-white hover:bg-[#0F2347] transition-all">
          <ArrowLeft size={18} />
        </Link>
        <div>
          <h1 className="text-2xl font-bold text-white">Nouvelle vente</h1>
          <p className="text-sm text-[#A0AEC0]">Enregistrer une vente au comptant ou à crédit</p>
        </div>
      </div>

      <form onSubmit={handleSubmit} className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-6 space-y-4">
        <div>
          <label className={labelCls}>Client</label>
          <select value={clientId} onChange={(e) => setClientId(e.target.value)} required className={inputCls}>
            <option value="">Choisir un client…</option>
            {clients.map((c) => (
              <option key={c.id as string} value={c.id as string}>
                {(c.full_name as string) || personName(c as never)} {c.phone ? `— ${c.phone as string}` : ''}
              </option>
            ))}
          </select>
          {clients.length === 0 && <p className="text-xs text-[#718096] mt-1">Vous ne voyez pas les clients des prospecteurs (portefeuilles privés). Les ventes s’enregistrent depuis l’espace terrain du prospecteur ; ici, seul un compte concepteur voit son propre portefeuille.</p>}
        </div>

        <div>
          <label className={labelCls}>Article</label>
          <select value={articleId} onChange={(e) => setArticleId(e.target.value)} required className={inputCls}>
            <option value="">Choisir un article…</option>
            {articles.map((a) => (
              <option key={a.id as string} value={a.id as string}>
                {a.name as string} ({a.sku as string}) — stock {a.stock_quantity as number}
              </option>
            ))}
          </select>
          {articles.length === 0 && (
            <p className="text-xs text-[#718096] mt-1">
              Aucun article. <Link href="/business/dashboard/catalogue" className="text-[#D4AF37] hover:underline">Créer un article</Link>
            </p>
          )}
        </div>

        <div>
          <label className={labelCls}>Prospecteur (facultatif)</label>
          <select value={prospecteurId} onChange={(e) => setProspecteurId(e.target.value)} className={inputCls}>
            <option value="">Aucun</option>
            {prospecteurs.map((p) => (
              <option key={p.id as string} value={p.id as string}>
                {personName(p as never)}
              </option>
            ))}
          </select>
        </div>

        <div className="grid grid-cols-2 gap-3">
          <div>
            <label className={labelCls}>Type de vente</label>
            <select value={saleType} onChange={(e) => setSaleType(e.target.value as 'cash' | 'credit')} className={inputCls}>
              <option value="cash">Comptant</option>
              <option value="credit">À crédit</option>
            </select>
          </div>
          <div>
            <label className={labelCls}>Quantité</label>
            <input type="number" min={1} value={quantity} onChange={(e) => setQuantity(Math.max(1, parseInt(e.target.value) || 1))} className={inputCls} />
          </div>
        </div>

        <div>
          <label className={labelCls}>Prix unitaire (XOF)</label>
          <input type="number" min={0} value={unitPrice} onChange={(e) => setUnitPrice(Math.max(0, parseInt(e.target.value) || 0))} className={inputCls} />
        </div>

        {saleType === 'credit' && (
          <div className="space-y-4 rounded-xl border border-[#D4AF37]/10 p-4">
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className={labelCls}>Acompte versé (XOF)</label>
                <input type="number" min={0} value={amountPaid} onChange={(e) => setAmountPaid(Math.max(0, parseInt(e.target.value) || 0))} className={inputCls} />
              </div>
              <div>
                <label className={labelCls}>Montant de chaque versement (XOF)</label>
                <input type="number" min={0} value={installment} disabled={frequency === 'four_installments'} onChange={(e) => setInstallment(Math.max(0, parseInt(e.target.value) || 0))} className={inputCls} />
              </div>
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className={labelCls}>Fréquence</label>
                <select value={frequency} onChange={(e) => setFrequency(e.target.value)} className={inputCls}>
                  <option value="daily">Journalière</option>
                  <option value="weekly">Hebdomadaire</option>
                  <option value="biweekly">Toutes les 2 semaines</option>
                  <option value="monthly">Mensuelle</option>
                  <option value="four_installments">Crédit en 4 échéances (hebdomadaires)</option>
                </select>
              </div>
              <div>
                <label className={labelCls}>Date limite</label>
                <input type="date" value={deadline} onChange={(e) => setDeadline(e.target.value)} className={inputCls} />
              </div>
            </div>
          </div>
        )}

        <div className="flex items-center justify-between rounded-xl bg-[#0A1628] px-4 py-3 text-sm">
          <span className="text-[#A0AEC0]">Total : <span className="font-bold text-white">{fmt(total)}</span></span>
          <span className="text-[#A0AEC0]">Reste à payer : <span className="font-bold text-[#D4AF37]">{fmt(remaining)}</span></span>
        </div>

        <div className="flex gap-3 pt-1">
          <Link href="/business/dashboard/ventes" className="flex-1 text-center py-2.5 rounded-xl border border-[#D4AF37]/20 text-[#A0AEC0] text-sm hover:text-white transition-colors">
            Annuler
          </Link>
          <button type="submit" disabled={saving} className="flex-1 flex items-center justify-center gap-2 btn-gold py-2.5 rounded-xl font-semibold text-sm disabled:opacity-60">
            <Save size={14} />
            {saving ? 'Enregistrement...' : 'Enregistrer la vente'}
          </button>
        </div>
      </form>
    </div>
  );
}

export default function NewSalePage() {
  return (
    <Suspense fallback={<div className="p-8 text-center text-[#A0AEC0]">Chargement...</div>}>
      <NewSaleForm />
    </Suspense>
  );
}
