import { createClient } from "jsr:@supabase/supabase-js@2.117.1";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";

const encoder = new TextEncoder();
const required = (name: string) => {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error("Rewards service is not configured");
  return value;
};
async function key() {
  return crypto.subtle.importKey("raw", encoder.encode(required("WPCC_REWARDS_WORKER_SECRET")),
    { name: "HMAC", hash: "SHA-256" }, false, ["sign", "verify"]);
}
const hex = (bytes: ArrayBuffer) => Array.from(new Uint8Array(bytes), b => b.toString(16).padStart(2, "0")).join("");
async function signed(value: string) {
  return hex(await crypto.subtle.sign("HMAC", await key(), encoder.encode(value)));
}
async function validSignature(raw: string, request: Request) {
  const timestamp = request.headers.get("x-rewards-time") ?? "";
  const signature = request.headers.get("x-rewards-signature") ?? "";
  if (!/^\d{13}$/.test(timestamp) || Math.abs(Date.now() - Number(timestamp)) > 60_000 ||
      !/^[a-f0-9]{64}$/.test(signature)) return false;
  return crypto.subtle.verify("HMAC", await key(),
    Uint8Array.from(signature.match(/../g)!, s => parseInt(s, 16)),
    encoder.encode(timestamp + "\n" + raw));
}
async function boundedBody(request: Request): Promise<string> {
  if (!request.body) return "";
  const reader = request.body.getReader();
  const chunks: Uint8Array[] = []; let size = 0;
  while (true) {
    const { value, done } = await reader.read();
    if (done) break;
    size += value.byteLength;
    if (size > 65536) { await reader.cancel(); throw new Error("Payload too large"); }
    chunks.push(value);
  }
  const bytes = new Uint8Array(size); let offset = 0;
  for (const chunk of chunks) { bytes.set(chunk, offset); offset += chunk.length; }
  return new TextDecoder().decode(bytes);
}
Deno.serve(async request => {
  if (request.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (request.method !== "POST") return jsonResponse({ error: "Method not allowed" }, { status: 405 });
  try {
    const raw = await boundedBody(request);
    const body = JSON.parse(raw);
    const url = Deno.env.get("PROJECT_URL") || required("SUPABASE_URL");
    const serviceKey = Deno.env.get("SUPABASE_SECRET_KEY") || Deno.env.get("SERVICE_ROLE_KEY") || required("SUPABASE_SERVICE_ROLE_KEY");
    const admin = createClient(url, serviceKey, { auth: { persistSession: false, autoRefreshToken: false } });
    if (body.action === "prayer-ticket") {
      const token = request.headers.get("authorization")?.replace(/^Bearer /, "") ?? "";
      const { data, error } = await admin.auth.getUser(token);
      if (error || !data.user) return jsonResponse({ error: "Authentication required" }, { status: 401 });
      if (typeof body.session_id !== "string") return jsonResponse({ error: "Session required" }, { status: 400 });
      const { data: context, error: contextError } = await admin.rpc("rewards_prayer_context",
        { p_user: data.user.id, p_session: body.session_id });
      if (contextError) throw contextError;
      if (!context) return jsonResponse({ eligible: false });
      const payload = btoa(JSON.stringify({ ...context, exp: Math.min(context.end, Date.now() + 300_000) }));
      const ticket = payload + "." + await signed("prayer:" + payload);
      return jsonResponse({ eligible: true, ticket, expires_at: Math.min(context.end, Date.now() + 300_000),
        heartbeat_url: required("WPCC_REWARDS_WORKER_URL") + "/prayer" },
        { headers: { "Cache-Control": "no-store" } });
    }
    if (!await validSignature(raw, request)) return jsonResponse({ error: "Unauthorized worker" }, { status: 401 });
    let rpc: string; let params: Record<string, unknown>;
    switch (body.action) {
      case "claim": rpc = "rewards_claim_events"; params = { p_limit: 100 }; break;
      case "settle": rpc = "rewards_settle_events"; params = { p_events: body.events }; break;
      case "failed": rpc = "rewards_fail_events"; params = { p_events: body.events }; break;
      case "reconcile": rpc = "rewards_reconcile"; params = { p_limit: 100 }; break;
      case "prayer": rpc = "rewards_record_prayer"; params = {
        p_user: body.user, p_occurrence: body.occurrence, p_seconds: body.seconds }; break;
      default: return jsonResponse({ error: "Unknown operation" }, { status: 400 });
    }
    const { data, error } = await admin.rpc(rpc, params);
    if (error) throw error;
    return jsonResponse({ data }, { headers: { "Cache-Control": "no-store" } });
  } catch (error) {
    console.error("rewards_backend_failed", { message: error instanceof Error ? error.message : "Operation failed" });
    return jsonResponse({ error: "Rewards operation unavailable" }, { status: 503 });
  }
});
