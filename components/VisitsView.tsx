'use client';
import React, { useCallback, useEffect, useMemo, useState } from 'react';
import { Calendar, CheckCircle, Clock, MapPin, Phone, Plus, RefreshCw, Search, Users } from 'lucide-react';
import { toast } from 'sonner';
import { getAuthContext } from '@/lib/auth/context';
import { getAdminOrganization } from '@/lib/auth/admin-org';
import { fetchProspecteurNames } from '@/lib/services/relancesService';
import { createVisit, fetchProspectOptions, fetchVisits, type ProspectOption, type VisitRecord } from '@/lib/services/visitsService';
import {
  VISIT_RESULTS,
  fromDatetimeLocal,
  mapsUrl,
  prospectsDueForFollowUp,
  summarizeVisits,
  toDatetimeLocal,
  validateVisit,
  visitResultLabel,
} from '@/lib/visits/helpers';
import { formatDateTimeFr } from '@/lib/platform/paymentsHelpers';
import { toTelHref } from '@/lib/relances/helpers';
import { inputClass, labelClass } from '@/lib/ui/forms';
import Modal from '@/components/ui/Modal';
import MetricCard from '@/components/ui/MetricCard';
import LoadingState from '@/components/ui/LoadingState';
import ErrorState from '@/components/ui/ErrorState';

interface VisitsViewProps {
  /** « terrain » : le prospecteur saisit et consulte ses visites ; « business » : l'administrateur consulte toutes les visites. */
  mode: 'terrain' | 'business';
}

const RESULT_CLASSES: Record<string, string> = {
  sold: 'bg-green-500/20 text-green-400 border-green-500/30',
  interested: 'bg-blue-500/20 text-blue-400 border-blue-500/30',
  to_follow_up: 'bg-yellow-500/20 text-yellow-400 border-yellow-500/30',
  not_interested: 'bg-red-500/20 text-red-400 border-red-500/30',
  absent: 'bg-gray-500/20 text-gray-300 border-gray-500/30',
  other: 'bg-gray-500/20 text-gray-300 border-gray-500/30',
};

const TH = 'text-left px-4 py-3 text-xs font-semibold text-[#718096] uppercase tracking-wider whitespace-nowrap';

interface FormState {
  prospect_id: string;
  visit_date: string;
  result: string;
  notes: string;
  next_follow_up_at: string;
  address: string;
  latitude: number | null;
  longitude: number | null;
}

const emptyForm = (prospectId = ''): FormState => ({
  prospect_id: prospectId,
  visit_date: toDatetimeLocal(new Date()),
  result: '',
  notes: '',
  next_follow_up_at: '',
  address: '',
  latitude: null,
  longitude: null,
});

export default function VisitsView({ mode }: VisitsViewProps) {
  const isTerrain = mode === 'terrain';
  const [orgId, setOrgId] = useState<string | null>(null);
  const [prospecteurId, setProspecteurId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState('');
  const [visits, setVisits] = useState<VisitRecord[]>([]);
  const [prospects, setProspects] = useState<ProspectOption[]>([]);
  const [names, setNames] = useState<Record<string, string>>({});
  const [search, setSearch] = useState('');
  const [resultFilter, setResultFilter] = useState('');
  const [prospecteurFilter, setProspecteurFilter] = useState('');

  const [open, setOpen] = useState(false);
  const [form, setForm] = useState<FormState>(emptyForm());
  const [formError, setFormError] = useState('');
  const [saving, setSaving] = useState(false);
  const [locating, setLocating] = useState(false);

  const load = useCallback(async () => {
    setLoading(true);
    setError('');
    if (isTerrain) {
      const ctx = await getAuthContext();
      if (!ctx) {
        setError("Vous n'êtes pas connecté.");
        setLoading(false);
        return;
      }
      if (!ctx.prospecteurId || !ctx.prospecteurOrganizationId) {
        setError('Aucun profil prospecteur actif pour ce compte.');
        setLoading(false);
        return;
      }
      setOrgId(ctx.prospecteurOrganizationId);
      setProspecteurId(ctx.prospecteurId);
      const [v, p] = await Promise.all([
        fetchVisits(ctx.prospecteurOrganizationId, ctx.prospecteurId),
        fetchProspectOptions(ctx.prospecteurOrganizationId, ctx.prospecteurId),
      ]);
      if (v.error || p.error) setError(v.error || p.error || '');
      setVisits(v.data);
      setProspects(p.data);
    } else {
      const { orgId: org, error: guardError } = await getAdminOrganization();
      if (!org) {
        setError(guardError ?? 'Accès impossible.');
        setLoading(false);
        return;
      }
      setOrgId(org);
      const [v, n] = await Promise.all([fetchVisits(org), fetchProspecteurNames(org)]);
      if (v.error) setError(v.error);
      setVisits(v.data);
      setNames(n);
    }
    setLoading(false);
  }, [isTerrain]);

  useEffect(() => {
    void load();
  }, [load]);

  const now = useMemo(() => new Date(), [visits, prospects]); // eslint-disable-line react-hooks/exhaustive-deps
  const summary = useMemo(() => summarizeVisits(visits, now), [visits, now]);
  const due = useMemo(() => prospectsDueForFollowUp(prospects, now), [prospects, now]);

  const visible = useMemo(() => {
    const q = search.trim().toLowerCase();
    const qDigits = q.replace(/\D/g, '');
    return visits.filter((v) => {
      if (resultFilter && (v.result ?? 'other') !== resultFilter) return false;
      if (prospecteurFilter && v.prospecteur_id !== prospecteurFilter) return false;
      if (!q) return true;
      return (
        v.contact_name.toLowerCase().includes(q) ||
        (v.notes ?? '').toLowerCase().includes(q) ||
        (v.address ?? '').toLowerCase().includes(q) ||
        (qDigits.length >= 3 && (v.contact_phone ?? '').replace(/\D/g, '').includes(qDigits))
      );
    });
  }, [visits, search, resultFilter, prospecteurFilter]);

  function openCreate(prospectId = '') {
    setForm(emptyForm(prospectId));
    setFormError('');
    setOpen(true);
  }

  function locate() {
    if (typeof navigator === 'undefined' || !navigator.geolocation) {
      setFormError("La géolocalisation n'est pas disponible sur cet appareil.");
      return;
    }
    setLocating(true);
    setFormError('');
    navigator.geolocation.getCurrentPosition(
      (pos) => {
        setForm((f) => ({
          ...f,
          latitude: Math.round(pos.coords.latitude * 1e6) / 1e6,
          longitude: Math.round(pos.coords.longitude * 1e6) / 1e6,
        }));
        setLocating(false);
      },
      () => {
        setLocating(false);
        setFormError("Position introuvable. Autorisez la localisation dans votre navigateur, ou laissez ce champ vide.");
      },
      { enableHighAccuracy: true, timeout: 10_000, maximumAge: 60_000 }
    );
  }

  async function handleSave() {
    if (!orgId || !prospecteurId || saving) return;
    const input = {
      prospect_id: form.prospect_id,
      visit_date: fromDatetimeLocal(form.visit_date),
      result: form.result,
      notes: form.notes,
      next_follow_up_at: fromDatetimeLocal(form.next_follow_up_at),
      address: form.address,
      latitude: form.latitude,
      longitude: form.longitude,
    };
    const problem = validateVisit(input, new Date());
    if (problem) {
      setFormError(problem);
      return;
    }
    setSaving(true);
    const { error: err } = await createVisit(orgId, prospecteurId, input);
    setSaving(false);
    if (err) {
      setFormError(err);
      return;
    }
    toast.success('Visite enregistrée. La fiche du prospect a été mise à jour.');
    setOpen(false);
    void load();
  }

  if (loading && visits.length === 0 && !error) return <LoadingState message="Chargement des visites…" />;
  if (error && visits.length === 0 && prospects.length === 0 && !orgId) {
    return <ErrorState message={error} action={{ label: 'Réessayer', onClick: () => void load() }} />;
  }

  const prospecteurIds = Array.from(new Set(visits.map((v) => v.prospecteur_id)));

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div className="flex flex-col sm:flex-row sm:items-center justify-between gap-3">
        <div>
          <h1 className="text-2xl font-bold text-white">{isTerrain ? 'Mes visites' : 'Visites terrain'}</h1>
          <p className="text-sm text-[#A0AEC0] mt-1">
            {isTerrain ? 'Enregistrez vos visites chez les prospects et suivez vos relances' : 'Activité de visite de vos prospecteurs'}
          </p>
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => void load()}
            disabled={loading}
            aria-label="Actualiser la liste"
            className="flex items-center gap-2 btn-outline-gold px-4 py-2.5 rounded-xl text-sm font-semibold disabled:opacity-50"
          >
            <RefreshCw size={14} className={loading ? 'animate-spin' : ''} />
            Actualiser
          </button>
          {isTerrain && (
            <button onClick={() => openCreate()} className="flex items-center gap-2 btn-gold px-4 py-2.5 rounded-xl text-sm font-bold">
              <Plus size={14} />
              Nouvelle visite
            </button>
          )}
        </div>
      </div> 
      {error && (
        <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300" role="alert">
          {error}
        </div>
      )}

      <div className={`grid grid-cols-1 sm:grid-cols-2 ${isTerrain ? 'xl:grid-cols-4' : 'xl:grid-cols-3'} gap-4`}>
        <MetricCard title="Visites ce mois" value={String(summary.thisMonth)} subtitle={`${summary.total} au total`} icon={<MapPin size={18} />} variant="gold" />
        <MetricCard title="7 derniers jours" value={String(summary.last7Days)} subtitle="visites récentes" icon={<Calendar size={18} />} variant="default" />
        <MetricCard title="Personnes visitées" value={String(summary.distinctProspects)} subtitle="prospects différents" icon={<Users size={18} />} variant="default" />
        {isTerrain && (
          <MetricCard title="À relancer" value={String(due.length)} subtitle="relances échues" icon={<Clock size={18} />} variant={due.length > 0 ? 'warning' : 'success'} />
        )}
      </div>

      {isTerrain && (
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
          <div className="px-5 py-4 border-b border-[#D4AF37]/10 flex items-center gap-2">
            <Clock size={16} className="text-[#D4AF37]" />
            <h2 className="text-sm font-semibold text-white">Prospects à relancer</h2>
            <span className="text-xs text-[#718096]">({due.length})</span>
          </div>
          {due.length === 0 ? (
            <div className="py-8 text-center px-6">
              <CheckCircle size={26} className="mx-auto mb-2 text-[#68D391] opacity-70" />
              <p className="text-sm text-[#A0AEC0]">Aucune relance en retard.</p>
            </div>
          ) : (
            <ul className="divide-y divide-[#D4AF37]/5">
              {due.slice(0, 8).map((p) => {
                const tel = toTelHref(p.phone);
                return (
                  <li key={p.id} className="px-5 py-3 flex flex-col sm:flex-row sm:items-center justify-between gap-2">
                    <div>
                      <p className="text-sm text-white">{p.name}</p>
                      <p className="text-xs text-[#718096]">
                        Relance prévue le {formatDateTimeFr(p.next_follow_up_at)}
                        {p.city ? ` · ${p.city}` : ''}
                      </p>
                    </div>
                    <div className="flex items-center gap-2">
                      {tel && (
                        <a href={tel} aria-label={`Appeler ${p.name}`} className="p-2 rounded-lg bg-[#0B1B3D] border border-[#D4AF37]/20 text-[#D4AF37] hover:bg-[#D4AF37]/10">
                          <Phone size={14} />
                        </a>
                      )}
                      <button onClick={() => openCreate(p.id)} className="px-3 py-2 rounded-lg text-xs font-semibold bg-[#D4AF37]/10 text-[#D4AF37] border border-[#D4AF37]/30 hover:bg-[#D4AF37]/20">
                        Enregistrer une visite
                      </button>
                    </div>
                  </li>
                );
              })}
            </ul>
          )}
        </div>
      )}

      <div className="flex flex-col lg:flex-row gap-3">
        <div className="relative flex-1">
          <Search size={14} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#718096]" />
          <input
            type="text"
            value={search}
            onChange={(e) => setSearch(e.target.value)}
            placeholder="Rechercher un nom, un numéro, un lieu ou une note…"
            aria-label="Rechercher une visite"
            className="w-full bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl pl-9 pr-4 py-2.5 text-white text-sm placeholder-[#718096] focus:outline-none focus:border-[#D4AF37]/60"
          />
        </div>
        <select value={resultFilter} onChange={(e) => setResultFilter(e.target.value)} aria-label="Filtrer par résultat" className={`${inputClass} lg:w-56`}>
          <option value="">Tous les résultats</option>
          {VISIT_RESULTS.map((r) => (
            <option key={r.value} value={r.value}>{r.label}</option>
          ))}
        </select>
        {!isTerrain && (
          <select value={prospecteurFilter} onChange={(e) => setProspecteurFilter(e.target.value)} aria-label="Filtrer par prospecteur" className={`${inputClass} lg:w-56`}>
            <option value="">Tous les prospecteurs</option>
            {prospecteurIds.map((id) => (
              <option key={id} value={id}>{names[id] || 'Prospecteur'}</option>
            ))}
          </select>
        )}
      </div>

      <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
        {visible.length === 0 ? (
          <div className="py-16 text-center px-6">
            <MapPin size={32} className="mx-auto mb-3 text-[#D4AF37] opacity-60" />
            <p className="text-white text-sm font-semibold mb-1">{visits.length === 0 ? 'Aucune visite enregistrée' : 'Aucun résultat'}</p>
            <p className="text-[#A0AEC0] text-sm">
              {visits.length === 0
                ? isTerrain
                  ? 'Enregistrez votre première visite avec « Nouvelle visite ».'
                  : "Les visites saisies par vos prospecteurs apparaîtront ici."
                : 'Modifiez la recherche ou les filtres.'}
            </p>
          </div>
        ) : (
          <div className="overflow-x-auto">
            <table className="w-full">
              <thead>
                <tr className="border-b border-[#D4AF37]/10">
                  {['Date', 'Contact', ...(isTerrain ? [] : ['Prospecteur']), 'Résultat', 'Notes', 'Prochaine relance', 'Lieu'].map((h) => (
                    <th key={h} className={TH}>{h}</th>
                  ))}
                </tr>
              </thead>
              <tbody>
                {visible.map((v) => {
                  const map = mapsUrl(v.latitude, v.longitude);
                  const tel = toTelHref(v.contact_phone);
                  return (
                    <tr key={v.id} className="border-b border-[#D4AF37]/5 hover:bg-[#0B1B3D]/50">
                      <td className="px-4 py-3 text-sm text-[#A0AEC0] whitespace-nowrap">{formatDateTimeFr(v.visit_date)}</td>
                      <td className="px-4 py-3">
                        <p className="text-sm font-medium text-white">{v.contact_name}</p>
                        {v.contact_phone && (tel ? (
                          <a href={tel} className="text-xs text-[#D4AF37] hover:underline">{v.contact_phone}</a>
                        ) : (
                          <p className="text-xs text-[#718096]">{v.contact_phone}</p>
                        ))}
                      </td>                      {!isTerrain && <td className="px-4 py-3 text-sm text-[#A0AEC0] whitespace-nowrap">{names[v.prospecteur_id] || '—'}</td>}
                      <td className="px-4 py-3 whitespace-nowrap">
                        <span className={`inline-flex text-xs font-semibold px-2.5 py-1 rounded-full border ${RESULT_CLASSES[v.result ?? 'other'] ?? RESULT_CLASSES.other}`}>
                          {visitResultLabel(v.result)}
                        </span>
                      </td>
                      <td className="px-4 py-3 text-xs text-[#A0AEC0] max-w-xs break-words">{v.notes || '—'}</td>
                      <td className="px-4 py-3 text-sm text-[#A0AEC0] whitespace-nowrap">{v.next_follow_up_at ? formatDateTimeFr(v.next_follow_up_at) : '—'}</td>
                      <td className="px-4 py-3 text-sm whitespace-nowrap">
                        {map ? (
                          <a href={map} target="_blank" rel="noopener noreferrer" className="inline-flex items-center gap-1 text-[#D4AF37] hover:underline">
                            <MapPin size={12} /> Carte
                          </a>
                        ) : (
                          <span className="text-[#A0AEC0]">{v.address || '—'}</span>
                        )}
                      </td>
                    </tr>
                  );
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>

      {isTerrain && (
        <Modal open={open} onClose={() => !saving && setOpen(false)} title="Nouvelle visite" size="xl">
          <div className="space-y-4">
            {formError && (
              <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-4 py-3 text-sm text-red-300" role="alert">{formError}</div>
            )}
            {prospects.length === 0 && (
              <div className="rounded-xl border border-yellow-500/30 bg-yellow-500/10 px-4 py-3 text-sm text-yellow-200">
                Vous n&apos;avez aucun prospect. Ajoutez-en un dans « Mes prospects » avant d&apos;enregistrer une visite.
              </div>
            )}
            <div>
              <label className={labelClass} htmlFor="v-prospect">Prospect visité *</label>
              <select id="v-prospect" value={form.prospect_id} onChange={(e) => setForm((f) => ({ ...f, prospect_id: e.target.value }))} className={inputClass}>
                <option value="">Choisir…</option>
                {prospects.map((p) => (
                  <option key={p.id} value={p.id}>{p.phone ? `${p.name} — ${p.phone}` : p.name}</option>
                ))}
              </select>
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className={labelClass} htmlFor="v-date">Date et heure *</label>
                <input id="v-date" type="datetime-local" value={form.visit_date} onChange={(e) => setForm((f) => ({ ...f, visit_date: e.target.value }))} className={inputClass} />
              </div>
              <div>
                <label className={labelClass} htmlFor="v-result">Résultat *</label>
                <select id="v-result" value={form.result} onChange={(e) => setForm((f) => ({ ...f, result: e.target.value }))} className={inputClass}>
                  <option value="">Choisir…</option>
                  {VISIT_RESULTS.map((r) => <option key={r.value} value={r.value}>{r.label}</option>)}
                </select>
              </div>
            </div>
            <div>
              <label className={labelClass} htmlFor="v-notes">Notes</label>
              <textarea id="v-notes" value={form.notes} onChange={(e) => setForm((f) => ({ ...f, notes: e.target.value }))} maxLength={2000} rows={3} className={inputClass} />
            </div>
            <div className="grid grid-cols-1 sm:grid-cols-2 gap-4">
              <div>
                <label className={labelClass} htmlFor="v-next">Prochaine relance</label>
                <input id="v-next" type="datetime-local" value={form.next_follow_up_at} onChange={(e) => setForm((f) => ({ ...f, next_follow_up_at: e.target.value }))} className={inputClass} />
              </div>
              <div>
                <label className={labelClass} htmlFor="v-address">Lieu de la visite</label>
                <input id="v-address" value={form.address} onChange={(e) => setForm((f) => ({ ...f, address: e.target.value }))} maxLength={300} className={inputClass} />
              </div>
            </div>
            <div className="flex flex-wrap items-center gap-3">
              <button type="button" onClick={locate} disabled={locating} className="flex items-center gap-2 px-3.5 py-2 rounded-xl text-sm font-semibold bg-[#0B1B3D] text-[#D4AF37] border border-[#D4AF37]/30 hover:bg-[#D4AF37]/10 disabled:opacity-50">
                <MapPin size={14} /> {locating ? 'Localisation…' : 'Enregistrer ma position'}
              </button>
              {form.latitude !== null && form.longitude !== null && (
                <span className="text-xs text-[#A0AEC0]">
                  Position : {form.latitude}, {form.longitude}{' '}
                  <button type="button" onClick={() => setForm((f) => ({ ...f, latitude: null, longitude: null }))} className="underline ml-1">Retirer</button>
                </span>
              )}
              <span className="text-xs text-[#718096]">Facultatif : votre navigateur vous demandera l&apos;autorisation.</span>
            </div>
            <div className="flex justify-end gap-2 pt-2">
              <button onClick={() => setOpen(false)} disabled={saving} className="px-4 py-2.5 rounded-xl text-sm font-semibold bg-[#0B1B3D] text-[#A0AEC0] border border-[#D4AF37]/20 hover:text-white disabled:opacity-50">Annuler</button>
              <button onClick={() => void handleSave()} disabled={saving || prospects.length === 0} className="btn-gold px-5 py-2.5 rounded-xl text-sm font-bold disabled:opacity-50">
                {saving ? 'Enregistrement…' : 'Enregistrer la visite'}
              </button>
            </div>
          </div>
        </Modal>
      )}
    </div>
  );
}
