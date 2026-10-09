import React from 'react';
import { BADGE_COLORS } from '@/styles/theme';

interface StatusBadgeProps {
  /**
   * Status key — looked up in BADGE_COLORS from theme.ts.
   * Falls back to 'neutral' if the key is not found.
   */
  status: string;
  /** Optional override label; defaults to the status string itself */
  label?: string;
  size?: 'sm' | 'md';
}

export default function StatusBadge({ status, label, size = 'sm' }: StatusBadgeProps) {
  const colors = BADGE_COLORS[status] ?? BADGE_COLORS['neutral'];
  const sizeClass = size === 'sm' ? 'text-xs px-2 py-0.5' : 'text-sm px-3 py-1';
  return (
    <span
      className={`inline-flex items-center font-semibold rounded-full ${sizeClass}`}
      style={{
        backgroundColor: colors.bg,
        color: colors.text,
        border: `1px solid ${colors.border}`,
      }}
    >
      {label ?? status}
    </span>
  );
}