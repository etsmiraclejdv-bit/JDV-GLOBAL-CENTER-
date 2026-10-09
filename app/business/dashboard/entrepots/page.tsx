'use client';

import React, { useEffect, useState } from 'react';
import {
  Warehouse,
  Plus,
  MapPin,
  RefreshCw,
  ArrowRightLeft,
  Save,
} from 'lucide-react';
import { toast } from 'sonner';
import { supabase } from '@/lib/supabase/client';
import { fetchOrgProfile } from '@/lib/auth/context';

type Wh = {
  id: string;
  code: string;
  name: string;
  address: string | null;
  city: string | null;
  country: string | null;
  active: boolean;
};

type P = {
  id: string;
  first_name: string;
  last_name: string;
  city: string | null;
  status: string;
};

type A = {
  id: string;
  prospecteur_id: string;
  warehouse_id: string;
  department: string | null;
  city: string | null;
  work_zone: string | null;
  is_primary: boolean;
  active: boolean;
  prospecteurs?: P;
  warehouses?: Wh;
};

const input =
  'w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm';
const label = 'block text-[11px] text-[#A0AEC0] mb-1';

export default function WarehousesPage() {
  const [orgId, setOrgId] = useState<string | null>(null);
  const [warehouses, setWarehouses] = useState<Wh[]>([]);
  const [prospecteurs, setProspecteurs] = useState<P[]>([]);
  const [assignments, setAssignments] = useState<A[]>([]);
  const [loading, setLoading] = useState(true);
  const [showCreate, setShowCreate] = useState(false);
  const [openedWarehouse, setOpenedWarehouse] = useState<string | null>(null);
  const [form, setForm] = useState({
    code: '',
    name: '',
    address: '',
    city: '',
    country: 'Benin',
  });
  const [selected, setSelected] = useState<
    Record<
      string,
      {
        warehouse_id: string;
        department: string;
        city: string;
        work_zone: string;
      }
    >
  >({});
  const [saving, setSaving] = useState<string | null>(null);

  const load = async () => {
    setLoading(true);

    const { data: profile } = await fetchOrgProfile();

    if (!profile?.organization_id) {
      setLoading(false);
      return;
    }

    setOrgId(profile.organization_id);

    const [w, p, a] = await Promise.all([
      supabase
        .from('warehouses')
        .select('id,code,name,address,city,country,active')
        .eq('organization_id', profile.organization_id)
        .order('name'),

      supabase
        .from('prospecteurs')
        .select('id,first_name,last_name,city,status')
        .eq('organization_id', profile.organization_id)
        .eq('status', 'active')
        .order('first_name'),

      supabase
        .from('prospecteur_warehouse_assignments')
        .select(
          'id,prospecteur_id,warehouse_id,department,city,work_zone,is_primary,active,prospecteurs(id,first_name,last_name,city,status),warehouses(id,code,name,address,city,country,active)',
        )
        .eq('organization_id', profile.organization_id)
        .eq('active', true)
        .eq('is_primary', true),
    ]);

    setWarehouses((w.data ?? []) as Wh[]);
    setProspecteurs((p.data ?? []) as P[]);
    setAssignments((a.data ?? []) as A[]);
    setLoading(false);
  };

  useEffect(() => {
    load();
  }, []);

  const create = async (e: React.FormEvent) => {
    e.preventDefault();

    if (!orgId) return;

    const { error } = await supabase.rpc('jdvcrm_create_warehouse_v1', {
      p_organization_id: orgId,
      p_code: form.code,
      p_name: form.name,
      p_address: form.address || null,
      p_city: form.city,
      p_country: form.country || 'Bénin',
    });

    if (error) {
      toast.error(error.message);
      return;
    }

    toast.success('Entrepôt créé');
    setForm({
      code: '',
      name: '',
      address: '',
      city: '',
      country: 'Benin',
    });
    setShowCreate(false);
    load();
  };

  const assign = async (pid: string) => {
    if (!orgId) return;
    const v = selected[pid];
    if (!v?.warehouse_id) {
      toast.error('Choisissez un entrepôt');
      return;
    }

    setSaving(pid);
    const { error } = await supabase.rpc('jdvcrm_assign_prospecteur_warehouse_v1', {
      p_organization_id: orgId,
      p_prospecteur_id: pid,
      p_warehouse_id: v.warehouse_id,
      p_department: v.department || null,
      p_city: v.city || null,
      p_work_zone: v.work_zone || null,
    });
    setSaving(null);

    if (error) {
      toast.error(error.message);
      return;
    }

    toast.success('Affectation enregistrée');
    await load();
  };

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div className="flex justify-between items-start">
        <div>
          <div className="flex items-center gap-2">
            <Warehouse className="text-[#D4AF37]" />
            <h1 className="text-2xl font-bold text-white">
              Entrepôts & affectation terrain
            </h1>
          </div>
          <p className="text-sm text-[#A0AEC0] mt-1">
            L’administrateur décide où chaque prospecteur travaille et de quel
            entrepôt il s’approvisionne.
          </p>
        </div>

        <div className="flex gap-2">
          <button
            type="button"
            onClick={load}
            className="p-2.5 rounded-xl border border-[#D4AF37]/20 text-[#A0AEC0]"
          >
            <RefreshCw size={16} />
          </button>

          <button
            type="button"
            onClick={() => setShowCreate((v) => !v)}
            className="btn-gold px-4 py-2 rounded-xl text-sm font-bold"
          >
            <Plus size={15} className="inline mr-1" />
            Nouvel entrepôt
          </button>
        </div>
      </div>

      {showCreate && (
        <form
          onSubmit={create}
          className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5 grid md:grid-cols-5 gap-3"
        >
          <input
            required
            placeholder="Code"
            value={form.code}
            onChange={(e) => setForm({ ...form, code: e.target.value })}
            className={input}
          />
          <input
            required
            placeholder="Nom de l’entrepôt"
            value={form.name}
            onChange={(e) => setForm({ ...form, name: e.target.value })}
            className={input}
          />
          <input
            placeholder="Adresse"
            value={form.address}
            onChange={(e) => setForm({ ...form, address: e.target.value })}
            className={input}
          />
          <input
            required
            placeholder="Ville"
            value={form.city}
            onChange={(e) => setForm({ ...form, city: e.target.value })}
            className={input}
          />
          <button type="submit" className="btn-gold rounded-xl">
            <Save size={15} className="inline mr-1" />
            Créer
          </button>
        </form>
      )}

      {loading ? (
        <div className="text-[#A0AEC0]">Chargement…</div>
      ) : (
        <>
          <div className="grid md:grid-cols-3 gap-4">
            {warehouses.map((w) => (
              <button
                type="button"
                key={w.id}
                onClick={() => setOpenedWarehouse(w.id)}
                className={
                  'text-left bg-[#0F2347] border rounded-2xl p-4 transition-all ' +
                  (openedWarehouse === w.id
                    ? 'border-[#D4AF37]/60 bg-[#D4AF37]/5'
                    : 'border-[#D4AF37]/15 hover:border-[#D4AF37]/40')
                }
              >
                <div className="flex justify-between">
                  <b className="text-white">{w.name}</b>
                  <span className="text-xs text-[#D4AF37]">{w.code}</span>
                </div>
                <p className="text-xs text-[#A0AEC0] mt-2">
                  <MapPin size={12} className="inline" />{' '}
                  {w.address || w.city || 'Adresse non renseignée'}
                </p>
                <p className="text-[11px] text-[#718096] mt-3">
                  Ouvrir le détail →
                </p>
              </button>
            ))}
          </div>

          {openedWarehouse && (
            <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-5 space-y-4">
              {(() => {
                const w = warehouses.find((x) => x.id === openedWarehouse);
                const members = assignments.filter(
                  (x) => x.warehouse_id === openedWarehouse,
                );

                if (!w) return null;

                return (
                  <>
                    <div className="flex justify-between items-start">
                      <div>
                        <p className="text-xs uppercase tracking-widest text-[#D4AF37]">
                          Système de l'entrepôt
                        </p>
                        <h2 className="text-lg font-bold text-white">
                          {w.name}
                        </h2>
                        <p className="text-xs text-[#A0AEC0]">
                          {w.code} · {w.city || 'Ville non renseignée'} ·{' '}
                          {w.address || 'Adresse non renseignée'}
                        </p>
                      </div>

                      <button
                        type="button"
                        onClick={() => setOpenedWarehouse(null)}
                        className="text-xs text-[#A0AEC0] hover:text-white"
                      >
                        Fermer
                      </button>
                    </div>

                    <div>
                      <h3 className="text-sm font-semibold text-white mb-2">
                        Prospecteurs affectés
                      </h3>

                      {members.length === 0 ? (
                        <p className="text-sm text-[#718096]">
                          Aucun prospecteur affecté à cet entrepôt.
                        </p>
                      ) : (
                        <div className="space-y-2">
                          {members.map((a) => (
                            <div
                              key={a.id}
                              className="flex items-center justify-between p-3 rounded-xl bg-[#0A1628] border border-[#D4AF37]/10"
                            >
                              <div>
                                <p className="text-sm font-semibold text-white">
                                  {a.prospecteurs?.first_name}{' '}
                                  {a.prospecteurs?.last_name}
                                </p>
                                <p className="text-xs text-[#718096]">
                                  {a.department || 'Département non renseigné'}{' '}
                                  · {a.city || 'Ville non renseignée'} ·{' '}
                                  {a.work_zone || 'Zone non renseignée'}
                                </p>
                              </div>
                              <span className="text-xs text-emerald-300">
                                Affecté{a.is_primary ? ' · principal' : ''}
                              </span>
                            </div>
                          ))}
                        </div>
                      )}
                    </div>
                  </>
                );
              })()}
            </div>
          )}

          <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl overflow-hidden">
            <div className="p-4 border-b border-[#D4AF37]/10">
              <h2 className="font-semibold text-white">
                Affecter / déplacer un prospecteur
              </h2>
              <p className="text-xs text-[#718096] mt-1">
                Un seul entrepôt principal actif par prospecteur. Une nouvelle
                affectation désactive automatiquement l’ancienne.
              </p>
            </div>

            <div className="divide-y divide-[#D4AF37]/10">
              {prospecteurs.map((p) => {
                const a = assignments.find(
                  (x) => x.prospecteur_id === p.id,
                );
                const v = selected[p.id] ?? {
                  warehouse_id: a?.warehouse_id ?? '',
                  department: a?.department ?? '',
                  city: a?.city ?? p.city ?? '',
                  work_zone: a?.work_zone ?? '',
                };

                return (
                  <div
                    key={p.id}
                    className="p-4 grid lg:grid-cols-6 gap-3 items-end"
                  >
                    <div>
                      <p className="text-sm font-semibold text-white">
                        {p.first_name} {p.last_name}
                      </p>
                      <p className="text-xs text-[#718096]">
                        {a?.warehouses?.name ?? 'Aucun entrepôt'}
                      </p>
                    </div>

                    <div>
                      <label className={label}>Entrepôt</label>
                      <select
                        value={v.warehouse_id}
                        onChange={(e) =>
                          setSelected((s) => ({
                            ...s,
                            [p.id]: {
                              ...v,
                              warehouse_id: e.target.value,
                            },
                          }))
                        }
                        className={input}
                      >
                        <option value="">Choisir…</option>
                        {warehouses.map((w) => (
                          <option key={w.id} value={w.id}>
                            {w.name} — {w.city}
                          </option>
                        ))}
                      </select>
                    </div>

                    <div>
                      <label className={label}>Département</label>
                      <input
                        value={v.department}
                        onChange={(e) =>
                          setSelected((s) => ({
                            ...s,
                            [p.id]: {
                              ...v,
                              department: e.target.value,
                            },
                          }))
                        }
                        className={input}
                        placeholder="Département"
                      />
                    </div>

                    <div>
                      <label className={label}>Ville</label>
                      <input
                        value={v.city}
                        onChange={(e) =>
                          setSelected((s) => ({
                            ...s,
                            [p.id]: {
                              ...v,
                              city: e.target.value,
                            },
                          }))
                        }
                        className={input}
                        placeholder="Ville"
                      />
                    </div>

                    <div>
                      <label className={label}>Zone / secteur</label>
                      <input
                        value={v.work_zone}
                        onChange={(e) =>
                          setSelected((s) => ({
                            ...s,
                            [p.id]: {
                              ...v,
                              work_zone: e.target.value,
                            },
                          }))
                        }
                        className={input}
                        placeholder="Zone A, quartier…"
                      />
                    </div>

                    <button
                      type="button"
                      disabled={saving === p.id}
                      onClick={() => assign(p.id)}
                      className="btn-gold rounded-xl py-2.5 disabled:opacity-50"
                    >
                      {saving === p.id ? (
                        '…'
                      ) : (
                        <>
                          <ArrowRightLeft
                            size={15}
                            className="inline mr-1"
                          />
                          Affecter
                        </>
                      )}
                    </button>
                  </div>
                );
              })}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
