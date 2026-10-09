'use client';

import React, { useEffect, useState } from 'react';
import { Package, Warehouse, Plus, Truck, RefreshCw } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchOrgProfile } from '@/lib/auth/context';
import { toast } from 'sonner';

type Article = { id:string; name:string; code:string; cash_price:number|null };
type Wh = { id:string; name:string; code:string; city:string|null };
type Central = { article_id:string; quantity:number; reserved_quantity:number; minimum_quantity:number };
type Inventory = { id:string; warehouse_id:string; article_id:string; quantity:number; reserved_quantity:number; minimum_quantity:number; warehouses?:{name:string;code:string}; articles?:{name:string;code:string} };

const input='w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm';
const label='block text-xs text-[#A0AEC0] mb-1.5';

export default function BusinessStockPage(){
  const [orgId,setOrgId]=useState<string|null>(null);
  const [articles,setArticles]=useState<Article[]>([]);
  const [warehouses,setWarehouses]=useState<Wh[]>([]);
  const [central,setCentral]=useState<Central[]>([]);
  const [inventory,setInventory]=useState<Inventory[]>([]);
  const [loading,setLoading]=useState(true);
  const [entry,setEntry]=useState({article_id:'',quantity:1,minimum_quantity:0,notes:''});
  const [supply,setSupply]=useState({article_id:'',warehouse_id:'',quantity:1,minimum_quantity:0,notes:''});
  const [saving,setSaving]=useState(false);

  async function load(oid?:string){
    const id=oid||orgId;
    if(!id)return;
    setLoading(true);
    const [a,w,c,i]=await Promise.all([
      supabase.from('articles').select('id,name,code,cash_price').eq('organization_id',id).eq('active',true).order('name'),
      supabase.from('warehouses').select('id,name,code,city').eq('organization_id',id).eq('active',true).order('name'),
      supabase.from('stocks').select('article_id,quantity,reserved_quantity,minimum_quantity').eq('organization_id',id),
      supabase.from('warehouse_inventory').select('id,warehouse_id,article_id,quantity,reserved_quantity,minimum_quantity,warehouses(name,code),articles(name,code)').eq('organization_id',id).order('updated_at',{ascending:false}),
    ]);
    const err=[a,w,c,i].find(x=>x.error)?.error;
    if(err)toast.error(err.message);
    setArticles((a.data??[]) as Article[]);
    setWarehouses((w.data??[]) as Wh[]);
    setCentral((c.data??[]) as Central[]);
    setInventory((i.data??[]) as Inventory[]);
    setLoading(false);
  }

  useEffect(()=>{(async()=>{const {data}=await fetchOrgProfile(); if(data?.organization_id){setOrgId(data.organization_id);await load(data.organization_id);}})()},[]);

  async function centralEntry(e:React.FormEvent){
    e.preventDefault(); if(!orgId||!entry.article_id||entry.quantity<=0)return;
    setSaving(true);
    const {error}=await supabase.rpc('jdvcrm_admin_stock_entry_v1',{p_organization_id:orgId,p_article_id:entry.article_id,p_quantity:entry.quantity,p_minimum_quantity:entry.minimum_quantity,p_notes:entry.notes||null});
    if(error)toast.error(error.message); else {toast.success('Entrée stock central enregistrée');setEntry({article_id:'',quantity:1,minimum_quantity:0,notes:''});await load();}
    setSaving(false);
  }

  async function warehouseSupply(e:React.FormEvent){
    e.preventDefault(); if(!orgId||!supply.article_id||!supply.warehouse_id||supply.quantity<=0)return;
    setSaving(true);
    const {error}=await supabase.rpc('jdvcrm_admin_supply_warehouse_v1',{p_organization_id:orgId,p_warehouse_id:supply.warehouse_id,p_article_id:supply.article_id,p_quantity:supply.quantity,p_minimum_quantity:supply.minimum_quantity,p_notes:supply.notes||null});
    if(error)toast.error(error.message); else {toast.success('Entrepôt approvisionné depuis le stock central');setSupply({article_id:'',warehouse_id:'',quantity:1,minimum_quantity:0,notes:''});await load();}
    setSaving(false);
  }

  const centralMap=new Map(central.map(x=>[x.article_id,x]));
  return <div className="p-6 lg:p-8 space-y-6">
    <div className="flex flex-wrap items-center justify-between gap-3">
      <div><h1 className="text-2xl font-bold text-white">Stock & approvisionnement</h1><p className="text-sm text-[#A0AEC0] mt-1">Flux unique : Stock central → Entrepôt → Prospecteur.</p></div>
      <button onClick={()=>load()} className="flex items-center gap-2 px-4 py-2 rounded-xl border border-[#D4AF37]/20 text-[#A0AEC0]"><RefreshCw size={14}/>Actualiser</button>
    </div>

    <div className="grid lg:grid-cols-2 gap-5">
      <form onSubmit={centralEntry} className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5 space-y-3">
        <div className="flex items-center gap-2"><Plus size={18} className="text-[#D4AF37]"/><h2 className="font-semibold text-white">Entrée stock central</h2></div>
        <p className="text-xs text-[#718096]">Crée ou augmente le stock central d’un article. Les quantités restent traçables.</p>
        <div><label className={label}>Article</label><select required value={entry.article_id} onChange={e=>setEntry(x=>({...x,article_id:e.target.value}))} className={input}><option value="">Choisir un article</option>{articles.map(a=><option key={a.id} value={a.id}>{a.name} · {a.code}</option>)}</select></div>
        <div className="grid grid-cols-2 gap-3"><div><label className={label}>Quantité</label><input type="number" min={1} required value={entry.quantity} onChange={e=>setEntry(x=>({...x,quantity:Math.max(1,Number(e.target.value)||1)}))} className={input}/></div><div><label className={label}>Minimum</label><input type="number" min={0} value={entry.minimum_quantity} onChange={e=>setEntry(x=>({...x,minimum_quantity:Number(e.target.value)||0}))} className={input}/></div></div>
        <input value={entry.notes} onChange={e=>setEntry(x=>({...x,notes:e.target.value}))} placeholder="Note / référence fournisseur" className={input}/>
        <button disabled={saving} className="w-full btn-gold rounded-xl py-2.5 font-semibold disabled:opacity-60">Enregistrer l’entrée</button>
      </form>

      <form onSubmit={warehouseSupply} className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5 space-y-3">
        <div className="flex items-center gap-2"><Truck size={18} className="text-[#D4AF37]"/><h2 className="font-semibold text-white">Approvisionner un entrepôt</h2></div>
        <p className="text-xs text-[#718096]">L’administrateur fournit l’entrepôt. Le prospecteur se réapprovisionne ensuite uniquement depuis son entrepôt affecté.</p>
        <div><label className={label}>Entrepôt</label><select required value={supply.warehouse_id} onChange={e=>setSupply(x=>({...x,warehouse_id:e.target.value}))} className={input}><option value="">Choisir un entrepôt</option>{warehouses.map(w=><option key={w.id} value={w.id}>{w.name} · {w.code}</option>)}</select></div>
        <div><label className={label}>Article</label><select required value={supply.article_id} onChange={e=>setSupply(x=>({...x,article_id:e.target.value}))} className={input}><option value="">Choisir un article</option>{articles.map(a=>{const c=centralMap.get(a.id);return <option key={a.id} value={a.id}>{a.name} · disponible {Math.max(0,Number(c?.quantity??0)-Number(c?.reserved_quantity??0))}</option>})}</select></div>
        <div className="grid grid-cols-2 gap-3"><div><label className={label}>Quantité</label><input type="number" min={1} required value={supply.quantity} onChange={e=>setSupply(x=>({...x,quantity:Math.max(1,Number(e.target.value)||1)}))} className={input}/></div><div><label className={label}>Minimum entrepôt</label><input type="number" min={0} value={supply.minimum_quantity} onChange={e=>setSupply(x=>({...x,minimum_quantity:Number(e.target.value)||0}))} className={input}/></div></div>
        <input value={supply.notes} onChange={e=>setSupply(x=>({...x,notes:e.target.value}))} placeholder="Note de transfert" className={input}/>
        <button disabled={saving} className="w-full btn-gold rounded-xl py-2.5 font-semibold disabled:opacity-60">Transférer vers l’entrepôt</button>
      </form>
    </div>

    <section className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
      <div className="p-4 border-b border-[#D4AF37]/10 flex items-center gap-2"><Package size={17} className="text-[#D4AF37]"/><h2 className="font-semibold text-white">Stock central</h2></div>
      {loading?<div className="p-8 text-center text-[#A0AEC0]">Chargement...</div>:<div className="overflow-x-auto"><table className="w-full"><thead><tr className="text-left text-xs text-[#718096] border-b border-white/10"><th className="p-3">Article</th><th className="p-3">Code</th><th className="p-3">Quantité</th><th className="p-3">Réservé</th><th className="p-3">Disponible</th></tr></thead><tbody>{articles.map(a=>{const c=centralMap.get(a.id);const q=Number(c?.quantity??0),r=Number(c?.reserved_quantity??0);return <tr key={a.id} className="border-b border-white/5"><td className="p-3 text-white">{a.name}</td><td className="p-3 text-[#D4AF37] font-mono text-xs">{a.code}</td><td className="p-3 text-white">{q}</td><td className="p-3 text-[#A0AEC0]">{r}</td><td className="p-3 font-semibold text-emerald-300">{q-r}</td></tr>})}</tbody></table></div>}
    </section>

    <section className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
      <div className="p-4 border-b border-[#D4AF37]/10 flex items-center gap-2"><Warehouse size={17} className="text-[#D4AF37]"/><h2 className="font-semibold text-white">Stocks par entrepôt</h2></div>
      {inventory.length===0?<div className="p-8 text-center text-[#718096]">Aucun stock opérationnel dans les entrepôts.</div>:<div className="overflow-x-auto"><table className="w-full"><thead><tr className="text-left text-xs text-[#718096] border-b border-white/10"><th className="p-3">Entrepôt</th><th className="p-3">Article</th><th className="p-3">Quantité</th><th className="p-3">Réservé</th><th className="p-3">Disponible</th><th className="p-3">Minimum</th></tr></thead><tbody>{inventory.map(i=>{const q=Number(i.quantity||0),r=Number(i.reserved_quantity||0);return <tr key={i.id} className="border-b border-white/5"><td className="p-3 text-white">{i.warehouses?.name}</td><td className="p-3 text-[#CBD5E0]">{i.articles?.name||i.articles?.code}</td><td className="p-3 text-white">{q}</td><td className="p-3 text-[#A0AEC0]">{r}</td><td className="p-3 font-semibold text-emerald-300">{q-r}</td><td className="p-3 text-[#A0AEC0]">{i.minimum_quantity}</td></tr>})}</tbody></table></div>}
    </section>
  </div>;
}
