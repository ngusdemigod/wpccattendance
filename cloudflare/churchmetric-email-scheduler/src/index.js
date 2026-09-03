async function dispatchEmailWork(env){
  const response=await fetch(env.DISPATCH_URL,{method:"POST",headers:{"x-mailer-secret":env.MAILER_SECRET}});
  if(!response.ok){
    await response.body?.cancel();
    throw new Error(`Email dispatcher returned HTTP ${response.status}`);
  }
  const result=await response.json();
  console.log(JSON.stringify({event:"churchmetric_email_dispatch_completed",...result}));
}

export default {
  fetch(){
    return Response.json({service:"churchmetric-email-scheduler",status:"ok"});
  },
  scheduled(_controller,env,ctx){
    ctx.waitUntil(dispatchEmailWork(env).catch(error=>{
      console.error(JSON.stringify({event:"churchmetric_email_dispatch_failed",message:error instanceof Error?error.message:"Unknown failure"}));
      throw error;
    }));
  },
};
