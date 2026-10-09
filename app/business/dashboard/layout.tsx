'use client';
import React, { useState } from 'react';
import AppLogo from '@/components/ui/AppLogo';
import NotificationBell from '@/components/NotificationBell';
import UserProfilePanel from '@/components/UserProfilePanel';
import Modal from '@/components/ui/Modal';
import { LayoutDashboard, Users, ShoppingCart, Package, FileText, Settings, LogOut, ChevronLeft, ChevronRight, UserCheck, BookOpen, ClipboardList, User, HelpCircle, AlertTriangle, Wallet, Truck, Percent, Warehouse, Network, MapPin, Undo2, ArrowLeftRight, Store } from 'lucide-react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase/client';
import IntelligencePresenceTracker from '@/components/IntelligencePresenceTracker';
import ConcepteurBranchBar from '@/components/ConcepteurBranchBar';

const navItems = [
  { id:'overview',label:'Vue d\'ensemble',icon:<LayoutDashboard size={18}/>,href:'/business/dashboard',group:'Principal' },
  { id:'intelligence',label:'Intelligence JDV',icon:<AlertTriangle size={18}/>,href:'/business/dashboard/intelligence',group:'Principal' },
  { id:'prospects',label:'Prospects',icon:<UserCheck size={18}/>,href:'/business/dashboard/prospects',group:'CRM' },
  { id:'clients',label:'Clients',icon:<Users size={18}/>,href:'/business/dashboard/clients',group:'CRM' },
  { id:'ventes',label:'Ventes',icon:<ShoppingCart size={18}/>,href:'/business/dashboard/ventes',group:'Commercial' },
  { id:'relances',label:'Relances & impayés',icon:<AlertTriangle size={18}/>,href:'/business/dashboard/relances',group:'Commercial' },
  { id:'retours',label:'Retours de marchandise',icon:<Undo2 size={18}/>,href:'/business/dashboard/retours',group:'Commercial' },
  { id:'catalogue',label:'Catalogue',icon:<BookOpen size={18}/>,href:'/business/dashboard/catalogue',group:'Commercial' },
  { id:'prospecteurs',label:'Prospecteurs',icon:<UserCheck size={18}/>,href:'/business/dashboard/prospecteurs',group:'Équipe' },
  { id:'visites',label:'Visites terrain',icon:<MapPin size={18}/>,href:'/business/dashboard/visites',group:'Équipe' },
  { id:'suivi-prospecteurs',label:'Suivi prospecteurs',icon:<Users size={18}/>,href:'/business/dashboard/suivi-prospecteurs',group:'Équipe' },
  { id:'fournisseurs',label:'Fournisseurs',icon:<Truck size={18}/>,href:'/business/dashboard/fournisseurs',group:'Logistique' },
  { id:'achats',label:'Achats',icon:<ClipboardList size={18}/>,href:'/business/dashboard/achats',group:'Logistique' },
  { id:'stock',label:'Stock',icon:<Package size={18}/>,href:'/business/dashboard/stock',group:'Logistique' },
  { id:'entrepots',label:'Entrepôts & zones',icon:<Warehouse size={18}/>,href:'/business/dashboard/entrepots',group:'Logistique' },
  { id:'sous-branches',label:'Sous-branches entrepôt',icon:<Store size={18}/>,href:'/business/dashboard/sous-branches',group:'Logistique' },
  { id:'mouvements-stock',label:'Mouvements de stock',icon:<ArrowLeftRight size={18}/>,href:'/business/dashboard/mouvements-stock',group:'Logistique' },
  { id:'logistique',label:'Centre de contrôle logistique',icon:<Network size={18}/>,href:'/business/dashboard/logistique',group:'Logistique' },
  { id:'finances',label:'Finances & commissions',icon:<Wallet size={18}/>,href:'/business/dashboard/finances',group:'Analyse' },
  { id:'commissions',label:'Règles de commissions',icon:<Percent size={18}/>,href:'/business/dashboard/commissions',group:'Analyse' },
  { id:'rapports',label:'Rapports',icon:<FileText size={18}/>,href:'/business/dashboard/reports',group:'Analyse' },
  { id:'audit',label:'Journal d\'audit',icon:<ClipboardList size={18}/>,href:'/business/dashboard/audit',group:'Analyse' },
  { id:'guide',label:'Guide d\'utilisation',icon:<HelpCircle size={18}/>,href:'/guide-onboarding',group:'Système' },
  { id:'settings',label:'Paramètres',icon:<Settings size={18}/>,href:'/business/dashboard/settings',group:'Système' },
];

export default function BusinessDashboardLayout({ children }:{children:React.ReactNode}) {
  const [collapsed,setCollapsed]=useState(false); const [profileOpen,setProfileOpen]=useState(false); const pathname=usePathname(); const router=useRouter();
  const groups=Array.from(new Set(navItems.map(i=>i.group)));
  async function handleLogout(){await supabase.auth.signOut();router.replace('/business/login');}
  return <><IntelligencePresenceTracker/><div className="flex h-screen bg-[#0B1B3D] overflow-hidden">
    <aside className={`h-screen flex flex-col bg-[#08152f] border-r border-[#D4AF37]/10 transition-all duration-300 flex-shrink-0 ${collapsed?'w-16':'w-60'}`}>
      <div className={`h-16 flex items-center border-b border-[#D4AF37]/10 px-4 flex-shrink-0 ${collapsed?'justify-center':'justify-between'}`}>
        {!collapsed&&<div className="flex items-center gap-2"><AppLogo size={28}/><span className="font-bold text-base text-white">JDV <span className="text-[#D4AF37]">CRM</span></span></div>}
        {collapsed&&<AppLogo size={28}/>}
        {!collapsed&&<button onClick={()=>setCollapsed(true)} className="p-1.5 rounded-lg text-[#718096] hover:text-white hover:bg-[#0F2347] transition-all"><ChevronLeft size={16}/></button>}
      </div>
      <nav className="flex-1 overflow-y-auto py-3 px-2">{groups.map(group=><div key={group} className="mb-4">
        {!collapsed&&<p className="text-[10px] font-semibold uppercase tracking-widest text-[#718096] px-3 mb-2">{group}</p>}
        {navItems.filter(i=>i.group===group).map(item=>{const isActive=pathname===item.href||(item.href!=='/business/dashboard'&&pathname.startsWith(item.href));return <Link key={item.id} href={item.href} title={collapsed?item.label:undefined} className={`flex items-center gap-3 px-3 py-2.5 rounded-xl mb-0.5 text-sm font-medium transition-all ${isActive?'bg-[#D4AF37]/15 text-[#D4AF37] border border-[#D4AF37]/20':'text-[#A0AEC0] hover:text-white hover:bg-[#0F2347]'} ${collapsed?'justify-center':''}`}><span className="flex-shrink-0">{item.icon}</span>{!collapsed&&<span className="flex-1 truncate">{item.label}</span>}</Link>})}
      </div>)}</nav>
      <div className="border-t border-[#D4AF37]/10 p-2 flex-shrink-0"><div className={`flex ${collapsed?'flex-col gap-1 items-center':'gap-2'}`}>
        <button onClick={()=>setProfileOpen(true)} className={`flex items-center gap-2 px-3 py-2 rounded-xl text-[#A0AEC0] hover:text-white hover:bg-[#0F2347] transition-all text-sm ${collapsed?'justify-center w-full':'flex-1'}`} title="Mon profil"><User size={16}/>{!collapsed&&<span>Mon profil</span>}</button>
        <button onClick={handleLogout} className={`flex items-center gap-2 px-3 py-2 rounded-xl text-[#A0AEC0] hover:text-red-400 transition-all text-sm ${collapsed?'justify-center w-full':''}`} title="Déconnexion"><LogOut size={16}/>{!collapsed&&<span>Quitter</span>}</button>
      </div>{collapsed&&<button onClick={()=>setCollapsed(false)} className="w-full flex justify-center p-2 mt-1 text-[#718096] hover:text-white hover:bg-[#0F2347] rounded-xl transition-all"><ChevronRight size={14}/></button>}</div>
    </aside>
    <div className="flex-1 flex flex-col overflow-hidden"><ConcepteurBranchBar/><div className="h-16 flex items-center justify-between px-6 border-b border-[#D4AF37]/10 bg-[#08152f]/80 backdrop-blur-sm flex-shrink-0"><h1 className="text-base font-semibold text-white">Portail Entreprise</h1><div className="flex items-center gap-3"><NotificationBell/></div></div><main className="flex-1 overflow-y-auto">{children}</main></div>
    <Modal open={profileOpen} onClose={()=>setProfileOpen(false)} title="" size="sm"><UserProfilePanel onClose={()=>setProfileOpen(false)}/></Modal>
  </div></>;
}
