import { createClient } from "jsr:@supabase/supabase-js@2";
import { getRequiredEnv, getSupabaseRuntimeUrl } from "./mail.ts";

type GenerateAuthLinkArgs = {
  email: string;
  redirectTo?: string;
} & ({ type: "magiclink" | "invite" | "recovery" } |
     { type: "signup"; password: string } |
     { type: "email_change_current" | "email_change_new"; newEmail: string });

export async function generateAuthLink(args: GenerateAuthLinkArgs) {
  const supabaseUrl = getSupabaseRuntimeUrl();
  const serviceRoleKey = Deno.env.get("SERVICE_ROLE_KEY")?.trim() ||
    getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY");
  const admin = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const { data, error } = await admin.auth.admin.generateLink({
    ...args,
    options: args.redirectTo ? { redirectTo: args.redirectTo } : undefined,
  });

  if (error) throw error;

  return data.properties;
}

export async function getAuthenticatedUser(jwt: string) {
  const supabaseUrl = getSupabaseRuntimeUrl();
  const apiKey = Deno.env.get("API_KEY")?.trim() || Deno.env.get("SUPABASE_ANON_KEY")?.trim() || Deno.env.get("SERVICE_ROLE_KEY")?.trim() || getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY");
  const response = await fetch(`${supabaseUrl}/auth/v1/user`, {
    method: "GET",
    headers: { Authorization: `Bearer ${jwt}`, apikey: apiKey },
  });
  if (!response.ok) return null;
  return await response.json().catch(() => null);
}
