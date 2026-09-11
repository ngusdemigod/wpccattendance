-- WPCC Community Prayer Alerts foundation
-- Server-authoritative scheduling, push subscriptions and prayer sessions.
-- ISO weekday convention: 1=Monday ... 7=Sunday.

create table if not exists public.prayer_alerts (
  id uuid primary key default gen_random_uuid(),
  created_by uuid not null references auth.users(id) on delete cascade,
  scope text not null default 'personal',
  user_id uuid references public.profiles(id) on delete cascade,
  branch_id uuid references public.branches(id) on delete cascade,
  department_id uuid references public.departments(id) on delete cascade,
  title text not null,
  description text,
  timezone text not null default 'Africa/Lagos',
  local_time time without time zone not null,
  days_of_week smallint[] not null default array[1,2,3,4,5,6,7]::smallint[],
  starts_on date,
  ends_on date,
  duration_seconds integer,
  audio_url text,
  audio_title text,
  audio_source text,
  push_title text,
  push_body text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint prayer_alerts_scope_check check (scope in ('personal','department','branch','global')),
  constraint prayer_alerts_days_check check (
    cardinality(days_of_week) between 1 and 7
    and days_of_week <@ array[1,2,3,4,5,6,7]::smallint[]
  ),
  constraint prayer_alerts_duration_check check (duration_seconds is null or duration_seconds > 0),
  constraint prayer_alerts_date_range_check check (ends_on is null or starts_on is null or ends_on >= starts_on),
  constraint prayer_alerts_scope_targets_check check (
    (scope='personal' and user_id is not null and branch_id is null and department_id is null)
    or (scope='department' and user_id is null and branch_id is not null and department_id is not null)
    or (scope='branch' and user_id is null and branch_id is not null and department_id is null)
    or (scope='global' and user_id is null and branch_id is null and department_id is null)
  )
);

create index if not exists prayer_alerts_user_active_idx
  on public.prayer_alerts(user_id, is_active, local_time)
  where scope='personal';
create index if not exists prayer_alerts_department_active_idx
  on public.prayer_alerts(branch_id, department_id, is_active, local_time)
  where scope='department';
create index if not exists prayer_alerts_branch_active_idx
  on public.prayer_alerts(branch_id, is_active, local_time)
  where scope='branch';

create table if not exists public.prayer_alert_occurrences (
  id uuid primary key default gen_random_uuid(),
  prayer_alert_id uuid not null references public.prayer_alerts(id) on delete cascade,
  scheduled_for timestamptz not null,
  local_scheduled_for timestamp without time zone not null,
  status text not null default 'scheduled',
  processing_started_at timestamptz,
  sent_at timestamptz,
  cancelled_at timestamptz,
  failure_reason text,
  created_at timestamptz not null default now(),
  constraint prayer_alert_occurrences_status_check check (status in ('scheduled','processing','sent','cancelled','failed')),
  constraint prayer_alert_occurrences_unique unique (prayer_alert_id, scheduled_for)
);

create index if not exists prayer_alert_occurrences_due_idx
  on public.prayer_alert_occurrences(status, scheduled_for)
  where status in ('scheduled','processing');

create table if not exists public.push_subscriptions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  endpoint text not null,
  p256dh_key text not null,
  auth_key text not null,
  device_name text,
  platform text,
  user_agent text,
  is_active boolean not null default true,
  last_seen_at timestamptz not null default now(),
  last_success_at timestamptz,
  last_failure_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint push_subscriptions_endpoint_unique unique(endpoint)
);

create index if not exists push_subscriptions_user_active_idx
  on public.push_subscriptions(user_id, is_active);

create table if not exists public.prayer_alert_deliveries (
  id uuid primary key default gen_random_uuid(),
  occurrence_id uuid not null references public.prayer_alert_occurrences(id) on delete cascade,
  alert_id uuid not null references public.prayer_alerts(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  subscription_id uuid references public.push_subscriptions(id) on delete set null,
  status text not null default 'pending',
  provider_message_id text,
  attempt_count integer not null default 0,
  sent_at timestamptz,
  opened_at timestamptz,
  failure_code text,
  created_at timestamptz not null default now(),
  constraint prayer_alert_deliveries_status_check check (status in ('pending','processing','sent','failed','opened','cancelled')),
  constraint prayer_alert_deliveries_attempt_check check (attempt_count >= 0),
  constraint prayer_alert_deliveries_unique unique(occurrence_id, subscription_id)
);

create index if not exists prayer_alert_deliveries_occurrence_status_idx
  on public.prayer_alert_deliveries(occurrence_id, status);
create index if not exists prayer_alert_deliveries_user_idx
  on public.prayer_alert_deliveries(user_id, created_at desc);

create table if not exists public.prayer_sessions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  prayer_alert_id uuid references public.prayer_alerts(id) on delete set null,
  occurrence_id uuid references public.prayer_alert_occurrences(id) on delete set null,
  started_at timestamptz not null default now(),
  ended_at timestamptz,
  duration_seconds integer,
  target_duration_seconds integer,
  completion_status text not null default 'active',
  started_from text not null default 'app',
  created_at timestamptz not null default now(),
  constraint prayer_sessions_completion_check check (completion_status in ('active','completed','abandoned')),
  constraint prayer_sessions_source_check check (started_from in ('push','app','manual')),
  constraint prayer_sessions_duration_check check (duration_seconds is null or duration_seconds >= 0),
  constraint prayer_sessions_target_check check (target_duration_seconds is null or target_duration_seconds > 0),
  constraint prayer_sessions_end_check check (ended_at is null or ended_at >= started_at)
);

create index if not exists prayer_sessions_user_started_idx
  on public.prayer_sessions(user_id, started_at desc);
create unique index if not exists prayer_sessions_one_active_per_user_idx
  on public.prayer_sessions(user_id)
  where completion_status='active' and ended_at is null;

-- Server-owned timestamps and identity.
create or replace function public.wpcc_prayer_alert_before_write()
returns trigger
language plpgsql
security invoker
set search_path=''
as $$
begin
  if tg_op='INSERT' then
    new.created_at := now();
    new.updated_at := now();
    if auth.uid() is not null then
      new.created_by := auth.uid();
      if new.scope='personal' then
        new.user_id := auth.uid();
      end if;
    end if;
  else
    new.created_at := old.created_at;
    new.created_by := old.created_by;
    new.updated_at := now();
    if old.scope='personal' then
      new.user_id := old.user_id;
    end if;
  end if;
  return new;
end;
$$;

drop trigger if exists wpcc_prayer_alert_before_write on public.prayer_alerts;
create trigger wpcc_prayer_alert_before_write
before insert or update on public.prayer_alerts
for each row execute function public.wpcc_prayer_alert_before_write();

create or replace function public.wpcc_push_subscription_before_write()
returns trigger
language plpgsql
security invoker
set search_path=''
as $$
begin
  if auth.uid() is not null then
    new.user_id := auth.uid();
  end if;
  if tg_op='INSERT' then
    new.created_at := now();
  else
    new.created_at := old.created_at;
  end if;
  new.updated_at := now();
  new.last_seen_at := now();
  return new;
end;
$$;

drop trigger if exists wpcc_push_subscription_before_write on public.push_subscriptions;
create trigger wpcc_push_subscription_before_write
before insert or update on public.push_subscriptions
for each row execute function public.wpcc_push_subscription_before_write();

-- Authorization helpers.
create or replace function public.wpcc_can_manage_prayer_alert(
  p_scope text,
  p_user_id uuid,
  p_branch_id uuid,
  p_department_id uuid
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select auth.uid() is not null and case p_scope
    when 'personal' then p_user_id = auth.uid()
    when 'department' then (
      public.churchmetric_role() = 'globaladmin'
      or (public.churchmetric_role() = 'admin' and p_branch_id = public.churchmetric_branch_id())
      or exists (
        select 1 from public.leaders l
        where l.user_id=auth.uid()
          and l.department_id=p_department_id
          and l.branch_id=p_branch_id
          and coalesce(l.is_active,true)
      )
    )
    when 'branch' then (
      public.churchmetric_role() = 'globaladmin'
      or (public.churchmetric_role() = 'admin' and p_branch_id = public.churchmetric_branch_id())
    )
    when 'global' then public.churchmetric_role() = 'globaladmin'
    else false
  end;
$$;

revoke all on function public.wpcc_can_manage_prayer_alert(text,uuid,uuid,uuid) from public,anon;
grant execute on function public.wpcc_can_manage_prayer_alert(text,uuid,uuid,uuid) to authenticated;

create or replace function public.wpcc_can_read_prayer_alert(
  p_scope text,
  p_user_id uuid,
  p_branch_id uuid,
  p_department_id uuid
)
returns boolean
language sql
stable
security definer
set search_path=''
as $$
  select auth.uid() is not null and case p_scope
    when 'personal' then p_user_id = auth.uid()
    when 'department' then public.wpcc_can_view_department(p_department_id,p_branch_id)
    when 'branch' then (
      public.churchmetric_role()='globaladmin'
      or p_branch_id=public.churchmetric_branch_id()
      or exists (select 1 from public.profiles p where p.id=auth.uid() and p.branch_id=p_branch_id)
    )
    when 'global' then true
    else false
  end;
$$;

revoke all on function public.wpcc_can_read_prayer_alert(text,uuid,uuid,uuid) from public,anon;
grant execute on function public.wpcc_can_read_prayer_alert(text,uuid,uuid,uuid) to authenticated;

alter table public.prayer_alerts enable row level security;
alter table public.prayer_alert_occurrences enable row level security;
alter table public.push_subscriptions enable row level security;
alter table public.prayer_alert_deliveries enable row level security;
alter table public.prayer_sessions enable row level security;

create policy prayer_alerts_select_visible on public.prayer_alerts
for select to authenticated
using (public.wpcc_can_read_prayer_alert(scope,user_id,branch_id,department_id));

create policy prayer_alerts_insert_authorized on public.prayer_alerts
for insert to authenticated
with check (public.wpcc_can_manage_prayer_alert(scope,user_id,branch_id,department_id));

create policy prayer_alerts_update_authorized on public.prayer_alerts
for update to authenticated
using (public.wpcc_can_manage_prayer_alert(scope,user_id,branch_id,department_id))
with check (public.wpcc_can_manage_prayer_alert(scope,user_id,branch_id,department_id));

create policy prayer_alerts_delete_authorized on public.prayer_alerts
for delete to authenticated
using (public.wpcc_can_manage_prayer_alert(scope,user_id,branch_id,department_id));

create policy prayer_occurrences_select_visible on public.prayer_alert_occurrences
for select to authenticated
using (exists (
  select 1 from public.prayer_alerts a
  where a.id=prayer_alert_occurrences.prayer_alert_id
    and public.wpcc_can_read_prayer_alert(a.scope,a.user_id,a.branch_id,a.department_id)
));

create policy push_subscriptions_select_own on public.push_subscriptions
for select to authenticated using (user_id=(select auth.uid()));
create policy push_subscriptions_insert_own on public.push_subscriptions
for insert to authenticated with check (user_id=(select auth.uid()));
create policy push_subscriptions_update_own on public.push_subscriptions
for update to authenticated using (user_id=(select auth.uid())) with check (user_id=(select auth.uid()));
create policy push_subscriptions_delete_own on public.push_subscriptions
for delete to authenticated using (user_id=(select auth.uid()));

create policy prayer_deliveries_select_own on public.prayer_alert_deliveries
for select to authenticated using (user_id=(select auth.uid()));

create policy prayer_sessions_select_own on public.prayer_sessions
for select to authenticated using (user_id=(select auth.uid()));

-- Prevent client direct write paths for occurrences, deliveries and sessions.
revoke insert,update,delete on public.prayer_alert_occurrences from authenticated;
revoke insert,update,delete on public.prayer_alert_deliveries from authenticated;
revoke insert,update,delete on public.prayer_sessions from authenticated;

-- RPC: create/update an alert using scheduling preferences only. All timestamps remain server generated.
create or replace function public.save_prayer_alert(
  p_id uuid,
  p_scope text,
  p_title text,
  p_description text,
  p_timezone text,
  p_local_time time,
  p_days_of_week smallint[],
  p_starts_on date,
  p_ends_on date,
  p_duration_seconds integer,
  p_audio_url text,
  p_audio_title text,
  p_audio_source text,
  p_push_title text,
  p_push_body text,
  p_is_active boolean,
  p_branch_id uuid default null,
  p_department_id uuid default null
)
returns public.prayer_alerts
language plpgsql
security invoker
set search_path=''
as $$
declare
  v_row public.prayer_alerts;
  v_user_id uuid;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if p_scope not in ('personal','department','branch','global') then raise exception 'Invalid alert scope'; end if;
  if coalesce(nullif(btrim(p_title),''),'')='' then raise exception 'Title is required'; end if;
  if p_timezone is null or p_timezone not in (select name from pg_timezone_names) then raise exception 'Invalid timezone'; end if;
  if p_days_of_week is null or cardinality(p_days_of_week)=0 or not (p_days_of_week <@ array[1,2,3,4,5,6,7]::smallint[]) then raise exception 'Invalid repeat days'; end if;

  v_user_id := case when p_scope='personal' then auth.uid() else null end;

  if p_scope='personal' then
    p_branch_id := null; p_department_id := null;
  elsif p_scope='department' then
    if p_branch_id is null or p_department_id is null then raise exception 'Department alerts require branch and department'; end if;
  elsif p_scope='branch' then
    if p_branch_id is null then raise exception 'Branch alerts require branch'; end if;
    p_department_id := null;
  else
    p_branch_id := null; p_department_id := null;
  end if;

  if not public.wpcc_can_manage_prayer_alert(p_scope,v_user_id,p_branch_id,p_department_id) then
    raise exception 'Prayer alert management is not permitted' using errcode='42501';
  end if;

  if p_id is null then
    insert into public.prayer_alerts(
      scope,user_id,branch_id,department_id,title,description,timezone,local_time,days_of_week,
      starts_on,ends_on,duration_seconds,audio_url,audio_title,audio_source,push_title,push_body,is_active
    ) values (
      p_scope,v_user_id,p_branch_id,p_department_id,btrim(p_title),nullif(btrim(p_description),''),p_timezone,p_local_time,p_days_of_week,
      p_starts_on,p_ends_on,p_duration_seconds,p_audio_url,p_audio_title,p_audio_source,p_push_title,p_push_body,coalesce(p_is_active,true)
    ) returning * into v_row;
  else
    update public.prayer_alerts a
    set scope=p_scope,user_id=v_user_id,branch_id=p_branch_id,department_id=p_department_id,
        title=btrim(p_title),description=nullif(btrim(p_description),''),timezone=p_timezone,local_time=p_local_time,
        days_of_week=p_days_of_week,starts_on=p_starts_on,ends_on=p_ends_on,duration_seconds=p_duration_seconds,
        audio_url=p_audio_url,audio_title=p_audio_title,audio_source=p_audio_source,push_title=p_push_title,push_body=p_push_body,
        is_active=coalesce(p_is_active,true)
    where a.id=p_id
      and public.wpcc_can_manage_prayer_alert(a.scope,a.user_id,a.branch_id,a.department_id)
    returning * into v_row;
    if v_row.id is null then raise exception 'Prayer alert not found or not permitted' using errcode='42501'; end if;
  end if;
  return v_row;
end;
$$;

revoke all on function public.save_prayer_alert(uuid,text,text,text,text,time,smallint[],date,date,integer,text,text,text,text,text,boolean,uuid,uuid) from public,anon;
grant execute on function public.save_prayer_alert(uuid,text,text,text,text,time,smallint[],date,date,integer,text,text,text,text,text,boolean,uuid,uuid) to authenticated;

-- Materialize occurrences for a bounded server-side horizon.
create or replace function public.materialize_prayer_alert_occurrences(
  p_from timestamptz default now(),
  p_until timestamptz default now() + interval '8 days'
)
returns integer
language plpgsql
security definer
set search_path=''
as $$
declare
  v_count integer := 0;
begin
  if p_until <= p_from or p_until > p_from + interval '31 days' then
    raise exception 'Invalid occurrence horizon';
  end if;

  with days as (
    select gs::date as local_date
    from generate_series(
      (p_from at time zone 'UTC')::date - 1,
      (p_until at time zone 'UTC')::date + 1,
      interval '1 day'
    ) gs
  ), candidates as (
    select
      a.id as alert_id,
      (d.local_date + a.local_time) as local_scheduled,
      ((d.local_date + a.local_time) at time zone a.timezone) as scheduled_utc
    from public.prayer_alerts a
    cross join days d
    where a.is_active
      and extract(isodow from d.local_date)::smallint = any(a.days_of_week)
      and (a.starts_on is null or d.local_date >= a.starts_on)
      and (a.ends_on is null or d.local_date <= a.ends_on)
  ), inserted as (
    insert into public.prayer_alert_occurrences(prayer_alert_id,scheduled_for,local_scheduled_for)
    select alert_id, scheduled_utc, local_scheduled
    from candidates
    where scheduled_utc >= p_from and scheduled_utc < p_until
    on conflict (prayer_alert_id,scheduled_for) do nothing
    returning 1
  )
  select count(*) into v_count from inserted;
  return v_count;
end;
$$;

revoke all on function public.materialize_prayer_alert_occurrences(timestamptz,timestamptz) from public,anon,authenticated;
grant execute on function public.materialize_prayer_alert_occurrences(timestamptz,timestamptz) to service_role;

-- Resolve intended recipients for an occurrence. This is service-side infrastructure.
create or replace function public.create_prayer_alert_deliveries(p_occurrence_id uuid)
returns integer
language plpgsql
security definer
set search_path=''
as $$
declare v_count integer:=0;
begin
  with alert_row as (
    select a.*
    from public.prayer_alert_occurrences o
    join public.prayer_alerts a on a.id=o.prayer_alert_id
    where o.id=p_occurrence_id and o.status='scheduled'
  ), recipients as (
    select distinct p.id as user_id
    from alert_row a
    join public.profiles p on (
      (a.scope='personal' and p.id=a.user_id)
      or (a.scope='branch' and p.branch_id=a.branch_id)
      or (a.scope='global')
      or (a.scope='department' and exists (
        select 1 from public.profile_departments pd
        where pd.profile_id=p.id and pd.department_id=a.department_id and pd.branch_id=a.branch_id
      ))
      or (a.scope='department' and p.department_id=a.department_id and p.branch_id=a.branch_id)
    )
  ), subs as (
    select r.user_id,s.id as subscription_id
    from recipients r
    join public.push_subscriptions s on s.user_id=r.user_id and s.is_active
  ), inserted as (
    insert into public.prayer_alert_deliveries(occurrence_id,alert_id,user_id,subscription_id)
    select p_occurrence_id,a.id,s.user_id,s.subscription_id
    from alert_row a cross join subs s
    on conflict (occurrence_id,subscription_id) do nothing
    returning 1
  ) select count(*) into v_count from inserted;
  return v_count;
end;
$$;

revoke all on function public.create_prayer_alert_deliveries(uuid) from public,anon,authenticated;
grant execute on function public.create_prayer_alert_deliveries(uuid) to service_role;

-- Session lifecycle uses database time only. Flutter sends IDs/intent, never timestamps.
create or replace function public.start_prayer_session(
  p_prayer_alert_id uuid default null,
  p_occurrence_id uuid default null,
  p_started_from text default 'app'
)
returns public.prayer_sessions
language plpgsql
security definer
set search_path=''
as $$
declare v_row public.prayer_sessions; v_target integer;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if p_started_from not in ('push','app','manual') then raise exception 'Invalid session source'; end if;

  if exists(select 1 from public.prayer_sessions s where s.user_id=auth.uid() and s.completion_status='active' and s.ended_at is null) then
    raise exception 'An active prayer session already exists' using errcode='23505';
  end if;

  if p_prayer_alert_id is not null then
    select a.duration_seconds into v_target
    from public.prayer_alerts a
    where a.id=p_prayer_alert_id
      and public.wpcc_can_read_prayer_alert(a.scope,a.user_id,a.branch_id,a.department_id);
    if not found then raise exception 'Prayer alert is not available' using errcode='42501'; end if;
  end if;

  if p_occurrence_id is not null and not exists(
    select 1 from public.prayer_alert_occurrences o
    join public.prayer_alerts a on a.id=o.prayer_alert_id
    where o.id=p_occurrence_id
      and (p_prayer_alert_id is null or a.id=p_prayer_alert_id)
      and public.wpcc_can_read_prayer_alert(a.scope,a.user_id,a.branch_id,a.department_id)
  ) then raise exception 'Prayer alert occurrence is not available' using errcode='42501'; end if;

  insert into public.prayer_sessions(user_id,prayer_alert_id,occurrence_id,target_duration_seconds,started_from)
  values(auth.uid(),p_prayer_alert_id,p_occurrence_id,v_target,p_started_from)
  returning * into v_row;
  return v_row;
end;
$$;

revoke all on function public.start_prayer_session(uuid,uuid,text) from public,anon;
grant execute on function public.start_prayer_session(uuid,uuid,text) to authenticated;

create or replace function public.end_prayer_session(
  p_session_id uuid,
  p_completion_status text default 'completed'
)
returns public.prayer_sessions
language plpgsql
security definer
set search_path=''
as $$
declare v_row public.prayer_sessions; v_now timestamptz:=now();
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if p_completion_status not in ('completed','abandoned') then raise exception 'Invalid completion status'; end if;
  update public.prayer_sessions s
  set ended_at=v_now,
      duration_seconds=greatest(0,floor(extract(epoch from (v_now-s.started_at)))::integer),
      completion_status=p_completion_status
  where s.id=p_session_id and s.user_id=auth.uid() and s.completion_status='active' and s.ended_at is null
  returning * into v_row;
  if v_row.id is null then raise exception 'Active prayer session not found' using errcode='P0002'; end if;
  return v_row;
end;
$$;

revoke all on function public.end_prayer_session(uuid,text) from public,anon;
grant execute on function public.end_prayer_session(uuid,text) to authenticated;

-- Convenience RPC for the Flutter timer. This uses server time, not device time.
create or replace function public.get_active_prayer_session()
returns table(
  id uuid,
  prayer_alert_id uuid,
  occurrence_id uuid,
  started_at timestamptz,
  server_now timestamptz,
  elapsed_seconds integer,
  target_duration_seconds integer,
  started_from text
)
language sql
stable
security definer
set search_path=''
as $$
  select s.id,s.prayer_alert_id,s.occurrence_id,s.started_at,now(),
         greatest(0,floor(extract(epoch from (now()-s.started_at)))::integer),
         s.target_duration_seconds,s.started_from
  from public.prayer_sessions s
  where s.user_id=auth.uid() and s.completion_status='active' and s.ended_at is null
  order by s.started_at desc limit 1;
$$;

revoke all on function public.get_active_prayer_session() from public,anon;
grant execute on function public.get_active_prayer_session() to authenticated;

-- Users register PWA push subscriptions without sending authoritative timestamps.
create or replace function public.upsert_push_subscription(
  p_endpoint text,
  p_p256dh_key text,
  p_auth_key text,
  p_device_name text default null,
  p_platform text default null,
  p_user_agent text default null
)
returns public.push_subscriptions
language plpgsql
security definer
set search_path=''
as $$
declare v_row public.push_subscriptions;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if coalesce(nullif(btrim(p_endpoint),''),'')='' or coalesce(nullif(btrim(p_p256dh_key),''),'')='' or coalesce(nullif(btrim(p_auth_key),''),'')='' then
    raise exception 'Push subscription data is incomplete';
  end if;
  insert into public.push_subscriptions(user_id,endpoint,p256dh_key,auth_key,device_name,platform,user_agent,is_active)
  values(auth.uid(),p_endpoint,p_p256dh_key,p_auth_key,p_device_name,p_platform,p_user_agent,true)
  on conflict(endpoint) do update
    set user_id=auth.uid(),p256dh_key=excluded.p256dh_key,auth_key=excluded.auth_key,
        device_name=excluded.device_name,platform=excluded.platform,user_agent=excluded.user_agent,
        is_active=true,last_seen_at=now(),updated_at=now()
  returning * into v_row;
  return v_row;
end;
$$;

revoke all on function public.upsert_push_subscription(text,text,text,text,text,text) from public,anon;
grant execute on function public.upsert_push_subscription(text,text,text,text,text,text) to authenticated;
