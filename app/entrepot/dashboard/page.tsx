'use client';

import { useCallback, useEffect, useState } from 'react';
import Link from 'next/link';
import { supabase } from '@/lib/supabase/client';
import { useWarehouse } from '@/components/entrepot/WarehouseContext';
import { Banner, Card, PageTitle, Stat, money, num, useBanner } from '@/components/entrepot/common';

type StockRow = { article_id: string; article_name: string; quantity: number; minimum_quantity: number; is_low: boolean };
type Prosp = { prospecteur_id: string; full_name: string | null; overdue_count: number; to_return_units: number };
type Report = { sales_total: { quantity: number; amount: number; sales_count: number }; tickets: { opened: number; resolved: number; still_open: number }; supply_requests: { created_today: number; pending: number }; entries: { quantity: number }[]; exits: { quantity: number }[] };

export default function EntrepotOverviewPage() {
  const { current } = useWarehouse();
  const { banner, fail } = useBanner();
  const [stock, setStock] = useState<StockRow[]>([]);
  const [prosp, setProsp] = useState<Prosp[]>([]);
  const [report, setReport] = useState<Report | null>(null);
  const [loading, setLoading] = useState(true);

  const load = useCallback(async () => {
    if (!current) return;
    setLoading(true);
    const id = current.warehouse_id;
    const [s, p, r] = await Promise.all([
      supabase.rpc('jdvcrm_warehouse_stock_v1', { p_warehouse_id: id }),
      supabase.rpc('jdvcrm_warehouse_prospecteurs_v1', { p_warehouse_id: id }),
      supabase.rpc('jdvcrm_warehouse_day_report_v1', { p_warehouse_id: id }),
    ]);
    const err = s.error || p.error || r.error;
    if (err) fail(err.message);
    setStock((s.data ?? []) as StockRow[]);
    setProsp((p.data ?? []) as Prosp[]);
    setReport((r.data ?? null) as Report | null);
    setLoading(false);
  }, [current, fail]);

  useEffect(() => { load(); }, [load]);

  const inStock = stock.filter((s) => Number(s.quantity) > 0).length;
  const low = stock.filter((s) => s.is_low);
  const overdue = prosp.reduce((a, p) => a + Number(p.overdue_count), 0);
  const entries = (report?.entries ?? []).reduce((a, e) => a + Number(e.quantity), 0);
  const exits = (report?.exits ?? []).reduce((a, e) => a + Number(e.quantity), 0);

  return (
    <div className="p-6 space-y-6 text-white">
      <PageTitle title="Tableau de bord" subtitle="Situation de votre entrepôt en temps réel." />
      <Banner state={banner} />
      {loading ? <p className="text-slate-400 text-sm">Chargement…</p> : <>
        <div className="grid gap-4 grid-cols-2 lg:grid-cols-4">
          <Stat label="Produits en stock" value={num(inStock)} />
          <Stat label="Alertes stock bas" value={num(low.length)} tone={low.length ? 'warn' : 'ok'} />
          <Stat label="Prospecteurs affectés" value={num(prosp.length)} />
          <Stat label="Lots en retard de retour" value={num(overdue)} tone={overdue ? 'warn' : 'ok'} />
          <Stat label="Entrées du jour" value={`+${num(entries)}`} />
          <Stat label="Sorties du jour" value={`−${num(exits)}`} />
          <Stat label="Ventes du jour" value={money(report?.sales_total?.amount)} />
          <Stat label="Appels à traiter" value={num(report?.tickets?.still_open)} tone={report?.tickets?.still_open ? 'warn' : 'ok'} />
        </div>
        <div className="grid gap-6 lg:grid-cols-2">
          <Card title="Produits à réapprovisionner">
            {low.length === 0 ? <p className="text-sm text-slate-400">Aucun produit sous son seuil minimum.</p> : <ul className="space-y-2 text-sm">{low.map((s) => <li key={s.article_id} className="flex justify-between rounded-lg bg-[#0F2347] p-3"><span>{s.article_name}</span><span className="text-red-400">{num(s.quantity)} / seuil {num(s.minimum_quantity)}</span></li>)}</ul>}
            <Link href="/entrepot/dashboard/approvisionnement" className="inline-block mt-4 text-sm text-[#D4AF37] underline">Demander un approvisionnement →</Link>
          </Card>
          <Card title="Prospecteurs à surveiller">
            {prosp.filter((p) => Number(p.overdue_count) > 0).length === 0 ? <p className="text-sm text-slate-400">Aucun lot en retard de retour.</p> : <ul className="space-y-2 text-sm">{prosp.filter((p) => Number(p.overdue_count) > 0).map((p) => <li key={p.prospecteur_id} className="flex justify-between rounded-lg bg-[#0F2347] p-3"><span>{p.full_name ?? '—'}</span><span className="text-red-400">{num(p.overdue_count)} lot(s) · {num(p.to_return_units)} unité(s)</span></li>)}</ul>}
            <Link href="/entrepot/dashboard/prospecteurs" className="inline-block mt-4 text-sm text-[#D4AF37] underline">Gérer les prospecteurs et les retours →</Link>
          </Card>
        </div>
      </>}
    </div>
  );
}
