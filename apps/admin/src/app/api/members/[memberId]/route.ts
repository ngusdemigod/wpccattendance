import * as Sentry from "@sentry/nextjs";
import type { SupabaseClient } from "@supabase/supabase-js";
import { createClient } from "@/lib/supabase/server";
import { resolveAdminContext } from "@/lib/permissions/admin-context";

type Raw=Record<string,unknown>;
const text=(value:unknown)=>typeof value==="string"?value:value==null?"":String(value);
const date=(value:unknown)=>{const parsed=typeof value==="string"?new Date(value):null;return parsed&&!Number.isNaN(parsed.valueOf())?new Intl.DateTimeFormat("en-NG",{day:"2-digit",month:"short",year:"numeric"}).format(parsed):"—";};
const row=(value:Raw,fallback:string)=>({id:text(value.id),primary:text(value.full_name||value.title||value.name||fallback),secondary:text(value.email||value.category||""),status:text(value.status||"Active"),meta:date(value.created_at||value.won_at||value.completed_at),details:Object.fromEntries(Object.entries(value).filter(([,entry])=>["string","number","boolean"].includes(typeof entry)).map(([key,entry])=>[key,text(entry)]))});

export async function GET(_:Request,{params}:{params:Promise<{memberId:string}>}){
  const {memberId}=await params;if(!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(memberId))return Response.json({error:"Invalid member id"},{status:400});
  return Sentry.startSpan({name:"members.profile",op:"db.query",attributes:{route:"members",action:"profile_open",record_id:memberId}},async()=>{
    const client=await createClient();const rpcClient=client as unknown as SupabaseClient;const context=await resolveAdminContext(rpcClient);if(!context)return Response.json({error:"Administrator access required"},{status:403});
    const {data:profile,error:profileError}=await rpcClient.from("profiles").select("id,full_name,email,phone,membership_code,department_id,branch_id,created_at,date_joined,display_name,firstname,lastname,bio,last_login_at").eq("id",memberId).maybeSingle();
    if(profileError){Sentry.captureException(profileError,{tags:{route:"members",action:"profile_read"}});return Response.json({error:"Member profile could not be loaded"},{status:500});}if(!profile)return Response.json({error:"Member not found"},{status:404});
    const [attendanceResult,eventResult,soulsResult,enrolmentResult,assigneeResult,departmentResult]=await Promise.all([
      rpcClient.from("attendance").select("id,event_id,status,created_at").eq("user_id",memberId),
      rpcClient.from("events_attendance_view").select("event_id").eq("event_branch_id",profile.branch_id),
      rpcClient.from("souls").select("id,full_name,email,status,won_at,created_at").eq("recorded_by",memberId),
      rpcClient.from("course_enrollments").select("id,course_id,status,completed,progress_percent,created_at,completed_at").eq("user_id",memberId),
      rpcClient.from("quality_query_assignees").select("id,query_id,responded_at,created_at").eq("assignee_id",memberId),
      rpcClient.from("profile_departments").select("department_id,departments(id,name,description,created_at)").eq("profile_id",memberId),
    ]);
    const firstError=[attendanceResult,eventResult,soulsResult,enrolmentResult,assigneeResult,departmentResult].find(result=>result.error)?.error;if(firstError){Sentry.captureException(firstError,{tags:{route:"members",action:"profile_relations"}});return Response.json({error:"Member profile details could not be loaded"},{status:500});}
    const enrolments=(enrolmentResult.data||[]) as Raw[],courseIds=enrolments.map(item=>text(item.course_id)).filter(Boolean);const courseResult=courseIds.length?await rpcClient.from("courses").select("id,title,code").in("id",courseIds):{data:[],error:null};if(courseResult.error){Sentry.captureException(courseResult.error,{tags:{route:"members",action:"profile_classes"}});return Response.json({error:"Member classes could not be loaded"},{status:500});}
    const courses=new Map(((courseResult.data||[]) as Raw[]).map(item=>[text(item.id),item]));const attendance=(attendanceResult.data||[]) as Raw[],events=(eventResult.data||[]) as Raw[],souls=(soulsResult.data||[]) as Raw[],assignees=(assigneeResult.data||[]) as Raw[];const attended=new Set(attendance.filter(item=>["confirmed","present"].includes(text(item.status).toLowerCase())).map(item=>text(item.event_id))).size;
    const confirmedAttendance=attendance.filter(item=>["confirmed","present"].includes(text(item.status).toLowerCase()));const lastClockIn=confirmedAttendance.reduce<string>((latest,item)=>{const value=text(item.created_at);return !latest||value>latest?value:latest;},"");const activityAt=[text(profile.last_login_at),lastClockIn].filter(Boolean).sort().at(-1);const isActive=Boolean(activityAt&&new Date(activityAt).valueOf()>=Date.now()-30*24*60*60*1000);
    const departments=((departmentResult.data||[]) as unknown as Array<{department_id:string;departments:Raw|Raw[]|null}>).flatMap(item=>{const related=Array.isArray(item.departments)?item.departments:item.departments?[item.departments]:[];return related.map(department=>row({...department,id:item.department_id} as Raw,"Department"));});
    const member={...row({...profile,status:isActive?"active":"inactive",last_clock_in_at:lastClockIn,last_seen_at:activityAt||""} as Raw,"Member"),metrics:[String(assignees.length),String(Math.max(0,events.length-attended)),events.length?`${Math.round(attended/events.length*100)}%`:"0%",String(souls.length),String(enrolments.filter(item=>item.completed===true||text(item.status)==="completed").length)],sections:{"Personal details":[row({...profile,status:isActive?"active":"inactive",last_clock_in_at:lastClockIn,last_seen_at:activityAt||"",department_ids:departments.map(item=>item.id).join(","),department_name:departments.map(item=>item.primary).join(", ")} as Raw,"Member")],Departments:departments,Souls:souls.map(item=>row(item,"Soul")),Classes:enrolments.map(item=>row({...item,title:courses.get(text(item.course_id))?.title||"Class",category:courses.get(text(item.course_id))?.code||""},"Class"))}};
    return Response.json({member},{headers:{"Cache-Control":"private, no-store"}});
  });
}

export async function POST(request:Request,{params}:{params:Promise<{memberId:string}>}){
  const {memberId}=await params;
  if(!/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i.test(memberId))return Response.json({error:"Invalid member id"},{status:400});
  const client=await createClient();const rpcClient=client as unknown as SupabaseClient;
  if(!await resolveAdminContext(rpcClient))return Response.json({error:"Administrator access required"},{status:403});
  const body=await request.json().catch(()=>null);
  if(!body||typeof body!=="object")return Response.json({error:"Invalid request"},{status:400});
  const {data,error}=await rpcClient.functions.invoke("update-churchmetric-member",{body:{...body,member_id:memberId}});
  if(error){const context=await error.context?.json?.().catch(()=>null);return Response.json({error:context?.error||"The member request could not be completed"},{status:error.context?.status||500});}
  return Response.json(data,{headers:{"Cache-Control":"private, no-store"}});
}
