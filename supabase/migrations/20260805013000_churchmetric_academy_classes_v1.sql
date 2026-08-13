create index if not exists academy_assignments_course_session_idx on public.academy_instructor_assignments(course_id,session_id);
create index if not exists academy_modules_course_position_idx on public.academy_modules(course_id,position);

create or replace function public.churchmetric_academy_classes_v1(
  p_branch_id uuid default null,p_search text default null,p_status text default null,p_page integer default 1,p_page_size integer default 25
) returns jsonb language plpgsql security invoker set search_path='' stable as $$
declare v_page integer:=greatest(coalesce(p_page,1),1);v_size integer:=least(greatest(coalesce(p_page_size,25),1),100);v_search text:=nullif(btrim(coalesce(p_search,'')),'');v_total bigint;v_items jsonb;v_metrics jsonb;
begin
  if p_branch_id is not null and not public.churchmetric_can_manage_branch(p_branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if p_status is not null and p_status not in ('draft','active','archived') then raise exception 'invalid_status' using errcode='22023'; end if;
  with scoped as(
    select c.id,c.branch_id,c.title,c.code,c.status,c.created_at,
      coalesce((select ce.category from public.course_enrollments ce where ce.course_id=c.id and ce.category is not null order by ce.created_at desc limit 1),'General') track,
      (select p.full_name from public.academy_instructor_assignments aia join public.academy_instructors ai on ai.id=aia.instructor_id join public.profiles p on p.id=ai.profile_id where aia.course_id=c.id and ai.active order by aia.created_at desc limit 1) facilitator_name,
      (select p.email from public.academy_instructor_assignments aia join public.academy_instructors ai on ai.id=aia.instructor_id join public.profiles p on p.id=ai.profile_id where aia.course_id=c.id and ai.active order by aia.created_at desc limit 1) facilitator_email,
      coalesce((select concat_ws(' · ',s.title,nullif(s.location,'')) from public.academy_sessions s where s.course_id=c.id order by s.starts_at desc limit 1),'Not scheduled') delivery,
      case when exists(select 1 from public.course_enrollments ce where ce.course_id=c.id and ce.publication_id is not null) then 'Department' else 'Personal' end assigned_through,
      (select count(*) from public.course_enrollments ce where ce.course_id=c.id) enrolled,
      coalesce((select round(avg(ce.progress_percent)) from public.course_enrollments ce where ce.course_id=c.id),0) completion
    from public.courses c where (p_branch_id is null or c.branch_id=p_branch_id) and (p_status is null or c.status=p_status)
  ),filtered as(select * from scoped where v_search is null or title ilike '%'||v_search||'%' or track ilike '%'||v_search||'%' or facilitator_name ilike '%'||v_search||'%')
  select count(*) into v_total from filtered;
  with scoped as(
    select c.id,c.branch_id,c.title,c.code,c.status,c.created_at,
      coalesce((select ce.category from public.course_enrollments ce where ce.course_id=c.id and ce.category is not null order by ce.created_at desc limit 1),'General') track,
      (select p.full_name from public.academy_instructor_assignments aia join public.academy_instructors ai on ai.id=aia.instructor_id join public.profiles p on p.id=ai.profile_id where aia.course_id=c.id and ai.active order by aia.created_at desc limit 1) facilitator_name,
      (select p.email from public.academy_instructor_assignments aia join public.academy_instructors ai on ai.id=aia.instructor_id join public.profiles p on p.id=ai.profile_id where aia.course_id=c.id and ai.active order by aia.created_at desc limit 1) facilitator_email,
      coalesce((select concat_ws(' · ',s.title,nullif(s.location,'')) from public.academy_sessions s where s.course_id=c.id order by s.starts_at desc limit 1),'Not scheduled') delivery,
      case when exists(select 1 from public.course_enrollments ce where ce.course_id=c.id and ce.publication_id is not null) then 'Department' else 'Personal' end assigned_through,
      (select count(*) from public.course_enrollments ce where ce.course_id=c.id) enrolled,
      coalesce((select round(avg(ce.progress_percent)) from public.course_enrollments ce where ce.course_id=c.id),0) completion
    from public.courses c where (p_branch_id is null or c.branch_id=p_branch_id) and (p_status is null or c.status=p_status)
  ),filtered as(select * from scoped where v_search is null or title ilike '%'||v_search||'%' or track ilike '%'||v_search||'%' or facilitator_name ilike '%'||v_search||'%')
  select coalesce(jsonb_agg(to_jsonb(item) order by item.created_at desc),'[]'::jsonb) into v_items from(select * from filtered order by created_at desc offset(v_page-1)*v_size limit v_size)item;
  select jsonb_build_object(
    'active_classes',count(*)filter(where c.status='active'),
    'enrolled_members',(select count(*) from public.course_enrollments ce where p_branch_id is null or ce.branch_id=p_branch_id),
    'instructors',(select count(*) from public.academy_instructors ai where ai.active and (p_branch_id is null or ai.branch_id=p_branch_id)),
    'completion_rate',coalesce((select round(avg(ce.progress_percent)) from public.course_enrollments ce where p_branch_id is null or ce.branch_id=p_branch_id),0),
    'yet_to_attend',(select count(*) from public.course_enrollments ce where ce.status in('pending','not_started') and (p_branch_id is null or ce.branch_id=p_branch_id))
  )into v_metrics from public.courses c where p_branch_id is null or c.branch_id=p_branch_id;
  return jsonb_build_object('metrics',v_metrics,'items',v_items,'pagination',jsonb_build_object('page',v_page,'page_size',v_size,'total',v_total));
end$$;

create or replace function public.churchmetric_academy_class_detail_v1(p_course_id uuid,p_session_id uuid default null)
returns jsonb language plpgsql security invoker set search_path='' stable as $$
declare v_course public.courses%rowtype;v_result jsonb;
begin
  select * into v_course from public.courses where id=p_course_id;
  if not found then raise exception 'class_not_found' using errcode='P0002'; end if;
  if not public.churchmetric_can_read_branch(v_course.branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if p_session_id is not null and not exists(select 1 from public.academy_sessions s where s.id=p_session_id and s.course_id=p_course_id) then raise exception 'session_not_in_class' using errcode='22023'; end if;
  select jsonb_build_object(
    'course',jsonb_build_object('id',v_course.id,'branch_id',v_course.branch_id,'title',v_course.title,'code',v_course.code,'description',v_course.description,'status',v_course.status),
    'metrics',jsonb_build_object('modules',(select count(*) from public.academy_modules m where m.course_id=p_course_id),'attachments',(select count(*) from public.academy_module_attachments a join public.academy_modules m on m.id=a.module_id where m.course_id=p_course_id),'students',(select count(*) from public.course_enrollments e where e.course_id=p_course_id),'sessions',(select count(*) from public.academy_sessions s where s.course_id=p_course_id),'completion',coalesce((select round(avg(e.progress_percent)) from public.course_enrollments e where e.course_id=p_course_id),0)),
    'modules',coalesce((select jsonb_agg(jsonb_build_object('id',m.id,'title',m.title,'description',m.description,'position',m.position,'attachments',coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'file_name',a.file_name,'mime_type',a.mime_type,'size_bytes',a.size_bytes,'created_at',a.created_at)order by a.created_at)from public.academy_module_attachments a where a.module_id=m.id),'[]'::jsonb))order by m.position,m.title)from public.academy_modules m where m.course_id=p_course_id),'[]'::jsonb),
    'sessions',coalesce((select jsonb_agg(jsonb_build_object('id',s.id,'title',s.title,'starts_at',s.starts_at,'status',s.status,'location',s.location)order by s.starts_at desc)from public.academy_sessions s where s.course_id=p_course_id),'[]'::jsonb),
    'students',coalesce((select jsonb_agg(jsonb_build_object('id',e.id,'session_id',e.session_id,'membership_code',p.membership_code,'name',p.full_name,'email',p.email,'department',d.name,'progress',e.progress_percent,'status',case when e.status='completed' or e.completed then 'completed' else 'in_progress' end)order by p.full_name)from public.course_enrollments e join public.profiles p on p.id=e.user_id left join public.departments d on d.id=p.department_id where e.course_id=p_course_id and(p_session_id is null or e.session_id=p_session_id)),'[]'::jsonb),
    'selected_session_id',p_session_id
  )into v_result;
  return v_result;
end$$;

revoke all on function public.churchmetric_academy_classes_v1(uuid,text,text,integer,integer)from public,anon;
revoke all on function public.churchmetric_academy_class_detail_v1(uuid,uuid)from public,anon;
grant execute on function public.churchmetric_academy_classes_v1(uuid,text,text,integer,integer)to authenticated;
grant execute on function public.churchmetric_academy_class_detail_v1(uuid,uuid)to authenticated;
