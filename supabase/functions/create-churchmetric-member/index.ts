import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { getAuthenticatedUser, getChurchmetricAuthContext } from "../_shared/auth.ts";
import { getRequiredEnv, normalizeEmail, sendEmailThroughTransport } from "../_shared/mail.ts";

const clean=(value:unknown,max=160)=>typeof value==="string"?value.trim().slice(0,max):"";

Deno.serve(async(req:Request)=>{
  if(req.method==="OPTIONS")return new Response("ok",{headers:corsHeaders});
  if(req.method!=="POST")return jsonResponse({error:"Method not allowed"},{status:405});
  const authorization=req.headers.get("authorization")||"";const jwt=authorization.startsWith("Bearer ")?authorization.slice(7).trim():"";
  const [user,context]=await Promise.all([jwt?getAuthenticatedUser(jwt):null,jwt?getChurchmetricAuthContext(jwt):null]);
  if(!user?.id||!context)return jsonResponse({error:"Administrator access required"},{status:403});

  const body=await req.json().catch(()=>null) as Record<string,unknown>|null;
  const branchId=clean(body?.branch_id,36),fullName=clean(body?.full_name),email=normalizeEmail(body?.email),phone=clean(body?.phone,40)||null;
  const departmentIds=Array.isArray(body?.department_ids)?[...new Set(body.department_ids.map(value=>clean(value,36)).filter(value=>/^[0-9a-f-]{36}$/i.test(value)))]:[];
  if(!branchId||!fullName||!email)return jsonResponse({error:"Branch, full name, and a valid email are required"},{status:400});
  if(context.role==="admin"&&branchId!==context.branchId)return jsonResponse({error:"Cross-branch member creation is forbidden"},{status:403});

  const admin=createClient(getRequiredEnv("SUPABASE_URL"),getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY"),{auth:{persistSession:false,autoRefreshToken:false}});
  const {data:branch}=await admin.from("branches").select("id,name").eq("id",branchId).maybeSingle();
  if(!branch)return jsonResponse({error:"Branch not found"},{status:404});
  const {data:departments}=departmentIds.length?await admin.from("departments").select("id").in("id",departmentIds):{data:[]};
  if((departments||[]).length!==departmentIds.length)return jsonResponse({error:"One or more departments are invalid"},{status:400});
  const {data:allocated,error:allocationError}=await admin.rpc("generate_WPCC_member_code");
  const allocation=Array.isArray(allocated)?allocated[0]:allocated;
  if(allocationError||!allocation?.membership_code){console.error("membership_code_allocation_failed",{branch_id:branchId,code:allocationError?.code});return jsonResponse({error:"Unable to allocate membership code"},{status:500});}

  const membershipCode=String(allocation.membership_code);
  const {data:created,error:createError}=await admin.auth.admin.createUser({email,email_confirm:true,password:`${crypto.randomUUID()}Aa!7`,user_metadata:{full_name:fullName,membership_code:membershipCode,branch_id:branchId},app_metadata:{membership_code:membershipCode,branch_id:branchId,role:"member"}});
  if(createError||!created.user){return jsonResponse({error:createError?.message?.includes("registered")?"A member already uses this email":"Unable to create member account"},{status:createError?.message?.includes("registered")?409:500});}
  const userId=created.user.id;
  let creationStage="profile";
  try{
    const {error:profileError}=await admin.from("profiles").insert({id:userId,branch_id:branchId,department_id:departmentIds[0]||null,full_name:fullName,email,phone,verified:false,setup_completed:false});
    if(profileError)throw profileError;
    creationStage="membership_code";
    const {error:codeError}=await admin.from("membershipcode").insert({memberid:userId,membershipcode:membershipCode});
    if(codeError)throw codeError;
    creationStage="departments";
    if(departmentIds.length){const {error}=await admin.from("profile_departments").insert(departmentIds.map(department_id=>({profile_id:userId,department_id,branch_id:branchId})));if(error)throw error;}
    creationStage="audit";
    await admin.from("churchmetric_audit_events").insert({branch_id:branchId,actor_id:user.id,action:"member_created",entity_type:"profile",entity_id:userId,metadata:{onboarding:"membership_code_otp"}});
    let onboardingEmailSent=false;
    try{
      await sendEmailThroughTransport({to:email,subject:`Welcome to ${branch.name}`,text:`Hello ${fullName},\n\nYour church membership profile has been created.\n\nMembership code: ${membershipCode}\n\nUse this membership code to sign in and request your one-time verification code. Keep it private.\n\nWelcome to ${branch.name}.`,idempotencyKey:`member-onboarding-${userId}`});
      onboardingEmailSent=true;
    }catch(deliveryError){
      console.error("member_onboarding_delivery_failed",{user_id:userId,branch_id:branchId});
    }
    return jsonResponse({member:{id:userId,full_name:fullName,membership_code:membershipCode,display_code:String(allocation.display_code||membershipCode),branch_name:branch.name,onboarding_email_sent:onboardingEmailSent}});
  }catch(error){
    const failure=error&&typeof error==="object"?error as Record<string,unknown>:{};
    console.error("churchmetric_member_creation_failed",{user_id:userId,branch_id:branchId,stage:creationStage,code:String(failure.code||"unknown")});
    await admin.auth.admin.deleteUser(userId).catch(()=>undefined);
    return jsonResponse({error:"Member profile could not be created"},{status:500});
  }
});
