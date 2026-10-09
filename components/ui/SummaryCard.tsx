import React from 'react';

interface SummaryCardProps {
  title: string;
  value: string | number;
  subtitle?: string;
  icon?: React.ReactNode;
  color?: 'gold' | 'success' | 'danger' | 'warning' | 'info' | 'default';
  className?: string;
}

const colorMap: Record<string, { border: string; icon: string; value: string }> = {
  gold:    { border: 'border-l-[#D4AF37]',  icon: 'text-[#D4AF37]',  value: 'text-[#D4AF37]' },
  success: { border: 'border-l-[#68D391]',  icon: 'text-[#68D391]',  value: 'text-[#68D391]' },
  danger:  { border: 'border-l-[#FC8181]',  icon: 'text-[#FC8181]',  value: 'text-[#FC8181]' },
  warning: { border: 'border-l-[#F6E05E]',  icon: 'text-[#F6E05E]',  value: 'text-[#F6E05E]' },
  info:    { border: 'border-l-[#63B3ED]',  icon: 'text-[#63B3ED]',  value: 'text-[#63B3ED]' },
  default: { border: 'border-l-transparent', icon: 'text-[#A0AEC0]', value: 'text-white' },
};

export default function SummaryCard({ title, value, subtitle, icon, color = 'default', className = '' }: SummaryCardProps) {
  const c = colorMap[color];
  return (
    <div className={`bg-[#0F2347] border border-[rgba(212,175,55,0.15)] border-l-4 ${c.border} rounded-2xl p-5 shadow-card ${className}`}>
      <div className="flex items-start justify-between mb-3">
        <p className="text-xs font-semibold uppercase tracking-wider text-[#A0AEC0]">{title}</p>
        {icon && <div className={`p-2 rounded-xl bg-[#0A1628] ${c.icon}`}>{icon}</div>}
      </div>
      <p className={`text-3xl font-bold stat-number mb-1 ${c.value}`}>{value}</p>
      {subtitle && <p className="text-xs text-[#718096]">{subtitle}</p>}
    </div>
  );
}
