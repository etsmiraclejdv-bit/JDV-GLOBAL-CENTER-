import React from 'react';
import Link from 'next/link';

export const NavigationBar: React.FC = () => {
  const navItems = [
    { icon: '🏠', label: 'ACCUEIL', route: '/' },
    { icon: '🔍', label: 'EXPLORER', route: '/explorer' },
    { icon: '📦', label: 'SERVICES', route: '/services' },
    { icon: '💬', label: 'MESSAGES', route: '/messages' },
    { icon: '👤', label: 'PROFIL', route: '/profile' },
  ];

  return (
    <div className="fixed bottom-0 left-0 right-0 bg-gradient-to-t from-blue-900 to-blue-800 border-t border-yellow-400 border-opacity-30">
      <div className="flex justify-around items-center py-3 max-w-md mx-auto w-full">
        {navItems.map((item, idx) => (
          <Link key={idx} href={item.route}>
            <a className="flex flex-col items-center gap-1 text-white hover:text-yellow-400 transition">
              <span className="text-xl">{item.icon}</span>
              <span className="text-xs font-semibold">{item.label}</span>
            </a>
          </Link>
        ))}
      </div>
    </div>
  );
};
