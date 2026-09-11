drop function if exists public.community_department_attendance_events(uuid,integer,integer);
create function public.community_department_attendance_events(p_department_id uuid,p_limit integer default 50,p_offset integer default 0)
returns table(event_id uuid,title text,event_start_at timestamptz,event_end_at timestamptz,location text,event_type text,present_count bigint)
language plpgsql stable security definer set search_path=''
as $$
declare v_branch_id uuid; v_limit integer:=greatest(1,least(coalesce(p_limit,50),100)); v_offset integer:=greatest(0,coalesce(p_offset,0));
begin
  v_branch_id:=public.churchmetric_branch_id();
  if v_branch_id is null then select p.branch_id into v_branch_id from public.profiles p where p.id=auth.uid(); end if;
  if v_branch_id is null or not public.wpcc_can_view_department(p_department_id,v_branch_id) then raise exception 'Department attendance access is not permitted' using errcode='42501'; end if;
  return query select e.id,e.title,e.event_start_at,e.event_end_at,e.location,e.event_type,count(a.id) filter(where lower(coalesce(a.status,''))='present')
  from public.departmental_events e left join public.attendance a on a.event_id=e.id and a.department_id=p_department_id and a.branch_id=v_branch_id
  where e.department_id=p_department_id and e.branch_id=v_branch_id and e.closed_at is null
  group by e.id,e.title,e.event_start_at,e.event_end_at,e.location,e.event_type
  order by e.event_start_at desc limit v_limit offset v_offset;
end; $$;
revoke all on function public.community_department_attendance_events(uuid,integer,integer) from public,anon;
grant execute on function public.community_department_attendance_events(uuid,integer,integer) to authenticated;
