-- WPCC Community Phase 0 foundation
-- Non-destructive hardening + community-safe projections + department file visibility.

-- 1) Department attachment visibility.
alter table public.department_attachments
  add column if not exists visibility text not null default 'members';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'department_attachments_visibility_check'
      and conrelid = 'public.department_attachments'::regclass
  ) then
    alter table public.department_attachments
      add constraint department_attachments_visibility_check
      check (visibility in ('members','leaders'));
  end if;
end $$;

create index if not exists department_attachments_branch_department_idx
  on public.department_attachments(branch_id, department_id, created_at desc);

create or replace function public.wpcc_can_view_department(
  target_department_id uuid,
  target_branch_id uuid
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and (
    public.wpcc_can_manage_department_attachment(target_department_id, target_branch_id)
    or exists (
      select 1
      from public.profile_departments pd
      where pd.profile_id = auth.uid()
        and pd.department_id = target_department_id
        and pd.branch_id = target_branch_id
    )
    or exists (
      select 1
      from public.profiles p
      where p.id = auth.uid()
        and p.department_id = target_department_id
        and p.branch_id = target_branch_id
    )
  );
$$;

revoke all on function public.wpcc_can_view_department(uuid, uuid) from public, anon;
grant execute on function public.wpcc_can_view_department(uuid, uuid) to authenticated;

create or replace function public.wpcc_can_read_department_attachment(
  target_department_id uuid,
  target_branch_id uuid,
  target_visibility text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select auth.uid() is not null and (
    public.wpcc_can_manage_department_attachment(target_department_id, target_branch_id)
    or (
      coalesce(target_visibility, 'members') = 'members'
      and public.wpcc_can_view_department(target_department_id, target_branch_id)
    )
  );
$$;

revoke all on function public.wpcc_can_read_department_attachment(uuid, uuid, text) from public, anon;
grant execute on function public.wpcc_can_read_department_attachment(uuid, uuid, text) to authenticated;

drop policy if exists department_attachments_department_read on public.department_attachments;
create policy department_attachments_department_read
on public.department_attachments
for select
to authenticated
using (
  public.wpcc_can_read_department_attachment(department_id, branch_id, visibility)
);

-- 2) Community-safe member and leadership projections.
create or replace function public.community_department_members(
  p_department_id uuid,
  p_search text default null,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table(
  user_id uuid,
  full_name text,
  display_name text,
  avatar text,
  initials text,
  role_name text,
  department_id uuid,
  department_name text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_branch_id uuid;
  v_limit integer := greatest(1, least(coalesce(p_limit, 50), 100));
  v_offset integer := greatest(0, coalesce(p_offset, 0));
begin
  v_branch_id := public.churchmetric_branch_id();

  if v_branch_id is null then
    select p.branch_id into v_branch_id
    from public.profiles p
    where p.id = auth.uid();
  end if;

  if v_branch_id is null or not public.wpcc_can_view_department(p_department_id, v_branch_id) then
    raise exception 'Department access is not permitted' using errcode = '42501';
  end if;

  return query
  with members as (
    select pd.profile_id
    from public.profile_departments pd
    where pd.department_id = p_department_id
      and pd.branch_id = v_branch_id
    union
    select p.id
    from public.profiles p
    where p.department_id = p_department_id
      and p.branch_id = v_branch_id
  )
  select
    p.id,
    p.full_name,
    p.display_name,
    p.avatar,
    coalesce(nullif(p.initials, ''),
      upper(left(coalesce(nullif(p.firstname,''), split_part(p.full_name,' ',1), ''), 1) ||
            left(coalesce(nullif(p.lastname,''), nullif(split_part(p.full_name,' ',2),''), ''), 1))) as initials,
    coalesce(
      (
        select lower(r.rolename)
        from public.roles r
        where r.memberid = p.id
          and coalesce(r.is_active, true)
          and (r.department_id = p_department_id or r.department_id is null)
        order by coalesce(r.is_primary,false) desc, r.assigned_at desc nulls last
        limit 1
      ),
      'member'
    ) as role_name,
    p_department_id,
    d.name
  from members m
  join public.profiles p on p.id = m.profile_id
  join public.departments d on d.id = p_department_id
  where coalesce(nullif(btrim(p_search), ''), '') = ''
     or p.full_name ilike '%' || btrim(p_search) || '%'
     or coalesce(p.display_name,'') ilike '%' || btrim(p_search) || '%'
  order by p.full_name
  limit v_limit offset v_offset;
end;
$$;

revoke all on function public.community_department_members(uuid, text, integer, integer) from public, anon;
grant execute on function public.community_department_members(uuid, text, integer, integer) to authenticated;

create or replace function public.community_public_member_profile(p_profile_id uuid)
returns table(
  user_id uuid,
  full_name text,
  display_name text,
  avatar text,
  initials text,
  phone text,
  departments jsonb
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_allowed boolean;
begin
  select exists (
    select 1
    from (
      select pd.department_id, pd.branch_id
      from public.profile_departments pd
      where pd.profile_id = p_profile_id
      union
      select p.department_id, p.branch_id
      from public.profiles p
      where p.id = p_profile_id and p.department_id is not null
    ) target_depts
    where public.wpcc_can_view_department(target_depts.department_id, target_depts.branch_id)
  ) into v_allowed;

  if not coalesce(v_allowed, false) then
    raise exception 'Member profile access is not permitted' using errcode = '42501';
  end if;

  return query
  select
    p.id,
    p.full_name,
    p.display_name,
    p.avatar,
    coalesce(nullif(p.initials, ''),
      upper(left(coalesce(nullif(p.firstname,''), split_part(p.full_name,' ',1), ''), 1) ||
            left(coalesce(nullif(p.lastname,''), nullif(split_part(p.full_name,' ',2),''), ''), 1))) as initials,
    coalesce(pp.phone_number, pp.phone, p.phone) as phone,
    coalesce((
      select jsonb_agg(jsonb_build_object('id', x.department_id, 'name', d.name) order by d.name)
      from (
        select pd.department_id
        from public.profile_departments pd
        where pd.profile_id = p.id
        union
        select p.department_id where p.department_id is not null
      ) x
      join public.departments d on d.id = x.department_id
    ), '[]'::jsonb) as departments
  from public.profiles p
  left join public.profiles_priv_info pp on pp.id = p.id
  where p.id = p_profile_id;
end;
$$;

revoke all on function public.community_public_member_profile(uuid) from public, anon;
grant execute on function public.community_public_member_profile(uuid) to authenticated;

create or replace function public.community_department_leadership(p_department_id uuid)
returns table(
  user_id uuid,
  full_name text,
  display_name text,
  avatar text,
  initials text,
  title_name text,
  title_code text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_branch_id uuid;
begin
  v_branch_id := public.churchmetric_branch_id();

  if v_branch_id is null then
    select p.branch_id into v_branch_id
    from public.profiles p
    where p.id = auth.uid();
  end if;

  if v_branch_id is null or not public.wpcc_can_view_department(p_department_id, v_branch_id) then
    raise exception 'Department access is not permitted' using errcode = '42501';
  end if;

  return query
  select
    p.id,
    p.full_name,
    p.display_name,
    p.avatar,
    coalesce(nullif(p.initials, ''),
      upper(left(coalesce(nullif(p.firstname,''), split_part(p.full_name,' ',1), ''), 1) ||
            left(coalesce(nullif(p.lastname,''), nullif(split_part(p.full_name,' ',2),''), ''), 1))) as initials,
    lt.name,
    lt.code
  from public.leaders l
  join public.profiles p on p.id = l.user_id
  left join public.leadership_titles lt on lt.id = l.title_id
  where l.department_id = p_department_id
    and l.branch_id = v_branch_id
    and coalesce(l.is_active,true)
  order by l.created_at desc, p.full_name;
end;
$$;

revoke all on function public.community_department_leadership(uuid) from public, anon;
grant execute on function public.community_department_leadership(uuid) to authenticated;

-- 3) Department attendance projections using attendance.created_at as authoritative server check-in time.
create or replace function public.community_department_attendance_events(
  p_department_id uuid,
  p_limit integer default 50,
  p_offset integer default 0
)
returns table(
  event_id uuid,
  title text,
  event_start_at timestamptz,
  event_end_at timestamptz,
  location text,
  present_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_branch_id uuid;
  v_limit integer := greatest(1, least(coalesce(p_limit, 50), 100));
  v_offset integer := greatest(0, coalesce(p_offset, 0));
begin
  v_branch_id := public.churchmetric_branch_id();

  if v_branch_id is null then
    select p.branch_id into v_branch_id
    from public.profiles p
    where p.id = auth.uid();
  end if;

  if v_branch_id is null or not public.wpcc_can_view_department(p_department_id, v_branch_id) then
    raise exception 'Department attendance access is not permitted' using errcode = '42501';
  end if;

  return query
  select
    e.id,
    e.title,
    e.event_start_at,
    e.event_end_at,
    e.location,
    count(a.id) filter (where lower(coalesce(a.status,'')) = 'present') as present_count
  from public.departmental_events e
  left join public.attendance a
    on a.event_id = e.id
   and a.department_id = p_department_id
   and a.branch_id = v_branch_id
  where e.department_id = p_department_id
    and e.branch_id = v_branch_id
  group by e.id, e.title, e.event_start_at, e.event_end_at, e.location
  order by e.event_start_at desc
  limit v_limit offset v_offset;
end;
$$;

revoke all on function public.community_department_attendance_events(uuid, integer, integer) from public, anon;
grant execute on function public.community_department_attendance_events(uuid, integer, integer) to authenticated;

create or replace function public.community_department_event_attendance(
  p_department_id uuid,
  p_event_id uuid
)
returns table(
  user_id uuid,
  full_name text,
  avatar text,
  initials text,
  checked_in_at timestamptz,
  minutes_from_start integer
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_branch_id uuid;
  v_event_start timestamptz;
begin
  select e.branch_id, e.event_start_at
    into v_branch_id, v_event_start
  from public.departmental_events e
  where e.id = p_event_id
    and e.department_id = p_department_id
  limit 1;

  if v_branch_id is null or not public.wpcc_can_view_department(p_department_id, v_branch_id) then
    raise exception 'Department attendance access is not permitted' using errcode = '42501';
  end if;

  return query
  select
    p.id,
    coalesce(nullif(a.fullname,''), p.full_name),
    p.avatar,
    coalesce(nullif(p.initials, ''),
      upper(left(coalesce(nullif(p.firstname,''), split_part(p.full_name,' ',1), ''), 1) ||
            left(coalesce(nullif(p.lastname,''), nullif(split_part(p.full_name,' ',2),''), ''), 1))) as initials,
    (a.created_at at time zone 'UTC') as checked_in_at,
    round(extract(epoch from ((a.created_at at time zone 'UTC') - v_event_start)) / 60.0)::integer as minutes_from_start
  from public.attendance a
  join public.profiles p on p.id = a.user_id
  where a.event_id = p_event_id
    and a.department_id = p_department_id
    and a.branch_id = v_branch_id
    and lower(coalesce(a.status,'')) = 'present'
  order by a.created_at asc, p.full_name;
end;
$$;

revoke all on function public.community_department_event_attendance(uuid, uuid) from public, anon;
grant execute on function public.community_department_event_attendance(uuid, uuid) to authenticated;

-- 4) Harden posts/comments/reactions for the community client.
create or replace function public.wpcc_preserve_post_creator()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if auth.uid() is not null then
      new.created_by := auth.uid();
    end if;
    if auth.uid() is not null then
      new.created_at := now();
    else
      new.created_at := coalesce(new.created_at, now());
    end if;
    new.modified_at := now();
  else
    new.created_by := old.created_by;
    new.created_at := old.created_at;
    if auth.uid() is not null then
      new.modified_by := auth.uid();
    end if;
    new.modified_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists wpcc_posts_preserve_creator on public.posts;
create trigger wpcc_posts_preserve_creator
before insert or update on public.posts
for each row execute function public.wpcc_preserve_post_creator();

drop policy if exists posts_unified_update on public.posts;
create policy posts_unified_update
on public.posts
for update
to authenticated
using (
  public.churchmetric_role() = 'globaladmin'
  or created_by = (select auth.uid())
  or (
    public.churchmetric_role() = 'admin'
    and branch_id = public.churchmetric_branch_id()
  )
)
with check (
  public.churchmetric_role() = 'globaladmin'
  or created_by = (select auth.uid())
  or (
    public.churchmetric_role() = 'admin'
    and branch_id = public.churchmetric_branch_id()
  )
);

create or replace function public.wpcc_set_comment_author()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is not null then
    new.created_by := auth.uid();
    new.created_at := now();
    new.modified_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists wpcc_comments_set_author on public.comments;
create trigger wpcc_comments_set_author
before insert on public.comments
for each row execute function public.wpcc_set_comment_author();

drop policy if exists comments_unified_insert on public.comments;
create policy comments_unified_insert
on public.comments
for insert
to authenticated
with check (
  created_by = (select auth.uid())
  and exists (
    select 1
    from public.posts p
    where p.id = comments.post_id
      and (
        public.churchmetric_role() = 'globaladmin'
        or p.target_type = 'global'
        or p.created_by = (select auth.uid())
        or p.branch_id = public.churchmetric_branch_id()
      )
  )
);

-- Existing rows support one reaction of each type per user/post.
-- Restrict types to the approved devotional reactions without altering existing rows outside the set.
do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname = 'post_reactions_reaction_type_check'
      and conrelid = 'public.post_reactions'::regclass
  ) and not exists (
    select 1 from public.post_reactions
    where reaction_type not in ('amen','helpful','inspired')
  ) then
    alter table public.post_reactions
      add constraint post_reactions_reaction_type_check
      check (reaction_type in ('amen','helpful','inspired'));
  end if;
end $$;

create or replace function public.wpcc_set_reaction_author()
returns trigger
language plpgsql
security invoker
set search_path = ''
as $$
begin
  if auth.uid() is not null then
    new.user_id := auth.uid();
    new.created_at := now();
  end if;
  return new;
end;
$$;

drop trigger if exists wpcc_post_reactions_set_author on public.post_reactions;
create trigger wpcc_post_reactions_set_author
before insert on public.post_reactions
for each row execute function public.wpcc_set_reaction_author();

drop policy if exists post_reactions_select_visible on public.post_reactions;
create policy post_reactions_select_visible
on public.post_reactions
for select
to authenticated
using (
  exists (
    select 1 from public.posts p
    where p.id = post_reactions.post_id
      and (
        public.churchmetric_role() = 'globaladmin'
        or p.target_type = 'global'
        or p.created_by = (select auth.uid())
        or p.branch_id = public.churchmetric_branch_id()
      )
  )
);

drop policy if exists post_reactions_insert_own on public.post_reactions;
create policy post_reactions_insert_own
on public.post_reactions
for insert
to authenticated
with check (
  user_id = (select auth.uid())
  and exists (
    select 1 from public.posts p
    where p.id = post_reactions.post_id
      and (
        public.churchmetric_role() = 'globaladmin'
        or p.target_type = 'global'
        or p.created_by = (select auth.uid())
        or p.branch_id = public.churchmetric_branch_id()
      )
  )
);

drop policy if exists post_reactions_delete_own on public.post_reactions;
create policy post_reactions_delete_own
on public.post_reactions
for delete
to authenticated
using (user_id = (select auth.uid()));

create or replace function public.wpcc_refresh_post_reaction_counts()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_post_id uuid;
begin
  if tg_op = 'DELETE' then
    v_post_id := old.post_id;
  else
    v_post_id := new.post_id;
  end if;
  update public.posts p
  set reaction_counts = coalesce((
    select jsonb_object_agg(x.reaction_type, x.cnt)
    from (
      select pr.reaction_type, count(*)::integer as cnt
      from public.post_reactions pr
      where pr.post_id = v_post_id
      group by pr.reaction_type
    ) x
  ), '{}'::jsonb)
  where p.id = v_post_id;
  return null;
end;
$$;

create or replace function public.wpcc_refresh_post_comment_count()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_post_id uuid;
begin
  if tg_op = 'DELETE' then
    v_post_id := old.post_id;
  else
    v_post_id := new.post_id;
  end if;
  update public.posts p
  set comments_count = (
    select count(*)::integer
    from public.comments c
    where c.post_id = v_post_id
      and not coalesce(c.is_deleted,false)
  )
  where p.id = v_post_id;
  return null;
end;
$$;

drop trigger if exists wpcc_post_reactions_refresh_counts on public.post_reactions;
create trigger wpcc_post_reactions_refresh_counts
after insert or delete on public.post_reactions
for each row execute function public.wpcc_refresh_post_reaction_counts();

drop trigger if exists wpcc_comments_refresh_count on public.comments;
create trigger wpcc_comments_refresh_count
after insert or delete or update of is_deleted on public.comments
for each row execute function public.wpcc_refresh_post_comment_count();

-- Backfill denormalized counters from authoritative rows.
update public.posts p
set reaction_counts = coalesce((
  select jsonb_object_agg(x.reaction_type, x.cnt)
  from (
    select pr.reaction_type, count(*)::integer as cnt
    from public.post_reactions pr
    where pr.post_id = p.id
    group by pr.reaction_type
  ) x
), '{}'::jsonb),
comments_count = (
  select count(*)::integer
  from public.comments c
  where c.post_id = p.id and not coalesce(c.is_deleted,false)
);
