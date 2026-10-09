'use client';

import { useEffect, useState } from 'react';
import Link from 'next/link';
import { usePathname } from 'next/navigation';
import { Building2, MapPin, ShieldCheck, LayoutGrid } from 'lucide-react';
import { getAuthContext } from '@/lib/auth/context';

const BRANCHES = [
  { code: 'admin', label: 'Admin · Entreprise', href: '/business/dashboard', icon: Building2 },
  { code: 'terrain', label: 'Terrain · Prospecteurs', href: '/terrain/dashboard', icon: MapPin },
  { code: 'concepteur', label: 'Concepteur · Plateforme', href: '/hidden-concepteur-gate/dashboard', icon: ShieldCheck },
] as const;

export default function ConcepteurBranchBar() {
  const pathname = usePathname() ?? '';
  const [visible, setVisible] = useState(false);

  useEffect(() => {
    let cancelled = false;
    getAuthContext()
      .then((ctx) => { if (!cancelled) setVisible(!!ctx?.isSuperAdmin); })
      .catch(() => { if (!cancelled) setVisible(false); });
    return () => { cancelled = true; };
  }, []);

  if (!visible) return null;

  return (
    <nav aria-label="Branches du concepteur" className="flex flex-wrap items-center gap-2 border-b border-[#D4AF37]/30 bg-[#07142d] px-4 py-2 text-xs text-white">
      <Link href="/hidden-concepteur-gate" className="flex items-center gap-1 rounded-md px-2 py-1 text-[#D4AF37] hover:bg-white/10">
        <LayoutGrid size={14} /> Espace concepteur
      </Link>
      {BRANCHES.map(({ code, label, href, icon: Icon }) => {
        const active = pathname.startsWith(href);
        return (
          <Link key={code} href={href} className={active ? 'flex items-center gap-1 rounded-md px-2 py-1 transition bg-[#D4AF37] text-[#07142d] font-semibold' : 'flex items-center gap-1 rounded-md px-2 py-1 transition hover:bg-white/10'}>
            <Icon size={14} /> {label}
          </Link>
        );
      })}
    </nav>
  );
}