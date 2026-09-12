import { createClient } from "jsr:@supabase/supabase-js@2";
import { fileTypeFromBuffer } from "https://esm.sh/file-type@18";
import { getAuthenticatedUser } from "../_shared/auth.ts";
import { corsHeaders, jsonResponse } from "../_shared/cors.ts";
import {
  deletePrivateObject,
  getPrivateR2Config,
  presignR2,
  putPrivateObject,
} from "../_shared/private-r2.ts";
import { getRequiredEnv } from "../_shared/mail.ts";

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

  const config = getPrivateR2Config();
  const contentType = request.headers.get("content-type") || "";
  if (contentType.includes("application/json")) {
    const payload = await request.json().catch(() => null) as {
      avatar_url?: string;
      include_data?: boolean;
    } | null;
    const storedUrl = payload?.avatar_url || "";
    const prefix = `r2://${config.bucket}/`;
    const objectKey = storedUrl.startsWith(prefix)
      ? storedUrl.slice(prefix.length)
      : "";
    if (
      !avatarKey.test(objectKey) ||
      !objectKey.startsWith(`profile-avatars/${user.id}/`)
    ) {
      return jsonResponse({ error: "Avatar not found" }, { status: 404 });
    }
    const signedUrl = await presignR2(config, "GET", objectKey, undefined, 300);
    if (payload?.include_data) {
      const object = await fetch(signedUrl);
      if (!object.ok) {
        return jsonResponse({ error: "Avatar not found" }, { status: 404 });
      }
      const bytes = new Uint8Array(await object.arrayBuffer());
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

  const candidate = (await request.formData()).get("file");
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
  const admin = createClient(
    getRequiredEnv("SUPABASE_URL"),
    getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY"),
    { auth: { persistSession: false, autoRefreshToken: false } },
  );
  const previous = await admin.from("profiles").select("avatar").eq("id", user.id)
    .maybeSingle();

  try {
    await putPrivateObject(config, objectKey, contentTypes[extension], bytes);
    const { error } = await admin.from("profiles").update({ avatar: storedUrl })
      .eq("id", user.id);
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
    console.error("profile_avatar_upload_failed", { userId: user.id, error });
    return jsonResponse({ error: "Avatar upload failed" }, { status: 500 });
  }
});
