alter function public."Generate_WPCC_Membership_code"() rename to "generate_WPCC_member_code";

revoke all on function public."generate_WPCC_member_code"() from public, anon, authenticated;
grant execute on function public."generate_WPCC_member_code"() to service_role;
