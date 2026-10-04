const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const vm = require('node:vm');
const path = require('node:path');

function bridge() {
  const html = fs.readFileSync(path.join(__dirname, '../web/index.html'), 'utf8');
  const script = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)]
    .map(match => match[1]).find(source => source.includes('wpccSpotifyLoadAndPlay'));
  const window = {};
  vm.runInNewContext(script, { window, document: { getElementById: () => ({}) } });
  const calls = [];
  const listeners = {};
  const controller = Object.fromEntries(['loadEntity', 'play', 'resume', 'pause', 'seek']
    .map(name => [name, (...args) => calls.push([name, ...args])]));
  controller.addListener = (name, callback) => { listeners[name] = callback; };
  return { window, calls, listeners, connect: () => window.onSpotifyIframeApiReady({
    createController: (_, options, callback) => callback(controller),
  }) };
}

test('one play is queued immediately, without waiting for ready or duplicate resume', () => {
  const b = bridge(); b.connect();
  b.window.wpccSpotifyLoadAndPlay('spotify:episode:first');
  assert.deepEqual(b.calls, [['loadEntity', 'spotify:episode:first', false, 0], ['play']]);
  b.listeners.ready(); b.listeners.ready();
  assert.equal(b.calls.length, 2);
});

test('only the latest selection starts after API initialization', () => {
  const b = bridge();
  b.window.wpccSpotifyLoadAndPlay('first');
  b.window.wpccSpotifyLoadAndPlay('second'); b.connect();
  assert.deepEqual(b.calls, [['loadEntity', 'second', false, 0], ['play']]);
});

test('closing before initialization cancels pending playback', () => {
  const b = bridge(); b.window.wpccSpotifyLoadAndPlay('first');
  b.window.wpccSpotifyPause(); b.connect(); b.listeners.ready();
  assert.deepEqual(b.calls, []);
});

test('paused playback resumes on the first retry; playing playback pauses', () => {
  const b = bridge(); b.connect(); b.window.wpccSpotifyLoadAndPlay('first');
  b.window.wpccSpotifyTogglePlay();
  assert.deepEqual(b.calls.at(-1), ['resume']);
  b.listeners.playback_update({data: {isPaused: false, position: 1000, duration: 5000}});
  b.window.wpccSpotifyTogglePlay();
  assert.deepEqual(b.calls.at(-1), ['pause']);
});
