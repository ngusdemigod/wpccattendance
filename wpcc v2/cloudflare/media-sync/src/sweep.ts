import { chunk, mirrorKey } from "./mappers";
import type { Env } from "./types";

// Files we write: <prefix>/fb/<photo|video>-<id>/<file>. Anything else under the
// prefix is not ours to touch.
const OBJECT_KEY = /^(.+)\/fb\/(photo|video)-([A-Za-z0-9_-]{1,64})\/(original|w1600\.webp|w480\.webp)$/;
const PAGE = 1000;
const MAX_PAGES = 10;

export type SweepResult = { scanned: number; orphans: number; legacyOriginals: number; deleted: number; truncated: boolean };

/**
 * Deletes stored files that no longer belong to anything in the catalog:
 * leftovers of removed items (for example after an interrupted cleanup) and the
 * old full-size originals, which are no longer kept. Only keys of the exact shape
 * this worker writes are ever deleted, and at most 10,000 objects are scanned
 * per run (the catalog holds a few hundred).
 */
export async function sweepOrphans(env: Env): Promise<SweepResult> {
  const prefix = env.MEDIA_PREFIX;
  const photoIds = ((await env.DB.prepare("SELECT id FROM photos").all<{ id: string }>()).results ?? []).map((row) => row.id);
  const videoIds = ((await env.DB.prepare("SELECT external_id FROM videos WHERE provider = 'facebook'").all<{ external_id: string }>()).results ?? []).map((row) => row.external_id);
  const wanted = new Set<string>();
  for (const id of photoIds) wanted.add(mirrorKey("photo", id, prefix));
  for (const id of videoIds) wanted.add(mirrorKey("video", id, prefix));

  const doomed: string[] = [];
  let scanned = 0;
  let orphans = 0;
  let legacyOriginals = 0;
  let cursor: string | undefined;
  let truncated = false;
  for (let page = 0; page < MAX_PAGES; page++) {
    const listing = await env.MEDIA.list({ prefix: `${prefix}/fb/`, limit: PAGE, cursor });
    for (const object of listing.objects) {
      scanned++;
      const match = OBJECT_KEY.exec(object.key);
      if (!match || match[1] !== prefix) continue; // not one of our files: leave it alone
      const itemPrefix = `${prefix}/fb/${match[2]}-${match[3]}`;
      if (!wanted.has(itemPrefix)) {
        orphans++;
        doomed.push(object.key);
      } else if (match[4] === "original") {
        legacyOriginals++;
        doomed.push(object.key);
      }
    }
    if (!listing.truncated) break;
    cursor = (listing as { cursor?: string }).cursor;
    truncated = page === MAX_PAGES - 1;
  }

  // R2 accepts up to 1000 keys per delete call: one request per batch.
  for (const group of chunk(doomed, PAGE)) await env.MEDIA.delete(group);
  const result = { scanned, orphans, legacyOriginals, deleted: doomed.length, truncated };
  console.log(JSON.stringify({ event: "media_sweep", ...result }));
  return result;
}
