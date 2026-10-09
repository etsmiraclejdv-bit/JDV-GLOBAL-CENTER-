'use client';
import React from 'react';
import { Loader2 } from 'lucide-react';

type ButtonVariant = 'primary' | 'secondary' | 'danger' | 'ghost';
type ButtonSize = 'sm' | 'md' | 'lg';

interface ButtonProps extends React.ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: ButtonVariant;
  size?: ButtonSize;
  loading?: boolean;
  icon?: React.ReactNode;
  children: React.ReactNode;
}

const variantClasses: Record<ButtonVariant, string> = {
  primary: 'btn-gold rounded-xl font-semibold disabled:opacity-50 disabled:cursor-not-allowed disabled:transform-none',
  secondary: 'btn-outline-gold rounded-xl font-semibold disabled:opacity-50 disabled:cursor-not-allowed',
  danger: 'bg-[rgba(252,129,129,0.15)] text-[#FC8181] border border-[rgba(252,129,129,0.3)] rounded-xl font-semibold hover:bg-[rgba(252,129,129,0.25)] transition-all disabled:opacity-50 disabled:cursor-not-allowed',
  ghost: 'text-[#A0AEC0] hover:text-white hover:bg-[#0F2347] rounded-xl font-medium transition-all disabled:opacity-50 disabled:cursor-not-allowed',
};

const sizeClasses: Record<ButtonSize, string> = {
  sm: 'px-3 py-1.5 text-xs',
  md: 'px-5 py-2.5 text-sm',
  lg: 'px-7 py-3 text-base',
};

export default function Button({
  variant = 'primary',
  size = 'md',
  loading = false,
  icon,
  children,
  disabled,
  className = '',
  ...props
}: ButtonProps) {
  return (
    <button
      {...props}
      disabled={disabled || loading}
      className={`inline-flex items-center justify-center gap-2 ${variantClasses[variant]} ${sizeClasses[size]} ${className}`}
    >
      {loading ? (
        <Loader2 size={14} className="animate-spin flex-shrink-0" />
      ) : icon ? (
        <span className="flex-shrink-0">{icon}</span>
      ) : null}
      {children}
    </button>
  );
}
