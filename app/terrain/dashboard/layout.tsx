'use client';
import React, { useState } from 'react';
import { LayoutDashboard, ShoppingCart, Users, UserCheck, Wallet, User, LogOut, ChevronLeft, ChevronRight, HelpCircle, AlertTriangle, Warehouse, MapPin } from 'lucide-react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import AppLogo from '@/components/ui/AppLogo';
import NotificationBell from '@/components/NotificationBell';
import UserProfilePanel from '@/components/UserProfilePanel';
import Modal from '@/components/ui/Modal';
import { supabase } from '@/lib/supabase/client';
import IntelligencePresenceTracker from '@/components/IntelligencePresenceTracker';
import ConcepteurBranchBar from '@/components/ConcepteurBranchBar';

const navItems = [
  {id:'dashboard',label:'Mon tableau de bord',icon:<LayoutDashboard size={18}/>,href:'/terrain/dashboard',group:'Principal'},
  {id:'intelligence',label:'Mon assistant IA',icon:<AlertTriangle size={18}/>,href:'/terrain/dashboard/intelligence',group:'Principal'},
  {id:'approvisionnement',label:'Mon approvisionnement',icon:<Warehouse size={18}/>,href:'/terrain/dashboard/approvisionnement',group:'Stock'},
  {id:'ventes',label:'Mes ventes',icon:<ShoppingCart size={18}/>,href:'/terrain/dashboard/ventes',group:'Activité'},
  {id:'prospects',label:'Mes prospects',icon:<Users size={18}/>,href:'/terrain/dashboard/prospects',group:'Activité'},
  {id:'clients',label:'Mes clients',icon:<UserCheck size={18}/>,href:'/terrain/dashboard/clients',group:'Activité'},
  {id:'visites',label:'Mes visites',icon:<MapPin size={18}/>,href:'/terrain/dashboard/visites',group:'Activité'},
  {id:'relances',label:'Mes relances',icon:<AlertTriangle size={18}/>,href:'/terrain/dashboard/relances',group:'Activité'},
  {id:'commission',label:'Ma commission',icon:<Wallet size={18}/>,href:'/terrain/dashboard/commission',group:'Activité'},
  {id:'guide',label:'Guide d\'utilisation',icon:<HelpCircle size={18}/>,href:'/guide-onboarding',group:'Aide'},
];
export default function TerrainDashboardLayout({children}:{children:React.ReactNode}){
  const [collapsed,setCollapsed]=useState(false);const [profileOpen,setProfileOpen]=useState(false);const pathname=usePathname();const router=useRouter();const groups=Array.from(new Set(navItems.map(i=>i.group)));
  async function handleLogout(){await supabase.auth.signOut();router.replace('/terrain/login');}
  return <><IntelligencePresenceTracker/><div className="flex h-screen bg-[#0B1B3D] overflow-hidden">
    <aside className={`h-screen flex flex-col bg-[#08152f] border-r border-[#D4AF37]/10 transition-all duration-300 flex-shrink-0 ${collapsed?'w-16':'w-56'}`}>
      <div className={`h-16 flex items-center border-b border-[#D4AF37]/10 px-4 flex-shrink-0 ${collapsed?'justify-center':'justify-between'}`}>{!collapsed&&<div className="flex items-center gap-2"><AppLogo size={26}/><span className="font-bold text-sm text-white">JDV <span className="text-[#D4AF37]">Terrain</span></span></div>}{collapsed&&<AppLogo size={26}/>} {!collapsed&&<button onClick={()=>setCollapsed(true)} className="p-1.5 rounded-lg text-[#718096] hover:text-white hover:bg-[#0F2347] transition-all"><ChevronLeft size={16}/></button>}</div>
      <nav className="flex-1 overflow-y-auto py-3 px-2">{groups.map(group=><div key={group} className="mb-4">{!collapsed&&<p className="text-[10px] font-semibold uppercase tracking-widest text-[#718096] px-3 mb-2">{group}</p>}{navItems.filter(i=>i.group===group).map(item=>{const isActive=pathname===item.href||(item.href!=='/terrain/dashboard'&&pathname.startsWith(item.href));return <Link key={item.id} href={item.href} title={collapsed?item.label:undefined} className={`flex items-center gap-3 px-3 py-2.5 rounded-xl mb-0.5 text-sm font-medium transition-all ${isActive?'bg-[#D4AF37]/15 text-[#D4AF37] border border-[#D4AF37]/20':'text-[#A0AEC0] hover:text-white hover:bg-[#0F2347]'} ${collapsed?'justify-center':''}`}><span className="flex-shrink-0">{item.icon}</span>{!collapsed&&<span className="flex-1 truncate">{item.label}</span>}</Link>})}</div>)}</nav>
      <div className="border-t border-[#D4AF37]/10 p-2 flex-shrink-0"><div className={`flex ${collapsed?'flex-col gap-1 items-center':'gap-2'}`}><button onClick={()=>setProfileOpen(true)} className={`flex items-center gap-2 px-3 py-2 rounded-xl text-[#A0AEC0] hover:text-white hover:bg-[#0F2347] transition-all text-sm ${collapsed?'justify-center w-full':'flex-1'}`} title="Mon profil"><User size={16}/>{!collapsed&&<span>Mon profil</span>}</button><button onClick={handleLogout} className={`flex items-center gap-2 px-3 py-2 rounded-xl text-[#A0AEC0] hover:text-red-400 transition-all text-sm ${collapsed?'justify-center w-full':''}`} title="Déconnexion"><LogOut size={16}/>{!collapsed&&<span>Quitter</span>}</button></div>{collapsed&&<button onClick={()=>setCollapsed(false)} className="w-full flex justify-center p-2 mt-1 text-[#718096] hover:text-white hover:bg-[#0F2347] rounded-xl transition-all"><ChevronRight size={14}/></button>}</div>
    </aside>
    <div className="flex-1 flex flex-col overflow-hidden"><ConcepteurBranchBar/><div className="h-16 flex items-center justify-between px-6 border-b border-[#D4AF37]/10 bg-[#08152f]/80 backdrop-blur-sm flex-shrink-0"><h1 className="text-base font-semibold text-white">Portail Terrain</h1><div className="flex items-center gap-3"><NotificationBell/></div></div><main className="flex-1 overflow-y-auto">{children}</main></div>
    <Modal open={profileOpen} onClose={()=>setProfileOpen(false)} title="" size="sm"><UserProfilePanel onClose={()=>setProfileOpen(false)}/></Modal>
  </div></>;
}