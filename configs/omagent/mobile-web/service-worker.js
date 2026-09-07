const CACHE_NAME = 'omagent-pwa-v2';
const ASSETS = [
  '/',
  '/manifest.json',
  '/icon.svg'
];

self.addEventListener('install', (e) => {
  e.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (e) => {
  e.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))
      );
    })
  );
  self.clients.claim();
});

self.addEventListener('fetch', (e) => {
  // Pass API and WS calls directly through network
  if (e.request.url.includes('/api/') || e.request.url.includes('/ws')) {
    return;
  }
  // Network first, cache fallback for fast updates
  e.respondWith(
    fetch(e.request).catch(() => caches.match(e.request))
  );
});
