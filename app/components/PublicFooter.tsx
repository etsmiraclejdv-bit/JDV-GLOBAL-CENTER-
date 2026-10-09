import React from 'react';
import Link from 'next/link';
import AppLogo from '@/components/ui/AppLogo';

export default function PublicFooter() {
  return (
    <footer id="about" className="border-t border-border py-12 mt-8">
      <div className="max-w-screen-xl mx-auto px-6 lg:px-10">
        <div className="grid grid-cols-1 md:grid-cols-4 gap-8 mb-10">
          <div className="md:col-span-2">
            <div className="flex items-center gap-2 mb-4">
              <AppLogo size={28} />
              <span className="font-bold text-lg tracking-tight">
                JDV <span className="gold-gradient-text">CRM</span>
              </span>
            </div>
            <p className="text-sm text-muted-foreground leading-relaxed max-w-xs">
              La plateforme CRM conçue pour la vente à crédit avec paiements journaliers et agents terrain en Afrique de l&apos;Ouest.
            </p>
          </div>

          <div>
            <p className="text-xs font-semibold uppercase tracking-widest text-muted-foreground mb-4" style={{ letterSpacing: '0.08em' }}>Produit</p>
            <ul className="space-y-2">
              {[
                { label: 'Fonctionnalités', href: '/#features' },
                { label: 'Tarifs', href: '/#pricing' },
                { label: 'Essai gratuit', href: '/#register' },
              ].map((item) => (
                <li key={`footer-product-${item.label}`}>
                  <Link href={item.href} className="text-sm text-muted-foreground hover:text-foreground transition-colors">{item.label}</Link>
                </li>
              ))}
            </ul>
          </div>

          <div>
            <p className="text-xs font-semibold uppercase tracking-widest text-muted-foreground mb-4" style={{ letterSpacing: '0.08em' }}>Support</p>
            <ul className="space-y-2">
              {[
                { label: 'Guide d\'utilisation', href: '/guide-onboarding' },
                { label: 'Espace entreprise', href: '/business/login' },
                { label: 'Espace prospecteur', href: '/terrain/login' },
              ].map((item) => (
                <li key={`footer-support-${item.label}`}>
                  <Link href={item.href} className="text-sm text-muted-foreground hover:text-foreground transition-colors">{item.label}</Link>
                </li>
              ))}
            </ul>
          </div>
        </div>

        <div className="border-t border-border pt-6 flex flex-col md:flex-row items-center justify-between gap-4">
          <p className="text-xs text-muted-foreground">
            © 2026 JDV CRM. Tous droits réservés.
          </p>
          <div className="flex gap-6">
            <Link href="/legal#confidentialite" className="text-xs text-muted-foreground hover:text-foreground transition-colors">Confidentialité</Link>
            <Link href="/legal#conditions" className="text-xs text-muted-foreground hover:text-foreground transition-colors">Conditions</Link>
            <Link href="/legal#mentions" className="text-xs text-muted-foreground hover:text-foreground transition-colors">Mentions légales</Link>
          </div>
        </div>
      </div>
    </footer>
  );
}