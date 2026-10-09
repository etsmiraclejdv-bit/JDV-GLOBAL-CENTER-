'use client';
import React, { useState, useEffect } from 'react';
import { CheckCircle, Star, Zap, Shield, Users, BarChart2, Package, Bell, ArrowRight, Loader2, AlertCircle } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { trackPlanSelection, trackPaymentConfirmed } from '@/lib/analytics';

interface Plan {
  id: string;
  billing_amount_xof?: number;
  code: string;
  name: string;
  price: number;
  currency: string;
  duration_days: number;
  recommended?: boolean;
  features: string[];
  prospecteur_limit: string;
}

const PLANS: Plan[] = [
  {
    id: 'monthly',
    code: 'MONTHLY',
    name: 'Mensuel',
    price: 50,
    currency: 'USD',
    duration_days: 30,
    recommended: false,
    prospecteur_limit: '5',
    features: [
      'Jusqu\'à 5 prospecteurs',
      'Gestion des ventes & paiements',
      'Suivi des prospects',
      'Rapports de base',
      'Support par email',
    ],
  },
  {
    id: 'quarterly',
    code: 'QUARTERLY',
    name: 'Trimestriel',
    price: 150,
    currency: 'USD',
    duration_days: 90,
    recommended: false,
    prospecteur_limit: '10',
    features: [
      'Jusqu\'à 10 prospecteurs',
      'Gestion des ventes & paiements',
      'Suivi des prospects',
      'Rapports avancés',
      'Gestion du stock',
      'Support prioritaire',
    ],
  },
  {
    id: 'semester',
    code: 'SEMESTER',
    name: 'Semestriel',
    price: 300,
    currency: 'USD',
    duration_days: 180,
    recommended: false,
    prospecteur_limit: '25',
    features: [
      'Jusqu\'à 25 prospecteurs',
      'Toutes les fonctionnalités',
      'Transferts de stock',
      'Journal d\'audit complet',
      'Notifications avancées',
      'Support dédié',
    ],
  },
  {
    id: 'annual',
    code: 'ANNUAL',
    name: 'Annuel',
    price: 600,
    currency: 'USD',
    duration_days: 365,
    recommended: true,
    prospecteur_limit: 'Illimité',
    features: [
      'Prospecteurs illimités',
      'Toutes les fonctionnalités',
      'Accès API',
      'Personnalisation avancée',
      'Intégration FedaPay entreprise',
      'Support 24/7 prioritaire',
      '2 mois offerts vs mensuel',
    ],
  },
];

interface TrialStatus {
  status: 'trial' | 'active' | 'expired' | 'suspended';
  daysRemaining: number;
  organizationId: string;
  organizationName: string;
  subscriptionId?: string;
  planName?: string;
  expiresAt?: string;
}

export default function PaymentWallContent() {
  const [trialStatus, setTrialStatus] = useState<TrialStatus | null>(null);
  const [loading, setLoading] = useState(true);
  const [selectedPlan, setSelectedPlan] = useState<Plan | null>(null);
  const [initiating, setInitiating] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [plans, setPlans] = useState<Plan[]>(PLANS);

  useEffect(() => {
    loadTrialStatus();
    (async () => {
      const { data } = await supabase
        .from('subscription_plans')
        .select('code, price, billing_amount_xof, active')
        .neq('code', 'TRIAL');
      if (!data) return;
      const byCode = new Map((data as { code: string; price: number | string; billing_amount_xof: number | string | null; active: boolean }[]).map(r => [r.code, r]));
      setPlans(PLANS.filter(p => byCode.get(p.code)?.active !== false).map(p => {
        const r = byCode.get(p.code);
        return r
          ? { ...p, price: Number(r.price) || p.price, billing_amount_xof: Number(r.billing_amount_xof) || undefined }
          : p;
      }));
    })();
  }, []);

  async function loadTrialStatus() {
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) return;

      const { data: member } = await supabase
        .from('organization_members')
        .select('organization_id, organizations(name, status, subscription_status)')
        .eq('user_id', user.id)
        .eq('role', 'business_admin')
        .eq('status', 'active')
        .single();

      if (!member) return;

      const org = member.organizations as { name: string; status: string; subscription_status: string } | null;

      const { data: sub } = await supabase
        .from('organization_subscriptions')
        .select('id, status, expires_at, subscription_plans(name)')
        .eq('organization_id', member.organization_id)
        .order('created_at', { ascending: false })
        .limit(1)
        .single();

      let daysRemaining = 0;
      if (sub?.expires_at) {
        const diff = new Date(sub.expires_at).getTime() - Date.now();
        daysRemaining = Math.max(0, Math.ceil(diff / (1000 * 60 * 60 * 24)));
      }

      setTrialStatus({
        status: (sub?.status ?? org?.subscription_status ?? 'trial') as TrialStatus['status'],
        daysRemaining,
        organizationId: member.organization_id,
        organizationName: org?.name ?? '',
        subscriptionId: sub?.id,
        planName: (sub?.subscription_plans as { name: string } | null)?.name,
        expiresAt: sub?.expires_at,
      });
    } catch {
      // silently fail — show plans anyway
    } finally {
      setLoading(false);
    }
  }

  async function handleSelectPlan(plan: Plan) {
    if (initiating) return;
    setSelectedPlan(plan);
    setError(null);
    setInitiating(true);

    // Track plan selection event
    trackPlanSelection({
      planCode: plan.code,
      planName: plan.name,
      amount: plan.price,
      currency: plan.currency,
    });

    try {
      const { data: sess } = await supabase.auth.getSession();
      const accessToken = sess.session?.access_token;
      if (!accessToken || !trialStatus) throw new Error('Session expirée. Veuillez vous reconnecter.');

      // Le montant et l'entreprise sont déterminés côté serveur : on n'envoie que le plan choisi.
      const response = await fetch('/api/fedapay/initiate-subscription', {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: `Bearer ${accessToken}` },
        body: JSON.stringify({ planCode: plan.code }),
      });

      const result = await response.json();

      if (!response.ok || !result.paymentUrl) {
        throw new Error(result.error ?? 'Impossible d\'initier le paiement FedaPay.');
      }

      // Track payment initiation (confirmed when webhook fires, but track intent here)
      trackPaymentConfirmed({
        paymentType: 'subscription',
        planCode: plan.code,
        amountCents: (plan.billing_amount_xof ?? plan.price) * 100,
        organizationId: trialStatus.organizationId,
      });

      // Redirection vers la page de paiement FedaPay
      window.location.href = result.paymentUrl;
    } catch (err: unknown) {
      const message = err instanceof Error ? err.message : 'Une erreur est survenue.';
      setError(message);
      setInitiating(false);
      setSelectedPlan(null);
    }
  }

  if (loading) {
    return (
      <div className="min-h-screen bg-[#0B1B3D] flex items-center justify-center">
        <div className="flex flex-col items-center gap-4">
          <Loader2 size={32} className="text-[#D4AF37] animate-spin" />
          <p className="text-[#A0AEC0] text-sm">Chargement de votre abonnement…</p>
        </div>
      </div>
    );
  }

  const isExpired = trialStatus?.status === 'expired';
  const isTrial = trialStatus?.status === 'trial';
  const daysLeft = trialStatus?.daysRemaining ?? 0;

  return (
    <div className="min-h-screen bg-[#0B1B3D] py-12 px-4">
      {/* Header */}
      <div className="max-w-5xl mx-auto text-center mb-12">
        <div className="inline-flex items-center gap-2 bg-[rgba(212,175,55,0.1)] border border-[rgba(212,175,55,0.2)] rounded-full px-4 py-1.5 mb-6">
          <Star size={14} className="text-[#D4AF37]" />
          <span className="text-xs font-semibold text-[#D4AF37] uppercase tracking-wider">JDV CRM — Abonnement</span>
        </div>

        {isTrial && daysLeft > 0 && (
          <div className="inline-flex items-center gap-2 bg-[rgba(99,179,237,0.1)] border border-[rgba(99,179,237,0.2)] rounded-xl px-5 py-3 mb-6">
            <Bell size={16} className="text-[#63B3ED]" />
            <span className="text-sm text-[#63B3ED]">
              Essai gratuit — <strong>{daysLeft} jour{daysLeft > 1 ? 's' : ''}</strong> restant{daysLeft > 1 ? 's' : ''}
            </span>
          </div>
        )}

        {isExpired && (
          <div className="inline-flex items-center gap-2 bg-[rgba(252,129,129,0.1)] border border-[rgba(252,129,129,0.2)] rounded-xl px-5 py-3 mb-6">
            <AlertCircle size={16} className="text-[#FC8181]" />
            <span className="text-sm text-[#FC8181]">
              Votre essai a expiré. Choisissez un plan pour continuer à utiliser les fonctionnalités premium.
            </span>
          </div>
        )}

        <h1 className="text-3xl md:text-4xl font-bold text-white mb-4">
          Choisissez votre <span className="gold-gradient-text">plan JDV CRM</span>
        </h1>
        <p className="text-[#A0AEC0] text-base max-w-xl mx-auto">
          Gérez vos ventes à crédit, vos prospecteurs terrain et votre recouvrement avec une solution pensée pour l'Afrique de l'Ouest.
        </p>
      </div>

      {/* Error */}
      {error && (
        <div className="max-w-5xl mx-auto mb-6">
          <div className="flex items-center gap-3 bg-[rgba(252,129,129,0.1)] border border-[rgba(252,129,129,0.2)] rounded-xl px-5 py-3">
            <AlertCircle size={16} className="text-[#FC8181] flex-shrink-0" />
            <p className="text-sm text-[#FC8181]">{error}</p>
          </div>
        </div>
      )}

      {/* Plans grid */}
      <div className="max-w-5xl mx-auto grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-5 mb-12">
        {plans.map(plan => (
          <div
            key={plan.id}
            className={`relative flex flex-col rounded-2xl border transition-all duration-200 ${
              plan.recommended
                ? 'bg-gradient-to-b from-[#132a56] to-[#0F2347] border-[rgba(212,175,55,0.5)] shadow-[0_0_40px_rgba(212,175,55,0.12)]'
                : 'bg-[#0F2347] border-[rgba(212,175,55,0.15)] hover:border-[rgba(212,175,55,0.35)]'
            }`}
          >
            {plan.recommended && (
              <div className="absolute -top-3 left-1/2 -translate-x-1/2">
                <span className="btn-gold text-xs font-bold px-3 py-1 rounded-full">Recommandé</span>
              </div>
            )}

            <div className="p-5 flex-1">
              <h3 className="text-base font-bold text-white mb-1">{plan.name}</h3>
              <div className="flex items-baseline gap-1 mb-1">
                <span className="text-3xl font-bold text-[#D4AF37]">{plan.price}</span>
                <span className="text-sm text-[#A0AEC0]">{plan.currency}</span>
              </div>
              {plan.billing_amount_xof ? (
                <p className="text-xs text-[#A0AEC0] mb-1">
                  Réglé en francs CFA : <span className="font-semibold text-white">{new Intl.NumberFormat('fr-FR').format(plan.billing_amount_xof)} XOF</span>
                </p>
              ) : null}
              <p className="text-xs text-[#718096] mb-4">{plan.duration_days} jours</p>

              <div className="flex items-center gap-2 bg-[rgba(212,175,55,0.08)] rounded-lg px-3 py-2 mb-4">
                <Users size={13} className="text-[#D4AF37]" />
                <span className="text-xs text-[#D4AF37] font-semibold">{plan.prospecteur_limit} prospecteur{plan.prospecteur_limit !== '1' ? 's' : ''}</span>
              </div>

              <ul className="space-y-2">
                {plan.features.map((f, i) => (
                  <li key={i} className="flex items-start gap-2 text-xs text-[#A0AEC0]">
                    <CheckCircle size={13} className="text-[#68D391] flex-shrink-0 mt-0.5" />
                    {f}
                  </li>
                ))}
              </ul>
            </div>

            <div className="p-5 pt-0">
              <button
                onClick={() => handleSelectPlan(plan)}
                disabled={initiating}
                className={`w-full flex items-center justify-center gap-2 py-2.5 rounded-xl text-sm font-semibold transition-all disabled:opacity-60 disabled:cursor-not-allowed ${
                  plan.recommended
                    ? 'btn-gold' :'btn-outline-gold'
                }`}
              >
                {initiating && selectedPlan?.id === plan.id ? (
                  <>
                    <Loader2 size={14} className="animate-spin" />
                    Redirection…
                  </>
                ) : (
                  <>
                    Choisir ce plan
                    <ArrowRight size={14} />
                  </>
                )}
              </button>
            </div>
          </div>
        ))}
      </div>

      {/* Features overview */}
      <div className="max-w-5xl mx-auto">
        <h2 className="text-lg font-bold text-white text-center mb-6">Tout ce qui est inclus dans chaque plan</h2>
        <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
          {[
            { icon: <Zap size={20} />, label: 'Ventes à crédit', desc: 'Échéanciers automatiques' },
            { icon: <Users size={20} />, label: 'Prospecteurs terrain', desc: 'Suivi des agents' },
            { icon: <BarChart2 size={20} />, label: 'Rapports détaillés', desc: 'Analyse financière' },
            { icon: <Package size={20} />, label: 'Gestion du stock', desc: 'Transferts & réceptions' },
            { icon: <Shield size={20} />, label: 'Sécurité RLS', desc: 'Données isolées par org.' },
            { icon: <Bell size={20} />, label: 'Notifications', desc: 'Relances impayés' },
            { icon: <CheckCircle size={20} />, label: 'Journal d\'audit', desc: 'Traçabilité complète' },
            { icon: <Star size={20} />, label: 'Support dédié', desc: 'Selon le plan choisi' },
          ].map((f, i) => (
            <div key={i} className="bg-[#0F2347] border border-[rgba(212,175,55,0.1)] rounded-xl p-4 flex items-start gap-3">
              <div className="p-2 rounded-lg bg-[rgba(212,175,55,0.1)] text-[#D4AF37] flex-shrink-0">{f.icon}</div>
              <div>
                <p className="text-xs font-semibold text-white">{f.label}</p>
                <p className="text-xs text-[#718096]">{f.desc}</p>
              </div>
            </div>
          ))}
        </div>
      </div>

      {/* Security note */}
      <div className="max-w-5xl mx-auto mt-8 text-center">
        <p className="text-xs text-[#718096]">
          Paiement sécurisé via <span className="text-[#D4AF37]">FedaPay</span> · Aucune donnée bancaire stockée sur nos serveurs · Annulation possible à tout moment
        </p>
      </div>
    </div>
  );
}
