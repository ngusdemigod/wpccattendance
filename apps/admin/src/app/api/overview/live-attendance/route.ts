import * as Sentry from "@sentry/nextjs";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";
import { resolveAdminContext } from "@/lib/permissions/admin-context";

type Raw=Record<string,unknown>;
const text=(value:unknown)=>typeof value==="string"?value:value==null?"":String(value);

export async function GET(){
  return Sentry.startSpan({name:"overview.live_attendance",op:"db.query",attributes:{route:"overview",action:"live_attendance"}},async()=>{
    const client=await createClient();
    const rpcClient=client as unknown as SupabaseClient;
    const context=await resolveAdminContext(rpcClient);
    if(!context)return Response.json({error:"Administrator access required"},{status:403});

    const now=new Date().toISOString();
    let eventQuery=rpcClient.from("events").select("id,title,event_date,endtime,branch_id").eq("isactive",true).lte("event_date",now).gte("endtime",now);
    if(context.role==="admin")eventQuery=eventQuery.eq("branch_id",context.branchId);
    const {data:event,error:eventError}=await eventQuery.order("event_date",{ascending:false}).limit(1).maybeSingle();
    if(eventError){Sentry.captureException(eventError,{tags:{route:"overview",action:"live_event_read"}});return Response.json({error:"Live attendance session could not be loaded"},{status:500});}
    if(!event)return Response.json({event:null,rows:[]},{headers:{"Cache-Control":"private, no-store"}});

    const {data:attendance,error:attendanceError}=await rpcClient.from("attendance").select("id,user_id,fullname,created_at").eq("event_id",event.id).order("created_at",{ascending:false});
    if(attendanceError){Sentry.captureException(attendanceError,{tags:{route:"overview",action:"live_attendance_read"}});return Response.json({error:"Live clock-ins could not be loaded"},{status:500});}
    const rawRows=(attendance||[]) as Raw[];
    const userIds=[...new Set(rawRows.map(item=>text(item.user_id)).filter(Boolean))];
    const profileResult=userIds.length?await rpcClient.from("profiles").select("id,full_name,membership_code").in("id",userIds):{data:[],error:null};
    if(profileResult.error){Sentry.captureException(profileResult.error,{tags:{route:"overview",action:"live_profiles_read"}});return Response.json({error:"Clock-in members could not be loaded"},{status:500});}
    const profiles=new Map(((profileResult.data||[]) as Raw[]).map(profile=>[text(profile.id),profile]));
    const rows=rawRows.map(item=>{const profile=profiles.get(text(item.user_id));const fullName=text(profile?.full_name||item.fullname)||"Unknown member";return{id:text(item.id),member_code:text(profile?.membership_code)||"—",first_name:fullName.split(/\s+/)[0]||fullName,clocked_in_at:text(item.created_at)};});
    return Response.json({event:{id:text(event.id),title:text(event.title)||"Service Check-in",starts_at:text(event.event_date),ends_at:text(event.endtime)},rows},{headers:{"Cache-Control":"private, no-store"}});
  });
}
