// StorePulse Dedicated Web Push Service Worker for iOS & Modern Browsers
self.addEventListener('install', (event) => {
  self.skipWaiting();
});

self.addEventListener('activate', (event) => {
  event.waitUntil(self.clients.claim());
});

self.addEventListener('message', (event) => {
  if (event.data && event.data.type === 'SHOW_NOTIFICATION') {
    const title = event.data.title || 'Order #1794';
    const body = event.data.body || '₹6,555.00, 1 item from Online Store •\nFolkthreads';
    const options = {
      body: body,
      icon: 'icons/shopify_logo.png',
      badge: 'icons/shopify_logo.png',
      tag: 'storepulse-order-' + Date.now(),
      renotify: true,
      requireInteraction: false,
      vibrate: [200, 100, 200],
      data: {
        dateOfArrival: Date.now(),
        primaryKey: 'storepulse-notification'
      }
    };
    event.waitUntil(
      self.registration.showNotification(title, options)
    );
  }
});

self.addEventListener('notificationclick', (event) => {
  event.notification.close();
  event.waitUntil(
    self.clients.matchAll({ type: 'window', includeUncontrolled: true }).then((clientList) => {
      for (const client of clientList) {
        if ('focus' in client) {
          return client.focus();
        }
      }
      if (self.clients.openWindow) {
        return self.clients.openWindow('/');
      }
    })
  );
});
