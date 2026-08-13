-- Extend the existing branch-scoped overview RPC with the chart and activity
-- payloads required by the Overview page. The function remains SECURITY
-- INVOKER, so the underlying table RLS policies continue to define visibility.
create or replace function public.churchmetric_membership_overview(
  p_start_at timestamptz,
  p_end_at timestamptz,
  p_branch_id uuid default null
)
returns jsonb
language sql
stable
security invoker
set search_path = ''
as $$
  with scoped_profiles as (
    select p.id, p.full_name, p.email, p.department_id, p.verified, p.created_at
    from public.profiles p
    where (p_branch_id is null or p.branch_id = p_branch_id)
      and p.created_at < p_end_at
  ),
  period_profiles as (
    select * from scoped_profiles
    where created_at >= p_start_at and created_at < p_end_at
  ),
  active_members as (
    select count(distinct a.user_id)::integer as value
    from public.attendance a
    where (p_branch_id is null or a.branch_id = p_branch_id)
      and a.created_at >= p_start_at and a.created_at < p_end_at
      and a.status in ('confirmed', 'present')
  ),
  department_counts as (
    select
      d.id,
      d.name,
      count(sp.id)::integer as member_count,
      count(pp.id)::integer as new_member_count,
      count(sp.id) filter (where sp.verified is true)::integer as active_member_count
    from public.departments d
    left join scoped_profiles sp on sp.department_id = d.id
    left join period_profiles pp on pp.id = sp.id
    group by d.id, d.name
    order by member_count desc, d.name
  ),
  membership_trend as (
    select
      to_char(date_trunc('day', created_at), 'YYYY-MM-DD') as label,
      count(*)::integer as value
    from period_profiles
    group by date_trunc('day', created_at)
    order by date_trunc('day', created_at)
  ),
  audited_activity as (
    select
      ae.id,
      coalesce(entity_profile.full_name, actor_profile.full_name, 'Administrator') as member_name,
      coalesce(entity_profile.email, actor_profile.email, '') as member_email,
      coalesce(d.name, 'Unassigned') as department_name,
      replace(ae.action, '_', ' ') as activity,
      coalesce(ae.metadata ->> 'status', 'complete') as status,
      case
        when ae.metadata ->> 'completion_percent' ~ '^[0-9]{1,3}$'
          then least(100, (ae.metadata ->> 'completion_percent')::integer)
        when ae.action ~ '(created|completed|resolved|achieved|deleted)$' then 100
        else 0
      end as completion_percent,
      ae.entity_type,
      ae.entity_id,
      ae.created_at
    from public.churchmetric_audit_events ae
    left join public.profiles entity_profile
      on ae.entity_type = 'profile' and entity_profile.id = ae.entity_id
    left join public.profiles actor_profile on actor_profile.id = ae.actor_id
    left join public.departments d on d.id = coalesce(entity_profile.department_id, actor_profile.department_id)
    where (p_branch_id is null or ae.branch_id = p_branch_id)
      and ae.created_at >= p_start_at and ae.created_at < p_end_at
  ),
  registration_activity as (
    select
      pp.id,
      pp.full_name as member_name,
      coalesce(pp.email, '') as member_email,
      coalesce(d.name, 'Unassigned') as department_name,
      'membership registration'::text as activity,
      case when pp.verified then 'active' else 'pending' end as status,
      case when pp.verified then 100 else 50 end as completion_percent,
      'profile'::text as entity_type,
      pp.id as entity_id,
      pp.created_at
    from period_profiles pp
    left join public.departments d on d.id = pp.department_id
    where not exists (
      select 1 from audited_activity aa
      where aa.entity_type = 'profile' and aa.entity_id = pp.id
    )
  ),
  recent_activity as (
    select * from audited_activity
    union all
    select * from registration_activity
    order by created_at desc
    limit 10
  )
  select jsonb_build_object(
    'total_members', (select count(*) from scoped_profiles),
    'active_members', (select value from active_members),
    'souls_won', (
      select count(*) from public.souls s
      where (p_branch_id is null or s.branch_id = p_branch_id)
        and s.won_at >= p_start_at and s.won_at < p_end_at
    ),
    'new_members', (select count(*) from period_profiles),
    'open_enquiries', (
      select count(*) from public.enquiries e
      where (p_branch_id is null or e.branch_id = p_branch_id)
        and e.created_at >= p_start_at and e.created_at < p_end_at
        and e.status in ('open', 'in_progress')
    ),
    'departments', (select coalesce(jsonb_agg(to_jsonb(dc)), '[]'::jsonb) from department_counts dc),
    'membership_trend', (select coalesce(jsonb_agg(to_jsonb(mt)), '[]'::jsonb) from membership_trend mt),
    'recent_activity', (select coalesce(jsonb_agg(to_jsonb(ra)), '[]'::jsonb) from recent_activity ra)
  )
$$;

revoke all on function public.churchmetric_membership_overview(timestamptz, timestamptz, uuid) from public, anon;
grant execute on function public.churchmetric_membership_overview(timestamptz, timestamptz, uuid) to authenticated;
