'use client';
import React, { useState, useEffect } from 'react';
import { Globe, Check } from 'lucide-react';
import { supabase } from '@/lib/supabase/client';
import { SUPPORTED_LANGUAGES, Language } from '@/lib/i18n';

interface LanguageSwitcherProps {
  currentLanguage?: Language;
  onLanguageChange?: (lang: Language) => void;
}

export default function LanguageSwitcher({ currentLanguage = 'fr', onLanguageChange }: LanguageSwitcherProps) {
  const [open, setOpen] = useState(false);
  const [selected, setSelected] = useState<Language>(currentLanguage);

  async function handleSelect(lang: Language) {
    setSelected(lang);
    setOpen(false);
    onLanguageChange?.(lang);
    const { data: { user } } = await supabase.auth.getUser();
    if (user) {
      await supabase
        .from('profiles')
        .update({ preferred_language: lang } as never)
        .eq('id', user.id);
    }
  }

  const current = SUPPORTED_LANGUAGES.find(l => l.code === selected);

  return (
    <div className="relative">
      <button
        onClick={() => setOpen(v => !v)}
        className="flex items-center gap-2 px-3 py-2 rounded-xl bg-[#0A1628] border border-[#D4AF37]/20 text-[#A0AEC0] hover:text-white text-sm transition-all"
      >
        <Globe size={14} />
        <span>{current?.flag} {current?.code.toUpperCase()}</span>
      </button>

      {open && (
        <>
          <div className="fixed inset-0 z-40" onClick={() => setOpen(false)} />
          <div className="absolute right-0 top-full mt-1 w-40 bg-[#0F2347] border border-[#D4AF37]/20 rounded-xl shadow-2xl z-50 overflow-hidden">
            {SUPPORTED_LANGUAGES.map(lang => (
              <button
                key={lang.code}
                onClick={() => handleSelect(lang.code)}
                className={`w-full flex items-center justify-between px-4 py-2.5 text-sm transition-colors ${
                  selected === lang.code
                    ? 'text-[#D4AF37] bg-[#D4AF37]/10'
                    : 'text-[#A0AEC0] hover:text-white hover:bg-[#0A1628]'
                }`}
              >
                <span>{lang.flag} {lang.label}</span>
                {selected === lang.code && <Check size={12} />}
              </button>
            ))}
          </div>
        </>
      )}
    </div>
  );
}
