import { photoPreview, videoPreview } from "./db";
import type { Env } from "./types";

// Link previews for shared media. A link such as /s/v/<id> opens a tiny page
// whose only job is to carry the Open Graph tags (title, description,
// thumbnail) that chat apps read when the link is pasted, and then to send a
// person on to the app. Crawlers do not run scripts, so the redirect is a
// plain meta refresh. The page points at the PWA, never at the media itself.

export const APP_URL = "https://my.wisdompowercc.org";
const DEFAULT_IMAGE = `${APP_URL}/icons/Icon-512.png`;
const CDN = "https://storage.wisdompowercc.org";
const SITE = "WPCC Community";

export type SharePreview = { title: string; description: string; image: string; target: string };

const escapeHtml = (value: string) =>
  value.replace(/&/g, "&amp;").replace(/</g, "&lt;").replace(/>/g, "&gt;").replace(/"/g, "&quot;").replace(/'/g, "&#39;");

const clip = (value: string, max: number) => {
  const flat = value.replace(/\s+/g, " ").trim();
  return flat.length > max ? `${flat.slice(0, max - 1)}…` : flat;
};

export function renderSharePage(preview: SharePreview, canonical: string): string {
  const title = escapeHtml(clip(preview.title, 90));
  const description = escapeHtml(clip(preview.description, 200));
  const image = escapeHtml(preview.image);
  const target = escapeHtml(preview.target);
  const link = escapeHtml(canonical);
  return `<!doctype html>
<html lang="en">
<head>
<meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>${title}</title>
<meta name="robots" content="noindex">
<meta name="description" content="${description}">
<meta property="og:type" content="website">
<meta property="og:site_name" content="${SITE}">
<meta property="og:title" content="${title}">
<meta property="og:description" content="${description}">
<meta property="og:image" content="${image}">
<meta property="og:url" content="${link}">
<meta name="twitter:card" content="summary_large_image">
<meta name="twitter:title" content="${title}">
<meta name="twitter:description" content="${description}">
<meta name="twitter:image" content="${image}">
<link rel="canonical" href="${link}">
<meta http-equiv="refresh" content="0;url=${target}">
</head>
<body style="font-family:system-ui,sans-serif;padding:24px">
<p><a href="${target}">Open ${SITE}</a></p>
</body>
</html>`;
}

/** Only images from our own storage, Spotify and YouTube may be used as a preview thumbnail. */
export function safeImage(value: string | null): string | null {
  if (!value) return null;
  try {
    const url = new URL(value);
    const allowed = url.hostname === "storage.wisdompowercc.org" || url.hostname === "i.scdn.co" || url.hostname.endsWith(".ytimg.com") || url.hostname === "i.ytimg.com";
    return url.protocol === "https:" && allowed ? url.toString() : null;
  } catch {
    return null;
  }
}

const generic = (target: string): SharePreview => ({
  title: SITE,
  description: "Messages, videos, photos and more from Wisdom Power Christian Centre.",
  image: DEFAULT_IMAGE,
  target,
});

/**
 * kind: v = video or livestream, p = photo, a = audio message. Audio lives in
 * the app's own database, so its title and artwork travel in the link.
 */
export async function previewFor(env: Env, kind: string, id: string, query: URLSearchParams): Promise<SharePreview> {
  if (kind === "v") {
    const target = `${APP_URL}/#/media/video/${encodeURIComponent(id)}`;
    const row = await videoPreview(env.DB, id);
    if (!row) return generic(target);
    const image = row.provider === "youtube" ? safeImage(row.thumbnail_url) : row.r2_key ? `${CDN}/${row.r2_key}/w1600.webp` : null;
    return {
      title: row.title || SITE,
      description: row.kind === "live" ? "Watch the livestream on WPCC Community" : "Watch on WPCC Community",
      image: image ?? DEFAULT_IMAGE,
      target,
    };
  }
  if (kind === "p") {
    const target = `${APP_URL}/#/media`;
    const row = await photoPreview(env.DB, id);
    if (!row) return generic(target);
    return {
      title: row.caption || "Photo from WPCC",
      description: "See more photos on WPCC Community",
      image: row.r2_key ? `${CDN}/${row.r2_key}/w1600.webp` : DEFAULT_IMAGE,
      target,
    };
  }
  const target = `${APP_URL}/#/media/${encodeURIComponent(id)}`;
  const title = query.get("t")?.trim();
  return {
    title: title || "A message from WPCC",
    description: "Listen on WPCC Community",
    image: safeImage(query.get("i")) ?? DEFAULT_IMAGE,
    target,
  };
}

export async function handleShare(request: Request, env: Env, kind: string, rawId: string): Promise<Response> {
  let id: string;
  try {
    id = decodeURIComponent(rawId);
  } catch {
    id = "";
  }
  const url = new URL(request.url);
  const valid = /^[A-Za-z0-9_:-]{1,80}$/.test(id);
  // An unknown or malformed link still opens the app with the generic preview.
  const preview = valid ? await previewFor(env, kind, id, url.searchParams) : generic(APP_URL);
  const canonical = `${APP_URL}${url.pathname}${url.search}`;
  return new Response(renderSharePage(preview, canonical), {
    status: 200,
    headers: {
      "content-type": "text/html; charset=utf-8",
      "Cache-Control": "public, max-age=300",
      "X-Content-Type-Options": "nosniff",
      "Referrer-Policy": "no-referrer",
      "Content-Security-Policy": "default-src 'none'; style-src 'unsafe-inline'",
    },
  });
}
