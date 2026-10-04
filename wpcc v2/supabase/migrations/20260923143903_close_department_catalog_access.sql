-- Department detail access follows approved membership and existing admin scope.
begin;
set local lock_timeout='5s';
do $policies$
declare pol record;
begin
  for pol in select policyname from pg_policies
    where schemaname='public' and tablename='departments' and cmd='SELECT'
  loop
    execute format('drop policy %I on public.departments',pol.policyname);
  end loop;
end;
$policies$;
revoke all on public.departments from public,anon;
grant select on public.departments to authenticated,service_role;
create policy departments_members_and_managers_read on public.departments
for select to authenticated
using (public.wpcc_can_view_department(id, public.get_my_branch_id()));

-- These legacy helpers referenced profiles.role, which no longer exists.
-- The canonical helper reads the protected private authority field.
create or replace function public.get_current_user_role()
returns text language sql stable security definer set search_path=''
as $role$ select public.get_my_role(); $role$;
create or replace function public.get_user_role()
returns text language sql stable security definer set search_path=''
as $role$ select public.get_my_role(); $role$;

do $check$
begin
  if has_table_privilege('anon','public.departments','SELECT') then
    raise exception 'Anonymous department access remains';
  end if;
  if exists(select 1 from pg_policies where schemaname='public'
    and tablename='departments' and (qual='true' or 'public'=any(roles))) then
    raise exception 'Broad department read policy remains';
  end if;
end;
$check$;
-- A signed-in identity with no membership must see no department records.
set local request.jwt.claims='{"sub":"10000000-0000-0000-0000-000000000099","role":"authenticated"}';
set local role authenticated;
do $nonmember$
begin
  if exists(select 1 from public.departments) then
    raise exception 'Nonmember can read department details';
  end if;
  perform public.get_current_user_role();
  perform public.get_user_role();
end;
$nonmember$;
reset role;
notify pgrst,'reload schema';
commit;

