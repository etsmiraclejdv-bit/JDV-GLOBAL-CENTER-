import React from 'react';
import { CreditCard, MapPin, Package, AlertCircle, BarChart2, Shield } from 'lucide-react';

const features = [
  {
    id: 'feat-credit',
    icon: <CreditCard size={24} />,
    title: 'Vente à crédit & échéanciers',
    description: 'Créez des plans de paiement journaliers, hebdomadaires ou mensuels. Le moteur de calcul gère automatiquement les intérêts, les soldes et les retards.',
    highlight: 'Paiements journaliers',
    color: 'text-primary',
    bgColor: 'bg-primary/10',
  },
  {
    id: 'feat-terrain',
    icon: <MapPin size={24} />,
    title: 'Prospecteurs terrain',
    description: 'Suivez vos agents en temps réel : visites clients, collectes du jour, prospects chauds/tièdes/froids. Protection anti-vol de lead intégrée.',
    highlight: 'Anti-vol de prospect',
    color: 'text-info',
    bgColor: 'bg-info/10',
  },
  {
    id: 'feat-stock',
    icon: <Package size={24} />,
    title: 'Gestion de stock',
    description: 'Gérez les entrées fournisseurs, les transferts vers agents terrain et les retours. Chaque mouvement de stock est traçable et auditable.',
    highlight: 'Transferts terrain',
    color: 'text-success',
    bgColor: 'bg-success/10',
  },
  {
    id: 'feat-recouvrement',
    icon: <AlertCircle size={24} />,
    title: 'Recouvrement intelligent',
    description: 'Alertes automatiques sur les impayés, tableau des créances par âge, historique des relances et calcul du risque client en temps réel.',
    highlight: 'Alertes automatiques',
    color: 'text-danger',
    bgColor: 'bg-danger/10',
  },
  {
    id: 'feat-commissions',
    icon: <BarChart2 size={24} />,
    title: 'Commissions automatiques',
    description: 'Calculez et réglez les commissions des prospecteurs sur chaque paiement encaissé. Historique complet, paiement groupé en un clic.',
    highlight: 'Règlement en 1 clic',
    color: 'text-warning',
    bgColor: 'bg-warning/10',
  },
  {
    id: 'feat-securite',
    icon: <Shield size={24} />,
    title: 'Sécurité & isolation',
    description: 'Chaque entreprise est isolée par Row Level Security. Rôles granulaires : admin, manager, prospecteur, comptable, observateur.',
    highlight: 'RLS Supabase',
    color: 'text-primary',
    bgColor: 'bg-primary/10',
  },
];

export default function FeaturesSection() {
  return (
    <section id="features" className="py-20">
      <div className="max-w-screen-xl mx-auto px-6 lg:px-10">
        <div className="text-center mb-14">
          <p className="text-xs font-semibold uppercase tracking-widest text-primary mb-3" style={{ letterSpacing: '0.12em' }}>
            Fonctionnalités
          </p>
          <h2 className="text-3xl lg:text-4xl font-extrabold text-foreground mb-4">
            Tout ce dont vous avez besoin,{' '}
            <span className="gold-gradient-text">rien de superflu</span>
          </h2>
          <p className="text-base text-muted-foreground max-w-2xl mx-auto">
            Conçu spécifiquement pour le modèle de vente à crédit avec agents terrain pratiqué en Afrique de l&apos;Ouest.
          </p>
        </div>

        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-6">
          {features?.map((feat) => (
            <div
              key={feat?.id}
              className="card-navy rounded-2xl p-6 feature-card-hover cursor-default"
            >
              <div className={`w-12 h-12 rounded-2xl ${feat?.bgColor} ${feat?.color} flex items-center justify-center mb-4`}>
                {feat?.icon}
              </div>
              <div className="flex items-center gap-2 mb-3">
                <h3 className="text-base font-semibold text-foreground">{feat?.title}</h3>
              </div>
              <p className="text-sm text-muted-foreground leading-relaxed mb-4">
                {feat?.description}
              </p>
              <span className={`inline-flex items-center text-xs font-semibold px-2.5 py-1 rounded-full ${feat?.bgColor} ${feat?.color} border border-current/20`}>
                {feat?.highlight}
              </span>
            </div>
          ))}
        </div>
      </div>
    </section>
  );
}