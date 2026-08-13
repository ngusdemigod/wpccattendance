import { createClient } from "jsr:@supabase/supabase-js@2";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { getRequiredEnv, sendEmailThroughTransport } from "../_shared/mail.ts";

type OutboxRow={id:string;aggregate_id:string;branch_id:string;attempts:number;event_type:string;payload:Record<string,unknown>};
type Campaign={id:string;branch_id:string;channel:string;subject:string|null;body:string;status:string};
type Recipient={id:string;branch_id:string;destination:string;status:string};

Deno.serve(async(req:Request)=>{
  if(req.method==="OPTIONS")return new Response("ok",{headers:corsHeaders});
  if(req.method!=="POST")return jsonResponse({error:"Method not allowed"},{status:405});
  if(req.headers.get("x-mailer-secret")!==getRequiredEnv("MAILER_SECRET"))return jsonResponse({error:"Unauthorized"},{status:401});

  const admin=createClient(getRequiredEnv("SUPABASE_URL"),getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY"),{auth:{persistSession:false,autoRefreshToken:false}});
  const {data:claimed,error:claimError}=await admin.rpc("churchmetric_claim_email_outbox",{p_limit:10});
  if(claimError){console.error("churchmetric_email_claim_failed",{code:claimError.code});return jsonResponse({error:"Unable to claim email work"},{status:500});}

  let campaignsProcessed=0,enquiriesProcessed=0,recipientsSent=0,recipientsFailed=0;
  for(const item of (claimed||[]) as OutboxRow[]){
    if(item.event_type==="enquiry_response_created"){
      const {data:message}=await admin.from("enquiry_messages").select("id,enquiry_id,body,delivery_status").eq("id",item.aggregate_id).maybeSingle();
      const {data:enquiry}=message?await admin.from("enquiries").select("id,subject,member_id").eq("id",message.enquiry_id).maybeSingle():{data:null};
      const {data:member}=enquiry?.member_id?await admin.from("profiles").select("email").eq("id",enquiry.member_id).maybeSingle():{data:null};
      if(!message||!enquiry||!member?.email){
        if(message)await admin.from("enquiry_messages").update({delivery_status:"failed"}).eq("id",message.id);
        await admin.from("notification_outbox").update({status:"failed",last_error:"Enquiry email destination unavailable",processed_at:new Date().toISOString(),locked_at:null}).eq("id",item.id);
        continue;
      }
      try{
        await sendEmailThroughTransport({to:member.email,subject:`Re: ${enquiry.subject}`,text:message.body,idempotencyKey:`churchmetric-enquiry-${message.id}`});
        await admin.from("enquiry_messages").update({delivery_status:"sent"}).eq("id",message.id);
        await admin.from("notification_outbox").update({status:"processed",processed_at:new Date().toISOString(),locked_at:null}).eq("id",item.id);
        enquiriesProcessed++;recipientsSent++;
      }catch(error){
        console.error("churchmetric_enquiry_email_failed",{enquiry_id:enquiry.id,message_id:message.id});
        const retry=item.attempts<5;
        await admin.from("enquiry_messages").update({delivery_status:retry?"queued":"failed"}).eq("id",message.id);
        await admin.from("notification_outbox").update(retry?{status:"retry",last_error:"Enquiry email delivery failed",locked_at:null,available_at:new Date(Date.now()+60_000*Math.min(30,item.attempts*2)).toISOString()}:{status:"failed",last_error:"Enquiry email retry limit reached",processed_at:new Date().toISOString(),locked_at:null}).eq("id",item.id);
        recipientsFailed++;
      }
      continue;
    }
    const {data:campaignData}=await admin.from("broadcast_campaigns").select("id,branch_id,channel,subject,body,status").eq("id",item.aggregate_id).maybeSingle();
    const campaign=campaignData as Campaign|null;
    if(!campaign||campaign.channel!=="email"){
      await admin.from("notification_outbox").update({status:"failed",last_error:"Email campaign not found",locked_at:null}).eq("id",item.id);
      continue;
    }
    const {data:recipientData,error:recipientError}=await admin.from("broadcast_recipients").select("id,branch_id,destination,status").eq("campaign_id",campaign.id).in("status",["pending","failed"]).order("created_at");
    if(recipientError){await admin.from("notification_outbox").update({status:"retry",last_error:"Unable to load recipients",locked_at:null,available_at:new Date(Date.now()+60_000*Math.min(30,item.attempts*2)).toISOString()}).eq("id",item.id);continue;}

    for(const recipient of (recipientData||[]) as Recipient[]){
      try{
        const response=await sendEmailThroughTransport({to:recipient.destination,subject:campaign.subject||"ChurchMetric update",text:campaign.body,idempotencyKey:`churchmetric-${recipient.id}`}) as {id?:string};
        const providerId=response.id||`accepted:${recipient.id}`;
        await admin.from("broadcast_recipients").update({status:"sent",provider_message_id:providerId}).eq("id",recipient.id);
        await admin.from("broadcast_delivery_events").upsert({branch_id:recipient.branch_id,recipient_id:recipient.id,event_type:"sent",provider_event_id:providerId,occurred_at:new Date().toISOString(),metadata:{provider:"resend"}},{onConflict:"provider_event_id"});
        recipientsSent++;
      }catch(error){
        console.error("churchmetric_email_recipient_failed",{campaign_id:campaign.id,recipient_id:recipient.id});
        await admin.from("broadcast_recipients").update({status:"failed"}).eq("id",recipient.id);
        await admin.from("broadcast_delivery_events").upsert({branch_id:recipient.branch_id,recipient_id:recipient.id,event_type:"failed",provider_event_id:`failed:${recipient.id}:${item.attempts}`,occurred_at:new Date().toISOString(),metadata:{retryable:true}},{onConflict:"provider_event_id"});
        recipientsFailed++;
      }
    }
    const {count:remaining}=await admin.from("broadcast_recipients").select("id",{count:"exact",head:true}).eq("campaign_id",campaign.id).in("status",["pending","failed"]);
    const retry=Boolean(remaining)&&item.attempts<5;
    await admin.from("broadcast_campaigns").update({status:retry?"dispatching":remaining?"failed":"sent",sent_at:remaining?null:new Date().toISOString()}).eq("id",campaign.id);
    await admin.from("notification_outbox").update(retry?{status:"retry",last_error:"One or more recipients failed",locked_at:null,available_at:new Date(Date.now()+60_000*Math.min(30,item.attempts*2)).toISOString()}:{status:remaining?"failed":"processed",last_error:remaining?"Retry limit reached":null,processed_at:new Date().toISOString(),locked_at:null}).eq("id",item.id);
    campaignsProcessed++;
  }
  return jsonResponse({campaignsProcessed,enquiriesProcessed,recipientsSent,recipientsFailed});
});
