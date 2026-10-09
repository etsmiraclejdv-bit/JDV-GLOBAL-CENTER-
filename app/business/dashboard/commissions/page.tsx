'use client';

import { useEffect, useState } from 'react';
import { supabase } from '@/lib/supabase/client';
import { Plus, Settings2, Percent, Wallet, Trash2 } from 'lucide-react';

type Type = { id:string; name:string; code:string|null; calculation_method:'percentage'|'fixed'|'per_unit'; active:boolean };
type Article = { id:string; name:string; code:string; category:string|null };
type Rule = { id:string; name:string; scope:string; priority:number; rate_percent:number|null; fixed_amount:number|null; per_unit_amount:number|null; cumulative:boolean; active:boolean; commission_types?: {name:string; calculation_method:string} | null; articles?: {name:string;code:string} | null; category_name:string|null };

export default function CommissionsPage() {
  const [orgId,setOrgId]=useState('');
  const [types,setTypes]=useState<Type[]>([]);
  const [articles,setArticles]=useState<Article[]>([]);
  const [rules,setRules]=useState<Rule[]>([]);
  const [loading,setLoading]=useState(true);
  const [saving,setSaving]=useState(false);
  const [typeForm,setTypeForm]=useState({name:'',code:'',description:'',calculation_method:'percentage'});
  const [ruleForm,setRuleForm]=useState({name:'',commission_type_id:'',scope:'organization',article_id:'',category_name:'',priority:100,rate_percent:'',fixed_amount:'',per_unit_amount:'',cumulative:false,applies_to_sale_type:'both'});
  const [message,setMessage]=useState('');

  async function load() {
    setLoading(true);
    const auth = await supabase.auth.getUser();
    const user = auth.data.user;
    if(!user){setMessage('Session expirée.');setLoading(false);return;}
    const memberResult = await supabase.from('organization_members').select('organization_id,role').eq('user_id',user.id).eq('status','active').in('role',['business_admin','manager']).limit(1).maybeSingle();
    const member = memberResult.data;
    if(memberResult.error || !member){setMessage('Accès réservé à l’administration de l’entreprise.');setLoading(false);return;}
    setOrgId(member.organization_id);
    const [t,a,r]=await Promise.all([
      supabase.from('commission_types').select('id,name,code,calculation_method,active').eq('organization_id',member.organization_id).order('name'),
      supabase.from('articles').select('id,name,code,category').eq('organization_id',member.organization_id).order('name'),
      supabase.from('commission_rules').select('id,name,scope,priority,rate_percent,fixed_amount,per_unit_amount,cumulative,active,category_name,commission_types(name,calculation_method),articles(name,code)').eq('organization_id',member.organization_id).order('priority',{ascending:false}).order('created_at')
    ]);
    if(t.error||a.error||r.error){setMessage(t.error?.message||a.error?.message||r.error?.message||'Erreur de chargement.');}
    setTypes((t.data||[]) as Type[]);
    setArticles((a.data||[]) as Article[]);
    setRules((r.data||[]) as Rule[]);
    if(!ruleForm.commission_type_id && t.data && t.data[0]) setRuleForm(function(x){return {...x,commission_type_id:t.data![0].id};});
    setLoading(false);
  }
  useEffect(function(){load()},[]);

  async function createType(e:React.FormEvent){
    e.preventDefault(); if(!orgId||!typeForm.name.trim()) return;
    setSaving(true);setMessage('');
    const user=(await supabase.auth.getUser()).data.user;
    const {error}=await supabase.from('commission_types').insert({organization_id:orgId,name:typeForm.name.trim(),code:typeForm.code.trim()||null,description:typeForm.description.trim()||null,calculation_method:typeForm.calculation_method,created_by:user?.id});
    setSaving(false);setMessage(error?error.message:'Type de commission créé.');
    if(!error){setTypeForm({name:'',code:'',description:'',calculation_method:'percentage'});load();}
  }

  async function createRule(e:React.FormEvent){
    e.preventDefault(); if(!orgId||!ruleForm.name.trim()||!ruleForm.commission_type_id)return;
    setSaving(true);setMessage('');
    const user=(await supabase.auth.getUser()).data.user;
    const {error}=await supabase.from('commission_rules').insert({
      organization_id:orgId,name:ruleForm.name.trim(),commission_type_id:ruleForm.commission_type_id,scope:ruleForm.scope,
      article_id:ruleForm.scope==='article'?ruleForm.article_id:null,category_name:ruleForm.scope==='category'?ruleForm.category_name.trim():null,
      priority:Number(ruleForm.priority)||100,rate_percent:ruleForm.rate_percent===''?null:Number(ruleForm.rate_percent),
      fixed_amount:ruleForm.fixed_amount===''?null:Number(ruleForm.fixed_amount),per_unit_amount:ruleForm.per_unit_amount===''?null:Number(ruleForm.per_unit_amount),
      cumulative:ruleForm.cumulative,applies_to_sale_type:ruleForm.applies_to_sale_type,created_by:user?.id
    });
    setSaving(false);setMessage(error?error.message:'Règle de commission créée.');
    if(!error){setRuleForm(function(x){return {...x,name:'',article_id:'',category_name:'',rate_percent:'',fixed_amount:'',per_unit_amount:''};});load();}
  }

  async function toggleRule(id:string,active:boolean){await supabase.from('commission_rules').update({active:!active}).eq('id',id);load();}
  async function deleteRule(id:string){if(!confirm('Supprimer cette règle ?'))return;await supabase.from('commission_rules').delete().eq('id',id);load();}

  if(loading) return <div className="p-8 text-white">Chargement…</div>;

  return <div className="p-6 space-y-6 text-white">
    <div><h1 className="text-2xl font-bold">Commissions & primes</h1><p className="text-slate-400 mt-1">Configurez les commissions par entreprise, article, catégorie et les primes complémentaires.</p></div>
    {message && <div className="rounded-xl border border-[#D4AF37]/20 bg-[#D4AF37]/10 p-3 text-sm">{message}</div>}
    <div className="grid lg:grid-cols-2 gap-6">
      <section className="rounded-2xl border border-white/10 bg-[#08152f] p-5">
        <div className="flex items-center gap-2 mb-4"><Settings2 size={18}/><h2 className="font-semibold">Types de commission / primes</h2></div>
        <form onSubmit={createType} className="space-y-3">
          <input className="w-full rounded-lg bg-[#0F2347] border border-white/10 p-2.5" placeholder="Ex. Commission de vente, Transport, Prime objectif" value={typeForm.name} onChange={e=>setTypeForm({...typeForm,name:e.target.value})}/>
          <div className="grid grid-cols-2 gap-3"><input className="rounded-lg bg-[#0F2347] border border-white/10 p-2.5" placeholder="Code (optionnel)" value={typeForm.code} onChange={e=>setTypeForm({...typeForm,code:e.target.value})}/><select className="rounded-lg bg-[#0F2347] border border-white/10 p-2.5" value={typeForm.calculation_method} onChange={e=>setTypeForm({...typeForm,calculation_method:e.target.value})}><option value="percentage">Pourcentage</option><option value="fixed">Montant fixe</option><option value="per_unit">Par unité</option></select></div>
          <input className="w-full rounded-lg bg-[#0F2347] border border-white/10 p-2.5" placeholder="Description" value={typeForm.description} onChange={e=>setTypeForm({...typeForm,description:e.target.value})}/>
          <button disabled={saving} className="inline-flex items-center gap-2 rounded-lg bg-[#D4AF37] text-[#08152f] font-semibold px-4 py-2"><Plus size={16}/>Créer le type</button>
        </form>
        <div className="mt-5 space-y-2">{types.map(t=><div key={t.id} className="flex items-center justify-between rounded-lg bg-[#0F2347] p-3 text-sm"><span>{t.name}</span><span className="text-slate-400">{t.calculation_method}</span></div>)}</div>
      </section>
      <section className="rounded-2xl border border-white/10 bg-[#08152f] p-5">
        <div className="flex items-center gap-2 mb-4"><Percent size={18}/><h2 className="font-semibold">Nouvelle règle</h2></div>
        <form onSubmit={createRule} className="space-y-3">
          <input required className="w-full rounded-lg bg-[#0F2347] border border-white/10 p-2.5" placeholder="Nom de la règle" value={ruleForm.name} onChange={e=>setRuleForm({...ruleForm,name:e.target.value})}/>
          <select required className="w-full rounded-lg bg-[#0F2347] border border-white/10 p-2.5" value={ruleForm.commission_type_id} onChange={e=>setRuleForm({...ruleForm,commission_type_id:e.target.value})}>{types.map(t=><option key={t.id} value={t.id}>{t.name}</option>)}</select>
          <div className="grid grid-cols-2 gap-3"><select className="rounded-lg bg-[#0F2347] border border-white/10 p-2.5" value={ruleForm.scope} onChange={e=>setRuleForm({...ruleForm,scope:e.target.value})}><option value="organization">Entreprise</option><option value="article">Article</option><option value="category">Catégorie</option></select><input type="number" className="rounded-lg bg-[#0F2347] border border-white/10 p-2.5" placeholder="Priorité" value={ruleForm.priority} onChange={e=>setRuleForm({...ruleForm,priority:Number(e.target.value)})}/></div>
          {ruleForm.scope==='article' && <select required className="w-full rounded-lg bg-[#0F2347] border border-white/10 p-2.5" value={ruleForm.article_id} onChange={e=>setRuleForm({...ruleForm,article_id:e.target.value})}><option value="">Choisir l'article</option>{articles.map(a=><option key={a.id} value={a.id}>{a.code} — {a.name}</option>)}</select>}
          {ruleForm.scope==='category' && <input required className="w-full rounded-lg bg-[#0F2347] border border-white/10 p-2.5" placeholder="Nom exact de la catégorie" value={ruleForm.category_name} onChange={e=>setRuleForm({...ruleForm,category_name:e.target.value})}/>}
          <div className="grid grid-cols-3 gap-3"><input type="number" step="0.0001" className="rounded-lg bg-[#0F2347] border border-white/10 p-2.5" placeholder="% taux" value={ruleForm.rate_percent} onChange={e=>setRuleForm({...ruleForm,rate_percent:e.target.value})}/><input type="number" step="0.01" className="rounded-lg bg-[#0F2347] border border-white/10 p-2.5" placeholder="Montant fixe" value={ruleForm.fixed_amount} onChange={e=>setRuleForm({...ruleForm,fixed_amount:e.target.value})}/><input type="number" step="0.01" className="rounded-lg bg-[#0F2347] border border-white/10 p-2.5" placeholder="Par unité" value={ruleForm.per_unit_amount} onChange={e=>setRuleForm({...ruleForm,per_unit_amount:e.target.value})}/></div>
          <div className="grid grid-cols-2 gap-3"><select className="rounded-lg bg-[#0F2347] border border-white/10 p-2.5" value={ruleForm.applies_to_sale_type} onChange={e=>setRuleForm({...ruleForm,applies_to_sale_type:e.target.value})}><option value="both">Comptant + crédit</option><option value="cash">Comptant</option><option value="credit">Crédit</option></select><label className="flex items-center gap-2 rounded-lg bg-[#0F2347] p-2.5 text-sm"><input type="checkbox" checked={ruleForm.cumulative} onChange={e=>setRuleForm({...ruleForm,cumulative:e.target.checked})}/> Cumulable</label></div>
          <button disabled={saving||types.length===0} className="inline-flex items-center gap-2 rounded-lg bg-[#D4AF37] text-[#08152f] font-semibold px-4 py-2"><Plus size={16}/>Ajouter la règle</button>
        </form>
      </section>
    </div>
    <section className="rounded-2xl border border-white/10 bg-[#08152f] p-5"><div className="flex items-center gap-2 mb-4"><Wallet size={18}/><h2 className="font-semibold">Règles configurées</h2></div><div className="overflow-x-auto"><table className="w-full text-sm"><thead><tr className="text-left text-slate-400 border-b border-white/10"><th className="p-2">Règle</th><th className="p-2">Portée</th><th className="p-2">Calcul</th><th className="p-2">Priorité</th><th className="p-2">État</th><th className="p-2"></th></tr></thead><tbody>{rules.map(r=><tr key={r.id} className="border-b border-white/5"><td className="p-2">{r.name}<div className="text-xs text-slate-500">{r.commission_types?.name}</div></td><td className="p-2">{r.scope==='article'?(r.articles?.name||'Article'):r.scope==='category'?(r.category_name||'Catégorie'):'Entreprise'}</td><td className="p-2">{r.rate_percent!=null?String(r.rate_percent)+'%':r.fixed_amount!=null?String(r.fixed_amount):String(r.per_unit_amount||0)+'/unité'}</td><td className="p-2">{r.priority}</td><td className="p-2"><button onClick={()=>toggleRule(r.id,r.active)} className="text-[#D4AF37]">{r.active?'Active':'Inactive'}</button></td><td className="p-2 text-right"><button onClick={()=>deleteRule(r.id)} className="text-red-400"><Trash2 size={16}/></button></td></tr>)}</tbody></table></div></section>
  </div>;
}
