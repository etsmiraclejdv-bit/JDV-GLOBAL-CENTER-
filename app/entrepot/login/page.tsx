'use client';

import { useState } from 'react';
import { useRouter } from 'next/navigation';
import { Warehouse } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';

export default function EntrepotLoginPage() {
  const router = useRouter();
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');

  async function handleSubmit(e: React.FormEvent) {
    e.preventDefault();
    setLoading(true);
    setError('');
    const { error: signInError } = await supabase.auth.signInWithPassword({ email: email.trim(), password });
    if (signInError) { setLoading(false); setError('Identifiants incorrects.'); return; }
    const { data, error: rpcError } = await supabase.rpc('jdvcrm_my_warehouses_v1');
    if (rpcError || !data || (data as unknown[]).length === 0) {
      await supabase.auth.signOut(); setLoading(false);
      setError("Ce compte n'est rattaché à aucun entrepôt actif. Contactez votre administrateur."); return;
    }
    router.replace('/entrepot/dashboard');
  }

  return (
    <main className="min-h-screen bg-[#07142d] flex items-center justify-center p-6 text-white">
      <form onSubmit={handleSubmit} className="w-full max-w-md rounded-2xl border border-white/10 bg-white/5 p-8 space-y-5">
        <div className="text-center"><Warehouse className="mx-auto text-[#D4AF37]" size={34} /><h1 className="mt-3 text-2xl font-bold">JDV <span className="text-[#D4AF37]">Entrepôt</span></h1><p className="text-slate-400 text-sm mt-1">Espace du responsable d&apos;entrepôt</p></div>
        <label className="block text-sm">Adresse e-mail<input type="email" required autoComplete="email" value={email} onChange={(e) => setEmail(e.target.value)} className="mt-1 w-full rounded-lg bg-[#0F2347] border border-white/10 p-2.5" /></label>
        <label className="block text-sm">Mot de passe<input type="password" required autoComplete="current-password" value={password} onChange={(e) => setPassword(e.target.value)} className="mt-1 w-full rounded-lg bg-[#0F2347] border border-white/10 p-2.5" /></label>
        {error && <div className="rounded-lg border border-red-400/30 bg-red-400/10 p-3 text-sm">{error}</div>}
        <button disabled={loading} className="w-full rounded-lg bg-[#D4AF37] text-[#08152f] font-semibold py-2.5 disabled:opacity-50">{loading ? 'Connexion…' : 'Se connecter'}</button>
      </form>
    </main>
  );
}
