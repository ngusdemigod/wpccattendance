export type RewardEvent = {
  id: string; lease_token: string; revision: number;
  kind: "attendance" | "giving" | "prayer" | "profile";
};
export type PrayerTicket = {
  user: string; occurrence: string; start: number; end: number; threshold: number; exp: number;
};
export function pointsFor(kind: RewardEvent["kind"]): number {
  switch (kind) {
    case "attendance": case "giving": case "prayer": return 30;
    case "profile": return 15;
    default: throw new Error("Unknown reward kind");
  }
}
export function connectedInterval(last: number | null, now: number, start: number, end: number): number {
  if (last === null || now <= last || now - last > 90_000) return 0;
  return Math.max(0, Math.min(now, end) - Math.max(last, start));
}
const encoder = new TextEncoder();
export async function signingKey(secret: string) {
  return crypto.subtle.importKey("raw", encoder.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign", "verify"]);
}
export async function signature(secret: string, value: string) {
  const bytes = await crypto.subtle.sign("HMAC", await signingKey(secret), encoder.encode(value));
  return [...new Uint8Array(bytes)].map(x => x.toString(16).padStart(2, "0")).join("");
}
export async function verifyTicket(secret: string, token: string, now = Date.now()): Promise<PrayerTicket | null> {
  try {
    if (token.length > 4096) return null;
    const parts = token.split(".");
    if (parts.length !== 2 || !/^[a-f0-9]{64}$/.test(parts[1])) return null;
    const valid = await crypto.subtle.verify("HMAC", await signingKey(secret),
      Uint8Array.from(parts[1].match(/../g)!, x => parseInt(x, 16)), encoder.encode("prayer:" + parts[0]));
    if (!valid) return null;
    const t: PrayerTicket = JSON.parse(atob(parts[0]));
    const uuid = /^[0-9a-f-]{36}$/;
    if (!uuid.test(t.user) || !uuid.test(t.occurrence) ||
        ![t.start,t.end,t.threshold,t.exp].every(Number.isFinite) ||
        t.exp <= now || t.end <= now || t.start > now || t.end <= t.start ||
        t.threshold < 1 || t.threshold > 600) return null;
    return t;
  } catch { return null; }
}
export async function backend(env: Env, action: string, values: Record<string, unknown> = {}) {
  const raw = JSON.stringify({ action, ...values });
  const timestamp = String(Date.now());
  const response = await fetch(env.WPCC_PROJECT_URL + "/functions/v1/rewards-worker", {
    method: "POST", signal: AbortSignal.timeout(20_000),
    headers: { "Content-Type": "application/json", "x-rewards-time": timestamp,
      "x-rewards-signature": await signature(env.WPCC_REWARDS_WORKER_SECRET, timestamp + "\n" + raw) },
    body: raw,
  });
  if (!response.ok) {
    await response.body?.cancel();
    throw new Error("Rewards backend status " + response.status);
  }
  const result = await response.json<{ data: unknown }>();
  return result.data;
}
