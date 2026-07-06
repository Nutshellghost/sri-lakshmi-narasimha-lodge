'use strict';

const CACHE_NAME = 'sln-lodge-v1';

// Assets to pre-cache on install
const PRECACHE_URLS = [
  './',
  './index.html',
  './manifest.json',
  './main.dart.js',
  './flutter.js',
  './flutter_bootstrap.js',
  './favicon.png',
  './icons/Icon-192.png',
  './icons/Icon-512.png',
  './icons/Icon-maskable-192.png',
  './icons/Icon-maskable-512.png',
];

// Install: pre-cache the app shell
self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => {
      return cache.addAll(PRECACHE_URLS);
    }).then(() => {
      self.skipWaiting();
    })
  );
});

// Activate: clean up old caches
self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) => {
      return Promise.all(
        keys.filter((key) => key !== CACHE_NAME).map((key) => caches.delete(key))
      );
    }).then(() => {
      return self.clients.claim();
    })
  );
});

// Fetch: cache-first for static assets, network-first for everything else
self.addEventListener('fetch', (event) => {
  const url = new URL(event.request.url);

  // Cache-first for app assets (js, css, png, ico, json, wasm)
  if (url.origin === self.location.origin) {
    const isAsset = /\.(js|css|png|ico|json|wasm|otf|ttf)$/.test(url.pathname);
    const isFlutterAsset = url.pathname.startsWith('/assets/');

    if (isAsset || isFlutterAsset || url.pathname === '/') {
      event.respondWith(
        caches.match(event.request).then((cached) => {
          return cached || fetch(event.request).then((response) => {
            return caches.open(CACHE_NAME).then((cache) => {
              cache.put(event.request, response.clone());
              return response;
            });
          });
        })
      );
      return;
    }
  }

  // Network-first for everything else (API calls, etc.)
  event.respondWith(
    fetch(event.request).then((response) => {
      // Cache successful responses
      if (response.status === 200) {
        const responseClone = response.clone();
        caches.open(CACHE_NAME).then((cache) => {
          cache.put(event.request, responseClone);
        });
      }
      return response;
    }).catch(() => {
      // Offline fallback
      return caches.match(event.request).then((cached) => {
        return cached || new Response('Offline', { status: 503 });
      });
    })
  );
});
