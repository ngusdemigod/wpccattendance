import { recordSync } from "./db";
import { chunk, isMirrorKey } from "./mappers";
import { ConfigError, syncSource } from "./sources";
import { type Env, SYNC_SOURCES, type SweepTask, type SyncTask, VARIANT_NAMES } from "./types";

/** Failed images are retried once a day, at the 02:00 UTC (03:00 Lagos) run. */
export function shouldRetryFailed(scheduledTime: number): boolean {
  const when = new Date(scheduledTime);
  return when.getUTCHours() === 2 && when.getUTCMinutes() < 30;
}

/** Cron handler: one queue task per source, each with its own request budget. */
export async function scheduleSync(env: Env, scheduledTime: number): Promise<{ tasks: number }> {
  const run_id = String(scheduledTime);
  const retry_failed = shouldRetryFailed(scheduledTime);
  const tasks: SyncTask[] = SYNC_SOURCES.map((source) => ({ type: "sync", source, run_id, ...(retry_failed ? { retry_failed } : {}) }));
  const messages: (SyncTask | SweepTask)[] = [...tasks];
  // The daily run also sweeps up stored files that no longer belong to anything.
  if (retry_failed) messages.push({ type: "sweep", run_id });
  await env.QUEUE.sendBatch(messages.map((body) => ({ body, contentType: "json" as const })));
  console.log(JSON.stringify({ event: "media_sync_scheduled", tasks: messages.length, retry_failed }));
  return { tasks: messages.length };
}

/**
 * Deletes every stored object for the given item keys, but only keys this
 * worker owns. Deletes are batched (R2 takes up to 1000 keys per call), so
 * removing thousands of items stays within the per-invocation request limit.
 */
export async function deleteMirrored(env: Env, keys: string[]): Promise<number> {
  const objects: string[] = [];
  let items = 0;
  for (const key of keys) {
    if (!isMirrorKey(key, env.MEDIA_PREFIX)) {
      console.error(JSON.stringify({ event: "media_sync_refused_delete", reason: "key outside prefix" }));
      continue;
    }
    items++;
    for (const name of VARIANT_NAMES) objects.push(`${key}/${name}`);
  }
  for (const group of chunk(objects, 1000)) await env.MEDIA.delete(group);
  return items;
}

export type TaskOutcome = "done" | "retry" | "failed";

/**
 * Runs one source: pulls its newest window from Facebook or YouTube, writes the
 * catalog, removes anything outside the window (and its stored images), and
 * queues the images that still need copying. "retry" means a temporary
 * failure; "failed" means configuration is wrong.
 */
export async function runSyncTask(env: Env, task: SyncTask): Promise<TaskOutcome> {
  try {
    const result = await syncSource(env, task);
    for (const group of chunk(result.jobs, 100)) {
      await env.QUEUE.sendBatch(group.map((body) => ({ body, contentType: "json" as const })));
    }
    const deleted = await deleteMirrored(env, result.deletedKeys);
    await recordSync(env.DB, task.source);
    console.log(JSON.stringify({ event: "media_sync_run", source: task.source, synced: result.synced, prune: result.prune, enqueued: result.jobs.length, deleted }));
    return "done";
  } catch (error) {
    const message = (error as Error).message;
    console.error(JSON.stringify({ event: "media_sync_failed", source: task.source, error: message }));
    await recordSync(env.DB, task.source, message).catch(() => {});
    return error instanceof ConfigError ? "failed" : "retry";
  }
}
