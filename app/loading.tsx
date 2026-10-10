"use client";

import { useEffect, useState } from 'react';
import { ArrowRight, Banknote, BriefcaseBusiness, Globe2, Landmark, Users } from 'lucide-react';

const steps = [
  { icon: Globe2, label: 'Écosystème', text: 'Un espace numérique intégré' },
  { icon: Landmark, label: 'Services', text: 'Des solutions au même endroit' },
  { icon: BriefcaseBusiness, label: 'Entreprises', text: 'Des outils pour vos activités' },
  { icon: Users, label: 'Communauté', text: 'Des personnes et organisations connectées' },
  { icon: Banknote, label: 'Finances', text: 'Des services pour vos opérations' },
];

const slides = [
  { image: '/assets/images/app_logo.png', title: 'Un écosystème numérique ouvert sur le monde', alt: 'Identité visuelle de JDV Global Center, plateforme numérique internationale' },
  { image: '/assets/images/app_logo.png', title: 'Des services réunis pour les individus et les organisations', alt: 'Logo JDV Global Center illustrant des services numériques connectés' },
  { image: '/assets/images/app_logo.png', title: 'Une plateforme qui accompagne vos projets et votre croissance', alt: 'Logo JDV Global Center' },
];

export default function Loading() {
  const [slide, setSlide] = useState(0);
  useEffect(() => {
    const timer = window.setInterval(() => setSlide((current) => (current + 1) % slides.length), 10000);
    return () => window.clearInterval(timer);
  }, []);

  return (
    <main className="jdv-loading jdv-loading--extended" aria-label="Chargement de JDV Global Center">
      <div className="jdv-loading__glow jdv-loading__glow--one" />
      <div className="jdv-loading__glow jdv-loading__glow--two" />
      <div className="jdv-loading__grid" />
      <section className="jdv-loading__content">
        <div className="jdv-loading__brand">
          <div className="jdv-loading__logo-wrap">
            <div className="jdv-loading__orbit jdv-loading__orbit--outer" />
            <div className="jdv-loading__orbit jdv-loading__orbit--inner" />
            <div className="jdv-loading__logo-card"><img src="/assets/images/app_logo.png" alt="Logo JDV Global Center" className="jdv-loading__logo" /></div>
          </div>
          <div className="jdv-loading__name">JDV <span>Global Center</span></div>
          <p>Services numériques • Finances • Entreprises • Commerce • Communauté</p>
        </div>

        <div className="jdv-loading__headline">
          <span>Un monde de services à portée de main.</span><strong>Un écosystème numérique pour vos projets.</strong><span>Des solutions pour avancer ensemble.</span>
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
            {slides.map((item, index) => <img key={item.image + index} src={item.image} alt={item.alt} className={`jdv-loading__hero-image ${index === slide ? 'is-active' : ''}`} />)}
            <div className="jdv-loading__hero-overlay" />
            <div className="jdv-loading__hero-caption"><span>JDV GLOBAL CENTER • {slide + 1}/3</span><strong>{slides[slide].title}</strong></div>
          </div>
        </div>

        <div className="jdv-loading__timeline" aria-hidden="true">
          {slides.map((item, index) => <i key={item.image + index} className={index === slide ? 'is-active' : ''} />)}
        </div>

        <div className="jdv-loading__progress">
          <div className="jdv-loading__progress-track"><span /></div>
          <div className="jdv-loading__status"><span>JDV Global Center prépare votre espace</span><span>Chargement en cours</span></div>
        </div>
      </section>
      <p className="jdv-loading__footer">Connecter les services. Accompagner les projets. Ouvrir les possibilités.</p>
    </main>
  );
}
