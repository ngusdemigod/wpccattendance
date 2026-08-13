import * as Sentry from "@sentry/nextjs";
import type { SupabaseClient } from "@supabase/supabase-js";
import { NextRequest, NextResponse } from "next/server";
import { createClient } from "@/lib/supabase/server";
import { resolveAdminContext } from "@/lib/permissions/admin-context";

type Raw=Record<string,unknown>;
const cell=(value:unknown)=>`"${String(value??"").replaceAll('"','""')}"`;

export async function GET(request:NextRequest,{params}:{params:Promise<{courseId:string}>}){
  const {courseId}=await params,sessionId=request.nextUrl.searchParams.get("session")||"";
  if(!sessionId)return NextResponse.json({error:"Select a session before exporting."},{status:400});
  return Sentry.startSpan({name:"academy.session_students.export",op:"db.rpc",attributes:{route:"academy/classes",record_id:courseId,session_id:sessionId}},async()=>{
    try{
      const client=await createClient(),context=await resolveAdminContext(client as unknown as SupabaseClient);
      if(!context)return NextResponse.json({error:"Administrator access is required."},{status:403});
      const {data,error}=await (client as unknown as SupabaseClient).rpc("churchmetric_academy_class_detail_v1",{p_course_id:courseId,p_session_id:sessionId});
      if(error)throw error;
      const payload=(data&&typeof data==="object"?data:{})as Raw,course=(payload.course&&typeof payload.course==="object"?payload.course:{})as Raw,sessions=Array.isArray(payload.sessions)?payload.sessions as Raw[]:[],students=Array.isArray(payload.students)?payload.students as Raw[]:[],session=sessions.find(item=>String(item.id)===sessionId);
      if(!session)return NextResponse.json({error:"The selected session does not belong to this class."},{status:400});
      const headings=["Course","Session","Member code","Name","Email","Department","Progress","Status"],rows=students.map(student=>[course.title,session.title,student.membership_code,student.name,student.email,student.department,`${student.progress??0}%`,String(student.status||"").replaceAll("_"," ")]);
      const csv=[headings,...rows].map(row=>row.map(cell).join(",")).join("\r\n");
      return new NextResponse(`\uFEFF${csv}`,{headers:{"Content-Type":"text/csv; charset=utf-8","Content-Disposition":`attachment; filename="academy-session-${sessionId}.csv"`,"Cache-Control":"private, no-store"}});
    }catch(error){Sentry.captureException(error,{tags:{route:"academy/classes",action:"session_export",record_id:courseId}});return NextResponse.json({error:"The authorised session export could not be generated."},{status:500});}
  });
}
