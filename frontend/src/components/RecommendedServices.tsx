import React from 'react';

export const RecommendedServices: React.FC = () => {
  const services = [
    {
      icon: '⭐',
      title: 'Service Premium 1',
      desc: 'Description',
      rating: 4.8,
    },
    {
      icon: '⭐',
      title: 'Service Premium 2',
      desc: 'Description',
      rating: 4.9,
    },
    {
      icon: '⭐',
      title: 'Service Premium 3',
      desc: 'Description',
      rating: 5.0,
    },
  ];

  return (
    <div className="px-4 py-4">
      <h3 className="text-white font-bold mb-3">⭐ SERVICES RECOMMANDÉS</h3>
      <div className="space-y-2">
        {services.map((service, idx) => (
          <div
            key={idx}
            className="bg-white bg-opacity-5 border border-yellow-400 border-opacity-20 rounded-lg p-3 hover:bg-opacity-10 transition cursor-pointer"
          >
            <div className="flex items-center gap-3">
              <span className="text-2xl">{service.icon}</span>
              <div className="flex-1">
                <h4 className="text-white font-semibold text-sm">{service.title}</h4>
                <p className="text-blue-200 text-xs">{service.desc}</p>
              </div>
              <span className="text-yellow-400 text-sm">⭐ {service.rating}</span>
            </div>
          </div>
        ))}
      </div>
    </div>
  );
};
