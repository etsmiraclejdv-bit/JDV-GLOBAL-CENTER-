'use client';

import { useEffect, useState } from 'react';
import { Building2, Users, CreditCard, AlertTriangle, CheckCircle2, RefreshCw, ArrowRight } from 'lucide-react';
import Link from 'next/link';
import { supabase } from '@/lib/supabase/client';

type Row={organization_id:string;organization_name:string;organization_status:string;subscription_status:string;plan_name:string|null;expires_at:string|null;days_remaining:number|null;last_payment_status:string|null;auto_renew:boolean};

export default function SuperAdminDashboardPage(){
 const [rows,setRows]=useState<Row[]>([]);const [loading,setLoading]=useState(true);
 async function load(){setLoading(true);const {data}=await supabase.rpc('jdvcrm_get_platform_companies_v1');setRows((data??[]) as Row[]);setLoading(false)}
 useEffect(()=>{load()},[]);
 const active=rows.filter(r=>['active','trial'].includes(r.subscription_status)).length;
 const unpaid=rows.filter(r=>['past_due','expired','cancelled'].includes(r.subscription_status)||r.last_payment_status==='failed').length;
 const suspended=rows.filter(r=>r.organization_status==='suspended').length;
 const auto=rows.filter(r=>r.auto_renew).length;
 return <div className="p-6 lg:p-8 space-y-8">
  <div className="flex items-center justify-between"><div><h1 className="text-2xl font-bold text-white">Gestion de la plateforme</h1><p className="text-sm text-[#A0AEC0] mt-1">Contrôle global des entreprises et des abonnements JDV CRM.</p></div><button onClick={load} className="p-2 rounded-xl border border-[#D4AF37]/20 text-[#A0AEC0] hover:text-white"><RefreshCw size={16}/></button></div>
  <div className="grid grid-cols-2 lg:grid-cols-4 gap-4">
   {[['Entreprises',rows.length,Building2,'text-[#D4AF37]'],['Abonnements actifs',active,CreditCard,'text-green-400'],['Impayées / expirées',unpaid,AlertTriangle,'text-red-400'],['Renouvellement auto',auto,CheckCircle2,'text-blue-400']].map(([l,v,I,c])=>{const Icon=I as typeof Building2;return <div key={l as string} className="bg-[#0F2347] border border-[#D4AF37]/15 rounded-2xl p-5"><Icon size={20} className={c as string}/><p className="text-2xl font-bold text-white mt-3">{loading?'—':v as number}</p><p className="text-xs text-[#718096] mt-1">{l as string}</p></div>})}
  </div>
  <div className="bg-[#0F2347] border border-[#D4AF37]/15 rounded-2xl p-6">
   <div className="flex items-center justify-between mb-5"><div><h2 className="text-base font-semibold text-white">État des entreprises</h2><p className="text-xs text-[#718096] mt-1">Les échéances expirées sont automatiquement marquées comme expirées/suspendues lors du contrôle.</p></div><Link href="/hidden-concepteur-gate/dashboard/company-applications" className="flex items-center gap-1 text-xs text-[#D4AF37]">Dossiers entreprises <ArrowRight size={13}/></Link></div>
   {suspended>0&&<div className="mb-4 p-3 rounded-xl bg-red-500/10 border border-red-500/20 text-sm text-red-300">{suspended} entreprise(s) actuellement suspendue(s).</div>}
   <div className="overflow-x-auto"><table className="w-full"><thead><tr className="border-b border-[#D4AF37]/10">{['Entreprise','Abonnement','Échéance','Paiement','État'].map(h=><th key={h} className="text-left text-xs text-[#718096] uppercase px-4 py-3">{h}</th>)}</tr></thead><tbody className="divide-y divide-[#D4AF37]/5">{rows.slice(0,10).map(r=><tr key={r.organization_id}><td className="px-4 py-3 text-sm text-white">{r.organization_name}</td><td className="px-4 py-3 text-sm text-[#A0AEC0]">{r.plan_name||'—'}</td><td className="px-4 py-3 text-sm text-[#A0AEC0]">{r.expires_at?new Date(r.expires_at).toLocaleDateString('fr-FR'):'—'}</td><td className="px-4 py-3 text-sm text-[#A0AEC0]">{r.last_payment_status||'Aucun'}</td><td className="px-4 py-3"><span className={(r.organization_status==='suspended'||r.subscription_status==='expired')?'text-red-400':'text-green-400'}>{r.organization_status==='suspended'||r.subscription_status==='expired'?'Suspendue':'Active'}</span></td></tr>)}</tbody></table></div>
  </div>
 </div>
}
