import React from 'react';
import { TrendingUp, TrendingDown, Minus } from 'lucide-react';

interface MetricCardProps {
  title: string;
  value: string;
  subtitle?: string;
  trend?: number;
  trendLabel?: string;
  icon?: React.ReactNode;
  variant?: 'default' | 'success' | 'danger' | 'warning' | 'gold';
  className?: string;
  children?: React.ReactNode;
}

const variantStyles: Record<string, string> = {
  default: 'card-navy shadow-card',
  success: 'card-navy shadow-card border-l-4 border-l-success',
  danger: 'card-navy shadow-card border-l-4 border-l-danger',
  warning: 'card-navy shadow-card border-l-4 border-l-warning',
  gold: 'card-navy shadow-card border-l-4 border-l-primary',
};

export default function MetricCard({
  title,
  value,
  subtitle,
  trend,
  trendLabel,
  icon,
  variant = 'default',
  className = '',
  children,
}: MetricCardProps) {
  const trendPositive = trend !== undefined && trend > 0;
  const trendNegative = trend !== undefined && trend < 0;
  const trendNeutral = trend !== undefined && trend === 0;

  return (
    <div className={`p-5 rounded-2xl ${variantStyles[variant]} ${className}`}>
      <div className="flex items-start justify-between mb-3">
        <p className="text-xs font-semibold uppercase tracking-wider text-muted-foreground" style={{ letterSpacing: '0.06em' }}>
          {title}
        </p>
        {icon && (
          <div className="p-2 rounded-xl bg-secondary text-muted-foreground">
            {icon}
          </div>
        )}
      </div>
      <p className="text-3xl font-bold text-foreground stat-number mb-1">{value}</p>
      {subtitle && <p className="text-xs text-muted-foreground mb-2">{subtitle}</p>}
      {trend !== undefined && (
        <div className={`flex items-center gap-1 text-xs font-semibold ${
          trendPositive ? 'text-success' : trendNegative ? 'text-danger' : 'text-muted-foreground'
        }`}>
          {trendPositive && <TrendingUp size={12} />}
          {trendNegative && <TrendingDown size={12} />}
          {trendNeutral && <Minus size={12} />}
          <span>{trendPositive ? '+' : ''}{trend}% {trendLabel || 'vs hier'}</span>
        </div>
      )}
      {children}
    </div>
  );
}