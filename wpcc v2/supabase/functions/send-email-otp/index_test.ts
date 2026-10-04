let handler: (request: Request) => Promise<Response>;
const serve = Deno.serve;
Deno.serve = ((callback: typeof handler) => { handler = callback; }) as typeof Deno.serve;
await import("./index.ts");
Deno.serve = serve;

function assert(value: unknown, message: string): asserts value {
  if (!value) throw new Error(message);
}

Deno.test("membership OTP sends the generated code without exposing email or token", async () => {
  const previousFetch = globalThis.fetch;
  const settings = {
    PROJECT_URL: "https://supabase.test",
    SUPABASE_SECRET_KEY: "test-service-key",
    RESEND_API_KEY: "test-mail-key",
    RESEND_FROM_EMAIL: "test@example.org",
  };
  const previous = Object.fromEntries(Object.keys(settings).map(key => [key, Deno.env.get(key)]));
  for (const [key, value] of Object.entries(settings)) Deno.env.set(key, value);
  let sent = false;
  globalThis.fetch = async (input, init) => {
    const url = new URL(input instanceof Request ? input.url : String(input));
    const body = init?.body ? JSON.parse(String(init.body)) : {};
    const reply = (value: unknown) => Promise.resolve(Response.json(value));
    if (url.pathname === "/rest/v1/email_rate_limits") return reply(null);
    if (url.pathname === "/rest/v1/membershipcode") return reply({ memberid: "test-member" });
    if (url.pathname === "/rest/v1/profiles_priv_info") return reply({ email: "member@example.org" });
    if (url.pathname === "/rest/v1/rpc/request_email_login_otp") return reply(true);
    if (url.pathname === "/auth/v1/admin/generate_link") {
      assert(body.email === "member@example.org", "Wrong recipient lookup");
      return reply({
        email_otp: "123456", action_link: "https://unused.test",
        hashed_token: "unused", verification_type: "magiclink", redirect_to: "",
      });
    }
    if (url.hostname === "api.resend.com") {
      assert(body.text.includes("123456"), "Generated code was not included");
      assert(!body.html.includes("<a"), "Email still contains a magic link");
      assert(body.to[0] === "member@example.org", "Wrong email destination");
      sent = true;
      return reply({ id: "test-message" });
    }
    throw new Error("Unexpected network request: " + url.pathname);
  };
  try {
    const response = await handler(new Request("https://local.test", {
      method: "POST", headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ membership_code: "WPCC-123" }),
    }));
    const text = await response.text();
    assert(response.status === 200 && sent, "Code delivery failed: " + text);
    assert(!text.includes("member@example.org") && !text.includes("123456"),
      "Response exposes member email or OTP");
  } finally {
    globalThis.fetch = previousFetch;
    for (const key of Object.keys(settings)) {
      if (previous[key] === undefined) Deno.env.delete(key);
      else Deno.env.set(key, previous[key]!);
    }
  }
});
