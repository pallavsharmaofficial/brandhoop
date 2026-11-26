// Offline shell for the admin panel. The page, Saathi's files and the logo are stored when the app is installed, and refreshed from the
// network whenever there is signal. GitHub API calls, photos and other sites are never touched here.
const CACHE = 'bh-admin-v2';
const SHELL = ['./', 'index.html', 'sync.js', 'saathi/kb.js', 'saathi/saathi.js', 'saathi/llm.js', 'manifest.webmanifest', 'icons/icon-192.png', 'icons/icon-512.png', '../favicon.png', '../brand/logo/brandhoop-mark-white.svg', '../brand/logo/brandhoop-mark.svg', '../brand/logo/brandhoop-logo-horizontal-on-dark.svg', '../brand/logo/brandhoop-logo-horizontal.svg', '../brand/logo/brandhoop-logo.svg', '../brand/logo/brandhoop-logo-on-dark.svg', '../brand/cards/lineart.png'];
self.addEventListener('install', (e) => { self.skipWaiting(); e.waitUntil(caches.open(CACHE).then((c) => Promise.all(SHELL.map((u) => c.add(new Request(u, { cache: 'reload' })).catch(() => {}))))); });
self.addEventListener('activate', (e) => { e.waitUntil(caches.keys().then((ks) => Promise.all(ks.filter((k) => k !== CACHE).map((k) => caches.delete(k)))).then(() => self.clients.claim())); });
self.addEventListener('fetch', (e) => {
  const u = new URL(e.request.url);
  if (e.request.method !== 'GET' || u.origin !== location.origin) return;
  e.respondWith(fetch(e.request).then((r) => { if (r.ok) { const c = r.clone(); caches.open(CACHE).then((x) => x.put(e.request, c)); } return r; }).catch(() => caches.match(e.request, { ignoreSearch: true })));
});
