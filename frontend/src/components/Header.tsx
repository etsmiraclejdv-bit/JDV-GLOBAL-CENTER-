import React from 'react';

interface HeaderProps {}

export const Header: React.FC<HeaderProps> = () => {
  return (
    <div className="bg-gradient-to-r from-blue-900 to-blue-800 px-4 py-3 flex justify-between items-center sticky top-0 z-40">
      {/* Logo */}
      <div className="flex items-center gap-2">
        <div className="w-10 h-10 bg-yellow-400 rounded-full flex items-center justify-center">
          <span className="text-blue-900 font-bold text-lg">J</span>
        </div>
        <span className="text-white font-bold hidden sm:block">JDV GLOBAL</span>
      </div>

      {/* Search Icon */}
      <div className="flex gap-4 items-center">
        <button className="text-white hover:text-yellow-400 transition">
          🔍
        </button>

        {/* Notifications */}
        <button className="relative text-white hover:text-yellow-400 transition">
          🔔
          <span className="absolute top-0 right-0 w-2 h-2 bg-red-500 rounded-full"></span>
        </button>

        {/* Messages */}
        <button className="relative text-white hover:text-yellow-400 transition">
          📧
          <span className="absolute top-0 right-0 w-2 h-2 bg-red-500 rounded-full"></span>
        </button>

        {/* Profile */}
        <button className="text-white hover:text-yellow-400 transition">
          👤
        </button>
      </div>
    </div>
  );
};
