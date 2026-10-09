'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import {
  ArrowRight,
  BarChart3,
  Building2,
  CheckCircle2,
  CreditCard,
  MapPin,
  Package,
  Phone,
  ShieldCheck,
  Smartphone,
  Users,
  Wallet,
} from 'lucide-react';

const terrainPoints = [
  ['Portefeuille terrain', 'Prospects, clients, visites et rendez-vous au même endroit.'],
  ['Vente à crédit', 'Enregistrez la vente, les échéances et les paiements journaliers.'],
  ['Communication', 'Appel et WhatsApp accessibles directement depuis le dossier.'],
  ['Stock terrain', 'Chaque prospecteur est rattaché à son entrepôt et à son stock.'],
];

const adminPoints = [
  ['Pilotage commercial', 'Suivez les ventes, le chiffre d’affaires, les encaissements et les retards.'],
  ['Prospecteurs', 'Affectez, suivez et accompagnez vos équipes terrain.'],
  ['Stock & entrepôts', 'Contrôlez les entrées, transferts, sorties et retours avec traçabilité.'],
  ['Commissions & rapports', 'Calculez les commissions et prenez vos décisions avec des données fiables.'],
];

export default function PublicExperience() {
  const [intro, setIntro] = useState(true);

  useEffect(() => {
    const seen = window.sessionStorage.getItem('jdv_crm_intro_seen');
    if (seen === '1') {
      setIntro(false);
      return;
    }
    const timer = window.setTimeout(() => {
      window.sessionStorage.setItem('jdv_crm_intro_seen', '1');
      setIntro(false);
    }, 5200);
    return () => window.clearTimeout(timer);
  }, []);

  if (intro) {
    return (
      <div className="fixed inset-0 z-[100] overflow-hidden bg-[#050d22] text-white">
        <div className="absolute inset-0 bg-[radial-gradient(circle_at_50%_35%,rgba(212,175,55,.18),transparent_32%),radial-gradient(circle_at_15%_80%,rgba(99,179,237,.10),transparent_28%)]" />
        <div className="absolute inset-0 opacity-20 [background-image:linear-gradient(rgba(212,175,55,.15)_1px,transparent_1px),linear-gradient(90deg,rgba(212,175,55,.15)_1px,transparent_1px)] [background-size:52px_52px] animate-[jdvGrid_14s_linear_infinite]" />
        <div className="relative z-10 flex min-h-full items-center justify-center px-5 py-10">
          <div className="w-full max-w-5xl text-center">
            <div className="mx-auto mb-7 flex h-24 w-24 items-center justify-center rounded-3xl border border-[#D4AF37]/50 bg-[#0B1B3D]/90 p-3 shadow-[0_0_70px_rgba(212,175,55,.25)] animate-[jdvPulse_2.4s_ease-in-out_infinite]">
              <img src="/assets/images/app_logo.png" alt="JDV CRM" className="h-full w-full rounded-2xl object-contain" />
            </div>
            <p className="text-xs font-bold uppercase tracking-[.35em] text-[#D4AF37] animate-fade-in">JDV CRM</p>
            <h1 className="mt-4 text-3xl font-extrabold sm:text-5xl lg:text-6xl animate-slide-up">
              La gestion commerciale pensée <span className="gold-gradient-text">pour le terrain.</span>
            </h1>
            <p className="mx-auto mt-5 max-w-2xl text-sm leading-7 text-slate-300 sm:text-base animate-slide-up">
              Une seule application pour relier votre équipe terrain, votre administration, vos ventes à crédit,
              vos paiements et votre stock.
            </p>

            <div className="mx-auto mt-9 grid max-w-3xl gap-4 sm:grid-cols-2">
              <div className="rounded-2xl border border-[#63B3ED]/25 bg-[#0F2347]/70 p-5 text-left backdrop-blur-xl animate-[jdvStep_.7s_.25s_both]">
                <div className="mb-3 flex items-center gap-3"><MapPin className="text-[#63B3ED]" /><span className="font-bold">PROSPECTEUR TERRAIN</span></div>
                <p className="text-xs leading-6 text-slate-300">Prospecter, suivre les clients, vendre, encaisser et travailler avec son stock.</p>
              </div>
              <div className="rounded-2xl border border-[#D4AF37]/25 bg-[#0F2347]/70 p-5 text-left backdrop-blur-xl animate-[jdvStep_.7s_.45s_both]">
                <div className="mb-3 flex items-center gap-3"><Building2 className="text-[#D4AF37]" /><span className="font-bold">ADMINISTRATION / ENTREPRISE</span></div>
                <p className="text-xs leading-6 text-slate-300">Piloter l’activité, les équipes, les entrepôts, les ventes, les paiements et les rapports.</p>
              </div>
            </div>

            <div className="mx-auto mt-8 h-1 max-w-md overflow-hidden rounded-full bg-white/10">
              <div className="h-full w-1/2 animate-[jdvProgress_1.7s_ease-in-out_infinite] bg-gradient-to-r from-transparent via-[#D4AF37] to-transparent" />
            </div>
            <button
              type="button"
              onClick={() => { window.sessionStorage.setItem('jdv_crm_intro_seen', '1'); setIntro(false); }}
              className="mt-5 text-xs font-semibold text-slate-400 transition hover:text-white"
            >
              Passer l’introduction <ArrowRight size={13} className="ml-1 inline" />
            </button>
          </div>
        </div>
      </div>
    );
  }

  return (
    <section className="relative overflow-hidden">
      <div className="pointer-events-none absolute inset-0 hero-glow" />

      <div className="relative mx-auto max-w-screen-xl px-6 pb-20 pt-20 lg:px-10 lg:pt-28">
        <div className="grid items-center gap-12 lg:grid-cols-[1.05fr_.95fr]">
          <div className="animate-slide-up">
            <div className="mb-5 inline-flex items-center gap-2 rounded-full badge-gold px-3 py-1.5 text-xs font-semibold">
              <ShieldCheck size={13} /> CRM spécialisé dans la vente à crédit
            </div>
            <h2 className="text-4xl font-extrabold leading-tight sm:text-5xl lg:text-6xl">
              Du premier prospect <span className="gold-gradient-text">au dernier paiement.</span>
            </h2>
            <p className="mt-6 max-w-xl text-base leading-8 text-muted-foreground sm:text-lg">
              JDV CRM a été créé pour résoudre un problème concret : trop de prospects dispersés,
              des équipes difficiles à suivre, des stocks mal tracés et des paiements compliqués à contrôler.
            </p>
            <div className="mt-8 flex flex-wrap gap-3">
              <a href="#terrain" className="btn-gold inline-flex items-center gap-2 rounded-xl px-6 py-3.5 text-sm">Découvrir le terrain <ArrowRight size={16} /></a>
              <a href="#entreprise" className="btn-outline-gold inline-flex items-center gap-2 rounded-xl px-6 py-3.5 text-sm">Voir l’administration <Building2 size={16} /></a>
            </div>
          </div>

          <div className="relative animate-scale-in">
            <div className="overflow-hidden rounded-3xl border border-[#D4AF37]/20 bg-[#0F2347] shadow-card-hover">
              <img src="/assets/images/image_a5395bef-1789673870442.jpg" alt="Tableau de bord JDV CRM" className="h-auto w-full object-cover" />
            </div>
            <div className="absolute -bottom-5 -left-4 hidden rounded-2xl border border-[#63B3ED]/20 bg-[#0B1B3D]/95 px-4 py-3 shadow-xl sm:block">
              <div className="flex items-center gap-3"><MapPin size={18} className="text-[#63B3ED]" /><div><p className="text-[10px] text-slate-400">Équipe terrain</p><p className="text-sm font-bold text-white">Suivie et organisée</p></div></div>
            </div>
            <div className="absolute -right-4 -top-5 hidden rounded-2xl border border-[#D4AF37]/20 bg-[#0B1B3D]/95 px-4 py-3 shadow-xl sm:block">
              <div className="flex items-center gap-3"><BarChart3 size={18} className="text-[#D4AF37]" /><div><p className="text-[10px] text-slate-400">Administration</p><p className="text-sm font-bold text-white">Vue globale</p></div></div>
            </div>
          </div>
        </div>
      </div>

      <div id="terrain" className="relative border-y border-[#D4AF37]/10 bg-[#08152f]/65">
        <div className="mx-auto max-w-screen-xl px-6 py-20 lg:px-10">
          <div className="grid items-center gap-12 lg:grid-cols-[.85fr_1.15fr]">
            <div className="relative">
              <div className="absolute -inset-5 rounded-[2rem] bg-[#63B3ED]/5 blur-2xl" />
              <div className="relative rounded-[2rem] border border-[#63B3ED]/20 bg-[#0A1628] p-7 shadow-card">
                <div className="mb-7 flex items-center justify-between"><div className="flex items-center gap-3"><div className="rounded-xl bg-[#63B3ED]/10 p-3"><Smartphone className="text-[#63B3ED]" size={24} /></div><div><p className="text-xs uppercase tracking-wider text-slate-400">Espace terrain</p><h3 className="font-bold text-white">Mon activité</h3></div></div><span className="rounded-full bg-green-500/10 px-2.5 py-1 text-[10px] text-green-300">En ligne</span></div>
                <div className="grid grid-cols-2 gap-3">
                  {[['24','Prospects'],['8','Rendez-vous'],['5','Ventes'],['320 000 F','Encaissé']].map(([v,l],i)=><div key={l} className="rounded-2xl border border-white/5 bg-white/[.03] p-4 animate-[jdvStep_.7s_both]" style={{animationDelay: (i*120)+'ms'}}><p className="text-xl font-extrabold text-white">{v}</p><p className="mt-1 text-[10px] text-slate-400">{l}</p></div>)}
                </div>
                <div className="mt-4 rounded-2xl border border-[#D4AF37]/10 bg-[#D4AF37]/5 p-4"><div className="flex items-center gap-2 text-xs font-semibold text-[#D4AF37]"><Package size={15} /> Stock rattaché à l’entrepôt</div><p className="mt-2 text-xs leading-5 text-slate-400">Chaque mouvement est tracé entre l’entreprise, l’entrepôt et le prospecteur.</p></div>
              </div>
            </div>
            <div>
              <p className="text-xs font-bold uppercase tracking-[.2em] text-[#63B3ED]">Projet terrain</p>
              <h2 className="mt-3 text-3xl font-extrabold sm:text-4xl">Le prospecteur travaille avec <span className="text-[#63B3ED]">tout son CRM dans la poche.</span></h2>
              <p className="mt-5 text-sm leading-7 text-muted-foreground sm:text-base">L’objectif est simple : permettre à chaque agent de rester concentré sur le terrain tout en donnant à l’entreprise une traçabilité complète de son activité.</p>
              <div className="mt-7 grid gap-3 sm:grid-cols-2">{terrainPoints.map(([title,text])=><div key={title} className="rounded-2xl border border-white/5 bg-white/[.025] p-4 transition hover:-translate-y-1 hover:border-[#63B3ED]/30"><div className="mb-2 flex items-center gap-2 text-sm font-bold text-white"><CheckCircle2 size={15} className="text-[#63B3ED]" />{title}</div><p className="text-xs leading-5 text-slate-400">{text}</p></div>)}</div>
              <div className="mt-7 flex flex-wrap gap-4 text-xs text-slate-400"><span className="inline-flex items-center gap-2"><Phone size={14} /> Appels</span><span className="inline-flex items-center gap-2"><Users size={14} /> Portefeuille clients</span><span className="inline-flex items-center gap-2"><Wallet size={14} /> Encaissements</span></div>
            </div>
          </div>
        </div>
      </div>

      <div id="entreprise" className="relative">
        <div className="mx-auto max-w-screen-xl px-6 py-20 lg:px-10">
          <div className="grid items-center gap-12 lg:grid-cols-[1.1fr_.9fr]">
            <div className="lg:order-2">
              <p className="text-xs font-bold uppercase tracking-[.2em] text-[#D4AF37]">Projet administration / entreprise</p>
              <h2 className="mt-3 text-3xl font-extrabold sm:text-4xl">L’entreprise garde <span className="gold-gradient-text">le contrôle de bout en bout.</span></h2>
              <p className="mt-5 text-sm leading-7 text-muted-foreground sm:text-base">JDV CRM centralise les informations qui comptent pour diriger l’activité : équipes, entrepôts, stocks, ventes, paiements, commissions, créances et rapports.</p>
              <div className="mt-7 grid gap-3 sm:grid-cols-2">{adminPoints.map(([title,text])=><div key={title} className="rounded-2xl border border-[#D4AF37]/10 bg-[#0F2347]/70 p-4 transition hover:-translate-y-1 hover:border-[#D4AF37]/35"><div className="mb-2 flex items-center gap-2 text-sm font-bold text-white"><CheckCircle2 size={15} className="text-[#D4AF37]" />{title}</div><p className="text-xs leading-5 text-slate-400">{text}</p></div>)}</div>
            </div>
            <div className="lg:order-1">
              <div className="rounded-[2rem] border border-[#D4AF37]/20 bg-gradient-to-br from-[#0F2347] to-[#08152f] p-6 shadow-card-hover">
                <div className="mb-5 flex items-center gap-3"><Building2 className="text-[#D4AF37]" size={27} /><div><p className="text-xs text-slate-400">Tableau de pilotage</p><p className="font-bold text-white">Entreprise</p></div></div>
                <div className="space-y-3">
                  {[
                    [BarChart3,'Chiffre d’affaires','Suivi des ventes et encaissements'],
                    [Package,'Entrepôts & stock','Entrées, transferts et retours'],
                    [Users,'Prospecteurs','Affectation et performance'],
                    [CreditCard,'Crédit & recouvrement','Échéances et retards'],
                  ].map(([Icon,title,text],i)=>{const I=Icon as typeof BarChart3;return <div key={title as string} className="flex items-center gap-3 rounded-2xl border border-white/5 bg-white/[.03] p-4 animate-[jdvStep_.7s_both]" style={{animationDelay:(i*120)+'ms'}}><div className="rounded-xl bg-[#D4AF37]/10 p-2.5"><I size={18} className="text-[#D4AF37]" /></div><div><p className="text-sm font-semibold text-white">{title as string}</p><p className="text-[10px] text-slate-400">{text as string}</p></div><ArrowRight size={15} className="ml-auto text-slate-600" /></div>})}
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>

      <div className="mx-auto max-w-screen-xl px-6 pb-16 lg:px-10">
        <div className="rounded-3xl border border-[#D4AF37]/15 bg-[#0F2347]/70 p-7 text-center shadow-card sm:p-10">
          <p className="text-xs font-bold uppercase tracking-[.2em] text-[#D4AF37]">Pourquoi JDV CRM ?</p>
          <h2 className="mt-3 text-2xl font-extrabold sm:text-3xl">Terrain et administration travaillent enfin sur la même information.</h2>
          <p className="mx-auto mt-4 max-w-2xl text-sm leading-7 text-muted-foreground">Une application pensée pour réduire les pertes d’information, sécuriser les stocks, améliorer le suivi des équipes et rendre les ventes à crédit réellement pilotables.</p>
        </div>
      </div>
    </section>
  );
}
