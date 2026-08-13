import type { SupabaseClient } from "@supabase/supabase-js";

export type AdminContext = {
  userId: string;
  role: "admin" | "globaladmin";
  branchId: string;
};

export async function resolveAdminContext(client: SupabaseClient): Promise<AdminContext | null> {
  const { data: userData, error: userError } = await client.auth.getUser();
  const userId = userData.user?.id ?? "";
  if (userError || !userId) return null;

  const { data, error } = await client.rpc("churchmetric_admin_context", {});
  if (error || !data || typeof data !== "object" || Array.isArray(data)) return null;
  const context = data as Record<string, unknown>;
  const role = typeof context.role === "string" ? context.role.toLowerCase() : "";
  if (role !== "admin" && role !== "globaladmin") return null;
  return {
    userId,
    role,
    branchId: typeof context.branch_id === "string" ? context.branch_id : "",
  };
}
