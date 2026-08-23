import React from 'react';
import { Header } from '@/components/Header';
import { BalanceCard } from '@/components/BalanceCard';
import { QuickActions } from '@/components/QuickActions';
import { Categories } from '@/components/Categories';
import { RecommendedServices } from '@/components/RecommendedServices';
import { PromotionsCarousel } from '@/components/PromotionsCarousel';
import { NearbyServices } from '@/components/NearbyServices';
import { NavigationBar } from '@/components/NavigationBar';
import { FloatingActionButton } from '@/components/FloatingActionButton';

export default function Home() {
  return (
    <div className="min-h-screen bg-gradient-to-br from-blue-900 via-blue-800 to-blue-900">
      {/* Header */}
      <Header />

      {/* Main Content */}
      <div className="pb-24 pt-4">
        {/* Greeting */}
        <div className="px-4 py-4">
          <h2 className="text-white text-2xl font-bold">👋 Bonjour, utilisateur</h2>
          <p className="text-blue-100 text-sm">Bienvenue sur JDV GLOBAL CENTER</p>
        </div>

        {/* Balance Card */}
        <BalanceCard balance={150000} currency="XOF" />

        {/* Quick Actions */}
        <QuickActions />

        {/* Search Bar */}
        <div className="px-4 py-4">
          <input
            type="text"
            placeholder="Que recherchez-vous ?"
            className="w-full px-4 py-3 rounded-lg bg-white bg-opacity-10 text-white placeholder-blue-200 border border-yellow-400 focus:outline-none focus:ring-2 focus:ring-yellow-400"
          />
        </div>

        {/* Categories */}
        <Categories />

        {/* Recommended Services */}
        <RecommendedServices />

        {/* Promotions */}
        <PromotionsCarousel />

        {/* Nearby Services */}
        <NearbyServices />
      </div>

      {/* Navigation Bar */}
      <NavigationBar />

      {/* Floating Action Button */}
      <FloatingActionButton />
    </div>
  );
}
