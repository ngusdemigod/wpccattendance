import { createClient } from "jsr:@supabase/supabase-js@2";
import { fileTypeFromBuffer } from "https://esm.sh/file-type@18";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { getAuthenticatedUser } from "../_shared/auth.ts";
import { deletePrivateObject, getPrivateR2Config, presignR2, putPrivateObject } from "../_shared/private-r2.ts";
import { getRequiredEnv } from "../_shared/mail.ts";

type Claims={sub?:string;wprole?:string;wpbranch_id?:string};
const allowedTypes=new Set(["image/jpeg","image/png","image/webp","image/gif","application/pdf","text/plain","text/csv","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]);
const decode=(jwt:string):Claims=>{try{const value=jwt.split(".")[1].replaceAll("-","+").replaceAll("_","/");return JSON.parse(atob(value.padEnd(Math.ceil(value.length/4)*4,"=")));}catch{return {};}};
const safeName=(value:string)=>value.normalize("NFKC").replace(/[^a-zA-Z0-9._-]+/g,"-").replace(/^-+|-+$/g,"").slice(0,100)||"attachment";
const hex=(bytes:ArrayBuffer)=>[...new Uint8Array(bytes)].map(value=>value.toString(16).padStart(2,"0")).join("");

Deno.serve(async(req:Request)=>{
  if(req.method==="OPTIONS")return new Response("ok",{headers:corsHeaders});
  if(req.method!=="POST")return jsonResponse({error:"Method not allowed"},{status:405});
  const authorization=req.headers.get("authorization")||"",jwt=authorization.startsWith("Bearer ")?authorization.slice(7).trim():"";
  const [user,claims]=await Promise.all([jwt?getAuthenticatedUser(jwt):null,Promise.resolve(decode(jwt))]);
  if(!user?.id||user.id!==claims.sub||!["admin","globaladmin"].includes(claims.wprole||""))return jsonResponse({error:"Administrator access required"},{status:403});
  const admin=createClient(getRequiredEnv("SUPABASE_URL"),getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY"),{auth:{persistSession:false,autoRefreshToken:false}});
  const action=new URL(req.url).searchParams.get("action")||"upload",config=getPrivateR2Config();

  if(action==="upload"){
    const form=await req.formData(),departmentId=String(form.get("department_id")||""),requestedBranch=String(form.get("branch_id")||""),candidate=form.get("file");
    if(!departmentId||!(candidate instanceof File))return jsonResponse({error:"Department and file are required"},{status:400});
    const {data:department}=await admin.from("departments").select("id").eq("id",departmentId).maybeSingle();
    if(!department)return jsonResponse({error:"Department not found"},{status:404});
    const branchId=claims.wprole==="admin"?claims.wpbranch_id:requestedBranch;
    if(!branchId)return jsonResponse({error:"A branch scope is required for private uploads"},{status:400});
    if(claims.wprole==="admin"&&requestedBranch&&requestedBranch!==claims.wpbranch_id)return jsonResponse({error:"Cross-branch upload is forbidden"},{status:403});
    const {data:branch}=await admin.from("branches").select("id").eq("id",branchId).maybeSingle();if(!branch)return jsonResponse({error:"Branch not found"},{status:404});
    const bytes=new Uint8Array(await candidate.arrayBuffer());if(!bytes.length||bytes.length>10*1024*1024)return jsonResponse({error:"File must be between 1 byte and 10 MB"},{status:413});
    const detected=await fileTypeFromBuffer(bytes),contentType=detected?.mime||candidate.type||"application/octet-stream";
    if(!allowedTypes.has(contentType))return jsonResponse({error:"File type is not allowed"},{status:415});
    const key=`churchmetric/${branchId}/departments/${department.id}/${crypto.randomUUID()}-${safeName(candidate.name)}`;
    let objectStored=false,metadataStored=false;
    try{
      await putPrivateObject(config,key,contentType,bytes);
      objectStored=true;
      const checksum=hex(await crypto.subtle.digest("SHA-256",bytes));
      const {data:attachment,error}=await admin.from("department_attachments").insert({branch_id:branchId,department_id:department.id,bucket_name:config.bucket,object_path:key,file_name:candidate.name.slice(0,255),mime_type:contentType,size_bytes:bytes.length,checksum_sha256:checksum,created_by:user.id}).select("id,file_name,mime_type,size_bytes,created_at").single();
      if(error)throw error;
      metadataStored=true;
      return jsonResponse({attachment});
    }catch(error){if(objectStored&&!metadataStored){try{await deletePrivateObject(config,key);}catch{console.error("churchmetric_private_upload_cleanup_failed",{department_id:departmentId});}}console.error("churchmetric_private_upload_failed",{department_id:departmentId});return jsonResponse({error:"Attachment upload failed"},{status:500});}
  }

  const payload=await req.json().catch(()=>null) as {attachment_id?:string;attachment_type?:string}|null,attachmentId=payload?.attachment_id||"",attachmentType=payload?.attachment_type||"department";
  if(!["department","academy_module"].includes(attachmentType))return jsonResponse({error:"Attachment type is invalid"},{status:400});
  const attachmentTable=attachmentType==="academy_module"?"academy_module_attachments":"department_attachments";
  const {data:attachment}=await admin.from(attachmentTable).select("id,branch_id,bucket_name,object_path,file_name").eq("id",attachmentId).maybeSingle();
  if(!attachment)return jsonResponse({error:"Attachment not found"},{status:404});
  if(claims.wprole==="admin"&&attachment.branch_id!==claims.wpbranch_id)return jsonResponse({error:"Cross-branch file access is forbidden"},{status:403});
  if(attachment.bucket_name!==config.bucket)return jsonResponse({error:"Attachment bucket is invalid"},{status:409});
  if(action==="download")return jsonResponse({url:await presignR2(config,"GET",attachment.object_path,undefined,300),file_name:attachment.file_name,expires_in:300});
  if(action==="delete"&&attachmentType==="department"){
    try{await deletePrivateObject(config,attachment.object_path);const {error}=await admin.from("department_attachments").delete().eq("id",attachment.id);if(error)throw error;await admin.from("churchmetric_audit_events").insert({branch_id:attachment.branch_id,actor_id:user.id,action:"department_attachment_deleted",entity_type:"department_attachment",entity_id:attachment.id,metadata:{bucket:config.bucket}});return jsonResponse({deleted:true});}catch(error){console.error("churchmetric_private_delete_failed",{attachment_id:attachment.id});return jsonResponse({error:"Attachment delete failed"},{status:500});}
  }
  if(action==="delete")return jsonResponse({error:"Academy attachment deletion is not available from this page"},{status:405});
  return jsonResponse({error:"Unsupported action"},{status:400});
});
