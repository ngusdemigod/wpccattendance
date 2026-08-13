alter function public.churchmetric_allocate_membership_code() rename to "Generate_WPCC_Membership_code";

revoke all on function public."Generate_WPCC_Membership_code"() from public,anon,authenticated;
grant execute on function public."Generate_WPCC_Membership_code"() to service_role;
