import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";

export type RateLimitResult =
  | { allowed: true }
  | { allowed: false; retryAfterSeconds: number };

type EnforceRateLimitArgs = {
  supabaseAdmin: SupabaseClient;
  scope: string;
  identifier: string;
  maxAttempts: number;
  windowSeconds: number;
};

export function getRequestIp(req: Request): string {
  const forwardedFor = req.headers.get("x-forwarded-for");
  if (forwardedFor) {
    return forwardedFor.split(",")[0].trim();
  }

  return req.headers.get("cf-connecting-ip")?.trim() ||
    req.headers.get("x-real-ip")?.trim() ||
    "unknown";
}

export async function enforceRateLimit({
  supabaseAdmin,
  scope,
  identifier,
  maxAttempts,
  windowSeconds,
}: EnforceRateLimitArgs): Promise<RateLimitResult> {
  const now = new Date();
  const nowMs = now.getTime();

  const { data: row, error: readError } = await supabaseAdmin
    .from("email_rate_limits")
    .select("attempt_count, window_started_at")
    .eq("scope", scope)
    .eq("identifier", identifier)
    .maybeSingle();

  if (readError) throw readError;

  const startedAtMs = row?.window_started_at
    ? new Date(row.window_started_at).getTime()
    : null;

  if (startedAtMs === null || nowMs - startedAtMs >= windowSeconds * 1000) {
    const { error: upsertError } = await supabaseAdmin
      .from("email_rate_limits")
      .upsert(
        {
          scope,
          identifier,
          attempt_count: 1,
          window_started_at: now.toISOString(),
          updated_at: now.toISOString(),
        },
        { onConflict: "scope,identifier" },
      );

    if (upsertError) throw upsertError;
    return { allowed: true };
  }

  if ((row?.attempt_count ?? 0) >= maxAttempts) {
    const retryAfterSeconds = Math.max(
      1,
      Math.ceil((startedAtMs + windowSeconds * 1000 - nowMs) / 1000),
    );
    return { allowed: false, retryAfterSeconds };
  }

  const { error: updateError } = await supabaseAdmin
    .from("email_rate_limits")
    .update({
      attempt_count: (row?.attempt_count ?? 0) + 1,
      updated_at: now.toISOString(),
    })
    .eq("scope", scope)
    .eq("identifier", identifier);

  if (updateError) throw updateError;
  return { allowed: true };
}
