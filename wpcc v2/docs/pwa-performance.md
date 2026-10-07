# PWA performance and Vercel headers

Goal: cold start and repeat launches that feel native. Nothing here changes
authentication, profile, reward, ledger or installation-gating behaviour.

## What the app does at startup

1. `index.html` paints a branded splash from inline CSS and a 10 KB logo
   (`splash-logo.png`). It uses the system font stack, so no third-party
   stylesheet blocks first paint.
2. `wpcc-install.js` decides whether this is a supported installed launch.
   Only then is `main.dart.js` preloaded and `flutter_bootstrap.js` allowed to
   start Flutter. Browser tabs and desktops still stop at the install page.
3. Flutter downloads `main.dart.js`, CanvasKit (from `www.gstatic.com`, in
   parallel) and every font in `FontManifest.json`, then runs `main()`.
4. `main()` only reads the stored Supabase session (no network), then calls
   `runApp`. The splash fades on the engine's `flutter-first-frame` event.
5. About 2.5 s later `CacheWarmup` fills the SWR cache for Media and Events so
   those tabs open instantly. The Spotify SDK loads when the browser is idle
   after the first frame.

## Recommended Vercel response headers (Build Output API)

Flutter 3.44 ships a `flutter_service_worker.js` that only unregisters itself,
so there is no service-worker cache. HTTP caching is the whole story. Files
that are not content-hashed must revalidate (cheap `304` via ETag); only files
whose name changes with their content, or that are versioned by path, can be
`immutable`.

Paste these routes at the top of `.vercel/output/config.json`, before
`{ "handle": "filesystem" }`. Every entry uses `"continue": true` so routing
carries on to the filesystem and the SPA fallback.

```json
{
  "version": 3,
  "routes": [
    {
      "src": "^/(?:index\\.html|flutter_bootstrap\\.js|flutter\\.js|main\\.dart\\.js(?:_\\d+\\.part\\.js)?|flutter_service_worker\\.js|version\\.json|manifest\\.json|wpcc-[a-z-]+\\.(?:js|css))?$",
      "headers": { "cache-control": "public, max-age=0, must-revalidate" },
      "continue": true
    },
    {
      "src": "^/assets/(?:AssetManifest\\.bin(?:\\.json)?|FontManifest\\.json|NOTICES)$",
      "headers": { "cache-control": "public, max-age=0, must-revalidate" },
      "continue": true
    },
    {
      "src": "^/assets/(?:fonts|packages|shaders)/.+$",
      "headers": { "cache-control": "public, max-age=2592000, stale-while-revalidate=86400" },
      "continue": true
    },
    {
      "src": "^/assets/assets/(?:DMSans|Manrope)-.+\\.ttf$",
      "headers": { "cache-control": "public, max-age=2592000, stale-while-revalidate=86400" },
      "continue": true
    },
    {
      "src": "^/assets/assets/images/.+$",
      "headers": { "cache-control": "public, max-age=604800, stale-while-revalidate=2592000" },
      "continue": true
    },
    {
      "src": "^/(?:icons/.+|splash-logo\\.png)$",
      "headers": { "cache-control": "public, max-age=2592000, stale-while-revalidate=86400" },
      "continue": true
    },
    {
      "src": "^/canvaskit/.+$",
      "headers": { "cache-control": "public, max-age=31536000, immutable" },
      "continue": true
    },
    { "handle": "filesystem" },
    {
      "src": "/.*",
      "dest": "/index.html",
      "headers": { "cache-control": "public, max-age=0, must-revalidate" }
    }
  ]
}
```

Notes on the choices:

* The first pattern's trailing `?` also matches `/` (the install entry).
  `index.html`, `flutter_bootstrap.js`, `main.dart.js` and
  `flutter_service_worker.js` must never be cached without revalidation:
  they pin the app version, and an old service worker can only be replaced if
  the browser can fetch the new stub.
* The SPA fallback route repeats the no-cache header because a rewritten
  `/index.html` response does not inherit headers from the earlier routes.
* `fonts`, `packages` and the bundled DM Sans/Manrope files are not
  fingerprinted, so they are long-lived with stale-while-revalidate rather than
  `immutable`. They only change when a dependency or font file changes.
* `/canvaskit/*` is `immutable` only because it is unreachable by default:
  the standard `flutter build web` loads CanvasKit from
  `https://www.gstatic.com/flutter-canvaskit/<engine revision>/`, which Google
  already serves as immutable. In that case delete the folder from the deploy
  (`node tool/trim_web_build.cjs build/web --drop-unused-canvaskit`, about
  30 MB of every renderer variant). If you ever self-host CanvasKit, serve it
  from a path that includes the engine revision (set `canvasKitBaseUrl`);
  otherwise `immutable` would pin a stale engine after a Flutter upgrade.
* Vercel compresses text, `.js`, `.wasm` and `.ttf` responses with brotli or
  gzip automatically; do not set `content-encoding` by hand.

Optional, faster repeat launches: give `main.dart.js` and
`flutter_bootstrap.js` `public, max-age=0, stale-while-revalidate=604800`
so the previous version starts instantly and the new one is fetched in the
background. The trade-off is that a member can run the previous version for one
extra launch after each deploy. Not applied by default.

## Build and trim steps

```
flutter build web --release --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_PUBLISHABLE_KEY=...
node tool/trim_web_build.cjs build/web --drop-unused-canvaskit
```

`trim_web_build.cjs` removes the Phosphor Thin, Light and Duotone fonts from
the output and from `FontManifest.json`. Flutter downloads every manifest font
before the first frame, and those three are about 1.5 MB. The app only uses
Regular, Fill and Bold, and `test/phosphor_weights_test.dart` fails if code
starts using another weight.

## Measurements

Table at the bottom of this file, from
`flutter build web --release --output build/web_perf`.

## Not done, and why

* **Persisting the SWR cache to storage.** It would make Home and Media paint
  from the previous session, but the providers only re-read data when a screen
  is rebuilt, so a stale persisted value would stay on screen until the member
  pulled to refresh. It needs a "refreshed" notification wired into every
  provider first.
* **Shortening the returning-member splash.** `PwaOnboarding(splashOnly)` runs
  a roughly 1.2 s reveal after the first frame. It is protected design
  (`design.md`: keep splash choreography unchanged); the content underneath is
  already building during the reveal. Product decision for the lead.
* **A custom caching service worker.** Flutter removed its own because stale
  shells after a deploy are hard to reason about; ETag revalidation plus the
  headers above gets most of the benefit without that risk.
* **Wasm (`--wasm`) build.** Needs cross-origin isolation headers for
  multi-threading and interacts with the Spotify iframe and cross-origin media.
* **Subsetting Phosphor Regular/Fill/Bold to the glyphs in use.** Would save a
  further ~1 MB, but other agents are adding icons right now. Revisit after the
  UI freeze (pyftsubset over the three TTFs, then regenerate).
* **Recompressing `assets/images/profile_reward_badge.png` (1.5 MB).** It loads
  only on the award screen; left alone because it is user-supplied artwork.

## Measurements (build/web_perf vs the previous build/web)

| Item | Before | After |
|---|---|---|
| `main.dart.js` | 5,026,676 B (1.47 MB gzip) | 4,176,920 B (1.22 MB gzip) |
| Deferred receipt/PDF code, loaded on first receipt save | in `main.dart.js` | `main.dart.js_1.part.js` 922 KB (273 KB gzip) |
| Phosphor fonts, downloaded before first frame | 2.64 MB (6 weights) | 1.26 MB (Regular, Fill, Bold) after `trim_web_build.cjs` |
| DM Sans + Manrope TTFs | 252 KB | unchanged (bundled; runtime font fetching now disabled) |
| First-paint requests to third parties | Google Fonts CSS and font files (render blocking) | none; `preconnect` only |
| Splash logo | 195 KB PNG | 10.6 KB PNG |
| `canvaskit/` in the deploy folder | 38.5 MB (unused, CDN default) | removed by `--drop-unused-canvaskit` |
| Deploy folder total | 51.6 MB | 11.8 MB |
