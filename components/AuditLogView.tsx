'use client';
import React, { useState, useEffect } from 'react';
import { FileText, ChevronDown, ChevronRight } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchAuditLogs, AuditLog } from '@/lib/services/auditService';

function DiffView({ oldData, newData }: { oldData?: Record<string, unknown>; newData?: Record<string, unknown> }) {
  if (!oldData && !newData) return null;
  const keys = Array.from(new Set([...Object.keys(oldData ?? {}), ...Object.keys(newData ?? {})]));
  const changed = keys.filter(k => JSON.stringify((oldData ?? {})[k]) !== JSON.stringify((newData ?? {})[k]));
  if (changed.length === 0) return <p className="text-xs text-[#718096]">Aucun changement détecté</p>;
  return (
    <div className="space-y-1">
      {changed.map(k => (
        <div key={k} className="text-xs">
          <span className="text-[#A0AEC0] font-medium">{k}: </span>
          {oldData?.[k] !== undefined && (
            <span className="text-red-400 line-through mr-2">{JSON.stringify(oldData[k])}</span>
          )}
          {newData?.[k] !== undefined && (
            <span className="text-green-400">{JSON.stringify(newData[k])}</span>
          )}
        </div>
      ))}
    </div>
  );
}

interface AuditPageProps {
  isSuperAdmin?: boolean;
}

export default function AuditLogPage({ isSuperAdmin = false }: AuditPageProps) {
  const [logs, setLogs] = useState<AuditLog[]>([]);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [expandedId, setExpandedId] = useState<string | null>(null);
  const [entityTypeFilter, setEntityTypeFilter] = useState('');
  const [actionFilter, setActionFilter] = useState('');
  const [orgId, setOrgId] = useState<string | null>(null);
  const [orgIdResolved, setOrgIdResolved] = useState(false);

  // Step 1: resolve orgId once (only needed for non-super-admin)
  useEffect(() => {
    if (isSuperAdmin) {
      setOrgIdResolved(true);
      return;
    }
    supabase.auth.getUser().then(async ({ data }) => {
      if (!data.user) {
        setOrgIdResolved(true);
        return;
      }
      const { data: member } = await supabase
        .from('organization_members' as never)
        .select('organization_id')
        .eq('user_id', data.user.id)
        .eq('status', 'active')
        .limit(1)
        .single();
      setOrgId((member as { organization_id: string } | null)?.organization_id ?? null);
      setOrgIdResolved(true);
    });
  }, [isSuperAdmin]);

  // Step 2: fetch logs once orgId is resolved
  useEffect(() => {
    if (!orgIdResolved) return;
    setLoading(true);
    setError('');
    fetchAuditLogs({
      organizationId: isSuperAdmin ? undefined : (orgId ?? undefined),
      entityType: entityTypeFilter || undefined,
      action: actionFilter || undefined,
    }).then(({ data: logsData, error: logsError }) => {
      if (logsError) setError(logsError.message);
      else setLogs(logsData ?? []);
      setLoading(false);
    });
  }, [orgIdResolved, orgId, entityTypeFilter, actionFilter, isSuperAdmin]);

  const entityTypes = Array.from(new Set(logs.map(l => l.entity_type).filter(Boolean)));
  const actions = Array.from(new Set(logs.map(l => l.action).filter(Boolean)));

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Journal d&apos;audit</h1>
        <p className="text-sm text-[#A0AEC0] mt-1">Lecture seule — alimenté automatiquement par les triggers</p>
      </div>

      {/* Filters */}
      <div className="flex flex-col sm:flex-row gap-3">
        <select
          value={entityTypeFilter}
          onChange={e => setEntityTypeFilter(e.target.value)}
          className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-[#A0AEC0] text-sm focus:outline-none focus:border-[#D4AF37]/60"
        >
          <option value="">Tous les types</option>
          {entityTypes.map(t => <option key={t} value={t}>{t}</option>)}
        </select>
        <select
          value={actionFilter}
          onChange={e => setActionFilter(e.target.value)}
          className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-[#A0AEC0] text-sm focus:outline-none focus:border-[#D4AF37]/60"
        >
          <option value="">Toutes les actions</option>
          {actions.map(a => <option key={a} value={a}>{a}</option>)}
        </select>
      </div>

      {/* Table */}
      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
        {loading ? (
          <div className="py-16 text-center text-[#A0AEC0] text-sm">Chargement...</div>
        ) : error ? (
          <div className="py-16 text-center text-red-400 text-sm">{error}</div>
        ) : logs.length === 0 ? (
          <div className="py-16 text-center">
            <FileText size={32} className="mx-auto mb-3 text-[#718096] opacity-50" />
            <p className="text-[#A0AEC0] text-sm">Aucun log d&apos;audit pour le moment</p>
            <p className="text-[#718096] text-xs mt-1">Les logs apparaissent automatiquement dès qu&apos;une action est enregistrée</p>
          </div>
        ) : (
          <div className="divide-y divide-[#D4AF37]/5">
            {logs.map(log => (
              <div key={log.id} className="hover:bg-[#0A1628]/30 transition-colors">
                <button
                  onClick={() => setExpandedId(expandedId === log.id ? null : log.id)}
                  className="w-full flex items-center gap-4 px-4 py-3 text-left"
                >
                  <span className="flex-shrink-0 text-[#718096]">
                    {expandedId === log.id ? <ChevronDown size={14} /> : <ChevronRight size={14} />}
                  </span>
                  <div className="flex-1 min-w-0 grid grid-cols-2 sm:grid-cols-4 gap-2">
                    <span className="text-xs text-[#718096]">{new Date(log.created_at).toLocaleString('fr-FR')}</span>
                    <span className="text-xs font-medium text-[#D4AF37]">{log.action}</span>
                    <span className="text-xs text-[#A0AEC0]">{log.entity_type}</span>
                    <span className="text-xs text-[#718096] truncate">{log.entity_id ? `${log.entity_id.slice(0, 8)}...` : '—'}</span>
                  </div>
                </button>
                {expandedId === log.id && (
                  <div className="px-10 pb-4">
                    <DiffView
                      oldData={log.old_data as Record<string, unknown> | undefined}
                      newData={log.new_data as Record<string, unknown> | undefined}
                    />
                  </div>
                )}
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  );
}
