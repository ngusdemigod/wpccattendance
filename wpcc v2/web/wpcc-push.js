(function () {
  function b64ToUint8Array(value) {
    const padding = '='.repeat((4 - value.length % 4) % 4);
    const base64 = (value + padding).replace(/-/g, '+').replace(/_/g, '/');
    const raw = atob(base64);
    return Uint8Array.from([...raw].map(c => c.charCodeAt(0)));
  }

  window.wpccPush = {
    async supported() {
      return 'serviceWorker' in navigator && 'PushManager' in window && 'Notification' in window;
    },
    async subscribe(vapidPublicKey) {
      if (!(await this.supported())) throw new Error('Push is not supported on this browser');
      const permission = await Notification.requestPermission();
      if (permission !== 'granted') throw new Error('Notification permission was not granted');
      // Use a dedicated narrow scope so this push worker does not replace Flutter's
      // generated root service worker / offline cache. Push does not require the
      // worker to control the current page.
      const registration = await navigator.serviceWorker.register('./wpcc-sw.js', { scope: './wpcc-push-scope/' });
      let subscription = await registration.pushManager.getSubscription();
      if (!subscription) {
        subscription = await registration.pushManager.subscribe({
          userVisibleOnly: true,
          applicationServerKey: b64ToUint8Array(vapidPublicKey)
        });
      }
      return subscription.toJSON();
    }
  };
})();
