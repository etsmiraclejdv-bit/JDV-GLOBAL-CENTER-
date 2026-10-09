'use client';

import React, { useEffect, useState } from 'react';
import { AlertTriangle, CheckCircle2, Clock3, Package, UserCheck, RefreshCw, Sparkles } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchOrgProfile } from '@/lib/auth/context';

type AlertRow = {
  id: string;
  severity: 'critical'|'warning'|'opportunity'|'info';
  category: string;
  title: string;
  message: string;
  recommendation: string | null;
  status: string;
  created_at: string;
};

const severityClass: Record<string,string> = {
  critical: 'border-red-500/40 bg-red-500/10 text-red-300',
  warning: 'border-amber-500/40 bg-amber-500/10 text-amber-300',
  opportunity: 'border-emerald-500/40 bg-emerald-500/10 text-emerald-300',
  info: 'border-blue-500/40 bg-blue-500/10 text-blue-300',
};

export default function IntelligencePage() {
  const [alerts, setAlerts] = useState<AlertRow[]>([]);
  const [loading, setLoading] = useState(true);

  const load = async () => {
    setLoading(true);
    const { data: profile } = await fetchOrgProfile();
    if (!profile?.organization_id) { setLoading(false); return; }
    const { data } = await supabase
      .from('intelligence_alerts')
      .select('id,severity,category,title,message,recommendation,status,created_at')
      .eq('organization_id', profile.organization_id)
      .in('status', ['open','acknowledged'])
      .order('created_at', { ascending: false })
      .limit(100);
    setAlerts((data ?? []) as AlertRow[]);
    setLoading(false);
  };

  useEffect(() => {
    load();
    let channel: ReturnType<typeof supabase.channel> | null = null;
    let active = true;
    fetchOrgProfile().then(({ data: profile }) => {
      if (!active || !profile?.organization_id) return;
      channel = supabase
        .channel(`intelligence-business-${profile.organization_id}`)
        .on('postgres_changes', { event: '*', schema: 'public', table: 'intelligence_alerts', filter: `organization_id=eq.${profile.organization_id}` }, load)
        .subscribe();
    });
    return () => {
      active = false;
      if (channel) void supabase.removeChannel(channel);
    };
  }, []);

  const acknowledge = async (id: string) => {
    await supabase.from('intelligence_alerts').update({ status: 'acknowledged', acknowledged_at: new Date().toISOString() }).eq('id', id);
    await load();
  };

  const resolve = async (id: string) => {
    await supabase.from('intelligence_alerts').update({ status: 'resolved', resolved_at: new Date().toISOString() }).eq('id', id);
    await load();
  };

  const iconFor = (category: string) => {
    if (category === 'stock') return <Package size={18} />;
    if (category === 'productivity') return <UserCheck size={18} />;
    if (category === 'return') return <RefreshCw size={18} />;
    return <Clock3 size={18} />;
  };

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div className="flex items-start justify-between gap-4">
        <div>
          <div className="flex items-center gap-2">
            <Sparkles className="text-[#D4AF37]" size={22} />
            <h1 className="text-2xl font-bold text-white">Intelligence JDV</h1>
          </div>
          <p className="text-sm text-[#A0AEC0] mt-1">Relances, stocks, retours et activité analysés automatiquement.</p>
        </div>
        <button onClick={load} className="p-2 rounded-xl border border-[#D4AF37]/20 text-[#D4AF37] hover:bg-[#D4AF37]/10" title="Actualiser">
          <RefreshCw size={17} />
        </button>
      </div>

      {loading ? <div className="text-sm text-[#A0AEC0]">Analyse en cours…</div> : alerts.length === 0 ? (
        <div className="rounded-2xl border border-emerald-500/20 bg-emerald-500/5 p-6 text-emerald-300">Aucune alerte active.</div>
      ) : (
        <div className="space-y-3">
          {alerts.map(alert => (
            <div key={alert.id} className={`rounded-2xl border p-4 ${severityClass[alert.severity] ?? severityClass.info}`}>
              <div className="flex items-start gap-3">
                <div className="mt-0.5">{iconFor(alert.category)}</div>
                <div className="flex-1">
                  <div className="flex items-center justify-between gap-3">
                    <h2 className="font-semibold">{alert.title}</h2>
                    <span className="text-[11px] opacity-70">{new Date(alert.created_at).toLocaleString('fr-FR')}</span>
                  </div>
                  <p className="text-sm mt-1">{alert.message}</p>
                  {alert.recommendation && <p className="text-xs mt-2 opacity-90"><strong>Suggestion :</strong> {alert.recommendation}</p>}
                  <div className="flex gap-2 mt-3">
                    <button onClick={() => acknowledge(alert.id)} className="px-3 py-1.5 rounded-lg bg-white/5 text-xs">Prendre en compte</button>
                    <button onClick={() => resolve(alert.id)} className="px-3 py-1.5 rounded-lg bg-white/10 text-xs flex items-center gap-1"><CheckCircle2 size={13} /> Résoudre</button>
                  </div>
                </div>
              </div>
            </div>
          ))}
        </div>
      )}

      <div className="rounded-2xl border border-[#D4AF37]/20 bg-[#0F2347] p-4 text-xs text-[#A0AEC0]">
        Le moteur applique les règles opérationnelles du CRM (J+14, J+10/J+20, seuils de stock et inactivité). L'IA générative pourra ensuite enrichir ces alertes avec une explication et une recommandation contextualisée.
      </div>
    </div>
  );
}
