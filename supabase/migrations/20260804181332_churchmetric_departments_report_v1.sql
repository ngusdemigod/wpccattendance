create or replace function public.churchmetric_departments_report_v1(p_search text default '',p_branch_id uuid default null)
returns jsonb language plpgsql stable security invoker set search_path=public,pg_temp as $$
declare v_role text:=public.churchmetric_role();v_claim_branch uuid:=public.churchmetric_branch_id();v_branch uuid;v_search text:=lower(btrim(coalesce(p_search,'')));v_result jsonb;
begin
  if v_role not in ('admin','globaladmin') then raise exception 'Administrator access required' using errcode='42501';end if;
  if v_role='admin' then
    if p_branch_id is not null and p_branch_id is distinct from v_claim_branch then raise exception 'Cross-branch department access is forbidden' using errcode='42501';end if;
    v_branch:=v_claim_branch;
  else v_branch:=p_branch_id;end if;
  with values_by_department as materialized(
    select d.id,d.name,d.description,
      (select count(*) from public.profiles p where p.department_id=d.id and (v_branch is null or p.branch_id=v_branch))::bigint member_count,
      (select count(*) from public.attendance a where a.department_id=d.id and (v_branch is null or a.branch_id=v_branch))::numeric attendance_count,
      (select count(*) from public.attendance a where a.department_id=d.id and lower(coalesce(a.status,'')) in ('confirmed','present') and (v_branch is null or a.branch_id=v_branch))::numeric present_count,
      (select dl.user_full_name from public.department_leadership_view dl where dl.department_id=d.id and dl.is_active is true and (v_branch is null or dl.branch_id=v_branch) order by dl.start_date desc nulls last limit 1) leader,
      (select dl.title_name from public.department_leadership_view dl where dl.department_id=d.id and dl.is_active is true and (v_branch is null or dl.branch_id=v_branch) order by dl.start_date desc nulls last limit 1) leader_title,
      (select count(*) from public.department_leadership_view dl where dl.department_id=d.id and dl.is_active is true and (v_branch is null or dl.branch_id=v_branch))::bigint leader_count
    from public.departments d
  ),scoped as materialized(
    select id,name,description,coalesce(leader,'Unassigned') leader,coalesce(leader_title,'No active leader') leader_title,member_count,leader_count,case when attendance_count=0 then 0 else round(present_count/attendance_count*100,1) end attendance_rate
    from values_by_department where v_role='globaladmin' and v_branch is null or member_count>0 or leader_count>0
  ),filtered as materialized(select * from scoped d where v_search='' or lower(coalesce(d.name,'')||' '||coalesce(d.description,'')||' '||d.leader||' '||d.leader_title) like '%'||v_search||'%')
  select jsonb_build_object('metrics',jsonb_build_object('departments',(select count(*) from scoped),'assigned_members',(select coalesce(sum(member_count),0) from scoped),'department_leaders',(select coalesce(sum(leader_count),0) from scoped),'average_attendance',(select coalesce(round(avg(attendance_rate),1),0) from scoped)),'departments',coalesce((select jsonb_agg(to_jsonb(d) order by d.name) from filtered d),'[]'::jsonb)) into v_result;
  return v_result;
end $$;
revoke all on function public.churchmetric_departments_report_v1(text,uuid) from public,anon;
grant execute on function public.churchmetric_departments_report_v1(text,uuid) to authenticated;
comment on function public.churchmetric_departments_report_v1(text,uuid) is 'RLS-scoped department cards, leadership export fields, and reconciled metrics. SECURITY INVOKER.';
