const CACHE_NAME = 'pelotao-cache-v3';
const ASSETS = [
  './index.html',
  './manifest.json',
  './icon-192.png',
  './icon-512.png'
];

// bibliotecas de fora que o app precisa para abrir (guardadas para funcionar sem sinal)
const EXTERNOS = ['cdn.jsdelivr.net', 'fonts.googleapis.com', 'fonts.gstatic.com'];
const ehMapboxLib = (u) => u.hostname === 'api.mapbox.com' && u.pathname.includes('/mapbox-gl-js/');
// previsão do tempo: tenta a rede e, sem sinal, mostra a última que foi guardada
const ehClima = (u) => u.hostname === 'api.open-meteo.com';

self.addEventListener('install', (event) => {
  event.waitUntil(
    caches.open(CACHE_NAME).then((cache) => cache.addAll(ASSETS))
  );
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(
    caches.keys().then((keys) =>
      Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)))
    )
  );
  self.clients.claim();
});

function guardar(request, response) {
  if (response && (response.status === 200 || response.type === 'opaque')) {
    const clone = response.clone();
    caches.open(CACHE_NAME).then((cache) => cache.put(request, clone));
  }
  return response;
}

self.addEventListener('fetch', (event) => {
  const req = event.request;
  if (req.method !== 'GET') return;
  const url = new URL(req.url);

  // dados do usuário (login e banco): nunca guardar, sempre pela rede
  if (url.hostname.endsWith('supabase.co')) return;

  // abrir o app: rede primeiro (pega sempre a versão nova); sem sinal, usa a guardada
  if (req.mode === 'navigate') {
    event.respondWith(
      fetch(req)
        .then((res) => guardar(new Request('./index.html'), res))
        .catch(() => caches.match('./index.html').then((c) => c || caches.match(req)))
    );
    return;
  }

  // previsão do tempo: rede primeiro, cai para a última guardada
  if (ehClima(url)) {
    event.respondWith(
      fetch(req).then((res) => guardar(req, res)).catch(() => caches.match(req))
    );
    return;
  }

  // bibliotecas e fontes: guardadas na primeira vez, atualizadas em segundo plano
  if (EXTERNOS.includes(url.hostname) || ehMapboxLib(url)) {
    event.respondWith(
      caches.match(req).then((cached) => {
        const rede = fetch(req).then((res) => guardar(req, res)).catch(() => cached);
        return cached || rede;
      })
    );
    return;
  }

  // arquivos do próprio app: guardado primeiro, atualizando em segundo plano
  if (url.origin === self.location.origin) {
    event.respondWith(
      caches.match(req).then((cached) => {
        const network = fetch(req)
          .then((response) => {
            if (response && response.status === 200 && response.type === 'basic') {
              const clone = response.clone();
              caches.open(CACHE_NAME).then((cache) => cache.put(req, clone));
            }
            return response;
          })
          .catch(() => cached);
        return cached || network;
      })
    );
  }
  // qualquer outra origem (Spotify, tiles do mapa etc.): segue direto pela rede
});

// ---------- notificações push ----------
self.addEventListener('push', (event) => {
  let dados = { title: 'Pelotão', body: 'Você tem um aviso novo.' };
  try {
    if (event.data) dados = event.data.json();
  } catch (e) {
    if (event.data) dados.body = event.data.text();
  }
  event.waitUntil(
    self.registration.showNotification(dados.title || 'Pelotão', {
      body: dados.body || '',
      icon: './icon-192.png',
      badge: './icon-192.png',
      vibrate: [100, 50, 100],
      data: { url: dados.url || './' }
    })
  );
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  const url = (event.notification.data && event.notification.data.url) || './';
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if (client.url.includes(self.registration.scope) && 'focus' in client) return client.focus();
      }
      if (self.clients.openWindow) return self.clients.openWindow(url);
    })
  );
});
