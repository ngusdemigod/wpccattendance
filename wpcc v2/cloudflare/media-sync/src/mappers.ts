// Pure helpers: map Facebook and YouTube API responses to catalog rows. Nothing
// here touches the network or the database, so everything is unit tested.

export const MIRROR_PREFIX = "media-sync";

/** Immutable storage key prefix for one mirrored image. */
export function mirrorKey(kind: "photo" | "video", sourceId: string, prefix = MIRROR_PREFIX): string {
  if (!/^[A-Za-z0-9_-]{1,64}$/.test(sourceId)) throw new Error("Invalid source id");
  return `${prefix}/fb/${kind}-${sourceId}`;
}

export function isMirrorKey(key: string, prefix: string): boolean {
  const escaped = prefix.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
  return new RegExp(`^${escaped}/fb/(photo|video)-[A-Za-z0-9_-]{1,64}$`).test(key);
}

export type FacebookImage = { source?: string; width?: number; height?: number };

/** The largest https image Facebook returned, or null when none is usable. */
export function largestImage(images: FacebookImage[] | undefined): { url: string; width: number | null; height: number | null } | null {
  const usable = (images ?? []).filter((image) => typeof image.source === "string" && image.source.startsWith("https://"));
  if (!usable.length) return null;
  usable.sort((a, b) => (b.width ?? 0) * (b.height ?? 0) - (a.width ?? 0) * (a.height ?? 0));
  const best = usable[0];
  return { url: best.source!, width: best.width ?? null, height: best.height ?? null };
}

export type FacebookPhoto = { id: string; name?: string; created_time?: string; link?: string; images?: FacebookImage[] };

export type PhotoRow = {
  id: string;
  caption: string;
  permalink: string;
  published_at: string;
  width: number | null;
  height: number | null;
  source_url: string;
};

/** Facebook sends times like 2026-09-01T10:00:00+0000; store them as UTC ISO strings. */
export function toIso(value: string | undefined): string | null {
  if (!value) return null;
  const normalised = value.replace(/([+-]\d{2})(\d{2})$/, "$1:$2");
  const date = new Date(normalised);
  return Number.isNaN(date.getTime()) ? null : date.toISOString();
}

export function photoRow(photo: FacebookPhoto): PhotoRow | null {
  const image = largestImage(photo.images);
  const publishedAt = toIso(photo.created_time);
  if (!image || !publishedAt || !photo.link?.startsWith("https://") || !/^[A-Za-z0-9_-]{1,64}$/.test(photo.id)) return null;
  return {
    id: photo.id,
    caption: (photo.name ?? "").slice(0, 2000),
    permalink: photo.link,
    published_at: publishedAt,
    width: image.width,
    height: image.height,
    source_url: image.url,
  };
}

export type FacebookVideo = {
  id: string;
  title?: string;
  description?: string;
  created_time?: string;
  length?: number;
  permalink_url?: string;
  picture?: string;
  live_status?: string;
  /** Encodings of the video; each carries the frame size. */
  format?: { width?: number; height?: number }[];
};

export type VideoFormat = "standard" | "short" | "portrait";

/** YouTube Shorts can be up to 3 minutes long. */
export const SHORT_MAX_SECONDS = 180;

/**
 * Classifies a video's shape. "short" is a Reel or a portrait clip up to
 * SHORT_MAX_SECONDS (or anything the platform itself marks as a short);
 * "portrait" is taller than wide but longer than that; everything else is
 * "standard". Missing dimensions are never guessed from the title.
 */
export function videoFormat(input: { reel?: boolean; width?: number | null; height?: number | null; durationSeconds?: number | null }): VideoFormat {
  const portrait = (input.width ?? 0) > 0 && (input.height ?? 0) > (input.width ?? 0);
  if (input.reel) return "short";
  if (!portrait) return "standard";
  return input.durationSeconds != null && input.durationSeconds <= SHORT_MAX_SECONDS ? "short" : "portrait";
}

/** The frame size of the largest encoding Facebook reports, if any. */
export function largestFrame(formats: FacebookVideo["format"]): { width: number; height: number } | null {
  const sized = (formats ?? []).filter((f) => (f.width ?? 0) > 0 && (f.height ?? 0) > 0);
  if (!sized.length) return null;
  sized.sort((a, b) => (b.width ?? 0) * (b.height ?? 0) - (a.width ?? 0) * (a.height ?? 0));
  return { width: sized[0].width!, height: sized[0].height! };
}

export type VideoRow = {
  id: string;
  provider: "youtube" | "facebook";
  external_id: string;
  title: string;
  description: string | null;
  thumbnail_url: string | null;
  permalink_url: string;
  embed_url: string | null;
  kind: "video" | "live";
  published_at: string;
  duration_seconds: number | null;
  mirror_status: "pending" | "done";
  format: VideoFormat;
  /** 1 while the livestream is on air. */
  live_now: 0 | 1;
};

// live_status values that describe a livestream (or its replay). Scheduled
// broadcasts that have not started are not published yet and are skipped.
const FACEBOOK_LIVE = new Set(["LIVE", "LIVE_NOW", "LIVE_STOPPED", "PROCESSING", "VOD"]);
// The subset that means the broadcast is on air right now.
const FACEBOOK_ON_AIR = new Set(["LIVE", "LIVE_NOW"]);
const FACEBOOK_NOT_PUBLISHED = new Set(["SCHEDULED_UPCOMING", "SCHEDULED_LIVE", "SCHEDULED_UNPUBLISHED", "SCHEDULED_CANCELED", "UNPUBLISHED"]);

export function facebookPermalink(value: string | undefined): string | null {
  if (!value) return null;
  const absolute = value.startsWith("/") ? `https://www.facebook.com${value}` : value;
  return absolute.startsWith("https://") ? absolute : null;
}

export function videoRowFromFacebook(video: FacebookVideo): VideoRow | null {
  if (video.live_status && FACEBOOK_NOT_PUBLISHED.has(video.live_status)) return null;
  const permalink = facebookPermalink(video.permalink_url);
  const publishedAt = toIso(video.created_time);
  if (!permalink || !publishedAt || !/^[A-Za-z0-9_-]{1,64}$/.test(video.id)) return null;
  const thumbnail = video.picture?.startsWith("https://") ? video.picture : null;
  const frame = largestFrame(video.format);
  const duration = typeof video.length === "number" ? Math.round(video.length) : null;
  const onAir = Boolean(video.live_status && FACEBOOK_ON_AIR.has(video.live_status));
  return {
    id: `facebook:${video.id}`,
    provider: "facebook",
    external_id: video.id,
    title: (video.title ?? "").trim() || (video.description ?? "").trim().split("\n")[0].slice(0, 120),
    description: video.description?.slice(0, 2000) ?? null,
    thumbnail_url: thumbnail,
    permalink_url: permalink,
    embed_url: null,
    kind: video.live_status && FACEBOOK_LIVE.has(video.live_status) ? "live" : "video",
    published_at: publishedAt,
    duration_seconds: duration,
    mirror_status: thumbnail ? "pending" : "done",
    // A livestream is never a short, even if it was streamed from a phone.
    format: onAir || (video.live_status && FACEBOOK_LIVE.has(video.live_status)) ? "standard" : videoFormat({ reel: /\/reels?\//i.test(permalink), width: frame?.width, height: frame?.height, durationSeconds: duration }),
    live_now: onAir ? 1 : 0,
  };
}

export type YouTubeVideoItem = {
  id: string;
  snippet?: {
    title?: string;
    description?: string;
    publishedAt?: string;
    liveBroadcastContent?: string;
    thumbnails?: Record<string, { url?: string }>;
  };
  contentDetails?: { duration?: string };
  liveStreamingDetails?: { actualStartTime?: string; actualEndTime?: string; scheduledStartTime?: string };
  status?: { privacyStatus?: string; embeddable?: boolean };
};

/** Seconds in an ISO 8601 duration such as PT1H5M9S. Returns null if unreadable. */
export function parseIsoDuration(value: string | undefined): number | null {
  const match = /^P(?:(\d+)D)?(?:T(?:(\d+)H)?(?:(\d+)M)?(?:(\d+)S)?)?$/.exec(value ?? "");
  if (!match) return null;
  const [d, h, m, s] = [1, 2, 3, 4].map((index) => (match[index] ? Number(match[index]) : 0));
  return d * 86400 + h * 3600 + m * 60 + s;
}

/**
 * Whether a YouTube video could be a Short, judged from the data we already
 * have: short enough and not a livestream. YouTube does not expose the frame
 * size, so the sync confirms candidates with the /shorts/ URL.
 */
export function isShortCandidate(item: YouTubeVideoItem): boolean {
  const seconds = parseIsoDuration(item.contentDetails?.duration);
  const live = Boolean(item.liveStreamingDetails?.actualStartTime) || item.snippet?.liveBroadcastContent === "live";
  return !live && seconds !== null && seconds > 0 && seconds <= SHORT_MAX_SECONDS;
}

/** `short` is the confirmed answer for this video; pass nothing for "not a short". */
export function videoRowFromYouTube(item: YouTubeVideoItem, short = false): VideoRow | null {
  const snippet = item.snippet;
  if (!snippet?.publishedAt || !/^[A-Za-z0-9_-]{1,64}$/.test(item.id)) return null;
  if (item.status?.privacyStatus && item.status.privacyStatus !== "public") return null;
  // Upcoming broadcasts have not started and cannot be watched yet.
  if (snippet.liveBroadcastContent === "upcoming") return null;
  const thumbs = snippet.thumbnails ?? {};
  const thumbnail = (thumbs.maxres ?? thumbs.high ?? thumbs.medium ?? thumbs.default)?.url ?? null;
  const live = Boolean(item.liveStreamingDetails?.actualStartTime) || snippet.liveBroadcastContent === "live";
  return {
    id: `youtube:${item.id}`,
    provider: "youtube",
    external_id: item.id,
    title: snippet.title ?? "",
    description: snippet.description?.slice(0, 2000) ?? null,
    thumbnail_url: thumbnail?.startsWith("https://") ? thumbnail : null,
    permalink_url: `https://www.youtube.com/watch?v=${encodeURIComponent(item.id)}`,
    embed_url: item.status?.embeddable === false ? null : `https://www.youtube-nocookie.com/embed/${encodeURIComponent(item.id)}`,
    kind: live ? "live" : "video",
    published_at: toIso(item.liveStreamingDetails?.actualStartTime) ?? toIso(snippet.publishedAt) ?? snippet.publishedAt,
    duration_seconds: parseIsoDuration(item.contentDetails?.duration),
    mirror_status: "done",
    format: short && !live ? "short" : "standard",
    live_now: snippet.liveBroadcastContent === "live" ? 1 : 0,
  };
}

/** The uploads playlist of a standard YouTube channel id (UC... becomes UU...). */
export function uploadsPlaylistId(channelId: string): string {
  if (!/^UC[A-Za-z0-9_-]{22}$/.test(channelId)) throw new Error("Invalid YouTube channel id");
  return `UU${channelId.slice(2)}`;
}

export function chunk<T>(items: T[], size: number): T[][] {
  const out: T[][] = [];
  for (let i = 0; i < items.length; i += size) out.push(items.slice(i, i + size));
  return out;
}
