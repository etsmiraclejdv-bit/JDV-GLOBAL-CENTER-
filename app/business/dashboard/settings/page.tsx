'use client';
import React, { useState, useEffect } from 'react';
import { Save, Building2, Palette, Sliders, CreditCard } from 'lucide-react';
import { getCurrentOrgId } from '@/lib/auth/context';
import {
  fetchOrganization,
  updateOrganization,
  fetchOrganizationSettings,
  saveOrganizationSettings,
} from '@/lib/services/settingsService';
import { toast } from 'sonner';
import Link from 'next/link';

type Tab = 'general' | 'personalization' | 'advanced' | 'payment';

export default function BusinessSettingsPage() {
  const [activeTab, setActiveTab] = useState<Tab>('general');
  const [orgId, setOrgId] = useState<string | null>(null);
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [org, setOrg] = useState<Record<string, unknown>>({});

  const [settings, setSettings] = useState<{
    slogan: string;
    email_on_late_payment: boolean;
    sms_on_sale: boolean;
    default_payment_frequency: string;
    require_deposit: boolean;
    low_stock_alert_threshold_percent: number;
  }>({
    slogan: '',
    email_on_late_payment: true,
    sms_on_sale: false,
    default_payment_frequency: 'weekly',
    require_deposit: true,
    low_stock_alert_threshold_percent: 10,
  });

  useEffect(() => {
    let cancelled = false;
    (async () => {
      const oid = await getCurrentOrgId();
      if (cancelled) return;
      if (!oid) {
        setLoading(false);
        return;
      }
      setOrgId(oid);
      const [{ data: orgData }, { data: saved }] = await Promise.all([
        fetchOrganization(oid),
        fetchOrganizationSettings(oid),
      ]);
      if (cancelled) return;
      if (orgData) setOrg(orgData as Record<string, unknown>);
      const s = saved as Record<string, any>;
      setSettings((cur) => ({
        slogan: s.slogan ?? cur.slogan,
        email_on_late_payment: s.notifications?.email_on_late_payment ?? cur.email_on_late_payment,
        sms_on_sale: s.notifications?.sms_on_sale ?? cur.sms_on_sale,
        default_payment_frequency: s.sales?.default_payment_frequency ?? cur.default_payment_frequency,
        require_deposit: s.sales?.require_deposit ?? cur.require_deposit,
        low_stock_alert_threshold_percent: s.stock?.low_stock_alert_threshold_percent ?? cur.low_stock_alert_threshold_percent,
      }));
      setLoading(false);
    })();
    return () => {
      cancelled = true;
    };
  }, []);

  async function handleSavePersonalization() {
    if (!orgId) return;
    setSaving(true);
    const [{ error: e1 }, { error: e2 }] = await Promise.all([
      updateOrganization(orgId, { primary_color: org.primary_color ?? '#D4AF37' }),
      saveOrganizationSettings(orgId, { slogan: settings.slogan }),
    ]);
    setSaving(false);
    const err = e1 ?? e2;
    if (err) toast.error(err.message);
    else toast.success('Personnalisation enregistrée');
  }

  async function handleSaveAdvanced() {
    if (!orgId) return;
    setSaving(true);
    const { error } = await saveOrganizationSettings(orgId, {
      notifications: {
        email_on_late_payment: settings.email_on_late_payment,
        sms_on_sale: settings.sms_on_sale,
      },
      sales: {
        default_payment_frequency: settings.default_payment_frequency,
        require_deposit: settings.require_deposit,
      },
      stock: { low_stock_alert_threshold_percent: settings.low_stock_alert_threshold_percent },
    });
    setSaving(false);
    if (error) toast.error(error.message);
    else toast.success('Paramètres avancés enregistrés');
  }

  async function handleSaveGeneral(e: React.FormEvent) {
    e.preventDefault();
    if (!orgId) return;
    setSaving(true);
    const { error } = await updateOrganization(orgId, {
      name: org.name,
      phone: org.phone,
      address: org.address,
      city: org.city,
      currency: org.currency,
    });
    setSaving(false);
    if (error) toast.error(error.message);
    else toast.success('Paramètres enregistrés');
  }

  const tabs: { id: Tab; label: string; icon: React.ReactNode }[] = [
    { id: 'general', label: 'Général', icon: <Building2 size={14} /> },
    { id: 'personalization', label: 'Personnalisation', icon: <Palette size={14} /> },
    { id: 'advanced', label: 'Avancés', icon: <Sliders size={14} /> },
    { id: 'payment', label: 'Paiement en ligne', icon: <CreditCard size={14} /> },
  ];

  if (loading) return <div className="p-8 text-center text-[#A0AEC0]">Chargement...</div>;

  return (
    <div className="p-6 lg:p-8 space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-white">Paramètres</h1>
        <p className="text-sm text-[#A0AEC0] mt-1">Configuration de votre organisation</p>
      </div>

      {/* Tabs */}
      <div className="flex gap-1 bg-[#0A1628] rounded-xl p-1 w-fit">
        {tabs.map(tab => (
          <button
            key={tab.id}
            onClick={() => setActiveTab(tab.id)}
            className={`flex items-center gap-2 px-4 py-2 rounded-lg text-sm font-medium transition-all ${
              activeTab === tab.id
                ? 'bg-[#D4AF37] text-[#0B1B3D]'
                : 'text-[#A0AEC0] hover:text-white'
            }`}
          >
            {tab.icon}
            <span className="hidden sm:inline">{tab.label}</span>
          </button>
        ))}
      </div>

      {/* General Tab */}
      {activeTab === 'general' && (
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-6">
          <h2 className="text-lg font-semibold text-white mb-5">Informations générales</h2>
          <form onSubmit={handleSaveGeneral} className="space-y-4 max-w-lg">
            <div>
              <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Nom de l&apos;organisation</label>
              <input
                type="text"
                value={(org.name as string) ?? ''}
                onChange={e => setOrg(o => ({ ...o, name: e.target.value }))}
                className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Téléphone</label>
              <input
                type="tel"
                value={(org.phone as string) ?? ''}
                onChange={e => setOrg(o => ({ ...o, phone: e.target.value }))}
                className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
              />
            </div>
            <div>
              <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Adresse</label>
              <input
                type="text"
                value={(org.address as string) ?? ''}
                onChange={e => setOrg(o => ({ ...o, address: e.target.value }))}
                className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
              />
            </div>
            <div className="grid grid-cols-2 gap-3">
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Ville</label>
                <input
                  type="text"
                  value={(org.city as string) ?? ''}
                  onChange={e => setOrg(o => ({ ...o, city: e.target.value }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                />
              </div>
              <div>
                <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Devise</label>
                <select
                  value={(org.currency as string) ?? 'XOF'}
                  onChange={e => setOrg(o => ({ ...o, currency: e.target.value }))}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
                >
                  <option value="XOF">XOF (FCFA)</option>
                  <option value="USD">USD ($)</option>
                  <option value="EUR">EUR (€)</option>
                  <option value="GHS">GHS (₵)</option>
                  <option value="NGN">NGN (₦)</option>
                </select>
              </div>
            </div>
            <button type="submit" disabled={saving} className="flex items-center gap-2 btn-gold px-5 py-2.5 rounded-xl font-semibold text-sm disabled:opacity-60">
              <Save size={14} />
              {saving ? 'Enregistrement...' : 'Enregistrer'}
            </button>
          </form>
        </div>
      )}

      {/* Personalization Tab */}
      {activeTab === 'personalization' && (
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-6">
          <h2 className="text-lg font-semibold text-white mb-5">Personnalisation</h2>
          <p className="text-sm text-[#A0AEC0]">Configurez les couleurs et l&apos;apparence de votre portail.</p>
          <div className="mt-4 space-y-4 max-w-lg">
            <div>
              <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Couleur principale</label>
              <div className="flex items-center gap-3">
                <input
                  type="color"
                  value={(org.primary_color as string) || '#D4AF37'}
                  onChange={e => setOrg(o => ({ ...o, primary_color: e.target.value }))}
                  className="w-10 h-10 rounded-lg border border-[#D4AF37]/20 bg-transparent cursor-pointer"
                />
                <span className="text-sm text-[#A0AEC0]">{((org.primary_color as string) || '#D4AF37').toUpperCase()}</span>
              </div>
            </div>
            <div>
              <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Slogan entreprise</label>
              <input
                type="text"
                value={settings.slogan}
                onChange={e => setSettings(s => ({ ...s, slogan: e.target.value }))}
                placeholder="Votre slogan..."
                className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
              />
            </div>
            <button
              type="button"
              onClick={handleSavePersonalization}
              disabled={saving}
              className="flex items-center gap-2 btn-gold px-5 py-2.5 rounded-xl font-semibold text-sm disabled:opacity-60"
            >
              <Save size={14} />
              {saving ? 'Enregistrement...' : 'Enregistrer'}
            </button>
          </div>
        </div>
      )}

      {/* Advanced Tab */}
      {activeTab === 'advanced' && (
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-6">
          <h2 className="text-lg font-semibold text-white mb-5">Paramètres avancés</h2>
          <div className="space-y-6 max-w-lg">
            <div>
              <h3 className="text-sm font-semibold text-[#D4AF37] mb-3">Notifications</h3>
              <div className="space-y-3">
                <label className="flex items-center justify-between">
                  <span className="text-sm text-[#A0AEC0]">Email en cas de paiement en retard</span>
                  <input
                    type="checkbox"
                    checked={settings.email_on_late_payment}
                    onChange={e => setSettings(s => ({ ...s, email_on_late_payment: e.target.checked }))}
                    className="w-4 h-4 accent-[#D4AF37]"
                  />
                </label>
                <label className="flex items-center justify-between">
                  <span className="text-sm text-[#A0AEC0]">SMS à chaque vente</span>
                  <input
                    type="checkbox"
                    checked={settings.sms_on_sale}
                    onChange={e => setSettings(s => ({ ...s, sms_on_sale: e.target.checked }))}
                    className="w-4 h-4 accent-[#D4AF37]"
                  />
                </label>
              </div>
            </div>
            <div>
              <h3 className="text-sm font-semibold text-[#D4AF37] mb-3">Ventes</h3>
              <div className="space-y-3">
                <div>
                  <label className="block text-xs text-[#A0AEC0] mb-1.5">Fréquence de paiement par défaut</label>
                  <select
                    value={settings.default_payment_frequency}
                    onChange={e => setSettings(s => ({ ...s, default_payment_frequency: e.target.value }))}
                    className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none"
                  >
                    <option value="daily">Journalier</option>
                    <option value="weekly">Hebdomadaire</option>
                    <option value="monthly">Mensuel</option>
                  </select>
                </div>
                <label className="flex items-center justify-between">
                  <span className="text-sm text-[#A0AEC0]">Acompte obligatoire</span>
                  <input
                    type="checkbox"
                    checked={settings.require_deposit}
                    onChange={e => setSettings(s => ({ ...s, require_deposit: e.target.checked }))}
                    className="w-4 h-4 accent-[#D4AF37]"
                  />
                </label>
              </div>
            </div>
            <div>
              <h3 className="text-sm font-semibold text-[#D4AF37] mb-3">Stock</h3>
              <div>
                <label className="block text-xs text-[#A0AEC0] mb-1.5">Seuil d&apos;alerte stock bas (%)</label>
                <input
                  type="number"
                  value={settings.low_stock_alert_threshold_percent}
                  onChange={e => setSettings(s => ({ ...s, low_stock_alert_threshold_percent: Math.min(100, Math.max(1, parseInt(e.target.value) || 1)) }))}
                  min={1}
                  max={100}
                  className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none"
                />
              </div>
            </div>
            <button
              type="button"
              onClick={handleSaveAdvanced}
              disabled={saving}
              className="flex items-center gap-2 btn-gold px-5 py-2.5 rounded-xl font-semibold text-sm disabled:opacity-60"
            >
              <Save size={14} />
              {saving ? 'Enregistrement...' : 'Enregistrer'}
            </button>
          </div>
        </div>
      )}

      {/* Payment Tab */}
      {activeTab === 'payment' && (
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-6">
          <h2 className="text-lg font-semibold text-white mb-2">Paiement en ligne (FedaPay)</h2>
          <p className="text-sm text-[#A0AEC0] mb-5">
            Les clés FedaPay sont gérées par le concepteur de la plateforme. Elles ne sont jamais saisies ni stockées depuis votre navigateur.
          </p>
          <div className="space-y-3 max-w-lg text-sm">
            <div className="flex items-center justify-between rounded-xl bg-[#0A1628] border border-[#D4AF37]/10 px-4 py-3">
              <span className="text-[#A0AEC0]">Abonnement</span>
              <span className="font-semibold text-white">{String(org.subscription_status ?? '—')}</span>
            </div>
            <Link
              href="/payment-wall"
              className="inline-flex items-center gap-2 btn-gold px-5 py-2.5 rounded-xl font-semibold text-sm"
            >
              <CreditCard size={14} />
              Gérer mon abonnement
            </Link>
          </div>
        </div>
      )}
    </div>
  );
}
