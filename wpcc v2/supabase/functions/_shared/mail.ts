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
