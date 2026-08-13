create or replace function public.churchmetric_members_report_v3(
  p_search text default '', p_status text default null, p_filter text default null,
  p_sort text default 'newest', p_branch_id uuid default null,
  p_page integer default 1, p_page_size integer default 25
) returns jsonb language plpgsql stable security invoker set search_path = public, pg_temp as $$
declare
  v_role text := public.churchmetric_role(); v_claim_branch uuid := public.churchmetric_branch_id(); v_branch uuid;
  v_search text := lower(btrim(coalesce(p_search, ''))); v_status text := nullif(lower(btrim(coalesce(p_status, ''))), '');
  v_filter text := nullif(lower(btrim(coalesce(p_filter, ''))), ''); v_sort text := lower(btrim(coalesce(p_sort, 'newest')));
  v_page integer := greatest(coalesce(p_page, 1), 1); v_size integer := least(greatest(coalesce(p_page_size, 25), 1), 100); v_result jsonb;
begin
  if v_role not in ('admin','globaladmin') then raise exception 'Administrator access required' using errcode='42501'; end if;
  if v_status is not null and v_status not in ('active','inactive') then raise exception 'Invalid member status' using errcode='22023'; end if;
  if v_filter is not null and v_filter <> 'recent' then raise exception 'Invalid member filter' using errcode='22023'; end if;
  if v_sort not in ('newest','oldest','name_asc','name_desc','last_seen','membership_code_asc','membership_code_desc') then raise exception 'Invalid member sort' using errcode='22023'; end if;
  if v_role='admin' then
    if p_branch_id is not null and p_branch_id is distinct from v_claim_branch then raise exception 'Cross-branch member access is forbidden' using errcode='42501'; end if;
    v_branch:=v_claim_branch;
  else v_branch:=p_branch_id; end if;
  with member_activity as materialized (
    select p.id,p.full_name,p.email,p.phone,p.membership_code,p.branch_id,p.created_at,p.date_joined,p.last_login_at,
      coalesce(ds.department_names,'Unassigned') department_name,coalesce(ds.department_ids,'') department_ids,
      a.last_clock_in_at,
      greatest(coalesce(p.last_login_at,'-infinity'::timestamptz),coalesce(a.last_clock_in_at,'-infinity'::timestamptz)) last_seen_at,
      greatest(coalesce(p.last_login_at,'-infinity'::timestamptz),coalesce(a.last_clock_in_at,'-infinity'::timestamptz))>=now()-interval '30 days' is_active
    from public.profiles p
    left join lateral (
      select string_agg(d.name,', ' order by d.name) department_names,string_agg(d.id::text,',' order by d.name) department_ids
      from public.profile_departments pd join public.departments d on d.id=pd.department_id where pd.profile_id=p.id
    ) ds on true
    left join lateral (select max(att.created_at)::timestamptz last_clock_in_at from public.attendance att where att.user_id=p.id and lower(coalesce(att.status,'')) in ('confirmed','present')) a on true
    where v_branch is null or p.branch_id=v_branch
  ), filtered as materialized (
    select * from member_activity m where (v_search='' or lower(coalesce(m.full_name,'')||' '||coalesce(m.email,'')||' '||coalesce(m.phone,'')||' '||coalesce(m.membership_code,'')||' '||coalesce(m.department_name,'')) like '%'||v_search||'%')
      and (v_status is null or (m.is_active and v_status='active') or (not m.is_active and v_status='inactive'))
      and (v_filter is null or coalesce(m.date_joined,m.created_at)>=now()-interval '30 days')
  ), page_rows as (
    select * from filtered order by
      case when v_sort='newest' then coalesce(date_joined,created_at) end desc nulls last,
      case when v_sort='oldest' then coalesce(date_joined,created_at) end asc nulls last,
      case when v_sort='name_asc' then lower(full_name) end asc nulls last,
      case when v_sort='name_desc' then lower(full_name) end desc nulls last,
      case when v_sort='last_seen' then last_seen_at end desc nulls last,
      case when v_sort='membership_code_asc' then membership_code end asc nulls last,
      case when v_sort='membership_code_desc' then membership_code end desc nulls last,
      id limit v_size offset((v_page-1)*v_size)
  )
  select jsonb_build_object('metrics',jsonb_build_object('total',(select count(*) from member_activity),'active',(select count(*) from member_activity where is_active),'new_this_month',(select count(*) from member_activity where coalesce(date_joined,created_at)>=date_trunc('month',now())),'inactive',(select count(*) from member_activity where not is_active)),'pagination',jsonb_build_object('page',v_page,'page_size',v_size,'total',(select count(*) from filtered)),'items',coalesce((select jsonb_agg(to_jsonb(r)) from page_rows r),'[]'::jsonb)) into v_result;
  return v_result;
end; $$;

revoke all on function public.churchmetric_members_report_v3(text,text,text,text,uuid,integer,integer) from public,anon;
grant execute on function public.churchmetric_members_report_v3(text,text,text,text,uuid,integer,integer) to authenticated;
