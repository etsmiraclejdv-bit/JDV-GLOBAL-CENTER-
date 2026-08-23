import React from 'react';

interface BalanceCardProps {
  balance: number;
  currency: string;
}

export const BalanceCard: React.FC<BalanceCardProps> = ({ balance, currency }) => {
  const formattedBalance = balance.toLocaleString('fr-FR');

  return (
    <div className="px-4 py-4">
      <div className="bg-gradient-to-r from-yellow-400 to-yellow-300 rounded-lg p-6 shadow-lg">
        <p className="text-blue-900 text-sm font-semibold opacity-80">Solde JDV PAY</p>
        <h1 className="text-blue-900 text-3xl font-bold mt-2">
          {formattedBalance} <span className="text-lg">{currency}</span>
        </h1>
        <div className="flex justify-between mt-4 text-blue-900 text-xs font-semibold">
          <span>💰 Portefeuille actif</span>
          <span>Premium ✨</span>
        </div>
      </div>
    </div>
  );
};
