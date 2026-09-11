-- Prayer Alert preferences required by the approved v76 implementation.
-- All authoritative occurrence/session timestamps remain server-generated.

alter table public.prayer_alerts
  add column if not exists vibration_enabled boolean not null default true,
  add column if not exists snooze_minutes smallint;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conname='prayer_alerts_snooze_minutes_check'
      and conrelid='public.prayer_alerts'::regclass
  ) then
    alter table public.prayer_alerts
      add constraint prayer_alerts_snooze_minutes_check
      check (snooze_minutes is null or snooze_minutes in (5,10,15,30));
  end if;
end $$;

drop function if exists public.save_prayer_alert(uuid,text,text,text,text,time without time zone,smallint[],date,date,integer,text,text,text,text,text,boolean,uuid,uuid);

create function public.save_prayer_alert(
  p_id uuid,
  p_scope text,
  p_title text,
  p_description text,
  p_timezone text,
  p_local_time time without time zone,
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
  p_department_id uuid default null,
  p_vibration_enabled boolean default true,
  p_snooze_minutes smallint default null
)
returns public.prayer_alerts
language plpgsql
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
  if p_snooze_minutes is not null and p_snooze_minutes not in (5,10,15,30) then raise exception 'Invalid snooze duration'; end if;

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
      starts_on,ends_on,duration_seconds,audio_url,audio_title,audio_source,push_title,push_body,
      is_active,vibration_enabled,snooze_minutes
    ) values (
      p_scope,v_user_id,p_branch_id,p_department_id,btrim(p_title),nullif(btrim(p_description),''),p_timezone,
      p_local_time,p_days_of_week,p_starts_on,p_ends_on,p_duration_seconds,p_audio_url,p_audio_title,
      p_audio_source,p_push_title,p_push_body,coalesce(p_is_active,true),coalesce(p_vibration_enabled,true),p_snooze_minutes
    ) returning * into v_row;
  else
    update public.prayer_alerts a set
      scope=p_scope,user_id=v_user_id,branch_id=p_branch_id,department_id=p_department_id,title=btrim(p_title),
      description=nullif(btrim(p_description),''),timezone=p_timezone,local_time=p_local_time,days_of_week=p_days_of_week,
      starts_on=p_starts_on,ends_on=p_ends_on,duration_seconds=p_duration_seconds,audio_url=p_audio_url,
      audio_title=p_audio_title,audio_source=p_audio_source,push_title=p_push_title,push_body=p_push_body,
      is_active=coalesce(p_is_active,true),vibration_enabled=coalesce(p_vibration_enabled,true),snooze_minutes=p_snooze_minutes
    where a.id=p_id
      and public.wpcc_can_manage_prayer_alert(a.scope,a.user_id,a.branch_id,a.department_id)
    returning * into v_row;
    if v_row.id is null then raise exception 'Prayer alert not found or not permitted' using errcode='42501'; end if;
  end if;

  return v_row;
end;
$$;

revoke all on function public.save_prayer_alert(uuid,text,text,text,text,time without time zone,smallint[],date,date,integer,text,text,text,text,text,boolean,uuid,uuid,boolean,smallint) from public, anon;
grant execute on function public.save_prayer_alert(uuid,text,text,text,text,time without time zone,smallint[],date,date,integer,text,text,text,text,text,boolean,uuid,uuid,boolean,smallint) to authenticated;

create or replace function public.snooze_prayer_alert_occurrence(
  p_occurrence_id uuid,
  p_minutes smallint
)
returns public.prayer_alert_occurrences
language plpgsql
security definer
set search_path=''
as $$
declare
  v_source public.prayer_alert_occurrences;
  v_alert public.prayer_alerts;
  v_row public.prayer_alert_occurrences;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if p_minutes not in (5,10,15,30) then raise exception 'Invalid snooze duration'; end if;

  select * into v_source from public.prayer_alert_occurrences o where o.id=p_occurrence_id;
  if v_source.id is null then raise exception 'Prayer occurrence not found'; end if;

  select * into v_alert
  from public.prayer_alerts a
  where a.id=v_source.prayer_alert_id
    and public.wpcc_can_read_prayer_alert(a.scope,a.user_id,a.branch_id,a.department_id);
  if v_alert.id is null then raise exception 'Prayer alert access is not permitted' using errcode='42501'; end if;

  if not (
    (v_alert.scope='personal' and v_alert.user_id=auth.uid())
    or exists (
      select 1 from public.prayer_alert_deliveries d
      where d.occurrence_id=p_occurrence_id and d.user_id=auth.uid()
    )
  ) then
    raise exception 'Prayer occurrence is not assigned to this member' using errcode='42501';
  end if;

  insert into public.prayer_alert_occurrences(
    prayer_alert_id, scheduled_for, local_scheduled_for, status, created_at
  ) values (
    v_alert.id,
    now() + make_interval(mins => p_minutes),
    (now() + make_interval(mins => p_minutes)) at time zone v_alert.timezone,
    'scheduled',
    now()
  ) returning * into v_row;

  return v_row;
end;
$$;

revoke all on function public.snooze_prayer_alert_occurrence(uuid,smallint) from public, anon;
grant execute on function public.snooze_prayer_alert_occurrence(uuid,smallint) to authenticated;
