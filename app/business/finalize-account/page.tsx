'use client';

import { FormEvent, useEffect, useState } from 'react';
import { CheckCircle2, LockKeyhole, ShieldCheck } from 'lucide-react';
import { useRouter } from 'next/navigation';
import { supabase } from '@/lib/supabase/client';

export default function FinalizeAccountPage() {
  const router = useRouter();
  const [applicationId, setApplicationId] = useState('');
  const [ready, setReady] = useState(false);
  const [sessionReady, setSessionReady] = useState(false);
  const [password, setPassword] = useState('');
  const [confirm, setConfirm] = useState('');
  const [loading, setLoading] = useState(false);
  const [message, setMessage] = useState('');

  useEffect(() => {
    const params = new URLSearchParams(window.location.search);
    const id = params.get('application_id') ?? '';
    setApplicationId(id);

    let active = true;
    const finish = async () => {
      await new Promise((resolve) => setTimeout(resolve, 300));
      const { data } = await supabase.auth.getSession();
      if (!active) return;
      setSessionReady(Boolean(data.session));
      setReady(true);
      if (!data.session) setMessage('Le lien est invalide, expiré ou la session de récupération n’a pas été établie. Demandez un nouveau lien au Concepteur.');
    };
    finish();

    const { data: listener } = supabase.auth.onAuthStateChange((_event, session) => {
      if (!active) return;
      if (session) {
        setSessionReady(true);
        setMessage('');
      }
    });

    return () => {
      active = false;
      listener.subscription.unsubscribe();
    };
  }, []);

  async function handleSubmit(event: FormEvent) {
    event.preventDefault();
    if (!applicationId) return setMessage('Identifiant de demande manquant.');
    if (!sessionReady) return setMessage('Votre lien de finalisation n’est plus actif.');
    if (password.length < 8) return setMessage('Le mot de passe doit contenir au moins 8 caractères.');
    if (password !== confirm) return setMessage('Les deux mots de passe ne correspondent pas.');

    setLoading(true);
    setMessage('');
    try {
      const { error: passwordError } = await supabase.auth.updateUser({ password });
      if (passwordError) throw passwordError;

      const { data, error } = await supabase.rpc('jdvcrm_finalize_company_application_v1', {
        p_application_id: applicationId,
      });
      if (error) throw error;

      const row = Array.isArray(data) ? data[0] : data;
      if (!row?.organization_id) throw new Error('Activation de l’entreprise impossible.');

      setMessage('Votre compte entreprise est maintenant actif. Redirection vers votre espace…');
      setTimeout(() => router.replace('/business/dashboard'), 900);
    } catch (error) {
      setMessage(error instanceof Error ? error.message : 'Impossible de finaliser le compte.');
    } finally {
      setLoading(false);
    }
  }

  if (!ready) {
    return <main className="min-h-screen bg-[#07142d] text-white flex items-center justify-center p-6"><p>Vérification du lien de finalisation…</p></main>;
  }

  return (
    <main className="min-h-screen bg-[#07142d] text-white flex items-center justify-center p-6">
      <div className="w-full max-w-lg">
        <div className="rounded-3xl border border-[#D4AF37]/20 bg-[#0F2347] p-8 md:p-10 shadow-2xl">
          <div className="text-center mb-8">
            <div className="mx-auto mb-4 w-14 h-14 rounded-2xl bg-[#D4AF37]/10 flex items-center justify-center"><ShieldCheck className="text-[#D4AF37]" size={30}/></div>
            <p className="text-xs uppercase tracking-[0.2em] text-[#D4AF37] font-semibold">JDV CRM</p>
            <h1 className="text-2xl md:text-3xl font-bold mt-2">Finaliser votre compte entreprise</h1>
            <p className="text-sm text-[#A0AEC0] mt-3 leading-6">Votre demande a été approuvée par le Concepteur. Définissez maintenant votre mot de passe pour activer votre espace.</p>
          </div>

          {message && <div className="mb-5 rounded-xl border border-[#D4AF37]/20 bg-[#D4AF37]/5 p-4 text-sm text-[#E2E8F0]">{message}</div>}

          {sessionReady && (
            <form onSubmit={handleSubmit} className="space-y-5">
              <div>
                <label className="block text-xs uppercase tracking-wide text-[#A0AEC0] mb-2">Nouveau mot de passe</label>
                <div className="relative">
                  <LockKeyhole className="absolute left-3 top-1/2 -translate-y-1/2 text-[#718096]" size={16}/>
                  <input required minLength={8} type="password" value={password} onChange={(e)=>setPassword(e.target.value)} className="w-full rounded-xl bg-[#07142d] border border-[#D4AF37]/20 px-10 py-3 text-white outline-none focus:border-[#D4AF37]/60" placeholder="Minimum 8 caractères"/>
                </div>
              </div>
              <div>
                <label className="block text-xs uppercase tracking-wide text-[#A0AEC0] mb-2">Confirmer le mot de passe</label>
                <input required minLength={8} type="password" value={confirm} onChange={(e)=>setConfirm(e.target.value)} className="w-full rounded-xl bg-[#07142d] border border-[#D4AF37]/20 px-4 py-3 text-white outline-none focus:border-[#D4AF37]/60" placeholder="Retapez votre mot de passe"/>
              </div>
              <button disabled={loading} className="w-full rounded-xl bg-[#D4AF37] text-[#07142d] py-3.5 font-bold disabled:opacity-50">{loading ? 'Activation…' : 'Activer mon compte entreprise'}</button>
            </form>
          )}

          {!sessionReady && ready && <div className="text-center"><CheckCircle2 className="mx-auto mb-3 text-[#D4AF37]" size={30}/><p className="text-sm text-[#A0AEC0]">Contactez le Concepteur pour recevoir un nouveau lien de finalisation.</p></div>}
        </div>
      </div>
    </main>
  );
}
