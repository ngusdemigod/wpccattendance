import { pendingJobs, pruneToWindow, retryFailedMirrors, upsertPhotos, upsertVideos } from "./db";
import {
  type FacebookPhoto,
  type FacebookVideo,
  isShortCandidate,
  parseIsoDuration,
  photoRow,
  uploadsPlaylistId,
  videoRowFromFacebook,
  videoRowFromYouTube,
  type YouTubeVideoItem,
} from "./mappers";
import type { Env, MirrorJob, SyncTask } from "./types";

/** A problem retrying cannot fix (missing credentials, bad configuration). */
export class ConfigError extends Error {}

export type SourceResult = { synced: number; prune: string; jobs: MirrorJob[]; deletedKeys: string[] };

/**
 * The short, safe reason an upstream API gave for rejecting a request: a
 * Facebook Graph error code (for example 190 = bad token, 10 or 200 = missing
 * permission, 100 = unsupported field) or a YouTube error reason (for example
 * quotaExceeded, keyInvalid). Never the URL, token or message text.
 */
export function upstreamReason(body: unknown): string | null {
  const error = (body as { error?: { code?: unknown; errors?: { reason?: unknown }[] } } | null)?.error;
  if (!error) return null;
  const reason = error.errors?.[0]?.reason;
  if (typeof reason === "string" && /^[A-Za-z]{1,40}$/.test(reason)) return reason;
  if (typeof error.code === "number" && Number.isInteger(error.code)) return `code ${error.code}`;
  return null;
}

async function getJson<T>(url: URL, headers: Record<string, string>): Promise<T> {
  const response = await fetch(url, { headers, signal: AbortSignal.timeout(20_000) });
  if (!response.ok) {
    const body = await response.json().catch(() => null);
    const reason = upstreamReason(body);
    // The full message goes to the worker logs only; the thrown error (which
    // is stored and shown on /v1/status) carries just the status and reason.
    const detail = (body as { error?: { message?: unknown } } | null)?.error?.message;
    if (typeof detail === "string") console.error(JSON.stringify({ event: "media_upstream_error", status: response.status, detail: detail.slice(0, 200) }));
    throw new Error(`Upstream request failed (${response.status}${reason ? `, ${reason}` : ""})`);
  }
  return (await response.json()) as T;
}

type FacebookPage<T> = { data?: T[] };

/** A whole-number setting clamped to a range, with a default for missing or invalid values. */
export function limitFrom(value: string | undefined, fallback: number, max: number): number {
  const parsed = Number.parseInt(value ?? "", 10);
  return Number.isFinite(parsed) ? Math.min(Math.max(parsed, 1), max) : fallback;
}

function facebookConfig(env: Env) {
  const token = env.FACEBOOK_PAGE_ACCESS_TOKEN?.trim();
  const page = env.FACEBOOK_PAGE_ID?.trim();
  const version = env.FACEBOOK_GRAPH_VERSION?.trim() || "v24.0";
  if (!token || !page) throw new ConfigError("Facebook is not configured (page id or access token missing)");
  if (!/^[0-9]+$/.test(page) || !/^v[0-9]+\.[0-9]+$/.test(version)) throw new ConfigError("Facebook configuration is invalid");
  return { token, page, version };
}

async function syncFacebookPhotos(env: Env, task: SyncTask): Promise<SourceResult> {
  const { token, page, version } = facebookConfig(env);
  const window = limitFrom(env.MAX_PHOTOS, 50, 100);
  const url = new URL(`https://graph.facebook.com/${version}/${page}/photos`);
  url.searchParams.set("type", "uploaded");
  url.searchParams.set("fields", "id,name,created_time,images,link");
  url.searchParams.set("limit", String(window));
  const payload = await getJson<FacebookPage<FacebookPhoto>>(url, { Authorization: `Bearer ${token}` });
  if (!Array.isArray(payload.data)) throw new Error("Invalid Facebook response");
  const rows = payload.data.map(photoRow).filter((row) => row !== null);
  await upsertPhotos(env.DB, rows);
  const { outcome, deletedKeys } = await pruneToWindow(env.DB, "photos", null, new Set(rows.map((row) => row.id)), window);
  if (task.retry_failed) await retryFailedMirrors(env.DB);
  return { synced: rows.length, prune: outcome, jobs: await pendingJobs(env.DB, "photos"), deletedKeys };
}

const FACEBOOK_VIDEO_FIELDS = "id,title,description,created_time,length,permalink_url,picture,live_status";

async function syncFacebookVideos(env: Env, task: SyncTask): Promise<SourceResult> {
  const { token, page, version } = facebookConfig(env);
  const window = limitFrom(env.MAX_VIDEOS, 50, 50);
  const request = (fields: string) => {
    const url = new URL(`https://graph.facebook.com/${version}/${page}/videos`);
    url.searchParams.set("fields", fields);
    url.searchParams.set("limit", String(window));
    return getJson<FacebookPage<FacebookVideo>>(url, { Authorization: `Bearer ${token}` });
  };
  // `format` carries the frame size, which tells portrait from landscape. If
  // Facebook refuses the field for this token, sync without it rather than
  // stopping: videos then count as landscape unless their link says Reel.
  const payload = await request(`${FACEBOOK_VIDEO_FIELDS},format`).catch((error: Error) => {
    if (!/\(400/.test(error.message)) throw error;
    console.error(JSON.stringify({ event: "media_facebook_format_unavailable" }));
    return request(FACEBOOK_VIDEO_FIELDS);
  });
  if (!Array.isArray(payload.data)) throw new Error("Invalid Facebook response");
  const rows = payload.data.map(videoRowFromFacebook).filter((row) => row !== null);
  await upsertVideos(env.DB, rows);
  const { outcome, deletedKeys } = await pruneToWindow(env.DB, "videos", "facebook", new Set(rows.map((row) => row.id)), window);
  if (task.retry_failed) await retryFailedMirrors(env.DB);
  return { synced: rows.length, prune: outcome, jobs: await pendingJobs(env.DB, "videos"), deletedKeys };
}

const SHORT_CHECKS = 20;
/** Clips this short are treated as Shorts when YouTube cannot be asked. */
const SHORT_FALLBACK_SECONDS = 61;

/**
 * Which of the short-enough candidates really are YouTube Shorts. YouTube
 * serves a Short at /shorts/<id> and redirects any other video away from it, so
 * one request without following redirects tells them apart (200 = Short). If
 * that request fails, a clip of about a minute or less counts as a Short.
 */
export async function confirmShorts(candidates: YouTubeVideoItem[]): Promise<Set<string>> {
  const shorts = new Set<string>();
  await Promise.all(
    candidates.slice(0, SHORT_CHECKS).map(async (item) => {
      try {
        const response = await fetch(`https://www.youtube.com/shorts/${encodeURIComponent(item.id)}`, { redirect: "manual", signal: AbortSignal.timeout(8_000) });
        if (response.status === 200) shorts.add(item.id);
        else if (response.status < 300 || response.status >= 400) throw new Error(`status ${response.status}`);
      } catch {
        const seconds = parseIsoDuration(item.contentDetails?.duration);
        if (seconds !== null && seconds <= SHORT_FALLBACK_SECONDS) shorts.add(item.id);
      }
    }),
  );
  // Past the cap there is no budget left to ask, so the duration rule decides.
  for (const item of candidates.slice(SHORT_CHECKS)) {
    const seconds = parseIsoDuration(item.contentDetails?.duration);
    if (seconds !== null && seconds <= SHORT_FALLBACK_SECONDS) shorts.add(item.id);
  }
  return shorts;
}

async function syncYouTube(env: Env): Promise<SourceResult> {
  const apiKey = env.YOUTUBE_API_KEY?.trim();
  const channel = env.YOUTUBE_CHANNEL_ID?.trim();
  if (!apiKey || !channel) throw new ConfigError("YouTube is not configured (channel id or API key missing)");
  let playlist: string;
  try {
    playlist = uploadsPlaylistId(channel);
  } catch {
    throw new ConfigError("YouTube channel id is invalid");
  }
  const headers = { "X-Goog-Api-Key": apiKey };
  const window = limitFrom(env.MAX_VIDEOS, 50, 50);
  const listUrl = new URL("https://www.googleapis.com/youtube/v3/playlistItems");
  listUrl.searchParams.set("part", "contentDetails");
  listUrl.searchParams.set("playlistId", playlist);
  listUrl.searchParams.set("maxResults", String(window));
  const list = await getJson<{ items?: { contentDetails?: { videoId?: string } }[] }>(listUrl, headers);
  const ids = (list.items ?? []).map((item) => item.contentDetails?.videoId).filter((id): id is string => Boolean(id));
  let rows: NonNullable<ReturnType<typeof videoRowFromYouTube>>[] = [];
  if (ids.length) {
    const videosUrl = new URL("https://www.googleapis.com/youtube/v3/videos");
    videosUrl.searchParams.set("part", "snippet,contentDetails,liveStreamingDetails,status");
    videosUrl.searchParams.set("id", ids.join(","));
    const details = await getJson<{ items?: YouTubeVideoItem[] }>(videosUrl, headers);
    const items = details.items ?? [];
    const shorts = await confirmShorts(items.filter(isShortCandidate));
    rows = items.map((item) => videoRowFromYouTube(item, shorts.has(item.id))).filter((row) => row !== null);
  }
  await upsertVideos(env.DB, rows);
  const { outcome } = await pruneToWindow(env.DB, "videos", "youtube", new Set(rows.map((row) => row.id)), window);
  return { synced: rows.length, prune: outcome, jobs: [], deletedKeys: [] };
}

export function syncSource(env: Env, task: SyncTask): Promise<SourceResult> {
  switch (task.source) {
    case "facebook_photos":
      return syncFacebookPhotos(env, task);
    case "facebook_videos":
      return syncFacebookVideos(env, task);
    case "youtube":
      return syncYouTube(env);
  }
}
