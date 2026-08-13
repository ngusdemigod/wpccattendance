import { redirect } from "next/navigation";
import { LoginForm } from "@/features/auth/login-form";
import { createClient } from "@/lib/supabase/server";
import { resolveAdminContext } from "@/lib/permissions/admin-context";

export default async function LoginPage({ searchParams }: { searchParams: Promise<{ notice?: string; error?: string }> }) {
  if (process.env.NEXT_PUBLIC_SUPABASE_URL && process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY) {
    const supabase = await createClient();
    if (await resolveAdminContext(supabase)) redirect("/dashboard");
  }
  const params = await searchParams;
  return <LoginForm notice={params.notice} error={params.error}/>;
}
