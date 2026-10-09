import { imageHosts } from './image-hosts.config.mjs';

/** @type {import('next').NextConfig} */
const nextConfig = {
  // Ne jamais publier les cartes sources : elles rendent le code lisible par tout le monde.
  productionBrowserSourceMaps: false,
  distDir: process.env.DIST_DIR || '.next',

  // Mettre STRICT_BUILD=true (variable d'environnement de build) dès que `npm run type-check`
  // et `npm run lint` passent sans erreur : les erreurs bloqueront alors le déploiement.
  typescript: {
    ignoreBuildErrors: process.env.STRICT_BUILD !== 'true',
  },

  eslint: {
    ignoreDuringBuilds: process.env.STRICT_BUILD !== 'true',
  },

  async redirects() {
    return [
      { source: '/business-admin-dashboard', destination: '/business/dashboard', permanent: true },
      { source: '/terrain-prospector-dashboard', destination: '/terrain/dashboard', permanent: true },
    ];
  },

  images: {
    remotePatterns: imageHosts,
    minimumCacheTTL: 60,
    qualities: [75, 85, 100],
  }
};
export default nextConfig;