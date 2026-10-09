'use client';
import React, { useState } from 'react';
import { BookOpen, Users, Building2, ShieldCheck, ChevronDown, ChevronUp, ShoppingCart, Package, ArrowLeftRight, RotateCcw, Wrench, Bell, ClipboardList, Wallet, UserPlus, Settings, BarChart2, Truck, MapPin, Star, CheckCircle, AlertCircle, Info,  } from 'lucide-react';
import Link from 'next/link';

interface Step {
  num: number;
  title: string;
  icon: React.ReactNode;
  desc: string;
  tips?: string[];
}

interface Section {
  id: string;
  role: string;
  roleColor: string;
  icon: React.ReactNode;
  description: string;
  steps: Step[];
}

const sections: Section[] = [
  // ── PROSPECTEUR TERRAIN ──────────────────────────────────────────────
  {
    id: 'terrain',
    role: 'Prospecteur Terrain',
    roleColor: '#63B3ED',
    icon: <MapPin size={20} />,
    description: 'Guide complet pour les agents terrain : de la connexion à la gestion quotidienne de vos prospects, ventes et commissions.',
    steps: [
      {
        num: 1,
        title: 'Connexion au portail terrain',
        icon: <ShieldCheck size={16} />,
        desc: 'Accédez à /terrain/login avec vos identifiants fournis par votre administrateur entreprise. Votre compte est créé par l\'admin, pas en self-service.',
        tips: ['Utilisez l\'icône œil pour afficher/masquer votre mot de passe', 'En cas de compte inactif, contactez votre admin entreprise'],
      },
      {
        num: 2,
        title: 'Tableau de bord — Vue d\'ensemble',
        icon: <BarChart2 size={16} />,
        desc: 'Votre tableau de bord affiche vos ventes du jour, vos prospects actifs (chaud/tiède/froid), votre commission du jour et de la semaine, et un fil d\'activité récente.',
        tips: ['Les badges de couleur indiquent la température du prospect : rouge = chaud, jaune = tiède, bleu = froid'],
      },
      {
        num: 3,
        title: 'Créer un nouveau prospect',
        icon: <UserPlus size={16} />,
        desc: 'Depuis Mes prospects → Nouveau prospect : saisissez le nom, téléphone (anti-doublon automatique), produit d\'intérêt et notes. Le prospect vous est automatiquement assigné.',
        tips: ['Si le téléphone existe déjà, la base refusera la création — vérifiez avant de saisir', 'Ne tentez jamais de modifier le champ prospecteur_id — il est verrouillé sur votre session'],
      },
      {
        num: 4,
        title: 'Suivi des prospects et activités',
        icon: <Users size={16} />,
        desc: 'Enregistrez chaque interaction (appel, visite, message) via "Ajouter une activité". La date de dernier contact est mise à jour automatiquement. Planifiez des relances via next_follow_up_at.',
        tips: ['Un badge "À relancer aujourd\'hui" apparaît sur les prospects dont la relance est due', 'Les visites terrain peuvent inclure une géolocalisation si votre navigateur l\'autorise'],
      },
      {
        num: 5,
        title: 'Enregistrer une vente',
        icon: <ShoppingCart size={16} />,
        desc: 'Depuis Mes ventes → Nouvelle vente : sélectionnez le client (ou créez-le rapidement), l\'article, le type (comptant/crédit), la quantité et l\'acompte. Les échéances sont générées automatiquement par la base.',
        tips: ['Ne calculez jamais les échéances manuellement — le système le fait', 'Si le stock est insuffisant, la base affichera un message d\'erreur explicite'],
      },
      {
        num: 6,
        title: 'Consulter mes commissions',
        icon: <Wallet size={16} />,
        desc: 'L\'onglet Ma commission affiche vos commissions en attente et réglées, avec le détail par vente. Le règlement est effectué par le Super Admin depuis le portail de supervision.',
        tips: ['Les commissions sont calculées automatiquement à chaque vente enregistrée'],
      },
      {
        num: 7,
        title: 'Notifications et alertes',
        icon: <Bell size={16} />,
        desc: 'L\'icône cloche en haut à droite affiche vos notifications non lues (relances impayés, alertes stock, etc.). Cliquez sur une notification pour la marquer comme lue.',
        tips: ['Les relances impayés sont générées automatiquement par la tâche de maintenance'],
      },
      {
        num: 8,
        title: 'Mon profil et paramètres personnels',
        icon: <Settings size={16} />,
        desc: 'Cliquez sur "Mon profil" en bas de la barre latérale pour modifier votre nom, téléphone, avatar et langue préférée. Ces changements s\'appliquent immédiatement.',
        tips: ['Le sélecteur de langue (FR/EN) est disponible dans votre profil'],
      },
    ],
  },

  // ── ENTREPRISE / BUSINESS ADMIN ──────────────────────────────────────
  {
    id: 'business',
    role: 'Entreprise (Admin)',
    roleColor: '#D4AF37',
    icon: <Building2 size={20} />,
    description: 'Guide pour les administrateurs entreprise : gestion complète de l\'activité, des prospecteurs, du stock, des ventes et des rapports.',
    steps: [
      {
        num: 1,
        title: 'Connexion et tableau de bord',
        icon: <ShieldCheck size={16} />,
        desc: 'Accédez à /business/login. Votre compte est créé lors de l\'inscription de votre entreprise sur la page publique. Le tableau de bord affiche les KPI clés : encaissements, prospecteurs actifs, prospects par température.',
        tips: ['Seul le rôle business_admin peut accéder à ce portail'],
      },
      {
        num: 2,
        title: 'Ajouter un prospecteur',
        icon: <UserPlus size={16} />,
        desc: 'Depuis Prospecteurs → Ajouter un prospecteur : remplissez le formulaire (nom, email, téléphone, taux de commission). Le compte Supabase Auth est créé automatiquement côté serveur — le prospecteur reçoit ses identifiants par email.',
        tips: ['Le code prospecteur est généré automatiquement', 'Le taux de commission par défaut est celui de votre organisation'],
      },
      {
        num: 3,
        title: 'Gestion des prospects',
        icon: <Users size={16} />,
        desc: 'Tableau filtrable par température (chaud/tiède/froid), prospecteur et statut. Seul l\'admin peut réassigner un prospect à un autre prospecteur — avec confirmation explicite.',
        tips: ['La protection anti-vol de prospect est gérée par la base de données', 'Si la réassignation échoue, le message d\'erreur PostgreSQL s\'affiche tel quel'],
      },
      {
        num: 4,
        title: 'Catalogue articles',
        icon: <BookOpen size={16} />,
        desc: 'Depuis Catalogue : créez et gérez vos articles (code, nom, catégorie, prix fixe/comptant/crédit, acompte minimum). Désactivez un article plutôt que de le supprimer pour préserver l\'historique des ventes.',
        tips: ['Chaque article crée automatiquement une ligne de stock à quantité 0'],
      },
      {
        num: 5,
        title: 'Réception de marchandises (stock)',
        icon: <Truck size={16} />,
        desc: 'Stock → Réceptions : créez un bon de réception lié à un bon de commande, ajoutez les lignes reçues, puis cliquez "Valider la réception". La fonction jdvcrm_process_goods_receipt_v1 met à jour le stock automatiquement.',
        tips: ['Ne modifiez jamais le stock directement — passez toujours par une réception ou un transfert'],
      },
      {
        num: 6,
        title: 'Transferts de stock',
        icon: <ArrowLeftRight size={16} />,
        desc: 'Stock → Transferts : créez le transfert (draft), puis "Envoyer" pour décrémenter le stock source (statut in_transit), puis "Confirmer la réception" pour incrémenter le stock destination.',
        tips: ['Les quantités reçues peuvent différer des quantités envoyées (casse/perte)'],
      },
      {
        num: 7,
        title: 'Enregistrer une vente et un paiement',
        icon: <ShoppingCart size={16} />,
        desc: 'Ventes → Nouvelle vente : sélectionnez le client, l\'article, le type (comptant/crédit). Depuis la fiche de vente, bouton "Enregistrer un paiement" pour saisir un encaissement (espèces, mobile money ou FedaPay si configuré).',
        tips: ['Les échéances et le stock sont gérés automatiquement par les triggers', 'La plus ancienne échéance non soldée est présélectionnée dans le formulaire de paiement'],
      },
      {
        num: 8,
        title: 'Retours de vente',
        icon: <RotateCcw size={16} />,
        desc: 'Depuis la fiche d\'une vente → "Enregistrer un retour" : saisissez la raison, les articles retournés et les montants remboursés. La fonction jdvcrm_process_sale_return réintègre le stock et ajuste les montants.',
        tips: ['Le motif de retour est obligatoire', 'Les articles suivis par numéro de série sont validés automatiquement'],
      },
      {
        num: 9,
        title: 'Rapports et analyses',
        icon: <BarChart2 size={16} />,
        desc: 'Rapports → 4 onglets : Ventes, Paiements, Commissions, Impayés. Filtrez par plage de dates. Les 5 fonctions RPC de reporting sont appelées en parallèle pour des performances optimales.',
        tips: ['Les rapports sont filtrés automatiquement sur votre organisation par RLS'],
      },
      {
        num: 10,
        title: 'Journal d\'audit',
        icon: <ClipboardList size={16} />,
        desc: 'Audit → Journal de toutes les modifications (ventes, paiements, membres, prospects, stock). Filtrez par type d\'entité, action, utilisateur et plage de dates. Les changements sont affichés en différentiel lisible.',
        tips: ['Le journal est alimenté automatiquement par les triggers — aucune écriture manuelle'],
      },
      {
        num: 11,
        title: 'Notifications',
        icon: <Bell size={16} />,
        desc: 'L\'icône cloche affiche les notifications non lues de votre organisation (relances impayés, alertes stock bas, etc.). Cliquez pour marquer comme lue.',
        tips: ['Les relances sont générées par la tâche de maintenance "Relances impayés"'],
      },
      {
        num: 12,
        title: 'Paramètres entreprise',
        icon: <Settings size={16} />,
        desc: 'Paramètres → 4 onglets : Général (infos légales), Personnalisation (logo, couleurs, aperçu en temps réel), Paramètres avancés (notifications, ventes, stock), Paiement en ligne (clés FedaPay de votre entreprise).',
        tips: ['La clé secrète FedaPay n\'est jamais renvoyée en lecture — utilisez "Remplacer la clé" pour la modifier'],
      },
      {
        num: 13,
        title: 'Abonnement JDV CRM',
        icon: <Star size={16} />,
        desc: 'Depuis /payment-wall ou Paramètres → Abonnement : choisissez votre plan (Mensuel 50$, Trimestriel 150$, Semestriel 300$, Annuel 600$). Le paiement est traité via FedaPay et l\'abonnement est activé automatiquement.',
        tips: ['L\'essai gratuit dure 3 jours', 'Après expiration, seules les fonctionnalités premium sont verrouillées — pas l\'accès total'],
      },
    ],
  },

  // ── SUPER ADMIN / CONCEPTEUR ─────────────────────────────────────────
  {
    id: 'superadmin',
    role: 'Super Admin (Concepteur)',
    roleColor: '#FC8181',
    icon: <ShieldCheck size={20} />,
    description: 'Guide pour le fondateur et les concepteurs autorisés : supervision de toute la plateforme, gestion du stock global, des prospecteurs, de la maintenance et des paramètres plateforme.',
    steps: [
      {
        num: 1,
        title: 'Accès au portail Super Admin',
        icon: <ShieldCheck size={16} />,
        desc: 'Accédez directement à /hidden-concepteur-gate/login (URL non listée dans la navigation publique). Seuls les comptes de la liste fermée AUTHORIZED_CONCEPTEURS peuvent se connecter.',
        tips: ['Compte fondateur : romarica15@gmail.com', 'Aucun formulaire d\'inscription — liste fermée uniquement'],
      },
      {
        num: 2,
        title: 'Vue d\'ensemble plateforme',
        icon: <BarChart2 size={16} />,
        desc: 'Le tableau de bord affiche les KPI globaux de toutes les entreprises : revenus plateforme, entreprises actives/suspendues/en essai, prospecteurs actifs, et graphiques d\'évolution.',
        tips: ['Vous voyez toutes les organisations — pas de filtre RLS à ce niveau'],
      },
      {
        num: 3,
        title: 'Gestion des entreprises',
        icon: <Building2 size={16} />,
        desc: 'Entreprises → liste de toutes les organisations avec statut, abonnement, date d\'inscription. Cliquez sur une entreprise pour activer, suspendre ou consulter ses détails.',
        tips: ['La suspension bloque l\'accès au portail Business de l\'entreprise concernée'],
      },
      {
        num: 4,
        title: 'Stock plateforme (Module 5)',
        icon: <Package size={16} />,
        desc: 'Stock → 6 sous-sections : Fournisseurs, Bons de commande, Réceptions, Inventaire (vue agrégée), Transferts, Mouvements (journal d\'audit stock). Filtrez par entreprise sur chaque écran.',
        tips: ['L\'inventaire est en lecture seule — toute modification passe par une réception ou un transfert', 'Les mouvements sont générés automatiquement par les triggers'],
      },
      {
        num: 5,
        title: 'Gestion des prospecteurs (Module 6)',
        icon: <Users size={16} />,
        desc: 'Prospecteurs → liste globale de tous les agents terrain. Fiche détail : identité, performance (ventes/commissions), stock alloué, prospects assignés. Actions : changer le statut, révoquer l\'accès de connexion.',
        tips: ['La révocation de session passe par une route API serveur — jamais directement côté client', 'L\'indicateur "compte lié" montre si le prospecteur a un accès Supabase Auth actif'],
      },
      {
        num: 6,
        title: 'Commissions en attente',
        icon: <Wallet size={16} />,
        desc: 'Prospecteurs → Commissions : liste des commissions pending. Sélectionnez plusieurs commissions et cliquez "Régler" pour appeler jdvcrm_settle_commission_v1 sur chacune, avec barre de progression.',
        tips: ['Le règlement groupé affiche un résumé succès/échecs à la fin'],
      },
      {
        num: 7,
        title: 'Conversion prospect → client',
        icon: <CheckCircle size={16} />,
        desc: 'Depuis la fiche d\'un prospect (accessible en drill-down depuis la fiche prospecteur) : bouton "Convertir en client" → confirmation → appel jdvcrm_convert_prospect_to_client_v1 → redirection vers la fiche client créée.',
        tips: ['Cette action est irréversible — confirmez avant de valider'],
      },
      {
        num: 8,
        title: 'Maintenance plateforme',
        icon: <Wrench size={16} />,
        desc: 'Maintenance → 5 tâches déclenchables manuellement : expiration des abonnements, marquage des échéances en retard, archivage clients/prospects inactifs, génération des relances impayés.',
        tips: ['Ces tâches remplacent pg_cron — à déclencher régulièrement (quotidien recommandé)', 'Chaque tâche affiche son résultat (lignes traitées, erreurs éventuelles)'],
      },
      {
        num: 9,
        title: 'Journal d\'audit plateforme',
        icon: <ClipboardList size={16} />,
        desc: 'Audit → vue transverse de toutes les organisations. Sélecteur d\'entreprise pour filtrer. Utile pour le support et l\'investigation en cas de litige.',
        tips: ['Filtrez par entity_type (sale, payment, prospect, stock_movement, organization_member) pour cibler votre recherche'],
      },
      {
        num: 10,
        title: 'Paramètres plateforme',
        icon: <Settings size={16} />,
        desc: 'Paramètres → gestion des plans d\'abonnement (CRUD sur subscription_plans), gestion des comptes Super Admin autorisés (activation/désactivation), configuration FedaPay plateforme.',
        tips: ['Ne supprimez jamais une ligne super_admins — désactivez via status/actif', 'Les clés FedaPay plateforme sont stockées en variables d\'environnement serveur, jamais en base'],
      },
      {
        num: 11,
        title: 'Notifications',
        icon: <Bell size={16} />,
        desc: 'L\'icône cloche affiche les notifications de la plateforme. Les notifications sont filtrées sur votre user_id.',
        tips: [],
      },
    ],
  },
];

export default function GuideOnboardingPage() {
  const [openSection, setOpenSection] = useState<string>('business');
  const [openSteps, setOpenSteps] = useState<Record<string, boolean>>({});

  function toggleStep(sectionId: string, stepNum: number) {
    const key = `${sectionId}-${stepNum}`;
    setOpenSteps(prev => ({ ...prev, [key]: !prev[key] }));
  }

  return (
    <div className="min-h-screen bg-[#0B1B3D] py-10 px-4">
      <div className="max-w-4xl mx-auto">
        {/* Header */}
        <div className="text-center mb-10">
          <div className="inline-flex items-center gap-2 bg-[rgba(212,175,55,0.1)] border border-[rgba(212,175,55,0.2)] rounded-full px-4 py-1.5 mb-5">
            <BookOpen size={14} className="text-[#D4AF37]" />
            <span className="text-xs font-semibold text-[#D4AF37] uppercase tracking-wider">Guide d'utilisation</span>
          </div>
          <h1 className="text-3xl font-bold text-white mb-3">
            Guide d'onboarding <span className="gold-gradient-text">JDV CRM</span>
          </h1>
          <p className="text-[#A0AEC0] text-sm max-w-xl mx-auto">
            Retrouvez ici toutes les instructions pour chaque portail. Sélectionnez votre rôle pour accéder aux étapes qui vous concernent.
          </p>
        </div>

        {/* Role tabs */}
        <div className="flex flex-wrap gap-3 justify-center mb-8">
          {sections.map(s => (
            <button
              key={s.id}
              onClick={() => setOpenSection(s.id)}
              className={`flex items-center gap-2 px-4 py-2.5 rounded-xl text-sm font-semibold transition-all border ${
                openSection === s.id
                  ? 'bg-[#0F2347] border-[rgba(212,175,55,0.4)] text-white'
                  : 'bg-transparent border-[rgba(212,175,55,0.15)] text-[#A0AEC0] hover:text-white hover:border-[rgba(212,175,55,0.3)]'
              }`}
            >
              <span style={{ color: openSection === s.id ? s.roleColor : undefined }}>{s.icon}</span>
              {s.role}
            </button>
          ))}
        </div>

        {/* Active section */}
        {sections.filter(s => s.id === openSection).map(section => (
          <div key={section.id}>
            {/* Section header */}
            <div className="bg-[#0F2347] border border-[rgba(212,175,55,0.15)] rounded-2xl p-5 mb-5">
              <div className="flex items-center gap-3 mb-2">
                <div className="p-2 rounded-xl" style={{ backgroundColor: `${section.roleColor}20`, color: section.roleColor }}>
                  {section.icon}
                </div>
                <h2 className="text-lg font-bold text-white">{section.role}</h2>
              </div>
              <p className="text-sm text-[#A0AEC0]">{section.description}</p>
            </div>

            {/* Steps */}
            <div className="space-y-3">
              {section.steps.map(step => {
                const key = `${section.id}-${step.num}`;
                const isOpen = openSteps[key] ?? false;
                return (
                  <div key={step.num} className="bg-[#0F2347] border border-[rgba(212,175,55,0.12)] rounded-2xl overflow-hidden">
                    <button
                      onClick={() => toggleStep(section.id, step.num)}
                      className="w-full flex items-center gap-4 px-5 py-4 text-left hover:bg-[rgba(212,175,55,0.04)] transition-colors"
                    >
                      <div
                        className="w-7 h-7 rounded-full flex items-center justify-center text-xs font-bold flex-shrink-0"
                        style={{ backgroundColor: `${section.roleColor}20`, color: section.roleColor }}
                      >
                        {step.num}
                      </div>
                      <div className="flex items-center gap-2 flex-1 min-w-0">
                        <span style={{ color: section.roleColor }} className="flex-shrink-0">{step.icon}</span>
                        <span className="text-sm font-semibold text-white truncate">{step.title}</span>
                      </div>
                      {isOpen ? (
                        <ChevronUp size={16} className="text-[#718096] flex-shrink-0" />
                      ) : (
                        <ChevronDown size={16} className="text-[#718096] flex-shrink-0" />
                      )}
                    </button>

                    {isOpen && (
                      <div className="px-5 pb-5 border-t border-[rgba(212,175,55,0.08)]">
                        <p className="text-sm text-[#A0AEC0] mt-4 leading-relaxed">{step.desc}</p>
                        {step.tips && step.tips.length > 0 && (
                          <div className="mt-4 space-y-2">
                            {step.tips.map((tip, i) => (
                              <div key={i} className="flex items-start gap-2 bg-[rgba(99,179,237,0.06)] border border-[rgba(99,179,237,0.15)] rounded-xl px-3 py-2">
                                <Info size={13} className="text-[#63B3ED] flex-shrink-0 mt-0.5" />
                                <p className="text-xs text-[#A0AEC0]">{tip}</p>
                              </div>
                            ))}
                          </div>
                        )}
                      </div>
                    )}
                  </div>
                );
              })}
            </div>

            {/* Quick links */}
            <div className="mt-6 bg-[rgba(212,175,55,0.05)] border border-[rgba(212,175,55,0.15)] rounded-2xl p-5">
              <h3 className="text-sm font-semibold text-[#D4AF37] mb-3 flex items-center gap-2">
                <AlertCircle size={14} />
                Liens rapides — {section.role}
              </h3>
              <div className="flex flex-wrap gap-2">
                {section.id === 'terrain' && (
                  <>
                    <Link href="/terrain/login" className="text-xs text-[#63B3ED] hover:text-white bg-[rgba(99,179,237,0.1)] border border-[rgba(99,179,237,0.2)] rounded-lg px-3 py-1.5 transition-colors">Connexion Terrain</Link>
                    <Link href="/terrain/dashboard" className="text-xs text-[#63B3ED] hover:text-white bg-[rgba(99,179,237,0.1)] border border-[rgba(99,179,237,0.2)] rounded-lg px-3 py-1.5 transition-colors">Mon tableau de bord</Link>
                    <Link href="/terrain/dashboard/prospects" className="text-xs text-[#63B3ED] hover:text-white bg-[rgba(99,179,237,0.1)] border border-[rgba(99,179,237,0.2)] rounded-lg px-3 py-1.5 transition-colors">Mes prospects</Link>
                    <Link href="/terrain/dashboard/ventes" className="text-xs text-[#63B3ED] hover:text-white bg-[rgba(99,179,237,0.1)] border border-[rgba(99,179,237,0.2)] rounded-lg px-3 py-1.5 transition-colors">Mes ventes</Link>
                    <Link href="/terrain/dashboard/commission" className="text-xs text-[#63B3ED] hover:text-white bg-[rgba(99,179,237,0.1)] border border-[rgba(99,179,237,0.2)] rounded-lg px-3 py-1.5 transition-colors">Ma commission</Link>
                  </>
                )}
                {section.id === 'business' && (
                  <>
                    <Link href="/business/login" className="text-xs text-[#D4AF37] hover:text-white bg-[rgba(212,175,55,0.1)] border border-[rgba(212,175,55,0.2)] rounded-lg px-3 py-1.5 transition-colors">Connexion Entreprise</Link>
                    <Link href="/business/dashboard" className="text-xs text-[#D4AF37] hover:text-white bg-[rgba(212,175,55,0.1)] border border-[rgba(212,175,55,0.2)] rounded-lg px-3 py-1.5 transition-colors">Tableau de bord</Link>
                    <Link href="/business/dashboard/catalogue" className="text-xs text-[#D4AF37] hover:text-white bg-[rgba(212,175,55,0.1)] border border-[rgba(212,175,55,0.2)] rounded-lg px-3 py-1.5 transition-colors">Catalogue</Link>
                    <Link href="/business/dashboard/ventes" className="text-xs text-[#D4AF37] hover:text-white bg-[rgba(212,175,55,0.1)] border border-[rgba(212,175,55,0.2)] rounded-lg px-3 py-1.5 transition-colors">Ventes</Link>
                    <Link href="/business/dashboard/clients" className="text-xs text-[#D4AF37] hover:text-white bg-[rgba(212,175,55,0.1)] border border-[rgba(212,175,55,0.2)] rounded-lg px-3 py-1.5 transition-colors">Clients</Link>
                    <Link href="/business/dashboard/reports" className="text-xs text-[#D4AF37] hover:text-white bg-[rgba(212,175,55,0.1)] border border-[rgba(212,175,55,0.2)] rounded-lg px-3 py-1.5 transition-colors">Rapports</Link>
                    <Link href="/payment-wall" className="text-xs text-[#D4AF37] hover:text-white bg-[rgba(212,175,55,0.1)] border border-[rgba(212,175,55,0.2)] rounded-lg px-3 py-1.5 transition-colors">Abonnement</Link>
                  </>
                )}
                {section.id === 'superadmin' && (
                  <>
                    <Link href="/hidden-concepteur-gate/dashboard" className="text-xs text-[#FC8181] hover:text-white bg-[rgba(252,129,129,0.1)] border border-[rgba(252,129,129,0.2)] rounded-lg px-3 py-1.5 transition-colors">Dashboard Super Admin</Link>
                    <Link href="/hidden-concepteur-gate/dashboard/maintenance" className="text-xs text-[#FC8181] hover:text-white bg-[rgba(252,129,129,0.1)] border border-[rgba(252,129,129,0.2)] rounded-lg px-3 py-1.5 transition-colors">Maintenance</Link>
                    <Link href="/hidden-concepteur-gate/dashboard/audit" className="text-xs text-[#FC8181] hover:text-white bg-[rgba(252,129,129,0.1)] border border-[rgba(252,129,129,0.2)] rounded-lg px-3 py-1.5 transition-colors">Journal d'audit</Link>
                    <Link href="/hidden-concepteur-gate/dashboard/settings" className="text-xs text-[#FC8181] hover:text-white bg-[rgba(252,129,129,0.1)] border border-[rgba(252,129,129,0.2)] rounded-lg px-3 py-1.5 transition-colors">Paramètres</Link>
                  </>
                )}
              </div>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
}
