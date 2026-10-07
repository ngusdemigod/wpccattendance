// Stages a Flutter web build as a Vercel "Build Output API" folder, so it can be
// deployed with `vercel deploy --prebuilt`. Flutter cannot be built on Vercel's
// own build machines, so the build happens in CI and only the result is uploaded.
//
//   node tool/stage_vercel_output.mjs build/web build/vercel-output
//
// Writes <out>/.vercel/output/static (the build) and <out>/.vercel/output/config.json:
//   - cache headers (see docs/pwa-performance.md): the app shell revalidates on every
//     load, fonts and icons are cached for a month, images for a week;
//   - the link-preview proxy: /s/v|p|a/<id> is answered by the media worker, which
//     returns the thumbnail and title tags that chat apps read;
//   - the filesystem, then the single-page-app fallback to /index.html.
// It also writes <out>/microfrontends.json (see below).
import { cpSync, mkdirSync, rmSync, writeFileSync } from "node:fs";
import { join } from "node:path";

const [buildDir, outDir] = process.argv.slice(2);
if (!buildDir || !outDir) {
  console.error("usage: node tool/stage_vercel_output.mjs <flutter build dir> <output dir>");
  process.exit(2);
}

const output = join(outDir, ".vercel", "output");
rmSync(output, { recursive: true, force: true });
mkdirSync(join(output, "static"), { recursive: true });
// Files that would clash with the project's own routing are not uploaded.
cpSync(buildDir, join(output, "static"), {
  recursive: true,
  filter: (source) => !/(?:^|[\\/])(?:\.env\.local|vercel\.json|microfrontends\.json|\.gitignore|\.vercel)$/.test(source),
});

const revalidate = "public, max-age=0, must-revalidate";
const month = "public, max-age=2592000, stale-while-revalidate=86400";
const cache = (src, value) => ({ src, headers: { "cache-control": value }, continue: true });

const config = {
  version: 3,
  routes: [
    cache("^/(?:index\\.html|flutter_bootstrap\\.js|flutter\\.js|main\\.dart\\.js(?:_\\d+\\.part\\.js)?|flutter_service_worker\\.js|version\\.json|manifest\\.json|wpcc-[a-z-]+\\.(?:js|css))?$", revalidate),
    cache("^/assets/(?:AssetManifest\\.bin(?:\\.json)?|FontManifest\\.json|NOTICES)$", revalidate),
    cache("^/assets/(?:fonts|packages|shaders)/.+$", month),
    cache("^/assets/assets/(?:DMSans|Manrope)-.+\\.ttf$", month),
    cache("^/assets/assets/images/.+$", "public, max-age=604800, stale-while-revalidate=2592000"),
    cache("^/(?:icons/.+|splash-logo\\.png)$", month),
    { src: "^/s/([vpa])/([^/]+)$", dest: "https://media-api.wisdompowercc.org/s/$1/$2" },
    { handle: "filesystem" },
    { src: "/.*", dest: "/index.html", headers: { "cache-control": revalidate } },
  ],
};
writeFileSync(join(output, "config.json"), JSON.stringify(config, null, 2));

// This project is the default app of the "wpcc-platform" microfrontends group, which
// sends /admin to the wpcc-admin project. Vercel reads this file from the root of the
// deployment folder (next to .vercel), and the application name must match the Vercel
// project name. If the project is ever renamed or replaced, change it here too.
const microfrontends = {
  $schema: "https://openapi.vercel.sh/microfrontends.json",
  applications: {
    "wpcc-community": { development: { fallback: "https://my.wisdompowercc.org" } },
    "wpcc-admin": {
      packageName: "admin",
      routing: [{ group: "admin", paths: ["/admin", "/admin/:path*"] }],
    },
  },
};
writeFileSync(join(outDir, "microfrontends.json"), JSON.stringify(microfrontends, null, 2));
console.log(`staged ${buildDir} -> ${output}`);
