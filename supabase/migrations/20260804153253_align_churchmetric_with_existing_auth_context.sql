-- profiles_priv_info is the linked project's canonical live authorization
-- source. Prefer its existing caller-scoped helpers before the roles fallback.
create or replace function public.churchmetric_role()
returns text
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(
    nullif(auth.jwt() ->> 'wprole', ''),
    nullif(lower(public.get_my_role()), ''),
    (select context.role_name from private.churchmetric_current_context() context)
  )
$$;

create or replace function public.churchmetric_branch_id()
returns uuid
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(
    nullif(auth.jwt() ->> 'wpbranch_id', '')::uuid,
    public.get_my_branch_id(),
    (select context.branch_id from private.churchmetric_current_context() context)
  )
$$;

revoke all on function public.churchmetric_role() from public, anon;
revoke all on function public.churchmetric_branch_id() from public, anon;
grant execute on function public.churchmetric_role() to authenticated;
grant execute on function public.churchmetric_branch_id() to authenticated;
