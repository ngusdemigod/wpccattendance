import { createClient } from "jsr:@supabase/supabase-js@2";
const cors={"Access-Control-Allow-Origin":"*","Access-Control-Allow-Headers":"authorization, x-client-info, apikey, content-type","Access-Control-Allow-Methods":"POST, OPTIONS"};
const json=(body:unknown,status=200)=>new Response(JSON.stringify(body),{status,headers:{...cors,"Content-Type":"application/json"}});
const env=(n:string)=>{const v=Deno.env.get(n)?.trim();if(!v)throw new Error(`Missing ${n}`);return v;};
async function record(admin:any,reference:string,data:any){
  const authorization=data?.authorization||{}; const customer=data?.customer||{};
  return await admin.rpc("wpcc_record_paystack_transaction",{
    p_reference:reference,p_status:String(data?.status||"failed"),p_channel:String(data?.channel||""),
    p_source_summary:String(authorization?.bank||data?.channel||"Paystack"),p_provider_response:data||{},
    p_customer_code:String(customer?.customer_code||""),p_email:String(customer?.email||""),
    p_authorization_code:String(authorization?.authorization_code||""),p_card_type:String(authorization?.card_type||""),
    p_bank:String(authorization?.bank||""),p_last4:String(authorization?.last4||""),p_exp_month:String(authorization?.exp_month||""),
    p_exp_year:String(authorization?.exp_year||""),p_signature:String(authorization?.signature||""),p_reusable:Boolean(authorization?.reusable),
  });
}
Deno.serve(async(req)=>{
  if(req.method==="OPTIONS") return new Response("ok",{headers:cors});
  if(req.method!=="POST") return json({error:"Method not allowed"},405);
  try{
    const auth=req.headers.get("authorization")||""; const token=auth.toLowerCase().startsWith("bearer ")?auth.slice(7).trim():"";
    if(!token)return json({error:"Authentication required"},401);
    const admin=createClient(env("SUPABASE_URL"),env("SUPABASE_SERVICE_ROLE_KEY"),{auth:{persistSession:false,autoRefreshToken:false}});
    const {data:userData}=await admin.auth.getUser(token); if(!userData.user)return json({error:"Authentication required"},401);
    const body=await req.json().catch(()=>null) as {reference?:string}|null; const reference=String(body?.reference||"").trim();
    if(!reference)return json({error:"Reference is required"},400);
    const {data:tx}=await admin.from("giving_transactions").select("id,profile_id,amount_kobo,currency,paystack_reference").eq("paystack_reference",reference).eq("profile_id",userData.user.id).maybeSingle();
    if(!tx)return json({error:"Transaction not found"},404);
    const res=await fetch(`https://api.paystack.co/transaction/verify/${encodeURIComponent(reference)}`,{headers:{Authorization:`Bearer ${env("PAYSTACK_SECRET_KEY")}`}});
    const payload=await res.json().catch(()=>null) as any; const data=payload?.data;
    if(!res.ok||!payload?.status||!data)return json({error:"Unable to verify payment"},502);
    if(Number(data.amount)!==Number(tx.amount_kobo)||String(data.currency)!=="NGN")return json({error:"Payment verification mismatch"},409);
    const {data:recorded,error}=await record(admin,reference,data); if(error)return json({error:error.message},500);
    return json({transaction:recorded});
  }catch(error){console.error("verify_giving_failed",error);return json({error:"Unable to verify payment"},503);}
});
