'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { usePathname, useRouter } from 'next/navigation';
import { LayoutDashboard, Package, Users, Headphones, Truck, Search, ClipboardCheck, LogOut, ArrowLeft } from 'lucide-react';
import AppLogo from '@/components/ui/AppLogo';
import { supabase } from '@/lib/supabase/client';
import { WarehouseProvider, useWarehouse } from '@/components/entrepot/WarehouseContext';

const NAV = [
  { href: '/entrepot/dashboard', label: 'Tableau de bord', icon: LayoutDashboard },
  { href: '/entrepot/dashboard/stock', label: 'Stock de l’entrepôt', icon: Package },
  { href: '/entrepot/dashboard/prospecteurs', label: 'Prospecteurs & retours', icon: Users },
  { href: '/entrepot/dashboard/appels', label: 'Appels & plaintes', icon: Headphones },
  { href: '/entrepot/dashboard/approvisionnement', label: 'Approvisionnement', icon: Truck },
  { href: '/entrepot/dashboard/tracabilite', label: 'Traçabilité', icon: Search },
  { href: '/entrepot/dashboard/fin-de-service', label: 'Fin de service', icon: ClipboardCheck },
];

function Shell({ children }: { children: React.ReactNode }) {
  const pathname = usePathname(); const router = useRouter();
  const { warehouses, current, setCurrentId, loading, error } = useWarehouse();
  const [checked, setChecked] = useState(false);
  useEffect(() => { supabase.auth.getUser().then(({ data }) => { if (!data.user) router.replace('/entrepot/login'); else setChecked(true); }); }, [router]);
  async function logout() { await supabase.auth.signOut(); router.replace('/entrepot/login'); }
  if (!checked || loading) return <div className="flex h-screen items-center justify-center bg-[#0B1B3D] text-slate-300 text-sm">Chargement de l&apos;espace entrepôt…</div>;
  if (error || !current) return <div className="flex h-screen flex-col items-center justify-center gap-4 bg-[#0B1B3D] p-6 text-center text-white"><p className="max-w-md">{error ? `Erreur : ${error}` : "Aucun entrepôt actif n'est rattaché à ce compte. Contactez votre administrateur."}</p><button onClick={logout} className="rounded-lg border border-white/10 px-4 py-2 text-sm">Se déconnecter</button></div>;
  const isAdmin = current.access_role === 'admin';
  return <div className="flex h-screen bg-[#0B1B3D] text-white overflow-hidden">
    <aside className="w-64 flex-shrink-0 flex flex-col bg-[#08152f] border-r border-[#D4AF37]/10">
      <div className="h-16 flex items-center gap-2 px-4 border-b border-[#D4AF37]/10"><AppLogo size={26} /><span className="font-bold text-sm">JDV <span className="text-[#D4AF37]">Entrepôt</span></span></div>
      <div className="p-3 border-b border-[#D4AF37]/10">{warehouses.length > 1 ? <select value={current.warehouse_id} onChange={(e)=>setCurrentId(e.target.value)} className="w-full rounded-lg bg-[#0F2347] border border-white/10 p-2 text-sm">{warehouses.map(w=><option key={w.warehouse_id} value={w.warehouse_id}>{w.name}{w.city ? ` - ${w.city}` : ''}</option>)}</select> : <div className="text-sm"><div className="font-semibold">{current.name}</div><div className="text-xs text-slate-400">{current.city ?? current.code}</div></div>}</div>
      <nav className="flex-1 overflow-y-auto p-2">{NAV.map(({href,label,icon:Icon})=>{const active=href==='/entrepot/dashboard'?pathname===href:pathname.startsWith(href);return <Link key={href} href={href} className={`flex items-center gap-3 px-3 py-2.5 rounded-xl mb-0.5 text-sm font-medium transition-all ${active?'bg-[#D4AF37]/15 text-[#D4AF37] border border-[#D4AF37]/20':'text-[#A0AEC0] hover:text-white hover:bg-[#0F2347]'}`}><Icon size={18}/>{label}</Link>})}</nav>
      <div className="border-t border-[#D4AF37]/10 p-2 space-y-1">{isAdmin&&<Link href="/business/dashboard/sous-branches" className="flex items-center gap-2 px-3 py-2 rounded-xl text-sm text-[#A0AEC0] hover:text-white hover:bg-[#0F2347]"><ArrowLeft size={16}/>Retour espace admin</Link>}<button onClick={logout} className="w-full flex items-center gap-2 px-3 py-2 rounded-xl text-sm text-[#A0AEC0] hover:text-red-400 hover:bg-[#0F2347]"><LogOut size={16}/>Quitter</button></div>
    </aside>
    <div className="flex-1 flex flex-col overflow-hidden"><div className="h-16 flex items-center justify-between px-6 border-b border-[#D4AF37]/10 bg-[#08152f]/80 flex-shrink-0"><h1 className="text-base font-semibold">{current.name}{current.city?<span className="text-slate-400 font-normal"> · {current.city}</span>:null}</h1><span className="text-xs text-slate-400">{isAdmin?'Accès administrateur':'Responsable d’entrepôt'}</span></div><main className="flex-1 overflow-y-auto">{children}</main></div>
  </div>;
}
export default function EntrepotDashboardLayout({children}:{children:React.ReactNode}){return <WarehouseProvider><Shell>{children}</Shell></WarehouseProvider>;}
