import React from 'react';
import Link from 'next/link';
import { ArrowLeft } from 'lucide-react';

export const metadata = { title: 'Informations légales — JDV CRM' };

export default function LegalPage() {
  return (
    <main className="min-h-screen bg-background">
      <div className="max-w-3xl mx-auto px-6 py-16 space-y-12">
        <Link href="/" className="inline-flex items-center gap-2 text-sm text-muted-foreground hover:text-foreground transition-colors">
          <ArrowLeft size={14} /> Retour à l&apos;accueil
        </Link>

        <section id="conditions" className="space-y-3 scroll-mt-24">
          <h1 className="text-2xl font-bold text-foreground">Conditions d&apos;utilisation</h1>
          <p className="text-sm text-muted-foreground leading-relaxed">
            JDV CRM est un service en ligne de gestion de la vente à crédit : clients, prospects, ventes, paiements, stock et équipes terrain.
            Chaque entreprise dispose d&apos;un espace isolé et reste responsable des données qu&apos;elle y saisit et de l&apos;usage que font ses collaborateurs de leurs accès.
            L&apos;abonnement est facturé selon le plan choisi ; l&apos;accès à l&apos;espace peut être suspendu si l&apos;abonnement expire.
          </p>
        </section>

        <section id="confidentialite" className="space-y-3 scroll-mt-24">
          <h2 className="text-xl font-bold text-foreground">Politique de confidentialité</h2>
          <p className="text-sm text-muted-foreground leading-relaxed">
            Les données de votre entreprise sont stockées dans une base sécurisée où chaque entreprise ne voit que ses propres informations.
            Les paiements d&apos;abonnement sont traités par FedaPay et les emails transactionnels envoyés via Resend.
            Vous pouvez demander l&apos;accès, la correction ou la suppression de vos données en contactant l&apos;éditeur.
          </p>
        </section>

        <section id="mentions" className="space-y-3 scroll-mt-24">
          <h2 className="text-xl font-bold text-foreground">Mentions légales</h2>
          <p className="text-sm text-muted-foreground leading-relaxed">
            Éditeur : JDV Global Center. Les informations d&apos;immatriculation, l&apos;adresse et le contact de l&apos;éditeur doivent être complétés ici par le propriétaire du service.
          </p>
        </section>
      </div>
    </main>
  );
}
