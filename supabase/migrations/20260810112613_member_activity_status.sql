alter table public.profiles
  add column if not exists last_login_at timestamptz;

update public.profiles p
set last_login_at = u.last_sign_in_at
from auth.users u
where u.id = p.id
  and p.last_login_at is distinct from u.last_sign_in_at;

create or replace function public.sync_profile_last_login_at()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.profiles
  set last_login_at = new.last_sign_in_at
  where id = new.id
    and last_login_at is distinct from new.last_sign_in_at;
  return new;
end;
$$;

revoke all on function public.sync_profile_last_login_at() from public, anon, authenticated;

drop trigger if exists sync_profile_last_login_at on auth.users;
create trigger sync_profile_last_login_at
after update of last_sign_in_at on auth.users
for each row
when (old.last_sign_in_at is distinct from new.last_sign_in_at)
execute function public.sync_profile_last_login_at();

create index if not exists attendance_member_activity_idx
  on public.attendance (user_id, created_at desc)
  where lower(coalesce(status, '')) in ('confirmed', 'present');

create or replace function public.churchmetric_members_report_v2(
  p_search text default '',
  p_status text default null,
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
  v_claim_branch uuid := public.churchmetric_branch_id();
  v_branch uuid;
  v_search text := lower(btrim(coalesce(p_search, '')));
  v_status text := nullif(lower(btrim(coalesce(p_status, ''))), '');
  v_page integer := greatest(coalesce(p_page, 1), 1);
  v_size integer := least(greatest(coalesce(p_page_size, 25), 1), 100);
  v_result jsonb;
begin
  if v_role not in ('admin', 'globaladmin') then
    raise exception 'Administrator access required' using errcode = '42501';
  end if;
  if v_status is not null and v_status not in ('active', 'inactive') then
    raise exception 'Invalid member status' using errcode = '22023';
  end if;
  if v_role = 'admin' then
    if p_branch_id is not null and p_branch_id is distinct from v_claim_branch then
      raise exception 'Cross-branch member access is forbidden' using errcode = '42501';
    end if;
    v_branch := v_claim_branch;
  else
    v_branch := p_branch_id;
  end if;

  with member_activity as materialized (
    select
      p.id, p.full_name, p.email, p.phone, p.membership_code, p.department_id,
      p.branch_id, p.created_at, p.date_joined, p.last_login_at,
      d.name as department_name,
      a.last_clock_in_at,
      greatest(
        coalesce(p.last_login_at, '-infinity'::timestamptz),
        coalesce(a.last_clock_in_at, '-infinity'::timestamptz)
      ) >= now() - interval '30 days' as is_active
    from public.profiles p
    left join public.departments d on d.id = p.department_id
    left join lateral (
      select max(att.created_at)::timestamptz as last_clock_in_at
      from public.attendance att
      where att.user_id = p.id
        and lower(coalesce(att.status, '')) in ('confirmed', 'present')
    ) a on true
    where v_branch is null or p.branch_id = v_branch
  ), filtered as materialized (
    select * from member_activity m
    where (v_search = '' or lower(
      coalesce(m.full_name, '') || ' ' || coalesce(m.email, '') || ' ' ||
      coalesce(m.phone, '') || ' ' || coalesce(m.membership_code, '')
    ) like '%' || v_search || '%')
      and (v_status is null or (m.is_active and v_status = 'active') or (not m.is_active and v_status = 'inactive'))
  ), page_rows as (
    select * from filtered
    order by lower(full_name), id
    limit v_size offset ((v_page - 1) * v_size)
  )
  select jsonb_build_object(
    'metrics', jsonb_build_object(
      'total', (select count(*) from member_activity),
      'active', (select count(*) from member_activity where is_active),
      'new_this_month', (select count(*) from member_activity where coalesce(date_joined, created_at) >= date_trunc('month', now())),
      'inactive', (select count(*) from member_activity where not is_active)
    ),
    'pagination', jsonb_build_object('page', v_page, 'page_size', v_size, 'total', (select count(*) from filtered)),
    'items', coalesce((select jsonb_agg(to_jsonb(r) order by lower(r.full_name), r.id) from page_rows r), '[]'::jsonb)
  ) into v_result;
  return v_result;
end;
$$;

revoke all on function public.churchmetric_members_report_v2(text, text, uuid, integer, integer) from public, anon;
grant execute on function public.churchmetric_members_report_v2(text, text, uuid, integer, integer) to authenticated;

comment on function public.churchmetric_members_report_v2(text, text, uuid, integer, integer)
is 'RLS-scoped member directory. Active means a login or confirmed/present attendance clock-in occurred within the last 30 days.';
