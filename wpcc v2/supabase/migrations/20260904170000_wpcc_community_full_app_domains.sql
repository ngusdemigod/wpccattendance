-- WPCC Community full app domains
-- Additive extension for the approved v76 Flutter web/PWA pages.
-- Existing profile/event/announcement/department architecture remains authoritative.

-- -----------------------------------------------------------------------------
-- Department profile presentation fields
-- -----------------------------------------------------------------------------
alter table public.departments
  add column if not exists cover_url text,
  add column if not exists avatar_url text,
  add column if not exists updated_at timestamptz not null default now();

-- -----------------------------------------------------------------------------
-- Event presentation category used by the approved UI filters.
-- -----------------------------------------------------------------------------
do $$
declare
  t text;
begin
  foreach t in array array['departmental_events','branch_events','global_events'] loop
    execute format('alter table public.%I add column if not exists event_type text not null default %L', t, 'service');
    if not exists (
      select 1 from pg_constraint
      where conname = t || '_event_type_check'
        and conrelid = format('public.%I', t)::regclass
    ) then
      execute format(
        'alter table public.%I add constraint %I check (event_type in (''service'',''meeting'',''rehearsal'',''training'',''special'',''other''))',
        t, t || '_event_type_check'
      );
    end if;
  end loop;
end $$;

-- Add event_type to the existing unified visible event projection without changing
-- the established source tables.
create or replace view public.my_events
with (security_invoker = true)
as
select
  e.id as event_id,
  e.title,
  e.description,
  'department'::text as event_scope,
  'departmental_events'::text as source_table,
  e.branch_id,
  e.department_id,
  e.event_start_at,
  e.event_end_at,
  e.featured_url as featured_image,
  e.location,
  e.latitude,
  e.longitude,
  e.is_active,
  e.created_by,
  e.created_at,
  e.event_type
from public.departmental_events e
where e.closed_at is null
union all
select
  e.id,
  e.title,
  e.description,
  'branch'::text,
  'branch_events'::text,
  e.branch_id,
  null::uuid,
  e.event_start_at,
  e.event_end_at,
  e.featured_url,
  e.location,
  e.latitude,
  e.longitude,
  e.is_active,
  e.created_by,
  e.created_at,
  e.event_type
from public.branch_events e
where e.closed_at is null
union all
select
  e.id,
  e.title,
  e.description,
  'global'::text,
  'global_events'::text,
  null::uuid,
  null::uuid,
  e.event_start_at,
  e.event_end_at,
  e.featured_url,
  e.location,
  e.latitude,
  e.longitude,
  e.is_active,
  e.created_by,
  e.created_at,
  e.event_type
from public.global_events e
where e.closed_at is null;

grant select on public.my_events to authenticated;

-- -----------------------------------------------------------------------------
-- Devotional discriminator. Existing posts remain community posts.
-- -----------------------------------------------------------------------------
alter table public.posts
  add column if not exists post_kind text not null default 'community';

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='posts_post_kind_check'
      and conrelid='public.posts'::regclass
  ) then
    alter table public.posts
      add constraint posts_post_kind_check
      check (post_kind in ('community','devotional'));
  end if;
end $$;

create index if not exists posts_kind_created_idx
  on public.posts(post_kind, created_at desc)
  where coalesce(is_archived,false)=false;

-- Keep comment display identity server-authored.
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
    select p.full_name into new."commentor name"
    from public.profiles p
    where p.id = auth.uid();
  end if;
  return new;
end;
$$;

-- -----------------------------------------------------------------------------
-- Member-origin Query path using the existing worker_queries domain.
-- -----------------------------------------------------------------------------
alter table public.worker_queries
  add column if not exists origin text not null default 'leadership',
  add column if not exists branch_id uuid references public.branches(id);

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='worker_queries_origin_check'
      and conrelid='public.worker_queries'::regclass
  ) then
    alter table public.worker_queries
      add constraint worker_queries_origin_check
      check (origin in ('leadership','member'));
  end if;
end $$;

update public.worker_queries q
set branch_id = p.branch_id
from public.profiles p
where q.branch_id is null and p.id=q.user_id;

create index if not exists worker_queries_branch_origin_idx
  on public.worker_queries(branch_id, origin, opened_at desc);

create or replace function public.submit_my_query(
  p_title text,
  p_details text
)
returns public.worker_queries
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_branch uuid;
  v_row public.worker_queries;
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode='42501';
  end if;
  if length(btrim(coalesce(p_title,''))) < 3 then
    raise exception 'Query title is required';
  end if;
  if length(btrim(coalesce(p_details,''))) < 10 then
    raise exception 'Please describe what you need help with';
  end if;

  select p.branch_id into v_branch
  from public.profiles p where p.id=v_uid;

  insert into public.worker_queries(
    user_id, title, details, status,
    raised_by_user_id, raised_by_name,
    requires_response, requires_acknowledgement,
    category, origin, branch_id,
    opened_at, updated_at
  ) values (
    v_uid, btrim(p_title), btrim(p_details), 'open',
    v_uid, 'Member query',
    true, false,
    'Other', 'member', v_branch,
    now(), now()
  ) returning * into v_row;

  return v_row;
end;
$$;
revoke all on function public.submit_my_query(text,text) from public, anon;
grant execute on function public.submit_my_query(text,text) to authenticated;

-- Existing privileged query handlers can read/update member-origin rows they are
-- already authorized to query/assign.
drop policy if exists worker_queries_privileged_select on public.worker_queries;
create policy worker_queries_privileged_select
on public.worker_queries for select to authenticated
using (public.wpcc_can_assign_worker_query(user_id));

drop policy if exists worker_queries_privileged_update on public.worker_queries;
create policy worker_queries_privileged_update
on public.worker_queries for update to authenticated
using (public.wpcc_can_assign_worker_query(user_id))
with check (public.wpcc_can_assign_worker_query(user_id));

-- -----------------------------------------------------------------------------
-- Community department projections and authorized mutations.
-- -----------------------------------------------------------------------------
create or replace function public.community_departments(p_filter text default 'all')
returns table(
  department_id uuid,
  name text,
  description text,
  cover_url text,
  avatar_url text,
  member_count bigint,
  is_member boolean,
  is_leading boolean,
  branch_id uuid
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_branch uuid;
  v_filter text := lower(coalesce(nullif(btrim(p_filter),''),'all'));
begin
  if v_uid is null then
    raise exception 'Authentication required' using errcode='42501';
  end if;
  v_branch := public.churchmetric_branch_id();
  if v_branch is null then
    select p.branch_id into v_branch from public.profiles p where p.id=v_uid;
  end if;

  return query
  select
    d.id,
    d.name,
    d.description,
    d.cover_url,
    d.avatar_url,
    (
      select count(distinct x.profile_id)
      from (
        select pd.profile_id
        from public.profile_departments pd
        where pd.department_id=d.id and (v_branch is null or pd.branch_id=v_branch)
        union
        select p.id
        from public.profiles p
        where p.department_id=d.id and (v_branch is null or p.branch_id=v_branch)
      ) x
    )::bigint,
    (
      exists(select 1 from public.profile_departments pd where pd.profile_id=v_uid and pd.department_id=d.id and (v_branch is null or pd.branch_id=v_branch))
      or exists(select 1 from public.profiles p where p.id=v_uid and p.department_id=d.id and (v_branch is null or p.branch_id=v_branch))
    ),
    exists(
      select 1 from public.leaders l
      where l.user_id=v_uid and l.department_id=d.id and coalesce(l.is_active,true)
        and (v_branch is null or l.branch_id=v_branch)
    ),
    v_branch
  from public.departments d
  where
    v_filter='all'
    or (v_filter in ('mine','my teams','my_teams') and (
      exists(select 1 from public.profile_departments pd where pd.profile_id=v_uid and pd.department_id=d.id and (v_branch is null or pd.branch_id=v_branch))
      or exists(select 1 from public.profiles p where p.id=v_uid and p.department_id=d.id and (v_branch is null or p.branch_id=v_branch))
    ))
    or (v_filter in ('leading','lead') and exists(
      select 1 from public.leaders l
      where l.user_id=v_uid and l.department_id=d.id and coalesce(l.is_active,true)
        and (v_branch is null or l.branch_id=v_branch)
    ))
  order by d.name;
end;
$$;
revoke all on function public.community_departments(text) from public, anon;
grant execute on function public.community_departments(text) to authenticated;

create or replace function public.community_department_context(p_department_id uuid)
returns table(
  department_id uuid,
  name text,
  description text,
  cover_url text,
  avatar_url text,
  branch_id uuid,
  member_count bigint,
  is_member boolean,
  is_leading boolean,
  can_manage boolean
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_uid uuid := auth.uid();
  v_branch uuid;
begin
  if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
  v_branch := public.churchmetric_branch_id();
  if v_branch is null then select p.branch_id into v_branch from public.profiles p where p.id=v_uid; end if;

  return query
  select
    d.id,d.name,d.description,d.cover_url,d.avatar_url,v_branch,
    (
      select count(distinct x.profile_id)
      from (
        select pd.profile_id from public.profile_departments pd where pd.department_id=d.id and (v_branch is null or pd.branch_id=v_branch)
        union
        select p.id from public.profiles p where p.department_id=d.id and (v_branch is null or p.branch_id=v_branch)
      ) x
    )::bigint,
    (
      exists(select 1 from public.profile_departments pd where pd.profile_id=v_uid and pd.department_id=d.id and (v_branch is null or pd.branch_id=v_branch))
      or exists(select 1 from public.profiles p where p.id=v_uid and p.department_id=d.id and (v_branch is null or p.branch_id=v_branch))
    ),
    exists(select 1 from public.leaders l where l.user_id=v_uid and l.department_id=d.id and coalesce(l.is_active,true) and (v_branch is null or l.branch_id=v_branch)),
    case when v_branch is null then false else public.can_manage_department_scope_content(v_branch,d.id) end
  from public.departments d
  where d.id=p_department_id;
end;
$$;
revoke all on function public.community_department_context(uuid) from public, anon;
grant execute on function public.community_department_context(uuid) to authenticated;

create or replace function public.community_update_department_profile(
  p_department_id uuid,
  p_name text,
  p_description text,
  p_cover_url text,
  p_avatar_url text
)
returns public.departments
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_branch uuid;
  v_row public.departments;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  v_branch := public.churchmetric_branch_id();
  if v_branch is null then select p.branch_id into v_branch from public.profiles p where p.id=auth.uid(); end if;
  if v_branch is null or not public.can_manage_department_scope_content(v_branch,p_department_id) then
    raise exception 'Department profile management is not permitted' using errcode='42501';
  end if;
  if length(btrim(coalesce(p_name,''))) < 2 then raise exception 'Department name is required'; end if;
  if length(coalesce(p_description,'')) > 500 then raise exception 'Description is too long'; end if;

  update public.departments d
  set name=btrim(p_name), description=nullif(btrim(coalesce(p_description,'')),''),
      cover_url=nullif(btrim(coalesce(p_cover_url,'')),''),
      avatar_url=nullif(btrim(coalesce(p_avatar_url,'')),''), updated_at=now()
  where d.id=p_department_id
  returning * into v_row;
  return v_row;
end;
$$;
revoke all on function public.community_update_department_profile(uuid,text,text,text,text) from public, anon;
grant execute on function public.community_update_department_profile(uuid,text,text,text,text) to authenticated;

create or replace function public.community_post_department_announcement(
  p_department_id uuid,
  p_title text,
  p_content text,
  p_media_url text default null
)
returns public.announcements
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_branch uuid;
  v_row public.announcements;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  v_branch := public.churchmetric_branch_id();
  if v_branch is null then select p.branch_id into v_branch from public.profiles p where p.id=auth.uid(); end if;
  if v_branch is null or not public.can_manage_department_scope_content(v_branch,p_department_id) then
    raise exception 'Announcement publishing is not permitted' using errcode='42501';
  end if;
  if length(btrim(coalesce(p_title,''))) < 3 then raise exception 'Announcement title is required'; end if;
  if length(btrim(coalesce(p_content,''))) < 3 then raise exception 'Announcement message is required'; end if;

  insert into public.announcements(
    title,content,scope,branch_id,department_id,created_by,created_at,
    mediaurl,hasmedia,is_pinned,allow_comments
  ) values (
    btrim(p_title),btrim(p_content),'department',v_branch,p_department_id,auth.uid(),now(),
    nullif(btrim(coalesce(p_media_url,'')),''),
    nullif(btrim(coalesce(p_media_url,'')),'') is not null,false,false
  ) returning * into v_row;
  return v_row;
end;
$$;
revoke all on function public.community_post_department_announcement(uuid,text,text,text) from public, anon;
grant execute on function public.community_post_department_announcement(uuid,text,text,text) to authenticated;

create or replace function public.community_create_department_event(
  p_department_id uuid,
  p_event_type text,
  p_title text,
  p_description text,
  p_start_at timestamptz,
  p_end_at timestamptz,
  p_featured_url text,
  p_location text,
  p_latitude double precision default null,
  p_longitude double precision default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_branch uuid;
  v_result jsonb;
  v_ids uuid[];
  v_type text := lower(coalesce(nullif(btrim(p_event_type),''),'service'));
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if v_type not in ('service','meeting','rehearsal','training','special','other') then raise exception 'Unsupported event type'; end if;
  v_branch := public.churchmetric_branch_id();
  if v_branch is null then select p.branch_id into v_branch from public.profiles p where p.id=auth.uid(); end if;
  if v_branch is null or not public.can_manage_department_scope_content(v_branch,p_department_id) then
    raise exception 'Department event creation is not permitted' using errcode='42501';
  end if;

  v_result := public.create_scoped_event(
    'department',v_branch,array[p_department_id],
    p_title,p_description,p_start_at,p_end_at,p_featured_url,p_location,p_latitude,p_longitude,
    auth.uid()::text
  );
  select coalesce(array_agg(value::uuid),array[]::uuid[])
  into v_ids
  from jsonb_array_elements_text(v_result->'created_ids');
  update public.departmental_events set event_type=v_type, updated_at=now() where id=any(v_ids);
  return v_result || jsonb_build_object('event_type',v_type);
end;
$$;
revoke all on function public.community_create_department_event(uuid,text,text,text,timestamptz,timestamptz,text,text,double precision,double precision) from public, anon;
grant execute on function public.community_create_department_event(uuid,text,text,text,timestamptz,timestamptz,text,text,double precision,double precision) to authenticated;

create or replace function public.community_update_attachment_visibility(
  p_attachment_id uuid,
  p_visibility text
)
returns public.department_attachments
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.department_attachments;
  v_visibility text := lower(coalesce(p_visibility,''));
begin
  if v_visibility not in ('members','leaders') then raise exception 'Invalid visibility'; end if;
  select * into v_row from public.department_attachments where id=p_attachment_id;
  if v_row.id is null then raise exception 'Attachment not found'; end if;
  if not public.wpcc_can_manage_department_attachment(v_row.department_id,v_row.branch_id) then
    raise exception 'File management is not permitted' using errcode='42501';
  end if;
  update public.department_attachments
  set visibility=v_visibility
  where id=p_attachment_id
  returning * into v_row;
  return v_row;
end;
$$;
revoke all on function public.community_update_attachment_visibility(uuid,text) from public, anon;
grant execute on function public.community_update_attachment_visibility(uuid,text) to authenticated;

-- Event attendance projection that preserves the existing attendance authorization
-- model: privileged attendance readers see scoped roster, ordinary members see self.
create or replace function public.community_event_attendance(p_event_id uuid)
returns table(
  user_id uuid,
  full_name text,
  avatar text,
  initials text,
  status text,
  checked_in_at timestamptz,
  clocked_out_at timestamptz,
  minutes_from_start integer,
  expected_count bigint,
  present_count bigint
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_scope text;
  v_branch uuid;
  v_department uuid;
  v_start timestamptz;
  v_can_roster boolean := false;
  v_expected bigint := 0;
  v_present bigint := 0;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;

  select 'department',e.branch_id,e.department_id,e.event_start_at
    into v_scope,v_branch,v_department,v_start
  from public.departmental_events e where e.id=p_event_id and e.closed_at is null;
  if v_scope is null then
    select 'branch',e.branch_id,null::uuid,e.event_start_at into v_scope,v_branch,v_department,v_start
    from public.branch_events e where e.id=p_event_id and e.closed_at is null;
  end if;
  if v_scope is null then
    select 'global',null::uuid,null::uuid,e.event_start_at into v_scope,v_branch,v_department,v_start
    from public.global_events e where e.id=p_event_id and e.closed_at is null;
  end if;
  if v_scope is null then raise exception 'Event not found'; end if;

  if v_scope='department' and not public.can_read_department_scope_event(v_branch,v_department) then raise exception 'Event access is not permitted' using errcode='42501'; end if;
  if v_scope='branch' and not public.can_read_branch_scope_event(v_branch) then raise exception 'Event access is not permitted' using errcode='42501'; end if;

  select coalesce(s.is_global_admin,false)
      or (v_scope='branch' and coalesce(s.can_read_branch_attendance,false) and s.branch_id=v_branch)
      or (v_scope='department' and (
          (coalesce(s.can_read_department_attendance,false) and s.branch_id=v_branch and s.department_id=v_department)
          or (coalesce(s.can_read_branch_attendance,false) and s.branch_id=v_branch)
      ))
  into v_can_roster
  from public.current_access_scope() s;

  if v_scope='department' then
    select count(distinct x.id) into v_expected from (
      select pd.profile_id id from public.profile_departments pd where pd.branch_id=v_branch and pd.department_id=v_department
      union select p.id from public.profiles p where p.branch_id=v_branch and p.department_id=v_department
    ) x;
  elsif v_scope='branch' then
    select count(*) into v_expected from public.profiles p where p.branch_id=v_branch;
  else
    select count(*) into v_expected from public.profiles p;
  end if;

  select count(*) into v_present from public.attendance a where a.event_id=p_event_id and lower(coalesce(a.status,''))='present';

  return query
  select
    p.id,
    coalesce(nullif(a.fullname,''),p.full_name),
    p.avatar,
    coalesce(nullif(p.initials,''),upper(left(coalesce(nullif(p.firstname,''),split_part(p.full_name,' ',1),''),1)||left(coalesce(nullif(p.lastname,''),nullif(split_part(p.full_name,' ',2),''),''),1))),
    a.status,
    (a.created_at at time zone 'UTC'),
    a.clockout,
    round(extract(epoch from ((a.created_at at time zone 'UTC')-v_start))/60.0)::integer,
    v_expected,
    v_present
  from public.attendance a
  join public.profiles p on p.id=a.user_id
  where a.event_id=p_event_id
    and (v_can_roster or a.user_id=auth.uid())
  order by a.created_at asc;
end;
$$;
revoke all on function public.community_event_attendance(uuid) from public, anon;
grant execute on function public.community_event_attendance(uuid) to authenticated;

create or replace function public.community_event_meta(p_event_id uuid)
returns table(
  expected_count bigint,
  present_count bigint,
  host_name text,
  host_avatar text,
  host_initials text
)
language plpgsql
stable
security definer
set search_path = ''
as $$
declare
  v_scope text;
  v_branch uuid;
  v_department uuid;
  v_creator text;
  v_expected bigint := 0;
  v_present bigint := 0;
  v_host uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  select 'department',e.branch_id,e.department_id,e.created_by into v_scope,v_branch,v_department,v_creator from public.departmental_events e where e.id=p_event_id and e.closed_at is null;
  if v_scope is null then select 'branch',e.branch_id,null::uuid,e.created_by into v_scope,v_branch,v_department,v_creator from public.branch_events e where e.id=p_event_id and e.closed_at is null; end if;
  if v_scope is null then select 'global',null::uuid,null::uuid,e.created_by into v_scope,v_branch,v_department,v_creator from public.global_events e where e.id=p_event_id and e.closed_at is null; end if;
  if v_scope is null then raise exception 'Event not found'; end if;
  if v_scope='department' and not public.can_read_department_scope_event(v_branch,v_department) then raise exception 'Event access is not permitted' using errcode='42501'; end if;
  if v_scope='branch' and not public.can_read_branch_scope_event(v_branch) then raise exception 'Event access is not permitted' using errcode='42501'; end if;

  if v_scope='department' then
    select count(distinct x.id) into v_expected from (
      select pd.profile_id id from public.profile_departments pd where pd.branch_id=v_branch and pd.department_id=v_department
      union select p.id from public.profiles p where p.branch_id=v_branch and p.department_id=v_department
    ) x;
  elsif v_scope='branch' then select count(*) into v_expected from public.profiles p where p.branch_id=v_branch;
  else select count(*) into v_expected from public.profiles p;
  end if;
  select count(*) into v_present from public.attendance a where a.event_id=p_event_id and lower(coalesce(a.status,''))='present';

  begin v_host := v_creator::uuid; exception when invalid_text_representation then v_host := null; end;

  return query
  select v_expected,v_present,
         coalesce(p.full_name,'Unavailable'),
         p.avatar,
         coalesce(nullif(p.initials,''),upper(left(coalesce(nullif(p.firstname,''),split_part(p.full_name,' ',1),''),1)||left(coalesce(nullif(p.lastname,''),nullif(split_part(p.full_name,' ',2),''),''),1)))
  from (select 1) one
  left join public.profiles p on p.id=v_host;
end;
$$;
revoke all on function public.community_event_meta(uuid) from public, anon;
grant execute on function public.community_event_meta(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Give / Paystack domain (previously absent).
-- -----------------------------------------------------------------------------
create table if not exists public.church_bank_accounts (
  id uuid primary key default gen_random_uuid(),
  scope text not null default 'global',
  branch_id uuid references public.branches(id) on delete cascade,
  department_id uuid references public.departments(id) on delete cascade,
  wallet_name text,
  bank_name text not null,
  account_name text not null,
  account_number text not null,
  purpose text,
  display_order integer not null default 0,
  style_variant text not null default 'dark',
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint church_bank_accounts_scope_check check (scope in ('global','branch','department')),
  constraint church_bank_accounts_style_check check (style_variant in ('dark','light','warm')),
  constraint church_bank_accounts_scope_target_check check (
    (scope='global' and branch_id is null and department_id is null)
    or (scope='branch' and branch_id is not null and department_id is null)
    or (scope='department' and branch_id is not null and department_id is not null)
  ),
  constraint church_bank_accounts_number_check check (account_number ~ '^[0-9]{6,20}$')
);
create unique index if not exists church_bank_accounts_scope_number_unique
  on public.church_bank_accounts(
    scope,
    coalesce(branch_id,'00000000-0000-0000-0000-000000000000'::uuid),
    coalesce(department_id,'00000000-0000-0000-0000-000000000000'::uuid),
    account_number
  );
create index if not exists church_bank_accounts_visible_idx on public.church_bank_accounts(scope,branch_id,department_id,is_active,display_order);

create table if not exists public.giving_projects (
  id uuid primary key default gen_random_uuid(),
  scope text not null default 'global',
  branch_id uuid references public.branches(id) on delete cascade,
  department_id uuid references public.departments(id) on delete cascade,
  title text not null,
  description text,
  image_url text,
  status text not null default 'draft',
  target_amount_kobo bigint,
  starts_at timestamptz,
  ends_at timestamptz,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint giving_projects_scope_check check (scope in ('global','branch','department')),
  constraint giving_projects_status_check check (status in ('draft','active','closed')),
  constraint giving_projects_amount_check check (target_amount_kobo is null or target_amount_kobo > 0),
  constraint giving_projects_scope_target_check check (
    (scope='global' and branch_id is null and department_id is null)
    or (scope='branch' and branch_id is not null and department_id is null)
    or (scope='department' and branch_id is not null and department_id is not null)
  )
);
create index if not exists giving_projects_visible_idx on public.giving_projects(scope,branch_id,department_id,status,created_at desc);

create table if not exists private.paystack_authorizations (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete set null,
  customer_code text,
  authorization_code text not null unique,
  email text not null,
  card_type text,
  bank text,
  last4 text,
  exp_month text,
  exp_year text,
  signature text,
  reusable boolean not null default false,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create index if not exists paystack_authorizations_profile_idx on private.paystack_authorizations(profile_id,is_active,updated_at desc);

create table if not exists public.recurring_giving_mandates (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete set null,
  giving_type text not null,
  project_id uuid references public.giving_projects(id) on delete set null,
  amount_kobo bigint not null,
  rule_keys text[] not null,
  timezone text not null default 'Africa/Lagos',
  local_charge_time time not null default '08:00:00',
  authorization_id uuid not null references private.paystack_authorizations(id),
  status text not null default 'active',
  next_charge_at timestamptz,
  last_charge_at timestamptz,
  consent_at timestamptz not null default now(),
  cancelled_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint recurring_giving_amount_check check (amount_kobo > 0),
  constraint recurring_giving_type_check check (giving_type in ('offering','tithe','prophet_offering','project','auto_give')),
  constraint recurring_giving_status_check check (status in ('active','paused','cancelled')),
  constraint recurring_giving_rules_check check (cardinality(rule_keys) > 0)
);
create index if not exists recurring_giving_due_idx on public.recurring_giving_mandates(status,next_charge_at) where status='active';
create index if not exists recurring_giving_profile_idx on public.recurring_giving_mandates(profile_id,created_at desc);

create table if not exists public.giving_transactions (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null references public.profiles(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete set null,
  giving_type text not null,
  project_id uuid references public.giving_projects(id) on delete set null,
  mandate_id uuid references public.recurring_giving_mandates(id) on delete set null,
  amount_kobo bigint not null,
  currency text not null default 'NGN',
  internal_reference text not null unique,
  paystack_reference text unique,
  status text not null default 'initialized',
  payment_channel text,
  source_summary text,
  receipt_type text not null default 'PDF receipt',
  provider_response jsonb not null default '{}'::jsonb,
  initiated_at timestamptz not null default now(),
  paid_at timestamptz,
  failed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint giving_transactions_amount_check check (amount_kobo > 0),
  constraint giving_transactions_type_check check (giving_type in ('offering','tithe','prophet_offering','project','auto_give')),
  constraint giving_transactions_status_check check (status in ('initialized','pending','successful','failed','cancelled')),
  constraint giving_transactions_currency_check check (currency='NGN')
);
create index if not exists giving_transactions_profile_idx on public.giving_transactions(profile_id,created_at desc);
create index if not exists giving_transactions_status_idx on public.giving_transactions(status,created_at desc);

-- scope helpers
create or replace function public.wpcc_can_read_giving_scope(p_scope text,p_branch uuid,p_department uuid)
returns boolean language sql stable security definer set search_path=''
as $$
select auth.uid() is not null and (
  p_scope='global'
  or (p_scope='branch' and p_branch=public.churchmetric_branch_id())
  or (p_scope='department' and public.wpcc_can_view_department(p_department,p_branch))
  or public.churchmetric_role()='globaladmin'
);
$$;
revoke all on function public.wpcc_can_read_giving_scope(text,uuid,uuid) from public,anon;
grant execute on function public.wpcc_can_read_giving_scope(text,uuid,uuid) to authenticated;

create or replace function public.wpcc_can_manage_giving_scope(p_scope text,p_branch uuid,p_department uuid)
returns boolean language sql stable security definer set search_path=''
as $$
select auth.uid() is not null and (
  public.churchmetric_role()='globaladmin'
  or (p_scope='branch' and p_branch=public.churchmetric_branch_id() and public.churchmetric_role()='admin')
  or (p_scope='department' and public.wpcc_can_manage_department_attachment(p_department,p_branch))
);
$$;
revoke all on function public.wpcc_can_manage_giving_scope(text,uuid,uuid) from public,anon;
grant execute on function public.wpcc_can_manage_giving_scope(text,uuid,uuid) to authenticated;

alter table public.church_bank_accounts enable row level security;
alter table public.giving_projects enable row level security;
alter table public.giving_transactions enable row level security;
alter table public.recurring_giving_mandates enable row level security;

drop policy if exists church_bank_accounts_read on public.church_bank_accounts;
create policy church_bank_accounts_read on public.church_bank_accounts for select to authenticated
using (is_active and public.wpcc_can_read_giving_scope(scope,branch_id,department_id));
drop policy if exists church_bank_accounts_manage on public.church_bank_accounts;
create policy church_bank_accounts_manage on public.church_bank_accounts for all to authenticated
using (public.wpcc_can_manage_giving_scope(scope,branch_id,department_id))
with check (public.wpcc_can_manage_giving_scope(scope,branch_id,department_id));

drop policy if exists giving_projects_read on public.giving_projects;
create policy giving_projects_read on public.giving_projects for select to authenticated
using (status='active' and public.wpcc_can_read_giving_scope(scope,branch_id,department_id));
drop policy if exists giving_projects_manage on public.giving_projects;
create policy giving_projects_manage on public.giving_projects for all to authenticated
using (public.wpcc_can_manage_giving_scope(scope,branch_id,department_id))
with check (public.wpcc_can_manage_giving_scope(scope,branch_id,department_id));

drop policy if exists giving_transactions_read_own on public.giving_transactions;
create policy giving_transactions_read_own on public.giving_transactions for select to authenticated
using (profile_id=auth.uid());

drop policy if exists recurring_giving_read_own on public.recurring_giving_mandates;
create policy recurring_giving_read_own on public.recurring_giving_mandates for select to authenticated
using (profile_id=auth.uid());

-- Department New Wallet uses the same account domain as Give rather than a
-- second wallet table.
create or replace function public.community_create_department_wallet(
  p_department_id uuid,
  p_wallet_name text,
  p_bank_name text,
  p_account_number text,
  p_account_name text,
  p_purpose text default null
)
returns public.church_bank_accounts
language plpgsql security definer set search_path=''
as $$
declare
  v_branch uuid;
  v_row public.church_bank_accounts;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  v_branch:=public.churchmetric_branch_id();
  if v_branch is null then select p.branch_id into v_branch from public.profiles p where p.id=auth.uid(); end if;
  if v_branch is null or not public.wpcc_can_manage_department_attachment(p_department_id,v_branch) then
    raise exception 'Department wallet management is not permitted' using errcode='42501';
  end if;
  if length(btrim(coalesce(p_wallet_name,'')))<2 then raise exception 'Wallet name is required'; end if;
  if length(btrim(coalesce(p_bank_name,'')))<2 then raise exception 'Bank name is required'; end if;
  if btrim(coalesce(p_account_number,'')) !~ '^[0-9]{6,20}$' then raise exception 'Enter a valid account number'; end if;
  if length(btrim(coalesce(p_account_name,'')))<2 then raise exception 'Account holder is required'; end if;

  insert into public.church_bank_accounts(
    scope,branch_id,department_id,wallet_name,bank_name,account_name,account_number,purpose,
    style_variant,created_by,created_at,updated_at
  ) values (
    'department',v_branch,p_department_id,btrim(p_wallet_name),btrim(p_bank_name),btrim(p_account_name),btrim(p_account_number),nullif(btrim(coalesce(p_purpose,'')),''),
    'warm',auth.uid(),now(),now()
  ) returning * into v_row;
  return v_row;
exception when unique_violation then
  raise exception 'This account is already configured for the department';
end;
$$;
revoke all on function public.community_create_department_wallet(uuid,text,text,text,text,text) from public,anon;
grant execute on function public.community_create_department_wallet(uuid,text,text,text,text,text) to authenticated;

-- Safe payment-method projection. Authorization codes stay in private schema.
create or replace function public.my_saved_payment_methods()
returns table(
  id uuid,
  bank text,
  last4 text,
  card_type text,
  exp_month text,
  exp_year text
)
language sql stable security definer set search_path=''
as $$
select a.id,a.bank,a.last4,a.card_type,a.exp_month,a.exp_year
from private.paystack_authorizations a
where a.profile_id=auth.uid() and a.is_active and a.reusable
order by a.updated_at desc;
$$;
revoke all on function public.my_saved_payment_methods() from public,anon;
grant execute on function public.my_saved_payment_methods() to authenticated;

-- Determine the next supported automatic charge on the server. Special services
-- are sourced from upcoming branch/global events explicitly marked event_type=special.
create or replace function private.next_auto_give_charge(
  p_profile_id uuid,
  p_branch_id uuid,
  p_rule_keys text[],
  p_timezone text,
  p_local_time time,
  p_from timestamptz default now()
)
returns timestamptz
language plpgsql stable set search_path=''
as $$
declare
  v_local_now timestamp := p_from at time zone p_timezone;
  v_date date;
  v_candidate timestamptz;
  v_best timestamptz;
  v_dow int;
  i int;
begin
  for i in 0..21 loop
    v_date := v_local_now::date + i;
    v_dow := extract(isodow from v_date)::int;
    if (('sunday_service'=any(p_rule_keys) and v_dow=7)
        or ('wednesday'=any(p_rule_keys) and v_dow=3)
        or ('thursday'=any(p_rule_keys) and v_dow=4)) then
      v_candidate := make_timestamptz(
        extract(year from v_date)::int,extract(month from v_date)::int,extract(day from v_date)::int,
        extract(hour from p_local_time)::int,extract(minute from p_local_time)::int,extract(second from p_local_time),p_timezone
      );
      if v_candidate>p_from and (v_best is null or v_candidate<v_best) then v_best:=v_candidate; end if;
    end if;
  end loop;

  if 'special'=any(p_rule_keys) then
    select min(x.event_start_at) into v_candidate
    from (
      select g.event_start_at from public.global_events g where g.closed_at is null and g.event_type='special' and g.event_start_at>p_from
      union all
      select b.event_start_at from public.branch_events b where b.closed_at is null and b.event_type='special' and b.branch_id=p_branch_id and b.event_start_at>p_from
    ) x;
    if v_candidate is not null and (v_best is null or v_candidate<v_best) then v_best:=v_candidate; end if;
  end if;
  return v_best;
end;
$$;

create or replace function public.create_auto_give_mandate(
  p_amount_kobo bigint,
  p_giving_type text,
  p_project_id uuid,
  p_rule_keys text[],
  p_authorization_id uuid,
  p_timezone text default 'Africa/Lagos',
  p_local_charge_time time default '08:00:00'
)
returns public.recurring_giving_mandates
language plpgsql security definer set search_path=''
as $$
declare
  v_uid uuid:=auth.uid();
  v_branch uuid;
  v_row public.recurring_giving_mandates;
  v_next timestamptz;
begin
  if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if p_amount_kobo<100 then raise exception 'Amount is too small'; end if;
  if p_giving_type not in ('offering','tithe','prophet_offering','project','auto_give') then raise exception 'Invalid giving type'; end if;
  if p_rule_keys is null or cardinality(p_rule_keys)=0 then raise exception 'Select at least one recurring event day'; end if;
  if exists(select 1 from unnest(p_rule_keys) x where x not in ('sunday_service','wednesday','thursday','special')) then raise exception 'Unsupported recurring rule'; end if;
  if not exists(select 1 from private.paystack_authorizations a where a.id=p_authorization_id and a.profile_id=v_uid and a.is_active and a.reusable) then
    raise exception 'Saved payment account is not available';
  end if;
  select p.branch_id into v_branch from public.profiles p where p.id=v_uid;
  if p_giving_type='project' and (p_project_id is null or not exists(select 1 from public.giving_projects gp where gp.id=p_project_id and gp.status='active' and public.wpcc_can_read_giving_scope(gp.scope,gp.branch_id,gp.department_id))) then
    raise exception 'Giving project is not available';
  end if;
  v_next:=private.next_auto_give_charge(v_uid,v_branch,p_rule_keys,p_timezone,p_local_charge_time,now());
  if v_next is null then raise exception 'No upcoming charge can be scheduled from the selected rules'; end if;

  insert into public.recurring_giving_mandates(
    profile_id,branch_id,giving_type,project_id,amount_kobo,rule_keys,timezone,local_charge_time,
    authorization_id,status,next_charge_at,consent_at,created_at,updated_at
  ) values (
    v_uid,v_branch,p_giving_type,p_project_id,p_amount_kobo,p_rule_keys,p_timezone,p_local_charge_time,
    p_authorization_id,'active',v_next,now(),now(),now()
  ) returning * into v_row;
  return v_row;
end;
$$;
revoke all on function public.create_auto_give_mandate(bigint,text,uuid,text[],uuid,text,time) from public,anon;
grant execute on function public.create_auto_give_mandate(bigint,text,uuid,text[],uuid,text,time) to authenticated;

create or replace function public.cancel_auto_give_mandate(p_mandate_id uuid)
returns public.recurring_giving_mandates
language plpgsql security definer set search_path=''
as $$
declare v_row public.recurring_giving_mandates;
begin
  update public.recurring_giving_mandates
  set status='cancelled',cancelled_at=now(),next_charge_at=null,updated_at=now()
  where id=p_mandate_id and profile_id=auth.uid() and status<>'cancelled'
  returning * into v_row;
  if v_row.id is null then raise exception 'Mandate not found'; end if;
  return v_row;
end;
$$;
revoke all on function public.cancel_auto_give_mandate(uuid) from public,anon;
grant execute on function public.cancel_auto_give_mandate(uuid) to authenticated;

-- -----------------------------------------------------------------------------
-- Public non-sensitive WPCC asset bucket paths for department profile and
-- announcement media. Files with restricted visibility remain in private R2.
-- -----------------------------------------------------------------------------
drop policy if exists wpcc_public_read on storage.objects;
create policy wpcc_public_read on storage.objects for select to public
using (bucket_id='wpcc');

drop policy if exists wpcc_department_asset_insert on storage.objects;
create policy wpcc_department_asset_insert on storage.objects for insert to authenticated
with check (
  bucket_id='wpcc'
  and (storage.foldername(name))[1] in ('departments','announcements')
  and array_length(storage.foldername(name),1)>=3
  and public.can_manage_department_scope_content(
    ((storage.foldername(name))[2])::uuid,
    ((storage.foldername(name))[3])::uuid
  )
);

drop policy if exists wpcc_department_asset_update on storage.objects;
create policy wpcc_department_asset_update on storage.objects for update to authenticated
using (
  bucket_id='wpcc'
  and (storage.foldername(name))[1] in ('departments','announcements')
  and array_length(storage.foldername(name),1)>=3
  and public.can_manage_department_scope_content(((storage.foldername(name))[2])::uuid,((storage.foldername(name))[3])::uuid)
)
with check (
  bucket_id='wpcc'
  and (storage.foldername(name))[1] in ('departments','announcements')
  and array_length(storage.foldername(name),1)>=3
  and public.can_manage_department_scope_content(((storage.foldername(name))[2])::uuid,((storage.foldername(name))[3])::uuid)
);

drop policy if exists wpcc_department_asset_delete on storage.objects;
create policy wpcc_department_asset_delete on storage.objects for delete to authenticated
using (
  bucket_id='wpcc'
  and (storage.foldername(name))[1] in ('departments','announcements')
  and array_length(storage.foldername(name),1)>=3
  and public.can_manage_department_scope_content(((storage.foldername(name))[2])::uuid,((storage.foldername(name))[3])::uuid)
);
