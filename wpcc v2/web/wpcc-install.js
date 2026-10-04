// Gate before Flutter downloads/starts. Installation never substitutes for authentication.
(() => {
  const modes = ['standalone', 'minimal-ui', 'window-controls-overlay']
    .map(mode => matchMedia('(display-mode: ' + mode + ')'));
  const installed = () => navigator.standalone === true || modes.some(mode => mode.matches);
  const { device, screen } = window.wpccDevice.launchState(navigator, installed());
  let promptEvent;
  let installButton;
  let status;
  window.addEventListener('beforeinstallprompt', event => {
    if (device !== 'android') return;
    event.preventDefault();
    promptEvent = event;
    if (installButton) installButton.hidden = false;
  });
  // TEMP-LOCAL-DEV: remove this constant and the `|| localDevBypass` below when PWA-only gating should apply locally again.
  const localDevBypass = ['localhost', '127.0.0.1'].includes(location.hostname);
  window.wpccInstalledLaunch = new Promise(resolve => {
    if (screen === 'app' || localDevBypass) {
      document.documentElement.dataset.installedLaunch = 'true';
      resolve();
      return;
    }
    const splash = document.getElementById('wpcc-splash');
    if (splash) splash.style.display = 'none';
    const gate = document.createElement('main');
    gate.id = 'wpcc-install';
    gate.setAttribute('aria-label', screen === 'desktop' ? 'Supported devices' : 'Add WPCC Community to your home screen');
    const heading = screen === 'desktop' ? 'Use a phone or tablet' : 'Add WPCC to your home screen';
    const intro = screen === 'desktop'
      ? 'WPCC Community is available on iPhone, iPad and Android phones and tablets. Open this website on your mobile device, then add it to your home screen.'
      : 'Install it once, then open it from your home screen like a regular app.';
    gate.innerHTML = `
      <div class="install-sheet"><div class="install-content">
        <header class="install-header">
          <div class="install-logo"><img src="assets/assets/images/wpcc_logo.png" alt="WPCC logo"></div>
          <div class="install-title"><h1>${heading}</h1><p>${intro}</p></div>
        </header>
        ${screen === 'desktop' ? '<p class="install-note">Desktop browsers and desktop-installed apps are not supported.</p>' : `
        <div class="install-tabs" role="tablist" aria-label="Installation steps">
          <button id="tab-ios" type="button" role="tab" aria-controls="steps-ios">iPhone / iPad</button>
          <button id="tab-android" type="button" role="tab" aria-controls="steps-android">Android</button>
        </div>
        <section class="install-panel">
          <div class="install-steps" id="steps-ios" role="tabpanel" aria-labelledby="tab-ios" tabindex="0">
            <div class="install-step"><span class="install-num" aria-hidden="true">1</span><div><h3>Open in Safari</h3><p>Open WPCC Community in Safari on your iPhone or iPad. If you’re inside another app, copy the website address and open it in Safari.</p></div></div>
            <div class="install-step"><span class="install-num" aria-hidden="true">2</span><div><h3>Open the Share menu</h3><p>Tap <strong>Share</strong> (the square with an upward arrow). It may be inside the browser’s More menu.</p></div></div>
            <div class="install-step"><span class="install-num" aria-hidden="true">3</span><div><h3>Choose “Add to Home Screen”</h3><p>Choose <strong>Add to Home Screen</strong>, keep <strong>Open as Web App</strong> enabled if shown, then tap <strong>Add</strong>.</p></div></div>
          </div>
          <div class="install-steps" id="steps-android" role="tabpanel" aria-labelledby="tab-android" tabindex="0">
            <div class="install-step"><span class="install-num" aria-hidden="true">1</span><div><h3>Open in Chrome</h3><p>Open WPCC Community in Chrome on your Android phone or tablet. If you’re inside another app, open the link in Chrome first.</p></div></div>
            <div class="install-step"><span class="install-num" aria-hidden="true">2</span><div><h3>Open the browser menu</h3><p>Tap the <strong>three-dot menu</strong> in the top-right corner.</p></div></div>
            <div class="install-step"><span class="install-num" aria-hidden="true">3</span><div><h3>Choose “Add to Home screen”</h3><p>Tap <strong>Add to Home screen</strong> or <strong>Install app</strong>, then confirm.</p></div></div>
          </div>
        </section>
        <button id="install-action" type="button" hidden>Install WPCC</button>
        <p id="install-status" class="install-note" role="status">Already installed? Close this page and open WPCC Community from your home screen.</p>`}
      </div></div>`;
    document.body.append(gate);
    if (screen === 'desktop') return; // Desktop standalone mode must not unlock Flutter.
    const tabs = [gate.querySelector('#tab-ios'), gate.querySelector('#tab-android')];
    const panels = [gate.querySelector('#steps-ios'), gate.querySelector('#steps-android')];
    const activate = (index, focus = false) => {
      tabs.forEach((tab, i) => {
        const selected = i === index;
        tab.classList.toggle('active', selected);
        tab.setAttribute('aria-selected', String(selected));
        tab.tabIndex = selected ? 0 : -1;
        panels[i].hidden = !selected;
      });
      if (focus) tabs[index].focus();
    };
    tabs.forEach((tab, index) => {
      tab.addEventListener('click', () => activate(index));
      tab.addEventListener('keydown', event => {
        if (!['ArrowLeft', 'ArrowRight', 'Home', 'End'].includes(event.key)) return;
        event.preventDefault();
        activate(event.key === 'Home' ? 0 : event.key === 'End' ? 1 : 1 - index, true);
      });
    });
    activate(device === 'ios' ? 0 : 1);
    installButton = gate.querySelector('#install-action');
    status = gate.querySelector('#install-status');
    installButton.hidden = !promptEvent;
    installButton.addEventListener('click', async () => {
      if (!promptEvent) return;
      const pending = promptEvent;
      promptEvent = null;
      installButton.hidden = true;
      try {
        await pending.prompt();
        const result = await pending.userChoice;
        status.textContent = result.outcome === 'accepted'
          ? 'Installation requested. When it finishes, open WPCC from your home screen.'
          : 'You can still install WPCC using the steps above.';
      } catch (_) {
        status.textContent = 'Use the browser menu and follow the steps above to install WPCC.';
      }
    });
    window.addEventListener('appinstalled', () => {
      promptEvent = null;
      installButton.hidden = true;
      status.textContent = 'WPCC is installed. Open it from your home screen to continue.';
    });
    const checkLaunch = () => {
      if (window.wpccDevice.launchState(navigator, installed()).screen !== 'app') return;
      document.documentElement.dataset.installedLaunch = 'true';
      gate.remove();
      if (splash) splash.style.removeProperty('display');
      modes.forEach(mode => mode.removeEventListener('change', checkLaunch));
      resolve();
    };
    modes.forEach(mode => mode.addEventListener('change', checkLaunch));
    checkLaunch();
  });
})();
