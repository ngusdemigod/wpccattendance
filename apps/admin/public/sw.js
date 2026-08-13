const CACHE = "dream-team-shell-v1";
const SHELL = ["/offline.html", "/wpcc-logo.png"];

self.addEventListener("install", event => {
  event.waitUntil(caches.open(CACHE).then(cache => cache.addAll(SHELL)).then(() => self.skipWaiting()));
});

self.addEventListener("activate", event => {
  event.waitUntil(caches.keys().then(keys => Promise.all(keys.filter(key => key !== CACHE).map(key => caches.delete(key)))).then(() => self.clients.claim()));
});

self.addEventListener("fetch", event => {
  const request = event.request;
  if (request.method !== "GET") return;
  const url = new URL(request.url);
  if (url.origin !== self.location.origin || url.pathname.startsWith("/api/") || url.pathname.startsWith("/dashboard")) {
    if (request.mode === "navigate") event.respondWith(fetch(request).catch(() => caches.match("/offline.html")));
    return;
  }
  if (request.destination === "image" || request.destination === "font" || url.pathname.startsWith("/_next/static/")) {
    event.respondWith(caches.match(request).then(cached => cached || fetch(request).then(response => { if (response.ok) caches.open(CACHE).then(cache => cache.put(request, response.clone())); return response; })));
  }
});
