import { DurableObject } from "cloudflare:workers";
import { backend, connectedInterval, pointsFor, verifyTicket } from "./protocol";
import type { PrayerTicket, RewardEvent } from "./protocol";

export class PrayerParticipation extends DurableObject<Env> {
  async heartbeat(ticket: PrayerTicket): Promise<{ qualified: boolean; connected_seconds: number }> {
    const now = Date.now();
    // Storage transactions serialize concurrent devices for this member/occurrence.
    const state = await this.ctx.storage.transaction(async txn => {
      const current = await txn.get<{ last: number | null; ms: number; recorded: boolean }>("state")
        ?? { last: null, ms: 0, recorded: false };
      if (!current.recorded && (current.last === null || now - current.last >= 5000)) {
        current.ms += connectedInterval(current.last, now, ticket.start, ticket.end);
        current.last = Math.max(current.last ?? now, now);
        await txn.put("state", current);
        await txn.put("ticket", ticket);
        await txn.setAlarm(Math.min(now + 60_000, ticket.end + 60_000));
      }
      return current;
    });
    if (!state.recorded && state.ms >= ticket.threshold * 1000) {
      await this.record(ticket, state.ms);
    }
    return { qualified: state.ms >= ticket.threshold * 1000, connected_seconds: Math.floor(state.ms / 1000) };
  }
  private async record(ticket: PrayerTicket, ms: number) {
    await backend(this.env, "prayer", { user: ticket.user, occurrence: ticket.occurrence, seconds: Math.floor(ms / 1000) });
    await this.ctx.storage.transaction(async txn => {
      const state = await txn.get<{ last: number | null; ms: number; recorded: boolean }>("state");
      if (state) await txn.put("state", { ...state, recorded: true });
      await txn.setAlarm(ticket.end + 86400_000);
    });
  }
  async alarm() {
    const ticket = await this.ctx.storage.get<PrayerTicket>("ticket");
    const state = await this.ctx.storage.get<{ ms: number; recorded: boolean }>("state");
    if (!ticket || !state) return;
    if (!state.recorded && state.ms >= ticket.threshold * 1000) {
      await this.record(ticket, state.ms); // Alarm retries retain earned evidence through backend outages.
    } else if (Date.now() >= ticket.end + 86400_000) {
      await this.ctx.storage.deleteAll();
    } else {
      await this.ctx.storage.setAlarm(ticket.end + 86400_000);
    }
  }
}

export default {
  async scheduled(controller: ScheduledController, env: Env): Promise<void> {
    const events = await backend(env, "claim") as RewardEvent[];
    if (events.length) {
      // A failed send leaves the database lease to expire; do not acknowledge a claim here.
      await env.REWARDS_QUEUE.sendBatch(events.map(body => ({ body, contentType: "json" as const })));
    }
    if (new Date(controller.scheduledTime).getUTCMinutes() === 0) {
      await backend(env, "reconcile");
    }
    console.log(JSON.stringify({ event: "rewards_claimed", count: events.length }));
  },
  async queue(batch: MessageBatch<RewardEvent>, env: Env): Promise<void> {
    try {
      const events = batch.messages.map(m => m.body);
      if (batch.queue === "wpcc-rewards-failed") {
        await backend(env, "failed", { events });
        console.error(JSON.stringify({ event: "rewards_failed_batch", count: events.length }));
      } else {
        await backend(env, "settle", { events: events.map(e => ({ ...e, points: pointsFor(e.kind) })) });
      }
      batch.ackAll(); // Only acknowledge after the database transaction succeeds.
    } catch (error) {
      console.error(JSON.stringify({ event: "rewards_retry", count: batch.messages.length,
        error: error instanceof Error ? error.message : "Processing failed" }));
      batch.retryAll({ delaySeconds: 30 });
    }
  },
  async fetch(request: Request, env: Env): Promise<Response> {
    const origin = request.headers.get("origin") ?? "";
    const allowed = env.ALLOWED_ORIGINS.split(",").includes(origin);
    const cors: Record<string, string> = allowed ? {
      "Access-Control-Allow-Origin": origin, "Vary": "Origin",
      "Access-Control-Allow-Headers": "authorization,content-type",
      "Access-Control-Allow-Methods": "POST,OPTIONS",
    } : {};
    if (request.method === "OPTIONS") return new Response(null, { status: allowed ? 204 : 403, headers: cors });
    if (new URL(request.url).pathname !== "/prayer" || request.method !== "POST") return new Response("Not found", { status: 404 });
    if (origin && !allowed) return new Response("Origin denied", { status: 403 });
    const ticket = await verifyTicket(env.WPCC_REWARDS_WORKER_SECRET,
      request.headers.get("authorization")?.replace(/^Bearer /, "") ?? "");
    if (!ticket) return Response.json({ error: "Invalid participation ticket" }, { status: 401, headers: cors });
    try {
      const stub = env.PRAYER.getByName(ticket.user + ":" + ticket.occurrence);
      return Response.json(await stub.heartbeat(ticket), { headers: { ...cors, "Cache-Control": "no-store" } });
    } catch {
      return Response.json({ error: "Participation update unavailable" }, { status: 503, headers: cors });
    }
  },
} satisfies ExportedHandler<Env, RewardEvent>;
