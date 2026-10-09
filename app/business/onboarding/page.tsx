'use client';

import { useCallback, useEffect, useState } from 'react';
import { AlertCircle, CheckCircle2, FileText, Loader2, ShieldCheck, UploadCloud, XCircle } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { useRouter } from 'next/navigation';

const docs = [
  ['identity', 'Pièce d’identité du représentant'],
  ['rccm', 'RCCM / registre de commerce'],
  ['ifu', 'IFU / document fiscal'],
  ['incorporation', 'Acte constitutif / création'],
  ['statutes', 'Statuts'],
  ['mandate', 'Mandat / pouvoir si nécessaire'],
  ['address_proof', 'Justificatif d’adresse'],
] as const;
const MAX_FILE_SIZE = 8 * 1024 * 1024;
const ACCEPTED_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'application/pdf'];

type ValidationState = {
  identity?: { status?: string; reasons?: string[]; attempts?: number };
  documents?: Array<{ type: string; status: string; reason?: string | null; document_id?: string | null; name?: string | null }>;
  can_validate?: boolean;
};

export default function CompanyOnboardingPage() {
  const router = useRouter();
  const [app, setApp] = useState<any>(null);
  const [files, setFiles] = useState<Record<string, File | null>>({});
  const [validation, setValidation] = useState<ValidationState | null>(null);
  const [loading, setLoading] = useState(true);
  const [busy, setBusy] = useState('');
  const [error, setError] = useState('');
  const [notice, setNotice] = useState('');

  const refreshValidation = useCallback(async (applicationId: string) => {
    const { data, error: rpcError } = await supabase.rpc('jdvcrm_my_company_validation_v1', {
      p_application_id: applicationId,
    });
    if (rpcError) throw rpcError;
    setValidation(data as ValidationState);
    return data as ValidationState;
  }, []);

  useEffect(() => {
    let cancelled = false;
    (async () => {
      try {
        const { data: { user } } = await supabase.auth.getUser();
        if (!user) { router.replace('/business/login'); return; }
        const { data, error: queryError } = await supabase
          .from('organization_applications')
          .select('id,company_name,status,professional_email,company_nature,company_size')
          .eq('applicant_user_id', user.id)
          .order('created_at', { ascending: false })
          .limit(1)
          .maybeSingle();
        if (queryError) throw queryError;
        if (!data) throw new Error('Aucun dossier d’entreprise trouvé. Revenez à l’inscription pour créer votre dossier.');
        if (cancelled) return;
        setApp(data);
        await refreshValidation(data.id);
      } catch (e) {
        if (!cancelled) setError(e instanceof Error ? e.message : 'Impossible de charger le dossier.');
      } finally {
        if (!cancelled) setLoading(false);
      }
    })();
    return () => { cancelled = true; };
  }, [router, refreshValidation]);

  async function reviewIdentity() {
    if (!app) return;
    setBusy('identity'); setError(''); setNotice('');
    try {
      const { data, error: invokeError } = await supabase.functions.invoke('company-ai-review', {
        body: { application_id: app.id, stage: 'identity' },
      });
      if (invokeError) throw invokeError;
      if (data?.status === 'approved') setNotice('Identité approuvée. Vous pouvez maintenant transmettre les documents.');
      else if (data?.status === 'refused') setError((data.reasons || ['Identité refusée. Corrigez les informations du dossier puis réessayez.']).join(' '));
      else setNotice(data?.message || 'Résultat reçu. Actualisez le dossier pour consulter le statut.');
      await refreshValidation(app.id);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'La vérification de l’identité a échoué.');
    } finally { setBusy(''); }
  }

  async function uploadDocument(type: string, label: string) {
    const file = files[type];
    if (!app || !file) { setError('Choisissez d’abord un fichier.'); return; }
    if (!ACCEPTED_TYPES.includes(file.type)) { setError('Format refusé. Utilisez JPG, PNG, WEBP ou PDF.'); return; }
    if (file.size > MAX_FILE_SIZE) { setError('Le fichier dépasse la limite de 8 Mo.'); return; }
    setBusy(type); setError(''); setNotice('');
    try {
      const { data: { user } } = await supabase.auth.getUser();
      if (!user) throw new Error('Session expirée. Reconnectez-vous.');
      const safeName = file.name.replace(/[^\w.\-]/g, '_');
      const path = user.id + '/' + app.id + '/' + Date.now() + '-' + safeName;
      const { error: storageError } = await supabase.storage.from('company-kyb-documents').upload(path, file, {
        upsert: false, contentType: file.type,
      });
      if (storageError) throw storageError;
      const { data: doc, error: insertError } = await supabase
        .from('organization_application_documents')
        .insert({
          application_id: app.id, document_type: type, document_name: file.name,
          storage_path: path, mime_type: file.type, file_size: file.size, uploaded_by: user.id,
        })
        .select('id')
        .single();
      if (insertError) throw insertError;
      const { data: verdict, error: reviewError } = await supabase.functions.invoke('company-ai-review', {
        body: { application_id: app.id, stage: 'document', document_id: doc.id },
      });
      if (reviewError) throw reviewError;
      if (verdict?.status === 'verified') setNotice(label + ' : document vérifié.');
      else if (verdict?.status === 'rejected') setNotice(label + ' : document refusé. ' + (verdict.reason || 'Envoyez un nouveau fichier.'));
      else if (verdict?.status === 'needs_review') setNotice(verdict.message || 'Document reçu, en attente de contrôle par l’équipe JDV.');
      else setNotice('Document transmis. Actualisation de son statut…');
      setFiles(current => ({ ...current, [type]: null }));
      await refreshValidation(app.id);
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Échec de l’envoi ou du contrôle du document.');
    } finally { setBusy(''); }
  }

  async function validateCompany() {
    if (!app || !validation?.can_validate) return;
    setBusy('activate'); setError(''); setNotice('');
    try {
      const { data, error: rpcError } = await supabase.rpc('jdvcrm_validate_my_company_v1', {
        p_application_id: app.id,
      });
      if (rpcError) throw rpcError;
      if (!data || (Array.isArray(data) && !data[0])) throw new Error('La validation n’a pas renvoyé de confirmation.');
      router.replace('/business/dashboard');
    } catch (e) {
      setError(e instanceof Error ? e.message : 'Impossible de valider l’entreprise pour le moment.');
    } finally { setBusy(''); }
  }

  if (loading) return <div className="min-h-screen bg-[#0B1B3D] text-white grid place-items-center"><Loader2 className="animate-spin mr-2" />Chargement du dossier…</div>;

  const identityStatus = validation?.identity?.status || 'pending';
  const statusLabel: Record<string, string> = {
    missing: 'Manquant', pending: 'En attente', analyzing: 'Analyse en cours',
    verified: 'Vérifié', approved: 'Approuvée', rejected: 'Refusé',
    refused: 'Refusée', stale: 'À renvoyer', needs_review: 'En attente de contrôle',
  };
  const statusClass = (status: string) =>
    ['verified', 'approved'].includes(status) ? 'text-emerald-300' :
    ['rejected', 'refused'].includes(status) ? 'text-red-300' :
    status === 'needs_review' ? 'text-amber-300' : 'text-slate-300';

  return (
    <main className="min-h-screen bg-[#0B1B3D] text-white px-4 py-10">
      <div className="max-w-5xl mx-auto">
        <header className="mb-8">
          <p className="text-[#D4AF37] text-xs uppercase tracking-widest">Activation sécurisée · JDV CRM</p>
          <h1 className="text-3xl font-bold mt-2">Validation de {app?.company_name || 'votre entreprise'}</h1>
          <p className="text-slate-300 mt-2">Suivez les trois étapes. L’entreprise ne sera activée que lorsque les contrôles requis seront validés.</p>
        </header>

        {error && <div role="alert" className="mb-4 p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-200 flex gap-2"><AlertCircle className="shrink-0" size={19}/><span>{error}</span></div>}
        {notice && <div role="status" className="mb-4 p-4 rounded-xl bg-[#D4AF37]/10 border border-[#D4AF37]/30 text-amber-100">{notice}</div>}

        <section className="grid md:grid-cols-3 gap-3 mb-6">
          <div className="rounded-2xl border border-[#D4AF37]/30 bg-[#0F2347] p-5"><span className="text-xs text-[#D4AF37]">ÉTAPE 1</span><h2 className="font-bold mt-2">Identité de l’entreprise</h2><p className={'text-sm mt-2 ' + statusClass(identityStatus)}>{statusLabel[identityStatus] || identityStatus}</p><p className="text-xs text-slate-400 mt-2">Essais : {validation?.identity?.attempts ?? 0} / 10</p><button onClick={reviewIdentity} disabled={!!busy || identityStatus === 'approved'} className="mt-4 w-full rounded-lg bg-[#D4AF37] text-[#0B1B3D] p-3 font-semibold disabled:opacity-50">{busy === 'identity' ? 'Vérification…' : identityStatus === 'approved' ? 'Identité approuvée' : 'Vérifier mon identité'}</button>{validation?.identity?.reasons?.length ? <ul className="mt-3 list-disc pl-5 text-sm text-red-200">{validation.identity.reasons.map((reason, i) => <li key={i}>{reason}</li>)}</ul> : null}</div>
          <div className="rounded-2xl border border-[#D4AF37]/30 bg-[#0F2347] p-5"><span className="text-xs text-[#D4AF37]">ÉTAPE 2</span><h2 className="font-bold mt-2">Documents justificatifs</h2><p className="text-sm text-slate-300 mt-2">PDF, JPG, PNG ou WEBP · 8 Mo maximum par fichier.</p><p className="text-xs text-slate-400 mt-2">Un document refusé peut être remplacé par un nouveau fichier du même type.</p></div>
          <div className="rounded-2xl border border-[#D4AF37]/30 bg-[#0F2347] p-5"><span className="text-xs text-[#D4AF37]">ÉTAPE 3</span><h2 className="font-bold mt-2">Activation</h2><p className="text-sm mt-2 text-slate-300">{validation?.can_validate ? 'Tous les contrôles requis sont au vert.' : 'Disponible après validation de tous les contrôles requis.'}</p><button onClick={validateCompany} disabled={!!busy || !validation?.can_validate} className="mt-4 w-full rounded-lg bg-emerald-500 text-slate-950 p-3 font-bold disabled:opacity-40">{busy === 'activate' ? 'Activation…' : 'Valider mon entreprise'}</button></div>
        </section>

        <section className="rounded-2xl border border-[#D4AF37]/20 bg-[#0F2347] p-5 md:p-7">
          <h2 className="text-xl font-bold mb-4">Pièces à transmettre</h2>
          <div className="space-y-4">
            {docs.map(([type, label]) => {
              const current = validation?.documents?.find(document => document.type === type);
              const status = current?.status || 'missing';
              const selectedFile = files[type];
              return <div key={type} className="rounded-xl border border-white/10 p-4">
                <div className="flex flex-wrap items-center justify-between gap-2 mb-3">
                  <div className="flex items-center gap-2"><FileText size={18} className="text-[#D4AF37]"/><span className="font-semibold">{label}</span></div>
                  <span className={'text-sm flex items-center gap-1 ' + statusClass(status)}>{status === 'verified' ? <CheckCircle2 size={16}/> : ['rejected', 'refused'].includes(status) ? <XCircle size={16}/> : null}{statusLabel[status] || status}</span>
                </div>
                {current?.reason && <p className="text-sm text-red-200 mb-3">{current.reason}</p>}
                {status === 'verified' ? <p className="text-sm text-emerald-200">Document contrôlé avec succès.</p> : <div className="flex flex-col sm:flex-row gap-3">
                  <label className="flex-1 cursor-pointer rounded-lg border border-dashed border-white/20 p-3 text-sm text-slate-300"><span className="flex items-center gap-2"><UploadCloud size={17}/>{selectedFile?.name || 'Choisir un nouveau fichier'}</span><input type="file" accept=".pdf,image/jpeg,image/png,image/webp" className="hidden" onChange={event => { const file = event.target.files?.[0] || null; setFiles(old => ({ ...old, [type]: file })); event.currentTarget.value = ''; setError(''); }}/></label>
                  <button onClick={() => uploadDocument(type, label)} disabled={!selectedFile || !!busy || identityStatus !== 'approved'} className="rounded-lg bg-[#D4AF37] text-[#0B1B3D] px-5 py-3 font-semibold disabled:opacity-40">{busy === type ? 'Envoi et contrôle…' : 'Envoyer et vérifier'}</button>
                </div>}
              </div>;
            })}
          </div>
          <div className="mt-6 flex items-start gap-3 text-sm text-slate-400"><ShieldCheck className="text-[#D4AF37] shrink-0" size={20}/><p>Les fichiers sont stockés dans un espace privé. L’activation dépend exclusivement du résultat des contrôles côté Supabase.</p></div>
        </section>
      </div>
    </main>
  );
}
