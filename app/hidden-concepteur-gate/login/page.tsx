'use client';

import React, { useState, useRef, useEffect } from 'react';
import { Eye, EyeOff, Lock, Mail, Shield } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { checkCurrentSuperAdmin } from '@/lib/auth/super-admin';
import AppLogo from '@/components/ui/AppLogo';
import { useRouter } from 'next/navigation';

export default function SuperAdminLoginPage() {
  const router = useRouter();
  const redirected = useRef(false);
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [showPassword, setShowPassword] = useState(false);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  useEffect(() => {
    let active = true;
    const timeout = setTimeout(async () => {
      if (!active || redirected.current) return;
      const result = await checkCurrentSuperAdmin();
      if (result.ok && active && !redirected.current) {
        redirected.current = true;
        router.replace('/hidden-concepteur-gate/dashboard');
      }
    }, 300);
    return () => { active = false; clearTimeout(timeout); };
  }, [router]);

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setError('');
    setLoading(true);
    try {
      const normalizedEmail = email.trim().toLowerCase();
      if (!normalizedEmail || !password) {
        setError('Veuillez renseigner votre adresse email et votre mot de passe.');
        setLoading(false);
        return;
      }
      const { data, error: signInError } = await supabase.auth.signInWithPassword({ email: normalizedEmail, password });
      if (signInError) {
        setError(signInError.message.toLowerCase().includes('invalid login credentials')
          ? 'Identifiants incorrects. Vérifiez votre email et votre mot de passe.'
          : signInError.message);
        setLoading(false);
        return;
      }
      if (!data.user) {
        setError('Impossible de récupérer le compte utilisateur.');
        setLoading(false);
        return;
      }
      await new Promise(resolve => setTimeout(resolve, 120));
      const result = await checkCurrentSuperAdmin();
      if (!result.ok) {
        await supabase.auth.signOut();
        setError(result.reason === 'not_authenticated'
          ? "La session n'a pas pu être établie. Réessayez."
          : result.message || "Ce compte n'est pas autorisé sur le portail Concepteur.");
        setLoading(false);
        return;
      }
      if (!redirected.current) {
        redirected.current = true;
        router.replace('/hidden-concepteur-gate/dashboard');
      }
    } catch (error) {
      console.error('Erreur connexion Concepteur:', error);
      setError('Une erreur inattendue est survenue.');
      setLoading(false);
    }
  }

  return (
    <div className="min-h-screen flex items-center justify-center bg-[#0B1B3D] px-4">
      <div className="w-full max-w-md">
        <div className="flex flex-col items-center mb-8">
          <div className="flex items-center gap-3 mb-3"><AppLogo size={40} /><span className="text-2xl font-bold text-white">JDV <span className="gold-gradient-text">CRM</span></span></div>
          <div className="flex items-center gap-2 text-sm text-[#A0AEC0]"><Shield size={14} /><span>Espace Concepteur — Accès restreint</span></div>
        </div>
        <div className="bg-[#0F2347] border border-[#D4AF37]/20 rounded-2xl p-8 shadow-2xl">
          <h1 className="text-xl font-bold text-white mb-1">Connexion Concepteur</h1>
          <p className="text-sm text-[#A0AEC0] mb-6">Portail de supervision de la plateforme</p>
          {error && <div className="mb-4 p-3 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-sm">{error}</div>}
          <form onSubmit={handleSubmit} className="space-y-4">
            <div><label className="block text-sm font-medium text-[#A0AEC0] mb-1.5">Adresse email</label><div className="relative"><Mail size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#718096]" /><input type="email" value={email} onChange={e => setEmail(e.target.value)} required autoComplete="email" placeholder="votre@email.com" className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl pl-10 pr-4 py-3 text-white placeholder-[#718096] text-sm focus:outline-none focus:border-[#D4AF37]/60 transition-colors" /></div></div>
            <div><label className="block text-sm font-medium text-[#A0AEC0] mb-1.5">Mot de passe</label><div className="relative"><Lock size={16} className="absolute left-3 top-1/2 -translate-y-1/2 text-[#718096]" /><input type={showPassword ? 'text' : 'password'} value={password} onChange={e => setPassword(e.target.value)} required autoComplete="current-password" placeholder="••••••••" className="w-full bg-[#0A1628] border border-[#D4AF37]/20 rounded-xl pl-10 pr-12 py-3 text-white placeholder-[#718096] text-sm focus:outline-none focus:border-[#D4AF37]/60 transition-colors" /><button type="button" tabIndex={-1} aria-label={showPassword ? 'Masquer le mot de passe' : 'Afficher le mot de passe'} onClick={() => setShowPassword(v => !v)} className="absolute right-3 top-1/2 -translate-y-1/2 text-[#718096] hover:text-[#A0AEC0] transition-colors">{showPassword ? <EyeOff size={16} /> : <Eye size={16} />}</button></div></div>
            <button type="submit" disabled={loading} className="w-full btn-gold py-3 rounded-xl font-bold text-sm disabled:opacity-60 disabled:cursor-not-allowed mt-2">{loading ? 'Vérification en cours...' : 'Accéder au portail'}</button>
          </form>
          <div className="mt-6 pt-6 border-t border-[#D4AF37]/10 text-center"><p className="text-xs text-[#718096]">Accès réservé au SUPER ADMIN / CONCEPTEUR autorisé.</p></div>
        </div>
      </div>
    </div>
  );
}
