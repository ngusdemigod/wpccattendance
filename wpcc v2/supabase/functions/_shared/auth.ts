import { getRequiredEnv, getSupabaseRuntimeUrl } from "./mail.ts";
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
