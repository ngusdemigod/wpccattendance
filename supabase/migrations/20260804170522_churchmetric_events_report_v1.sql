-- `public.events` and `public.my_events` are compatibility views. Their three
-- underlying event tables already have branch/date indexes from the segmented
-- event migration, so this report deliberately adds no duplicate indexes.

create or replace function public.churchmetric_events_report_v1(
  p_start_at timestamptz,
  p_end_at timestamptz,
  p_search text default '',
  p_branch_id uuid default null,
  p_page integer default 1,
  p_page_size integer default 25
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_role text := public.churchmetric_role();
  v_branch uuid := public.churchmetric_branch_id();
  v_search text := lower(trim(coalesce(p_search,'')));
  v_page integer := greatest(1,coalesce(p_page,1));
  v_page_size integer := least(100,greatest(1,coalesce(p_page_size,25)));
  v_result jsonb;
begin
  if v_role not in ('admin','globaladmin') then raise exception 'Administrator access required' using errcode='42501'; end if;
  if p_start_at is null or p_end_at is null or p_start_at > p_end_at then raise exception 'Invalid event period' using errcode='22007'; end if;
  if v_role='admin' and p_branch_id is not null and p_branch_id is distinct from v_branch then raise exception 'Cross-branch event access is forbidden' using errcode='42501'; end if;

  with period_events as materialized (
    select e.id,e.title,e.description,e.event_date,e.endtime,e.scope,e.location,e.branch_id,e.isactive,
      coalesce(nullif(trim(e.location),''),b.name,'Unassigned') as venue,
      coalesce((select count(*) from public.attendance a where a.event_id=e.id),0)::bigint as attendance_count
    from public.events e
    left join public.branches b on b.id=e.branch_id
    where e.event_date between p_start_at and p_end_at
      and (p_branch_id is null or e.branch_id=p_branch_id)
  ), filtered_events as materialized (
    select * from period_events e
    where v_search='' or lower(coalesce(e.title,'')||' '||coalesce(e.scope,'')||' '||coalesce(e.venue,'')||' '||coalesce(e.event_date::text,'')) like '%'||v_search||'%'
  ), page_rows as (
    select * from filtered_events order by event_date desc nulls last,title limit v_page_size offset ((v_page-1)*v_page_size)
  )
  select jsonb_build_object(
    'metrics',jsonb_build_object(
      'total_events',(select count(*) from period_events),
      'total_attendance',(select coalesce(sum(attendance_count),0) from period_events),
      'average_attendance',(select case when count(*)=0 then 0 else round(coalesce(sum(attendance_count),0)::numeric/count(*),1) end from period_events),
      'latest_event',(select event_date from period_events order by event_date desc nulls last limit 1)
    ),
    'total',(select count(*) from filtered_events),
    'page',v_page,
    'page_size',v_page_size,
    'events',coalesce((select jsonb_agg(jsonb_build_object(
      'id',r.id,'title',r.title,'description',r.description,'event_start_date',r.event_date,'event_end_time',r.endtime,
      'event_scope',r.scope,'venue',r.venue,'event_branch_id',r.branch_id,'is_active',r.isactive,'attendance_count',r.attendance_count
    ) order by r.event_date desc nulls last,r.title) from page_rows r),'[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$$;

revoke all on function public.churchmetric_events_report_v1(timestamptz,timestamptz,text,uuid,integer,integer) from public,anon;
grant execute on function public.churchmetric_events_report_v1(timestamptz,timestamptz,text,uuid,integer,integer) to authenticated;

create or replace function public.churchmetric_event_attendance_v1(
  p_event_id uuid,
  p_search text default '',
  p_page integer default 1,
  p_page_size integer default 50
)
returns jsonb
language plpgsql
stable
security invoker
set search_path = public, pg_temp
as $$
declare
  v_role text := public.churchmetric_role();
  v_search text := lower(trim(coalesce(p_search,'')));
  v_page integer := greatest(1,coalesce(p_page,1));
  v_page_size integer := least(100,greatest(1,coalesce(p_page_size,50)));
  v_event_title text;
  v_result jsonb;
begin
  if v_role not in ('admin','globaladmin') then raise exception 'Administrator access required' using errcode='42501'; end if;
  select e.title into v_event_title from public.events e where e.id=p_event_id;
  if not found then raise exception 'Event not found or unavailable' using errcode='P0002'; end if;

  with register as materialized (
    select a.id,a.user_id,coalesce(nullif(p.full_name,''),a.fullname,'Unknown member') as full_name,p.email,
      p.membership_code,coalesce(d.name,'Unassigned') as department_name,a.created_at,a.status
    from public.attendance a
    left join public.profiles p on p.id=a.user_id
    left join public.departments d on d.id=coalesce(a.department_id,p.department_id)
    where a.event_id=p_event_id
  ), filtered as materialized (
    select * from register r where v_search='' or lower(coalesce(r.full_name,'')||' '||coalesce(r.department_name,'')||' '||coalesce(r.membership_code,'')) like '%'||v_search||'%'
  ), page_rows as (
    select * from filtered order by lower(full_name),id limit v_page_size offset ((v_page-1)*v_page_size)
  )
  select jsonb_build_object(
    'event_id',p_event_id,'event_title',v_event_title,'total',(select count(*) from filtered),'page',v_page,'page_size',v_page_size,
    'rows',coalesce((select jsonb_agg(jsonb_build_object('id',r.id,'user_id',r.user_id,'full_name',r.full_name,'email',r.email,'department_name',r.department_name,'membership_code',r.membership_code,'created_at',r.created_at,'status',r.status) order by lower(r.full_name),r.id) from page_rows r),'[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$$;

revoke all on function public.churchmetric_event_attendance_v1(uuid,text,integer,integer) from public,anon;
grant execute on function public.churchmetric_event_attendance_v1(uuid,text,integer,integer) to authenticated;

comment on function public.churchmetric_events_report_v1(timestamptz,timestamptz,text,uuid,integer,integer) is 'RLS-scoped event metrics and paginated directory. SECURITY INVOKER.';
comment on function public.churchmetric_event_attendance_v1(uuid,text,integer,integer) is 'RLS-scoped alphabetical event attendance register. SECURITY INVOKER.';
