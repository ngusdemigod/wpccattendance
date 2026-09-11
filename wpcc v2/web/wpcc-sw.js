self.addEventListener('push', event => {
  let payload = {};
  try { payload = event.data ? event.data.json() : {}; } catch (_) { payload = { body: event.data ? event.data.text() : '' }; }
  const title = payload.title || 'WPCC Prayer Alert';
  const snooze = Number(payload.snooze_minutes || 0);
  const actions = snooze > 0
    ? [{ action: 'snooze', title: `Snooze ${snooze} min` }, { action: 'open', title: 'Open' }]
    : [{ action: 'open', title: 'Open' }];
  const options = {
    body: payload.body || 'It is time to pray.',
    icon: payload.icon || undefined,
    badge: payload.badge || undefined,
    tag: payload.tag || 'wpcc-prayer-alert',
    data: { ...(payload.data || {}), snooze_minutes: snooze },
    renotify: true,
    actions,
    vibrate: payload.vibration_enabled === false ? undefined : [180, 80, 180]
  };
  event.waitUntil(self.registration.showNotification(title, options));
});

self.addEventListener('notificationclick', event => {
  event.notification.close();
  const data = event.notification.data || {};
  const basePath = data.path || '/prayer-alerts';
  const occurrence = data.occurrence_id || '';
  const snooze = Number(data.snooze_minutes || 0);
  let path = basePath;
  if (event.action === 'snooze' && occurrence && snooze > 0) {
    const glue = basePath.includes('?') ? '&' : '?';
    path = `${basePath}${glue}snooze_occurrence=${encodeURIComponent(occurrence)}&snooze_minutes=${encodeURIComponent(String(snooze))}`;
  }
  event.waitUntil((async () => {
    const clientsList = await clients.matchAll({ type: 'window', includeUncontrolled: true });
    for (const client of clientsList) {
      if ('focus' in client) {
        await client.focus();
        if ('navigate' in client) await client.navigate(path);
        return;
      }
    }
    if (clients.openWindow) await clients.openWindow(path);
  })());
});
