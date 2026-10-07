import { chunk, mirrorKey, type PhotoRow, type VideoRow } from "./mappers";
import type { MirrorJob, MirrorTable, SyncSource } from "./types";

// D1 allows 100 bound parameters per statement and bills per row written, so
// writes are conditional: a row that has not changed is not written at all.
const BATCH = 50;

export async function upsertPhotos(db: D1Database, rows: PhotoRow[]): Promise<void> {
  const statement = db.prepare(
    `INSERT INTO photos (id, caption, permalink, published_at, width, height, source_url)
     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7)
     ON CONFLICT(id) DO UPDATE SET
       caption = excluded.caption,
       permalink = excluded.permalink,
       published_at = excluded.published_at,
       width = excluded.width,
       height = excluded.height,
       is_active = 1,
       source_url = CASE WHEN photos.mirror_status = 'done' THEN photos.source_url ELSE excluded.source_url END
     WHERE photos.caption IS NOT excluded.caption
        OR photos.permalink IS NOT excluded.permalink
        OR photos.published_at IS NOT excluded.published_at
        OR photos.width IS NOT excluded.width
        OR photos.height IS NOT excluded.height
        OR photos.is_active = 0
        OR (photos.mirror_status != 'done' AND photos.source_url IS NOT excluded.source_url)`,
  );
  for (const group of chunk(rows, BATCH)) {
    await db.batch(group.map((row) => statement.bind(row.id, row.caption, row.permalink, row.published_at, row.width, row.height, row.source_url)));
  }
}

export async function upsertVideos(db: D1Database, rows: VideoRow[]): Promise<void> {
  const statement = db.prepare(
    `INSERT INTO videos (id, provider, external_id, title, description, thumbnail_url, permalink_url, embed_url, kind, published_at, duration_seconds, mirror_status, format, live_now)
     VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8, ?9, ?10, ?11, ?12, ?13, ?14)
     ON CONFLICT(id) DO UPDATE SET
       title = excluded.title,
       description = excluded.description,
       permalink_url = excluded.permalink_url,
       embed_url = excluded.embed_url,
       kind = excluded.kind,
       published_at = excluded.published_at,
       duration_seconds = excluded.duration_seconds,
       format = excluded.format,
       live_now = excluded.live_now,
       status = 'published',
       thumbnail_url = CASE WHEN videos.provider = 'facebook' AND videos.mirror_status = 'done' THEN videos.thumbnail_url ELSE excluded.thumbnail_url END
     WHERE videos.title IS NOT excluded.title
        OR videos.description IS NOT excluded.description
        OR videos.permalink_url IS NOT excluded.permalink_url
        OR videos.embed_url IS NOT excluded.embed_url
        OR videos.kind IS NOT excluded.kind
        OR videos.published_at IS NOT excluded.published_at
        OR videos.duration_seconds IS NOT excluded.duration_seconds
        OR videos.format IS NOT excluded.format
        OR videos.live_now IS NOT excluded.live_now
        OR videos.status != 'published'
        OR (videos.provider = 'youtube' AND videos.thumbnail_url IS NOT excluded.thumbnail_url)
        OR (videos.provider = 'facebook' AND videos.mirror_status != 'done' AND videos.thumbnail_url IS NOT excluded.thumbnail_url)`,
  );
  for (const group of chunk(rows, BATCH)) {
    await db.batch(
      group.map((row) =>
        statement.bind(row.id, row.provider, row.external_id, row.title, row.description, row.thumbnail_url, row.permalink_url, row.embed_url, row.kind, row.published_at, row.duration_seconds, row.mirror_status, row.format, row.live_now),
      ),
    );
  }
}

export type PruneResult = { outcome: string; deleted: number; deletedKeys: string[] };

/**
 * Keeps only the items the source just returned (its newest window). Anything
 * else, whether older than the window or deleted at the source, is removed so
 * no junk and no deleted photo lingers. Skipped when the source returned less
 * than half of the items we expect (at most the window size, or fewer if we
 * hold fewer), so one odd response cannot empty the catalog.
 */
export async function pruneToWindow(
  db: D1Database,
  table: "photos" | "videos",
  provider: "facebook" | "youtube" | null,
  seen: Set<string>,
  windowSize: number,
): Promise<PruneResult> {
  const select =
    table === "photos"
      ? db.prepare("SELECT id, id AS source_id FROM photos")
      : db.prepare("SELECT id, external_id AS source_id FROM videos WHERE provider = ?1").bind(provider);
  const held = ((await select.all<{ id: string; source_id: string }>()).results ?? []);
  const missing = held.filter((row) => !seen.has(row.id));
  const expected = Math.min(held.length, windowSize);
  if (held.length > 0 && !(seen.size > 0 && seen.size >= expected * 0.5)) {
    return { outcome: "skipped: source returned too few items", deleted: 0, deletedKeys: [] };
  }
  const remove = db.prepare(`DELETE FROM ${table} WHERE id = ?1`);
  for (const group of chunk(missing, BATCH)) await db.batch(group.map((row) => remove.bind(row.id)));

  // YouTube thumbnails are not copied, so only photos and Facebook videos have files.
  const keys = table === "photos" ? missing.map((row) => mirrorKey("photo", row.source_id)) : provider === "facebook" ? missing.map((row) => mirrorKey("video", row.source_id)) : [];
  return { outcome: `removed ${missing.length}`, deleted: missing.length, deletedKeys: keys };
}

/** Retried once a day so permanent failures do not retry every half hour. */
export async function retryFailedMirrors(db: D1Database): Promise<void> {
  await db.batch([
    db.prepare("UPDATE photos SET mirror_status = 'pending' WHERE is_active = 1 AND mirror_status = 'failed'"),
    db.prepare("UPDATE videos SET mirror_status = 'pending' WHERE status = 'published' AND provider = 'facebook' AND mirror_status = 'failed'"),
  ]);
}

/** Images that still need copying, newest first. The window is small, so this is a handful. */
export async function pendingJobs(db: D1Database, table: MirrorTable): Promise<MirrorJob[]> {
  if (table === "photos") {
    const rows = (
      await db.prepare("SELECT id, source_url, width, height FROM photos WHERE is_active = 1 AND mirror_status = 'pending' ORDER BY published_at DESC LIMIT 200")
        .all<{ id: string; source_url: string; width: number | null; height: number | null }>()
    ).results ?? [];
    return rows.map((row) => ({ type: "mirror", table: "photos", id: row.id, source_url: row.source_url, key: mirrorKey("photo", row.id), width: row.width, height: row.height }));
  }
  const rows = (
    await db.prepare(
      `SELECT id, external_id, thumbnail_url FROM videos
       WHERE provider = 'facebook' AND status = 'published' AND mirror_status = 'pending' AND thumbnail_url IS NOT NULL
       ORDER BY published_at DESC LIMIT 200`,
    ).all<{ id: string; external_id: string; thumbnail_url: string }>()
  ).results ?? [];
  return rows.map((row) => ({ type: "mirror", table: "videos", id: row.id, source_url: row.thumbnail_url, key: mirrorKey("video", row.external_id) }));
}

/** Whether the item still exists and is wanted, so a queued copy of a removed item can be skipped. */
export async function isWanted(db: D1Database, job: Pick<MirrorJob, "table" | "id">): Promise<boolean> {
  const row =
    job.table === "photos"
      ? await db.prepare("SELECT 1 AS ok FROM photos WHERE id = ?1 AND is_active = 1").bind(job.id).first()
      : await db.prepare("SELECT 1 AS ok FROM videos WHERE id = ?1 AND status = 'published'").bind(job.id).first();
  return row !== null;
}

/**
 * Records the result of copying an image. Returns false when the row is no
 * longer active (removed at the source meanwhile), so the caller can remove
 * the files it just wrote.
 */
export async function markMirror(
  db: D1Database,
  job: Pick<MirrorJob, "table" | "id" | "key">,
  status: "done" | "failed",
  size?: { width?: number; height?: number },
): Promise<boolean> {
  const active = job.table === "photos" ? "is_active = 1" : "status = 'published'";
  const result =
    status === "done"
      ? job.table === "photos"
        ? await db.prepare(`UPDATE photos SET mirror_status = 'done', r2_key = ?2, width = COALESCE(?3, width), height = COALESCE(?4, height) WHERE id = ?1 AND ${active}`)
            .bind(job.id, job.key, size?.width ?? null, size?.height ?? null).run()
        : await db.prepare(`UPDATE videos SET mirror_status = 'done', r2_key = ?2 WHERE id = ?1 AND ${active}`).bind(job.id, job.key).run()
      : await db.prepare(`UPDATE ${job.table} SET mirror_status = 'failed', r2_key = NULL WHERE id = ?1 AND ${active}`).bind(job.id).run();
  return (result.meta?.changes ?? 0) > 0;
}

export async function recordSync(db: D1Database, source: SyncSource, error?: string): Promise<void> {
  const now = new Date().toISOString();
  if (error) {
    await db
      .prepare("INSERT INTO sync_state (source, last_error, updated_at) VALUES (?1, ?2, ?3) ON CONFLICT(source) DO UPDATE SET last_error = excluded.last_error, updated_at = excluded.updated_at")
      .bind(source, error.slice(0, 500), now).run();
  } else {
    await db
      .prepare("INSERT INTO sync_state (source, last_success_at, last_error, updated_at) VALUES (?1, ?2, NULL, ?2) ON CONFLICT(source) DO UPDATE SET last_success_at = excluded.last_success_at, last_error = NULL, updated_at = excluded.updated_at")
      .bind(source, now).run();
  }
}

// ---- Reads for the public API (all use partial indexes) ----

export type Cursor = { publishedAt: string; id: string } | null;

export function parseCursor(value: string | null): Cursor | "invalid" {
  if (!value) return null;
  const separator = value.indexOf("|");
  if (separator < 1) return "invalid";
  const publishedAt = value.slice(0, separator);
  const id = value.slice(separator + 1);
  if (Number.isNaN(Date.parse(publishedAt)) || !publishedAt.endsWith("Z") || !/^[A-Za-z0-9_:-]{1,80}$/.test(id)) return "invalid";
  return { publishedAt, id };
}

export const cursorFor = (row: { published_at: string; id: string }) => `${row.published_at}|${row.id}`;

export async function queryGallery(db: D1Database, cursor: Cursor, limit: number) {
  const rows = (
    await db.prepare(
      `SELECT id, caption, permalink, published_at, width, height, r2_key FROM photos
       WHERE is_active = 1 AND mirror_status = 'done'
         AND (?1 IS NULL OR published_at < ?1 OR (published_at = ?1 AND id < ?2))
       ORDER BY published_at DESC, id DESC LIMIT ?3`,
    ).bind(cursor?.publishedAt ?? null, cursor?.id ?? null, limit + 1).all<{ id: string; published_at: string }>()
  ).results ?? [];
  const page = rows.slice(0, limit);
  return { items: page, next: rows.length > limit ? cursorFor(page[page.length - 1]) : null };
}

/** What a link preview needs to know about one video. */
export async function videoPreview(db: D1Database, id: string) {
  return db
    .prepare("SELECT provider, title, kind, thumbnail_url, r2_key FROM videos WHERE id = ?1 AND status = 'published'")
    .bind(id)
    .first<{ provider: string; title: string; kind: string; thumbnail_url: string | null; r2_key: string | null }>();
}

/** What a link preview needs to know about one photo. */
export async function photoPreview(db: D1Database, id: string) {
  return db
    .prepare("SELECT caption, r2_key FROM photos WHERE id = ?1 AND is_active = 1 AND mirror_status = 'done'")
    .bind(id)
    .first<{ caption: string; r2_key: string | null }>();
}

/** Storage key prefix of a photo that is live and fully copied, or null. */
export async function photoFileKey(db: D1Database, id: string): Promise<string | null> {
  const row = await db.prepare("SELECT r2_key FROM photos WHERE id = ?1 AND is_active = 1 AND mirror_status = 'done'").bind(id).first<{ r2_key: string | null }>();
  return row?.r2_key ?? null;
}

export async function queryVideos(db: D1Database, cursor: Cursor, limit: number) {
  const rows = (
    await db.prepare(
      `SELECT id, provider, external_id, title, substr(description, 1, 600) AS description, thumbnail_url, r2_key,
              embed_url, permalink_url, kind, published_at, duration_seconds, format, live_now
       FROM videos
       WHERE status = 'published'
         AND (?1 IS NULL OR published_at < ?1 OR (published_at = ?1 AND id < ?2))
       ORDER BY published_at DESC, id DESC LIMIT ?3`,
    ).bind(cursor?.publishedAt ?? null, cursor?.id ?? null, limit + 1).all<Record<string, unknown> & { id: string; published_at: string }>()
  ).results ?? [];
  const page = rows.slice(0, limit).map((row) => ({
    ...row,
    // Facebook thumbnails expire: only expose them once mirrored. YouTube's are stable.
    thumbnail_url: row.provider === "youtube" ? row.thumbnail_url : null,
  }));
  return { items: page, next: rows.length > limit ? cursorFor(page[page.length - 1]) : null };
}

export async function queryStatus(db: D1Database) {
  return (await db.prepare("SELECT source, last_success_at, last_error FROM sync_state ORDER BY source").all()).results ?? [];
}
