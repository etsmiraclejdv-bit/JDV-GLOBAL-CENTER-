'use client';

import { useEffect, useState } from 'react';
import { ArrowRight, Award, Banknote, BriefcaseBusiness, Building2, CheckCircle2, CreditCard, Globe2, Landmark, Package, Quote, ShieldCheck, Target, Users } from 'lucide-react';

const scenes = [
  { eyebrow:'JDV GLOBAL CENTER', title:'Un écosystème numérique pensé pour vos projets.', text:'JDV Global Center rassemble des services numériques, financiers, commerciaux, professionnels et sociaux dans un espace conçu pour les individus et les organisations.', icon:Globe2, visual:'vision' },
  { eyebrow:'SERVICES CONNECTÉS', title:'Les services essentiels, réunis au même endroit.', text:'Découvrez un environnement qui facilite l’accès aux services, accompagne les démarches et aide chacun à mieux organiser ses activités au quotidien.', icon:Landmark, visual:'services' },
  { eyebrow:'ENTREPRISES & COMMERCE', title:'Des outils pour développer et piloter votre activité.', text:'Les organisations peuvent s’appuyer sur des outils de gestion et sur JDV CRM pour organiser leurs équipes, suivre leurs clients et mieux gérer leurs opérations.', icon:BriefcaseBusiness, visual:'business' },
  { eyebrow:'PERSONNES & COMMUNAUTÉS', title:'Créer des liens et faire avancer les initiatives.', text:'JDV Global Center vise à rapprocher les personnes, les professionnels et les organisations grâce à une plateforme numérique accessible et évolutive.', icon:Users, visual:'community' },
  { eyebrow:'VISION DU FONDATEUR', title:'Mettre la technologie au service des possibilités.', text:'Romaric A. B. ADEDEDJI porte une vision d’un écosystème numérique international qui accompagne les projets et rend les services plus accessibles.', icon:Target, visual:'founder' },
];

function SceneVisual({type}:{type:string}) {
  if(type==='services') return <div className="jdv-scene-visual"><Landmark size={29}/><ArrowRight size={18}/><ShieldCheck size={29}/><CheckCircle2 size={20}/><span>Services • Accès • Confiance</span></div>;
  if(type==='business') return <div className="jdv-scene-visual"><Building2 size={28}/><ArrowRight size={18}/><Package size={27}/><CreditCard size={23}/><span>Entreprise • Commerce • CRM</span></div>;
  if(type==='community') return <div className="jdv-scene-visual jdv-training"><div className="jdv-person"><Globe2 size={25}/></div><div className="jdv-trainees"><Users size={32}/><Users size={32}/><Users size={32}/></div><span>Personnes et organisations connectées</span></div>;
  if(type==='founder') return <div className="jdv-scene-visual"><div className="jdv-founder"><Award size={27}/></div><div className="jdv-vision-lines"><i/><i/><i/></div><span>Vision • Innovation • Développement</span></div>;
  return <div className="jdv-scene-visual jdv-vision"><Globe2 size={30}/><BriefcaseBusiness size={30}/><Banknote size={30}/><span>Un écosystème numérique international</span></div>;
}

export default function JdvLoadingScreen(){
  const [visible,setVisible]=useState(false),[scene,setScene]=useState(0),[progress,setProgress]=useState(0);
  useEffect(()=>{ if(sessionStorage.getItem('jdv_loading_seen')==='1') return; setVisible(true); const started=Date.now(); const timer=window.setInterval(()=>{const elapsed=Date.now()-started;setProgress(Math.min(100,elapsed/15000*100));if(elapsed>=15000){window.clearInterval(timer);sessionStorage.setItem('jdv_loading_seen','1');setVisible(false);}},100);return()=>window.clearInterval(timer);},[]);
  useEffect(()=>{if(!visible)return;const timer=window.setInterval(()=>setScene(v=>(v+1)%scenes.length),3000);return()=>window.clearInterval(timer);},[visible]);
  if(!visible)return null;
  const current=scenes[scene],Icon=current.icon;
  return <div className="jdv-loading jdv-loading--extended" role="status" aria-label="Présentation de JDV Global Center">
    <div className="jdv-loading__grid"/><div className="jdv-loading__glow jdv-loading__glow--one"/><div className="jdv-loading__glow jdv-loading__glow--two"/>
    <section className="jdv-loading__content">
      <div className="jdv-loading__brand"><div className="jdv-loading__logo-wrap"><div className="jdv-loading__orbit jdv-loading__orbit--outer"/><div className="jdv-loading__orbit jdv-loading__orbit--inner"/><div className="jdv-loading__logo-card"><img src="/assets/images/app_logo.png" alt="Logo JDV Global Center" className="jdv-loading__logo"/></div></div><div className="jdv-loading__name">JDV <span>Global Center</span></div><p>Services numériques • Finances • Entreprises • Commerce • Communauté</p></div>
      <div className="jdv-founder-strip"><div className="jdv-founder-strip__icon"><Quote size={18}/></div><div><strong>Romaric A. B. ADEDEDJI</strong><small>Fondateur et porteur de la vision JDV Global Center</small></div></div>
      <div className="jdv-loading__story"><div className="jdv-story-copy" key={scene}><div className="jdv-story-eyebrow"><Icon size={15}/>{current.eyebrow}</div><h1>{current.title}</h1><p>{current.text}</p></div><SceneVisual type={current.visual}/></div>
      <div className="jdv-loading__timeline">{scenes.map((_,i)=><i key={i} className={i===scene?'is-active':''}/>)}</div>
      <div className="jdv-loading__progress"><div className="jdv-loading__progress-track"><span style={{width:progress+'%'}}/></div><div className="jdv-loading__status"><span>Découvrez JDV Global Center avant d’entrer dans votre espace</span><span>{Math.round(progress)}%</span></div></div>
    </section><p className="jdv-loading__footer">Connecter les services. Accompagner les projets. Ouvrir les possibilités.</p>
  </div>;
}
