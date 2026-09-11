import { createClient } from "jsr:@supabase/supabase-js@2";
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{"Content-Type":"application/json"}});
const env=(n:string)=>{const v=Deno.env.get(n)?.trim();if(!v)throw new Error(`Missing ${n}`);return v;};
Deno.serve(async(req)=>{
  if(req.method!=="POST")return json({error:"Method not allowed"},405);
  try{
    if(req.headers.get("x-worker-secret")!==env("WPCC_GIVING_WORKER_SECRET"))return json({error:"Unauthorized"},401);
    const admin=createClient(env("SUPABASE_URL"),env("SUPABASE_SERVICE_ROLE_KEY"),{auth:{persistSession:false,autoRefreshToken:false}});
    const {data:due,error}=await admin.rpc("wpcc_claim_due_auto_give",{p_limit:25,p_lease_seconds:600});if(error)throw error;
    const results=[];
    for(const m of due||[]){
      const reference=String(m.paystack_reference);
      const charge=await fetch("https://api.paystack.co/transaction/charge_authorization",{method:"POST",headers:{Authorization:`Bearer ${env("PAYSTACK_SECRET_KEY")}`,"Content-Type":"application/json"},body:JSON.stringify({authorization_code:m.authorization_code,email:m.email,amount:m.amount_kobo,reference,currency:"NGN",metadata:{mandate_id:m.mandate_id,profile_id:m.profile_id}})});
      const chargePayload=await charge.json().catch(()=>null) as any;
      const verify=await fetch(`https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`,{headers:{Authorization:`Bearer ${env("PAYSTACK_SECRET_KEY")}`}});
      const verifyPayload=await verify.json().catch(()=>null) as any;
      if(!verify.ok||!verifyPayload?.status||!verifyPayload?.data)throw new Error(`Unable to verify Auto Give charge ${reference}`);
      const data=verifyPayload.data||chargePayload?.data||{},providerStatus=String(data?.status||"").toLowerCase();
      if(providerStatus==="success"&&(Number(data?.amount)!==Number(m.amount_kobo)||String(data?.currency)!=="NGN"))throw new Error(`Auto Give payment verification mismatch ${reference}`);
      if(!["success","failed","abandoned","reversed"].includes(providerStatus))throw new Error(`Auto Give payment is not final ${reference}`);
      const ok=providerStatus==="success",authorization=data?.authorization||{},customer=data?.customer||{};
      const {error:recordError}=await admin.rpc("wpcc_record_paystack_transaction",{p_reference:reference,p_status:ok?"success":"failed",p_channel:String(data?.channel||""),p_source_summary:String(authorization?.bank||data?.channel||"Paystack"),p_provider_response:data,p_customer_code:String(customer?.customer_code||""),p_email:String(customer?.email||m.email||""),p_authorization_code:String(authorization?.authorization_code||m.authorization_code||""),p_card_type:String(authorization?.card_type||""),p_bank:String(authorization?.bank||""),p_last4:String(authorization?.last4||""),p_exp_month:String(authorization?.exp_month||""),p_exp_year:String(authorization?.exp_year||""),p_signature:String(authorization?.signature||""),p_reusable:Boolean(authorization?.reusable??true)});
      if(recordError)throw recordError;
      const {error:completeError}=await admin.rpc("wpcc_complete_auto_give_claim",{p_claim_id:m.claim_id,p_claim_token:m.claim_token,p_charged:ok});
      if(completeError)throw completeError;
      results.push({mandate_id:m.mandate_id,ok,reference});
    }
    return json({processed:results.length,results});
  }catch(error){console.error("auto_give_worker_failed",error);return json({error:"Worker processing failed"},503);}
});
