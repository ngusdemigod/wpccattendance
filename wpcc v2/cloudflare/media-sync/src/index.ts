import { handleApi } from "./api";
import { markFailed, mirrorImage, PermanentError } from "./mirror";
import { sweepOrphans } from "./sweep";
import { runSyncTask, scheduleSync } from "./sync";
import type { Env, MirrorJob, QueueMessage, SyncTask } from "./types";

/** Seconds to wait before retry number `attempt` (1-based): 60, 120, 240 ... capped at 15 minutes. */
export function retryDelay(attempt: number): number {
  return Math.min(60 * 2 ** Math.max(0, attempt - 1), 900);
}

export default {
  // One cron, every 30 minutes. It only enqueues work.
  async scheduled(controller: ScheduledController, env: Env, ctx: ExecutionContext): Promise<void> {
    ctx.waitUntil(scheduleSync(env, controller.scheduledTime));
  },

  async fetch(request: Request, env: Env, ctx: ExecutionContext): Promise<Response> {
    const cache = (globalThis as unknown as { caches?: { default?: Cache } }).caches?.default;
    return handleApi(request, env, cache, ctx);
  },

  async queue(batch: MessageBatch<QueueMessage>, env: Env): Promise<void> {
    // The dead-letter queue only records the final failure in the database.
    if (batch.queue.endsWith("-failed")) {
      for (const message of batch.messages) {
        if (message.body.type === "mirror") await markFailed(env, message.body);
        message.ack();
      }
      return;
    }
    for (const message of batch.messages) {
      if (message.body.type === "sweep") {
        try {
          await sweepOrphans(env);
          message.ack();
        } catch (error) {
          console.error(JSON.stringify({ event: "media_sweep_failed", error: (error as Error).message }));
          message.retry({ delaySeconds: retryDelay(message.attempts) });
        }
        continue;
      }
      if (message.body.type === "sync") {
        const outcome = await runSyncTask(env, message.body as SyncTask);
        if (outcome === "retry") message.retry({ delaySeconds: retryDelay(message.attempts) });
        else message.ack();
        continue;
      }
      try {
        await mirrorImage(env, message.body as MirrorJob);
        message.ack();
      } catch (error) {
        if (error instanceof PermanentError) {
          console.error(JSON.stringify({ event: "media_mirror_permanent", reason: error.message }));
          await markFailed(env, message.body);
          message.ack();
        } else {
          console.error(JSON.stringify({ event: "media_mirror_retry", attempt: message.attempts, error: (error as Error).message }));
          message.retry({ delaySeconds: retryDelay(message.attempts) });
        }
      }
    }
  },
} satisfies ExportedHandler<Env, QueueMessage>;
