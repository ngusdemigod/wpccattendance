import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";

type Body = { event_id?: string | null; latitude?: number | string | null; longitude?: number | string | null; user_location?: { latitude?: number | string | null; longitude?: number | string | null } };
const RADIUS_M = 100;
const cors = {"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,"Content-Type":"application/json"}});
const number=(value:unknown)=>{if(typeof value==="number"&&Number.isFinite(value))return value;if(typeof value==="string"&&value.trim()){const parsed=Number(value);return Number.isFinite(parsed)?parsed:null;}return null;};
const clientIp=(req:Request)=>req.headers.get("x-forwarded-for")?.split(",")[0]?.trim()||req.headers.get("x-real-ip");
function distance(lat1:number,lon1:number,lat2:number,lon2:number){const r=6371000,toRad=(x:number)=>x*Math.PI/180,dLat=toRad(lat2-lat1),dLon=toRad(lon2-lon1),a=Math.sin(dLat/2)**2+Math.cos(toRad(lat1))*Math.cos(toRad(lat2))*Math.sin(dLon/2)**2;return r*2*Math.atan2(Math.sqrt(a),Math.sqrt(1-a));}

Deno.serve(async(req:Request)=>{
  if(req.method==="OPTIONS")return new Response(null,{status:204,headers:cors});
  if(req.method!=="POST")return json({error:"method_not_allowed"},405);
  const auth=req.headers.get("authorization")||"";
  if(!auth.toLowerCase().startsWith("bearer "))return json({error:"unauthorized"},401);
  const token=auth.replace(/^[Bb]earer\s+/,"").trim();
  const admin=createClient(Deno.env.get("SUPABASE_URL")!,Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!,{auth:{persistSession:false,autoRefreshToken:false}});
  const {data:userData}=await admin.auth.getUser(token);
  if(!userData?.user)return json({error:"unauthorized"},401);
  const userId=userData.user.id;
  const body=(await req.json().catch(()=>({}))) as Body;
  const eventId=typeof body.event_id==="string"?body.event_id.trim():"";
  const latitude=number(body.latitude??body.user_location?.latitude),longitude=number(body.longitude??body.user_location?.longitude);
  const {data:profile}=await admin.from("profiles").select("full_name,branch_id,department_id").eq("id",userId).maybeSingle();
  if(!profile)return json({ok:false,message:"Member profile not found"},404);
  const fullName=profile.full_name||"WPCC Member";
  let distanceM:number|null=null;
  const audit=async(action:string,extra:Record<string,unknown>={})=>{await admin.from("attendance_audit_logs").insert({user_id:userId,event_id:eventId||null,action,latitude,longitude,distance_m:distanceM,user_full_name:fullName,request_ip:clientIp(req),user_agent:req.headers.get("user-agent"),raw_payload:{event_id:eventId,...extra}});};
  if(!eventId||latitude===null||longitude===null||latitude < -90||latitude > 90||longitude < -180||longitude > 180){await audit("invalid_location",{error:"missing_or_invalid_data"});return json({ok:false,message:"Event ID and valid location required"},400);}

  const {data:event}=await admin.from("my_events").select("event_id,event_scope,branch_id,department_id,event_end_at,latitude,longitude").eq("event_id",eventId).maybeSingle();
  if(!event){await audit("invalid_location",{error:"event_not_found"});return json({ok:false,message:"Event not found"},404);}
  const eventLat=number(event.latitude),eventLng=number(event.longitude);
  if(eventLat===null||eventLng===null){await audit("invalid_location",{error:"event_has_no_geofence"});return json({ok:false,message:"This event does not have a check-in location"},409);}

  let allowed=false;
  if(event.event_scope==="global") allowed=true;
  else if(event.event_scope==="branch") allowed=Boolean(event.branch_id&&profile.branch_id===event.branch_id);
  else if(event.event_scope==="department"&&event.department_id&&event.branch_id){
    if(profile.branch_id===event.branch_id&&profile.department_id===event.department_id) allowed=true;
    else {const {data:membership}=await admin.from("profile_departments").select("profile_id").eq("profile_id",userId).eq("branch_id",event.branch_id).eq("department_id",event.department_id).maybeSingle();allowed=Boolean(membership);}
  }
  if(!allowed){await audit("invalid_location",{error:"event_scope_not_permitted"});return json({ok:false,message:"This event is not available to your membership scope"},403);}

  distanceM=distance(latitude,longitude,eventLat,eventLng);
  if(!Number.isFinite(distanceM)||distanceM>RADIUS_M){await audit("invalid_location",{error:"outside_geofence"});return json({ok:false,message:"You must be within the event location to clock in or clock out",distance_m:Number.isFinite(distanceM)?Math.round(distanceM):null},400);}

  const {data:existing}=await admin.from("attendance").select("id,clockout").eq("user_id",userId).eq("event_id",eventId).maybeSingle();
  const resolvedBranchId=event.branch_id??profile.branch_id??null;
  const resolvedDepartmentId=event.event_scope==="department"?event.department_id:(profile.department_id??null);
  if(!existing){
    const {error}=await admin.from("attendance").insert({user_id:userId,event_id:eventId,status:"present",latitude,longitude,branch_id:resolvedBranchId,department_id:resolvedDepartmentId,fullname:fullName});
    if(error){await audit("clock_in",{error:error.message});return json({ok:false,message:"Unable to clock in"},400);}
    await audit("clock_in");return json({ok:true,action:"clock_in",message:"You have been clocked in"});
  }
  if(existing.clockout){await audit("clock_out",{error:"already_clocked_out"});return json({ok:false,message:"You have already been clocked out"},400);}
  const end=event.event_end_at?new Date(event.event_end_at):null;
  if(!end||Date.now()<end.getTime()){await audit("clock_out",{error:"event_not_ended"});return json({ok:false,message:"You cannot clock out until the event has ended"},400);}
  const {data:closed,error:closeError}=await admin.rpc("wpcc_clock_out_attendance",{p_attendance_id:existing.id,p_latitude:latitude,p_longitude:longitude});
  if(closeError||!Array.isArray(closed)||closed.length===0){await audit("clock_out",{error:"clockout_failed"});return json({ok:false,message:"Unable to clock out"},400);}
  await audit("clock_out");return json({ok:true,action:"clock_out",message:"You have been clocked out"});
});
