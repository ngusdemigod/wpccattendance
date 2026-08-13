-- Fresh JWTs in the linked project currently omit the legacy top-level WPCC
-- role claims. Resolve only the signed-in caller's context from the existing
-- role assignment tables so ChurchMetric does not depend on stale JWTs.
create schema if not exists private;
revoke all on schema private from public, anon;
grant usage on schema private to authenticated;

create or replace function private.churchmetric_current_context()
returns table(role_name text, branch_id uuid, department_id uuid)
language sql
stable
security definer
set search_path = ''
as $$
  select
    lower(r.rolename),
    coalesce(r.branch_id, w.branch_id),
    coalesce(r.department_id, w.department_id)
  from public.roles r
  left join public.workers w on w.user_id = r.memberid
  where r.memberid = auth.uid()
    and auth.uid() is not null
    and r.is_active is true
  order by r.is_primary desc, r.assigned_at desc
  limit 1
$$;

revoke all on function private.churchmetric_current_context() from public, anon;
grant execute on function private.churchmetric_current_context() to authenticated;

create or replace function public.churchmetric_role()
returns text
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(
    nullif(auth.jwt() ->> 'wprole', ''),
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
    (select context.branch_id from private.churchmetric_current_context() context)
  )
$$;

create or replace function public.churchmetric_admin_context()
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  select coalesce(
    (
      select jsonb_build_object(
        'role', context.role_name,
        'branch_id', context.branch_id,
        'department_id', context.department_id
      )
      from private.churchmetric_current_context() context
    ),
    '{}'::jsonb
  )
$$;

revoke all on function public.churchmetric_role() from public, anon;
revoke all on function public.churchmetric_branch_id() from public, anon;
revoke all on function public.churchmetric_admin_context() from public, anon;
grant execute on function public.churchmetric_role() to authenticated;
grant execute on function public.churchmetric_branch_id() to authenticated;
grant execute on function public.churchmetric_admin_context() to authenticated;

-- Existing legacy policies read only JWT claims. These additive policies make
-- the dashboard's existing source tables follow the same live role context.
create policy churchmetric_profiles_admin_select
on public.profiles for select to authenticated
using (public.churchmetric_can_read_branch(branch_id));

create policy churchmetric_attendance_admin_select
on public.attendance for select to authenticated
using (public.churchmetric_can_read_branch(branch_id));

create policy churchmetric_departments_authenticated_select
on public.departments for select to authenticated
using (auth.uid() is not null);
