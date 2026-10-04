import { serve } from "https://deno.land/std@0.224.0/http/server.ts";
import { fileTypeFromBuffer } from "https://esm.sh/file-type@18";
import { getAuthenticatedUser } from "../_shared/auth.ts";

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
  "Access-Control-Allow-Methods": "POST, OPTIONS",
};

const ALLOWED_BUCKET = "wpcc";
const MAX_FILE_SIZE_BYTES = 10 * 1024 * 1024;

type StorageTarget = {
  endpoint: string;
  publicBaseUrl: string;
  accessKeyId: string;
  secretAccessKey: string;
};

function toHex(buffer: ArrayBuffer): string {
  return [...new Uint8Array(buffer)]
    .map((b) => b.toString(16).padStart(2, "0"))
    .join("");
}

async function hmac(key: BufferSource, msg: string): Promise<ArrayBuffer> {
  const cryptoKey = await crypto.subtle.importKey(
    "raw",
    key,
    { name: "HMAC", hash: "SHA-256" },
    false,
    ["sign"],
  );
  return crypto.subtle.sign("HMAC", cryptoKey, new TextEncoder().encode(msg));
}

async function sha256(msg: string): Promise<string> {
  const hash = await crypto.subtle.digest(
    "SHA-256",
    new TextEncoder().encode(msg),
  );
  return toHex(hash);
}

async function getSigningKey(
  secret: string,
  date: string,
  region: string,
  service: string,
): Promise<ArrayBuffer> {
  const kDate = await hmac(
    new TextEncoder().encode("AWS4" + secret),
    date,
  );
  const kRegion = await hmac(kDate, region);
  const kService = await hmac(kRegion, service);
  return hmac(kService, "aws4_request");
}

async function generatePresignedPutUrl({
  endpoint,
  accessKeyId,
  secretAccessKey,
  bucket,
  objectKey,
  contentType,
  expiresIn = 300,
}: {
  endpoint: string;
  accessKeyId: string;
  secretAccessKey: string;
  bucket: string;
  objectKey: string;
  contentType: string;
  expiresIn?: number;
}) {
  const service = "s3";
  const region = "auto";
  const now = new Date();
  const amzDate = now.toISOString().replace(/[:-]|\.\d{3}/g, "");
  const dateStamp = amzDate.slice(0, 8);
  const endpointUrl = new URL(endpoint);
  const host = endpointUrl.host;
  const basePath = endpointUrl.pathname.replace(/\/$/, "");
  const encodedKey = encodeURIComponent(objectKey).replace(/%2F/g, "/");
  const credentialScope = `${dateStamp}/${region}/${service}/aws4_request`;
  const canonicalUri = `${basePath}/${bucket}/${encodedKey}`;

  const params = new URLSearchParams({
    "X-Amz-Algorithm": "AWS4-HMAC-SHA256",
    "X-Amz-Credential": `${accessKeyId}/${credentialScope}`,
    "X-Amz-Date": amzDate,
    "X-Amz-Expires": expiresIn.toString(),
    "X-Amz-SignedHeaders": "content-type;host",
  });

  const canonicalRequest = [
    "PUT",
    canonicalUri,
    params.toString(),
    `content-type:${contentType}\nhost:${host}\n`,
    "content-type;host",
    "UNSIGNED-PAYLOAD",
  ].join("\n");

  const stringToSign = [
    "AWS4-HMAC-SHA256",
    amzDate,
    credentialScope,
    await sha256(canonicalRequest),
  ].join("\n");

  const signingKey = await getSigningKey(
    secretAccessKey,
    dateStamp,
    region,
    service,
  );
  const signature = toHex(await hmac(signingKey, stringToSign));
  params.set("X-Amz-Signature", signature);

  const requestUrl = new URL(endpointUrl.toString());
  requestUrl.pathname = canonicalUri;
  requestUrl.search = params.toString();
  return requestUrl.toString();
}

function getPublicUrl(
  publicBaseUrl: string,
  objectKey: string,
) {
  // R2 public domains map directly to a single bucket, including the
  // configured custom domain used by this app. The bucket is therefore not
  // repeated in the public object path.
  return `${publicBaseUrl.replace(/\/$/, "")}/${normalizeObjectKey(objectKey)}`;
}

function getStorageTarget(): StorageTarget | null {
  const r2AccountId = Deno.env.get("R2_ACCOUNT_ID")?.trim() ?? "";
  const r2AccessKeyId = Deno.env.get("R2_ACCESS_KEY_ID")?.trim() ?? "";
  const r2SecretAccessKey = Deno.env.get("R2_SECRET_ACCESS_KEY")?.trim() ?? "";

  if (r2AccountId && r2AccessKeyId && r2SecretAccessKey) {
    return {
      endpoint: `https://${r2AccountId}.r2.cloudflarestorage.com`,
      publicBaseUrl:
        Deno.env.get("R2_PUBLIC_URL")?.trim() ||
        `https://${r2AccountId}.r2.dev`,
      accessKeyId: r2AccessKeyId,
      secretAccessKey: r2SecretAccessKey,
    };
  }

  const localEndpoint = Deno.env.get("STORAGE_S3_URL")?.trim() ?? "";
  const localAccessKeyId = Deno.env
    .get("S3_PROTOCOL_ACCESS_KEY_ID")
    ?.trim() ?? "";
  const localSecretAccessKey = Deno.env
    .get("S3_PROTOCOL_ACCESS_KEY_SECRET")
    ?.trim() ?? "";
  if (localEndpoint && localAccessKeyId && localSecretAccessKey) {
    return {
      endpoint: localEndpoint,
      publicBaseUrl:
        Deno.env.get("PUBLIC_BASE_URL")?.trim() ||
        `${Deno.env.get("PROJECT_URL")?.trim() ||
          Deno.env.get("SUPABASE_URL")?.trim() ||
          "http://127.0.0.1:54321"}/storage/v1/object/public`,
      accessKeyId: localAccessKeyId,
      secretAccessKey: localSecretAccessKey,
    };
  }

  return null;
}

function normalizeObjectKey(objectKey: string) {
  return objectKey.trim().replace(/^\/+/, "").replace(/\/{2,}/g, "/");
}

function contentTypeFromExtension(pathLike: string): string | null {
  const extension = pathLike.split(".").pop()?.trim().toLowerCase() ?? "";
  switch (extension) {
    case "jpg":
    case "jpeg":
      return "image/jpeg";
    case "png":
      return "image/png";
    case "webp":
      return "image/webp";
    case "gif":
      return "image/gif";
    case "bmp":
      return "image/bmp";
    case "tif":
    case "tiff":
      return "image/tiff";
    case "heic":
      return "image/heic";
    case "heif":
      return "image/heif";
    default:
      return null;
  }
}

function hasUnsafePathSegment(objectKey: string) {
  return objectKey.split("/").some((segment) =>
    segment.trim().isEmpty || segment === "." || segment === ".."
  );
}

function isAllowedObjectKey(objectKey: string, userId: string) {
  const normalized = normalizeObjectKey(objectKey);
  if (!normalized || hasUnsafePathSegment(normalized)) {
    return false;
  }

  const escapedUserId = userId.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");

  return new RegExp(`^events/(test|${escapedUserId})/.+$`).test(normalized) ||
    new RegExp(`^profiles/${escapedUserId}/avatar/.+$`).test(normalized) ||
    new RegExp(`^media/[^/]+/${escapedUserId}/.+$`).test(normalized);
}

serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  if (req.method !== "POST") {
    return new Response("Method Not Allowed", {
      status: 405,
      headers: corsHeaders,
    });
  }

  try {
    const authorization = req.headers.get("Authorization") ??
      req.headers.get("authorization") ?? "";
    const jwt = authorization.startsWith("Bearer ")
      ? authorization.slice(7).trim()
      : "";
    if (!jwt) {
      return new Response(
        JSON.stringify({ error: "Missing authenticated bearer token" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const user = await getAuthenticatedUser(jwt);
    const userId = user?.id?.toString().trim() ?? "";
    if (!userId) {
      return new Response(
        JSON.stringify({ error: "Invalid or expired user session" }),
        {
          status: 401,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const formData = await req.formData();
    const file = formData.get("file");
    const objectKey = formData.get("objectKey")?.toString().trim() ?? "";
    const bucket = formData.get("bucket")?.toString().trim() ||
      Deno.env.get("R2_BUCKET_NAME");
    const expiresIn = Number(formData.get("expiresIn")?.toString()) || 300;

    if (!file) {
      return new Response(
        JSON.stringify({
          error: "Missing required field: file",
          fieldsReceived: Array.from(formData.keys()),
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (!(file instanceof File) &&
      !(typeof file === "object" && "arrayBuffer" in file)) {
      return new Response(
        JSON.stringify({
          error: "The provided 'file' is not a valid file object. Use MULTIPART upload.",
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const uploadFile = file as File;
    const bytes = new Uint8Array(await uploadFile.arrayBuffer());
    if (bytes.length == 0 || bytes.length > MAX_FILE_SIZE_BYTES) {
      return new Response(
        JSON.stringify({
          error: "File size is invalid for upload",
          maxBytes: MAX_FILE_SIZE_BYTES,
          receivedBytes: bytes.length,
        }),
        {
          status: 413,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const originalType = uploadFile.type?.trim() || "application/octet-stream";
    const detected = await fileTypeFromBuffer(bytes);
    const extensionType = contentTypeFromExtension(
      uploadFile.name || objectKey || "",
    );
    const contentType = detected?.mime ||
      (originalType !== "application/octet-stream" ? originalType : null) ||
      extensionType ||
      "application/octet-stream";

    if (!bucket || !objectKey) {
      return new Response(
        JSON.stringify({
          error: "Missing required fields: bucket and objectKey",
          fieldsReceived: Array.from(formData.keys()),
        }),
        {
          status: 400,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    if (bucket !== ALLOWED_BUCKET) {
      return new Response(
        JSON.stringify({ error: "Uploads are restricted to the wpcc bucket" }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const normalizedObjectKey = normalizeObjectKey(objectKey);
    if (!isAllowedObjectKey(normalizedObjectKey, userId)) {
      return new Response(
        JSON.stringify({
          error: "Object key is outside allowed upload namespaces",
          objectKey: normalizedObjectKey,
        }),
        {
          status: 403,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const storageTarget = getStorageTarget();
    if (!storageTarget) {
      return new Response(
        JSON.stringify({
          error: "Storage environment variables are not configured",
        }),
        {
          status: 500,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    const resolvedUploadUrl = await generatePresignedPutUrl({
      endpoint: storageTarget.endpoint,
      accessKeyId: storageTarget.accessKeyId,
      secretAccessKey: storageTarget.secretAccessKey,
      bucket,
      objectKey: normalizedObjectKey,
      contentType,
      expiresIn,
    });

    const r2Response = await fetch(resolvedUploadUrl, {
      method: "PUT",
      headers: {
        "Content-Type": contentType,
        "Content-Length": bytes.length.toString(),
      },
      body: bytes,
    });

    if (!r2Response.ok) {
      const responseBody = await r2Response.text();
      console.error("R2 Upload Error:", responseBody);
      return new Response(
        JSON.stringify({
          error: "Cloudflare R2 upload failed",
          status: r2Response.status,
          details: responseBody,
        }),
        {
          status: r2Response.status,
          headers: { ...corsHeaders, "Content-Type": "application/json" },
        },
      );
    }

    return new Response(
      JSON.stringify({
        message: "File uploaded successfully",
        uploadUrl: getPublicUrl(
          storageTarget.publicBaseUrl,
          normalizedObjectKey,
        ),
        objectKey: normalizedObjectKey,
        signedUrl: resolvedUploadUrl,
      }),
      {
        status: 200,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  } catch (err) {
    console.error("Unexpected Error:", err);
    return new Response(
      JSON.stringify({ error: String(err) }),
      {
        status: 500,
        headers: { ...corsHeaders, "Content-Type": "application/json" },
      },
    );
  }
});
