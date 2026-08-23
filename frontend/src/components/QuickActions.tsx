import React from 'react';

export const QuickActions: React.FC = () => {
  const actions = [
    { icon: '📤', label: 'Envoyer', route: '/pay/send' },
    { icon: '📥', label: 'Recevoir', route: '/pay/receive' },
    { icon: '💳', label: 'Payer', route: '/pay/payment' },
    { icon: '📱', label: 'Scanner', route: '/pay/scan' },
    { icon: '🛍️', label: 'Acheter', route: '/market' },
    { icon: '🏨', label: 'Réserver', route: '/travel' },
    { icon: '🛒', label: 'Commander', route: '/delivery' },
    { icon: '🙋', label: 'Service', route: '/support' },
  ];

  return (
    <div className="px-4 py-4">
      <h3 className="text-white font-bold mb-3">🎯 ACTIONS RAPIDES</h3>
      <div className="grid grid-cols-4 gap-2">
        {actions.map((action, idx) => (
          <button
            key={idx}
            className="bg-white bg-opacity-10 hover:bg-opacity-20 border border-yellow-400 border-opacity-30 rounded-lg py-3 flex flex-col items-center gap-1 transition transform hover:scale-105"
          >
            <span className="text-2xl">{action.icon}</span>
            <span className="text-white text-xs text-center">{action.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
};
