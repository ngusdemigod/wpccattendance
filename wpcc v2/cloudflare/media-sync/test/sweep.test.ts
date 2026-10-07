import { describe, expect, it } from "vitest";
import worker from "../src/index";
import { upsertPhotos, upsertVideos } from "../src/db";
import { sweepOrphans } from "../src/sweep";
import { FakeR2, makeEnv } from "./helpers";

const photo = (id: string) => ({ id, caption: "", permalink: "https://www.facebook.com/photo/1", published_at: "2026-09-01T10:00:00.000Z", width: 100, height: 100, source_url: "https://scontent.xx.fbcdn.net/a.jpg" });
const put = (media: FakeR2, ...keys: string[]) => keys.forEach((key) => media.objects.set(key, { bytes: new ArrayBuffer(1) }));

describe("sweepOrphans", () => {
  it("deletes files of items that are no longer in the catalog and keeps everything else", async () => {
    const { env, media } = makeEnv();
    await upsertPhotos(env.DB, [photo("11")]);
    await upsertVideos(env.DB, [
      { id: "facebook:77", provider: "facebook", external_id: "77", title: "t", description: null, thumbnail_url: "https://cdn/t.jpg", permalink_url: "https://f", embed_url: null, kind: "video", published_at: "2026-09-02T00:00:00.000Z", duration_seconds: null, mirror_status: "pending", format: "standard", live_now: 0 },
    ]);
    put(
      media,
      "media-sync/fb/photo-11/w480.webp",
      "media-sync/fb/photo-11/w1600.webp", // kept
      "media-sync/fb/video-77/w480.webp", // kept (facebook video thumbnail)
      "media-sync/fb/photo-999/w480.webp",
      "media-sync/fb/photo-999/w1600.webp",
      "media-sync/fb/photo-999/original", // orphan
      "media-sync/fb/video-888/w480.webp", // orphan
    );
    const result = await sweepOrphans(env);
    expect(result).toMatchObject({ scanned: 7, orphans: 4, legacyOriginals: 0, deleted: 4, truncated: false });
    expect([...media.objects.keys()].sort()).toEqual(["media-sync/fb/photo-11/w1600.webp", "media-sync/fb/photo-11/w480.webp", "media-sync/fb/video-77/w480.webp"]);
  });

  it("removes the old full-size originals even for items that are kept", async () => {
    const { env, media } = makeEnv();
    await upsertPhotos(env.DB, [photo("11")]);
    put(media, "media-sync/fb/photo-11/original", "media-sync/fb/photo-11/w480.webp", "media-sync/fb/photo-11/w1600.webp");
    const result = await sweepOrphans(env);
    expect(result).toMatchObject({ orphans: 0, legacyOriginals: 1, deleted: 1 });
    expect(media.objects.has("media-sync/fb/photo-11/original")).toBe(false);
    expect(media.objects.has("media-sync/fb/photo-11/w480.webp")).toBe(true);
  });

  it("never touches keys that are not exactly the shape this worker writes", async () => {
    const { env, media } = makeEnv();
    put(
      media,
      "media-sync/fb/notes.txt",
      "media-sync/fb/photo-1/extra/w480.webp",
      "media-sync/fb/photo-1/thumb.png",
      "media-sync/fb/other-5/w480.webp",
      "media-sync/fb/photo-../w480.webp",
    );
    const result = await sweepOrphans(env);
    expect(result.deleted).toBe(0);
    expect(media.objects.size).toBe(5);
  });

  it("only looks under its own prefix", async () => {
    const { env, media } = makeEnv();
    put(media, "supabase/storage/avatar.png", "other-prefix/fb/photo-1/w480.webp", "media-sync/fb/photo-5/w480.webp");
    await sweepOrphans(env);
    expect(media.objects.has("supabase/storage/avatar.png")).toBe(true);
    expect(media.objects.has("other-prefix/fb/photo-1/w480.webp")).toBe(true);
    expect(media.objects.has("media-sync/fb/photo-5/w480.webp")).toBe(false);
  });

  it("pages through large listings and deletes in batches of at most 1000", async () => {
    const { env, media } = makeEnv();
    for (let i = 0; i < 2500; i++) put(media, `media-sync/fb/photo-${i}/w480.webp`);
    const result = await sweepOrphans(env);
    expect(result).toMatchObject({ scanned: 2500, orphans: 2500, deleted: 2500, truncated: false });
    expect(media.deleteCalls.map((call) => call.length)).toEqual([1000, 1000, 500]);
    expect(media.objects.size).toBe(0);
  });

  it("is a no-op on a clean bucket", async () => {
    const { env, media } = makeEnv();
    await upsertPhotos(env.DB, [photo("11")]);
    put(media, "media-sync/fb/photo-11/w480.webp", "media-sync/fb/photo-11/w1600.webp");
    expect(await sweepOrphans(env)).toMatchObject({ deleted: 0 });
    expect(media.deleteCalls).toHaveLength(0);
  });

  it("runs from the queue and acks", async () => {
    const { env, media } = makeEnv();
    put(media, "media-sync/fb/photo-5/w480.webp");
    const calls = { ack: 0, retry: 0 };
    const message = { body: { type: "sweep", run_id: "x" }, attempts: 1, ack: () => void calls.ack++, retry: () => void calls.retry++ };
    await worker.queue({ queue: "wpcc-media", messages: [message] } as unknown as MessageBatch<never>, env);
    expect(calls).toEqual({ ack: 1, retry: 0 });
    expect(media.objects.size).toBe(0);
  });
});
