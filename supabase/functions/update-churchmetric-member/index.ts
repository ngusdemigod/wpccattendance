import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { getAuthenticatedUser, getChurchmetricAuthContext } from "../_shared/auth.ts";
import { getRequiredEnv, getSupabaseRuntimeUrl, maskEmail, normalizeEmail, sendEmailThroughTransport } from "../_shared/mail.ts";

const clean=(value:unknown,max:number)=>typeof value==="string"?value.trim().slice(0,max):"";
const digest=async(value:string)=>Array.from(new Uint8Array(await crypto.subtle.digest("SHA-256",new TextEncoder().encode(`${value}:${getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY")}`)))).map(byte=>byte.toString(16).padStart(2,"0")).join("");
const allowedFields={full_name:160,display_name:100,firstname:80,lastname:80,phone:40,bio:1000,email:254} as const;

Deno.serve(async(req:Request)=>{
  if(req.method==="OPTIONS")return new Response("ok",{headers:corsHeaders});
  if(req.method!=="POST")return jsonResponse({error:"Method not allowed"},{status:405});
  const authorization=req.headers.get("authorization")||"",jwt=authorization.startsWith("Bearer ")?authorization.slice(7).trim():"";
  const [actor,context]=await Promise.all([jwt?getAuthenticatedUser(jwt):null,jwt?getChurchmetricAuthContext(jwt):null]);
  if(!actor?.id||!actor.email||!context)return jsonResponse({error:"Administrator access required"},{status:403});
  const body=await req.json().catch(()=>null) as Record<string,unknown>|null;
  const memberId=clean(body?.member_id,36),action=clean(body?.action,24);
  if(!/^[0-9a-f-]{36}$/i.test(memberId))return jsonResponse({error:"Invalid member id"},{status:400});
  const admin=createClient(getSupabaseRuntimeUrl(),getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY"),{auth:{persistSession:false,autoRefreshToken:false}});
  const {data:member}=await admin.from("profiles").select("id,branch_id,full_name,email,phone,display_name,firstname,lastname,bio").eq("id",memberId).maybeSingle();
  if(!member||(context.role==="admin"&&member.branch_id!==context.branchId))return jsonResponse({error:"Member not found"},{status:404});
  if(actor.id===memberId&&action.includes("delete"))return jsonResponse({error:"You cannot delete your own administrator account"},{status:403});

  if(action==="request_otp"||action==="request_delete_otp"){
    if(!actor.email)return jsonResponse({error:"The signed-in administrator does not have an email address"},{status:400});
    const {data:latest}=await admin.from("member_update_verifications").select("created_at").eq("member_id",memberId).eq("actor_id",actor.id).order("created_at",{ascending:false}).limit(1).maybeSingle();
    const retryAfter=latest?Math.max(0,60-Math.floor((Date.now()-new Date(latest.created_at).valueOf())/1000)):0;
    if(retryAfter>0)return jsonResponse({error:`Wait ${retryAfter} seconds before requesting another code`,retry_after:retryAfter},{status:429,headers:{"Retry-After":String(retryAfter)}});
    const otp=String(crypto.getRandomValues(new Uint32Array(1))[0]%1000000).padStart(6,"0");
    await admin.from("member_update_verifications").update({consumed_at:new Date().toISOString()}).eq("member_id",memberId).eq("actor_id",actor.id).is("consumed_at",null);
    const {error}=await admin.from("member_update_verifications").insert({member_id:memberId,actor_id:actor.id,otp_hash:await digest(otp),expires_at:new Date(Date.now()+10*60_000).toISOString()});
    if(error)return jsonResponse({error:"Verification code could not be created"},{status:500});
    const deleting=action==="request_delete_otp";
    await sendEmailThroughTransport({to:actor.email,subject:deleting?"Authorize member deletion":"Authorize member profile update",text:`Use approval code ${otp} to ${deleting?"delete the selected member":"update the selected member profile"}. It expires in 10 minutes. This code authorizes an administrator action from your signed-in account.`,idempotencyKey:`admin-${deleting?"delete":"update"}-otp-${actor.id}-${memberId}-${Date.now()}`});
    return jsonResponse({ok:true,email_masked:maskEmail(actor.email),cooldown_seconds:60});
  }

  if(action==="execute_delete"){
    const token=clean(body?.deletion_token,128);
    const {data:authorization}=await admin.from("member_deletion_authorizations").select("id,expires_at,consumed_at").eq("member_id",memberId).eq("actor_id",actor.id).eq("token_hash",await digest(token)).maybeSingle();
    if(!authorization||authorization.consumed_at||new Date(authorization.expires_at).valueOf()<Date.now())return jsonResponse({error:"Deletion authorization is invalid or expired"},{status:401});
    await admin.from("member_deletion_authorizations").update({consumed_at:new Date().toISOString()}).eq("id",authorization.id).is("consumed_at",null);
    await admin.from("churchmetric_audit_events").insert({branch_id:member.branch_id,actor_id:actor.id,action:"member_deleted",entity_type:"profile",entity_id:memberId,metadata:{member_name:member.full_name||null}});
    const {error}=await admin.auth.admin.deleteUser(memberId);
    if(error)return jsonResponse({error:"Member could not be deleted"},{status:500});
    return jsonResponse({ok:true});
  }

  if(action!=="update"&&action!=="authorize_delete")return jsonResponse({error:"Invalid action"},{status:400});
  const method=clean(body?.verification_method,16),password=clean(body?.password,256),otp=clean(body?.otp,8);
  if(method==="password"){
    const verifier=createClient(getSupabaseRuntimeUrl(),getRequiredEnv("SUPABASE_ANON_KEY"),{auth:{persistSession:false,autoRefreshToken:false}});
    const {error}=await verifier.auth.signInWithPassword({email:actor.email,password});
    if(error)return jsonResponse({error:"Administrator password is incorrect"},{status:401});
  }else if(method==="otp"){
    const {data:verification}=await admin.from("member_update_verifications").select("id,otp_hash,expires_at,attempts").eq("member_id",memberId).eq("actor_id",actor.id).is("consumed_at",null).order("created_at",{ascending:false}).limit(1).maybeSingle();
    if(!verification||new Date(verification.expires_at).valueOf()<Date.now()||verification.attempts>=5)return jsonResponse({error:"The approval code is invalid or expired"},{status:401});
    if(verification.otp_hash!==await digest(otp)){await admin.from("member_update_verifications").update({attempts:verification.attempts+1}).eq("id",verification.id);return jsonResponse({error:"The approval code is incorrect"},{status:401});}
    await admin.from("member_update_verifications").update({consumed_at:new Date().toISOString()}).eq("id",verification.id);
  }else return jsonResponse({error:"Choose password or email approval"},{status:400});

  if(action==="authorize_delete"){
    const token=crypto.randomUUID()+crypto.randomUUID();
    await admin.from("member_deletion_authorizations").update({consumed_at:new Date().toISOString()}).eq("member_id",memberId).eq("actor_id",actor.id).is("consumed_at",null);
    const {error}=await admin.from("member_deletion_authorizations").insert({member_id:memberId,actor_id:actor.id,token_hash:await digest(token),expires_at:new Date(Date.now()+2*60_000).toISOString()});
    if(error)return jsonResponse({error:"Deletion could not be authorized"},{status:500});
    return jsonResponse({ok:true,deletion_token:token});
  }

  const incoming=(body?.changes&&typeof body.changes==="object"?body.changes:{}) as Record<string,unknown>,changes:Record<string,string|null>={},changed:string[]=[];
  for(const [field,max] of Object.entries(allowedFields)){if(!(field in incoming))continue;let value=clean(incoming[field],max);if(field==="email"){const email=normalizeEmail(value);if(!email)return jsonResponse({error:"Enter a valid email address"},{status:400});value=email;}const next=value||null;if(next!==(member[field]??null)){changes[field]=next;changed.push(field);}}
  const departmentIds=Array.isArray(body?.department_ids)?[...new Set(body.department_ids.map(value=>clean(value,36)).filter(value=>/^[0-9a-f-]{36}$/i.test(value)))]:null;
  let departmentsChanged=false;
  if(departmentIds){
    const {data:validDepartments}=departmentIds.length?await admin.from("departments").select("id").in("id",departmentIds):{data:[]};
    if((validDepartments||[]).length!==departmentIds.length)return jsonResponse({error:"One or more departments are invalid"},{status:400});
    const {data:current}=await admin.from("profile_departments").select("department_id").eq("profile_id",memberId);
    departmentsChanged=JSON.stringify((current||[]).map(item=>item.department_id).sort())!==JSON.stringify([...departmentIds].sort());
  }
  if(!changed.length&&!departmentsChanged)return jsonResponse({error:"No details were changed"},{status:400});
  if(changes.email){const {error}=await admin.auth.admin.updateUserById(memberId,{email:changes.email,email_confirm:true});if(error)return jsonResponse({error:error.message.includes("registered")?"That email is already in use":"Email could not be updated"},{status:409});}
  const {error:updateError}=await admin.from("profiles").update(changes).eq("id",memberId);if(updateError)return jsonResponse({error:"Member details could not be updated"},{status:500});
  if(departmentIds&&departmentsChanged){
    await admin.from("profile_departments").delete().eq("profile_id",memberId);
    if(departmentIds.length){const {error}=await admin.from("profile_departments").insert(departmentIds.map(department_id=>({profile_id:memberId,department_id,branch_id:member.branch_id})));if(error)return jsonResponse({error:"Department assignments could not be updated"},{status:500});}
    await admin.from("profiles").update({department_id:departmentIds[0]||null}).eq("id",memberId);
    changed.push("departments");
  }
  await admin.from("churchmetric_audit_events").insert({branch_id:member.branch_id,actor_id:actor.id,action:"member_details_updated",entity_type:"profile",entity_id:memberId,metadata:{fields:changed,verification_method:method}});
  const destination=(changes.email as string|null)||member.email,labels:Record<string,string>={full_name:"Full name",display_name:"Display name",firstname:"First name",lastname:"Last name",phone:"Phone",bio:"Biography",email:"Email",departments:"Departments"};
  if(destination)await sendEmailThroughTransport({to:destination,subject:"Your member details were updated",text:`Hello ${changes.full_name||member.full_name||"member"},\n\nA church administrator updated the following details on your profile:\n${changed.map(field=>`- ${labels[field]}`).join("\n")}\n\nIf you did not expect this change, please contact church administration.`,idempotencyKey:`member-updated-${memberId}-${Date.now()}`});
  if(changes.email&&member.email&&member.email!==changes.email)await sendEmailThroughTransport({to:member.email,subject:"Your member email address was changed",text:`Your church member profile email was changed to ${changes.email}. If you did not expect this, contact church administration immediately.`});
  return jsonResponse({ok:true,changed_fields:changed});
});
