export type TransportEmailPayload = {
  to: string | string[];
  subject: string;
  html?: string;
  text?: string;
  from?: string;
  replyTo?: string;
  idempotencyKey?: string;
};

export function getRequiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

export function getSupabaseRuntimeUrl(): string {
  const configured = Deno.env.get("PROJECT_URL")?.trim() || getRequiredEnv("SUPABASE_URL");
  return /^https?:\/\/(127\.0\.0\.1|localhost)(:\d+)?\/?$/i.test(configured)
    ? "http://kong:8000"
    : configured.replace(/\/$/, "");
}

export function getString(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const trimmed = value.trim();
  return trimmed.length > 0 ? trimmed : null;
}

export function normalizeEmail(value: unknown): string | null {
  const email = getString(value)?.toLowerCase();
  if (!email) return null;
  return isValidEmail(email) ? email : null;
}

export function getEmailList(value: unknown): string[] | null {
  if (typeof value === "string") {
    const single = normalizeEmail(value);
    return single ? [single] : null;
  }

  if (!Array.isArray(value) || value.length === 0) {
    return null;
  }

  const emails = value
    .map((item) => normalizeEmail(item))
    .filter((item): item is string => Boolean(item));

  return emails.length > 0 ? emails : null;
}

export function isValidEmail(email: string): boolean {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}

export function maskEmail(email: string): string {
  const trimmed = email.trim();
  const at = trimmed.indexOf("@");
  if (at <= 1) return "***";

  const local = trimmed.slice(0, at);
  const domain = trimmed.slice(at + 1);
  const dot = domain.indexOf(".");
  const domainName = dot === -1 ? domain : domain.slice(0, dot);
  const tld = dot === -1 ? "" : domain.slice(dot + 1);

  const localMasked =
    local.length <= 2
      ? `${local[0]}*`
      : `${local.slice(0, 2)}${"*".repeat(Math.min(12, Math.max(4, local.length - 2)))}`;

  const domainMasked =
    domainName.length <= 1
      ? `${domainName}*`
      : `${domainName[0]}${"*".repeat(Math.min(12, Math.max(4, domainName.length - 1)))}`;

  const tldMasked = tld
    ? (tld.length <= 2 ? tld : `${tld[0]}${"*".repeat(Math.min(8, tld.length - 1))}`)
    : "";

  return `${localMasked}@${domainMasked}${tldMasked ? `.${tldMasked}` : ""}`;
}

export async function sendEmailThroughTransport(payload: TransportEmailPayload) {
  const resendApiKey = getRequiredEnv("RESEND_API_KEY");
  const defaultFrom = getRequiredEnv("RESEND_FROM_EMAIL");
  const from = getString(payload.from) ?? defaultFrom;
  const replyTo = getString(payload.replyTo);
  const to = Array.isArray(payload.to) ? payload.to : [payload.to];

  if (to.some((email) => !isValidEmail(email))) {
    throw new Error("Invalid recipient email address");
  }

  if (!isValidEmail(from)) {
    throw new Error("Invalid from email address");
  }

  if (replyTo && !isValidEmail(replyTo)) {
    throw new Error("Invalid replyTo email address");
  }

  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `Bearer ${resendApiKey}`,
      ...(payload.idempotencyKey
        ? { "Idempotency-Key": payload.idempotencyKey }
        : {}),
    },
    body: JSON.stringify({
      from,
      to,
      subject: payload.subject,
      html: payload.html ?? undefined,
      text: payload.text ?? undefined,
      reply_to: replyTo ?? undefined,
    }),
  });

  const responseData = await response.json().catch(() => null);
  if (!response.ok) {
    console.error("Resend transport failed:", responseData);
    throw new Error("Failed to dispatch email");
  }

  return responseData;
}
