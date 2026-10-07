import { parseCursor, photoFileKey, queryGallery, queryStatus, queryVideos } from "./db";
import { handleShare } from "./share";
import type { Env } from "./types";

// Public, read-only JSON API for the Media page. The data is public content
// (Facebook photos and public YouTube / Facebook videos), so there is no login.
// Abuse is limited by, in order: a method and path allow-list, an Origin
// allow-list (casual scripts and crawlers get 403), a per-IP rate limit,
// strict parameter validation (callers cannot invent new queries), and an edge
// cache so repeated reads never reach D1.

const DEFAULT_LIMIT = { gallery: 40, videos: 50 } as const;
const MAX_LIMIT = 50;
const CLIENT_CACHE_SECONDS = 60;
const EDGE_CACHE_SECONDS = 120;
const CACHE_ORIGIN = "https://media-api.cache.invalid";

const SECURITY_HEADERS: Record<string, string> = {
  "X-Content-Type-Options": "nosniff",
  "Referrer-Policy": "no-referrer",
  "Cross-Origin-Resource-Policy": "cross-origin",
};

export function allowedOrigins(env: Pick<Env, "ALLOWED_ORIGINS">): Set<string> {
  return new Set(
    (env.ALLOWED_ORIGINS ?? "")
      .split(",")
      .map((origin) => origin.trim().replace(/\/$/, ""))
      .filter(Boolean),
  );
}

function reply(body: unknown, status: number, headers: Record<string, string> = {}): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "content-type": "application/json; charset=utf-8", ...SECURITY_HEADERS, ...headers },
  });
}

const cors = (origin: string | null): Record<string, string> =>
  origin
    ? {
        "Access-Control-Allow-Origin": origin,
        "Access-Control-Allow-Methods": "GET, OPTIONS",
        "Access-Control-Allow-Headers": "Accept",
        "Access-Control-Max-Age": "86400",
        Vary: "Origin",
      }
    : {};

type Route = "gallery" | "videos";

/** Validates and normalises the query string. Returns null for a bad request. */
export function parseQuery(url: URL, route: Route): { limit: number; before: string | null } | null {
  const rawLimit = url.searchParams.get("limit");
  let limit: number = DEFAULT_LIMIT[route];
  if (rawLimit !== null) {
    if (!/^\d{1,3}$/.test(rawLimit)) return null;
    limit = Number(rawLimit);
    if (limit < 1 || limit > MAX_LIMIT) return null;
  }
  const before = url.searchParams.get("before");
  if (before !== null && parseCursor(before) === "invalid") return null;
  return { limit, before };
}

/**
 * The stored copy of one photo as a download. The image host sends no CORS
 * headers, so a browser app cannot fetch the bytes from it to save them; this
 * route serves the same file with the app's origin allowed and a filename.
 */
async function servePhotoFile(env: Env, id: string, corsHeaders: Record<string, string>): Promise<Response> {
  const key = await photoFileKey(env.DB, id);
  if (!key) return reply({ error: "not found" }, 404, corsHeaders);
  const object = (await env.MEDIA.get(`${key}/w1600.webp`)) ?? (await env.MEDIA.get(`${key}/w480.webp`));
  if (!object) return reply({ error: "not found" }, 404, corsHeaders);
  return new Response(object.body, {
    status: 200,
    headers: {
      "content-type": "image/webp",
      "Content-Disposition": `attachment; filename="wpcc-photo-${id}.webp"`,
      "Cache-Control": "public, max-age=86400",
      "Access-Control-Expose-Headers": "Content-Disposition",
      ...SECURITY_HEADERS,
      ...corsHeaders,
    },
  });
}

export async function handleApi(request: Request, env: Env, cache?: Cache, ctx?: ExecutionContext): Promise<Response> {
  const url = new URL(request.url);
  const origin = request.headers.get("origin")?.replace(/\/$/, "") ?? null;
  const allowed = allowedOrigins(env);
  const originOk = origin !== null && allowed.has(origin);

  if (request.method === "OPTIONS") {
    return originOk ? new Response(null, { status: 204, headers: { ...SECURITY_HEADERS, ...cors(origin) } }) : reply({ error: "forbidden" }, 403);
  }
  if (request.method !== "GET") return reply({ error: "method not allowed" }, 405, { Allow: "GET, OPTIONS" });

  // Link-preview pages for shared media (/s/v/<id>, /s/p/<id>, /s/a/<id>). They are read by
  // chat apps and crawlers, which send no Origin, so only the rate limit applies.
  const shareMatch = /^\/s\/([vpa])\/([^/]{1,120})$/.exec(url.pathname);
  if (shareMatch) {
    try {
      const { success } = await env.API_LIMITER.limit({ key: request.headers.get("cf-connecting-ip") ?? "unknown" });
      if (!success) return reply({ error: "too many requests" }, 429, { "Retry-After": "60" });
    } catch (error) {
      console.error(JSON.stringify({ event: "media_api_ratelimit_error", error: (error as Error).message }));
    }
    try {
      return await handleShare(request, env, shareMatch[1], shareMatch[2]);
    } catch (error) {
      console.error(JSON.stringify({ event: "media_share_error", error: (error as Error).message }));
      return reply({ error: "unavailable" }, 503);
    }
  }
  const fileMatch = /^\/v1\/photos\/([A-Za-z0-9_-]{1,64})\/file$/.exec(url.pathname);
  const route = fileMatch ? "file" : url.pathname === "/v1/gallery" ? "gallery" : url.pathname === "/v1/videos" ? "videos" : url.pathname === "/v1/status" ? "status" : null;
  if (!route) return reply({ error: "not found" }, 404);
  // Data routes are for the app in a browser: requests from other origins, or
  // without an Origin at all (curl, scripts), are refused.
  if (route !== "status" && !originOk) return reply({ error: "forbidden" }, 403);

  try {
    const { success } = await env.API_LIMITER.limit({ key: request.headers.get("cf-connecting-ip") ?? "unknown" });
    if (!success) return reply({ error: "too many requests" }, 429, { "Retry-After": "60", ...cors(originOk ? origin : null) });
  } catch (error) {
    // The limiter failing must not take the Media page down.
    console.error(JSON.stringify({ event: "media_api_ratelimit_error", error: (error as Error).message }));
  }

  const headers = { "Cache-Control": `public, max-age=${CLIENT_CACHE_SECONDS}`, ...cors(originOk ? origin : null) };

  try {
    if (route === "status") return reply({ sources: await queryStatus(env.DB) }, 200, { ...headers, "Cache-Control": "no-store" });
    if (route === "file") return await servePhotoFile(env, fileMatch![1], cors(originOk ? origin : null));

    const query = parseQuery(url, route);
    if (!query) return reply({ error: "bad request" }, 400, cors(originOk ? origin : null));

    // Canonical cache key: only known parameters, in a fixed order.
    const cacheUrl = `${CACHE_ORIGIN}/v1/${route}?limit=${query.limit}${query.before ? `&before=${encodeURIComponent(query.before)}` : ""}`;
    const cacheKey = new Request(cacheUrl);
    const hit = await cache?.match(cacheKey);
    if (hit) return new Response(hit.body, { status: 200, headers: { "content-type": "application/json; charset=utf-8", ...SECURITY_HEADERS, ...headers, "X-Cache": "hit" } });

    const cursor = parseCursor(query.before);
    const page = route === "gallery" ? await queryGallery(env.DB, cursor === "invalid" ? null : cursor, query.limit) : await queryVideos(env.DB, cursor === "invalid" ? null : cursor, query.limit);
    const body = JSON.stringify(page);
    if (cache) {
      const stored = new Response(body, { headers: { "content-type": "application/json; charset=utf-8", "Cache-Control": `public, max-age=${EDGE_CACHE_SECONDS}` } });
      const write = cache.put(cacheKey, stored);
      if (ctx) ctx.waitUntil(write);
      else await write;
    }
    return new Response(body, { status: 200, headers: { "content-type": "application/json; charset=utf-8", ...SECURITY_HEADERS, ...headers, "X-Cache": "miss" } });
  } catch (error) {
    console.error(JSON.stringify({ event: "media_api_error", error: (error as Error).message }));
    return reply({ error: "unavailable" }, 503, cors(originOk ? origin : null));
  }
}
