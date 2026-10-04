export function getRequiredEnv(name: string): string {
  const value = Deno.env.get(name)?.trim();
  if (!value) throw new Error(`Missing required environment variable: ${name}`);
  return value;
}
export function getSupabaseRuntimeUrl(): string {
  const configured = Deno.env.get("PROJECT_URL")?.trim() || getRequiredEnv("SUPABASE_URL");
  return /^https?:\/\/(127\.0\.0\.1|localhost)(:\d+)?\/?$/i.test(configured)
    ? "http://kong:8000"
    : configured.replace(/\/$/, "");
}

export function getSupabaseServiceKey(): string {
  return Deno.env.get("SUPABASE_SECRET_KEY")?.trim() ||
    Deno.env.get("SERVICE_ROLE_KEY")?.trim() ||
    getRequiredEnv("SUPABASE_SERVICE_ROLE_KEY");
}

export function normalizeEmail(value: unknown): string | null {
  if (typeof value !== "string") return null;
  const email = value.trim().toLowerCase();
  if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) return null;
  return email;
}

export function maskEmail(value: string): string {
  const email = normalizeEmail(value);
  if (!email) return "";
  const [local, domain] = email.split("@");
  const visible = local.slice(0, Math.min(2, local.length));
  return `${visible}${"*".repeat(Math.max(3, local.length - visible.length))}@${domain}`;
}

type SendEmailArgs = {
  to: string;
  subject: string;
  html: string;
  text?: string;
};

export async function sendEmailThroughTransport(args: SendEmailArgs) {
  const apiKey = getRequiredEnv("RESEND_API_KEY");
  const fromEmail = getRequiredEnv("RESEND_FROM_EMAIL");
  const fromName = Deno.env.get("RESEND_FROM_NAME")?.trim() || "WPCC Community";
  const response = await fetch("https://api.resend.com/emails", {
    method: "POST",
    headers: {
      Authorization: `Bearer ${apiKey}`,
      "Content-Type": "application/json",
    },
    body: JSON.stringify({
      from: `${fromName} <${fromEmail}>`,
      to: [args.to],
      subject: args.subject,
      html: args.html,
      ...(args.text ? { text: args.text } : {}),
    }),
  });

  if (!response.ok) {
    const detail = await response.text().catch(() => "");
    throw new Error(`Email transport failed (${response.status}): ${detail.slice(0, 300)}`);
  }

  return await response.json().catch(() => ({}));
}
