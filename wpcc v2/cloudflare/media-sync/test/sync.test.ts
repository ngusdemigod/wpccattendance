import { afterEach, describe, expect, it, vi } from "vitest";
import worker, { retryDelay } from "../src/index";
import { limitFrom } from "../src/sources";
import { deleteMirrored, runSyncTask, scheduleSync, shouldRetryFailed } from "../src/sync";
import type { SyncTask } from "../src/types";
import { fbPhoto, json, makeEnv, mockFetch } from "./helpers";

let restore: (() => void) | undefined;
afterEach(() => {
  restore?.();
  restore = undefined;
  vi.restoreAllMocks();
});

const task = (source: SyncTask["source"], extra: Partial<SyncTask> = {}): SyncTask => ({ type: "sync", source, run_id: "run-1", ...extra });

describe("schedule", () => {
  it("retries failed images only at the 02:00 UTC run", () => {
    expect(shouldRetryFailed(Date.UTC(2026, 9, 6, 2, 0))).toBe(true);
    expect(shouldRetryFailed(Date.UTC(2026, 9, 6, 2, 30))).toBe(false);
    expect(shouldRetryFailed(Date.UTC(2026, 9, 6, 14, 0))).toBe(false);
  });

  it("queues one task per source with the same run id", async () => {
    const { env, queue } = makeEnv();
    const time = Date.UTC(2026, 9, 6, 10, 30);
    await scheduleSync(env, time);
    expect(queue.sent).toEqual([
      { type: "sync", source: "facebook_photos", run_id: String(time) },
      { type: "sync", source: "facebook_videos", run_id: String(time) },
      { type: "sync", source: "youtube", run_id: String(time) },
    ]);
  });

  it("the daily run also retries failed images and queues the sweep", async () => {
    const { env, queue } = makeEnv();
    const time = Date.UTC(2026, 9, 6, 2, 0);
    await scheduleSync(env, time);
    expect(queue.sent).toHaveLength(4);
    expect(queue.sent.filter((message) => message.type === "sync").every((message) => message.type === "sync" && message.retry_failed === true)).toBe(true);
    expect(queue.sent.at(-1)).toEqual({ type: "sweep", run_id: String(time) });
  });

  it("the cron handler only enqueues work (no network)", async () => {
    const { env, queue } = makeEnv();
    const mock = mockFetch(() => json({}));
    restore = mock.restore;
    const pending: Promise<unknown>[] = [];
    await worker.scheduled({ cron: "*/30 * * * *", scheduledTime: Date.UTC(2026, 9, 6, 10, 30) } as ScheduledController, env, { waitUntil: (p: Promise<unknown>) => void pending.push(p) } as ExecutionContext);
    await Promise.all(pending);
    expect(queue.sent).toHaveLength(3);
    expect(mock.calls).toHaveLength(0);
  });

  it("backs off retries up to 15 minutes", () => {
    expect([1, 2, 3, 4, 5, 6].map(retryDelay)).toEqual([60, 120, 240, 480, 900, 900]);
  });

  it("clamps the window size settings", () => {
    expect(limitFrom("50", 50, 100)).toBe(50);
    expect(limitFrom("500", 50, 100)).toBe(100);
    expect(limitFrom("0", 50, 100)).toBe(1);
    expect(limitFrom("-5", 50, 100)).toBe(1);
    expect(limitFrom("abc", 50, 100)).toBe(50);
    expect(limitFrom(undefined, 50, 100)).toBe(50);
  });
});

describe("facebook photos", () => {
  it("pulls only the newest window, stores it, queues the images, and sends the token as a bearer header", async () => {
    const { env, db, queue } = makeEnv({ MAX_PHOTOS: "25" });
    const mock = mockFetch(() => json({ data: [fbPhoto("11"), fbPhoto("12", "2026-09-02T10:00:00+0000"), { id: "13", link: "https://x" }] }));
    restore = mock.restore;

    expect(await runSyncTask(env, task("facebook_photos"))).toBe("done");
    expect(mock.calls).toHaveLength(1);
    expect(mock.calls[0].url).toContain("graph.facebook.com/v24.0/555000111/photos");
    expect(mock.calls[0].url).toContain("limit=25");
    expect(mock.calls[0].url).not.toContain("fb-token-secret");
    expect(mock.calls[0].headers.Authorization).toBe("Bearer fb-token-secret");
    expect(db.all("SELECT id FROM photos ORDER BY id")).toEqual([{ id: "11" }, { id: "12" }]);
    expect(queue.mirrorJobs.map((job) => job.key)).toEqual(["media-sync/fb/photo-12", "media-sync/fb/photo-11"]);
    expect(db.all("SELECT source, last_error FROM sync_state")).toEqual([{ source: "facebook_photos", last_error: null }]);
  });

  it("removes photos outside the window or deleted at the source, and deletes their stored files", async () => {
    const { env, db, media } = makeEnv();
    // Three photos are already stored; the window now holds only the two newest.
    db.sqlite.exec(`INSERT INTO photos (id, permalink, published_at, source_url, is_active, mirror_status, r2_key) VALUES
      ('11', 'https://x', '2026-09-01T10:00:00.000Z', 'https://s', 1, 'done', 'media-sync/fb/photo-11'),
      ('12', 'https://x', '2026-09-02T10:00:00.000Z', 'https://s', 1, 'done', 'media-sync/fb/photo-12'),
      ('999', 'https://x', '2026-08-01T00:00:00.000Z', 'https://s', 1, 'done', 'media-sync/fb/photo-999')`);
    media.objects.set("media-sync/fb/photo-999/w480.webp", { bytes: new ArrayBuffer(1) });
    const mock = mockFetch(() => json({ data: [fbPhoto("11"), fbPhoto("12", "2026-09-02T10:00:00+0000")] }));
    restore = mock.restore;

    expect(await runSyncTask(env, task("facebook_photos"))).toBe("done");
    expect(db.all("SELECT id FROM photos ORDER BY id")).toEqual([{ id: "11" }, { id: "12" }]);
    expect(media.deleted).toEqual(["media-sync/fb/photo-999/original", "media-sync/fb/photo-999/w1600.webp", "media-sync/fb/photo-999/w480.webp"]);
  });

  it("does not delete anything when facebook returns far fewer photos than we hold", async () => {
    const { env, db, media } = makeEnv();
    for (let i = 1; i <= 10; i++) db.sqlite.exec(`INSERT INTO photos (id, permalink, published_at, source_url, mirror_status) VALUES ('${i}', 'https://x', '2026-09-0${(i % 9) + 1}T00:00:00.000Z', 'https://s', 'done')`);
    const mock = mockFetch(() => json({ data: [fbPhoto("1")] }));
    restore = mock.restore;
    await runSyncTask(env, task("facebook_photos"));
    expect(db.all("SELECT COUNT(*) AS n FROM photos")).toEqual([{ n: 10 }]);
    expect(media.deleted).toHaveLength(0);
  });

  it("retries failed images only when asked", async () => {
    const { env, db } = makeEnv();
    db.sqlite.exec("INSERT INTO photos (id, permalink, published_at, source_url, mirror_status) VALUES ('11', 'https://x', '2026-09-01T10:00:00.000Z', 'https://s', 'failed')");
    const mock = mockFetch(() => json({ data: [fbPhoto("11")] }));
    restore = mock.restore;
    await runSyncTask(env, task("facebook_photos"));
    expect(db.all("SELECT mirror_status FROM photos")).toEqual([{ mirror_status: "failed" }]);
    await runSyncTask(env, task("facebook_photos", { retry_failed: true }));
    expect(db.all("SELECT mirror_status FROM photos")).toEqual([{ mirror_status: "pending" }]);
  });
});

describe("facebook videos and youtube", () => {
  it("syncs facebook videos and queues their thumbnails", async () => {
    const { env, db, queue } = makeEnv();
    const mock = mockFetch(() =>
      json({ data: [{ id: "77", title: "Live service", created_time: "2026-09-20T10:00:00+0000", permalink_url: "/wpcc/videos/77/", picture: "https://scontent.xx.fbcdn.net/t.jpg", live_status: "VOD", length: 3600 }] }),
    );
    restore = mock.restore;
    await runSyncTask(env, task("facebook_videos"));
    expect(mock.calls[0].url).toContain("limit=50");
    expect(db.all("SELECT id, kind, mirror_status, duration_seconds FROM videos")).toEqual([{ id: "facebook:77", kind: "live", mirror_status: "pending", duration_seconds: 3600 }]);
    expect(queue.mirrorJobs).toEqual([expect.objectContaining({ table: "videos", id: "facebook:77", key: "media-sync/fb/video-77" })]);
  });

  it("syncs youtube through the uploads playlist, sending the key in a header", async () => {
    const { env, db, queue } = makeEnv({ MAX_VIDEOS: "30" });
    const mock = mockFetch((call) =>
      call.url.includes("/playlistItems")
        ? json({ items: [{ contentDetails: { videoId: "vid00000001" } }, { contentDetails: { videoId: "vid00000002" } }] })
        : json({
            items: [
              { id: "vid00000001", snippet: { title: "Sunday", publishedAt: "2026-09-20T10:00:00Z", thumbnails: { high: { url: "https://i.ytimg.com/a.jpg" } } }, contentDetails: { duration: "PT10M" }, status: { privacyStatus: "public", embeddable: true } },
              { id: "vid00000002", snippet: { title: "Private", publishedAt: "2026-09-19T10:00:00Z" }, status: { privacyStatus: "private" } },
            ],
          }),
    );
    restore = mock.restore;
    await runSyncTask(env, task("youtube"));
    expect(mock.calls).toHaveLength(2);
    expect(mock.calls[0].url).toContain("playlistId=UUabcdefghijklmnopqrstuv");
    expect(mock.calls[0].url).toContain("maxResults=30");
    expect(mock.calls.every((call) => call.headers["X-Goog-Api-Key"] === "yt-key-secret" && !call.url.includes("yt-key-secret"))).toBe(true);
    expect(db.all("SELECT id, kind, mirror_status FROM videos")).toEqual([{ id: "youtube:vid00000001", kind: "video", mirror_status: "done" }]);
    expect(queue.mirrorJobs).toHaveLength(0);
  });

  it("confirms youtube shorts with the /shorts/ link and stores the format", async () => {
    const { env, db } = makeEnv();
    const entry = (id: string, duration: string, extra = {}) => ({ id, snippet: { title: id, publishedAt: "2026-09-20T10:00:00Z" }, contentDetails: { duration }, status: { privacyStatus: "public" }, ...extra });
    const mock = mockFetch((call) => {
      if (call.url.includes("/playlistItems")) return json({ items: ["short000001", "clip0000002", "long0000003", "live0000004"].map((videoId) => ({ contentDetails: { videoId } })) });
      if (call.url.includes("/videos?")) {
        return json({
          items: [
            entry("short000001", "PT40S"),
            entry("clip0000002", "PT2M", {}),
            entry("long0000003", "PT45M"),
            entry("live0000004", "PT30S", { liveStreamingDetails: { actualStartTime: "2026-09-20T09:00:00Z" } }),
          ],
        });
      }
      // /shorts/<id>: a Short answers 200, any other video redirects to /watch.
      return call.url.endsWith("/short000001") ? new Response("", { status: 200 }) : new Response("", { status: 303, headers: { location: "/watch" } });
    });
    restore = mock.restore;
    await runSyncTask(env, task("youtube"));
    const checked = mock.calls.filter((call) => call.url.includes("/shorts/")).map((call) => call.url.split("/").pop());
    expect(checked.sort()).toEqual(["clip0000002", "short000001"]);
    expect(db.all("SELECT external_id, format FROM videos ORDER BY external_id")).toEqual([
      { external_id: "clip0000002", format: "standard" },
      { external_id: "live0000004", format: "standard" },
      { external_id: "long0000003", format: "standard" },
      { external_id: "short000001", format: "short" },
    ]);
  });

  it("falls back to the duration when the shorts link cannot be checked", async () => {
    const { env, db } = makeEnv();
    const mock = mockFetch((call) => {
      if (call.url.includes("/playlistItems")) return json({ items: [{ contentDetails: { videoId: "tiny0000001" } }, { contentDetails: { videoId: "mid00000002" } }] });
      if (call.url.includes("/videos?")) {
        return json({
          items: [
            { id: "tiny0000001", snippet: { title: "t", publishedAt: "2026-09-20T10:00:00Z" }, contentDetails: { duration: "PT30S" }, status: { privacyStatus: "public" } },
            { id: "mid00000002", snippet: { title: "m", publishedAt: "2026-09-20T09:00:00Z" }, contentDetails: { duration: "PT2M30S" }, status: { privacyStatus: "public" } },
          ],
        });
      }
      throw new Error("network down");
    });
    restore = mock.restore;
    await runSyncTask(env, task("youtube"));
    expect(db.all("SELECT external_id, format FROM videos ORDER BY external_id")).toEqual([
      { external_id: "mid00000002", format: "standard" },
      { external_id: "tiny0000001", format: "short" },
    ]);
  });

  it("asks facebook for the frame size, and still syncs if the field is refused", async () => {
    const { env, db } = makeEnv();
    vi.spyOn(console, "error").mockImplementation(() => {});
    const video = { id: "88", title: "Clip", created_time: "2026-09-20T10:00:00+0000", permalink_url: "/wpcc/videos/88/", length: 20 };
    const mock = mockFetch((call) => (call.url.includes("format") ? json({ error: { code: 100, message: "bad field" } }, 400) : json({ data: [video] })));
    restore = mock.restore;
    await runSyncTask(env, task("facebook_videos"));
    expect(mock.calls).toHaveLength(2);
    expect(mock.calls[0].url).toContain("format");
    expect(mock.calls[1].url).not.toContain("format");
    expect(db.all("SELECT id, format FROM videos")).toEqual([{ id: "facebook:88", format: "standard" }]);
  });

  it("keeps the two video sources independent when pruning", async () => {
    const { env, db } = makeEnv();
    db.sqlite.exec(`INSERT INTO videos (id, provider, external_id, permalink_url, published_at, mirror_status) VALUES
      ('facebook:1', 'facebook', '1', 'https://f', '2026-09-01T00:00:00.000Z', 'done'),
      ('youtube:old', 'youtube', 'old', 'https://y', '2026-08-01T00:00:00.000Z', 'done'),
      ('youtube:keep', 'youtube', 'keep', 'https://y', '2026-09-02T00:00:00.000Z', 'done')`);
    const mock = mockFetch((call) =>
      call.url.includes("/playlistItems")
        ? json({ items: [{ contentDetails: { videoId: "keep" } }] })
        : json({ items: [{ id: "keep", snippet: { title: "Kept", publishedAt: "2026-09-02T00:00:00Z" }, status: { privacyStatus: "public" } }] }),
    );
    restore = mock.restore;
    await runSyncTask(env, task("youtube"));
    expect(db.all("SELECT id FROM videos ORDER BY id")).toEqual([{ id: "facebook:1" }, { id: "youtube:keep" }]);
  });
});

describe("failures", () => {
  it("missing credentials are a permanent configuration error, recorded without secrets", async () => {
    const { env, db } = makeEnv({ FACEBOOK_PAGE_ID: "" });
    vi.spyOn(console, "error").mockImplementation(() => {});
    expect(await runSyncTask(env, task("facebook_photos"))).toBe("failed");
    expect(db.all<{ last_error: string }>("SELECT last_error FROM sync_state")[0].last_error).toContain("not configured");
  });

  it("an upstream outage is retried and the error is recorded (status only)", async () => {
    const { env, db } = makeEnv();
    const errors: string[] = [];
    vi.spyOn(console, "error").mockImplementation((message) => void errors.push(String(message)));
    const mock = mockFetch(() => new Response("token expired", { status: 400 }));
    restore = mock.restore;
    expect(await runSyncTask(env, task("facebook_photos"))).toBe("retry");
    expect(db.all("SELECT last_error FROM sync_state")).toEqual([{ last_error: "Upstream request failed (400)" }]);
    expect(errors.join("\n")).not.toContain("fb-token-secret");
    expect(errors.join("\n")).not.toContain("token expired");
  });

  it("records a safe reason from Facebook and YouTube errors, logging the message only", async () => {
    const { env, db } = makeEnv();
    const errors: string[] = [];
    vi.spyOn(console, "error").mockImplementation((message) => void errors.push(String(message)));
    const graph = mockFetch(() => json({ error: { message: "(#200) Requires pages_read_engagement permission", type: "OAuthException", code: 200, fbtrace_id: "XYZ" } }, 403));
    restore = graph.restore;
    await runSyncTask(env, task("facebook_photos"));
    expect(db.all("SELECT last_error FROM sync_state WHERE source = 'facebook_photos'")).toEqual([{ last_error: "Upstream request failed (403, code 200)" }]);
    graph.restore();

    const youtube = mockFetch(() => json({ error: { code: 403, message: "quota", errors: [{ reason: "quotaExceeded" }] } }, 403));
    restore = youtube.restore;
    await runSyncTask(env, task("youtube"));
    expect(db.all("SELECT last_error FROM sync_state WHERE source = 'youtube'")).toEqual([{ last_error: "Upstream request failed (403, quotaExceeded)" }]);
    expect(errors.join("\n")).toContain("pages_read_engagement");
    expect(errors.join("\n")).not.toContain("fb-token-secret");
    expect(errors.join("\n")).not.toContain("yt-key-secret");
  });

  it("queue handler acks configuration errors and retries outages with backoff", async () => {
    const calls = { ack: 0, retry: [] as (number | undefined)[] };
    const message = (body: SyncTask, attempts = 2) => ({ body, attempts, ack: () => void calls.ack++, retry: (o?: { delaySeconds?: number }) => void calls.retry.push(o?.delaySeconds) });
    vi.spyOn(console, "error").mockImplementation(() => {});

    const bad = makeEnv({ YOUTUBE_API_KEY: "" });
    await worker.queue({ queue: "wpcc-media", messages: [message(task("youtube"))] } as unknown as MessageBatch<SyncTask>, bad.env);
    expect(calls).toEqual({ ack: 1, retry: [] });

    const down = makeEnv();
    const mock = mockFetch(() => new Response("x", { status: 503 }));
    restore = mock.restore;
    await worker.queue({ queue: "wpcc-media", messages: [message(task("facebook_videos"), 3)] } as unknown as MessageBatch<SyncTask>, down.env);
    expect(calls.retry).toEqual([240]);
  });

  it("still accepts sync tasks queued by the previous version (extra fields are ignored)", async () => {
    const { env, db } = makeEnv();
    const mock = mockFetch(() => json({ data: [fbPhoto("11")] }));
    restore = mock.restore;
    const old = { type: "sync", source: "facebook_photos", mode: "full", run_id: "manual-1" } as unknown as SyncTask;
    expect(await runSyncTask(env, old)).toBe("done");
    expect(db.all("SELECT id FROM photos")).toEqual([{ id: "11" }]);
  });
});

describe("deleting mirrored files", () => {
  it("only touches keys under the media prefix", async () => {
    const { env, media } = makeEnv();
    vi.spyOn(console, "error").mockImplementation(() => {});
    const deleted = await deleteMirrored(env, ["media-sync/fb/photo-1", "supabase/storage/avatars/me.png", "media-sync/fb/photo-../x", "media-sync/fb/photo-2/original"]);
    expect(deleted).toBe(1);
    expect(media.deleted).toEqual(["media-sync/fb/photo-1/original", "media-sync/fb/photo-1/w1600.webp", "media-sync/fb/photo-1/w480.webp"]);
  });

  it("deletes in large batches so thousands of items stay within the request limit", async () => {
    const { env, media } = makeEnv();
    const keys = Array.from({ length: 2500 }, (_, i) => `media-sync/fb/photo-${i + 1}`);
    expect(await deleteMirrored(env, keys)).toBe(2500);
    // 2500 items x 3 files = 7500 objects: eight calls of at most 1000, not 2500 calls.
    expect(media.deleteCalls.length).toBe(8);
    expect(media.deleteCalls.every((call) => call.length <= 1000)).toBe(true);
    expect(media.deleted).toHaveLength(7500);
  });
});
