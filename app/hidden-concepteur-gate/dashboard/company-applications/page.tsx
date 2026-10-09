'use client';
import { useEffect, useState } from 'react';
import { Building2, CheckCircle2, XCircle, RefreshCw, FileSearch, MailCheck, Send } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';

type Row={application_id:string;company_name:string;legal_name:string|null;professional_email:string;company_nature:string;legal_form:string|null;legal_status:string|null;sector_name:string|null;country:string;city:string|null;company_size:string|null;status:string;analysis_status:string;analysis_score:number|null;created_at:string};

export default function CompanyApplicationsPage(){
 const [rows,setRows]=useState<Row[]>([]);const [loading,setLoading]=useState(true);const [message,setMessage]=useState('');const [busy,setBusy]=useState<string|null>(null);

 async function load(){
  setLoading(true);
  const {data,error}=await supabase.rpc('jdvcrm_get_pending_company_applications_v1');
  if(error)setMessage(error.message);
  setRows((data??[]) as Row[]);
  setLoading(false);
 }
 useEffect(()=>{load()},[]);

 async function sendApprovalEmail(id:string){
  setBusy(id);setMessage('');
  try{
   const {data:{session}}=await supabase.auth.getSession();
   if(!session?.access_token){setMessage('Session concepteur expirée.');return;}
   const res=await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/send-email`,{
    method:'POST',
    headers:{'Content-Type':'application/json',Authorization:`Bearer ${session.access_token}`,apikey:process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY??''},
    body:JSON.stringify({type:'company_approval',application_id:id})
   });
   const body=await res.json().catch(()=>({}));
   if(!res.ok)throw new Error(body.error??'Envoi du lien impossible.');
   setMessage('Entreprise validée : le lien de finalisation a été envoyé à son adresse email.');
  }catch(e){setMessage(e instanceof Error?e.message:'Envoi du lien impossible.');}
  finally{setBusy(null);}
 }

 async function decide(id:string,decision:'approve'|'request_changes'|'reject'){
  setBusy(id);setMessage('');
  try{
   const notes=decision==='approve'?'Dossier approuvé par le Concepteur.':decision==='reject'?'Dossier refusé après vérification.':'Correction demandée avant validation.';
   const {error}=await supabase.rpc('jdvcrm_platform_review_company_application_v1',{p_application_id:id,p_decision:decision,p_notes:notes});
   if(error)throw error;
   if(decision==='approve'){
    setMessage('Validation enregistrée. Envoi du lien de finalisation…');
    const {data:{session}}=await supabase.auth.getSession();
    if(!session?.access_token)throw new Error('Session concepteur expirée.');
    const res=await fetch(`${process.env.NEXT_PUBLIC_SUPABASE_URL}/functions/v1/send-email`,{
      method:'POST',
      headers:{'Content-Type':'application/json',Authorization:`Bearer ${session.access_token}`,apikey:process.env.NEXT_PUBLIC_SUPABASE_ANON_KEY??''},
      body:JSON.stringify({type:'company_approval',application_id:id})
    });
    const body=await res.json().catch(()=>({}));
    if(!res.ok)throw new Error(body.error??'Entreprise validée, mais l’email n’a pas pu être envoyé.');
    setMessage('Entreprise validée avec succès. Le lien de finalisation a été envoyé par email.');
   }else{
    setMessage(decision==='reject'?'Dossier refusé.':'Correction demandée.');
   }
  }catch(e){setMessage(e instanceof Error?e.message:'Une erreur est survenue.')}
  finally{setBusy(null);await load();}
 }

 return <div className="p-6 lg:p-8 space-y-7">
  <div className="flex items-center justify-between"><div><p className="text-xs text-[#D4AF37] uppercase tracking-widest">Concepteur</p><h1 className="text-2xl font-bold text-white mt-1">Dossiers de création d’entreprise</h1><p className="text-sm text-[#A0AEC0] mt-1">Analyse, validation et envoi du lien de finalisation.</p></div><button onClick={load} className="p-3 rounded-xl border border-[#D4AF37]/20 text-[#A0AEC0]"><RefreshCw size={17}/></button></div>
  {message&&<div className="p-3 rounded-xl bg-[#D4AF37]/10 border border-[#D4AF37]/20 text-[#D4AF37] text-sm">{message}</div>}
  <div className="bg-[#0F2347] border border-[#D4AF37]/15 rounded-2xl p-4 text-sm text-[#A0AEC0]"><FileSearch className="inline mr-2 text-[#D4AF37]" size={17}/>Après validation, JDV CRM génère un lien sécurisé et l’envoie au représentant de l’entreprise pour définir son mot de passe et activer son espace.</div>
  <div className="space-y-4">{loading?<div className="text-[#A0AEC0]">Chargement…</div>:rows.length===0?<div className="bg-[#0F2347] rounded-2xl p-10 text-center text-[#A0AEC0]">Aucun dossier en attente.</div>:rows.map(r=><div key={r.application_id} className="bg-[#0F2347] border border-[#D4AF37]/15 rounded-2xl p-6"><div className="flex flex-col lg:flex-row lg:items-start lg:justify-between gap-5"><div className="space-y-2"><div className="flex items-center gap-2"><Building2 size={18} className="text-[#D4AF37]"/><h2 className="font-bold text-white">{r.company_name}</h2></div><p className="text-sm text-[#A0AEC0]">{r.legal_name||'—'} · {r.legal_form||'forme non précisée'} · {r.sector_name||'secteur non précisé'}</p><p className="text-sm text-[#A0AEC0]">{r.professional_email} · {r.country}{r.city ? ' · '+r.city : ''}</p><div className="flex gap-2 flex-wrap"><span className="px-2 py-1 rounded-lg bg-[#D4AF37]/10 text-[#D4AF37] text-xs">{r.status}</span><span className="px-2 py-1 rounded-lg bg-blue-500/10 text-blue-300 text-xs">Analyse: {r.analysis_status}</span></div></div><div className="flex flex-wrap gap-2">
   {r.status==='approved_pending_email'?<button disabled={busy===r.application_id} onClick={()=>sendApprovalEmail(r.application_id)} className="px-4 py-2 rounded-xl bg-blue-500/15 text-blue-300 flex items-center gap-2 text-sm disabled:opacity-50"><Send size={16}/>{busy===r.application_id?'Envoi…':'Renvoyer le lien'}</button>:<button disabled={busy===r.application_id} onClick={()=>decide(r.application_id,'approve')} className="px-4 py-2 rounded-xl bg-green-500/15 text-green-300 flex items-center gap-2 text-sm disabled:opacity-50"><CheckCircle2 size={16}/>{busy===r.application_id?'Validation…':'Valider'}</button>}
   {r.status==='approved_pending_email'&&<span className="px-3 py-2 rounded-xl bg-green-500/10 text-green-300 flex items-center gap-2 text-sm"><MailCheck size={16}/>Validée</span>}
   {r.status!=='approved_pending_email'&&<><button disabled={busy===r.application_id} onClick={()=>decide(r.application_id,'request_changes')} className="px-4 py-2 rounded-xl bg-yellow-500/15 text-yellow-300 text-sm disabled:opacity-50">Demander correction</button><button disabled={busy===r.application_id} onClick={()=>decide(r.application_id,'reject')} className="px-4 py-2 rounded-xl bg-red-500/15 text-red-300 flex items-center gap-2 text-sm disabled:opacity-50"><XCircle size={16}/> Refuser</button></>}
  </div></div></div>)}</div>
 </div>;
}