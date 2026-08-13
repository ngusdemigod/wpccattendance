"use server";

import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { resolveAdminContext } from "@/lib/permissions/admin-context";

export type LoginState = { error?: string; message?: string };
export type MemberCodeState = { error?: string; message?: string };

function adminCallbackUrl() {
  const configured = process.env.ADMIN_BASE_URL?.trim();
  if (configured) return `${configured.replace(/\/+$/, "")}/auth/confirm`;
  const vercelHost = process.env.VERCEL_PROJECT_PRODUCTION_URL?.trim();
  if (vercelHost) return `https://${vercelHost.replace(/\/+$/, "")}/auth/confirm`;
  return "http://localhost:3000/auth/confirm";
}

export async function login(_state: LoginState, formData: FormData): Promise<LoginState> {
  const email = String(formData.get("email") || "").trim().toLowerCase();
  const password = String(formData.get("password") || "");
  if (!email || !password) return { error: "Enter your email and password." };
  const supabase = await createClient();
  const { error } = await supabase.auth.signInWithPassword({ email, password });
  if (error) return { error: "The email or password is incorrect." };
  const context = await resolveAdminContext(supabase);
  if (!context) {
    await supabase.auth.signOut();
    return { error: "This account does not have administrator access." };
  }
  const { data: membership, error: membershipError } = await supabase
    .from("membershipcode")
    .select("membershipcode")
    .eq("memberid", context.userId)
    .maybeSingle();
  if (membershipError || !membership?.membershipcode) {
    await supabase.auth.signOut();
    return { error: "This administrator account does not have a membership code." };
  }
  const { error: linkError } = await supabase.functions.invoke("send-otp", {
    body: { membership_code: membership.membershipcode, redirect_to: adminCallbackUrl() },
  });
  await supabase.auth.signOut();
  if (linkError) return { error: "The sign-in link could not be sent. Please try again." };
  return { message: "Password accepted. Check your email and use the sign-in link to finish signing in." };
}

export async function requestMemberCodeLink(
  _state: MemberCodeState,
  formData: FormData,
): Promise<MemberCodeState> {
  const membershipCode = String(formData.get("membership_code") || "").trim();
  if (!/^[A-Za-z0-9_-]{3,64}$/.test(membershipCode)) {
    return { error: "Enter a valid membership code." };
  }
  const supabase = await createClient();
  const { error } = await supabase.functions.invoke("send-otp", {
    body: { membership_code: membershipCode, redirect_to: adminCallbackUrl() },
  });
  if (error) return { error: "The sign-in link could not be sent. Please try again." };
  return { message: "If this membership code is valid, a sign-in link has been sent to its email address." };
}

export async function logout() {
  const supabase = await createClient();
  await supabase.auth.signOut();
  redirect("/login");
}
