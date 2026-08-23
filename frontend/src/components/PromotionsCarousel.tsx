import React from 'react';

export const PromotionsCarousel: React.FC = () => {
  const promotions = [
    { title: '🎉 OFFRE 1', discount: '50%', code: 'JDV50' },
    { title: '🎉 OFFRE 2', discount: '30%', code: 'JDV30' },
    { title: '🎉 OFFRE 3', discount: '20%', code: 'JDV20' },
  ];

  return (
    <div className="px-4 py-4">
      <h3 className="text-white font-bold mb-3">🎉 OFFRES & PROMOTIONS</h3>
      <div className="flex gap-2 overflow-x-auto pb-2">
        {promotions.map((promo, idx) => (
          <div
            key={idx}
            className="flex-shrink-0 bg-gradient-to-r from-yellow-400 to-orange-400 rounded-lg p-4 min-w-[200px] hover:shadow-lg transition cursor-pointer"
          >
            <p className="text-blue-900 font-bold text-sm">{promo.title}</p>
            <p className="text-blue-900 text-2xl font-bold mt-2">{promo.discount}</p>
            <p className="text-blue-900 text-xs font-semibold mt-1">Code: {promo.code}</p>
          </div>
        ))}
      </div>
    </div>
  );
};
