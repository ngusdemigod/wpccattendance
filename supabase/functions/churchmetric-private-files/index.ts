import { createClient } from "jsr:@supabase/supabase-js@2";
import { fileTypeFromBuffer } from "https://esm.sh/file-type@18";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import { getAuthenticatedUser } from "../_shared/auth.ts";
import { deletePrivateObject, getPrivateR2Config, presignR2, putPrivateObject } from "../_shared/private-r2.ts";
import { getRequiredEnv } from "../_shared/mail.ts";

const allowedTypes = new Set(["image/jpeg","image/png","image/webp","image/gif","application/pdf","text/plain","text/csv","application/vnd.openxmlformats-officedocument.wordprocessingml.document","application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"]);
const safeName = (value: string) => value.normalize("NFKC").replace(/[^a-zA-Z0-9._-]+/g, "-").replace(/^-+|-+$/g, "").slice(0, 100) || "attachment";
const hex = (bytes: ArrayBuffer) => [...new Uint8Array(bytes)].map((value) => value.toString(16).padStart(2, "0")).join("");

type RequestContext = { userId: string; role: string; branchId: string | null };
const serviceClient = () => createClient(getRequiredEnv("SUPABASE_URL"), getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY"), { auth: { persistSession: false, autoRefreshToken: false } });

async function requestContext(jwt: string): Promise<RequestContext | null> {
  const user = await getAuthenticatedUser(jwt);
  if (!user?.id) return null;
  const caller = createClient(getRequiredEnv("SUPABASE_URL"), Deno.env.get("SUPABASE_ANON_KEY") || Deno.env.get("API_KEY") || getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY"), {
    global: { headers: { Authorization: `Bearer ${jwt}` } },
    auth: { persistSession: false, autoRefreshToken: false },
  });
  const [roleResult, branchResult] = await Promise.all([caller.rpc("churchmetric_role"), caller.rpc("churchmetric_branch_id")]);
  if (roleResult.error || branchResult.error) return null;
  return { userId: user.id, role: String(roleResult.data || "").toLowerCase(), branchId: typeof branchResult.data === "string" ? branchResult.data : null };
}

async function canManage(context: RequestContext, departmentId: string, branchId: string) {
  if (context.role === "globaladmin") return true;
  if (context.role === "admin" && context.branchId === branchId) return true;
  const { data } = await serviceClient().from("leaders").select("id").eq("user_id", context.userId).eq("department_id", departmentId).eq("branch_id", branchId).eq("is_active", true).maybeSingle();
  return Boolean(data);
}

async function canRead(context: RequestContext, departmentId: string, branchId: string) {
  if (await canManage(context, departmentId, branchId)) return true;
  const admin = serviceClient();
  const [membership, profile] = await Promise.all([
    admin.from("profile_departments").select("profile_id").eq("profile_id", context.userId).eq("department_id", departmentId).eq("branch_id", branchId).maybeSingle(),
    admin.from("profiles").select("id").eq("id", context.userId).eq("department_id", departmentId).eq("branch_id", branchId).maybeSingle(),
  ]);
  return Boolean(membership.data || profile.data);
}

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders });
  if (req.method !== "POST") return jsonResponse({ error: "Method not allowed" }, { status: 405 });
  const authorization = req.headers.get("authorization") || "";
  const jwt = authorization.startsWith("Bearer ") ? authorization.slice(7).trim() : "";
  const context = jwt ? await requestContext(jwt) : null;
  if (!context) return jsonResponse({ error: "Authentication required" }, { status: 401 });

  const action = new URL(req.url).searchParams.get("action") || "upload";
  const config = getPrivateR2Config();
  const admin = serviceClient();

  if (action === "upload") {
    const form = await req.formData();
    const departmentId = String(form.get("department_id") || "");
    const branchId = String(form.get("branch_id") || "");
    const candidate = form.get("file");
    if (!departmentId || !branchId || !(candidate instanceof File)) return jsonResponse({ error: "Department, branch, and file are required" }, { status: 400 });
    if (!(await canManage(context, departmentId, branchId))) return jsonResponse({ error: "Department file management is not permitted" }, { status: 403 });
    const bytes = new Uint8Array(await candidate.arrayBuffer());
    if (!bytes.length || bytes.length > 10 * 1024 * 1024) return jsonResponse({ error: "File must be between 1 byte and 10 MB" }, { status: 413 });
    const detected = await fileTypeFromBuffer(bytes);
    const contentType = detected?.mime || candidate.type || "application/octet-stream";
    if (!allowedTypes.has(contentType)) return jsonResponse({ error: "File type is not allowed" }, { status: 415 });
    const key = `churchmetric/${branchId}/departments/${departmentId}/${crypto.randomUUID()}-${safeName(candidate.name)}`;
    try {
      await putPrivateObject(config, key, contentType, bytes);
      const checksum = hex(await crypto.subtle.digest("SHA-256", bytes));
      const { data, error } = await admin.from("department_attachments").insert({ branch_id: branchId, department_id: departmentId, bucket_name: config.bucket, object_path: key, file_name: candidate.name.slice(0, 255), mime_type: contentType, size_bytes: bytes.length, checksum_sha256: checksum, created_by: context.userId }).select("id,file_name,mime_type,size_bytes,created_at").single();
      if (error) throw error;
      return jsonResponse({ attachment: data });
    } catch (error) {
      try { await deletePrivateObject(config, key); } catch { /* cleanup failure is logged server-side */ }
      console.error("department_file_upload_failed", { departmentId, branchId, error });
      return jsonResponse({ error: "Attachment upload failed" }, { status: 500 });
    }
  }

  const payload = await req.json().catch(() => null) as { attachment_id?: string } | null;
  const attachmentId = payload?.attachment_id || "";
  const { data: attachment } = await admin.from("department_attachments").select("id,branch_id,department_id,bucket_name,object_path,file_name").eq("id", attachmentId).maybeSingle();
  if (!attachment) return jsonResponse({ error: "Attachment not found" }, { status: 404 });
  if (attachment.bucket_name !== config.bucket) return jsonResponse({ error: "Attachment bucket is invalid" }, { status: 409 });

  if (action === "download") {
    if (!(await canRead(context, attachment.department_id, attachment.branch_id))) return jsonResponse({ error: "Department file access is not permitted" }, { status: 403 });
    return jsonResponse({ url: await presignR2(config, "GET", attachment.object_path, undefined, 300), file_name: attachment.file_name, expires_in: 300 });
  }

  if (action === "delete") {
    if (!(await canManage(context, attachment.department_id, attachment.branch_id))) return jsonResponse({ error: "Department file management is not permitted" }, { status: 403 });
    try {
      await deletePrivateObject(config, attachment.object_path);
      const { error } = await admin.from("department_attachments").delete().eq("id", attachment.id);
      if (error) throw error;
      return jsonResponse({ deleted: true });
    } catch (error) {
      console.error("department_file_delete_failed", { attachmentId, error });
      return jsonResponse({ error: "Attachment delete failed" }, { status: 500 });
    }
  }
  return jsonResponse({ error: "Unsupported action" }, { status: 400 });
});
