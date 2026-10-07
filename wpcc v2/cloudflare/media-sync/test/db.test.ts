import { describe, expect, it } from "vitest";
import { isWanted, markMirror, parseCursor, pendingJobs, pruneToWindow, queryGallery, queryVideos, recordSync, retryFailedMirrors, upsertPhotos, upsertVideos } from "../src/db";
import type { PhotoRow, VideoRow } from "../src/mappers";
import { FakeD1 } from "./helpers";

const photo = (n: number, overrides: Partial<PhotoRow> = {}): PhotoRow => ({
  id: String(1000 + n),
  caption: `Caption ${n}`,
  permalink: `https://www.facebook.com/photo/${n}`,
  published_at: new Date(Date.UTC(2026, 8, 1, 10, 0, 0) - n * 3600_000).toISOString(),
  width: 1200,
  height: 800,
  source_url: `https://scontent.xx.fbcdn.net/${n}.jpg?sig=a`,
  ...overrides,
});

const video = (n: number, overrides: Partial<VideoRow> = {}): VideoRow => ({
  id: `youtube:v${n}`,
  provider: "youtube",
  external_id: `v${n}`,
  title: `Video ${n}`,
  description: "About",
  thumbnail_url: `https://i.ytimg.com/vi/v${n}/hq.jpg`,
  permalink_url: `https://www.youtube.com/watch?v=v${n}`,
  embed_url: `https://www.youtube-nocookie.com/embed/v${n}`,
  kind: "video",
  published_at: new Date(Date.UTC(2026, 8, 20, 10, 0, 0) - n * 3600_000).toISOString(),
  duration_seconds: 600,
  mirror_status: "done",
  format: "standard",
  live_now: 0,
  ...overrides,
});

const fbVideo = (n: number, overrides: Partial<VideoRow> = {}) =>
  video(n, { id: `facebook:f${n}`, provider: "facebook", external_id: `f${n}`, thumbnail_url: `https://cdn/f${n}.jpg`, mirror_status: "pending", ...overrides });

const asDb = (fake: FakeD1) => fake as unknown as D1Database;

describe("upserts only write what changed", () => {
  it("inserts new photos as pending, then writes nothing when nothing changed", async () => {
    const d1 = new FakeD1();
    await upsertPhotos(asDb(d1), [photo(1), photo(2)]);
    expect(d1.all("SELECT id, mirror_status, is_active FROM photos ORDER BY id")).toEqual([
      { id: "1001", mirror_status: "pending", is_active: 1 },
      { id: "1002", mirror_status: "pending", is_active: 1 },
    ]);
    d1.resetChanges();
    await upsertPhotos(asDb(d1), [photo(1), photo(2)]);
    expect(d1.changes).toBe(0);
  });

  it("updates edited captions but keeps the mirrored copy and does not churn the signed url", async () => {
    const d1 = new FakeD1();
    await upsertPhotos(asDb(d1), [photo(1)]);
    await markMirror(asDb(d1), { table: "photos", id: "1001", key: "media-sync/fb/photo-1001" }, "done", { width: 1200, height: 800 });
    d1.resetChanges();
    // Facebook hands out a new signed URL on every call; that alone must not write.
    await upsertPhotos(asDb(d1), [photo(1, { source_url: "https://scontent.xx.fbcdn.net/1.jpg?sig=NEW" })]);
    expect(d1.changes).toBe(0);
    await upsertPhotos(asDb(d1), [photo(1, { caption: "Edited" })]);
    expect(d1.all("SELECT caption, mirror_status, r2_key, source_url FROM photos")).toEqual([
      { caption: "Edited", mirror_status: "done", r2_key: "media-sync/fb/photo-1001", source_url: "https://scontent.xx.fbcdn.net/1.jpg?sig=a" },
    ]);
  });

  it("refreshes the signed url while an image is still pending", async () => {
    const d1 = new FakeD1();
    await upsertPhotos(asDb(d1), [photo(1)]);
    await upsertPhotos(asDb(d1), [photo(1, { source_url: "https://scontent.xx.fbcdn.net/1.jpg?sig=NEW" })]);
    expect(d1.all<{ source_url: string }>("SELECT source_url FROM photos")[0].source_url).toContain("sig=NEW");
  });

  it("keeps youtube thumbnails fresh and facebook videos pending until mirrored", async () => {
    const d1 = new FakeD1();
    await upsertVideos(asDb(d1), [video(1), fbVideo(2)]);
    expect(d1.all("SELECT id, mirror_status FROM videos ORDER BY id")).toEqual([
      { id: "facebook:f2", mirror_status: "pending" },
      { id: "youtube:v1", mirror_status: "done" },
    ]);
    d1.resetChanges();
    await upsertVideos(asDb(d1), [video(1)]);
    expect(d1.changes).toBe(0);
  });
});

describe("mirroring state", () => {
  it("lists pending images newest first with their keys", async () => {
    const d1 = new FakeD1();
    await upsertPhotos(asDb(d1), [photo(2), photo(1), photo(3)]);
    await markMirror(asDb(d1), { table: "photos", id: "1002", key: "media-sync/fb/photo-1002" }, "done");
    const jobs = await pendingJobs(asDb(d1), "photos");
    expect(jobs.map((job) => job.id)).toEqual(["1001", "1003"]);
    expect(jobs[0]).toMatchObject({ type: "mirror", table: "photos", key: "media-sync/fb/photo-1001" });
  });

  it("only queues facebook video thumbnails", async () => {
    const d1 = new FakeD1();
    await upsertVideos(asDb(d1), [video(1), fbVideo(2)]);
    expect((await pendingJobs(asDb(d1), "videos")).map((job) => job.key)).toEqual(["media-sync/fb/video-f2"]);
  });

  it("knows whether a queued item still exists", async () => {
    const d1 = new FakeD1();
    await upsertPhotos(asDb(d1), [photo(1)]);
    await upsertVideos(asDb(d1), [fbVideo(2)]);
    expect(await isWanted(asDb(d1), { table: "photos", id: "1001" })).toBe(true);
    expect(await isWanted(asDb(d1), { table: "photos", id: "9999" })).toBe(false);
    expect(await isWanted(asDb(d1), { table: "videos", id: "facebook:f2" })).toBe(true);
    d1.sqlite.exec("DELETE FROM photos");
    expect(await isWanted(asDb(d1), { table: "photos", id: "1001" })).toBe(false);
  });

  it("reports whether the item still exists so a late copy can be cleaned up", async () => {
    const d1 = new FakeD1();
    await upsertPhotos(asDb(d1), [photo(1)]);
    d1.sqlite.exec("UPDATE photos SET is_active = 0");
    expect(await markMirror(asDb(d1), { table: "photos", id: "1001", key: "media-sync/fb/photo-1001" }, "done")).toBe(false);
    expect(d1.all("SELECT mirror_status, r2_key FROM photos")).toEqual([{ mirror_status: "pending", r2_key: null }]);
  });

  it("retries failed mirrors on request", async () => {
    const d1 = new FakeD1();
    await upsertPhotos(asDb(d1), [photo(1)]);
    await markMirror(asDb(d1), { table: "photos", id: "1001", key: "media-sync/fb/photo-1001" }, "failed");
    expect(d1.all("SELECT mirror_status FROM photos")).toEqual([{ mirror_status: "failed" }]);
    await retryFailedMirrors(asDb(d1));
    expect(d1.all("SELECT mirror_status FROM photos")).toEqual([{ mirror_status: "pending" }]);
  });
});

describe("keeping only the newest window", () => {
  const ids = (rows: { id: string }[]) => new Set(rows.map((row) => row.id));

  it("removes photos outside the window or deleted at the source, and returns their storage keys", async () => {
    const d1 = new FakeD1();
    const all = [photo(1), photo(2), photo(3), photo(4)];
    await upsertPhotos(asDb(d1), all);
    for (const row of all) await markMirror(asDb(d1), { table: "photos", id: row.id, key: `media-sync/fb/photo-${row.id}` }, "done");
    // The source now returns only 1, 2 and 3 (4 fell out of the window or was deleted).
    const result = await pruneToWindow(asDb(d1), "photos", null, ids([photo(1), photo(2), photo(3)]), 50);
    expect(result).toEqual({ outcome: "removed 1", deleted: 1, deletedKeys: ["media-sync/fb/photo-1004"] });
    expect(d1.all("SELECT id FROM photos ORDER BY id")).toEqual([{ id: "1001" }, { id: "1002" }, { id: "1003" }]);
  });

  it("refuses to empty the catalog when the source returns too little", async () => {
    const d1 = new FakeD1();
    await upsertPhotos(asDb(d1), [1, 2, 3, 4, 5, 6].map((n) => photo(n)));
    const result = await pruneToWindow(asDb(d1), "photos", null, ids([photo(1)]), 50);
    expect(result.deleted).toBe(0);
    expect(result.outcome).toContain("skipped");
    expect(d1.all("SELECT COUNT(*) AS n FROM photos")).toEqual([{ n: 6 }]);
  });

  it("refuses when the source returned nothing at all", async () => {
    const d1 = new FakeD1();
    await upsertPhotos(asDb(d1), [photo(1), photo(2)]);
    expect((await pruneToWindow(asDb(d1), "photos", null, new Set(), 50)).outcome).toContain("skipped");
    expect(d1.all("SELECT COUNT(*) AS n FROM photos")).toEqual([{ n: 2 }]);
  });

  it("shrinks a large catalog down to the window on the first run", async () => {
    const d1 = new FakeD1();
    const many = Array.from({ length: 120 }, (_, i) => photo(i + 1));
    await upsertPhotos(asDb(d1), many);
    const newest = many.slice(0, 50);
    const result = await pruneToWindow(asDb(d1), "photos", null, ids(newest), 50);
    expect(result.deleted).toBe(70);
    expect(result.deletedKeys).toHaveLength(70);
    expect(d1.all("SELECT COUNT(*) AS n FROM photos")).toEqual([{ n: 50 }]);
  });

  it("still refuses when a large catalog gets far less than the window back", async () => {
    const d1 = new FakeD1();
    await upsertPhotos(asDb(d1), Array.from({ length: 120 }, (_, i) => photo(i + 1)));
    const result = await pruneToWindow(asDb(d1), "photos", null, ids(Array.from({ length: 10 }, (_, i) => photo(i + 1))), 50);
    expect(result.outcome).toContain("skipped");
    expect(d1.all("SELECT COUNT(*) AS n FROM photos")).toEqual([{ n: 120 }]);
  });

  it("does nothing on an empty catalog", async () => {
    const d1 = new FakeD1();
    expect(await pruneToWindow(asDb(d1), "photos", null, new Set(), 50)).toEqual({ outcome: "removed 0", deleted: 0, deletedKeys: [] });
  });

  it("prunes each video source separately and only facebook has stored files", async () => {
    const d1 = new FakeD1();
    await upsertVideos(asDb(d1), [video(1), video(2), fbVideo(1), fbVideo(2), fbVideo(3)]);
    const youtube = await pruneToWindow(asDb(d1), "videos", "youtube", ids([video(1), video(2)]), 50);
    expect(youtube).toEqual({ outcome: "removed 0", deleted: 0, deletedKeys: [] });
    // Facebook returned f1 and f2 only: f3 is removed along with its thumbnail copy.
    const facebook = await pruneToWindow(asDb(d1), "videos", "facebook", ids([fbVideo(1), fbVideo(2)]), 50);
    expect(facebook).toEqual({ outcome: "removed 1", deleted: 1, deletedKeys: ["media-sync/fb/video-f3"] });
    // YouTube loses a video: nothing to delete in storage.
    const dropped = await pruneToWindow(asDb(d1), "videos", "youtube", ids([video(1)]), 50);
    expect(dropped).toEqual({ outcome: "removed 1", deleted: 1, deletedKeys: [] });
    expect(d1.all("SELECT id FROM videos ORDER BY id")).toEqual([{ id: "facebook:f1" }, { id: "facebook:f2" }, { id: "youtube:v1" }]);
  });
});

describe("reads for the API", () => {
  async function seeded() {
    const d1 = new FakeD1();
    const rows = [1, 2, 3, 4, 5].map((n) => photo(n));
    await upsertPhotos(asDb(d1), rows);
    for (const row of rows.slice(0, 4)) await markMirror(asDb(d1), { table: "photos", id: row.id, key: `media-sync/fb/photo-${row.id}` }, "done");
    return d1; // photo 5 is not mirrored yet
  }

  it("pages the gallery newest first with a keyset cursor and hides unmirrored photos", async () => {
    const d1 = await seeded();
    const first = await queryGallery(asDb(d1), null, 2);
    expect(first.items.map((item) => item.id)).toEqual(["1001", "1002"]);
    expect(first.next).toBe(`${first.items[1].published_at}|1002`);
    const cursor = parseCursor(first.next);
    const second = await queryGallery(asDb(d1), cursor === "invalid" ? null : cursor, 2);
    expect(second.items.map((item) => item.id)).toEqual(["1003", "1004"]);
    expect(second.next).toBeNull();
  });

  it("breaks ties on the same timestamp by id", async () => {
    const d1 = new FakeD1();
    const same = "2026-09-01T10:00:00.000Z";
    await upsertPhotos(asDb(d1), [photo(1, { id: "a1", published_at: same }), photo(2, { id: "a2", published_at: same }), photo(3, { id: "a3", published_at: same })]);
    for (const id of ["a1", "a2", "a3"]) await markMirror(asDb(d1), { table: "photos", id, key: `media-sync/fb/photo-${id}` }, "done");
    const first = await queryGallery(asDb(d1), null, 2);
    expect(first.items.map((item) => item.id)).toEqual(["a3", "a2"]);
    const cursor = parseCursor(first.next);
    expect((await queryGallery(asDb(d1), cursor === "invalid" ? null : cursor, 2)).items.map((item) => item.id)).toEqual(["a1"]);
  });

  it("lists published videos, exposes youtube thumbnails only, and truncates descriptions", async () => {
    const d1 = new FakeD1();
    await upsertVideos(asDb(d1), [video(1, { description: "x".repeat(900) }), fbVideo(2, { thumbnail_url: "https://scontent.fbcdn.net/expiring.jpg" })]);
    d1.sqlite.exec("INSERT INTO videos (id, provider, external_id, permalink_url, published_at, status) VALUES ('youtube:hid', 'youtube', 'hid', 'https://y', '2026-09-30T00:00:00.000Z', 'hidden')");
    const page = await queryVideos(asDb(d1), null, 10);
    const items = page.items as unknown as { id: string; thumbnail_url: string | null; description: string }[];
    expect(items.map((item) => item.id)).toEqual(["youtube:v1", "facebook:f2"]);
    expect(items[0].description).toHaveLength(600);
    expect(items[1].thumbnail_url).toBeNull();
    expect(items[0].thumbnail_url).toContain("ytimg.com");
  });

  it("returns the format and live flag, and rewrites them when a stream ends", async () => {
    const d1 = new FakeD1();
    await upsertVideos(asDb(d1), [video(1, { kind: "live", live_now: 1 }), video(2, { format: "short", duration_seconds: 40 })]);
    const first = (await queryVideos(asDb(d1), null, 10)).items as unknown as { id: string; format: string; live_now: number }[];
    expect(first.map((row) => [row.id, row.format, row.live_now])).toEqual([["youtube:v1", "standard", 1], ["youtube:v2", "short", 0]]);
    d1.resetChanges();
    await upsertVideos(asDb(d1), [video(1, { kind: "live", live_now: 1 }), video(2, { format: "short", duration_seconds: 40 })]);
    expect(d1.changes).toBe(0);
    // The stream ends: only live_now changes, and it is written.
    await upsertVideos(asDb(d1), [video(1, { kind: "live", live_now: 0 })]);
    expect(d1.all("SELECT id, live_now FROM videos WHERE id = 'youtube:v1'")).toEqual([{ id: "youtube:v1", live_now: 0 }]);
  });

  it("validates cursors", () => {
    expect(parseCursor(null)).toBeNull();
    expect(parseCursor("2026-09-01T10:00:00.000Z|1001")).toEqual({ publishedAt: "2026-09-01T10:00:00.000Z", id: "1001" });
    for (const bad of ["x", "|1001", "2026-09-01T10:00:00.000Z|", "2026-09-01|1001", "2026-09-01T10:00:00.000Z|1001; DROP TABLE photos", "nonsense|1"]) {
      expect(parseCursor(bad)).toBe("invalid");
    }
  });

  it("records sync results", async () => {
    const d1 = new FakeD1();
    await recordSync(asDb(d1), "youtube", "Upstream request failed (403)");
    expect(d1.all("SELECT source, last_success_at, last_error FROM sync_state")).toEqual([{ source: "youtube", last_success_at: null, last_error: "Upstream request failed (403)" }]);
    await recordSync(asDb(d1), "youtube");
    const row = d1.all<{ last_success_at: string | null; last_error: string | null }>("SELECT last_success_at, last_error FROM sync_state")[0];
    expect(row.last_error).toBeNull();
    expect(row.last_success_at).not.toBeNull();
    await recordSync(asDb(d1), "youtube", "later failure");
    expect(d1.all<{ last_success_at: string | null }>("SELECT last_success_at FROM sync_state")[0].last_success_at).not.toBeNull();
  });
});
