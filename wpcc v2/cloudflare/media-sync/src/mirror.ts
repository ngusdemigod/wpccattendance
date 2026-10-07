import { isWanted, markMirror } from "./db";
import { isMirrorKey } from "./mappers";
import { deleteMirrored } from "./sync";
import type { Env, MirrorJob } from "./types";

/** A failure that retrying cannot fix (bad URL, expired link, not an image). */
export class PermanentError extends Error {}

/** Largest source image we will copy. Facebook-served images are normally well under 1 MB. */
export const MAX_BYTES = 3 * 1024 * 1024;
const FETCH_TIMEOUT_MS = 20_000;
const ALLOWED_HOSTS = /(^|\.)(fbcdn\.net|facebook\.com|fbsbx\.com)$/i;
const ALLOWED_TYPES = new Set(["image/jpeg", "image/png", "image/webp", "image/gif"]);
const IMMUTABLE = "public, max-age=31536000, immutable";
// Two compressed WebP copies are stored; the original is not kept (the Facebook
// link in the viewer opens the full-size photo). w480 is written last.
const VARIANTS = [
  { name: "w1600.webp", width: 1600, quality: 80 },
  { name: "w480.webp", width: 480, quality: 75 },
] as const;

export function validateJob(value: unknown, prefix: string): MirrorJob {
  const job = value as Partial<MirrorJob> | null;
  if (!job || typeof job !== "object") throw new PermanentError("invalid job");
  if (job.table !== "photos" && job.table !== "videos") throw new PermanentError("invalid table");
  if (typeof job.id !== "string" || !job.id) throw new PermanentError("invalid id");
  if (typeof job.key !== "string" || !isMirrorKey(job.key, prefix)) throw new PermanentError("key outside prefix");
  let url: URL;
  try {
    url = new URL(String(job.source_url));
  } catch {
    throw new PermanentError("invalid source url");
  }
  if (url.protocol !== "https:" || !ALLOWED_HOSTS.test(url.hostname)) throw new PermanentError("source host not allowed");
  return job as MirrorJob;
}

const stream = (bytes: ArrayBuffer) => new Response(bytes).body as ReadableStream<Uint8Array>;

async function download(job: MirrorJob): Promise<{ bytes: ArrayBuffer; type: string }> {
  let response: Response;
  try {
    response = await fetch(job.source_url, { signal: AbortSignal.timeout(FETCH_TIMEOUT_MS) });
  } catch {
    throw new Error("download failed"); // timeout or network error: retry
  }
  if (!ALLOWED_HOSTS.test(new URL(response.url || job.source_url).hostname)) throw new PermanentError("redirected to a disallowed host");
  if (response.status === 429 || response.status >= 500) throw new Error(`source status ${response.status}`);
  if (!response.ok) throw new PermanentError(`source status ${response.status}`); // expired or removed
  const type = (response.headers.get("content-type") ?? "").split(";")[0].trim().toLowerCase();
  if (!ALLOWED_TYPES.has(type)) throw new PermanentError("not a supported image type");
  const declared = Number(response.headers.get("content-length") ?? 0);
  if (declared > MAX_BYTES) throw new PermanentError("image too large");
  const bytes = await response.arrayBuffer();
  if (bytes.byteLength > MAX_BYTES) throw new PermanentError("image too large");
  if (bytes.byteLength === 0) throw new PermanentError("empty image");
  return { bytes, type };
}

/** Writes the outcome to D1. If the item was deleted meanwhile, removes the files just written. */
async function complete(env: Env, job: MirrorJob, status: "done" | "failed", size?: { width?: number; height?: number }) {
  const stillWanted = await markMirror(env.DB, job, status, size);
  if (!stillWanted && status === "done") await deleteMirrored(env, [job.key]);
}

/**
 * Copies one image into R2 as two compressed WebP files (w1600.webp and
 * w480.webp) under the job's key, then records it in D1. Safe to run twice:
 * w480.webp is written last and marks the image as finished. Jobs for items
 * that were removed from the catalog while queued are dropped without
 * downloading anything.
 */
export async function mirrorImage(env: Env, rawJob: unknown): Promise<void> {
  const job = validateJob(rawJob, env.MEDIA_PREFIX);
  if (!(await isWanted(env.DB, job))) return;
  if (await env.MEDIA.head(`${job.key}/w480.webp`)) {
    await complete(env, job, "done");
    return;
  }

  const { bytes, type } = await download(job);
  let size: { width?: number; height?: number } | undefined;
  try {
    const info = await env.IMAGES.info(stream(bytes));
    if ("width" in info && "height" in info) size = { width: info.width, height: info.height };
  } catch {
    // Dimensions are optional; Facebook already supplied them for photos.
  }

  for (const variant of VARIANTS) {
    let body: ArrayBuffer = bytes;
    let contentType = type;
    try {
      const out = await env.IMAGES.input(stream(bytes))
        .transform({ width: variant.width, fit: "scale-down" })
        .output({ format: "image/webp", quality: variant.quality });
      body = await out.response().arrayBuffer();
      contentType = "image/webp";
    } catch {
      // Resizing unavailable: store the original bytes so the key still exists.
    }
    await env.MEDIA.put(`${job.key}/${variant.name}`, body, { httpMetadata: { contentType, cacheControl: IMMUTABLE } });
  }

  await complete(env, job, "done", size);
}

/** Marks a job failed after retries are exhausted (best effort). */
export async function markFailed(env: Env, rawJob: unknown): Promise<void> {
  try {
    await complete(env, validateJob(rawJob, env.MEDIA_PREFIX), "failed");
  } catch (error) {
    console.error(JSON.stringify({ event: "media_mirror_mark_failed_error", error: (error as Error).message }));
  }
}
