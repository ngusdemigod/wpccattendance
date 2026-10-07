import { describe, expect, it } from "vitest";
import { handleApi } from "../src/api";
import { markMirror, upsertPhotos, upsertVideos } from "../src/db";
import { renderSharePage, safeImage } from "../src/share";
import { makeEnv } from "./helpers";

const get = (path: string, headers: Record<string, string> = {}) =>
  new Request(`https://media-api.example.test${path}`, { headers: { "cf-connecting-ip": "203.0.113.7", ...headers } });

const video = (overrides: Record<string, unknown> = {}) => ({
  id: "youtube:abc123",
  provider: "youtube" as const,
  external_id: "abc123",
  title: 'Sunday "Service" <b>',
  description: "d",
  thumbnail_url: "https://i.ytimg.com/vi/abc123/hq.jpg",
  permalink_url: "https://www.youtube.com/watch?v=abc123",
  embed_url: null,
  kind: "video" as const,
  published_at: "2026-09-20T10:00:00.000Z",
  duration_seconds: 600,
  mirror_status: "done" as const,
  format: "standard" as const,
  live_now: 0 as const,
  ...overrides,
});

describe("share pages", () => {
  it("carry the video thumbnail and title, point at the PWA, and need no Origin", async () => {
    const { env } = makeEnv();
    await upsertVideos(env.DB, [video()]);
    const response = await handleApi(get("/s/v/youtube%3Aabc123"), env);
    expect(response.status).toBe(200);
    expect(response.headers.get("content-type")).toContain("text/html");
    const html = await response.text();
    expect(html).toContain('property="og:image" content="https://i.ytimg.com/vi/abc123/hq.jpg"');
    expect(html).toContain("Sunday &quot;Service&quot; &lt;b&gt;");
    expect(html).not.toContain("<b>");
    expect(html).toContain('content="0;url=https://my.wisdompowercc.org/#/media/video/youtube%3Aabc123"');
    expect(html).toContain('rel="canonical" href="https://my.wisdompowercc.org/s/v/youtube%3Aabc123"');
  });

  it("uses the mirrored thumbnail for Facebook videos and never the expiring one", async () => {
    const { env, db } = makeEnv();
    await upsertVideos(env.DB, [video({ id: "facebook:77", provider: "facebook", external_id: "77", thumbnail_url: "https://scontent.fbcdn.net/x.jpg", mirror_status: "pending" })]);
    expect(await (await handleApi(get("/s/v/facebook%3A77"), env)).text()).not.toContain("fbcdn");
    db.sqlite.exec("UPDATE videos SET r2_key = 'media-sync/fb/video-77', mirror_status = 'done' WHERE id = 'facebook:77'");
    const html = await (await handleApi(get("/s/v/facebook%3A77"), env)).text();
    expect(html).toContain("https://storage.wisdompowercc.org/media-sync/fb/video-77/w1600.webp");
  });

  it("uses the photo for photos, and the app icon when nothing is known", async () => {
    const { env } = makeEnv();
    await upsertPhotos(env.DB, [{ id: "9001", caption: "Sunday", permalink: "https://www.facebook.com/photo/1", published_at: "2026-09-01T10:00:00.000Z", width: 1, height: 1, source_url: "https://scontent.xx.fbcdn.net/a.jpg" }]);
    await markMirror(env.DB, { table: "photos", id: "9001", key: "media-sync/fb/photo-9001" }, "done");
    const photo = await (await handleApi(get("/s/p/9001"), env)).text();
    expect(photo).toContain("media-sync/fb/photo-9001/w1600.webp");
    const unknown = await handleApi(get("/s/p/404404"), env);
    expect(unknown.status).toBe(200);
    expect(await unknown.text()).toContain("https://my.wisdompowercc.org/icons/Icon-512.png");
  });

  it("takes an audio title and artwork from the link, but only from trusted image hosts", async () => {
    const { env } = makeEnv();
    const good = await (await handleApi(get("/s/a/ep1?t=Walking%20in%20power&i=https%3A%2F%2Fi.scdn.co%2Fimage%2Fabc"), env)).text();
    expect(good).toContain("Walking in power");
    expect(good).toContain("https://i.scdn.co/image/abc");
    const bad = await (await handleApi(get("/s/a/ep1?t=x&i=https%3A%2F%2Fevil.example.com%2Fa.png"), env)).text();
    expect(bad).not.toContain(`og:image" content="https://evil`);
    expect(bad).toContain(`og:image" content="https://my.wisdompowercc.org/icons/Icon-512.png"`);
    expect(safeImage("http://i.scdn.co/a")).toBeNull();
    expect(safeImage("not a url")).toBeNull();
  });

  it("falls back to the generic preview for malformed ids and escapes everything it prints", async () => {
    const { env } = makeEnv();
    const bad = await handleApi(get("/s/v/%3Cscript%3E"), env);
    expect(bad.status).toBe(200);
    expect(await bad.text()).not.toContain("<script>");
    expect(renderSharePage({ title: '"><script>', description: "<", image: "https://x/'", target: "https://t/?a=1&b=2" }, "https://c")).not.toContain("<script>");
  });

  it("is rate limited, and unknown share kinds are 404", async () => {
    const { env, limiter } = makeEnv();
    expect((await handleApi(get("/s/x/abc"), env)).status).toBe(404);
    limiter.allow = false;
    expect((await handleApi(get("/s/v/abc"), env)).status).toBe(429);
  });
});
