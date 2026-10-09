'use client';
import React, { useState, useEffect } from 'react';
import { User, Save, X } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { fetchProfile, updateProfile } from '@/lib/services/settingsService';
import { toast } from 'sonner';
import ChangePasswordForm from '@/components/ChangePasswordForm';
// Language switcher removed — preferred_language not in profiles schema

interface UserProfilePanelProps {
  onClose?: () => void;
}

export default function UserProfilePanel({ onClose }: UserProfilePanelProps) {
  const [loading, setLoading] = useState(true);
  const [saving, setSaving] = useState(false);
  const [userId, setUserId] = useState<string | null>(null);
  const [form, setForm] = useState({
    full_name: '',
    phone: '',
  });

  useEffect(() => {
    supabase.auth.getUser().then(async ({ data }) => {
      if (data.user) {
        setUserId(data.user.id);
        const { data: profile } = await fetchProfile(data.user.id);
        if (profile) {
          setForm({
            full_name: profile.full_name ?? '',
            phone: profile.phone ?? '',
          });
        }
        setLoading(false);
      }
    });
  }, []);

  async function handleSave(e: React.FormEvent) {
    e.preventDefault();
    if (!userId) return;
    setSaving(true);
    const { error } = await updateProfile(userId, form);
    setSaving(false);
    if (error) {
      toast.error('Erreur lors de la mise à jour du profil');
    } else {
      toast.success('Profil mis à jour avec succès');
      onClose?.();
    }
  }

  if (loading) {
    return (
      <div className="p-6 text-center text-[#A0AEC0] text-sm">Chargement...</div>
    );
  }

  return (
    <div className="p-6 w-full max-w-sm">
      <div className="flex items-center justify-between mb-6">
        <h2 className="text-lg font-bold text-white">Mon profil</h2>
        {onClose && (
          <button onClick={onClose} className="text-[#718096] hover:text-white">
            <X size={18} />
          </button>
        )}
      </div>

      {/* Avatar */}
      <div className="flex justify-center mb-6">
        <div className="relative">
          <div className="w-20 h-20 rounded-full bg-[#0A1628] border-2 border-[#D4AF37]/30 flex items-center justify-center">
            <User size={32} className="text-[#D4AF37]" />
          </div>
        </div>
      </div>

      <form onSubmit={handleSave} className="space-y-4">
        <div>
          <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Nom complet</label>
          <input
            type="text"
            value={form.full_name}
            onChange={e => setForm(f => ({ ...f, full_name: e.target.value }))}
            className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
            placeholder="Votre nom complet"
          />
        </div>

        <div>
          <label className="block text-xs font-medium text-[#A0AEC0] mb-1.5">Téléphone</label>
          <input
            type="tel"
            value={form.phone}
            onChange={e => setForm(f => ({ ...f, phone: e.target.value }))}
            className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl px-3 py-2.5 text-white text-sm focus:outline-none focus:border-[#D4AF37]/60"
            placeholder="+225 07 00 00 00"
          />
        </div>

        <button
          type="submit"
          disabled={saving}
          className="w-full btn-gold py-2.5 rounded-xl font-semibold text-sm flex items-center justify-center gap-2 disabled:opacity-60"
        >
          <Save size={14} />
          {saving ? 'Enregistrement...' : 'Enregistrer'}
        </button>
      </form>

      <div className="mt-8 pt-6 border-t border-[#D4AF37]/10">
        <ChangePasswordForm />
      </div>
    </div>
  );
}
