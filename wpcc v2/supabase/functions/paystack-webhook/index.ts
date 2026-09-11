import { createClient } from "jsr:@supabase/supabase-js@2";
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{"Content-Type":"application/json"}});
const env=(n:string)=>{const v=Deno.env.get(n)?.trim();if(!v)throw new Error(`Missing ${n}`);return v;};
const hex=(b:ArrayBuffer)=>[...new Uint8Array(b)].map(x=>x.toString(16).padStart(2,"0")).join("");
async function hmac(secret:string,body:string){const key=await crypto.subtle.importKey("raw",new TextEncoder().encode(secret),{name:"HMAC",hash:"SHA-512"},false,["sign"]);return hex(await crypto.subtle.sign("HMAC",key,new TextEncoder().encode(body)));}
Deno.serve(async(req)=>{
  if(req.method!=="POST")return json({ok:true});
  try{
    const raw=await req.text(); const signature=req.headers.get("x-paystack-signature")||""; const secret=env("PAYSTACK_SECRET_KEY");
    if(!signature||signature.toLowerCase()!==(await hmac(secret,raw)).toLowerCase())return json({error:"Invalid signature"},401);
    const event=JSON.parse(raw); const data=event?.data||{}; const reference=String(data?.reference||"");
    const providerEventId=`${String(event?.event||"event")}:${String(data?.id||reference||crypto.randomUUID())}`;
    const admin=createClient(env("SUPABASE_URL"),env("SUPABASE_SERVICE_ROLE_KEY"),{auth:{persistSession:false,autoRefreshToken:false}});
    const {data:logged,error:logError}=await admin.from("provider_webhook_events").insert({provider:"paystack",provider_event_id:providerEventId,payload:event,received_at:new Date().toISOString()}).select("id,processed_at").maybeSingle();
    if(logError?.code==="23505")return json({ok:true,duplicate:true});
    if(logError)throw logError;
    if(reference&&(event.event==="charge.success"||event.event==="charge.failed")){
      const {data:transaction,error:transactionError}=await admin.from("giving_transactions").select("id,amount_kobo,currency").eq("paystack_reference",reference).maybeSingle();
      if(transactionError)throw transactionError;
      if(!transaction)throw new Error("Giving transaction not found");
      if(event.event==="charge.success"&&(Number(data?.amount)!==Number(transaction.amount_kobo)||String(data?.currency)!==String(transaction.currency))){
        await admin.from("provider_webhook_events").update({processed_at:new Date().toISOString(),processing_error:"Payment amount or currency mismatch"}).eq("id",logged.id);
        return json({ok:true,rejected:true});
      }
      const authorization=data?.authorization||{}; const customer=data?.customer||{};
      const {error}=await admin.rpc("wpcc_record_paystack_transaction",{
        p_reference:reference,p_status:event.event==="charge.success"?"success":"failed",p_channel:String(data?.channel||""),
        p_source_summary:String(authorization?.bank||data?.channel||"Paystack"),p_provider_response:data,
        p_customer_code:String(customer?.customer_code||""),p_email:String(customer?.email||""),p_authorization_code:String(authorization?.authorization_code||""),
        p_card_type:String(authorization?.card_type||""),p_bank:String(authorization?.bank||""),p_last4:String(authorization?.last4||""),
        p_exp_month:String(authorization?.exp_month||""),p_exp_year:String(authorization?.exp_year||""),p_signature:String(authorization?.signature||""),p_reusable:Boolean(authorization?.reusable),
      });
      if(error)throw error;
    }
    await admin.from("provider_webhook_events").update({processed_at:new Date().toISOString(),processing_error:null}).eq("id",logged.id);
    return json({ok:true});
  }catch(error){console.error("paystack_webhook_failed",error);return json({error:"Webhook processing failed"},500);}
});
