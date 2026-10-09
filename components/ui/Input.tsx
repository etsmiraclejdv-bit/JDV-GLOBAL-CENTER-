'use client';
import React, { useState } from 'react';
import { Eye, EyeOff } from 'lucide-react';

interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  label?: string;
  error?: string;
  hint?: string;
}

export function Input({ label, error, hint, className = '', id, ...props }: InputProps) {
  const inputId = id || (label ? label.toLowerCase().replace(/\s+/g, '-') : undefined);
  return (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label htmlFor={inputId} className="text-xs font-semibold text-[#A0AEC0] uppercase tracking-wider">
          {label}
        </label>
      )}
      <input
        id={inputId}
        {...props}
        className={`w-full bg-[#0A1628] border ${error ? 'border-[#FC8181]/50' : 'border-[rgba(212,175,55,0.2)]'} rounded-xl px-4 py-2.5 text-sm text-white placeholder-[#718096] focus:outline-none focus:border-[#D4AF37]/60 focus:ring-1 focus:ring-[#D4AF37]/30 transition-all ${className}`}
      />
      {error && <p className="text-xs text-[#FC8181]">{error}</p>}
      {hint && !error && <p className="text-xs text-[#718096]">{hint}</p>}
    </div>
  );
}

interface PasswordInputProps extends Omit<React.InputHTMLAttributes<HTMLInputElement>, 'type'> {
  label?: string;
  error?: string;
}

export function PasswordInput({ label, error, className = '', id, ...props }: PasswordInputProps) {
  const [showPassword, setShowPassword] = useState(false);
  const inputId = id || 'password-input';

  return (
    <div className="flex flex-col gap-1.5">
      {label && (
        <label htmlFor={inputId} className="text-xs font-semibold text-[#A0AEC0] uppercase tracking-wider">
          {label}
        </label>
      )}
      <div className="relative">
        <input
          id={inputId}
          type={showPassword ? 'text' : 'password'}
          {...props}
          className={`w-full bg-[#0A1628] border ${error ? 'border-[#FC8181]/50' : 'border-[rgba(212,175,55,0.2)]'} rounded-xl px-4 py-2.5 pr-11 text-sm text-white placeholder-[#718096] focus:outline-none focus:border-[#D4AF37]/60 focus:ring-1 focus:ring-[#D4AF37]/30 transition-all ${className}`}
        />
        <button
          type="button"
          tabIndex={-1}
          aria-label={showPassword ? 'Masquer le mot de passe' : 'Afficher le mot de passe'}
          onClick={() => setShowPassword(v => !v)}
          className="absolute right-3 top-1/2 -translate-y-1/2 text-[#718096] hover:text-[#A0AEC0] transition-colors"
        >
          {showPassword ? <EyeOff size={16} /> : <Eye size={16} />}
        </button>
      </div>
      {error && <p className="text-xs text-[#FC8181]">{error}</p>}
    </div>
  );
}

export default Input;
