import { describe, expect, it, vi } from "vitest";
import worker from "../src/index";
import { allowedOrigins, handleApi, parseQuery } from "../src/api";
import { markMirror, upsertPhotos, upsertVideos } from "../src/db";
import { FakeCache, makeEnv } from "./helpers";

const ORIGIN = "https://my.example.test";
const req = (path: string, init: RequestInit & { headers?: Record<string, string> } = {}) =>
  new Request(`https://media-api.example.test${path}`, { ...init, headers: { origin: ORIGIN, "cf-connecting-ip": "203.0.113.7", ...init.headers } });

async function seed(env: ReturnType<typeof makeEnv>["env"], count = 5) {
  const rows = Array.from({ length: count }, (_, i) => ({
    id: String(2000 + i),
    caption: `Photo ${i}`,
    permalink: `https://www.facebook.com/photo/${i}`,
    published_at: new Date(Date.UTC(2026, 8, 1, 10) - i * 3600_000).toISOString(),
    width: 1200,
    height: 800,
    source_url: "https://scontent.xx.fbcdn.net/x.jpg",
  }));
  await upsertPhotos(env.DB, rows);
  for (const row of rows) await markMirror(env.DB, { table: "photos", id: row.id, key: `media-sync/fb/photo-${row.id}` }, "done");
}

describe("access rules", () => {
  it("answers CORS preflight only for allowed origins", async () => {
    const { env } = makeEnv();
    const ok = await handleApi(req("/v1/gallery", { method: "OPTIONS" }), env);
    expect(ok.status).toBe(204);
    expect(ok.headers.get("access-control-allow-origin")).toBe(ORIGIN);
    expect(ok.headers.get("access-control-allow-methods")).toBe("GET, OPTIONS");
    const bad = await handleApi(req("/v1/gallery", { method: "OPTIONS", headers: { origin: "https://evil.example.com" } }), env);
    expect(bad.status).toBe(403);
    expect(bad.headers.get("access-control-allow-origin")).toBeNull();
  });

  it("refuses data requests from other origins or with no Origin (scripts, crawlers)", async () => {
    const { env } = makeEnv();
    await seed(env);
    for (const path of ["/v1/gallery", "/v1/videos"]) {
      expect((await handleApi(req(path, { headers: { origin: "https://evil.example.com" } }), env)).status).toBe(403);
      const noOrigin = new Request(`https://media-api.example.test${path}`);
      const response = await handleApi(noOrigin, env);
      expect(response.status).toBe(403);
      expect(await response.json()).toEqual({ error: "forbidden" });
    }
  });

  it("only allows GET and OPTIONS, and only known paths", async () => {
    const { env } = makeEnv();
    for (const method of ["POST", "PUT", "DELETE", "PATCH"]) {
      const response = await handleApi(req("/v1/gallery", { method }), env);
      expect(response.status).toBe(405);
      expect(response.headers.get("allow")).toBe("GET, OPTIONS");
    }
    expect((await handleApi(req("/"), env)).status).toBe(404);
    expect((await handleApi(req("/v1/admin"), env)).status).toBe(404);
    expect((await handleApi(req("/v1/gallery/extra"), env)).status).toBe(404);
  });

  it("adds security headers to every response", async () => {
    const { env } = makeEnv();
    for (const response of [await handleApi(req("/v1/gallery"), env), await handleApi(req("/nope"), env), await handleApi(req("/v1/gallery", { method: "POST" }), env)]) {
      expect(response.headers.get("x-content-type-options")).toBe("nosniff");
      expect(response.headers.get("referrer-policy")).toBe("no-referrer");
    }
  });

  it("parses the allowed origins list", () => {
    expect([...allowedOrigins({ ALLOWED_ORIGINS: "https://a.test/, http://b.test ,," })]).toEqual(["https://a.test", "http://b.test"]);
    expect(allowedOrigins({ ALLOWED_ORIGINS: "" }).size).toBe(0);
  });
});

describe("rate limiting", () => {
  it("rejects with 429 and Retry-After before touching D1", async () => {
    const { env, limiter } = makeEnv();
    limiter.allow = false;
    const spy = vi.spyOn(env.DB, "prepare");
    const response = await handleApi(req("/v1/gallery"), env);
    expect(response.status).toBe(429);
    expect(response.headers.get("retry-after")).toBe("60");
    expect(response.headers.get("access-control-allow-origin")).toBe(ORIGIN);
    expect(spy).not.toHaveBeenCalled();
    expect(limiter.keys).toEqual(["203.0.113.7"]);
  });

  it("keeps serving if the limiter itself fails", async () => {
    const { env, limiter } = makeEnv();
    await seed(env, 2);
    limiter.throws = true;
    vi.spyOn(console, "error").mockImplementation(() => {});
    expect((await handleApi(req("/v1/gallery"), env)).status).toBe(200);
  });
});

describe("parameters", () => {
  const parse = (query: string, route: "gallery" | "videos" = "gallery") => parseQuery(new URL(`https://x/v1/${route}${query}`), route);
  it("applies defaults and validates limit and cursor", () => {
    expect(parse("")).toEqual({ limit: 40, before: null });
    expect(parse("", "videos")).toEqual({ limit: 50, before: null });
    expect(parse("?limit=12")).toEqual({ limit: 12, before: null });
    for (const bad of ["?limit=0", "?limit=51", "?limit=abc", "?limit=-1", "?limit=1e2", "?limit=1000", "?limit=", "?before=nope", "?before=2026-09-01T10:00:00.000Z|"]) {
      expect(parse(bad), bad).toBeNull();
    }
    expect(parse("?before=2026-09-01T10:00:00.000Z|2001")).toEqual({ limit: 40, before: "2026-09-01T10:00:00.000Z|2001" });
  });

  it("returns 400 for a bad request without leaking details", async () => {
    const { env } = makeEnv();
    const response = await handleApi(req("/v1/gallery?limit=9999"), env);
    expect(response.status).toBe(400);
    expect(await response.json()).toEqual({ error: "bad request" });
  });
});

describe("data", () => {
  it("serves the gallery in pages with a next cursor, newest first", async () => {
    const { env } = makeEnv();
    await seed(env, 5);
    const first = await (await handleApi(req("/v1/gallery?limit=2"), env)).json() as { items: { id: string; r2_key: string }[]; next: string | null };
    expect(first.items.map((item) => item.id)).toEqual(["2000", "2001"]);
    expect(first.items[0].r2_key).toBe("media-sync/fb/photo-2000");
    expect(first.next).toBeTruthy();
    const second = await (await handleApi(req(`/v1/gallery?limit=2&before=${encodeURIComponent(first.next!)}`), env)).json() as { items: { id: string }[]; next: string | null };
    expect(second.items.map((item) => item.id)).toEqual(["2002", "2003"]);
    const last = await (await handleApi(req(`/v1/gallery?limit=2&before=${encodeURIComponent(second.next!)}`), env)).json() as { items: { id: string }[]; next: string | null };
    expect(last.items.map((item) => item.id)).toEqual(["2004"]);
    expect(last.next).toBeNull();
  });

  it("exposes only public fields (no source urls, no internal state)", async () => {
    const { env } = makeEnv();
    await seed(env, 1);
    const body = await (await handleApi(req("/v1/gallery"), env)).text();
    expect(body).not.toContain("source_url");
    expect(body).not.toContain("scontent");
    expect(body).not.toContain("mirror_status");
    expect(body).not.toContain("last_seen_run");
  });

  it("serves videos", async () => {
    const { env } = makeEnv();
    await upsertVideos(env.DB, [{ id: "youtube:v1", provider: "youtube", external_id: "v1", title: "Sunday", description: "d", thumbnail_url: "https://i.ytimg.com/a.jpg", permalink_url: "https://www.youtube.com/watch?v=v1", embed_url: "https://www.youtube-nocookie.com/embed/v1", kind: "live", published_at: "2026-09-20T10:00:00.000Z", duration_seconds: 60, mirror_status: "done", format: "standard", live_now: 1 }]);
    const body = await (await handleApi(req("/v1/videos"), env)).json() as { items: Record<string, unknown>[] };
    expect(body.items).toEqual([expect.objectContaining({ id: "youtube:v1", provider: "youtube", kind: "live", title: "Sunday", format: "standard", live_now: 1 })]);
  });

  describe("photo downloads", () => {
    const put = (media: ReturnType<typeof makeEnv>["media"], key: string, bytes: number[]) => media.objects.set(key, { bytes: new Uint8Array(bytes).buffer as ArrayBuffer });

    it("serves the large copy as an attachment with the app origin allowed", async () => {
      const { env, media } = makeEnv();
      await seed(env, 1);
      put(media, "media-sync/fb/photo-2000/w1600.webp", [1, 2, 3]);
      put(media, "media-sync/fb/photo-2000/w480.webp", [9]);
      const response = await handleApi(req("/v1/photos/2000/file"), env);
      expect(response.status).toBe(200);
      expect(response.headers.get("content-type")).toBe("image/webp");
      expect(response.headers.get("content-disposition")).toBe('attachment; filename="wpcc-photo-2000.webp"');
      expect(response.headers.get("access-control-allow-origin")).toBe(ORIGIN);
      expect(response.headers.get("access-control-expose-headers")).toBe("Content-Disposition");
      expect(new Uint8Array(await response.arrayBuffer())).toEqual(new Uint8Array([1, 2, 3]));
    });

    it("falls back to the small copy, and 404s for unknown, unmirrored or odd ids", async () => {
      const { env, media } = makeEnv();
      await seed(env, 1);
      put(media, "media-sync/fb/photo-2000/w480.webp", [9]);
      expect((await handleApi(req("/v1/photos/2000/file"), env)).status).toBe(200);
      expect((await handleApi(req("/v1/photos/9999/file"), env)).status).toBe(404);
      expect((await handleApi(req("/v1/photos/../file"), env)).status).toBe(404);
      expect((await handleApi(req("/v1/photos/2000/file/extra"), env)).status).toBe(404);
      media.objects.clear();
      expect((await handleApi(req("/v1/photos/2000/file"), env)).status).toBe(404);
    });

    it("follows the same origin and rate limit rules as the other routes", async () => {
      const { env, media, limiter } = makeEnv();
      await seed(env, 1);
      put(media, "media-sync/fb/photo-2000/w1600.webp", [1]);
      expect((await handleApi(req("/v1/photos/2000/file", { headers: { origin: "https://evil.example.com" } }), env)).status).toBe(403);
      expect((await handleApi(new Request("https://media-api.example.test/v1/photos/2000/file"), env)).status).toBe(403);
      limiter.allow = false;
      expect((await handleApi(req("/v1/photos/2000/file"), env)).status).toBe(429);
    });
  });

  it("serves sync status without an Origin so monitoring can poll it", async () => {
    const { env, db } = makeEnv();
    db.sqlite.exec("INSERT INTO sync_state (source, last_success_at, updated_at) VALUES ('youtube', '2026-10-06T10:00:00.000Z', '2026-10-06T10:00:00.000Z')");
    const response = await handleApi(new Request("https://media-api.example.test/v1/status"), env);
    expect(response.status).toBe(200);
    expect(response.headers.get("cache-control")).toBe("no-store");
    expect(await response.json()).toEqual({ sources: [{ source: "youtube", last_success_at: "2026-10-06T10:00:00.000Z", last_error: null }] });
  });

  it("hides internal errors", async () => {
    const { env } = makeEnv();
    vi.spyOn(console, "error").mockImplementation(() => {});
    (env.DB as unknown as { prepare: () => never }).prepare = () => {
      throw new Error("D1 exploded: secret details");
    };
    const response = await handleApi(req("/v1/gallery"), env);
    expect(response.status).toBe(503);
    expect(await response.text()).not.toContain("secret details");
  });
});

describe("edge cache", () => {
  it("serves repeated reads from the cache without querying D1", async () => {
    const { env } = makeEnv();
    await seed(env, 3);
    const cache = new FakeCache();
    const first = await handleApi(req("/v1/gallery?limit=2"), env, cache as unknown as Cache);
    expect(first.headers.get("x-cache")).toBe("miss");
    const spy = vi.spyOn(env.DB, "prepare");
    const second = await handleApi(req("/v1/gallery?limit=2"), env, cache as unknown as Cache);
    expect(second.headers.get("x-cache")).toBe("hit");
    expect(spy).not.toHaveBeenCalled();
    expect(await second.json()).toEqual(await first.json());
    expect(second.headers.get("cache-control")).toBe("public, max-age=60");
  });

  it("uses one cache entry however the query is spelled or padded", async () => {
    const { env } = makeEnv();
    await seed(env, 3);
    const cache = new FakeCache();
    await handleApi(req("/v1/gallery?limit=2"), env, cache as unknown as Cache);
    const spy = vi.spyOn(env.DB, "prepare");
    for (const path of ["/v1/gallery?limit=2&utm_source=x", "/v1/gallery?utm=1&limit=2&cachebust=123"]) {
      expect((await handleApi(req(path), env, cache as unknown as Cache)).headers.get("x-cache")).toBe("hit");
    }
    expect(spy).not.toHaveBeenCalled();
    expect(cache.store.size).toBe(1);
  });

  it("never stores CORS headers in the cache, so any allowed origin gets its own", async () => {
    const { env } = makeEnv();
    await seed(env, 1);
    const cache = new FakeCache();
    await handleApi(req("/v1/gallery"), env, cache as unknown as Cache);
    const stored = [...cache.store.values()][0];
    expect(stored.headers.get("access-control-allow-origin")).toBeNull();
    const other = await handleApi(req("/v1/gallery", { headers: { origin: "http://localhost:8801" } }), env, cache as unknown as Cache);
    expect(other.headers.get("x-cache")).toBe("hit");
    expect(other.headers.get("access-control-allow-origin")).toBe("http://localhost:8801");
  });

  it("the worker fetch handler routes to the API", async () => {
    const { env } = makeEnv();
    const response = await worker.fetch(req("/v1/status", { headers: { origin: "" } }), env, { waitUntil() {} } as unknown as ExecutionContext);
    expect(response.status).toBe(200);
  });
});
