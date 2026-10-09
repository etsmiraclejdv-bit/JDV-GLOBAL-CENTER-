'use client';
import React,{useEffect,useState} from 'react';
import {Package,Warehouse,ShoppingCart,Truck,Plus,Minus,RefreshCw,MapPin,AlertTriangle,RotateCcw} from 'lucide-react';
import {getMyProspecteurContext,getMyWarehouse,getWarehouseCatalog,getMyStock,getMyStockHoldings,getMySupplyRequests,getMySales,requestSupply,returnProspecteurStock} from '@/lib/services/prospecteurSupplyService';

const money=(v:number)=>new Intl.NumberFormat('fr-FR',{style:'currency',currency:'XOF',maximumFractionDigits:0}).format(Number(v)||0);

export default function ApprovisionnementPage(){
 const [ctx,setCtx]=useState<any>(); const [wh,setWh]=useState<any>(); const [catalog,setCatalog]=useState<any[]>([]);
 const [stock,setStock]=useState<any[]>([]); const [holdings,setHoldings]=useState<any[]>([]); const [requests,setRequests]=useState<any[]>([]); const [sales,setSales]=useState<any[]>([]);
 const [tab,setTab]=useState('catalogue'); const [selected,setSelected]=useState<Record<string,number>>({}); const [loading,setLoading]=useState(true); const [saving,setSaving]=useState(false); const [msg,setMsg]=useState('');

 async function load(){
  setLoading(true);
  const c=await getMyProspecteurContext();
  if(c.error){setMsg(c.error.message);setLoading(false);return;}
  setCtx(c.data);
  const a=await getMyWarehouse(c.data.id);
  if(a.error){setMsg(a.error.message);setLoading(false);return;}
  setWh(a.data);
  if(!a.data){setLoading(false);return;}
  const [ca,st,ho,re,sa]=await Promise.all([
   getWarehouseCatalog(c.data.organization_id,a.data.warehouse_id),
   getMyStock(c.data.id,c.data.organization_id),
   getMyStockHoldings(c.data.id,c.data.organization_id),
   getMySupplyRequests(c.data.id,c.data.organization_id),
   getMySales(c.data.organization_id,c.data.id)
  ]);
  setCatalog(ca.data||[]);setStock(st.data||[]);setHoldings(ho.data||[]);setRequests(re.data||[]);setSales(sa.data||[]);
  setLoading(false);
 }
 useEffect(()=>{load()},[]);

 const blocked=holdings.some(h=>Number(h.remaining_quantity)>0 && new Date(h.return_due_at).getTime()<=Date.now());
 const chosen=Object.entries(selected).filter(([,q])=>q>0).map(([article_id,quantity])=>({article_id,quantity}));
 const daysLeft=(date:string)=>Math.ceil((new Date(date).getTime()-Date.now())/86400000);

 async function submit(){
  if(blocked){setMsg('Approvisionnement bloqué : une marchandise doit être retournée à l’entrepôt.');setTab('stock');return;}
  if(!ctx||!wh||!chosen.length)return;
  setSaving(true);setMsg('');
  const r=await requestSupply(ctx.organization_id,ctx.id,wh.warehouse_id,chosen);
  setSaving(false);
  if(r.error){setMsg(r.error.message);return;}
  setSelected({});setMsg('Réapprovisionnement effectué depuis votre entrepôt affecté.');await load();setTab('demandes');
 }

 async function returnHolding(id:string){
  setSaving(true);setMsg('');
  const r=await returnProspecteurStock(id);
  setSaving(false);
  if(r.error){setMsg(r.error.message);return;}
  setMsg('Retour enregistré : la quantité non vendue a été réintégrée dans le stock de l’entrepôt. Aucune commission n’est créée.');
  await load();
 }

 return <div className="p-5 lg:p-8 space-y-6">
  <div className="flex justify-between">
   <div><p className="text-xs uppercase tracking-widest text-[#D4AF37]">Terrain</p><h1 className="text-2xl font-bold text-white">Mon approvisionnement</h1><p className="text-sm text-[#A0AEC0]">Entrepôt, stock personnel, délais de retour et historique des ventes.</p></div>
   <button onClick={load} className="p-2.5 rounded-xl bg-[#0F2347] text-[#A0AEC0]"><RefreshCw size={17}/></button>
  </div>
  {msg&&<div className="p-3 rounded-xl bg-amber-500/10 border border-amber-500/30 text-amber-300 text-sm">{msg}</div>}
  {loading?<div className="p-10 text-center text-[#A0AEC0]">Chargement…</div>:!wh?
   <div className="p-6 bg-[#0F2347] rounded-2xl border border-amber-500/30"><AlertTriangle className="text-amber-400"/><h2 className="text-white font-semibold mt-2">Aucun entrepôt affecté</h2><p className="text-sm text-[#A0AEC0]">L’administrateur doit affecter ce prospecteur à un entrepôt.</p></div>
  :<>
   <div className="p-5 bg-[#0F2347] rounded-2xl border border-[#D4AF37]/20"><div className="flex gap-3"><Warehouse className="text-[#D4AF37]"/><div><p className="text-xs text-[#718096]">Mon entrepôt</p><h2 className="text-lg font-bold text-white">{wh.warehouses?.name}</h2><p className="text-sm text-[#A0AEC0]">{wh.warehouses?.code} · {wh.department||'Département non renseigné'} · {wh.warehouses?.city||wh.city||'Ville non renseignée'}</p>{wh.warehouses?.address&&<p className="text-xs text-[#718096] mt-2"><MapPin size={12} className="inline"/> {wh.warehouses.address}</p>}</div></div></div>
   {blocked&&<div className="p-4 rounded-xl bg-red-500/10 border border-red-500/40 text-red-200 text-sm"><b>Approvisionnement bloqué.</b> Une marchandise a dépassé le délai de retour de 10 jours. Retournez-la avant toute nouvelle demande.</div>}
   <div className="grid grid-cols-4 gap-2">{[['catalogue','Catalogue',Package,catalog.length],['stock','Mon stock',Warehouse,stock.reduce((n,x)=>n+Number(x.quantity||0),0)],['ventes','Vendus',ShoppingCart,sales.reduce((n,x)=>n+Number(x.quantity||0),0)],['demandes','Historique',Truck,requests.length]].map((x:any)=>{const Icon=x[2];return <button key={x[0]} onClick={()=>setTab(x[0])} className={'p-3 rounded-xl border text-left '+(tab===x[0]?'bg-[#D4AF37]/10 border-[#D4AF37]/40':'bg-[#0F2347] border-[#D4AF37]/15')}><Icon size={16} className="text-[#D4AF37]"/><p className="text-xs text-[#A0AEC0] mt-2">{x[1]}</p><p className="text-lg font-bold text-white">{x[3]}</p></button>})}</div>
   {tab==='catalogue'&&<section><div className="flex justify-between items-center mb-3"><h2 className="font-semibold text-white">Articles disponibles</h2><button disabled={!chosen.length||saving||blocked} onClick={submit} className="btn-gold px-4 py-2 rounded-xl text-sm disabled:opacity-50">{blocked?'Retour obligatoire':`Réapprovisionner (${chosen.length})`}</button></div><div className="grid md:grid-cols-2 xl:grid-cols-3 gap-3">{catalog.length===0?<Empty text="Aucun article disponible dans cet entrepôt."/>:catalog.map((r:any)=>{const a=r.articles;const available=Math.max(0,Number(r.quantity||0)-Number(r.reserved_quantity||0));const q=selected[a.id]||0;return <div key={a.id} className="p-4 bg-[#0F2347] rounded-2xl border border-[#D4AF37]/15"><p className="font-semibold text-white">{a.name}</p><p className="text-xs text-[#718096]">{a.code} · {available} disponibles</p><div className="grid grid-cols-2 gap-2 mt-3 text-xs"><span className="text-[#A0AEC0]">Comptant<br/><b className="text-white">{money(a.cash_price||a.fixed_price)}</b></span><span className="text-[#A0AEC0]">Crédit<br/><b className="text-white">{money(a.credit_price||a.fixed_price)}</b></span></div><div className="flex justify-between items-center mt-4"><span className="text-xs text-[#A0AEC0]">À prendre</span><div className="flex gap-2 items-center"><button disabled={!q} onClick={()=>setSelected(s=>({...s,[a.id]:Math.max(0,q-1)}))} className="p-1.5 bg-[#08152f] text-white rounded-lg disabled:opacity-30"><Minus size={14}/></button><b className="text-white w-5 text-center">{q}</b><button disabled={q>=available||blocked} onClick={()=>setSelected(s=>({...s,[a.id]:q+1}))} className="p-1.5 bg-[#08152f] text-white rounded-lg disabled:opacity-30"><Plus size={14}/></button></div></div></div>})}</div></section>}
   {tab==='stock'&&<section><div className="flex justify-between items-center mb-3"><h2 className="font-semibold text-white">Mon stock personnel</h2>{blocked&&<span className="text-xs text-red-300">Approvisionnement bloqué</span>}</div><div className="space-y-2">{stock.length?stock.map((r:any)=><div key={r.article_id} className="p-4 bg-[#0F2347] rounded-xl flex justify-between"><div><b className="text-white">{r.articles?.name}</b><p className="text-xs text-[#718096]">{r.articles?.code}</p></div><b className="text-xl text-[#D4AF37]">{r.quantity}</b></div>):<Empty text="Votre stock est vide."/>}</div><h3 className="font-semibold text-white mt-6 mb-3">Marchandises affectées et délais de retour</h3><div className="space-y-3">{holdings.length?holdings.map((h:any)=>{const left=daysLeft(h.return_due_at);const hard=daysLeft(h.hard_due_at);const overdue=left<=0;return <div key={h.id} className={'p-4 bg-[#0F2347] rounded-xl border '+(overdue?'border-red-500/50':'border-[#D4AF37]/15')}><div className="flex justify-between gap-3"><div><b className="text-white">{h.articles?.name}</b><p className="text-xs text-[#718096]">{h.articles?.code} · Quantité restante : {h.remaining_quantity}</p><p className={'text-xs mt-1 '+(overdue?'text-red-300':'text-amber-300')}>{overdue?'Retour obligatoire depuis '+Math.abs(left)+' jour(s)':`Retour dans ${left} jour(s)`} · limite absolue J+20 (${hard} jours)</p></div><button onClick={()=>returnHolding(h.id)} disabled={saving} className="px-3 py-2 rounded-lg bg-amber-500/10 text-amber-300 text-xs disabled:opacity-50"><RotateCcw size={14} className="inline mr-1"/>Retourner</button></div></div>}) : <Empty text="Aucune marchandise affectée à retourner."/>}</div></section>}
   {tab==='ventes'&&<section><h2 className="font-semibold text-white mb-3">Articles vendus et clients</h2><div className="space-y-2">{sales.length?sales.map((s:any)=><div key={s.id} className="p-4 bg-[#0F2347] rounded-xl flex justify-between"><div><b className="text-white">{s.article?.name}</b><p className="text-xs text-[#A0AEC0]">{s.client?.first_name} {s.client?.last_name} · {s.client?.phone||'Sans téléphone'}</p><p className="text-xs text-[#718096]">{s.sale_number} · {s.sale_type==='credit'?'À crédit':'Comptant'} · {new Date(s.sale_date).toLocaleDateString('fr-FR')}</p></div><b className="text-white">× {s.quantity}</b></div>):<Empty text="Aucune vente enregistrée."/>}</div></section>}
   {tab==='demandes'&&<section><h2 className="font-semibold text-white mb-3">Historique des approvisionnements</h2><div className="space-y-2">{requests.length?requests.map((r:any)=><div key={r.id} className="p-4 bg-[#0F2347] rounded-xl flex justify-between"><div><b className="text-white">{r.prospecteur_supply_request_items?.map((i:any)=>i.articles?.name+' × '+i.quantity).join(' · ')}</b><p className="text-xs text-[#718096]">{new Date(r.requested_at).toLocaleString('fr-FR')}</p></div><span className="text-xs text-amber-300">{r.status==='approved'?'Approuvée':r.status==='rejected'?'Refusée':'En attente'}</span></div>):<Empty text="Aucun approvisionnement."/>}</div></section>}
  </>}
 </div>
}
function Empty({text}:{text:string}){return <div className="col-span-full p-8 text-center bg-[#0F2347] rounded-2xl border border-[#D4AF37]/10 text-sm text-[#718096]">{text}</div>}
