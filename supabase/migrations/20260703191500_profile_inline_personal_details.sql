drop view if exists public.my_profile;
drop function if exists public.current_my_profile();

create or replace function public.current_my_profile()
returns table (
  user_id uuid,
  full_name text,
  first_name text,
  last_name text,
  avatar text,
  email text,
  phone text,
  membership_code text,
  member_id_display text,
  member_since timestamp with time zone,
  branch_id uuid,
  branch_name text,
  department_id uuid,
  department_name text,
  role_name text,
  leadership_title text,
  is_verified boolean,
  status_label text,
  courses_completed_count integer,
  classes_in_progress_count integer,
  pending_classes_count integer,
  queries_count integer,
  attendance_rate_percent integer,
  next_pending_class_title text,
  next_pending_class_meta text,
  bio text,
  occupation text,
  residential_address text,
  gender text,
  marital_status text,
  date_of_birth date,
  emergency_contact text,
  water_baptism_date date,
  maturity_class_completed text,
  ministry_class_completed text,
  mission_class_completed text
)
language sql
security definer
set search_path = public, auth
as $$
  with me as (
    select
      s.auth_user_id as user_id,
      s.primary_role_name,
      s.primary_scope_type
    from public.current_access_scope() s
  ),
  profile_base as (
    select
      p.id as user_id,
      coalesce(pp.full_name, p.full_name) as full_name,
      coalesce(pp.firstname, p.firstname) as first_name,
      coalesce(pp.lastname, p.lastname) as last_name,
      coalesce(pp.avatar, p.avatar) as avatar,
      coalesce(pp.email, p.email) as email,
      coalesce(pp.phone_number, pp.phone, p.phone) as phone,
      coalesce(mc.membershipcode, pp.membership_code, p.membership_code) as membership_code,
      coalesce(pp.date_joined_wpcc, pp.date_joined, p.date_joined, p.created_at::timestamptz) as member_since,
      p.branch_id,
      b.name as branch_name,
      p.department_id,
      d.name as department_name,
      lower(coalesce(me.primary_role_name, 'member')) as role_name,
      (
        select coalesce(dlv.title_name, dlv.title_code)
        from public.department_leadership_view dlv
        where dlv.user_id = p.id
          and coalesce(dlv.is_active, true)
        order by dlv.created_at desc nulls last
        limit 1
      ) as leadership_title,
      coalesce(pp.verified, p.verified, false) as is_verified,
      exists (
        select 1
        from public.roles r
        where r.memberid = p.id
          and coalesce(r.is_active, true)
      ) as has_active_role,
      coalesce(pp.bio, p.bio) as bio,
      pp.occupation,
      coalesce(pp.residential_address, pp.address) as residential_address,
      pp.gender,
      pp.marital_status,
      coalesce(pp.date_of_birth, pp.dob::date) as date_of_birth,
      pp.emergency_contact,
      pp.water_baptism_date,
      pp.maturity_class_completed,
      pp.ministry_class_completed,
      pp.mission_class_completed
    from me
    join public.profiles p
      on p.id = me.user_id
    left join public.profiles_priv_info pp
      on pp.id = p.id
    left join public.membershipcode mc
      on mc.memberid = p.id
    left join public.branches b
      on b.id = p.branch_id
    left join public.departments d
      on d.id = p.department_id
  ),
  class_summary as (
    select
      count(*) filter (where status = 'completed')::integer as courses_completed_count,
      count(*) filter (where status = 'in_progress')::integer as classes_in_progress_count,
      count(*) filter (where status = 'pending')::integer as pending_classes_count
    from public.current_my_classes()
  ),
  query_summary as (
    select count(*)::integer as queries_count
    from public.current_my_queries()
  ),
  attendance_summary as (
    select
      case
        when count(*) = 0 then null
        else round(
          (
            count(*) filter (where lower(coalesce(a.status, '')) = 'present')::numeric /
            count(*)::numeric
          ) * 100
        )::integer
      end as attendance_rate_percent
    from public.attendance a
    where a.user_id = auth.uid()
  ),
  next_class as (
    select
      mc.title as next_pending_class_title,
      trim(
        both ' -' from concat_ws(
          ' - ',
          case
            when mc.module_index is not null and mc.module_total is not null
              then 'Module ' || mc.module_index || ' of ' || mc.module_total
            else null
          end,
          nullif(mc.description, '')
        )
      ) as next_pending_class_meta
    from public.current_my_classes() mc
    where mc.status <> 'completed'
    order by mc.due_at asc nulls last, mc.assigned_at desc nulls last
    limit 1
  )
  select
    pb.user_id,
    pb.full_name,
    pb.first_name,
    pb.last_name,
    pb.avatar,
    pb.email,
    pb.phone,
    pb.membership_code,
    pb.membership_code as member_id_display,
    pb.member_since,
    pb.branch_id,
    pb.branch_name,
    pb.department_id,
    pb.department_name,
    pb.role_name,
    pb.leadership_title,
    pb.is_verified,
    case
      when pb.has_active_role then 'Active'
      else null
    end as status_label,
    cs.courses_completed_count,
    cs.classes_in_progress_count,
    cs.pending_classes_count,
    qs.queries_count,
    ats.attendance_rate_percent,
    nc.next_pending_class_title,
    nc.next_pending_class_meta,
    pb.bio,
    pb.occupation,
    pb.residential_address,
    pb.gender,
    pb.marital_status,
    pb.date_of_birth,
    pb.emergency_contact,
    pb.water_baptism_date,
    pb.maturity_class_completed,
    pb.ministry_class_completed,
    pb.mission_class_completed
  from profile_base pb
  cross join class_summary cs
  cross join query_summary qs
  cross join attendance_summary ats
  left join next_class nc
    on true;
$$;

revoke all on function public.current_my_profile() from public;
grant execute on function public.current_my_profile() to authenticated;
grant execute on function public.current_my_profile() to service_role;

create or replace view public.my_profile
with (security_invoker = true)
as
select * from public.current_my_profile();

revoke all on public.my_profile from anon, authenticated;
grant select on public.my_profile to authenticated;
grant all on public.my_profile to service_role;

grant insert on public.profiles_priv_info to authenticated;

drop policy if exists profiles_priv_info_insert_own on public.profiles_priv_info;
create policy profiles_priv_info_insert_own
on public.profiles_priv_info
for insert
to authenticated
with check (id = auth.uid());
