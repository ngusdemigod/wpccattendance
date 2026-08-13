import { getRequiredEnv, getSupabaseRuntimeUrl } from "./mail.ts";

export type GeneratedAuthLink = {
  action_link: string;
  email_otp: string;
  hashed_token: string;
  redirect_to: string;
  verification_type: string;
};

type GenerateAuthLinkArgs = {
  type:
    | "magiclink"
    | "recovery"
    | "signup"
    | "invite"
    | "email_change_current"
    | "email_change_new";
  email: string;
  password?: string;
  newEmail?: string;
  redirectTo?: string;
};

export async function generateAuthLink(
  args: GenerateAuthLinkArgs,
): Promise<GeneratedAuthLink> {
  const supabaseUrl = getSupabaseRuntimeUrl();
  const serviceRoleKey =
    Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")?.trim() ||
    Deno.env.get("SERVICE_ROLE_KEY")?.trim() ||
    getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY");

  const response = await fetch(`${supabaseUrl}/auth/v1/admin/generate_link`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${serviceRoleKey}`,
      apikey: serviceRoleKey,
    },
    body: JSON.stringify({
      email: args.email,
      type: args.type,
      ...(args.password ? { password: args.password } : {}),
      ...(args.newEmail ? { new_email: args.newEmail } : {}),
      ...(args.redirectTo ? { redirect_to: args.redirectTo } : {}),
    }),
  });

  const data = await response.json().catch(() => null);
  if (!response.ok) {
    const error = new Error("Failed to generate auth link");
    (error as Error & { cause?: unknown }).cause = data;
    throw error;
  }

  return data as GeneratedAuthLink;
}

export async function getAuthenticatedUser(jwt: string) {
  const supabaseUrl = getSupabaseRuntimeUrl();
  const apiKey =
    Deno.env.get("API_KEY")?.trim() ||
    Deno.env.get("SUPABASE_ANON_KEY")?.trim() ||
    Deno.env.get("SERVICE_ROLE_KEY")?.trim() ||
    getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY");

  const response = await fetch(`${supabaseUrl}/auth/v1/user`, {
    method: "GET",
    headers: {
      Authorization: `Bearer ${jwt}`,
      apikey: apiKey,
    },
  });

  if (!response.ok) {
    return null;
  }

  return await response.json().catch(() => null);
}

export type ChurchmetricAuthContext = {
  role: "admin" | "globaladmin";
  branchId: string | null;
};

export async function getChurchmetricAuthContext(
  jwt: string,
): Promise<ChurchmetricAuthContext | null> {
  const supabaseUrl = getSupabaseRuntimeUrl();
  const apiKey =
    Deno.env.get("API_KEY")?.trim() ||
    Deno.env.get("SUPABASE_ANON_KEY")?.trim();

  if (!apiKey) return null;

  const invoke = async (name: string) => {
    const response = await fetch(`${supabaseUrl}/rest/v1/rpc/${name}`, {
      method: "POST",
      headers: {
        Authorization: `Bearer ${jwt}`,
        apikey: apiKey,
        "Content-Type": "application/json",
      },
      body: "{}",
    });
    return response.ok ? await response.json().catch(() => null) : null;
  };
  const [roleValue, branchValue] = await Promise.all([
    invoke("churchmetric_role"),
    invoke("churchmetric_branch_id"),
  ]);
  const role = typeof roleValue === "string" ? roleValue.toLowerCase() : "";
  if (role !== "admin" && role !== "globaladmin") return null;

  return {
    role,
    branchId: typeof branchValue === "string" && branchValue
      ? branchValue
      : null,
  };
}
