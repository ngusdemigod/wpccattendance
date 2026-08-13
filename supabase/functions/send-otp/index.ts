import { createClient } from "jsr:@supabase/supabase-js@2";

import { generateAuthLink } from "../_shared/auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import {
  maskEmail,
  normalizeEmail,
  sendEmailThroughTransport,
} from "../_shared/mail.ts";
import { enforceRateLimit, getRequestIp } from "../_shared/rate-limit.ts";

const COOLDOWN_SECONDS = 15;
const OTP_IP_RATE_LIMIT_WINDOW_SECONDS = 15 * 60;
const OTP_IP_RATE_LIMIT_MAX_ATTEMPTS = 30;
const OTP_MEMBERSHIP_RATE_LIMIT_WINDOW_SECONDS = 10 * 60;
const OTP_MEMBERSHIP_RATE_LIMIT_MAX_ATTEMPTS = 12;

function sanitizeMembershipCode(input: unknown): string | null {
  if (typeof input !== "string") return null;
  const trimmed = input.trim();
  if (trimmed.length < 3 || trimmed.length > 64) return null;

  if (!/^[A-Za-z0-9_-]+$/.test(trimmed)) return null;
  return trimmed;
}

async function getEmailForMembershipCode(
  supabaseAdmin: ReturnType<typeof createClient>,
  membershipCode: string,
) {
  const canonicalMembershipCode = membershipCode.trim();

  const { data: membershipRow, error: membershipError } = await supabaseAdmin
    .from("membershipcode")
    .select("memberid")
    .eq("membershipcode", canonicalMembershipCode)
    .maybeSingle();

  if (membershipError) throw membershipError;

  const memberId = membershipRow?.memberid?.toString().trim() ?? "";
  if (memberId.length > 0) {
    const { data: profileById, error: profileByIdError } = await supabaseAdmin
      .from("profiles_priv_info")
      .select("email")
      .eq("id", memberId)
      .maybeSingle();

    if (profileByIdError) throw profileByIdError;

    const emailById = profileById?.email?.toString().trim() ?? "";
    if (emailById.length > 0) {
      return emailById;
    }

    const { data: publicProfileById, error: publicProfileByIdError } =
      await supabaseAdmin
        .from("profiles")
        .select("email")
        .eq("id", memberId)
        .maybeSingle();

    if (publicProfileByIdError) throw publicProfileByIdError;

    const publicEmailById =
      publicProfileById?.email?.toString().trim() ?? "";
    if (publicEmailById.length > 0) {
      return publicEmailById;
    }
  }

  const { data, error } = await supabaseAdmin
    .from("profiles_priv_info")
    .select("email")
    .eq("membership_code", canonicalMembershipCode)
    .maybeSingle();

  if (error) throw error;

  const privateEmail = data?.email?.toString().trim() ?? "";
  if (privateEmail.length > 0) {
    return privateEmail;
  }

  const { data: publicProfile, error: publicProfileError } = await supabaseAdmin
    .from("profiles")
    .select("email")
    .eq("membership_code", canonicalMembershipCode)
    .maybeSingle();

  if (publicProfileError) throw publicProfileError;

  return publicProfile?.email?.toString().trim() ?? null;
}

async function checkCooldownViaTable(
  supabaseAdmin: ReturnType<typeof createClient>,
  membershipCode: string,
) {
  const { data: row, error: readError } = await supabaseAdmin
    .from("otp_cooldowns")
    .select("last_sent_at")
    .eq("membership_code", membershipCode)
    .maybeSingle();

  if (readError) throw readError;

  const nowMs = Date.now();
  const last = row?.last_sent_at ? new Date(row.last_sent_at).getTime() : null;

  if (last !== null) {
    const nextAllowedMs = last + COOLDOWN_SECONDS * 1000;
    if (nowMs < nextAllowedMs) {
      const retryAfterSeconds = Math.ceil((nextAllowedMs - nowMs) / 1000);
      return { allowed: false as const, retryAfterSeconds };
    }
  }

  return { allowed: true as const };
}

async function markCooldownSent(
  supabaseAdmin: ReturnType<typeof createClient>,
  membershipCode: string,
) {
  const { error: upsertError } = await supabaseAdmin
    .from("otp_cooldowns")
    .upsert(
      {
        membership_code: membershipCode,
        last_sent_at: new Date().toISOString(),
      },
      { onConflict: "membership_code" },
    );

  if (upsertError) {
    throw upsertError;
  }
}

function genericSuccessResponse(args?: {
  email?: string;
}) {
  return jsonResponse(
    {
      message: "If the membership code is valid, a sign in link has been sent.",
      ...(args?.email
        ? {
            email_masked: maskEmail(args.email),
          }
        : {}),
    },
    { status: 200 },
  );
}

function buildMagicLinkEmailHtml(actionLink: string) {
  return `
    <div style="font-family: Arial, sans-serif; color: #111827; line-height: 1.5;">
      <h2 style="margin-bottom: 12px;">Your WPCC sign in link</h2>
      <p>Use the button below to continue signing in.</p>
      <p style="margin: 24px 0;">
        <a
          href="${actionLink}"
          style="display: inline-block; padding: 12px 20px; border-radius: 999px; background: #111827; color: #ffffff; text-decoration: none; font-weight: 700;"
        >
          Sign in to WPCC
        </a>
      </p>
      <p>If the button does not open, copy and paste this link into your browser:</p>
      <p style="word-break: break-all;">${actionLink}</p>
      <p>If you did not request this sign in link, you can ignore this email.</p>
    </div>
  `;
}

function buildMagicLinkEmailText(actionLink: string) {
  return [
    "Your WPCC sign in link is ready.",
    `Open this link to continue signing in: ${actionLink}`,
    "If you did not request this sign in link, you can ignore this email.",
  ].join(" ");
}

function buildAppMagicLink(args: {
  appRedirectTo?: string;
  fallbackRedirectTo?: string;
  tokenHash?: string;
  type?: string;
}) {
  const redirectTo =
    args.appRedirectTo?.trim() || args.fallbackRedirectTo?.trim() || "";
  const tokenHash = args.tokenHash?.trim() ?? "";
  const type = args.type?.trim() ?? "magiclink";

  if (!redirectTo || !tokenHash) {
    return null;
  }

  const url = new URL(redirectTo);
  url.searchParams.set("token_hash", tokenHash);
  url.searchParams.set("type", type);
  return url.toString();
}

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

function buildMagicLinkRedirectTo(requestedRedirect?: unknown) {
  const configuredBaseUrl =
    Deno.env.get("DASHBOARD_BASE_URL")?.trim() ||
    Deno.env.get("OTP_REDIRECT_TO")?.trim() ||
    Deno.env.get("SITE_URL")?.trim();

  const normalizedBaseUrl = configuredBaseUrl?.replace(/\/+$/, "");
  const defaultRedirect = !normalizedBaseUrl
    ? undefined
    : normalizedBaseUrl.endsWith("/login")
      ? normalizedBaseUrl
      : `${normalizedBaseUrl}/login`;

  if (typeof requestedRedirect !== "string" || !requestedRedirect.trim()) {
    return defaultRedirect;
  }

  const adminBaseUrl = Deno.env.get("ADMIN_BASE_URL")?.trim().replace(/\/+$/, "");
  const allowedAdminRedirect = adminBaseUrl ? `${adminBaseUrl}/auth/confirm` : "";
  return requestedRedirect.trim() === allowedAdminRedirect
    ? allowedAdminRedirect
    : defaultRedirect;
}

function extractAuthLinkErrorMessage(error: unknown): string {
  if (error instanceof Error) {
    const cause = (error as Error & { cause?: unknown }).cause;
    if (cause && typeof cause === "object") {
      const record = cause as Record<string, unknown>;
      const messageCandidates = [
        record["msg"],
        record["message"],
        record["error_description"],
        record["error"],
      ];
      for (const candidate of messageCandidates) {
        if (typeof candidate === "string" && candidate.trim().length > 0) {
          return candidate.trim();
        }
      }
    }
    if (error.message.trim().length > 0) {
      return error.message.trim();
    }
  }

  return "";
}

function isMissingAuthUserError(error: unknown) {
  const message = extractAuthLinkErrorMessage(error);
  return /user.*not found|email.*not found|no user|not registered/i.test(
    message,
  );
}

async function generateMagicLinkForEmail(email: string, redirectTo?: string) {
  return await generateAuthLink({ type: "magiclink", email, redirectTo });
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

    const body = await req.json().catch(() => null);
    const membership_code = sanitizeMembershipCode(body?.membership_code);
    const redirectTo = buildMagicLinkRedirectTo(body?.redirect_to);

    if (!membership_code) {
      return jsonResponse({ error: "Invalid membership_code" }, { status: 400 });
    }

    const supabaseAdmin = createClient(supabaseUrl, serviceRoleKey);
    const ipRateLimit = await enforceRateLimit({
      supabaseAdmin,
      scope: "otp_ip",
      identifier: getRequestIp(req),
      maxAttempts: OTP_IP_RATE_LIMIT_MAX_ATTEMPTS,
      windowSeconds: OTP_IP_RATE_LIMIT_WINDOW_SECONDS,
    });

    if (!ipRateLimit.allowed) {
      return jsonResponse(
        {
          error: `Too many sign in link requests. Retry after ${ipRateLimit.retryAfterSeconds} seconds.`,
        },
        {
          status: 429,
          headers: { "Retry-After": String(ipRateLimit.retryAfterSeconds) },
        },
      );
    }

    const membershipRateLimit = await enforceRateLimit({
      supabaseAdmin,
      scope: "otp_membership_lookup",
      identifier: membership_code.toLowerCase(),
      maxAttempts: OTP_MEMBERSHIP_RATE_LIMIT_MAX_ATTEMPTS,
      windowSeconds: OTP_MEMBERSHIP_RATE_LIMIT_WINDOW_SECONDS,
    });

    if (!membershipRateLimit.allowed) {
      return jsonResponse(
        {
          error:
            `Too many sign in link requests for this member code. Retry after ${membershipRateLimit.retryAfterSeconds} seconds.`,
        },
        {
          status: 429,
          headers: { "Retry-After": String(membershipRateLimit.retryAfterSeconds) },
        },
      );
    }

    const email = normalizeEmail(
      await getEmailForMembershipCode(supabaseAdmin, membership_code),
    );
    if (!email) {
      return genericSuccessResponse();
    }

    const cooldown = await checkCooldownViaTable(supabaseAdmin, membership_code);
    if (!cooldown.allowed) {
      return jsonResponse(
        {
          error: `Please wait before requesting another sign in link. Retry after ${cooldown.retryAfterSeconds} seconds.`,
        },
        {
          status: 429,
          headers: { "Retry-After": String(cooldown.retryAfterSeconds) },
        },
      );
    }

    if (
      !Deno.env.get("RESEND_API_KEY")?.trim() ||
      !Deno.env.get("RESEND_FROM_EMAIL")?.trim()
    ) {
      console.error("Resend transport is not configured.");
      return jsonResponse({ error: "Email service not configured" }, { status: 500 });
    }

    let generatedLink;
    try {
      generatedLink = await generateMagicLinkForEmail(
        email,
        redirectTo,
      );
    } catch (error) {
      if (isMissingAuthUserError(error)) {
        console.warn("Magic link skipped because auth user was not found.");
        return genericSuccessResponse();
      }

      console.error("Magic link generation failed:", error);
      return jsonResponse(
        { error: "Unable to prepare the sign in link." },
        { status: 500 },
      );
    }

    const appMagicLink = buildAppMagicLink({
      appRedirectTo: redirectTo,
      fallbackRedirectTo: generatedLink.redirect_to,
      tokenHash: generatedLink.hashed_token,
      type: generatedLink.verification_type,
    });

    if (!appMagicLink) {
      console.error("Magic link generation failed: missing app callback data");
      return jsonResponse(
        { error: "Failed to generate sign in link" },
        { status: 500 },
      );
    }

    await sendEmailThroughTransport({
      to: email,
      subject: "Your WPCC sign in link",
      html: buildMagicLinkEmailHtml(appMagicLink),
      text: buildMagicLinkEmailText(appMagicLink),
    });

    await markCooldownSent(supabaseAdmin, membership_code).catch((error) => {
      console.warn("Failed to update sign in link cooldown after send:", error);
    });

    return genericSuccessResponse({
      email,
    });
  } catch (e) {
    console.error("Function error:", e);
    return jsonResponse({ error: "Unexpected server error" }, { status: 500 });
  }
});
