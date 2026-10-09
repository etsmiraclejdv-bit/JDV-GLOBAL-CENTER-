import Link from 'next/link';
import { ArrowRight, Building2, Globe2, Layers3, Sparkles } from 'lucide-react';

const sectors = [
  { name: 'JDV CRM', description: 'Gestion commerciale, ventes à crédit, prospecteurs et recouvrement.', href: '/crm', active: true },
  { name: 'JDV PAY', description: 'Branche dédiée aux paiements et services financiers.', href: null, active: false },
  { name: 'JDV BUSINESS', description: 'Espace destiné aux activités et services des entreprises.', href: null, active: false },
  { name: 'JDV ACADEMY', description: 'Branche dédiée à la formation et aux apprentissages.', href: null, active: false },
];

export default function GlobalCenterHomePage() {
  return (
    <main className="min-h-screen bg-[#07142d] text-white">
      <header className="border-b border-white/10">
        <div className="mx-auto flex max-w-7xl items-center justify-between px-6 py-5">
          <Link href="/" className="flex items-center gap-3" aria-label="JDV GLOBAL CENTER, accueil">
            <span className="flex h-11 w-11 items-center justify-center rounded-2xl bg-[#D4AF37] text-[#07142d]"><Globe2 size={24} /></span>
            <span><span className="block text-sm font-bold tracking-[0.18em] text-[#D4AF37]">JDV</span><span className="block text-lg font-semibold">GLOBAL CENTER</span></span>
          </Link>
          <span className="hidden text-sm text-slate-300 sm:block">Un écosystème. Des branches indépendantes.</span>
        </div>
      </header>

      <section className="mx-auto grid max-w-7xl gap-12 px-6 py-20 md:grid-cols-[1.2fr_0.8fr] md:items-center md:py-28">
        <div>
          <div className="mb-6 inline-flex items-center gap-2 rounded-full border border-[#D4AF37]/30 bg-[#D4AF37]/10 px-4 py-2 text-sm text-[#E8CC75]"><Sparkles size={16} /> La plateforme centrale JDV</div>
          <h1 className="max-w-3xl text-4xl font-bold leading-tight sm:text-5xl lg:text-6xl">Bienvenue dans <span className="text-[#D4AF37]">JDV GLOBAL CENTER</span></h1>
          <p className="mt-6 max-w-2xl text-lg leading-8 text-slate-300">Un point d’entrée commun pour les différentes branches de l’écosystème Joie de Vivre. Chaque service garde son espace, ses fonctions et son évolution propres : aucune branche ne remplace la plateforme centrale.</p>
          <a href="#branches" className="mt-9 inline-flex items-center gap-2 rounded-xl bg-[#D4AF37] px-6 py-3 font-semibold text-[#07142d] transition hover:bg-[#e4c45d]">Explorer les branches <ArrowRight size={18} /></a>
        </div>
        <div className="rounded-3xl border border-white/10 bg-white/[0.04] p-8 shadow-2xl shadow-black/20">
          <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-white/10 text-[#D4AF37]"><Layers3 size={28} /></div>
          <h2 className="mt-6 text-2xl font-semibold">Un socle, plusieurs secteurs</h2>
          <p className="mt-3 leading-7 text-slate-300">JDV GLOBAL CENTER reste l’accueil principal. Les modules spécialisés sont accessibles séparément et les nouvelles branches seront ajoutées à leur place, sans confondre leurs rôles.</p>
        </div>
      </section>

      <section id="branches" className="border-t border-white/10 bg-[#0b1b3d]">
        <div className="mx-auto max-w-7xl px-6 py-16">
          <div className="mb-9 flex items-end justify-between gap-4">
            <div><p className="text-sm font-semibold uppercase tracking-[0.2em] text-[#D4AF37]">Nos secteurs</p><h2 className="mt-2 text-3xl font-bold">Les branches de JDV</h2></div>
            <Building2 className="hidden text-[#D4AF37] sm:block" size={30} />
          </div>
          <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
            {sectors.map((sector) => (
              <article key={sector.name} className="flex min-h-56 flex-col rounded-2xl border border-white/10 bg-[#07142d] p-6">
                <div className="flex items-center justify-between gap-3"><h3 className="text-xl font-semibold">{sector.name}</h3><span className={sector.active ? 'rounded-full bg-emerald-400/10 px-2.5 py-1 text-xs text-emerald-300' : 'rounded-full bg-white/10 px-2.5 py-1 text-xs text-slate-300'}>{sector.active ? 'Disponible' : 'À développer'}</span></div>
                <p className="mt-4 flex-1 leading-6 text-slate-300">{sector.description}</p>
                {sector.active && sector.href ? <Link href={sector.href} className="mt-5 inline-flex items-center gap-2 font-semibold text-[#D4AF37] hover:text-[#E8CC75]">Accéder à la branche <ArrowRight size={16} /></Link> : <span className="mt-5 text-sm text-slate-500">Espace réservé à son développement futur</span>}
              </article>
            ))}
          </div>
          <p className="mt-8 text-sm text-slate-400">Les branches affichées comme « À développer » sont des secteurs prévus, pas des services annoncés comme déjà opérationnels.</p>
        </div>
      </section>
      <footer className="border-t border-white/10 px-6 py-7 text-center text-sm text-slate-400">© {new Date().getFullYear()} JDV GLOBAL CENTER · Joie de Vivre</footer>
    </main>
  );
}
