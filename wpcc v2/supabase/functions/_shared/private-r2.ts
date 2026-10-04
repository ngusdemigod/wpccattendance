import { getRequiredEnv } from "./mail.ts";
const encoder = new TextEncoder();
const toHex = (buffer: ArrayBuffer) => [...new Uint8Array(buffer)].map((v) => v.toString(16).padStart(2,"0")).join("");
const hmac = async (key: BufferSource, value: string) => {
  const cryptoKey = await crypto.subtle.importKey("raw", key, { name:"HMAC", hash:"SHA-256" }, false, ["sign"]);
  return crypto.subtle.sign("HMAC", cryptoKey, encoder.encode(value));
};
const sha256 = async (value: string) => toHex(await crypto.subtle.digest("SHA-256", encoder.encode(value)));
const awsEncode = (value:string) => encodeURIComponent(value).replace(/[!'()*]/g,(character)=>`%${character.charCodeAt(0).toString(16).toUpperCase()}`);
const canonicalQuery = (params:URLSearchParams) => [...params.entries()]
  .map(([key,value])=>[awsEncode(key),awsEncode(value)] as const)
  .sort(([aKey,aValue],[bKey,bValue])=>aKey<bKey?-1:aKey>bKey?1:aValue<bValue?-1:aValue>bValue?1:0)
  .map(([key,value])=>`${key}=${value}`).join("&");
const signingKey = async (secret: string, date: string) => {
  const dateKey = await hmac(encoder.encode(`AWS4${secret}`), date);
  const regionKey = await hmac(dateKey, "auto");
  const serviceKey = await hmac(regionKey, "s3");
  return hmac(serviceKey, "aws4_request");
};
const normalize = (value: string) => value.trim().replace(/^\/+|\/+$/g,"").replace(/\/{2,}/g,"/");
export type PrivateR2Config = { endpoint:string; bucket:string; accessKeyId:string; secretAccessKey:string };
export const getPrivateR2Config = (): PrivateR2Config => {
  const accountId = getRequiredEnv("R2_ACCOUNT_ID");
  return {
    endpoint:`https://${accountId}.r2.cloudflarestorage.com`,
    bucket:Deno.env.get("R2_PRIVATE_BUCKET_NAME")?.trim() || "wpcc-private",
    accessKeyId:getRequiredEnv("R2_PRIVATE_ACCESS_KEY_ID"),
    secretAccessKey:getRequiredEnv("R2_PRIVATE_SECRET_ACCESS_KEY"),
  };
};
export async function presignR2(config:PrivateR2Config, method:"GET"|"PUT"|"DELETE"|"HEAD", objectKey="", contentType?:string, expires=300, response?:{downloadName:string}) {
  const now=new Date(), amzDate=now.toISOString().replace(/[:-]|\.\d{3}/g,""), date=amzDate.slice(0,8), scope=`${date}/auto/s3/aws4_request`, host=new URL(config.endpoint).host;
  const key=normalize(objectKey), uri=`/${config.bucket}${key?`/${encodeURIComponent(key).replace(/%2F/g,"/")}`:""}`;
  const signedHeaders=contentType?"content-type;host":"host";
  const params=new URLSearchParams({"X-Amz-Algorithm":"AWS4-HMAC-SHA256","X-Amz-Credential":`${config.accessKeyId}/${scope}`,"X-Amz-Date":amzDate,"X-Amz-Expires":String(expires),"X-Amz-SignedHeaders":signedHeaders});
  if(method==="GET"&&response){
    const downloadName=response.downloadName.replace(/[^a-zA-Z0-9._-]+/g,"-").slice(0,100)||"attachment";
    params.set("response-content-disposition",`attachment; filename="${downloadName}"`);
    params.set("response-content-type","application/octet-stream");
  }
  const query=canonicalQuery(params);
  const canonicalHeaders=contentType?`content-type:${contentType}\nhost:${host}\n`:`host:${host}\n`;
  const canonical=[method,uri,query,canonicalHeaders,signedHeaders,"UNSIGNED-PAYLOAD"].join("\n");
  const signature=toHex(await hmac(await signingKey(config.secretAccessKey,date),["AWS4-HMAC-SHA256",amzDate,scope,await sha256(canonical)].join("\n")));
  return `${config.endpoint}${uri}?${query}&X-Amz-Signature=${signature}`;
}
export async function putPrivateObject(config:PrivateR2Config,key:string,contentType:string,bytes:Uint8Array){
  const response=await fetch(await presignR2(config,"PUT",key,contentType),{method:"PUT",headers:{"Content-Type":contentType,"Content-Length":String(bytes.length)},body:new Uint8Array(bytes).buffer});
  if(!response.ok) throw new Error("Private R2 upload failed");
}
export async function deletePrivateObject(config:PrivateR2Config,key:string){
  const response=await fetch(await presignR2(config,"DELETE",key),{method:"DELETE"});
  if(!response.ok&&response.status!==404) throw new Error("Private R2 delete failed");
}
