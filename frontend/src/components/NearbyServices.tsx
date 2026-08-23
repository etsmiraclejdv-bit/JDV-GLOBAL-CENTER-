import React from 'react';

export const NearbyServices: React.FC = () => {
  const nearby = [
    { icon: '🏥', name: 'Hôpital Central', dist: '0.5 km' },
    { icon: '💊', name: 'Pharmacie Plus', dist: '0.8 km' },
    { icon: '🍔', name: 'Restaurant XYZ', dist: '1.2 km' },
  ];

  return (
    <div className="px-4 py-4">
      <h3 className="text-white font-bold mb-3">📍 SERVICES PROCHES</h3>
      <div className="space-y-2">
        {nearby.map((service, idx) => (
          <div
            key={idx}
            className="bg-white bg-opacity-5 border border-yellow-400 border-opacity-20 rounded-lg p-3 flex items-center justify-between hover:bg-opacity-10 transition cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <span className="text-2xl">{service.icon}</span>
              <div>
                <h4 className="text-white font-semibold text-sm">{service.name}</h4>
                <p className="text-blue-200 text-xs">{service.dist}</p>
              </div>
            </div>
            <button className="text-yellow-400 hover:text-yellow-300">→</button>
          </div>
        ))}
      </div>
    </div>
  );
};
