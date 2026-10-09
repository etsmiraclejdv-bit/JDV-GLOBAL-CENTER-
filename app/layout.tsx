import React from 'react';
import type { Metadata, Viewport } from 'next';
import { Toaster } from 'sonner';
import { Suspense } from 'react';
import '../styles/tailwind.css';
import GoogleAnalytics from '@/components/GoogleAnalytics';
import JdvLoadingScreen from '@/app/components/JdvLoadingScreen';

export const viewport: Viewport = {
  width: 'device-width',
  initialScale: 1,
};

export const metadata: Metadata = {
  title: 'JDV CRM — Gestion Crédit & Prospecteurs Terrain',
  description: 'JDV CRM aide les entreprises ouest-africaines à gérer la vente à crédit, les paiements journaliers, les prospecteurs terrain et le recouvrement depuis un seul tableau de bord.',
  icons: {
    icon: [{ url: '/favicon.ico', type: 'image/x-icon' }],
  },
};

export default function RootLayout({
  children,
}: Readonly<{ children: React.ReactNode }>) {
  return (
    <html lang="fr">
      <body>
        <Suspense fallback={null}>
          <GoogleAnalytics />
        </Suspense>
        <JdvLoadingScreen />
        {children}
        <Toaster
          position="bottom-right"
          toastOptions={{
            style: {
              background: '#0F2347',
              border: '1px solid rgba(212,175,55,0.3)',
              color: '#F7F9FC',
              fontFamily: 'Arial, sans-serif',
            },
          }}
        />
      </body>
    </html>
  );
}
