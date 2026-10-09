'use client';
import React, { useState } from 'react';
import { Check } from 'lucide-react';
import { toast } from 'sonner';
import { supabase } from '@/lib/supabase/client';
import { friendlyAuthError, validateNewPassword } from '@/lib/security/password';
import { inputClass, labelClass } from '@/lib/ui/forms';

/** Changement de mot de passe de l'utilisateur connecté (le mot de passe actuel est revérifié avant tout changement). */
export default function ChangePasswordForm() {
  const [current, setCurrent] = useState('');
  const [next, setNext] = useState('');
  const [confirm, setConfirm] = useState('');
  const [error, setError] = useState('');
  const [saving, setSaving] = useState(false);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    if (saving) return;
    const problem = validateNewPassword(current, next, confirm);
    if (problem) {
      setError(problem);
      return;
    }
    setSaving(true);
    setError('');
    const { data: userData } = await supabase.auth.getUser();
    const email = userData.user?.email;
    if (!email) {
      setSaving(false);
      setError('Session expirée : reconnectez-vous puis réessayez.');
      return;
    }
    // Revérifie le mot de passe actuel : une session laissée ouverte ne suffit pas à prendre le contrôle du compte.
    const { error: checkError } = await supabase.auth.signInWithPassword({ email, password: current });
    if (checkError) {
      setSaving(false);
      setError(friendlyAuthError(checkError.message));
      return;
    }
    const { error: updateError } = await supabase.auth.updateUser({ password: next });
    setSaving(false);
    if (updateError) {
      setError(friendlyAuthError(updateError.message));
      return;
    }
    setCurrent('');
    setNext('');
    setConfirm('');
    toast.success('Mot de passe modifié avec succès.');
  }

  return (
    <form onSubmit={handleSubmit} className="space-y-3" noValidate>
      <h3 className="text-sm font-semibold text-white">Changer mon mot de passe</h3>
      {error && (
        <div className="rounded-xl border border-red-500/30 bg-red-500/10 px-3 py-2 text-xs text-red-300" role="alert">
          {error}
        </div>
      )}
      <div>
        <label className={labelClass} htmlFor="pw-current">Mot de passe actuel</label>
        <input id="pw-current" type="password" autoComplete="current-password" value={current} onChange={(e) => setCurrent(e.target.value)} className={inputClass} />
      </div>
      <div>
        <label className={labelClass} htmlFor="pw-new">Nouveau mot de passe</label>
        <input id="pw-new" type="password" autoComplete="new-password" value={next} onChange={(e) => setNext(e.target.value)} className={inputClass} />
        <p className="text-xs text-[#718096] mt-1">10 caractères minimum, avec au moins une lettre et un chiffre.</p>
      </div>
      <div>
        <label className={labelClass} htmlFor="pw-confirm">Confirmer le nouveau mot de passe</label>
        <input id="pw-confirm" type="password" autoComplete="new-password" value={confirm} onChange={(e) => setConfirm(e.target.value)} className={inputClass} />
      </div>
      <button
        type="submit"
        disabled={saving}
        className="w-full btn-outline-gold py-2.5 rounded-xl font-semibold text-sm flex items-center justify-center gap-2 disabled:opacity-60"
      >
        <Check size={14} />
        {saving ? 'Modification…' : 'Modifier le mot de passe'}
      </button>
    </form>
  );
}
