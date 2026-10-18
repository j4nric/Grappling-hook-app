// Service worker of the web build: makes the game installable and playable
// offline. Network first, so every push reaches the phone at once; the cache
// is only the fallback without a connection. The engine (index.wasm, ~40 MB,
// and its scripts) changes only with the Godot version: it comes straight
// from its own cache, named by a hash of the engine files, so the game starts
// without waiting for the network. Copied next to index.html by
// tools/export_web.sh, which stamps the build version, the engine hash and
// the files below.
const VERSION = "__VERSION__";
const ENGINE = "__ENGINE__";
const ENGINE_FILES = ["index.wasm", "index.js", "index.audio.worklet.js", "index.audio.position.worklet.js"];
const ENGINE_CACHE = "grappling-engine-" + ENGINE;
// Fetched when the worker installs, so the first visit already works offline.
const FILES = __FILES__;
const CACHE = "grappling-cave";
// The game data has a new name per build (cache busting): keep only one.
const PACK = /^index-.*\.pck$/;

self.addEventListener("install", (event) => {
  self.skipWaiting();
  event.waitUntil(precache());
});
self.addEventListener("activate", (event) => event.waitUntil((async () => {
  // Engines of older Godot versions go, and the engine copies older workers
  // kept with the game files.
  for (const name of await caches.keys()) {
    if (name.startsWith("grappling-engine-") && name !== ENGINE_CACHE) {
      await caches.delete(name);
    }
  }
  const cache = await caches.open(CACHE);
  for (const file of ENGINE_FILES) {
    await cache.delete(file);
  }
  await self.clients.claim();
})()));

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
  if (ENGINE_FILES.includes(file)) {
    event.respondWith(engineFirst(event, request, file));
    return;
  }
  event.respondWith(networkFirst(event, request, file || "index.html"));
});

async function engineFirst(event, request, file) {
  const cache = await caches.open(ENGINE_CACHE);
  const cached = await cache.match(file);
  if (cached) {
    return cached;
  }
  const response = await fetch(request);
  if (response.ok) {
    event.waitUntil(cache.put(file, response.clone()));
  }
  return response;
}

async function precache() {
  const cache = await caches.open(CACHE);
  const engine = await caches.open(ENGINE_CACHE);
  // A file that fails now gets cached on its next fetch. An engine already
  // cached (same hash) is not fetched again.
  await Promise.allSettled(FILES.map(async (file) => {
    const engineFile = ENGINE_FILES.includes(file);
    if (engineFile && await engine.match(file)) {
      return;
    }
    const response = await fetch(file);
    if (response.ok) {
      await (engineFile ? engine.put(file, response) : store(cache, file, response));
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
