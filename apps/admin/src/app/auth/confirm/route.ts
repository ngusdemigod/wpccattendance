import { NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { resolveAdminContext } from "@/lib/permissions/admin-context";

export const dynamic = "force-dynamic";

export async function GET(request: Request) {
  const url = new URL(request.url);
  const tokenHash = url.searchParams.get("token_hash")?.trim() ?? "";
  const redirect = (path: string) => {
    const response = NextResponse.redirect(new URL(path, url.origin));
    response.headers.set("Cache-Control", "private, no-store");
    return response;
  };

  if (!tokenHash || url.searchParams.get("type") !== "magiclink") {
    return redirect("/login?error=invalid_link");
  }

  const supabase = await createClient();
  const { error } = await supabase.auth.verifyOtp({ token_hash: tokenHash, type: "magiclink" });
  if (error) return redirect("/login?error=invalid_link");

  const context = await resolveAdminContext(supabase);
  if (!context) {
    await supabase.auth.signOut();
    return redirect("/login?notice=unauthorized");
  }
  return redirect("/dashboard");
}
