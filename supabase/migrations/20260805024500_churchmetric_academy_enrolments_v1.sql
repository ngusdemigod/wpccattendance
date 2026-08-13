create index if not exists course_enrollments_branch_updated_idx on public.course_enrollments(branch_id,updated_at desc);

create or replace function public.churchmetric_academy_enrolments_v1(p_branch_id uuid default null,p_search text default null,p_filter text default null,p_page integer default 1,p_page_size integer default 25)
returns jsonb language plpgsql security invoker set search_path='' stable as $$
declare v_page integer:=greatest(coalesce(p_page,1),1);v_size integer:=least(greatest(coalesce(p_page_size,25),1),100);v_search text:=nullif(btrim(coalesce(p_search,'')),'');v_total bigint;v_items jsonb;v_metrics jsonb;
begin
 if p_branch_id is not null and not public.churchmetric_can_manage_branch(p_branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
 if p_filter is not null and p_filter not in('finished','unfinished','yet_to_attend')then raise exception 'invalid_filter' using errcode='22023';end if;
 with scoped as(
  select e.id,e.branch_id,e.user_id,e.course_id,e.progress_percent,e.updated_at,e.created_at,p.full_name member_name,p.email member_email,p.membership_code,c.title class_name,c.code class_code,
   case when e.publication_id is not null then 'Department' else 'Direct' end assignment_source,
   case when e.completed or e.status='completed' or e.progress_percent=100 then 'completed' when e.progress_percent=0 and e.status in('pending','not_started')then 'yet_to_attend' else 'in_progress' end display_status
  from public.course_enrollments e join public.profiles p on p.id=e.user_id join public.courses c on c.id=e.course_id where p_branch_id is null or e.branch_id=p_branch_id
 ),filtered as(select * from scoped where(v_search is null or member_name ilike '%'||v_search||'%' or member_email ilike '%'||v_search||'%' or membership_code ilike '%'||v_search||'%' or class_name ilike '%'||v_search||'%')and(p_filter is null or(p_filter='finished'and display_status='completed')or(p_filter='unfinished'and display_status='in_progress')or(p_filter='yet_to_attend'and display_status='yet_to_attend')))
 select count(*)into v_total from filtered;
 with scoped as(
  select e.id,e.branch_id,e.user_id,e.course_id,e.progress_percent,e.updated_at,e.created_at,p.full_name member_name,p.email member_email,p.membership_code,c.title class_name,c.code class_code,
   case when e.publication_id is not null then 'Department' else 'Direct' end assignment_source,
   case when e.completed or e.status='completed' or e.progress_percent=100 then 'completed' when e.progress_percent=0 and e.status in('pending','not_started')then 'yet_to_attend' else 'in_progress' end display_status
  from public.course_enrollments e join public.profiles p on p.id=e.user_id join public.courses c on c.id=e.course_id where p_branch_id is null or e.branch_id=p_branch_id
 ),filtered as(select * from scoped where(v_search is null or member_name ilike '%'||v_search||'%' or member_email ilike '%'||v_search||'%' or membership_code ilike '%'||v_search||'%' or class_name ilike '%'||v_search||'%')and(p_filter is null or(p_filter='finished'and display_status='completed')or(p_filter='unfinished'and display_status='in_progress')or(p_filter='yet_to_attend'and display_status='yet_to_attend')))
 select coalesce(jsonb_agg(to_jsonb(item)order by item.updated_at desc),'[]'::jsonb)into v_items from(select * from filtered order by updated_at desc offset(v_page-1)*v_size limit v_size)item;
 with scoped as(select case when e.completed or e.status='completed' or e.progress_percent=100 then 'completed' when e.progress_percent=0 and e.status in('pending','not_started')then 'yet_to_attend' else 'in_progress' end display_status from public.course_enrollments e where p_branch_id is null or e.branch_id=p_branch_id)
 select jsonb_build_object('total',count(*),'in_progress',count(*)filter(where display_status='in_progress'),'completed',count(*)filter(where display_status='completed'),'yet_to_attend',count(*)filter(where display_status='yet_to_attend'))into v_metrics from scoped;
 return jsonb_build_object('metrics',v_metrics,'items',v_items,'pagination',jsonb_build_object('page',v_page,'page_size',v_size,'total',v_total));
end$$;
revoke all on function public.churchmetric_academy_enrolments_v1(uuid,text,text,integer,integer)from public,anon;
grant execute on function public.churchmetric_academy_enrolments_v1(uuid,text,text,integer,integer)to authenticated;
