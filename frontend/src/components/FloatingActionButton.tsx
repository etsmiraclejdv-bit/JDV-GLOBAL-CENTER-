import React, { useState } from 'react';

export const FloatingActionButton: React.FC = () => {
  const [isOpen, setIsOpen] = useState(false);

  const actions = [
    { icon: '💰', label: 'JDV PAY', route: '/jdv-pay' },
    { icon: '📱', label: 'SCANNER', route: '/scanner' },
    { icon: '🔍', label: 'RECHERCHE', route: '/search' },
    { icon: '🤖', label: 'IA', route: '/ai' },
    { icon: '🛒', label: 'COMMANDE', route: '/orders' },
    { icon: '🏨', label: 'RÉSERVATION', route: '/reservations' },
  ];

  return (
    <div className="fixed bottom-24 right-4 z-50">
      {/* Main Button */}
      <button
        onClick={() => setIsOpen(!isOpen)}
        className="bg-gradient-to-br from-yellow-400 to-orange-400 hover:shadow-xl w-16 h-16 rounded-full flex items-center justify-center text-2xl transition transform hover:scale-110 shadow-lg"
      >
        🚀
      </button>

      {/* Action Menu */}
      {isOpen && (
        <div className="absolute bottom-20 right-0 bg-blue-900 border border-yellow-400 rounded-lg shadow-xl p-2 space-y-2 min-w-max">
          {actions.map((action, idx) => (
            <button
              key={idx}
              className="flex items-center gap-2 text-white hover:text-yellow-400 hover:bg-white hover:bg-opacity-10 px-4 py-2 rounded transition w-full text-left"
            >
              <span className="text-xl">{action.icon}</span>
              <span className="text-sm font-semibold">{action.label}</span>
            </button>
          ))}
        </div>
      )}
    </div>
  );
};
