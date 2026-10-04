import { createClient } from "jsr:@supabase/supabase-js@2";

const cors = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};
const json = (body: unknown, status = 200) => new Response(JSON.stringify(body), {status, headers:{...cors,"Content-Type":"application/json"}});
const env = (name:string) => { const value=Deno.env.get(name)?.trim(); if(!value) throw new Error(`Missing ${name}`); return value; };
const serviceKey = () => Deno.env.get("SUPABASE_SECRET_KEY")?.trim() || Deno.env.get("SERVICE_ROLE_KEY")?.trim() || env("SUPABASE_SERVICE_ROLE_KEY");

Deno.serve(async (req) => {
  if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
  if(req.method!=="POST") return json({error:"Method not allowed"},405);
  try {
    const auth=req.headers.get("authorization")||"";
    const token=auth.toLowerCase().startsWith("bearer ")?auth.slice(7).trim():"";
    if(!token) return json({error:"Authentication required"},401);
    const admin=createClient(env("SUPABASE_URL"),serviceKey(),{auth:{persistSession:false,autoRefreshToken:false}});
    const {data:userData,error:userError}=await admin.auth.getUser(token);
    if(userError||!userData.user) return json({error:"Authentication required"},401);
    const payload=await req.json().catch(()=>null) as {amount_kobo?:number;giving_type?:string;project_id?:string|null;app_origin?:string;auto_give?:{rule_keys?:unknown;timezone?:unknown;local_charge_time?:unknown;event_labels?:unknown}}|null;
    const amount=Math.trunc(Number(payload?.amount_kobo||0));
    const type=String(payload?.giving_type||"").trim();
    const projectId=payload?.project_id||null;
    if(!Number.isSafeInteger(amount)||amount<100) return json({error:"Enter a valid amount"},400);
    if(!["offering","tithe","prophet_offering","project","auto_give"].includes(type)) return json({error:"Invalid giving type"},400);
    let autoGive:Record<string,unknown>|null=null;
    if(payload?.auto_give){
      const ruleKeys=Array.isArray(payload.auto_give.rule_keys)?payload.auto_give.rule_keys.map(String):[];
      const validRule=/^(weekday:[1-7](?::[0-9a-f-]{36})?|monthly:(?:[1-9]|[12][0-9]|3[01])(?::[0-9a-f-]{36})?|yearly:(?:[1-9]|1[0-2]):(?:[1-9]|[12][0-9]|3[01])(?::[0-9a-f-]{36})?|event:\d{4}-\d{2}-\d{2}:[0-9a-f-]{36})$/i;
      const localTime=String(payload.auto_give.local_charge_time||"");
      if(ruleKeys.length===0||ruleKeys.length>50||ruleKeys.some((key)=>!validRule.test(key))) return json({error:"Choose valid Auto Give days or services"},400);
      if(!/^([01]\d|2[0-3]):[0-5]\d:[0-5]\d$/.test(localTime)) return json({error:"Choose a valid Auto Give time"},400);
      autoGive={rule_keys:ruleKeys,timezone:"Africa/Lagos",local_charge_time:localTime,event_labels:payload.auto_give.event_labels||{}};
    }

    const [{data:priv},{data:profile}]=await Promise.all([
      admin.from("profiles_priv_info").select("email").eq("id",userData.user.id).maybeSingle(),
      admin.from("profiles").select("email").eq("id",userData.user.id).maybeSingle(),
    ]);
    const email=String(priv?.email||profile?.email||userData.user.email||"").trim().toLowerCase();
    if(!email) return json({error:"Your WPCC profile has no payment email"},409);

    const reference=`WPCC-${crypto.randomUUID()}`;
    const internalReference=`GIVE-${crypto.randomUUID()}`;
    const {data:transaction,error:txError}=await admin.rpc("wpcc_initialize_giving_transaction",{
      p_profile_id:userData.user.id,p_giving_type:type,p_project_id:projectId,p_amount_kobo:amount,
      p_internal_reference:internalReference,p_paystack_reference:reference,
    });
    if(txError) return json({error:txError.message},400);
    if(autoGive){
      const {error:autoError}=await admin.from("giving_transactions").update({pending_auto_give:autoGive,updated_at:new Date().toISOString()}).eq("id",transaction.id);
      if(autoError) return json({error:"Unable to save Auto Give schedule"},500);
    }

    const configuredOrigin=(Deno.env.get("WPCC_APP_ORIGIN")||"").trim().replace(/\/$/,"");
    const requestedOrigin=String(payload?.app_origin||"").trim().replace(/\/$/,"");
    let appOrigin=configuredOrigin;
    if(requestedOrigin){
      const candidate=new URL(requestedOrigin);
      const local=["localhost","127.0.0.1","::1"].includes(candidate.hostname);
      const configuredMatch=Boolean(configuredOrigin)&&candidate.origin===new URL(configuredOrigin).origin;
      if(!local&&!configuredMatch) return json({error:"Invalid payment return origin"},400);
      if(candidate.protocol!=="https:"&&!local) return json({error:"Payment return origin must use HTTPS"},400);
      appOrigin=candidate.origin;
    }
    const initializeBody:Record<string,unknown>={
      email,amount,currency:"NGN",reference,
      metadata:{wpcc_transaction_id:transaction.id,profile_id:userData.user.id,giving_type:type,project_id:projectId,auto_give_requested:Boolean(autoGive)},
    };
    if(appOrigin) initializeBody.callback_url=`${appOrigin}/#/give/result?reference=${encodeURIComponent(reference)}`;
    const paystack=await fetch("https://api.paystack.co/transaction/initialize",{
      method:"POST",headers:{Authorization:`Bearer ${env("PAYSTACK_SECRET_KEY")}`,"Content-Type":"application/json"},body:JSON.stringify(initializeBody),
    });
    const payData=await paystack.json().catch(()=>null) as any;
    if(!paystack.ok||!payData?.status||!payData?.data?.authorization_url){
      await admin.from("giving_transactions").update({status:"failed",failed_at:new Date().toISOString(),provider_response:payData||{},updated_at:new Date().toISOString()}).eq("id",transaction.id);
      return json({error:"Unable to start Paystack payment"},502);
    }
    await admin.from("giving_transactions").update({status:"pending",provider_response:payData,updated_at:new Date().toISOString()}).eq("id",transaction.id);
    return json({transaction_id:transaction.id,reference,authorization_url:payData.data.authorization_url});
  } catch(error) {
    console.error("initialize_giving_failed",error);
    return json({error:"Giving is not configured for this deployment"},503);
  }
});
