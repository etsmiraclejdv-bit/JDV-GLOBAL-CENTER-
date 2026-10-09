"use client";

import { useEffect, useState } from 'react';
import { ArrowRight, Banknote, Building2, CreditCard, MapPin, Users } from 'lucide-react';

const steps = [
  { icon: Building2, label: 'Entreprise', text: 'Pilotez votre activité' },
  { icon: MapPin, label: 'Prospection', text: 'Trouvez les bons prospects' },
  { icon: Users, label: 'Conversion', text: 'Transformez en clients' },
  { icon: CreditCard, label: 'Vente à crédit', text: 'Suivez chaque échéance' },
  { icon: Banknote, label: 'Recouvrement', text: 'Sécurisez vos paiements' },
];

const slides = [
  { image: '/assets/images/CRM mobile pour commerciaux terrain.png', title: 'Prospectez partout avec JDV CRM', alt: 'Commercial terrain enregistrant un prospect dans JDV CRM' },
  { image: '/assets/images/Présentation CRM JDV en entreprise.png', title: 'Transformez vos opportunités en ventes', alt: 'Commercial présentant JDV CRM à son client' },
  { image: '/assets/images/JDV CRM _Votre succès, notre priorité.png', title: 'Pilotez votre croissance avec votre équipe', alt: 'Équipe commerciale utilisant le tableau de bord JDV CRM' },
];

export default function Loading() {
  const [slide, setSlide] = useState(0);
  useEffect(() => {
    const timer = window.setInterval(() => setSlide((current) => (current + 1) % slides.length), 10000);
    return () => window.clearInterval(timer);
  }, []);

  return (
    <main className="jdv-loading jdv-loading--extended" aria-label="Chargement de JDV CRM">
      <div className="jdv-loading__glow jdv-loading__glow--one" />
      <div className="jdv-loading__glow jdv-loading__glow--two" />
      <div className="jdv-loading__grid" />
      <section className="jdv-loading__content">
        <div className="jdv-loading__brand">
          <div className="jdv-loading__logo-wrap">
            <div className="jdv-loading__orbit jdv-loading__orbit--outer" />
            <div className="jdv-loading__orbit jdv-loading__orbit--inner" />
            <div className="jdv-loading__logo-card"><img src="/assets/images/app_logo.png" alt="JDV CRM" className="jdv-loading__logo" /></div>
          </div>
          <div className="jdv-loading__name">JDV <span>CRM</span></div>
          <p>Gestion • Prospection • Vente à crédit • Recouvrement</p>
        </div>

        <div className="jdv-loading__headline">
          <span>Une entreprise mieux gérée.</span><strong>Des prospects mieux convertis.</strong><span>Des ventes mieux suivies.</span>
        </div>

        <div className="jdv-loading__flow" aria-hidden="true">
          {steps.map((step, index) => {
            const Icon = step.icon;
            return <div className="jdv-loading__flow-item" key={step.label} style={{ animationDelay: index * 180 + 'ms' }}>
              <div className="jdv-loading__flow-card"><Icon size={22} strokeWidth={1.8} /><div><b>{step.label}</b><small>{step.text}</small></div>{index < steps.length - 1 && <ArrowRight className="jdv-loading__arrow" size={17} />}</div>
            </div>;
          })}
        </div>

        <div className="jdv-loading__visual" aria-live="polite">
          <div className="jdv-loading__hero">
            {slides.map((item, index) => <img key={item.image} src={item.image} alt={item.alt} className={`jdv-loading__hero-image ${index === slide ? 'is-active' : ''}`} />)}
            <div className="jdv-loading__hero-overlay" />
            <div className="jdv-loading__hero-caption"><span>JDV CRM • {slide + 1}/3</span><strong>{slides[slide].title}</strong></div>
          </div>
        </div>

        <div className="jdv-loading__timeline" aria-hidden="true">
          {slides.map((item, index) => <i key={item.image} className={index === slide ? 'is-active' : ''} />)}
        </div>

        <div className="jdv-loading__progress">
          <div className="jdv-loading__progress-track"><span /></div>
          <div className="jdv-loading__status"><span>JDV CRM prépare votre espace</span><span>30 secondes</span></div>
        </div>
      </section>
      <p className="jdv-loading__footer">Votre activité. Votre contrôle. Votre croissance.</p>
    </main>
  );
}
