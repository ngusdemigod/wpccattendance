import * as Sentry from "@sentry/nextjs";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";
import { resolveAdminContext } from "@/lib/permissions/admin-context";

type MemberRow={id:string;full_name:string;email:string|null;phone:string|null;membership_code:string|null;department_id:string|null;verified:boolean|null;created_at:string|null;date_joined:string|null};
const csv=(value:unknown)=>`"${String(value??"").replaceAll('"','""')}"`;
const safeSearch=(value:string)=>value.trim().replace(/[%_(),]/g," ").slice(0,100);
const date=(value:string|null)=>value&&!Number.isNaN(new Date(value).valueOf())?new Intl.DateTimeFormat("en-NG",{day:"2-digit",month:"short",year:"numeric"}).format(new Date(value)):"";

export async function GET(request:Request){
  return Sentry.startSpan({name:"members.export",op:"db.query",attributes:{route:"members",action:"csv_export"}},async span=>{
    const client=await createClient();const context=await resolveAdminContext(client as unknown as SupabaseClient);
    if(!context)return new Response("Administrator access required",{status:403});
    const url=new URL(request.url),needle=safeSearch(url.searchParams.get("q")||""),status=url.searchParams.get("status")||"",branch=url.searchParams.get("branch")||"";
    if(branch&&context.role==="admin"&&branch!==context.branchId)return new Response("Cross-branch export is forbidden",{status:403});
    const rows:MemberRow[]=[];const pageSize=1000;
    for(let offset=0;offset<50000;offset+=pageSize){
      let query=(client as unknown as SupabaseClient).from("profiles").select("id,full_name,email,phone,membership_code,department_id,verified,created_at,date_joined").order("full_name").range(offset,offset+pageSize-1);
      if(needle)query=query.or(`full_name.ilike.%${needle}%,email.ilike.%${needle}%,phone.ilike.%${needle}%,membership_code.ilike.%${needle}%`);
      if(status==="active")query=query.eq("verified",true);if(status==="inactive")query=query.eq("verified",false);if(branch)query=query.eq("branch_id",branch);
      const {data,error}=await query;if(error){Sentry.captureException(error,{tags:{route:"members",action:"csv_export"}});return new Response("Export could not be generated",{status:500});}
      const batch=(data||[]) as unknown as MemberRow[];rows.push(...batch);if(batch.length<pageSize)break;
    }
    const {data:departmentData,error:departmentError}=await (client as unknown as SupabaseClient).from("departments").select("id,name");
    if(departmentError){Sentry.captureException(departmentError,{tags:{route:"members",action:"csv_export_departments"}});return new Response("Export could not be generated",{status:500});}
    const departments=new Map((departmentData||[]).map(item=>[String(item.id),String(item.name)]));span.setAttribute("row_count",rows.length);span.setAttribute("filtered",Boolean(needle||status||branch));
    const content=["Membership code,Name,Email,Phone,Department,Joined,Status",...rows.map(member=>[member.membership_code,member.full_name,member.email,member.phone,departments.get(member.department_id||"")||"Unassigned",date(member.date_joined||member.created_at),member.verified?"Active":"Inactive"].map(csv).join(","))].join("\r\n");
    return new Response(`\uFEFF${content}`,{headers:{"Content-Type":"text/csv; charset=utf-8","Content-Disposition":'attachment; filename="members-export.csv"',"Cache-Control":"private, no-store","X-Content-Type-Options":"nosniff"}});
  });
}
