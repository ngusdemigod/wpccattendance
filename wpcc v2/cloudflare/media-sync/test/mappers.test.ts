import { describe, expect, it } from "vitest";
import {
  chunk,
  facebookPermalink,
  isMirrorKey,
  isShortCandidate,
  largestImage,
  mirrorKey,
  parseIsoDuration,
  photoRow,
  toIso,
  uploadsPlaylistId,
  videoRowFromFacebook,
  videoRowFromYouTube,
} from "../src/mappers";

describe("keys", () => {
  it("namespaces and validates mirror keys", () => {
    expect(mirrorKey("photo", "123_456")).toBe("media-sync/fb/photo-123_456");
    expect(mirrorKey("video", "99")).toBe("media-sync/fb/video-99");
    expect(() => mirrorKey("photo", "../etc/passwd")).toThrow();
    expect(() => mirrorKey("photo", "a/b")).toThrow();
    expect(isMirrorKey("media-sync/fb/photo-1", "media-sync")).toBe(true);
    expect(isMirrorKey("media-sync/fb/video-abc_1", "media-sync")).toBe(true);
    expect(isMirrorKey("supabase/storage/avatar.png", "media-sync")).toBe(false);
    expect(isMirrorKey("media-sync/fb/photo-../x", "media-sync")).toBe(false);
    expect(isMirrorKey("media-sync/fb/photo-1/original", "media-sync")).toBe(false);
  });
});

describe("photos", () => {
  it("picks the biggest https image", () => {
    expect(
      largestImage([
        { source: "https://cdn/small.jpg", width: 200, height: 100 },
        { source: "https://cdn/large.jpg", width: 2000, height: 1500 },
        { source: "http://cdn/insecure.jpg", width: 9000, height: 9000 },
      ]),
    ).toEqual({ url: "https://cdn/large.jpg", width: 2000, height: 1500 });
    expect(largestImage([])).toBeNull();
    expect(largestImage(undefined)).toBeNull();
    expect(largestImage([{ source: "http://x/a.jpg" }])).toBeNull();
  });

  it("normalises Facebook timestamps to UTC ISO", () => {
    expect(toIso("2026-09-01T10:00:00+0000")).toBe("2026-09-01T10:00:00.000Z");
    expect(toIso("2026-09-01T11:00:00+0100")).toBe("2026-09-01T10:00:00.000Z");
    expect(toIso("garbage")).toBeNull();
    expect(toIso(undefined)).toBeNull();
  });

  it("builds a row and drops unusable photos", () => {
    const row = photoRow({ id: "1", name: "Sunday", created_time: "2026-09-01T10:00:00+0000", link: "https://www.facebook.com/photo/1", images: [{ source: "https://cdn/a.jpg", width: 1200, height: 800 }] });
    expect(row).toEqual({ id: "1", caption: "Sunday", permalink: "https://www.facebook.com/photo/1", published_at: "2026-09-01T10:00:00.000Z", width: 1200, height: 800, source_url: "https://cdn/a.jpg" });
    expect(photoRow({ id: "2", created_time: "2026-09-01T10:00:00+0000", link: "https://x", images: [] })).toBeNull();
    expect(photoRow({ id: "3", created_time: "2026-09-01T10:00:00+0000", link: "http://x", images: [{ source: "https://cdn/a.jpg" }] })).toBeNull();
    expect(photoRow({ id: "../4", created_time: "2026-09-01T10:00:00+0000", link: "https://x", images: [{ source: "https://cdn/a.jpg" }] })).toBeNull();
    expect(photoRow({ id: "5", link: "https://x", images: [{ source: "https://cdn/a.jpg" }] })).toBeNull();
  });
});

describe("facebook videos", () => {
  const base = { id: "9", title: "Service", created_time: "2026-09-20T10:00:00+0000", permalink_url: "/wpcc/videos/9/", picture: "https://cdn/p.jpg", length: 754.4 };

  it("maps a video and makes the link absolute", () => {
    const row = videoRowFromFacebook(base)!;
    expect(row.id).toBe("facebook:9");
    expect(row.kind).toBe("video");
    expect(row.duration_seconds).toBe(754);
    expect(row.permalink_url).toBe("https://www.facebook.com/wpcc/videos/9/");
    expect(row.mirror_status).toBe("pending");
    expect(videoRowFromFacebook({ ...base, picture: undefined })!.mirror_status).toBe("done");
  });

  it("detects livestreams and skips unpublished ones", () => {
    expect(videoRowFromFacebook({ ...base, live_status: "VOD" })!.kind).toBe("live");
    expect(videoRowFromFacebook({ ...base, live_status: "LIVE_NOW" })!.kind).toBe("live");
    expect(videoRowFromFacebook({ ...base, live_status: "SCHEDULED_UPCOMING" })).toBeNull();
    expect(videoRowFromFacebook({ ...base, permalink_url: undefined })).toBeNull();
    expect(videoRowFromFacebook({ ...base, created_time: undefined })).toBeNull();
    expect(videoRowFromFacebook({ ...base, title: "", description: "First line\nSecond" })!.title).toBe("First line");
  });

  it("tells portrait clips and reels from landscape videos", () => {
    const portrait = [{ width: 1080, height: 1920 }];
    expect(videoRowFromFacebook(base)!.format).toBe("standard");
    expect(videoRowFromFacebook({ ...base, format: [{ width: 1920, height: 1080 }] })!.format).toBe("standard");
    expect(videoRowFromFacebook({ ...base, length: 45, format: portrait })!.format).toBe("short");
    expect(videoRowFromFacebook({ ...base, length: 600, format: portrait })!.format).toBe("portrait");
    expect(videoRowFromFacebook({ ...base, permalink_url: "/reel/123/" })!.format).toBe("short");
    expect(videoRowFromFacebook({ ...base, permalink_url: "https://www.facebook.com/reel/123" })!.format).toBe("short");
    // The tallest-by-area encoding decides, not the first one listed.
    expect(videoRowFromFacebook({ ...base, length: 45, format: [{ width: 100, height: 56 }, ...portrait] })!.format).toBe("short");
  });

  it("never files a livestream under shorts, and knows when one is on air", () => {
    const portrait = [{ width: 1080, height: 1920 }];
    const live = videoRowFromFacebook({ ...base, live_status: "LIVE", length: 30, format: portrait })!;
    expect(live).toMatchObject({ kind: "live", format: "standard", live_now: 1 });
    expect(videoRowFromFacebook({ ...base, live_status: "LIVE_NOW" })!.live_now).toBe(1);
    expect(videoRowFromFacebook({ ...base, live_status: "VOD", length: 30, format: portrait })).toMatchObject({ kind: "live", format: "standard", live_now: 0 });
    expect(videoRowFromFacebook({ ...base, live_status: "LIVE_STOPPED" })!.live_now).toBe(0);
    expect(videoRowFromFacebook(base)!.live_now).toBe(0);
  });

  it("only accepts https permalinks", () => {
    expect(facebookPermalink("/wpcc/videos/1/")).toBe("https://www.facebook.com/wpcc/videos/1/");
    expect(facebookPermalink("https://fb.watch/abc")).toBe("https://fb.watch/abc");
    expect(facebookPermalink("http://fb.watch/abc")).toBeNull();
    expect(facebookPermalink(undefined)).toBeNull();
  });
});

describe("youtube", () => {
  const item = {
    id: "abcDEF12345",
    snippet: { title: "Sunday", publishedAt: "2026-09-20T10:00:00Z", thumbnails: { high: { url: "https://i.ytimg.com/vi/x/hq.jpg" } } },
    contentDetails: { duration: "PT12M34S" },
    status: { privacyStatus: "public", embeddable: true },
  };

  it("reads ISO durations", () => {
    expect(parseIsoDuration("PT1H5M9S")).toBe(3909);
    expect(parseIsoDuration("PT12M34S")).toBe(754);
    expect(parseIsoDuration("PT45S")).toBe(45);
    expect(parseIsoDuration("P0D")).toBe(0);
    expect(parseIsoDuration("P1DT1H")).toBe(90000);
    expect(parseIsoDuration("nonsense")).toBeNull();
    expect(parseIsoDuration(undefined)).toBeNull();
  });

  it("keeps public videos only, detects live, skips upcoming", () => {
    const row = videoRowFromYouTube(item)!;
    expect(row.id).toBe("youtube:abcDEF12345");
    expect(row.kind).toBe("video");
    expect(row.duration_seconds).toBe(754);
    expect(row.embed_url).toBe("https://www.youtube-nocookie.com/embed/abcDEF12345");
    expect(row.permalink_url).toBe("https://www.youtube.com/watch?v=abcDEF12345");
    expect(row.mirror_status).toBe("done");
    const live = videoRowFromYouTube({ ...item, liveStreamingDetails: { actualStartTime: "2026-09-21T09:00:00Z" } })!;
    expect(live.kind).toBe("live");
    expect(live.published_at).toBe("2026-09-21T09:00:00.000Z");
    expect(videoRowFromYouTube({ ...item, status: { privacyStatus: "private" } })).toBeNull();
    expect(videoRowFromYouTube({ ...item, snippet: { ...item.snippet, liveBroadcastContent: "upcoming" } })).toBeNull();
    expect(videoRowFromYouTube({ ...item, status: { privacyStatus: "public", embeddable: false } })!.embed_url).toBeNull();
  });

  it("marks confirmed shorts, and an on-air stream as live now", () => {
    expect(videoRowFromYouTube(item)!).toMatchObject({ format: "standard", live_now: 0 });
    expect(videoRowFromYouTube(item, true)!.format).toBe("short");
    const onAir = { ...item, snippet: { ...item.snippet, liveBroadcastContent: "live" }, liveStreamingDetails: { actualStartTime: "2026-09-21T09:00:00Z" } };
    expect(videoRowFromYouTube(onAir, true)!).toMatchObject({ kind: "live", format: "standard", live_now: 1 });
    // A finished stream is still a livestream, but no longer live now.
    const ended = { ...item, liveStreamingDetails: { actualStartTime: "2026-09-21T09:00:00Z", actualEndTime: "2026-09-21T11:00:00Z" } };
    expect(videoRowFromYouTube(ended)!).toMatchObject({ kind: "live", live_now: 0 });
  });

  it("only treats short, non-live videos as short candidates", () => {
    const withDuration = (duration: string, extra = {}) => ({ ...item, contentDetails: { duration }, ...extra });
    expect(isShortCandidate(withDuration("PT45S"))).toBe(true);
    expect(isShortCandidate(withDuration("PT3M"))).toBe(true);
    expect(isShortCandidate(withDuration("PT3M1S"))).toBe(false);
    expect(isShortCandidate(withDuration("PT0S"))).toBe(false);
    expect(isShortCandidate(withDuration("PT45S", { liveStreamingDetails: { actualStartTime: "2026-09-21T09:00:00Z" } }))).toBe(false);
    expect(isShortCandidate({ ...item, contentDetails: undefined })).toBe(false);
  });

  it("converts channel ids to uploads playlists and rejects junk", () => {
    expect(uploadsPlaylistId("UCabcdefghijklmnopqrstuv")).toBe("UUabcdefghijklmnopqrstuv");
    expect(() => uploadsPlaylistId("not-a-channel")).toThrow();
    expect(() => uploadsPlaylistId("UC short")).toThrow();
  });
});

it("chunks lists", () => {
  expect(chunk([1, 2, 3, 4, 5], 2)).toEqual([[1, 2], [3, 4], [5]]);
  expect(chunk([], 3)).toEqual([]);
});
