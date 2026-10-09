'use client';

import { useCallback, useState } from 'react';
export const dateFr = (d: string | null | undefined) => d ? new Date(d).toLocaleString('fr-FR', { dateStyle: 'short', timeStyle: 'short' }) : '—';
export const dayFr = (d: string | null | undefined) => d ? new Date(d).toLocaleDateString('fr-FR', { dateStyle: 'medium' }) : '—';
export const money = (n: number | string | null | undefined) => new Intl.NumberFormat('fr-FR').format(Math.round(Number(n) || 0)) + ' FCFA';
export const num = (n: number | string | null | undefined) => new Intl.NumberFormat('fr-FR').format(Number(n) || 0);
export type BannerState = { tone: 'ok' | 'error'; text: string } | null;
export function useBanner() { const [banner, setBanner] = useState<BannerState>(null); const ok = useCallback((text: string) => setBanner({ tone: 'ok', text }), []); const fail = useCallback((text: string) => setBanner({ tone: 'error', text }), []); const clear = useCallback(() => setBanner(null), []); return { banner, ok, fail, clear }; }
export function Banner({ state }: { state: BannerState }) { if (!state) return null; return <div className={`rounded-xl border p-3 text-sm ${state.tone === 'ok' ? 'border-emerald-400/30 bg-emerald-400/10' : 'border-red-400/30 bg-red-400/10'}`}>{state.text}</div>; }
export function PageTitle({ title, subtitle, children }: { title: string; subtitle?: string; children?: React.ReactNode }) { return <div className="flex flex-wrap items-start justify-between gap-3"><div><h1 className="text-2xl font-bold">{title}</h1>{subtitle && <p className="text-slate-400 mt-1 max-w-3xl">{subtitle}</p>}</div>{children}</div>; }
export function Card({ title, children, className = '' }: { title?: string; children: React.ReactNode; className?: string }) { return <section className={`rounded-2xl border border-white/10 bg-[#08152f] p-5 ${className}`}>{title && <h2 className="font-semibold mb-4">{title}</h2>}{children}</section>; }
export function Stat({ label, value, tone }: { label: string; value: React.ReactNode; tone?: 'warn' | 'ok' }) { return <div className="rounded-2xl border border-white/10 bg-[#08152f] p-4"><div className="text-xs uppercase tracking-wider text-slate-400">{label}</div><div className={`mt-2 text-2xl font-bold ${tone === 'warn' ? 'text-red-400' : tone === 'ok' ? 'text-emerald-400' : ''}`}>{value}</div></div>; }
export const inputCls = 'rounded-lg bg-[#0F2347] border border-white/10 p-2 text-sm w-full';
export const btnGold = 'rounded-lg bg-[#D4AF37] text-[#08152f] font-semibold px-4 py-2 text-sm disabled:opacity-50';
export const btnGhost = 'rounded-lg border border-white/10 px-3 py-2 text-sm hover:bg-white/5 disabled:opacity-50';
