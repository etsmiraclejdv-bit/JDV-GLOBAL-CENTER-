import React from 'react';
import { ChevronRight, Shield, TrendingUp, Users } from 'lucide-react';
import AppImage from '@/components/ui/AppImage';


export default function HeroSection() {
  const stats = [
    { id: 'stat-companies', value: '340+', label: 'Entreprises actives' },
    { id: 'stat-agents', value: '2 800+', label: 'Agents terrain' },
    { id: 'stat-recovered', value: '94%', label: 'Taux de recouvrement' },
  ];

  return (
    <section className="relative pt-24 pb-20 overflow-hidden">
      {/* Background glow */}
      <div className="absolute inset-0 hero-glow pointer-events-none" />
      <div className="absolute top-32 right-0 w-96 h-96 rounded-full pointer-events-none" style={{ background: 'radial-gradient(circle, rgba(99,179,237,0.06) 0%, transparent 70%)' }} />

      <div className="max-w-screen-xl mx-auto px-6 lg:px-10">
        <div className="grid grid-cols-1 lg:grid-cols-2 gap-16 items-center">
          {/* Left — Copy */}
          <div>
            {/* Logo */}
            <div className="flex items-center gap-3 mb-6">
            </div>

            <div className="inline-flex items-center gap-2 px-3 py-1.5 rounded-full badge-gold text-xs font-semibold ml-[120px] mr-1 -mt-1.5 mb-[26px] pt-2 pb-[11px]">
              <Shield size={12} />
              Plateforme CRM n°1 pour la vente à crédit en Afrique de l&apos;Ouest
            </div>

            <h1 className="text-4xl lg:text-5xl xl:text-6xl font-extrabold text-foreground leading-tight mb-6">
              Gérez vos{' '}
              <span className="gold-gradient-text">ventes à crédit</span>{' '}
              et vos agents terrain
            </h1>

            <p className="text-lg text-muted-foreground leading-relaxed mb-8 max-w-xl">
              JDV CRM centralise vos encaissements journaliers, suit vos prospecteurs terrain en temps réel,
              calcule automatiquement les commissions et vous alerte sur les impayés — tout depuis un seul tableau de bord.
            </p>

            <div className="flex flex-col sm:flex-row gap-4 mb-12">
              <a
                href="#register"
                className="btn-gold px-7 py-3.5 rounded-xl font-bold text-base flex items-center justify-center gap-2"
              >
                Démarrer l&apos;essai gratuit
                <ChevronRight size={16} />
              </a>
              <a
                href="#features"
                className="btn-outline-gold px-7 py-3.5 rounded-xl font-semibold text-base flex items-center justify-center gap-2"
              >
                <TrendingUp size={16} />
                Voir les fonctionnalités
              </a>
            </div>

            {/* Stats row */}
            <div className="flex flex-wrap gap-8">
              {stats?.map((stat) => (
                <div key={stat?.id}>
                  <p className="text-2xl font-extrabold gold-gradient-text stat-number">{stat?.value}</p>
                  <p className="text-xs text-muted-foreground font-medium">{stat?.label}</p>
                </div>
              ))}
            </div>
          </div>

          {/* Right — Dashboard preview */}
          <div className="relative">
            <div className="card-navy shadow-card-hover rounded-3xl overflow-hidden border border-primary/20">
              <div className="bg-muted px-4 py-2.5 flex items-center gap-2 border-b border-border">
                <div className="flex gap-1.5">
                  <div className="w-3 h-3 rounded-full bg-danger opacity-60" />
                  <div className="w-3 h-3 rounded-full bg-warning opacity-60" />
                  <div className="w-3 h-3 rounded-full bg-success opacity-60" />
                </div>
                <div className="flex-1 mx-4 bg-secondary rounded-lg px-3 py-1 text-xs text-muted-foreground text-center">
                  jdvcrm.com/business/dashboard
                </div>
              </div>
              <AppImage
                src="/assets/images/image_a5395bef-1789673870442.jpg"
                alt="JDV CRM tableau de bord principal montrant les encaissements, les agents terrain actifs et le suivi des paiements"
                width={640}
                height={400}
                className="w-full object-cover"
                priority
              />
            </div>

            {/* Floating badges */}
            <div className="absolute -bottom-4 -left-4 card-navy shadow-card-hover rounded-2xl px-4 py-3 flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl badge-success flex items-center justify-center">
                <TrendingUp size={16} className="text-success" />
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Encaissé aujourd&apos;hui</p>
                <p className="text-sm font-bold text-success stat-number">+ 1 240 000 F</p>
              </div>
            </div>

            <div className="absolute -top-4 -right-4 card-navy shadow-card-hover rounded-2xl px-4 py-3 flex items-center gap-3">
              <div className="w-9 h-9 rounded-xl badge-info flex items-center justify-center">
                <Users size={16} className="text-info" />
              </div>
              <div>
                <p className="text-xs text-muted-foreground">Agents actifs</p>
                <p className="text-sm font-bold text-foreground stat-number">18 / 22</p>
              </div>
            </div>
          </div>
        </div>
      </div>
    </section>
  );
}