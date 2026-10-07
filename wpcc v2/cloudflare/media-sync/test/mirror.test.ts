import { afterEach, describe, expect, it, vi } from "vitest";
import worker from "../src/index";
import { MAX_BYTES, mirrorImage, PermanentError, validateJob } from "../src/mirror";
import { upsertPhotos } from "../src/db";
import type { MirrorJob } from "../src/types";
import { fakeImages, imageResponse, makeEnv, mockFetch, photoJob } from "./helpers";

let restore: (() => void) | undefined;
afterEach(() => {
  restore?.();
  restore = undefined;
  vi.restoreAllMocks();
});

const row = (id = "100200300") => ({ id, caption: "", permalink: "https://www.facebook.com/photo/1", published_at: "2026-09-01T10:00:00.000Z", width: 1000, height: 700, source_url: "https://scontent.xx.fbcdn.net/a.jpg" });
const stored = (db: { all: (sql: string) => unknown[] }) => db.all("SELECT mirror_status, r2_key, width, height FROM photos");

describe("size cap", () => {
  it("is 3 MB", () => {
    expect(MAX_BYTES).toBe(3 * 1024 * 1024);
  });
});

describe("mirrorImage", () => {
  it("stores two compressed webp copies (w480 last) with immutable caching, and no original", async () => {
    const { env, media, db } = makeEnv({ IMAGES: fakeImages({ width: 1200, height: 800 }) });
    await upsertPhotos(env.DB, [row()]);
    const mock = mockFetch(() => imageResponse("image/jpeg"));
    restore = mock.restore;

    await mirrorImage(env, photoJob());
    expect(media.putOrder).toEqual(["media-sync/fb/photo-100200300/w1600.webp", "media-sync/fb/photo-100200300/w480.webp"]);
    expect(media.objects.has("media-sync/fb/photo-100200300/original")).toBe(false);
    for (const object of media.objects.values()) {
      expect(object.contentType).toBe("image/webp");
      expect(object.cacheControl).toBe("public, max-age=31536000, immutable");
    }
    expect(stored(db)).toEqual([{ mirror_status: "done", r2_key: "media-sync/fb/photo-100200300", width: 1200, height: 800 }]);
  });

  it("falls back to the source bytes when resizing is unavailable", async () => {
    const { env, media } = makeEnv({ IMAGES: fakeImages({ fail: true }) });
    await upsertPhotos(env.DB, [row()]);
    const mock = mockFetch(() => imageResponse("image/png"));
    restore = mock.restore;
    await mirrorImage(env, photoJob());
    const small = media.objects.get("media-sync/fb/photo-100200300/w480.webp")!;
    expect(small.contentType).toBe("image/png");
    expect(new Uint8Array(small.bytes)).toEqual(new Uint8Array([1, 2, 3, 4]));
  });

  it("is idempotent: an image that is already stored is not downloaded again", async () => {
    const { env, media, db } = makeEnv();
    await upsertPhotos(env.DB, [row()]);
    media.objects.set("media-sync/fb/photo-100200300/w480.webp", { bytes: new ArrayBuffer(1) });
    const mock = mockFetch(() => imageResponse());
    restore = mock.restore;
    await mirrorImage(env, photoJob());
    expect(mock.calls).toHaveLength(0);
    expect(media.putOrder).toHaveLength(0);
    expect(stored(db)).toEqual([expect.objectContaining({ mirror_status: "done" })]);
  });

  it("drops a queued job for an item that was already removed, without downloading anything", async () => {
    const { env, media } = makeEnv();
    const mock = mockFetch(() => imageResponse());
    restore = mock.restore;
    await mirrorImage(env, photoJob()); // no such photo in D1
    expect(mock.calls).toHaveLength(0);
    expect(media.putOrder).toHaveLength(0);
  });

  it("removes the files it wrote if the photo was removed while it was downloading", async () => {
    const { env, media, db } = makeEnv();
    await upsertPhotos(env.DB, [row()]);
    const mock = mockFetch(() => {
      db.sqlite.exec("DELETE FROM photos");
      return imageResponse();
    });
    restore = mock.restore;
    await mirrorImage(env, photoJob());
    expect(media.objects.size).toBe(0);
    expect(media.deleted).toContain("media-sync/fb/photo-100200300/w480.webp");
  });

  it("treats an expired or removed source as permanent and a server error as retryable", async () => {
    const { env } = makeEnv();
    await upsertPhotos(env.DB, [row()]);
    let status = 403;
    const mock = mockFetch(() => new Response("x", { status }));
    restore = mock.restore;
    await expect(mirrorImage(env, photoJob())).rejects.toBeInstanceOf(PermanentError);
    status = 404;
    await expect(mirrorImage(env, photoJob())).rejects.toBeInstanceOf(PermanentError);
    status = 503;
    await expect(mirrorImage(env, photoJob())).rejects.not.toBeInstanceOf(PermanentError);
    status = 429;
    await expect(mirrorImage(env, photoJob())).rejects.not.toBeInstanceOf(PermanentError);
  });

  it("rejects non-images, svg and anything over 3 MB without storing anything", async () => {
    const { env, media } = makeEnv();
    await upsertPhotos(env.DB, [row()]);
    let response: Response = new Response("<svg/>", { headers: { "content-type": "image/svg+xml" } });
    const mock = mockFetch(() => response);
    restore = mock.restore;
    await expect(mirrorImage(env, photoJob())).rejects.toBeInstanceOf(PermanentError);
    response = new Response("<html>", { headers: { "content-type": "text/html" } });
    await expect(mirrorImage(env, photoJob())).rejects.toBeInstanceOf(PermanentError);
    // Declared too large: refused before reading the body.
    response = new Response(new Uint8Array([1]), { headers: { "content-type": "image/jpeg", "content-length": String(MAX_BYTES + 1) } });
    await expect(mirrorImage(env, photoJob())).rejects.toBeInstanceOf(PermanentError);
    // Not declared, but really too large.
    response = new Response(new Uint8Array(MAX_BYTES + 1), { headers: { "content-type": "image/jpeg" } });
    await expect(mirrorImage(env, photoJob())).rejects.toBeInstanceOf(PermanentError);
    expect(media.putOrder).toHaveLength(0);
  });

  it("accepts an image right at the 3 MB limit", async () => {
    const { env, media } = makeEnv();
    await upsertPhotos(env.DB, [row()]);
    const mock = mockFetch(() => new Response(new Uint8Array(MAX_BYTES), { headers: { "content-type": "image/jpeg" } }));
    restore = mock.restore;
    await mirrorImage(env, photoJob());
    expect(media.putOrder).toHaveLength(2);
  });
});

describe("validateJob", () => {
  const ok = photoJob();
  it("accepts a well formed job", () => {
    expect(validateJob(ok, "media-sync")).toEqual(ok);
  });
  it("rejects keys outside the prefix, other tables, and hosts we do not trust", () => {
    expect(() => validateJob({ ...ok, key: "supabase/storage/x" }, "media-sync")).toThrow(PermanentError);
    expect(() => validateJob({ ...ok, key: "media-sync/fb/photo-1/../../x" }, "media-sync")).toThrow(PermanentError);
    expect(() => validateJob({ ...ok, table: "profiles" }, "media-sync")).toThrow(PermanentError);
    expect(() => validateJob({ ...ok, source_url: "https://evil.example.com/a.jpg" }, "media-sync")).toThrow(PermanentError);
    expect(() => validateJob({ ...ok, source_url: "http://scontent.xx.fbcdn.net/a.jpg" }, "media-sync")).toThrow(PermanentError);
    expect(() => validateJob({ ...ok, source_url: "https://fbcdn.net.evil.com/a.jpg" }, "media-sync")).toThrow(PermanentError);
    expect(() => validateJob(null, "media-sync")).toThrow(PermanentError);
  });
});

describe("queue handler for images", () => {
  type Message = { body: MirrorJob; attempts: number; ack: () => void; retry: (options?: { delaySeconds?: number }) => void };
  const batch = (queue: string, messages: Message[]) => ({ queue, messages }) as unknown as MessageBatch<MirrorJob>;
  const message = (body: MirrorJob, attempts = 1) => {
    const calls = { acked: 0, retried: [] as (number | undefined)[] };
    const value: Message = { body, attempts, ack: () => void calls.acked++, retry: (options) => void calls.retried.push(options?.delaySeconds) };
    return { value, calls };
  };

  it("acks a mirrored image", async () => {
    const { env } = makeEnv();
    await upsertPhotos(env.DB, [row()]);
    const mock = mockFetch(() => imageResponse());
    restore = mock.restore;
    const item = message(photoJob());
    await worker.queue(batch("wpcc-media", [item.value]), env);
    expect(item.calls).toEqual({ acked: 1, retried: [] });
  });

  it("retries a transient failure with backoff", async () => {
    const { env } = makeEnv();
    vi.spyOn(console, "error").mockImplementation(() => {});
    await upsertPhotos(env.DB, [row()]);
    const mock = mockFetch(() => new Response("x", { status: 503 }));
    restore = mock.restore;
    const item = message(photoJob(), 3);
    await worker.queue(batch("wpcc-media", [item.value]), env);
    expect(item.calls).toEqual({ acked: 0, retried: [240] });
  });

  it("marks a permanent failure as failed in D1 and acks", async () => {
    const { env, db } = makeEnv();
    vi.spyOn(console, "error").mockImplementation(() => {});
    await upsertPhotos(env.DB, [row()]);
    const mock = mockFetch(() => new Response("gone", { status: 404 }));
    restore = mock.restore;
    const item = message(photoJob());
    await worker.queue(batch("wpcc-media", [item.value]), env);
    expect(item.calls).toEqual({ acked: 1, retried: [] });
    expect(stored(db)).toEqual([expect.objectContaining({ mirror_status: "failed", r2_key: null })]);
  });

  it("records messages that exhausted their retries from the dead-letter queue", async () => {
    const { env, db } = makeEnv();
    await upsertPhotos(env.DB, [row()]);
    const item = message(photoJob(), 6);
    await worker.queue(batch("wpcc-media-failed", [item.value]), env);
    expect(item.calls.acked).toBe(1);
    expect(stored(db)).toEqual([expect.objectContaining({ mirror_status: "failed" })]);
  });
});
