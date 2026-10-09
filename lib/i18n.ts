'use client';
import frTranslations from '@/locales/fr.json';
import enTranslations from '@/locales/en.json';

export type Language =
  | 'fr'|'en'|'es'|'pt'|'de'|'it'|'nl'|'ar'|'zh'|'ja'|'ko'|'hi'|'bn'|'ur'|'id'|'ms'|'tr'|'ru'|'uk'|'sw'|'am'|'ha'|'yo'|'th'|'vi';

export const SUPPORTED_LANGUAGES: { code: Language; label: string; flag: string }[] = [
  {code:'fr',label:'Français',flag:'🇫🇷'},{code:'en',label:'English',flag:'🇬🇧'},
  {code:'es',label:'Español',flag:'🇪🇸'},{code:'pt',label:'Português',flag:'🇵🇹'},
  {code:'de',label:'Deutsch',flag:'🇩🇪'},{code:'it',label:'Italiano',flag:'🇮🇹'},
  {code:'nl',label:'Nederlands',flag:'🇳🇱'},{code:'ar',label:'العربية',flag:'🌐'},
  {code:'zh',label:'中文',flag:'🇨🇳'},{code:'ja',label:'日本語',flag:'🇯🇵'},
  {code:'ko',label:'한국어',flag:'🇰🇷'},{code:'hi',label:'हिन्दी',flag:'🇮🇳'},
  {code:'bn',label:'বাংলা',flag:'🇧🇩'},{code:'ur',label:'اردو',flag:'🌐'},
  {code:'id',label:'Bahasa Indonesia',flag:'🇮🇩'},{code:'ms',label:'Bahasa Melayu',flag:'🇲🇾'},
  {code:'tr',label:'Türkçe',flag:'🇹🇷'},{code:'ru',label:'Русский',flag:'🇷🇺'},
  {code:'uk',label:'Українська',flag:'🇺🇦'},{code:'sw',label:'Kiswahili',flag:'🌍'},
  {code:'am',label:'አማርኛ',flag:'🇪🇹'},{code:'ha',label:'Hausa',flag:'🌍'},
  {code:'yo',label:'Yorùbá',flag:'🌍'},{code:'th',label:'ไทย',flag:'🇹🇭'},
  {code:'vi',label:'Tiếng Việt',flag:'🇻🇳'},
];

type TranslationDict = typeof frTranslations;
const translations: Partial<Record<Language, TranslationDict>> = { fr: frTranslations, en: enTranslations };

export function getTranslations(language: Language = 'fr'): TranslationDict {
  return translations[language] ?? translations.en ?? translations.fr;
}

export function detectLanguage(preferredLanguage?: string | null, orgLanguage?: string | null): Language {
  const lang = (preferredLanguage ?? orgLanguage ?? 'fr').toLowerCase().split('-')[0] as Language;
  return SUPPORTED_LANGUAGES.some(x=>x.code===lang) ? lang : 'fr';
}
