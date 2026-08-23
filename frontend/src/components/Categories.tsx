import React from 'react';

export const Categories: React.FC = () => {
  const categories = [
    { icon: '💰', label: 'Finance', color: 'from-green-500 to-green-600' },
    { icon: '🏪', label: 'Commerce', color: 'from-blue-500 to-blue-600' },
    { icon: '🏠', label: 'Immo', color: 'from-orange-500 to-orange-600' },
    { icon: '🚗', label: 'Transport', color: 'from-red-500 to-red-600' },
    { icon: '✈️', label: 'Voyage', color: 'from-purple-500 to-purple-600' },
    { icon: '🏥', label: 'Santé', color: 'from-pink-500 to-pink-600' },
    { icon: '🌾', label: 'Agri', color: 'from-yellow-500 to-yellow-600' },
    { icon: '📚', label: 'Éducation', color: 'from-indigo-500 to-indigo-600' },
    { icon: '⚡', label: 'Énergie', color: 'from-cyan-500 to-cyan-600' },
    { icon: '💻', label: 'Tech', color: 'from-gray-500 to-gray-600' },
    { icon: '📺', label: 'Média', color: 'from-red-500 to-pink-600' },
    { icon: '⚖️', label: 'Juridique', color: 'from-slate-500 to-slate-600' },
  ];

  return (
    <div className="px-4 py-4">
      <h3 className="text-white font-bold mb-3">📂 CATÉGORIES</h3>
      <div className="grid grid-cols-3 gap-2">
        {categories.map((cat, idx) => (
          <button
            key={idx}
            className={`bg-gradient-to-br ${cat.color} rounded-lg p-3 text-white flex flex-col items-center gap-1 hover:shadow-lg transition transform hover:scale-105`}
          >
            <span className="text-2xl">{cat.icon}</span>
            <span className="text-xs font-semibold text-center">{cat.label}</span>
          </button>
        ))}
      </div>
    </div>
  );
};
