'use client';

import React, { useEffect, useMemo, useState } from 'react';
import { AlertTriangle, Boxes, MapPin, RefreshCw, Truck, Users, Warehouse, Clock3 } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchOrgProfile } from '@/lib/auth/context';

type Row = Record<string, any>;

const card = 'rounded-2xl border border-[#D4AF37]/15 bg-[#0F2347] p-4';
const pill = 'rounded-full px-2.5 py-1 text-xs font-semibold';

export default function LogisticsControlPage() {
  const [orgId, setOrgId] = useState<string | null>(null);
  const [warehouses, setWarehouses] = useState<Row[]>([]);
  const [assignments, setAssignments] = useState<Row[]>([]);
  const [inventory, setInventory] = useState<Row[]>([]);
  const [prospecteurStock, setProspecteurStock] = useState<Row[]>([]);
  const [holdings, setHoldings] = useState<Row[]>([]);
  const [requests, setRequests] = useState<Row[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');

  const load = async () => {
    setLoading(true); setError('');
    const { data: profile } = await fetchOrgProfile();
    const organizationId = profile?.organization_id;
    if (!organizationId) { setError('Organisation introuvable.'); setLoading(false); return; }
    setOrgId(organizationId);

    const results = await Promise.all([
      supabase.from('warehouses').select('id,code,name,city,address,active').eq('organization_id', organizationId).order('name'),
      supabase.from('prospecteur_warehouse_assignments').select('id,prospecteur_id,warehouse_id,department,city,work_zone,is_primary,active,prospecteurs(first_name,last_name,status),warehouses(name,code,city)').eq('organization_id', organizationId).eq('active', true).eq('is_primary', true),
      supabase.from('warehouse_inventory').select('id,warehouse_id,article_id,quantity,reserved_quantity,minimum_quantity,warehouses(name,code),articles(name,code)').eq('organization_id', organizationId),
      supabase.from('prospecteur_stocks').select('id,prospecteur_id,article_id,quantity,prospecteurs(first_name,last_name),articles(name,code)').eq('organization_id', organizationId),
      supabase.from('prospecteur_stock_holdings').select('id,prospecteur_id,article_id,warehouse_id,quantity,remaining_quantity,supplied_at,return_due_at,hard_due_at,status,prospecteurs(first_name,last_name),articles(name,code),warehouses(name,code)').eq('organization_id', organizationId).gt('remaining_quantity', 0).order('return_due_at'),
      supabase.from('prospecteur_supply_requests').select('id,prospecteur_id,warehouse_id,status,requested_at,prospecteurs(first_name,last_name),warehouses(name,code)').eq('organization_id', organizationId).eq('status', 'pending').order('requested_at')
    ]);
    const firstError = results.find(x => x.error)?.error;
    if (firstError) setError(firstError.message);
    setWarehouses(results[0].data ?? []);
    setAssignments(results[1].data ?? []);
    setInventory(results[2].data ?? []);
    setProspecteurStock(results[3].data ?? []);
    setHoldings(results[4].data ?? []);
    setRequests(results[5].data ?? []);
    setLoading(false);
  };

  useEffect(() => { load(); }, []);

  const metrics = useMemo(() => {
    const overdue = holdings.filter(h => new Date(h.return_due_at) <= new Date());
    const critical = holdings.filter(h => new Date(h.hard_due_at) <= new Date());
    const low = inventory.filter(i => Number(i.quantity ?? 0) - Number(i.reserved_quantity ?? 0) <= Number(i.minimum_quantity ?? 0));
    return {
      warehouses: warehouses.filter(w => w.active).length,
      assigned: assignments.length,
      unassigned: Math.max(0, assignments.length ? new Set(assignments.map(a => a.prospecteur_id)).size : 0),
      low: low.length, overdue: overdue.length, critical: critical.length, requests: requests.length
    };
  }, [warehouses, assignments, inventory, holdings, requests]);

  if (loading) return <div className="p-8 text-[#A0AEC0]">Chargement du centre de contrôle logistique…</div>;

  return (
    <div className="p-6 lg:p-8 space-y-6 overflow-y-auto h-full">
      <div className="flex flex-wrap justify-between gap-4">
        <div>
          <div className="flex items-center gap-2"><Warehouse className="text-[#D4AF37]" /><h1 className="text-2xl font-bold text-white">Centre de contrôle logistique</h1></div>
          <p className="mt-1 text-sm text-[#A0AEC0]">Entreprise → entrepôts → zones → prospecteurs → stocks → retours. L’entreprise alimente les entrepôts ; chaque prospecteur se réapprovisionne exclusivement dans son entrepôt affecté.</p>
        </div>
        <button onClick={load} className="rounded-xl border border-[#D4AF37]/20 px-3 py-2 text-sm text-white"><RefreshCw size={15} className="inline mr-1" />Actualiser</button>
      </div>

      {error && <div className="rounded-xl border border-red-500/30 bg-red-500/10 p-3 text-sm text-red-200">{error}</div>}

      <div className="grid grid-cols-2 lg:grid-cols-6 gap-3">
        <div className={card}><Warehouse size={18} className="text-[#D4AF37]" /><p className="mt-2 text-2xl font-bold text-white">{metrics.warehouses}</p><p className="text-xs text-[#A0AEC0]">Entrepôts actifs</p></div>
        <div className={card}><Users size={18} className="text-[#D4AF37]" /><p className="mt-2 text-2xl font-bold text-white">{metrics.assigned}</p><p className="text-xs text-[#A0AEC0]">Affectations actives</p></div>
        <div className={card}><Boxes size={18} className="text-[#D4AF37]" /><p className="mt-2 text-2xl font-bold text-white">{inventory.length}</p><p className="text-xs text-[#A0AEC0]">Lignes stock entrepôt</p></div>
        <div className={card}><AlertTriangle size={18} className="text-red-300" /><p className="mt-2 text-2xl font-bold text-white">{metrics.low}</p><p className="text-xs text-[#A0AEC0]">Stocks faibles</p></div>
        <div className={card}><Clock3 size={18} className="text-orange-300" /><p className="mt-2 text-2xl font-bold text-white">{metrics.overdue}</p><p className="text-xs text-[#A0AEC0]">Retours J+10</p></div>
        <div className={card}><Truck size={18} className="text-[#D4AF37]" /><p className="mt-2 text-2xl font-bold text-white">{metrics.requests}</p><p className="text-xs text-[#A0AEC0]">Demandes d’approvisionnement</p></div>
      </div>

      <section className={card}>
        <h2 className="font-semibold text-white mb-4">Entrepôts et zones</h2>
        <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-3">
          {warehouses.filter(w => w.active).map(w => {
            const people = assignments.filter(a => a.warehouse_id === w.id);
            const lines = inventory.filter(i => i.warehouse_id === w.id);
            return <div key={w.id} className="rounded-xl border border-[#D4AF37]/10 bg-[#0A1628] p-4">
              <div className="flex justify-between"><b className="text-white">{w.name}</b><span className="text-xs text-[#D4AF37]">{w.code}</span></div>
              <p className="mt-1 text-xs text-[#718096]"><MapPin size={12} className="inline" /> {w.city || w.address || '—'}</p>
              <div className="mt-3 flex gap-2"><span className={pill + ' bg-[#D4AF37]/10 text-[#D4AF37]'}>{people.length} prospecteur(s)</span><span className={pill + ' bg-white/5 text-[#A0AEC0]'}>{lines.length} article(s)</span></div>
              {people.length > 0 && <div className="mt-3 space-y-1">{people.map(a => <div key={a.id} className="text-xs text-[#CBD5E0]">{a.prospecteurs?.first_name} {a.prospecteurs?.last_name} · {a.work_zone || 'zone non définie'}</div>)}</div>}
            </div>;
          })}
        </div>
      </section>

      <section className={card}>
        <h2 className="font-semibold text-white mb-4">Stocks entrepôts</h2>
        <div className="overflow-x-auto"><table className="w-full text-sm"><thead><tr className="text-left text-xs text-[#718096] border-b border-white/10"><th className="p-2">Entrepôt</th><th className="p-2">Article</th><th className="p-2">Disponible</th><th className="p-2">Minimum</th><th className="p-2">État</th></tr></thead><tbody>
          {inventory.map(i => { const available=Number(i.quantity||0)-Number(i.reserved_quantity||0); const low=available<=Number(i.minimum_quantity||0); return <tr key={i.id} className="border-b border-white/5"><td className="p-2 text-white">{i.warehouses?.name}</td><td className="p-2 text-[#CBD5E0]">{i.articles?.name || i.articles?.code}</td><td className="p-2 text-white">{available}</td><td className="p-2 text-[#A0AEC0]">{i.minimum_quantity || 0}</td><td className="p-2"><span className={pill + ' ' + (low ? 'bg-red-500/10 text-red-300' : 'bg-emerald-500/10 text-emerald-300')}>{low ? 'Stock faible' : 'OK'}</span></td></tr>; })}
        </tbody></table></div>
      </section>

      <section className={card}>
        <h2 className="font-semibold text-white mb-4">Marchandises chez les prospecteurs — retours à surveiller</h2>
        <div className="space-y-2">{holdings.length === 0 ? <p className="text-sm text-[#718096]">Aucune marchandise actuellement en circulation.</p> : holdings.map(h => {
          const due = new Date(h.return_due_at); const hard = new Date(h.hard_due_at); const now = new Date(); const critical = hard <= now; const overdue = due <= now;
          return <div key={h.id} className="flex flex-wrap items-center justify-between gap-3 rounded-xl bg-[#0A1628] p-3"><div><p className="text-sm font-semibold text-white">{h.prospecteurs?.first_name} {h.prospecteurs?.last_name} · {h.articles?.name}</p><p className="text-xs text-[#718096]">{h.warehouses?.name} · restant {h.remaining_quantity} · échéance {due.toLocaleDateString('fr-FR')}</p></div><span className={pill + ' ' + (critical ? 'bg-red-500/15 text-red-300' : overdue ? 'bg-orange-500/15 text-orange-300' : 'bg-emerald-500/10 text-emerald-300')}>{critical ? 'J+20 critique' : overdue ? 'J+10 dépassé' : 'En cours'}</span></div>;
        })}</div>
      </section>

      <section className={card}>
        <h2 className="font-semibold text-white mb-4">Flux d’approvisionnement</h2>
        {requests.length === 0 ? <p className="text-sm text-[#718096]">Aucun approvisionnement en attente.</p> : <div className="space-y-2">{requests.map(r => <div key={r.id} className="flex justify-between rounded-xl bg-[#0A1628] p-3"><span className="text-sm text-white">{r.prospecteurs?.first_name} {r.prospecteurs?.last_name} → {r.warehouses?.name}</span><span className="text-xs text-[#A0AEC0]">{new Date(r.requested_at).toLocaleString('fr-FR')}</span></div>)}</div>}
      </section>

      <section className={card}>
        <h2 className="font-semibold text-white mb-4">Stock détenu par les prospecteurs</h2>
        <div className="grid md:grid-cols-2 xl:grid-cols-3 gap-2">{prospecteurStock.map(s => <div key={s.id} className="rounded-xl bg-[#0A1628] p-3"><p className="text-sm font-semibold text-white">{s.prospecteurs?.first_name} {s.prospecteurs?.last_name}</p><p className="text-xs text-[#A0AEC0]">{s.articles?.name} · quantité {s.quantity}</p></div>)}</div>
      </section>
    </div>
  );
}
