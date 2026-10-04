import { createClient } from "jsr:@supabase/supabase-js@2";

import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { normalizeEmail } from "../_shared/mail.ts";
import { verifyOtpContextToken } from "../_shared/otp-context.ts";
import { enforceRateLimit, getRequestIp } from "../_shared/rate-limit.ts";

const OTP_VERIFY_IP_RATE_LIMIT_WINDOW_SECONDS = 10 * 60;
const OTP_VERIFY_IP_RATE_LIMIT_MAX_ATTEMPTS = 30;

function getRequiredFunctionEnv(name: string): string {
  const aliases: Record<string, string[]> = {
    SUPABASE_URL: ["PROJECT_URL"],
    SUPABASE_SERVICE_ROLE_KEY: ["SERVICE_ROLE_KEY"],
  };

  const value = Deno.env.get(name)?.trim();
  if (!value) {
    const aliasValue = aliases[name]
      ?.map((alias) => Deno.env.get(alias)?.trim())
      .find((candidate) => Boolean(candidate));
    if (aliasValue) {
      return aliasValue;
    }
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

function sanitizeOtp(input: unknown): string | null {
  if (typeof input !== "string") return null;
  const normalized = input.replaceAll(/[^0-9]/g, "");
  if (normalized.length < 4 || normalized.length > 8) {
    return null;
  }
  return normalized;
}

function sanitizeContextToken(input: unknown): string | null {
  if (typeof input !== "string") return null;
  const trimmed = input.trim();
  return trimmed.length == 0 ? null : trimmed;
}

Deno.serve(async (req: Request) => {
  try {
    if (req.method === "OPTIONS") {
      return new Response("ok", { headers: corsHeaders });
    }

    if (req.method !== "POST") {
      return jsonResponse({ error: "Method not allowed" }, { status: 405 });
    }

    const supabaseUrl = getRequiredFunctionEnv("SUPABASE_URL");
    const serviceRoleKey = getRequiredFunctionEnv("SUPABASE_SERVICE_ROLE_KEY");

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);
    const ipRateLimit = await enforceRateLimit({
      supabaseAdmin,
      scope: "otp_verify_ip",
      identifier: getRequestIp(req),
      maxAttempts: OTP_VERIFY_IP_RATE_LIMIT_MAX_ATTEMPTS,
      windowSeconds: OTP_VERIFY_IP_RATE_LIMIT_WINDOW_SECONDS,
    });

    if (!ipRateLimit.allowed) {
      return jsonResponse(
        {
          error:
            `Too many verification attempts. Retry after ${ipRateLimit.retryAfterSeconds} seconds.`,
        },
        {
          status: 429,
          headers: { "Retry-After": String(ipRateLimit.retryAfterSeconds) },
        },
      );
    }

    const body = await req.json().catch(() => null);
    const otp = sanitizeOtp(body?.otp);
    const otpContextToken = sanitizeContextToken(body?.otp_context_token);

    if (!otp || !otpContextToken) {
      return jsonResponse(
        { error: "Missing OTP verification payload." },
        { status: 400 },
      );
    }

    let context;
    try {
      context = await verifyOtpContextToken(otpContextToken);
    } catch (_error) {
      return jsonResponse(
        { error: "Your verification session has expired. Request a new code." },
        { status: 401 },
      );
    }

    const email = normalizeEmail(context.email);
    const verificationType = context.verification_type.trim();
    if (!email || verificationType.isEmpty) {
      return jsonResponse(
        { error: "The verification request is invalid." },
        { status: 401 },
      );
    }

    const response = await fetch(`${supabaseUrl}/auth/v1/verify`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        Authorization: `Bearer ${serviceRoleKey}`,
        apikey: serviceRoleKey,
      },
      body: JSON.stringify({
        email,
        token: otp,
        type: verificationType,
      }),
    });

    const payload = await response.json().catch(() => null) as Record<
      string,
      unknown
    > | null;
    if (!response.ok || payload == null || payload["access_token"] == null) {
      const msg = payload?.["msg"];
      const errorDescription = payload?.["error_description"];
      const errorMessage = typeof msg === "string"
        ? msg
        : typeof errorDescription === "string"
        ? errorDescription
        : "Unable to verify the code. Please try again.";
      return jsonResponse(
        { error: errorMessage },
        { status: response.status },
      );
    }

    return jsonResponse({
      session: {
        access_token: payload["access_token"],
        refresh_token: payload["refresh_token"],
        token_type: payload["token_type"],
        expires_in: payload["expires_in"],
        provider_token: payload["provider_token"],
        provider_refresh_token: payload["provider_refresh_token"],
        user: payload["user"],
      },
    });
  } catch (error) {
    console.error("Function error:", error);
    return jsonResponse({ error: "Unexpected server error" }, { status: 500 });
  }
});
