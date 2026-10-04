import type { SupabaseClient } from "jsr:@supabase/supabase-js@2";
export function normalizeMembershipCode(value: string): string {
  const code = value.trim();
  return /^\d{3}$/.test(code) ? `0${code}` : code;
}

export async function getEmailForMembershipCode(
  supabaseAdmin: SupabaseClient,
  membershipCode: string,
) {
  const canonicalMembershipCode = normalizeMembershipCode(membershipCode);

  const { data: membershipRow, error: membershipError } = await supabaseAdmin
    .from("membershipcode")
    .select("memberid")
    .eq("membershipcode", canonicalMembershipCode)
    .maybeSingle();

  if (membershipError) throw membershipError;

  const memberId = membershipRow?.memberid?.toString().trim() ?? "";
  if (memberId.length > 0) {
    const { data: profileById, error: profileByIdError } = await supabaseAdmin
      .from("profiles_priv_info")
      .select("email")
      .eq("id", memberId)
      .maybeSingle();

    if (profileByIdError) throw profileByIdError;

    const emailById = profileById?.email?.toString().trim() ?? "";
    if (emailById.length > 0) {
      return emailById;
    }

    const { data: publicProfileById, error: publicProfileByIdError } =
      await supabaseAdmin
        .from("profiles")
        .select("email")
        .eq("id", memberId)
        .maybeSingle();

    if (publicProfileByIdError) throw publicProfileByIdError;

    const publicEmailById =
      publicProfileById?.email?.toString().trim() ?? "";
    if (publicEmailById.length > 0) {
      return publicEmailById;
    }
  }

  const { data, error } = await supabaseAdmin
    .from("profiles_priv_info")
    .select("email")
    .eq("membership_code", canonicalMembershipCode)
    .maybeSingle();

  if (error) throw error;

  const privateEmail = data?.email?.toString().trim() ?? "";
  if (privateEmail.length > 0) {
    return privateEmail;
  }

  const { data: publicProfile, error: publicProfileError } = await supabaseAdmin
    .from("profiles")
    .select("email")
    .eq("membership_code", canonicalMembershipCode)
    .maybeSingle();

  if (publicProfileError) throw publicProfileError;

  return publicProfile?.email?.toString().trim() ?? null;
}

