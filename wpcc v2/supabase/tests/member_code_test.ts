import { normalizeMembershipCode } from "../functions/_shared/member-login.ts";
Deno.test("numeric membership aliases share one canonical lookup/rate-limit key", () => {
  for (const [input, expected] of [["123", "0123"], [" 123 ", "0123"], ["0123", "0123"], ["ABC", "ABC"], ["12", "12"], ["12345", "12345"]]) {
    if (normalizeMembershipCode(input) !== expected) throw new Error(`Unexpected normalization for ${input}`);
  }
});
