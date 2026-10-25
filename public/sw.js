/* Service worker de Transi: app shell + recursos estáticos para uso offline. */

const CACHE = "transi-v2.2.0";
const APP_SHELL = [
  "./",
  "./index.html",
  "./manifest.webmanifest",
  "./icono.svg",
  "./icono-192.png",
  "./icono-512.png",
  "./icono-maskable-512.png",
  "./apple-touch-icon.png",
];

self.addEventListener("install", (event) => {
  event.waitUntil(
    caches
      .open(CACHE)
      .then((cache) => cache.addAll(APP_SHELL))
      .then(() => self.skipWaiting()),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    caches
      .keys()
      .then((claves) =>
        Promise.all(claves.filter((clave) => clave !== CACHE).map((clave) => caches.delete(clave))),
      )
      .then(() => self.clients.claim()),
  );
});

self.addEventListener("fetch", (event) => {
  const request = event.request;
  if (request.method !== "GET") return;

  const url = new URL(request.url);
  if (url.origin !== self.location.origin) return;

  // Navegación: red primero para recibir actualizaciones; cache como respaldo offline.
  if (request.mode === "navigate") {
    event.respondWith(
      fetch(request)
        .then((response) => {
          const copia = response.clone();
          caches.open(CACHE).then((cache) => cache.put("./index.html", copia));
          return response;
        })
        .catch(async () => {
          const cache = await caches.open(CACHE);
          return (await cache.match("./index.html")) || (await cache.match("./")) || Response.error();
        }),
    );
    return;
  }

  // Recursos estáticos: cache primero, completando el cache en segundo plano.
  event.respondWith(
    caches.match(request).then((cached) => {
      if (cached) return cached;
      return fetch(request).then((response) => {
        if (response.ok) {
          const copia = response.clone();
          caches.open(CACHE).then((cache) => cache.put(request, copia));
        }
        return response;
      });
    }),
  );
});
