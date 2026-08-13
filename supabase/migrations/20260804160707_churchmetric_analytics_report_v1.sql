create or replace function public.churchmetric_analytics_report_v1(
  p_start_at timestamptz,
  p_end_at timestamptz,
  p_category text default 'all',
  p_branch_id uuid default null
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
  v_category text := lower(coalesce(nullif(trim(p_category), ''), 'all'));
  v_duration interval;
  v_previous_start timestamptz;
  v_previous_end timestamptz;
  v_result jsonb;
begin
  if v_role not in ('admin', 'globaladmin') then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
  if p_start_at is null or p_end_at is null or p_start_at > p_end_at then
    raise exception 'Invalid reporting period' using errcode = '22007';
  end if;
  if v_category not in ('all','membership','attendance','outreach','departments','academy','care_qc') then
    raise exception 'Invalid analytics category' using errcode = '22023';
  end if;
  if v_role = 'admin' and p_branch_id is not null and p_branch_id is distinct from v_branch then
    raise exception 'Cross-branch analytics access is forbidden' using errcode = '42501';
  end if;

  v_duration := p_end_at - p_start_at;
  v_previous_end := p_start_at - interval '1 microsecond';
  v_previous_start := v_previous_end - v_duration;

  with values_by_period as (
    select
      (select count(*) from public.profiles p where p.created_at <= p_end_at and (p_branch_id is null or p.branch_id = p_branch_id))::numeric as total_members,
      (select count(*) from public.profiles p where p.created_at <= v_previous_end and (p_branch_id is null or p.branch_id = p_branch_id))::numeric as previous_total_members,
      (select count(*) from public.profiles p where p.verified is true and p.created_at <= p_end_at and (p_branch_id is null or p.branch_id = p_branch_id))::numeric as active_members,
      (select count(*) from public.profiles p where p.verified is true and p.created_at <= v_previous_end and (p_branch_id is null or p.branch_id = p_branch_id))::numeric as previous_active_members,
      (select count(*) from public.profiles p where p.created_at between p_start_at and p_end_at and (p_branch_id is null or p.branch_id = p_branch_id))::numeric as new_members,
      (select count(*) from public.profiles p where p.created_at between v_previous_start and v_previous_end and (p_branch_id is null or p.branch_id = p_branch_id))::numeric as previous_new_members,
      (select count(*) from public.attendance a where a.created_at between p_start_at and p_end_at and (p_branch_id is null or a.branch_id = p_branch_id))::numeric as attendance,
      (select count(*) from public.attendance a where a.created_at between v_previous_start and v_previous_end and (p_branch_id is null or a.branch_id = p_branch_id))::numeric as previous_attendance,
      (select count(distinct a.user_id) from public.attendance a where a.created_at between p_start_at and p_end_at and (p_branch_id is null or a.branch_id = p_branch_id))::numeric as unique_attendees,
      (select count(distinct a.user_id) from public.attendance a where a.created_at between v_previous_start and v_previous_end and (p_branch_id is null or a.branch_id = p_branch_id))::numeric as previous_unique_attendees,
      (select count(*) from public.souls s where s.won_at between p_start_at and p_end_at and (p_branch_id is null or s.branch_id = p_branch_id))::numeric as souls_won,
      (select count(*) from public.souls s where s.won_at between v_previous_start and v_previous_end and (p_branch_id is null or s.branch_id = p_branch_id))::numeric as previous_souls_won,
      (select count(*) from public.souls s where s.status = 'integrated' and s.updated_at between p_start_at and p_end_at and (p_branch_id is null or s.branch_id = p_branch_id))::numeric as souls_integrated,
      (select count(*) from public.souls s where s.status = 'integrated' and s.updated_at between v_previous_start and v_previous_end and (p_branch_id is null or s.branch_id = p_branch_id))::numeric as previous_souls_integrated,
      (select count(*) from public.course_enrollments e where (e.completed is true or e.status = 'completed') and e.updated_at between p_start_at and p_end_at and (p_branch_id is null or e.branch_id = p_branch_id))::numeric as class_completions,
      (select count(*) from public.course_enrollments e where (e.completed is true or e.status = 'completed') and e.updated_at between v_previous_start and v_previous_end and (p_branch_id is null or e.branch_id = p_branch_id))::numeric as previous_class_completions,
      (select count(distinct e.user_id) from public.course_enrollments e where e.updated_at between p_start_at and p_end_at and (p_branch_id is null or e.branch_id = p_branch_id))::numeric as active_learners,
      (select count(distinct e.user_id) from public.course_enrollments e where e.updated_at between v_previous_start and v_previous_end and (p_branch_id is null or e.branch_id = p_branch_id))::numeric as previous_active_learners,
      (select count(*) from public.quality_reports r where r.status in ('resolved','closed') and r.updated_at between p_start_at and p_end_at and (p_branch_id is null or r.branch_id = p_branch_id))::numeric as resolved_reports,
      (select count(*) from public.quality_reports r where r.status in ('resolved','closed') and r.updated_at between v_previous_start and v_previous_end and (p_branch_id is null or r.branch_id = p_branch_id))::numeric as previous_resolved_reports,
      (select count(*) from public.enquiries e where e.status not in ('resolved','closed') and e.created_at <= p_end_at and (p_branch_id is null or e.branch_id = p_branch_id))::numeric as open_enquiries,
      (select count(*) from public.enquiries e where e.status not in ('resolved','closed') and e.created_at <= v_previous_end and (p_branch_id is null or e.branch_id = p_branch_id))::numeric as previous_open_enquiries
  ), indicator_source as (
    select * from values_by_period v cross join lateral (values
      ('membership','New members',v.new_members,v.previous_new_members),
      ('membership','Active members',v.active_members,v.previous_active_members),
      ('attendance','Recorded attendance',v.attendance,v.previous_attendance),
      ('attendance','Unique attendees',v.unique_attendees,v.previous_unique_attendees),
      ('outreach','Souls won',v.souls_won,v.previous_souls_won),
      ('outreach','Souls integrated',v.souls_integrated,v.previous_souls_integrated),
      ('departments','Members assigned',v.total_members,v.previous_total_members),
      ('academy','Class completions',v.class_completions,v.previous_class_completions),
      ('academy','Active learners',v.active_learners,v.previous_active_learners),
      ('care_qc','Resolved reports',v.resolved_reports,v.previous_resolved_reports),
      ('care_qc','Open enquiries',v.open_enquiries,v.previous_open_enquiries)
    ) i(category, indicator, current_value, previous_value)
  ), indicators as (
    select category, indicator, current_value, previous_value,
      case when previous_value = 0 then null else round(((current_value - previous_value) / previous_value) * 100, 1) end as change_percent,
      case
        when previous_value = 0 and current_value > 0 then 'New'
        when current_value >= previous_value then 'Strong'
        when current_value >= previous_value * 0.9 then 'On track'
        else 'Needs attention'
      end as status
    from indicator_source
    where v_category = 'all' or category = v_category
  ), department_values as (
    select d.id, d.name,
      (select count(*) from public.profiles p where p.department_id = d.id and p.created_at <= p_end_at and (p_branch_id is null or p.branch_id = p_branch_id))::numeric as member_count,
      (select count(*) from public.attendance a where a.department_id = d.id and a.created_at between p_start_at and p_end_at and (p_branch_id is null or a.branch_id = p_branch_id))::numeric as attendance_count,
      (select count(*) from public.attendance a where a.department_id = d.id and a.created_at between p_start_at and p_end_at and lower(coalesce(a.status,'')) in ('confirmed','present') and (p_branch_id is null or a.branch_id = p_branch_id))::numeric as present_count,
      (select dl.user_full_name from public.department_leadership_view dl where dl.department_id = d.id and dl.is_active is true and (p_branch_id is null or dl.branch_id = p_branch_id) order by dl.start_date desc nulls last limit 1) as leader
    from public.departments d
  ), department_rankings as (
    select id, name, coalesce(leader,'Unassigned') as leader, member_count,
      case when attendance_count = 0 then 0 else round((present_count / attendance_count) * 100, 1) end as attendance_rate
    from department_values
    where member_count > 0
    order by attendance_rate desc, member_count desc, name
    limit 8
  ), trend as (
    select category as label,
      round(avg(case when previous_value = 0 then case when current_value > 0 then 100 else 0 end else least(100, greatest(0, current_value / previous_value * 100)) end), 1) as value
    from indicator_source
    where v_category = 'all' or category = v_category
    group by category
    order by category
  )
  select jsonb_build_object(
    'metrics', jsonb_build_object(
      'total_members', v.total_members,
      'active_member_rate', case when v.total_members = 0 then 0 else round(v.active_members / v.total_members * 100, 1) end,
      'souls_won', v.souls_won,
      'recorded_attendance', v.attendance
    ),
    'trend', coalesce((select jsonb_agg(to_jsonb(t)) from trend t), '[]'::jsonb),
    'departments', coalesce((select jsonb_agg(to_jsonb(d)) from department_rankings d), '[]'::jsonb),
    'indicators', coalesce((select jsonb_agg(to_jsonb(i) order by i.category, i.indicator) from indicators i), '[]'::jsonb),
    'period', jsonb_build_object('start_at',p_start_at,'end_at',p_end_at,'previous_start_at',v_previous_start,'previous_end_at',v_previous_end),
    'category', v_category
  ) into v_result
  from values_by_period v;

  return v_result;
end;
$$;

revoke all on function public.churchmetric_analytics_report_v1(timestamptz,timestamptz,text,uuid) from public, anon;
grant execute on function public.churchmetric_analytics_report_v1(timestamptz,timestamptz,text,uuid) to authenticated;

comment on function public.churchmetric_analytics_report_v1(timestamptz,timestamptz,text,uuid)
is 'RLS-scoped current/previous ChurchMetric analytics snapshot. SECURITY INVOKER; admin branch scope is enforced.';
