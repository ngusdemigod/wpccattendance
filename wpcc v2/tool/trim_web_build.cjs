#!/usr/bin/env node
// Post-build size trim for the Flutter web output. Run after `flutter build web`
// and before staging/deploying:
//
//   node tool/trim_web_build.cjs build/web [--drop-unused-canvaskit]
//
// 1. Removes Phosphor icon weights the app never uses. Flutter downloads every
//    font in FontManifest.json before the first frame, and the package ships six
//    weights of roughly 0.5 MB each. The app uses Regular, Fill and Bold only
//    (guarded by test/phosphor_weights_test.dart).
// 2. With --drop-unused-canvaskit, deletes the bundled canvaskit/ folder when
//    the build loads CanvasKit from www.gstatic.com (the default), because the
//    folder is then dead weight (about 30 MB of every variant) in the deploy.
'use strict';
const fs = require('node:fs');
const path = require('node:path');

const args = process.argv.slice(2);
const root = path.resolve(args.find((a) => !a.startsWith('--')) || 'build/web');
const dropCanvaskit = args.includes('--drop-unused-canvaskit');
const UNUSED = ['PhosphorThin', 'PhosphorLight', 'PhosphorDuotone'];

const manifestPath = path.join(root, 'assets', 'FontManifest.json');
if (!fs.existsSync(manifestPath)) {
  console.error(`No FontManifest.json under ${root}. Build first.`);
  process.exit(1);
}
let saved = 0;
const manifest = JSON.parse(fs.readFileSync(manifestPath, 'utf8'));
const kept = [];
for (const family of manifest) {
  if (!UNUSED.some((name) => family.family.endsWith('/' + name))) {
    kept.push(family);
    continue;
  }
  for (const font of family.fonts) {
    const file = path.join(root, 'assets', font.asset);
    if (fs.existsSync(file)) {
      saved += fs.statSync(file).size;
      fs.rmSync(file);
    }
  }
  console.log(`removed font family ${family.family}`);
}
fs.writeFileSync(manifestPath, JSON.stringify(kept));

if (dropCanvaskit) {
  const bootstrap = fs.readFileSync(path.join(root, 'flutter_bootstrap.js'), 'utf8');
  const local = /"useLocalCanvasKit"\s*:\s*true/.test(bootstrap);
  const dir = path.join(root, 'canvaskit');
  if (local) {
    console.log('build uses local CanvasKit; keeping canvaskit/');
  } else if (fs.existsSync(dir)) {
    const size = (d) => fs.readdirSync(d, { withFileTypes: true }).reduce(
      (n, e) => n + (e.isDirectory() ? size(path.join(d, e.name)) : fs.statSync(path.join(d, e.name)).size), 0);
    saved += size(dir);
    fs.rmSync(dir, { recursive: true });
    console.log('removed unused canvaskit/ (CanvasKit loads from gstatic)');
  }
}
console.log(`saved ${(saved / 1048576).toFixed(2)} MB`);
