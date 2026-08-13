-- Roles are authoritative in public.roles. Remove the obsolete profile-role
-- cache and the two triggers whose only purpose was maintaining that cache.
drop trigger if exists roles_sync_trigger on public.roles;
drop trigger if exists trg_role_sync on public.roles;

drop function if exists public.roles_to_profiles_sync();
drop function if exists public.sync_user_role();

create or replace function public.sync_dept_leader_role_for_user(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  dept_role record;
  profile_full_name text;
begin
  if target_user_id is null then
    return;
  end if;

  select id, rolename
  into dept_role
  from public.roletypes
  where rolename = 'dept_leader'
  limit 1;

  select full_name
  into profile_full_name
  from public.profiles
  where id = target_user_id;

  update public.roles
  set is_active = false
  where memberid = target_user_id
    and rolename = 'dept_leader';

  insert into public.roles (
    memberid,
    full_name,
    roleid,
    rolename,
    leadership_title_id,
    scope_type,
    branch_id,
    department_id,
    is_primary,
    is_active,
    assigned_at
  )
  select
    l.user_id,
    coalesce(profile_full_name, l.user_id::text),
    dept_role.id,
    dept_role.rolename,
    l.title_id,
    'department',
    l.branch_id,
    l.department_id,
    false,
    true,
    coalesce(l.start_date, l.created_at::timestamptz, now())
  from public.leaders l
  where l.user_id = target_user_id
    and l.is_active = true
  on conflict do nothing;
end;
$$;

create or replace function public.sync_global_admin_role_for_user(target_user_id uuid)
returns void
language plpgsql
security definer
set search_path to 'public'
as $$
declare
  global_role record;
  profile_full_name text;
begin
  if target_user_id is null then
    return;
  end if;

  select id, rolename
  into global_role
  from public.roletypes
  where rolename = 'globaladmin'
  limit 1;

  select full_name
  into profile_full_name
  from public.profiles
  where id = target_user_id;

  update public.roles
  set is_active = false
  where memberid = target_user_id
    and rolename = 'globaladmin'
    and is_primary = false;

  insert into public.roles (
    memberid,
    full_name,
    roleid,
    rolename,
    leadership_title_id,
    scope_type,
    branch_id,
    department_id,
    is_primary,
    is_active,
    assigned_at
  )
  select
    g.id,
    coalesce(profile_full_name, g.id::text),
    global_role.id,
    global_role.rolename,
    g.title_id,
    'global',
    null,
    null,
    false,
    g.is_active,
    g.assigned_at
  from public.global_admins g
  where g.id = target_user_id
    and g.is_active = true
    and g.title_id is not null
  on conflict do nothing;
end;
$$;

drop function if exists public.refresh_user_role_cache(uuid);

-- PostgreSQL cannot infer a partial unique index for an ON CONFLICT target
-- unless the matching predicate is repeated in every statement. These full
-- indexes preserve multiple NULL source IDs while making the existing upserts
-- valid and idempotent.
drop index if exists public.departmental_events_recurring_unique_idx;
drop index if exists public.branch_events_recurring_unique_idx;
drop index if exists public.global_events_recurring_unique_idx;

create unique index departmental_events_recurring_unique_idx
  on public.departmental_events (source_recurring_event_id, event_start_at);

create unique index branch_events_recurring_unique_idx
  on public.branch_events (source_recurring_event_id, event_start_at);

create unique index global_events_recurring_unique_idx
  on public.global_events (source_recurring_event_id, event_start_at);
