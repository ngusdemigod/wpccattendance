const { test } = require('node:test');
const assert = require('node:assert/strict');
const vm = require('node:vm');
const fs = require('node:fs');
const path = require('node:path');
const policy = require('../web/wpcc-device.js');
const gateSource = fs.readFileSync(path.join(__dirname, '../web/wpcc-install.js'), 'utf8');
const devices = {
  iphone: { userAgent: 'Mozilla/5.0 (iPhone; CPU iPhone OS 18_0 like Mac OS X)', platform: 'iPhone', maxTouchPoints: 5 },
  ipad: { userAgent: 'Mozilla/5.0 (iPad; CPU OS 18_0 like Mac OS X)', platform: 'iPad', maxTouchPoints: 5 },
  ipadDesktop: { userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15)', platform: 'MacIntel', maxTouchPoints: 5 },
  android: { userAgent: 'Mozilla/5.0 (Linux; Android 15; Pixel 9) Mobile', platform: 'Linux armv8l', maxTouchPoints: 5 },
  androidTablet: { userAgent: 'Mozilla/5.0 (Linux; Android 15; SM-X710)', platform: 'Linux armv8l', maxTouchPoints: 5 },
  windowsTouch: { userAgent: 'Mozilla/5.0 (Windows NT 10.0; Win64; x64)', platform: 'Win32', maxTouchPoints: 10 },
  mac: { userAgent: 'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15)', platform: 'MacIntel', maxTouchPoints: 0 },
};
for (const [name, nav] of Object.entries(devices)) {
  const expected = name.startsWith('ipad') || name === 'iphone' ? 'ios' : name.startsWith('android') ? 'android' : 'desktop';
  test(`${name}: device policy is independent of viewport and standalone mode`, () => {
    assert.equal(policy.deviceType(nav), expected);
    assert.equal(policy.launchState(nav, false).screen, expected === 'desktop' ? 'desktop' : 'install');
    assert.equal(policy.launchState(nav, true).screen, expected === 'desktop' ? 'desktop' : 'app');
  });
}
test('unknown devices are not allowed; Android client hints remain supported', () => {
  assert.equal(policy.deviceType({}), 'desktop');
  assert.equal(policy.deviceType({userAgentData:{platform:'Android'}}), 'android');
});

// Minimal event/DOM boundary: execute the actual bootstrap script, not a copy of its logic.
class Element {
  constructor() { this.listeners = {}; this.attributes = {}; this.hidden = false; this.nodes = {}; this.style = {removeProperty(){}}; this.classList = {toggle(){}}; }
  setAttribute(key, value) { this.attributes[key] = value; }
  addEventListener(name, callback) { this.listeners[name] = callback; }
  async fire(name, data = {}) { await this.listeners[name]?.(data); }
  focus() { this.focused = true; }
  remove() { this.removed = true; }
  set innerHTML(html) {
    this.html = html;
    for (const match of html.matchAll(/<[^>]+id="([^"]+)"[^>]*>/g)) {
      const element = new Element(); element.hidden = /\shidden/.test(match[0]); this.nodes['#' + match[1]] = element;
    }
  }
  querySelector(selector) { return this.nodes[selector]; }
}
function boot(nav, standalone = false) {
  const events = {};
  const modes = [];
  const body = {append(element) { this.gate = element; }};
  const document = {body, documentElement:{dataset:{}}, getElementById:()=>new Element(),createElement:()=>new Element()};
  const window = {wpccDevice:policy,addEventListener:(name, callback)=>events[name]=callback};
  vm.runInNewContext(gateSource, {window,document,navigator:nav,location:{hostname:'wpcc.example.test'},matchMedia:()=>{
    const mode={matches:standalone,addEventListener:(name,callback)=>mode.listener=callback,removeEventListener:()=>{mode.listener=null;}};modes.push(mode);return mode;
  }});
  let resolved = false;
  window.wpccInstalledLaunch.then(()=>resolved=true);
  return {window,document,events,modes,gate:body.gate,isResolved:()=>resolved};
}
test('mobile browser selects the matching panel and supports manual/keyboard tabs', async () => {
  const b = boot(devices.ipadDesktop);
  const ios=b.gate.querySelector('#tab-ios'), android=b.gate.querySelector('#tab-android');
  assert.equal(ios.attributes['aria-selected'],'true');
  assert.equal(b.gate.querySelector('#steps-android').hidden,true);
  await android.fire('click');
  assert.equal(android.attributes['aria-selected'],'true');
  assert.equal(b.gate.querySelector('#steps-ios').hidden,true);
  await android.fire('keydown',{key:'Home',preventDefault(){}});
  assert.equal(ios.focused,true);
  assert.equal(ios.tabIndex,0);
  assert.equal(android.tabIndex,-1);
  assert.equal(b.isResolved(),false);
});
test('desktop standalone is blocked, supported standalone bypasses the guide', async () => {
  const desktop=boot(devices.mac,true), mobile=boot(devices.iphone,true);
  await Promise.resolve();
  assert.match(desktop.gate.html,/Use a phone or tablet/);
  assert.equal(desktop.isResolved(),false);
  assert.equal(mobile.gate,undefined);
  assert.equal(mobile.isResolved(),true);
});
for (const outcome of ['accepted','dismissed','error']) {
  test(`Android install ${outcome} keeps the browser blocked and instructions available`, async () => {
    const b=boot(devices.android), button=b.gate.querySelector('#install-action');
    assert.equal(b.gate.querySelector('#tab-android').attributes['aria-selected'],'true');
    assert.equal(button.hidden,true);
    let prompts=0;
    b.events.beforeinstallprompt({preventDefault(){},prompt:async()=>{prompts++;if(outcome==='error')throw Error('unavailable');},userChoice:Promise.resolve({outcome})});
    assert.equal(button.hidden,false);
    await button.fire('click');
    await button.fire('click');
    assert.equal(prompts,1);
    assert.equal(b.isResolved(),false);
    assert.equal(b.gate.removed,undefined);
    b.events.appinstalled(); await Promise.resolve();
    assert.equal(b.isResolved(),false);
    b.modes[0].matches=true;b.modes[0].listener();await Promise.resolve();
    assert.equal(b.isResolved(),true);
    assert.equal(b.gate.removed,true);
  });
}

test('installation interactions use short motion and immediate reduced-motion states', () => {
  const css = fs.readFileSync(path.join(__dirname, '../web/wpcc-install.css'), 'utf8');
  assert.match(css, /\.install-tabs button\{[^}]*background \.18s cubic-bezier\(\.23,1,\.32,1\)/);
  assert.match(css, /\.install-steps\{[^}]*install-panel-in \.18s cubic-bezier\(\.23,1,\.32,1\)/);
  assert.match(css, /#install-action\{[^}]*transform \.14s cubic-bezier\(\.23,1,\.32,1\)/);
  assert.match(css, /#install-action:active\{[^}]*transition-duration:\.1s/);
  assert.match(css, /prefers-reduced-motion:reduce\)[\s\S]*animation:none[\s\S]*transition:none!important[\s\S]*transform:none!important/);
  assert.match(css, /\.install-sheet\{[^}]*install-page-in \.48s/);
});
