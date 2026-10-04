// Presentation policy only. Authorization always belongs to the backend.
(function (root) {
  function deviceType(nav) {
    const ua = nav.userAgent || '';
    const platform = nav.userAgentData?.platform || nav.platform || '';
    if (/iPhone|iPad|iPod/i.test(ua) ||
        (/Mac/i.test(platform) && /Macintosh/i.test(ua) && nav.maxTouchPoints > 1)) return 'ios';
    if (/Android/i.test(ua) || /Android/i.test(platform)) return 'android';
    return 'desktop';
  }
  function launchState(nav, standalone) {
    const device = deviceType(nav);
    return { device, screen: device === 'desktop' ? 'desktop' : standalone ? 'app' : 'install' };
  }
  const api = Object.freeze({ deviceType, launchState });
  if (typeof module !== 'undefined' && module.exports) module.exports = api;
  else root.wpccDevice = api;
})(typeof window !== 'undefined' ? window : globalThis);
