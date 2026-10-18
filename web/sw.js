// Service worker of the web build: makes the game installable and playable
// offline. Network first, so every push reaches the phone at once; the cache
// is only the fallback without a connection. Copied next to index.html by
// tools/export_web.sh, which stamps the build version and its files below.
const VERSION = "__VERSION__";
// Fetched when the worker installs, so the first visit already works offline.
const FILES = __FILES__;
const CACHE = "grappling-cave";
// The game data has a new name per build (cache busting): keep only one.
const PACK = /^index-.*\.pck$/;

self.addEventListener("install", (event) => {
  self.skipWaiting();
  event.waitUntil(precache());
});
self.addEventListener("activate", (event) => event.waitUntil(self.clients.claim()));

self.addEventListener("fetch", (event) => {
  const request = event.request;
  const scope = self.registration.scope;
  if (request.method !== "GET" || !request.url.startsWith(scope)) {
    return;
  }
  const file = request.url.slice(scope.length).split(/[?#]/)[0];
  // Only this build's own files: previews in subfolders have their own worker.
  if (file.includes("/")) {
    return;
  }
  event.respondWith(networkFirst(event, request, file || "index.html"));
});

async function precache() {
  const cache = await caches.open(CACHE);
  // A file that fails now gets cached on its next fetch.
  await Promise.allSettled(FILES.map(async (file) => {
    const response = await fetch(file);
    if (response.ok) {
      await store(cache, file, response);
    }
  }));
}

async function networkFirst(event, request, file) {
  const cache = await caches.open(CACHE);
  try {
    const response = await fetch(request);
    if (response.ok) {
      event.waitUntil(store(cache, file, response.clone()));
    }
    return response;
  } catch (error) {
    const cached = await cache.match(file);
    if (cached) {
      return cached;
    }
    throw error;
  }
}

async function store(cache, file, response) {
  await cache.put(file, response);
  if (PACK.test(file)) {
    for (const key of await cache.keys()) {
      const name = new URL(key.url).pathname.split("/").pop();
      if (PACK.test(name) && name !== file) {
        await cache.delete(key);
      }
    }
  }
}
