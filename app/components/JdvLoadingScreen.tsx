'use client';

import { useEffect, useState } from 'react';
import { ArrowRight, Award, Banknote, BriefcaseBusiness, Building2, CheckCircle2, CreditCard, GraduationCap, MapPin, Package, Quote, ShieldCheck, Target, Users } from 'lucide-react';

const scenes = [
  { eyebrow:'POURQUOI JDV CRM ?', title:'Une vision conçue pour les entreprises qui veulent grandir.', text:'JDV CRM réunit la gestion de l’entreprise, la prospection terrain, la vente à crédit, le suivi des paiements, le stock, les commissions et le recouvrement dans un même écosystème.', icon:Building2, visual:'vision' },
  { eyebrow:'SUR LE TERRAIN', title:'Le prospecteur au cœur de la croissance.', text:'Chaque prospecteur dispose de son portefeuille, de ses prospects, de ses visites, de ses relances et de ses ventes. Le terrain devient une donnée exploitable par l’entreprise.', icon:MapPin, visual:'prospection' },
  { eyebrow:'VENTE À CRÉDIT', title:'Du premier contact au dernier paiement.', text:'Le client peut acheter, choisir son mode de paiement et suivre ses échéances. L’entreprise conserve la trace de la vente, du stock, des paiements et du recouvrement.', icon:CreditCard, visual:'client' },
  { eyebrow:'FORMATION & MANAGEMENT', title:'Un gestionnaire qui prépare son équipe à réussir.', text:'Le responsable forme, organise et accompagne ses prospecteurs avant leur départ sur le terrain. JDV CRM donne une vision claire des équipes, des performances et des opérations.', icon:GraduationCap, visual:'formation' },
  { eyebrow:'VISION DU FONDATEUR', title:'Mettre la technologie au service du travail réel.', text:'Romaric A. B. ADEDEDJI porte une vision simple : donner aux entreprises des outils professionnels, accessibles et adaptés aux réalités du terrain, afin de transformer chaque activité en organisation maîtrisée.', icon:Target, visual:'founder' },
];

function SceneVisual({type}:{type:string}) {
  if(type==='prospection') return <div className="jdv-scene-visual"><div className="jdv-person jdv-person--prospector"><MapPin size={25}/></div><div className="jdv-client-dot"/><div className="jdv-signal"/><span>Prospection active</span></div>;
  if(type==='client') return <div className="jdv-scene-visual"><Package size={27}/><ArrowRight size={18}/><CreditCard size={27}/><CheckCircle2 size={20}/><span>Achat • Crédit • Suivi</span></div>;
  if(type==='formation') return <div className="jdv-scene-visual jdv-training"><div className="jdv-person"><GraduationCap size={25}/></div><div className="jdv-trainees"><Users size={32}/><Users size={32}/><Users size={32}/></div><span>Équipe prête pour le terrain</span></div>;
  if(type==='founder') return <div className="jdv-scene-visual"><div className="jdv-founder"><Award size={27}/></div><div className="jdv-vision-lines"><i/><i/><i/></div><span>Innovation • Discipline • Croissance</span></div>;
  return <div className="jdv-scene-visual jdv-vision"><ShieldCheck size={30}/><BriefcaseBusiness size={30}/><Banknote size={30}/><span>Une plateforme pensée pour toute l’activité</span></div>;
}

export default function JdvLoadingScreen(){
  const [visible,setVisible]=useState(false),[scene,setScene]=useState(0),[progress,setProgress]=useState(0);
  useEffect(()=>{ if(sessionStorage.getItem('jdv_loading_seen')==='1') return; setVisible(true); const started=Date.now(); const timer=window.setInterval(()=>{const elapsed=Date.now()-started;setProgress(Math.min(100,elapsed/15000*100));if(elapsed>=15000){window.clearInterval(timer);sessionStorage.setItem('jdv_loading_seen','1');setVisible(false);}},100);return()=>window.clearInterval(timer);},[]);
  useEffect(()=>{if(!visible)return;const timer=window.setInterval(()=>setScene(v=>(v+1)%scenes.length),3000);return()=>window.clearInterval(timer);},[visible]);
  if(!visible)return null;
  const current=scenes[scene],Icon=current.icon;
  return <div className="jdv-loading jdv-loading--extended" role="status" aria-label="Présentation de JDV CRM">
    <div className="jdv-loading__grid"/><div className="jdv-loading__glow jdv-loading__glow--one"/><div className="jdv-loading__glow jdv-loading__glow--two"/>
    <section className="jdv-loading__content">
      <div className="jdv-loading__brand"><div className="jdv-loading__logo-wrap"><div className="jdv-loading__orbit jdv-loading__orbit--outer"/><div className="jdv-loading__orbit jdv-loading__orbit--inner"/><div className="jdv-loading__logo-card"><img src="/assets/images/app_logo.png" alt="JDV CRM" className="jdv-loading__logo"/></div></div><div className="jdv-loading__name">JDV <span>CRM</span></div><p>Gestion • Prospection • Vente à crédit • Stock • Recouvrement</p></div>
      <div className="jdv-founder-strip"><div className="jdv-founder-strip__icon"><Quote size={18}/></div><div><strong>Romaric A. B. ADEDEDJI</strong><small>Fondateur, concepteur et porteur de la vision JDV CRM</small></div></div>
      <div className="jdv-loading__story"><div className="jdv-story-copy" key={scene}><div className="jdv-story-eyebrow"><Icon size={15}/>{current.eyebrow}</div><h1>{current.title}</h1><p>{current.text}</p></div><SceneVisual type={current.visual}/></div>
      <div className="jdv-loading__timeline">{scenes.map((_,i)=><i key={i} className={i===scene?'is-active':''}/>)}</div>
      <div className="jdv-loading__progress"><div className="jdv-loading__progress-track"><span style={{width:progress+'%'}}/></div><div className="jdv-loading__status"><span>Découvrez JDV CRM avant d’entrer dans votre espace</span><span>{Math.round(progress)}%</span></div></div>
    </section><p className="jdv-loading__footer">Votre activité. Votre contrôle. Votre croissance.</p>
  </div>;
}