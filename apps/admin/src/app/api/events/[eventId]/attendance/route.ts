import * as Sentry from "@sentry/nextjs";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";
import { resolveAdminContext } from "@/lib/permissions/admin-context";

const uuid=/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;

export async function GET(request:Request,{params}:{params:Promise<{eventId:string}>}){
  const {eventId}=await params;
  if(!uuid.test(eventId))return Response.json({error:"Invalid event id"},{status:400});
  const url=new URL(request.url);const q=(url.searchParams.get("q")||"").trim().slice(0,100);const page=Math.max(1,Number.parseInt(url.searchParams.get("page")||"1",10)||1);
  return Sentry.startSpan({name:"events.attendance",op:"db.query",attributes:{route:"events",action:"attendance_read",record_id:eventId,page}},async()=>{
    const client=await createClient();const rpcClient=client as unknown as SupabaseClient;const context=await resolveAdminContext(rpcClient);
    if(!context)return Response.json({error:"Administrator access required"},{status:403});
    const {data,error}=await rpcClient.rpc("churchmetric_event_attendance_v1",{p_event_id:eventId,p_search:q,p_page:page,p_page_size:50});
    if(error){if(error.code==="P0002")return Response.json({error:"Event not found"},{status:404});Sentry.captureException(error,{tags:{route:"events",action:"attendance_read",record_id:eventId}});return Response.json({error:"Attendance register could not be loaded"},{status:500});}
    const payload=data&&typeof data==="object"?data:{};const rowCount=Array.isArray((payload as {rows?:unknown[]}).rows)?(payload as {rows:unknown[]}).rows.length:0;Sentry.setTag("row_count",rowCount);
    return Response.json(payload,{headers:{"Cache-Control":"private, no-store"}});
  });
}
