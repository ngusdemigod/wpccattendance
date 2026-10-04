import { createClient } from "jsr:@supabase/supabase-js@2";
import { fileTypeFromBuffer } from "https://esm.sh/file-type@18.7.0";
import { getAuthenticatedUser } from "../_shared/auth.ts";
import { corsHeaders, jsonResponse as sharedJsonResponse } from "../_shared/cors.ts";
import {
  deletePrivateObject,
  getPrivateR2Config,
  presignR2,
  putPrivateObject,
} from "../_shared/private-r2.ts";
import { getSupabaseRuntimeUrl, getSupabaseServiceKey } from "../_shared/mail.ts";

function jsonResponse(body: unknown, init: ResponseInit = {}) {
  return sharedJsonResponse(body, { ...init, headers: { ...init.headers, "Cache-Control": "no-store", "X-Content-Type-Options": "nosniff" } });
}

const avatarKey = /^profile-avatars\/[0-9a-f-]{36}\/[0-9a-f-]{36}\.(jpg|png|webp)$/;
const contentTypes: Record<string, string> = {
  jpg: "image/jpeg",
  png: "image/png",
  webp: "image/webp",
};

Deno.serve(async (request) => {
  if (request.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, { status: 405 });
  }

  const authorization = request.headers.get("authorization") || "";
  const jwt = authorization.startsWith("Bearer ")
    ? authorization.slice(7).trim()
    : "";
  const user = jwt ? await getAuthenticatedUser(jwt) : null;
  if (!user?.id) {
    return jsonResponse({ error: "Authentication required" }, { status: 401 });
  }

  try {
  const config = getPrivateR2Config();
  // Bound the stream before parsing multipart data, including chunked requests.
  const reader = request.body?.getReader();
  const chunks: Uint8Array[] = [];
  let size = 0;
  if (reader) {
    while (true) {
      const { value, done } = await reader.read();
      if (done) break;
      size += value.length;
      if (size > 6 * 1024 * 1024) {
        await reader.cancel();
        return jsonResponse({ error: "Avatar must be no larger than 5 MB" }, { status: 413 });
      }
      chunks.push(value);
    }
  }
  const boundedBody = new Blob(chunks.map(chunk => new Uint8Array(chunk).buffer));
  const parsedRequest = new Request(request.url, { method: "POST", headers: request.headers, body: boundedBody });
  const admin = createClient(getSupabaseRuntimeUrl(), getSupabaseServiceKey(),
    { auth: { persistSession: false, autoRefreshToken: false } });
  const contentType = request.headers.get("content-type") || "";
  if (contentType.includes("application/json")) {
    const payload = await parsedRequest.json().catch(() => null) as {
      avatar_url?: string;
      include_data?: boolean;
    } | null;
    const storedUrl = payload?.avatar_url || "";
    const prefix = `r2://${config.bucket}/`;
    const objectKey = storedUrl.startsWith(prefix)
      ? storedUrl.slice(prefix.length)
      : "";
    if (
      !avatarKey.test(objectKey)
    ) {
      return jsonResponse({ error: "Avatar not found" }, { status: 404 });
    }
    const owner = objectKey.split("/")[1];
    let allowed = false;
    if (owner === user.id) {
      const { data } = await admin.from("profiles").select("avatar").eq("id", user.id).maybeSingle();
      allowed = data?.avatar === storedUrl;
    } else {
      // Existing member-visibility RPC enforces department membership with the caller's JWT.
      const caller = createClient(getSupabaseRuntimeUrl(), getSupabaseServiceKey(), {
        global: { headers: { Authorization: authorization } },
        auth: { persistSession: false, autoRefreshToken: false },
      });
      const { data, error } = await caller.rpc("community_public_member_profile", { p_profile_id: owner });
      allowed = !error && Array.isArray(data) && data[0]?.avatar === storedUrl;
    }
    if (!allowed) return jsonResponse({ error: "Avatar not found" }, { status: 404 });
    const signedUrl = await presignR2(config, "GET", objectKey, undefined, 300);
    if (payload?.include_data) {
      const object = await fetch(signedUrl);
      if (!object.ok) {
        return jsonResponse({ error: "Avatar not found" }, { status: 404 });
      }
      const bytes = new Uint8Array(await object.arrayBuffer());
      if (bytes.length > 5 * 1024 * 1024) return jsonResponse({ error: "Avatar unavailable" }, { status: 413 });
      let binary = "";
      const chunkSize = 0x8000;
      for (let offset = 0; offset < bytes.length; offset += chunkSize) {
        binary += String.fromCharCode(...bytes.subarray(offset, offset + chunkSize));
      }
      return jsonResponse({
        data_base64: btoa(binary),
        content_type: object.headers.get("content-type") || "image/jpeg",
        expires_in: 300,
      });
    }
    return jsonResponse({ url: signedUrl, expires_in: 300 });
  }

  const candidate = (await parsedRequest.formData()).get("file");
  if (!(candidate instanceof File)) {
    return jsonResponse({ error: "Select an image to upload" }, { status: 400 });
  }
  const bytes = new Uint8Array(await candidate.arrayBuffer());
  if (!bytes.length || bytes.length > 5 * 1024 * 1024) {
    return jsonResponse({ error: "Avatar must be no larger than 5 MB" }, { status: 413 });
  }
  const detected = await fileTypeFromBuffer(bytes);
  const extension = detected?.mime === "image/jpeg"
    ? "jpg"
    : detected?.mime === "image/png"
    ? "png"
    : detected?.mime === "image/webp"
    ? "webp"
    : null;
  if (!extension) {
    return jsonResponse({ error: "Use a JPG, PNG, or WebP image" }, { status: 415 });
  }

  const objectKey = `profile-avatars/${user.id}/${crypto.randomUUID()}.${extension}`;
  const storedUrl = `r2://${config.bucket}/${objectKey}`;
  const previous = await admin.from("profiles").select("avatar").eq("id", user.id)
    .maybeSingle();

  try {
    await putPrivateObject(config, objectKey, contentTypes[extension], bytes);
    const { error } = await admin.from("profiles").update({ avatar: storedUrl, avatar_storage_path: objectKey, avatar_is_encrypted: false, avatar_nonce: null })
      .eq("id", user.id).select("id").single();
    if (error) throw error;

    const previousStored = typeof previous.data?.avatar === "string"
      ? previous.data.avatar
      : "";
    const prefix = `r2://${config.bucket}/`;
    const previousKey = previousStored.startsWith(prefix)
      ? previousStored.slice(prefix.length)
      : "";
    if (
      previousKey.startsWith(`profile-avatars/${user.id}/`) &&
      avatarKey.test(previousKey)
    ) {
      try {
        await deletePrivateObject(config, previousKey);
      } catch {
        // Replaced successfully; stale-object cleanup is best effort.
      }
    }
    return jsonResponse({ avatar_url: storedUrl });
  } catch (error) {
    try {
      await deletePrivateObject(config, objectKey);
    } catch {
      // Best effort rollback.
    }
    console.error("profile_avatar_upload_failed", { userId: user.id });
    return jsonResponse({ error: "Avatar upload failed" }, { status: 500 });
  }
  } catch {
    return jsonResponse({ error: "Photo service is unavailable. Please try again." }, { status: 503 });
  }
});
