import React from 'react';
import PublicNavbar from '@/components/PublicNavbar';
import PublicExperience from './components/PublicExperience';
import FeaturesSection from './components/FeaturesSection';
import PricingSection from './components/PricingSection';
import RegistrationSection from './components/RegistrationSection';
import PublicFooter from './components/PublicFooter';
import PublicAIAssistant from '@/components/PublicAIAssistant';
import Link from 'next/link';
import { Building2, MapPin } from 'lucide-react';

export default function PublicSitePage() {
  return (
    <div className="min-h-screen bg-background">
      <PublicNavbar />
      <div className="bg-[#08152f] border-b border-[#D4AF37]/20 py-3 px-4">
        <div className="mx-auto flex max-w-6xl flex-col items-center justify-center gap-4 text-sm sm:flex-row">
          <span className="text-[#A0AEC0]">Vous avez déjà un compte ?</span>
          <div className="flex items-center gap-3">
            <Link href="/business/login" className="flex items-center gap-2 rounded-xl border border-[#D4AF37]/30 bg-[#D4AF37]/10 px-4 py-2 font-medium text-[#D4AF37] transition-all hover:bg-[#D4AF37]/20">
              <Building2 size={14} /> Espace Entreprise
            </Link>
            <Link href="/terrain/login" className="flex items-center gap-2 rounded-xl border border-[#63B3ED]/30 bg-[#63B3ED]/10 px-4 py-2 font-medium text-[#63B3ED] transition-all hover:bg-[#63B3ED]/20">
              <MapPin size={14} /> Espace Prospecteur
            </Link>
          </div>
        </div>
      </div>
      <PublicExperience />
      <FeaturesSection />
      <PricingSection />
      <RegistrationSection />
      <PublicFooter />
      <PublicAIAssistant />
    </div>
  );
}
