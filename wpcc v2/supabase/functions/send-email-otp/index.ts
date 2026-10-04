import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";
import { getEmailForMembershipCode, normalizeMembershipCode } from "../_shared/member-login.ts";
import { enforceRateLimit, getRequestIp } from "../_shared/rate-limit.ts";

import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import {
  normalizeEmail,
  sendEmailThroughTransport,
} from "../_shared/mail.ts";

function runtimeUrl() {
  return (Deno.env.get("PROJECT_URL") || Deno.env.get("SUPABASE_URL") || "")
    .replace(/\/$/, "");
}

function serviceKey() {
  return Deno.env.get("SUPABASE_SECRET_KEY") ||
    Deno.env.get("SERVICE_ROLE_KEY") ||
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY") || "";
}

const genericResponse = {
  message: "If this email belongs to an account, a verification code has been sent.",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, { status: 405 });
  }

  try {
    const body = await request.json().catch(() => ({}));
    const admin = createClient(runtimeUrl(), serviceKey(), {
      auth: { persistSession: false, autoRefreshToken: false },
    });
    const member = typeof body.membership_code === "string"
      ? normalizeMembershipCode(body.membership_code) : "";
    const verifying = body.action === "verify";
    if (body.membership_code !== undefined && !/^[A-Za-z0-9_-]{3,64}$/.test(member)) {
      return jsonResponse({ error: "Invalid membership code" }, { status: 400 });
    }
    if (verifying && (!member || typeof body.otp !== "string" || !/^\d{6}$/.test(body.otp))) {
      return jsonResponse({ error: "Invalid verification request" }, { status: 400 });
    }
    if (member) {
      for (const limit of [
        { scope: verifying ? "member_otp_verify_ip" : "member_otp_send_ip",
          identifier: getRequestIp(request), maxAttempts: 30 },
        { scope: verifying ? "member_otp_verify" : "member_otp_send",
          identifier: member.toLowerCase(), maxAttempts: verifying ? 6 : 5 },
      ]) {
        const result = await enforceRateLimit({
          supabaseAdmin: admin, ...limit, windowSeconds: 600,
        });
        if (!result.allowed) return jsonResponse(
          { error: "Too many attempts. Please try again later." },
          { status: 429, headers: { "Retry-After": String(result.retryAfterSeconds) } },
        );
      }
    }
    const email = member
      ? normalizeEmail(await getEmailForMembershipCode(admin, member))
      : normalizeEmail(body.email);
    if (!email) return verifying
      ? jsonResponse({ error: "Invalid or expired code" }, { status: 401 })
      : member ? jsonResponse(genericResponse)
      : jsonResponse({ error: "Invalid email" }, { status: 400 });

    if (verifying) {
      const { data, error } = await admin.auth.verifyOtp({
        email, token: body.otp, type: "email",
      });
      if (error || !data.session) {
        return jsonResponse({ error: "Invalid or expired code" }, { status: 401 });
      }
      return jsonResponse({ refresh_token: data.session.refresh_token },
        { headers: { "Cache-Control": "no-store" } });
    }

    if (!member) {
      const { data: profile, error } = await admin.from("profiles")
        .select("id").eq("email", email).maybeSingle();
      if (error) throw error;
      if (!profile) return jsonResponse(genericResponse);
    }
    const { data: allowed, error: rateError } = await admin.rpc(
      "request_email_login_otp",
      { p_email: email },
    );
    if (rateError) throw rateError;
    if (!allowed) {
      return jsonResponse(
        { error: "Please wait before requesting another code." },
        { status: 429 },
      );
    }

    const { data: generated, error: generationError } = await admin.auth.admin.generateLink({ type: "magiclink", email });
    if (generationError) throw generationError;
    const properties = generated.properties;
    const otp = properties.email_otp;
    if (!otp) throw new Error("Auth provider did not return an email OTP");

    await sendEmailThroughTransport({
      to: email,
      subject: "Your WPCC verification code",
      text: `Your WPCC verification code is ${otp}. It expires shortly.`,
      html: `<div style="font-family:Arial,sans-serif;color:#1f2230;line-height:1.5"><p>Use this verification code to sign in to WPCC Community:</p><p style="font-size:32px;font-weight:600;letter-spacing:8px;margin:24px 0">${otp}</p><p>This code expires shortly. If you did not request it, you can ignore this email.</p></div>`,
    });
    return jsonResponse(genericResponse);
  } catch (error) {
    console.error("send-email-otp failed", error);
    return jsonResponse({ error: "Unable to send verification code" }, { status: 500 });
  }
});
