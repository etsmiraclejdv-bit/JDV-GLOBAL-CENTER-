import React from 'react';
import { AlertTriangle } from 'lucide-react';

interface ErrorStateProps {
  title?: string;
  message?: string;
  action?: {
    label: string;
    onClick: () => void;
  };
  className?: string;
}

export default function ErrorState({
  title = 'Une erreur est survenue',
  message = 'Impossible de charger les données. Veuillez réessayer.',
  action,
  className = '',
}: ErrorStateProps) {
  return (
    <div className={`flex flex-col items-center justify-center py-16 px-6 text-center ${className}`}>
      <div className="p-4 rounded-2xl bg-[rgba(252,129,129,0.1)] mb-4">
        <AlertTriangle size={28} className="text-[#FC8181]" />
      </div>
      <h3 className="text-base font-semibold text-white mb-2">{title}</h3>
      <p className="text-sm text-[#A0AEC0] max-w-xs mb-4">{message}</p>
      {action && (
        <button
          onClick={action.onClick}
          className="btn-outline-gold px-5 py-2.5 rounded-xl text-sm font-semibold"
        >
          {action.label}
        </button>
      )}
    </div>
  );
}
