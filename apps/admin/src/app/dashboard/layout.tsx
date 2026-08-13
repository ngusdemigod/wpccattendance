import { DashboardShell } from "@/features/dashboard/dashboard-shell";
import { createClient } from "@/lib/supabase/server";
import { redirect } from "next/navigation";
import { resolveAdminContext } from "@/lib/permissions/admin-context";

export default async function DashboardLayout({ children }: { children: React.ReactNode }) {
  if (!process.env.NEXT_PUBLIC_SUPABASE_URL || !process.env.NEXT_PUBLIC_SUPABASE_PUBLISHABLE_KEY) redirect("/login");
  const supabase = await createClient();
  const context = await resolveAdminContext(supabase);
  if (!context) redirect("/auth/unauthorized");
  const { data: userData } = await supabase.auth.getUser();
  const email = userData.user?.email;
  const userLabel = email?.split("@")[0] || (context.role === "globaladmin" ? "Global administrator" : "Administrator");
  const { data: branch } = context.branchId
    ? await supabase.from("branches").select("name").eq("id", context.branchId).maybeSingle()
    : { data: null };
  const branchName = branch?.name || (context.role === "globaladmin" ? "All branches" : "Branch unavailable");
  const monthStart=new Date();monthStart.setUTCDate(1);monthStart.setUTCHours(0,0,0,0);
  const counts=await Promise.all([
    supabase.from("profiles").select("id",{count:"exact",head:true}).gte("created_at",monthStart.toISOString()),
    supabase.from("enquiries").select("id",{count:"exact",head:true}).in("status",["open","awaiting_response"]),
    supabase.from("quality_reports").select("id",{count:"exact",head:true}).in("status",["open","submitted","in_review"]),
    supabase.from("quality_queries").select("id",{count:"exact",head:true}).in("status",["open","awaiting_response","overdue"]),
    supabase.from("quality_issues").select("id",{count:"exact",head:true}).in("status",["open","reported","in_progress"]),
  ]);
  const paths=["/dashboard/members","/dashboard/enquiries","/dashboard/quality-control/reports","/dashboard/quality-control/queries","/dashboard/quality-control/issues"];
  const badges=Object.fromEntries(paths.map((path,index)=>[path,counts[index].count||0]).filter(([,count])=>Number(count)>0));
  return <DashboardShell userLabel={userLabel} branchName={branchName} badges={badges}>{children}</DashboardShell>;
}
