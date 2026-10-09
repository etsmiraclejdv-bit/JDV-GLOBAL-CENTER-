'use client';

import { useCallback,useEffect,useState } from 'react';
import { supabase } from '@/lib/supabase/client';
import { useWarehouse } from '@/components/entrepot/WarehouseContext';
import { Card,PageTitle,num } from '@/components/entrepot/common';

type Summary={opening_units:number;total_entries:number;total_exits:number;closing_units:number;theoretical_value:number;movement_count:number};
type StockRow={article_id:string;article_code:string;article_name:string;quantity:number};
type Sub={id:string;name:string;code:string};
type Closure={id:string;exercise_date:string;status:string;opening_units:number;total_entries:number;total_exits:number;closing_units:number;theoretical_value:number;physical_value:number|null;variance_units:number|null;variance_value:number|null;movement_count:number};

export default function ClotureStockPage(){
 const {current}=useWarehouse(); const [subs,setSubs]=useState<Sub[]>([]); const [subId,setSubId]=useState('');
 const [date,setDate]=useState(new Date().toISOString().slice(0,10)); const [summary,setSummary]=useState<Summary|null>(null);
 const [closures,setClosures]=useState<Closure[]>([]); const [stock,setStock]=useState<StockRow[]>([]); const [physical,setPhysical]=useState<Record<string,string>>({});
 const [error,setError]=useState(''); const [success,setSuccess]=useState(''); const [loading,setLoading]=useState(true); const [closing,setClosing]=useState(false);

 const load=useCallback(async()=>{if(!current||!subId){setLoading(false);return;}setLoading(true);setError('');
  const [sumRes,clRes,stockRes]=await Promise.all([
   supabase.rpc('jdvcrm_subwarehouse_daily_summary_v1',{p_subwarehouse_id:subId,p_exercise_date:date}),
   supabase.from('warehouse_subwarehouse_daily_closures').select('id,exercise_date,status,opening_units,total_entries,total_exits,closing_units,theoretical_value,physical_value,variance_units,variance_value,movement_count').eq('subwarehouse_id',subId).order('exercise_date',{ascending:false}).limit(30),
   supabase.from('warehouse_inventory').select('article_id,quantity,articles(code,name)').eq('subwarehouse_id',subId).order('article_id')
  ]);
  if(sumRes.error)setError(sumRes.error.message);else setSummary((sumRes.data?.[0]??null) as Summary|null);
  if(clRes.error)setError(clRes.error.message);else setClosures((clRes.data??[]) as Closure[]);
  if(stockRes.error)setError(stockRes.error.message);else setStock(((stockRes.data??[]) as any[]).map(x=>({article_id:x.article_id,quantity:Number(x.quantity||0),article_code:x.articles?.code||'—',article_name:x.articles?.name||'Article'})));
  setLoading(false);
 },[current,subId,date]);
 useEffect(()=>{if(!current)return;supabase.from('warehouse_subwarehouses').select('id,name,code').eq('parent_warehouse_id',current.warehouse_id).eq('active',true).order('name').then(({data,error})=>{if(error)setError(error.message);else{const list=(data??[]) as Sub[];setSubs(list);if(!subId&&list[0])setSubId(list[0].id);}});},[current,subId]);
 useEffect(()=>{void load();},[load]);

 async function closeDay(){if(!subId||!summary)return;setClosing(true);setError('');setSuccess('');
  const counts=Object.entries(physical).filter(([,v])=>v!=='').map(([article_id,v])=>({article_id,physical_quantity:Number(v)}));
  const result=await supabase.rpc('jdvcrm_subwarehouse_close_day_v1',{p_subwarehouse_id:subId,p_exercise_date:date,p_physical_counts:counts,p_notes:'Clôture journalière depuis le module sous-entrepôt'});
  if(result.error)setError(result.error.message);else setSuccess('Journée du sous-entrepôt clôturée et calculs enregistrés.');
  setClosing(false);await load();
 }

 const selected=subs.find(s=>s.id===subId);
 return <div className="p-6 space-y-6 text-white">
  <PageTitle title="Clôture journalière du stock" subtitle="Inventaire, calcul automatique et clôture indépendante de chaque sous-entrepôt.">
   <div className="flex flex-wrap gap-2"><select value={subId} onChange={e=>{setSubId(e.target.value);setPhysical({});}} className="rounded-lg border border-white/10 bg-[#08152f] px-3 py-2 text-sm"><option value="">Choisir un sous-entrepôt</option>{subs.map(s=><option key={s.id} value={s.id}>{s.code} — {s.name}</option>)}</select><input type="date" value={date} onChange={e=>setDate(e.target.value)} className="rounded-lg border border-white/10 bg-[#08152f] px-3 py-2 text-sm"/></div>
  </PageTitle>
  {!subId&&<Card><p className="text-slate-400">Créez ou sélectionnez un sous-entrepôt pour lancer son inventaire et sa clôture.</p></Card>}
  {error&&<div className="rounded-xl border border-red-400/30 bg-red-950/30 p-4 text-red-200">{error}</div>}
  {success&&<div className="rounded-xl border border-emerald-400/30 bg-emerald-950/30 p-4 text-emerald-200">{success}</div>}
  {subId&&<><Card><p className="text-xs uppercase text-[#D4AF37]">Sous-entrepôt sélectionné</p><p className="text-xl font-bold">{selected?.code} — {selected?.name}</p></Card>
  <div className="grid gap-4 md:grid-cols-3 xl:grid-cols-6"><Card><p className="text-xs text-slate-500">Début</p><p className="text-xl font-bold">{num(summary?.opening_units??0)}</p></Card><Card><p className="text-xs text-slate-500">Entrées</p><p className="text-xl font-bold text-emerald-400">+{num(summary?.total_entries??0)}</p></Card><Card><p className="text-xs text-slate-500">Sorties</p><p className="text-xl font-bold text-red-400">-{num(summary?.total_exits??0)}</p></Card><Card><p className="text-xs text-slate-500">Stock final</p><p className="text-xl font-bold">{num(summary?.closing_units??0)}</p></Card><Card><p className="text-xs text-slate-500">Valeur</p><p className="text-xl font-bold">{num(summary?.theoretical_value??0)} FCFA</p></Card><Card><p className="text-xs text-slate-500">Mouvements</p><p className="text-xl font-bold">{num(summary?.movement_count??0)}</p></Card></div>
  <Card><h2 className="text-xl font-semibold">Inventaire physique</h2><p className="mt-1 text-sm text-slate-400">Comptage physique du sous-entrepôt. L'écart est calculé automatiquement.</p><div className="mt-4 overflow-x-auto"><table className="w-full min-w-[700px] text-sm"><thead><tr className="border-b border-white/10 text-left text-slate-400"><th className="p-2">Code</th><th className="p-2">Article</th><th className="p-2 text-right">Théorique</th><th className="p-2 text-right">Physique</th><th className="p-2 text-right">Écart</th></tr></thead><tbody>{stock.map(item=>{const value=physical[item.article_id]??'';const variance=value===''?null:Number(value)-Number(item.quantity);return <tr key={item.article_id} className="border-b border-white/5"><td className="p-2 font-mono text-[#D4AF37]">{item.article_code}</td><td className="p-2">{item.article_name}</td><td className="p-2 text-right">{num(item.quantity)}</td><td className="p-2 text-right"><input type="number" min="0" step="1" value={value} onChange={e=>setPhysical(old=>({...old,[item.article_id]:e.target.value}))} className="w-28 rounded-lg border border-white/10 bg-[#08152f] px-2 py-2 text-right"/></td><td className={variance===null?'p-2 text-right text-slate-500':variance===0?'p-2 text-right text-emerald-400':'p-2 text-right text-amber-400'}>{variance===null?'—':num(variance)}</td></tr>})}</tbody></table></div></Card>
  <Card><div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between"><div><h2 className="text-xl font-semibold">Contrôle de la journée</h2><p className="text-sm text-slate-400">Après clôture, toute correction doit passer par un mouvement d'ajustement contrôlé.</p></div><button disabled={loading||closing||!summary} onClick={()=>void closeDay()} className="rounded-xl bg-[#D4AF37] px-5 py-3 font-semibold text-[#07142c] disabled:opacity-50">{closing?'Clôture…':'Clôturer le sous-entrepôt'}</button></div></Card>
  <Card><h2 className="text-xl font-semibold">Historique des clôtures</h2><div className="mt-4 overflow-x-auto"><table className="w-full min-w-[900px] text-sm"><thead><tr className="border-b border-white/10 text-left text-slate-400"><th className="p-2">Date</th><th className="p-2">Statut</th><th className="p-2 text-right">Début</th><th className="p-2 text-right">Entrées</th><th className="p-2 text-right">Sorties</th><th className="p-2 text-right">Final</th><th className="p-2 text-right">Écart</th><th className="p-2 text-right">Valeur</th></tr></thead><tbody>{closures.map(c=><tr key={c.id} className="border-b border-white/5"><td className="p-2">{c.exercise_date}</td><td className="p-2 text-emerald-400">{c.status==='closed'?'Clôturée':c.status}</td><td className="p-2 text-right">{num(c.opening_units)}</td><td className="p-2 text-right text-emerald-400">+{num(c.total_entries)}</td><td className="p-2 text-right text-red-400">-{num(c.total_exits)}</td><td className="p-2 text-right font-semibold">{num(c.closing_units)}</td><td className="p-2 text-right">{c.variance_units==null?'—':num(c.variance_units)}</td><td className="p-2 text-right">{num(c.theoretical_value)} FCFA</td></tr>)}</tbody></table></div></Card></>}
 </div>;
}