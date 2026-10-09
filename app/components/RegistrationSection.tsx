'use client';

import React, { useEffect, useMemo, useState } from 'react';
import { useForm } from 'react-hook-form';
import { toast } from 'sonner';
import { Building2, Mail, Lock, Phone, Globe, MapPin, Briefcase, Eye, EyeOff, CheckCircle, FileText, UserRound, UsersRound } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import Link from 'next/link';

type FormData = {
  organizationName: string; legalName: string; legalForm: string; companyNature: string; legalStatus: string;
  primarySectorId: string; country: string; city: string; address: string; website: string; phone: string;
  registrationNumber: string; taxNumber: string; professionalEmail: string;
  representativeFirstName: string; representativeLastName: string; representativeRole: string;
  representativePhone: string; representativeNationality: string; representativeBirthDate: string;
  peopleCount: string; associateCount: string; managerCount: string; companySize: string;
  password: string; confirmPassword: string; termsAccepted: boolean;
};

const countries = ['Bénin','Togo','Côte d’Ivoire','Sénégal','Ghana','Mali','Burkina Faso','Niger','Guinée','Cameroun','Nigeria','Autre'];
const natures = [
  ['sole_proprietorship','Entreprise individuelle'],['company','Société'],['association','Association / organisation'],
  ['cooperative','Coopérative'],['public_company','Entreprise publique'],['state_entity','Organisme d’État'],['ngo','ONG'],['other','Autre']
];
const legalForms = ['Entreprise individuelle','SARL','SA','SAS','SASU','GIE','Coopérative','Association','ONG','Établissement public','Autre'];

export default function RegistrationSection() {
  const defaultSectors = [
    ['3000fa16-cca6-4ccc-bda3-31ff9c23949c','Industrie & fabrication'],['8b10e093-7a4e-4b18-bfcf-729be2ef6b67','Énergie & électricité'],['a76dd249-f18e-47f5-a9fb-fb640924d49c','BTP & construction'],['267aa018-7372-46e9-aa67-83b8f919330b','Immobilier'],['e4b73b8a-8527-4440-833d-e1f431548bf3','Commerce & distribution'],['d05c0ff6-5df3-4e34-aec5-e77b90ecb40b','Agriculture'],['fa47beed-dd19-4c34-be8f-7f9a43a910da','Élevage'],['3c26bc8d-a56a-4812-a546-02fa826ffd88','Pêche & aquaculture'],['1e26ce68-aaab-4de3-9e04-a9f8c13da91c','Informatique & technologies'],['2bbfce77-f579-4254-bb27-81d1f054d806','Télécommunications'],['dfde2b22-7a4a-4714-8179-becababe7c7a','Banque, finance & assurance'],['fd676883-a9f8-4277-be09-672bcf3bcda1','Santé & pharmacie'],['330ef158-fe73-4aa1-81a8-8fa3e1afe96d','Éducation & formation'],['492f4084-9018-4d6e-8039-b4b55f5d907e','Hôtellerie & restauration'],['2bd6d734-0314-4be1-b0b5-ebc22fbeab35','Tourisme & voyages'],['f80e93f5-9c74-4087-8d99-5dee5c2de428','Mode & textile'],['aea7bbc6-f38c-4160-aea7-3a108f51567a','Beauté & cosmétique'],['2586cb52-983a-480c-becf-a4f11d456e13','Agroalimentaire'],['ca9815fc-4f2d-49c6-a755-7ceb74a634b2','Environnement'],['ba764ad4-f643-455b-bf7e-8acda05234b0','Énergies renouvelables'],['b2f461f6-7f47-4403-ad0e-134ad3cdffdc','Chimie & laboratoire'],['53fc0a2a-520a-4f48-8ae6-2ebde03356f4','Mines & carrières'],['219205d4-caf9-4261-a6bb-16c74d1ed35e','Services juridiques'],['9c921735-35a0-4ac9-ab53-4fc00e693131','Conseil & services professionnels'],['50ad3f64-741f-42f9-b0f3-e6cd663143da','Communication & marketing'],['72fdeb02-8c83-47ad-83f9-20c3749805df','Arts, culture & création'],['aedc0392-2cb7-41f6-9d42-0d35781816d1','Médias & divertissement'],['eb6fe343-0513-4e4c-ade7-c3a379219d01','Administration & secteur public'],['50d1e87e-a607-4887-ac8e-d2a29ecc5c09','ONG, associations & organisations'],['060cbc06-38ea-45c2-a57c-fb22430b5e73','Recherche & développement'],['d6fb3488-50df-4f11-b16d-e9d4b0e53707','Services aux entreprises et particuliers'],['cb5f1442-d9ef-4c4f-98dd-28ac039bb09f','E-commerce'],['90641afd-dbcb-4d0c-8736-492a5416e117','Maintenance & réparation'],['3e2fe2a8-b555-4e84-a031-8da594b34ee8','Eau & assainissement'],['af752e70-dc83-456d-8ee0-9ccde4acf828','Autre secteur']
  ].map(([id,name])=>({id,name,icon:null}));
  const [sectors,setSectors]=useState<{id:string;name:string;icon:string|null}[]>(defaultSectors);
  const [showPassword,setShowPassword]=useState(false),[showConfirm,setShowConfirm]=useState(false);
  const [loading,setLoading]=useState(false),[submitted,setSubmitted]=useState(false),[error,setError]=useState('');
  const {register,handleSubmit,watch,formState:{errors}}=useForm<FormData>();
  const password=watch('password');

  useEffect(()=>{supabase.from('company_sectors').select('id,name,icon').eq('active',true).order('sort_order').then(({data,error})=>{if(error){console.warn('company_sectors indisponible, secteurs de secours utilisés.',error);return;}if(data?.length)setSectors(data as typeof sectors);});},[]);

  const sectorOptions=useMemo(()=>sectors.map(s=><option key={s.id} value={s.id}>{s.name}</option>),[sectors]);

  async function onSubmit(d:FormData){
    setLoading(true);setError('');
    try{
      const payload={
        p_company_name:d.organizationName,p_legal_name:d.legalName,p_legal_form:d.legalForm,p_company_nature:d.companyNature,
        p_legal_status:d.legalStatus,p_primary_sector_id:d.primarySectorId,p_secondary_sector_ids:[],
        p_country:d.country,p_city:d.city,p_address:d.address,p_phone:d.phone,p_website:d.website,
        p_registration_number:d.registrationNumber,p_tax_number:d.taxNumber,
        p_representative_first_name:d.representativeFirstName,p_representative_last_name:d.representativeLastName,
        p_representative_role:d.representativeRole,p_representative_phone:d.representativePhone,
        p_representative_email:d.professionalEmail,p_representative_birth_date:d.representativeBirthDate||null,
        p_representative_nationality:d.representativeNationality,p_ownership_count:Number(d.associateCount)||null,
        p_associate_count:Number(d.associateCount)||null,p_manager_count:Number(d.managerCount)||null,
        p_people_count:Number(d.peopleCount)||null,p_company_size:d.companySize
      };

      // Si l'utilisateur est déjà connecté, ne recrée jamais son compte Auth.
      const {data:{session:currentSession}}=await supabase.auth.getSession();
      if(currentSession){
        const {data:applicationId,error:submitError}=await supabase.rpc('jdvcrm_submit_company_application_v1',payload);
        if(submitError)throw submitError;
        if(applicationId){
          const {data:{session}}=await supabase.auth.getSession();
          if(session){
            const {error:emailError}=await supabase.functions.invoke('send-email',{
              body:{type:'company_received',application_id:applicationId}
            });
            if(emailError) console.warn('[registration] email de réception non envoyé',emailError);
          }
        }
        localStorage.removeItem('jdv_pending_company_application');
        setSubmitted(true);
        toast.success('Dossier envoyé au Concepteur.');
        return;
      }

      let {data:authData,error:authError}=await supabase.auth.signUp({
        email:d.professionalEmail,password:d.password,
        options:{data:{pending_company_application:true,professional_email:d.professionalEmail}}
      });

      // L'adresse existe déjà : utiliser uniquement le mot de passe fourni pour
      // ouvrir la session existante, sans créer de doublon dans auth.users.
      if(authError && /already registered|already exists|user exists/i.test(authError.message||'')){
        const {data:loginData,error:loginError}=await supabase.auth.signInWithPassword({
          email:d.professionalEmail,password:d.password
        });
        if(loginError) throw new Error('Cette adresse est déjà enregistrée. Connectez-vous avec le mot de passe de ce compte, ou utilisez une autre adresse email.');
        authData={user:loginData.user,session:loginData.session};
        authError=null;
      }

      if(authError)throw authError;
      if(!authData.user)throw new Error('Impossible de créer ou récupérer le compte.');

      localStorage.setItem('jdv_pending_company_application',JSON.stringify(payload));
      if(authData.session){
        const {data:applicationId,error:submitError}=await supabase.rpc('jdvcrm_submit_company_application_v1',payload);
        if(submitError)throw submitError;
        if(applicationId){
          const {error:emailError}=await supabase.functions.invoke('send-email',{
            body:{type:'company_received',application_id:applicationId}
          });
          if(emailError) console.warn('[registration] email de réception non envoyé',emailError);
        }
        localStorage.removeItem('jdv_pending_company_application');
      }
      setSubmitted(true);
      toast.success(authData.session?'Dossier envoyé au Concepteur.':'Compte créé. Confirmez votre email puis connectez-vous pour finaliser le dossier.');
    }catch(e){
      const err = e as { message?: string; error_description?: string; code?: string; details?: string; hint?: string } | null;
      const rawMessage = err?.message || err?.error_description || '';
      const m = rawMessage || (err?.code ? 'Erreur ' + err.code : 'Une erreur est survenue');
      console.error('[registration] erreur inscription dossier entreprise', { code: err?.code, message: rawMessage, details: err?.details, hint: err?.hint });
      setError(m);
      toast.error(m);
    }
    finally{setLoading(false);}
  }

  if(submitted)return <section id="register" className="py-20"><div className="max-w-xl mx-auto px-6"><div className="card-navy rounded-3xl p-10 text-center"><CheckCircle size={52} className="mx-auto mb-5 text-[#D4AF37]"/><h3 className="text-2xl font-bold text-foreground">Dossier d’entreprise créé</h3><p className="text-muted-foreground mt-3 leading-relaxed">Votre demande suit maintenant la procédure de vérification JDV CRM. Vérifiez votre adresse email, puis connectez-vous pour terminer votre dossier si nécessaire.</p><Link href="/business/login" className="btn-gold inline-flex mt-7 px-6 py-3 rounded-xl font-semibold">Continuer</Link></div></div></section>;

  const input='input-navy w-full px-4 py-3 text-sm';
  const label='block text-xs font-semibold text-muted-foreground mb-1.5 uppercase tracking-wide';

  return <section id="register" className="py-20">
    <div className="max-w-screen-xl mx-auto px-6 lg:px-10">
      <div className="mb-10 max-w-3xl"><p className="text-xs font-semibold uppercase tracking-widest text-primary mb-3">Création sécurisée d’entreprise</p><h2 className="text-3xl lg:text-4xl font-extrabold text-foreground">Votre dossier professionnel <span className="gold-gradient-text">JDV CRM</span></h2><p className="text-muted-foreground mt-4">Une seule inscription pour constituer votre identité d’entreprise, son représentant légal, son secteur d’activité et les informations nécessaires à la validation par le Concepteur.</p></div>
      {error&&<div className="mb-6 p-4 rounded-xl bg-red-500/10 border border-red-500/30 text-red-400 text-sm">{error}</div>}
      <form onSubmit={handleSubmit(onSubmit)} className="space-y-8">
        <div className="card-navy rounded-3xl p-7">
          <div className="flex items-center gap-3 mb-6"><Building2 className="text-[#D4AF37]"/><div><h3 className="text-lg font-bold">1. Identité de l’entreprise</h3><p className="text-xs text-muted-foreground">Informations juridiques et commerciales</p></div></div>
          <div className="grid md:grid-cols-2 gap-5">
            <Field label="Nom commercial *" error={errors.organizationName?.message}><input {...register('organizationName',{required:'Nom requis'})} className={input} placeholder="Ex. JDV Distribution"/></Field>
            <Field label="Dénomination sociale"><input {...register('legalName')} className={input} placeholder="Dénomination légale"/></Field>
            <Field label="Forme juridique *" error={errors.legalForm?.message}><select {...register('legalForm',{required:'Forme juridique requise'})} className={input}><option value="">Choisir...</option>{legalForms.map(x=><option key={x}>{x}</option>)}</select></Field>
            <Field label="Nature de l’entité *"><select {...register('companyNature',{required:'Nature requise'})} className={input}><option value="">Choisir...</option>{natures.map(([v,l])=><option value={v} key={v}>{l}</option>)}</select></Field>
            <Field label="Statut juridique"><input {...register('legalStatus')} className={input} placeholder="Ex. société en activité"/></Field>
            <Field label="RCCM / registre de commerce"><input {...register('registrationNumber')} className={input}/></Field>
            <Field label="IFU / identifiant fiscal"><input {...register('taxNumber')} className={input}/></Field>
            <Field label="Email professionnel *" error={errors.professionalEmail?.message}><input type="email" {...register('professionalEmail',{required:'Email professionnel requis'})} className={input} placeholder="contact@entreprise.com"/></Field>
            <Field label="Téléphone professionnel"><input {...register('phone')} className={input}/></Field>
            <Field label="Pays *"><select {...register('country',{required:'Pays requis'})} className={input}><option value="">Choisir...</option>{countries.map(x=><option key={x}>{x}</option>)}</select></Field>
            <Field label="Ville"><input {...register('city')} className={input}/></Field>
            <Field label="Adresse complète"><input {...register('address')} className={input}/></Field>
            <Field label="Site web"><input {...register('website')} className={input} placeholder="https://"/></Field>
          </div>
        </div>

        <div className="card-navy rounded-3xl p-7">
          <div className="flex items-center gap-3 mb-6"><Briefcase className="text-[#D4AF37]"/><div><h3 className="text-lg font-bold">2. Secteur d’activité</h3><p className="text-xs text-muted-foreground">Sélectionnez le domaine principal de votre entreprise.</p></div></div>
          <select {...register('primarySectorId',{required:'Secteur obligatoire'})} className={input}><option value="">Choisir votre secteur d’activité...</option>{sectorOptions}</select>
          {errors.primarySectorId&&<p className="text-xs text-danger mt-1">{errors.primarySectorId.message}</p>}
        </div>

        <div className="card-navy rounded-3xl p-7">
          <div className="flex items-center gap-3 mb-6"><UserRound className="text-[#D4AF37]"/><div><h3 className="text-lg font-bold">3. Représentant légal / responsable</h3><p className="text-xs text-muted-foreground">La personne responsable de l’entreprise.</p></div></div>
          <div className="grid md:grid-cols-2 gap-5">
            <Field label="Nom *"><input {...register('representativeLastName',{required:'Nom requis'})} className={input}/></Field>
            <Field label="Prénoms *"><input {...register('representativeFirstName',{required:'Prénoms requis'})} className={input}/></Field>
            <Field label="Fonction *"><input {...register('representativeRole',{required:'Fonction requise'})} className={input} placeholder="Gérant, Directeur, Président..."/></Field>
            <Field label="Nationalité"><input {...register('representativeNationality')} className={input}/></Field>
            <Field label="Date de naissance"><input type="date" {...register('representativeBirthDate')} className={input}/></Field>
            <Field label="Téléphone"><input {...register('representativePhone')} className={input}/></Field>
          </div>
        </div>

        <div className="card-navy rounded-3xl p-7">
          <div className="flex items-center gap-3 mb-6"><UsersRound className="text-[#D4AF37]"/><div><h3 className="text-lg font-bold">4. Structure de l’entreprise</h3><p className="text-xs text-muted-foreground">Composition et taille.</p></div></div>
          <div className="grid md:grid-cols-4 gap-5">
            <Field label="Taille *"><select {...register('companySize',{required:'Taille requise'})} className={input}><option value="">Choisir...</option><option value="micro">Micro</option><option value="small">Petite</option><option value="medium">Moyenne</option><option value="large">Grande</option></select></Field>
            <Field label="Personnes impliquées"><input type="number" min="1" {...register('peopleCount')} className={input}/></Field>
            <Field label="Associés"><input type="number" min="0" {...register('associateCount')} className={input}/></Field>
            <Field label="Dirigeants"><input type="number" min="1" {...register('managerCount')} className={input}/></Field>
          </div>
        </div>

        <div className="card-navy rounded-3xl p-7">
          <div className="flex items-center gap-3 mb-6"><FileText className="text-[#D4AF37]"/><div><h3 className="text-lg font-bold">5. Documents de vérification</h3><p className="text-xs text-muted-foreground">Les documents seront demandés dans l’espace de finalisation après confirmation de votre compte.</p></div></div>
          <div className="grid md:grid-cols-3 gap-4">{['Pièce d’identité du représentant','RCCM / registre de commerce','IFU / document fiscal','Statuts / acte constitutif','Mandat ou pouvoir si nécessaire','Justificatif d’adresse'].map(x=><div key={x} className="rounded-xl border border-[#D4AF37]/15 bg-[#0A1628] p-4 text-sm text-muted-foreground">{x}</div>)}</div>
        </div>

        <div className="card-navy rounded-3xl p-7">
          <div className="grid md:grid-cols-2 gap-5">
            <Field label="Mot de passe *"><div className="relative"><input type={showPassword?'text':'password'} {...register('password',{required:'Mot de passe requis',minLength:{value:8,message:'Minimum 8 caractères'}})} className={input+' pr-11'}/><button type="button" onClick={()=>setShowPassword(v=>!v)} className="absolute right-3 top-1/2 -translate-y-1/2">{showPassword?<EyeOff size={16}/>:<Eye size={16}/>}</button></div></Field>
            <Field label="Confirmation *" error={errors.confirmPassword?.message}><div className="relative"><input type={showConfirm?'text':'password'} {...register('confirmPassword',{required:'Confirmation requise',validate:v=>v===password||'Mots de passe différents'})} className={input+' pr-11'}/><button type="button" onClick={()=>setShowConfirm(v=>!v)} className="absolute right-3 top-1/2 -translate-y-1/2">{showConfirm?<EyeOff size={16}/>:<Eye size={16}/>}</button></div></Field>
          </div>
          <label className="flex items-start gap-3 mt-6 text-xs text-muted-foreground"><input type="checkbox" {...register('termsAccepted',{required:'Acceptation obligatoire'})} className="mt-0.5"/><span>J’accepte les conditions d’utilisation et la politique de confidentialité de JDV CRM.</span></label>
          {errors.termsAccepted&&<p className="text-xs text-danger mt-1">{errors.termsAccepted.message}</p>}
          <button disabled={loading} className="btn-gold w-full mt-7 py-4 rounded-xl font-bold disabled:opacity-60">{loading?'Création du dossier...':'Créer mon dossier d’entreprise'}</button>
        </div>
      </form>
    </div>
  </section>;
}

function Field({label,error,children}:{label:string;error?:string;children:React.ReactNode}){return <div><label className="block text-xs font-semibold text-muted-foreground mb-1.5 uppercase tracking-wide">{label}</label>{children}{error&&<p className="text-xs text-danger mt-1">{error}</p>}</div>}
