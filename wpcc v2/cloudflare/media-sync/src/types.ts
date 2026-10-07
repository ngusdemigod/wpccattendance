export interface Env {
  // Storage and messaging
  DB: D1Database;
  MEDIA: R2Bucket;
  IMAGES: ImagesBinding;
  QUEUE: Queue<QueueMessage>;
  API_LIMITER: RateLimit;

  // Configuration (not secret)
  MEDIA_PREFIX: string;
  ALLOWED_ORIGINS: string;
  FACEBOOK_PAGE_ID: string;
  FACEBOOK_GRAPH_VERSION: string;
  YOUTUBE_CHANNEL_ID: string;
  /** How many of the newest photos to keep (1 to 100). */
  MAX_PHOTOS: string;
  /** How many of the newest videos to keep per source, Facebook and YouTube each (1 to 50). */
  MAX_VIDEOS: string;

  // Secrets
  FACEBOOK_PAGE_ACCESS_TOKEN: string;
  YOUTUBE_API_KEY: string;
}

export type SyncSource = "facebook_photos" | "facebook_videos" | "youtube";
export const SYNC_SOURCES: SyncSource[] = ["facebook_photos", "facebook_videos", "youtube"];

export type MirrorTable = "photos" | "videos";

/** One image to copy into R2. */
export type MirrorJob = {
  type: "mirror";
  table: MirrorTable;
  id: string;
  source_url: string;
  key: string;
  width?: number | null;
  height?: number | null;
};

/**
 * One source to sync. Each runs in its own queue invocation (its own request
 * budget). `retry_failed` is set once a day so permanent failures do not retry
 * every half hour.
 */
export type SyncTask = { type: "sync"; source: SyncSource; run_id: string; retry_failed?: boolean };

/** Deletes stored files that no longer belong to any catalog item. Queued once a day. */
export type SweepTask = { type: "sweep"; run_id: string };

export type QueueMessage = MirrorJob | SyncTask | SweepTask;

/**
 * Objects stored under each key prefix. The original is no longer stored (only
 * two compressed WebP copies); it stays in this list so older items still get
 * fully removed. w480 is written last: it is the "done" marker.
 */
export const VARIANT_NAMES = ["original", "w1600.webp", "w480.webp"] as const;
