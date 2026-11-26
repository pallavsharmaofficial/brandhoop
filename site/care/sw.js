// Lets Phone Care open without signal (the checks themselves run on the phone). Network first, saved copy when offline.
const CACHE = 'bh-care-v1';
self.addEventListener('install', (e) => { self.skipWaiting(); e.waitUntil(caches.open(CACHE).then((c) => Promise.all(['./', 'index.html', 'care.js', 'manifest.webmanifest', '../brand/logo/brandhoop-mark.svg', '../brand/logo/brandhoop-logo-horizontal-on-dark.svg'].map((u) => c.add(u).catch(() => {}))))); });
self.addEventListener('activate', (e) => { e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener('fetch', (e) => {
  const u = new URL(e.request.url); if (e.request.method !== 'GET' || u.origin !== location.origin || u.pathname.endsWith('speedtest.bin')) return;
  e.respondWith(fetch(e.request).then((r) => { if (r.ok) { const c = r.clone(); caches.open(CACHE).then((x) => x.put(e.request, c)); } return r; }).catch(() => caches.match(e.request, { ignoreSearch: true })));
});
