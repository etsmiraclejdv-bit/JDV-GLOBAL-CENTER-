'use client';
import React, { useCallback, useEffect, useState } from 'react';
import { Users, CreditCard, Package } from 'lucide-react';
import { toast } from 'sonner';
import { supabase } from '@/lib/supabase/client';
import Modal from '@/components/ui/Modal';

type Tab = 'plans' | 'admins' | 'fedapay';

interface Plan {
  id: string;
  code: string;
  name: string;
  price: number;
  billing_amount_xof: number;
  currency: string;
  duration_days: number;
  active: boolean;
}

export default function SuperAdminSettingsPage() {
  const [activeTab, setActiveTab] = useState<Tab>('plans');
  const [plans, setPlans] = useState<Plan[]>([]);
  const [loadingPlans, setLoadingPlans] = useState(true);
  const [editPlan, setEditPlan] = useState<Plan | null>(null);
  const [price, setPrice] = useState(0);
  const [xof, setXof] = useState(0);
  const [active, setActive] = useState(true);
  const [saving, setSaving] = useState(false);
  const [me, setMe] = useState<{ email: string; status: string } | null>(null);

  const loadPlans = useCallback(async () => {
    const { data, error } = await supabase
      .from('subscription_plans')
      .select('id, code, name, price, billing_amount_xof, currency, duration_days, active')
      .order('duration_days', { ascending: true });
    if (error) toast.error(error.message);
    setPlans(((data ?? []) as Record<string, unknown>[]).map(p => ({ ...(p as unknown as Plan), price: Number(p.price) || 0, billing_amount_xof: Number(p.billing_amount_xof) || 0 })));
    setLoadingPlans(false);
  }, []);

  useEffect(() => {
    loadPlans();
    (async () => {
      const { data: u } = await supabase.auth.getUser();
      if (!u.user) return;
      const { data } = await supabase.from('super_admins').select('status').eq('user_id', u.user.id).maybeSingle();
      setMe({ email: u.user.email ?? '', status: ((data as { status?: string } | null)?.status) ?? 'active' });
    })();
  }, [loadPlans]);

  function openEdit(p: Plan) {
    setEditPlan(p);
    setPrice(p.price);
    setXof(p.billing_amount_xof);
    setActive(p.active);
  }

  async function handleSavePlan(e: React.FormEvent) {
    e.preventDefault();
    if (!editPlan) return;
    if (price < 0 || xof < 0) return toast.error('Les prix ne peuvent pas être négatifs');
    setSaving(true);
    const { error } = await supabase
      .from('subscription_plans')
      .update({ price, billing_amount_xof: xof, active, updated_at: new Date().toISOString() })
      .eq('id', editPlan.id);
    setSaving(false);
    if (error) return toast.error(error.message);
    toast.success('Plan mis à jour');
    setEditPlan(null);
    loadPlans();
  }

  const tabs: { id: Tab; label: string; icon: React.ReactNode }[] = [
    { id: 'plans', label: 'Plans d\'abonnement', icon: <Package size={14} /> },
    { id: 'admins', label: 'Compte concepteur', icon: <Users size={14} /> },
    { id: 'fedapay', label: 'FedaPay Plateforme', icon: <CreditCard size={14} /> },
  ];

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Paramètres Plateforme</h1>
        <p className="text-sm text-[#A0AEC0] mt-1">Configuration globale de JDV CRM</p>
      </div>

      <div className="flex gap-1 bg-[#0A1628] rounded-xl p-1 w-fit">
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              activeTab === tab.id ? 'bg-[#D4AF37] text-[#0B1B3D]' : 'text-[#A0AEC0] hover:text-white'
            }`}
          >
            {tab.icon}
            <span className="hidden sm:inline">{tab.label}</span>
          </button>
        ))}
      </div>

      {activeTab === 'plans' && (
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-6">
          <h2 className="text-lg font-semibold text-white mb-5">Plans d&apos;abonnement</h2>
          {loadingPlans ? (
            <p className="text-sm text-[#A0AEC0]">Chargement...</p>
          ) : plans.length === 0 ? (
            <p className="text-sm text-[#A0AEC0]">Aucun plan défini.</p>
          ) : (
            <div className="space-y-3">
              {plans.map(plan => (
                <div key={plan.id} className="flex items-center justify-between p-4 bg-[#0A1628] rounded-xl border border-[#D4AF37]/10">
                  <div>
                    <p className="text-sm font-semibold text-white">
                      {plan.name}
                      {!plan.active && <span className="ml-2 text-xs text-red-400">désactivé</span>}
                    </p>
                    <p className="text-xs text-[#718096]">{plan.duration_days} jours — {plan.code}</p>
                  </div>
                  <div className="flex items-center gap-3">
                    <span className="text-[#D4AF37] font-bold text-right">
                      {plan.price} {plan.currency}
                      {plan.billing_amount_xof > 0 && (
                        <span className="block text-xs font-normal text-[#A0AEC0]">{new Intl.NumberFormat('fr-FR').format(plan.billing_amount_xof)} XOF facturés</span>
                      )}
                    </span>
                    <button
                      type="button"
                      onClick={() => openEdit(plan)}
                      className="text-xs px-3 py-1.5 rounded-lg border border-[#D4AF37]/20 text-[#A0AEC0] hover:text-white transition-colors"
                    >
                      Modifier
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      )}

      {activeTab === 'admins' && (
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-6">
          <h2 className="text-lg font-semibold text-white mb-5">Compte concepteur connecté</h2>
          {me ? (
            <div className="flex items-center justify-between p-4 bg-[#0A1628] rounded-xl border border-[#D4AF37]/10">
              <div>
                <p className="text-sm font-medium text-white">{me.email}</p>
                <p className="text-xs text-[#718096]">Concepteur — droits sur toute la plateforme</p>
              </div>
              <span className="text-xs px-2.5 py-1 rounded-lg bg-green-500/20 text-green-400 border border-green-500/30">{me.status}</span>
            </div>
          ) : (
            <p className="text-sm text-[#A0AEC0]">Chargement...</p>
          )}
          <p className="text-xs text-[#718096] mt-4">
            Les comptes concepteur sont définis uniquement en base, dans la table <code className="text-[#D4AF37]">super_admins</code>. Aucune inscription libre n&apos;est possible.
          </p>
        </div>
      )}

      {activeTab === 'fedapay' && (
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-6">
          <h2 className="text-lg font-semibold text-white mb-2">FedaPay — Abonnements Plateforme</h2>
          <p className="text-sm text-[#A0AEC0] mb-5">Collecte des abonnements JDV CRM.</p>
          <div className="space-y-4 max-w-lg">
            <div className="p-4 bg-yellow-500/10 border border-yellow-500/30 rounded-xl">
              <p className="text-xs text-yellow-400">Les clés (<code>FEDAPAY_SECRET_KEY</code>, <code>FEDAPAY_WEBHOOK_SECRET</code>) sont des variables d&apos;environnement serveur : elles se changent dans l&apos;hébergement, jamais depuis le navigateur.</p>
            </div>
            <div className="flex items-center gap-2 p-3 bg-[#0A1628] rounded-xl border border-[#D4AF37]/10">
              <div className="w-2 h-2 rounded-full bg-green-400" />
              <span className="text-sm text-[#A0AEC0]">Route webhook : <code className="text-[#D4AF37]">/api/fedapay-webhook</code></span>
            </div>
          </div>
        </div>
      )}

      <Modal open={!!editPlan} onClose={() => setEditPlan(null)} title={editPlan ? `Modifier ${editPlan.name}` : ''} size="sm">
        <form onSubmit={handleSavePlan} className="space-y-4 p-1">
          <div>
            <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Prix affiché ({editPlan?.currency})</label>
            <input
              type="number"
              min={0}
              value={price}
              onChange={e => setPrice(Math.max(0, Number(e.target.value) || 0))}
              className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
            />
          </div>
          <div>
            <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Montant facturé via FedaPay (XOF)</label>
            <input
              type="number"
              min={0}
              value={xof}
              onChange={e => setXof(Math.max(0, Number(e.target.value) || 0))}
              className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
            />
          </div>
          <label className="flex items-center justify-between text-sm text-[#A0AEC0]">
            Plan proposé aux entreprises
            <input type="checkbox" checked={active} onChange={e => setActive(e.target.checked)} className="w-4 h-4 accent-[#D4AF37]" />
          </label>
          <div className="flex gap-3 pt-2">
            <button type="button" onClick={() => setEditPlan(null)} className="flex-1 py-2.5 rounded-xl border border-[#D4AF37]/20 text-[#A0AEC0] text-sm hover:text-white transition-colors">Annuler</button>
            <button type="submit" disabled={saving} className="flex-1 btn-gold py-2.5 rounded-xl font-semibold text-sm disabled:opacity-60">{saving ? 'Enregistrement...' : 'Enregistrer'}</button>
          </div>
        </form>
      </Modal>
    </div>
  );
}
