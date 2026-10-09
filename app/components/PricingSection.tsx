import React from 'react';
import { Check, Zap } from 'lucide-react';

const plans = [
  {
    id: 'plan-mensuel',
    name: 'Mensuel',
    price: '50',
    currency: 'USD',
    duration: '30 jours',
    popular: false,
    features: [
      'Jusqu\'à 5 prospecteurs',
      'Gestion clients & prospects',
      'Ventes à crédit illimitées',
      'Rapports de base',
      'Support email',
    ],
  },
  {
    id: 'plan-trimestriel',
    name: 'Trimestriel',
    price: '150',
    currency: 'USD',
    duration: '90 jours',
    popular: false,
    features: [
      'Jusqu\'à 15 prospecteurs',
      'Gestion stock complète',
      'Transferts terrain',
      'Commissions automatiques',
      'Rapports avancés',
      'Support prioritaire',
    ],
  },
  {
    id: 'plan-semestriel',
    name: 'Semestriel',
    price: '300',
    currency: 'USD',
    duration: '180 jours',
    popular: true,
    features: [
      'Jusqu\'à 30 prospecteurs',
      'Toutes fonctionnalités',
      'Bons de commande fournisseurs',
      'Recouvrement avancé',
      'Export comptable',
      'Support dédié',
      'Formation équipe incluse',
    ],
  },
  {
    id: 'plan-annuel',
    name: 'Annuel',
    price: '600',
    currency: 'USD',
    duration: '365 jours',
    popular: false,
    features: [
      'Prospecteurs illimités',
      'Toutes fonctionnalités',
      'API dédiée',
      'Tableau de bord personnalisé',
      'SLA 99.9%',
      'Gestionnaire de compte dédié',
      'Intégration comptable',
    ],
  },
];

export default function PricingSection() {
  return (
    <section id="pricing" className="py-20">
      <div className="max-w-screen-xl mx-auto px-6 lg:px-10">
        <div className="text-center mb-14">
          <p className="text-xs font-semibold uppercase tracking-widest text-primary mb-3" style={{ letterSpacing: '0.12em' }}>
            Tarifs
          </p>
          <h2 className="text-3xl lg:text-4xl font-extrabold text-foreground mb-4">
            Des prix <span className="gold-gradient-text">transparents</span>, sans surprise
          </h2>
          <p className="text-base text-muted-foreground max-w-xl mx-auto">
            Essai gratuit inclus à l&apos;inscription. Aucune carte bancaire requise pour démarrer.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
          {plans?.map((plan) => (
            <div
              key={plan?.id}
              className={`rounded-2xl p-6 flex flex-col transition-all duration-250 ${
                plan?.popular
                  ? 'pricing-card-popular relative' :'card-navy feature-card-hover'
              }`}
            >
              {plan?.popular && (
                <div className="absolute -top-3 left-1/2 -translate-x-1/2">
                  <span className="btn-gold text-xs font-bold px-4 py-1.5 rounded-full flex items-center gap-1.5">
                    <Zap size={11} />
                    Populaire
                  </span>
                </div>
              )}

              <div className="mb-6">
                <p className="text-sm font-semibold text-muted-foreground mb-2">{plan?.name}</p>
                <div className="flex items-baseline gap-1">
                  <span className="text-4xl font-extrabold text-foreground stat-number">{plan?.price}</span>
                  <span className="text-lg font-bold text-primary">$</span>
                </div>
                <p className="text-xs text-muted-foreground mt-1">{plan?.duration} · renouvelable</p>
              </div>

              <ul className="flex-1 space-y-3 mb-6">
                {plan?.features?.map((feature, fi) => (
                  <li key={`${plan?.id}-feat-${fi}`} className="flex items-start gap-2 text-sm text-muted-foreground">
                    <Check size={14} className="text-success mt-0.5 flex-shrink-0" />
                    {feature}
                  </li>
                ))}
              </ul>

              <a
                href="#register"
                className={`w-full py-3 rounded-xl text-sm font-bold text-center transition-all duration-150 ${
                  plan?.popular
                    ? 'btn-gold' :'btn-outline-gold'
                }`}
              >
                {plan?.popular ? 'Choisir ce plan' : 'Commencer'}
              </a>
            </div>
          ))}
        </div>

        <p className="text-center text-xs text-muted-foreground mt-8">
          Tous les prix sont en USD. Paiement possible en CFA via mobile money ou virement bancaire.
        </p>
      </div>
    </section>
  );
}