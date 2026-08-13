create or replace function public.profiles_prevent_forbidden_inserts()
returns trigger
language plpgsql
security invoker
set search_path=''
as $$
begin
  if current_user in ('postgres','service_role') then return new; end if;
  if tg_op='INSERT' and new.membership_code is not null then
    raise exception 'Direct INSERTs setting restricted profile columns are forbidden unless executed by the trusted backend.';
  end if;
  return new;
end $$;

create or replace function public.profiles_prevent_forbidden_updates()
returns trigger
language plpgsql
security invoker
set search_path=''
as $$
begin
  if current_user in ('postgres','service_role') then return new; end if;
  if tg_op='UPDATE' and (
    old.email is distinct from new.email or
    old.membership_code is distinct from new.membership_code or
    old.department_id is distinct from new.department_id
  ) then
    raise exception 'Direct UPDATEs modifying restricted profile columns are forbidden unless executed by the trusted backend.';
  end if;
  return new;
end $$;

revoke all on function public.profiles_prevent_forbidden_inserts() from public,anon,authenticated;
revoke all on function public.profiles_prevent_forbidden_updates() from public,anon,authenticated;
