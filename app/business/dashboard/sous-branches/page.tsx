'use client';

import Link from 'next/link';

// Netlify sync checkpoint
export default function SousBranchesPage() {
  return (
    <div className="p-6 text-white space-y-6">
      <div>
        <h1 className="text-2xl font-bold">Sous-branches</h1>
        <p className="mt-2 text-slate-400">
          Accédez aux espaces opérationnels de votre organisation.
        </p>
      </div>

      <div className="grid gap-4 md:grid-cols-2 lg:grid-cols-3">
        <Link
          href="/entrepot/login"
          className="rounded-2xl border border-[#D4AF37]/30 bg-[#08152f] p-5 hover:bg-[#0F2347]"
        >
          <h2 className="font-semibold text-[#D4AF37]">Entrepôt</h2>
          <p className="mt-2 text-sm text-slate-400">
            Gestion du stock, prospecteurs, approvisionnement et traçabilité.
          </p>
        </Link>

        <Link
          href="/business/dashboard/suivi-prospecteurs"
          className="rounded-2xl border border-white/10 bg-[#08152f] p-5 hover:bg-[#0F2347]"
        >
          <h2 className="font-semibold">Prospecteurs</h2>
          <p className="mt-2 text-sm text-slate-400">
            Suivi des équipes commerciales et de leurs activités.
          </p>
        </Link>

        <Link
          href="/business/dashboard/mouvements-stock"
          className="rounded-2xl border border-white/10 bg-[#08152f] p-5 hover:bg-[#0F2347]"
        >
          <h2 className="font-semibold">Mouvements de stock</h2>
          <p className="mt-2 text-sm text-slate-400">
            Journal global des mouvements.
          </p>
        </Link>

        <Link
          href="/business/dashboard/sous-entrepots"
          className="rounded-2xl border border-[#D4AF37]/30 bg-[#08152f] p-5 hover:bg-[#0F2347]"
        >
          <h2 className="font-semibold text-[#D4AF37]">Sous-entrepôts</h2>
          <p className="mt-2 text-sm text-slate-400">
            Créer et administrer les unités rattachées aux entrepôts parents.
          </p>
        </Link>
      </div>
    </div>
  );
}
