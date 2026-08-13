create index if not exists quality_issues_branch_priority_status_created_idx on public.quality_issues(branch_id,priority,status,created_at desc);

create or replace function public.churchmetric_quality_issues_v1(p_branch_id uuid default null,p_search text default null,p_priority text default null,p_status text default null,p_page integer default 1,p_page_size integer default 25)
returns jsonb language plpgsql security invoker set search_path='' as $$
declare v_page integer:=greatest(coalesce(p_page,1),1);v_size integer:=least(greatest(coalesce(p_page_size,25),1),100);v_search text:=nullif(btrim(coalesce(p_search,'')),'');v_total bigint;v_items jsonb;v_metrics jsonb;
begin
 if p_branch_id is not null and not public.churchmetric_can_manage_branch(p_branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
 if p_priority is not null and p_priority not in ('low','medium','high','critical') then raise exception 'invalid_priority' using errcode='22023'; end if;
 if p_status is not null and p_status not in ('open','investigating','in_progress','resolved','closed') then raise exception 'invalid_status' using errcode='22023'; end if;
 select count(*) into v_total from public.quality_issues i left join public.quality_reports r on r.id=i.report_id left join public.profiles reporter on reporter.id=r.reporter_id left join public.profiles owner on owner.id=i.owner_id
 where (p_branch_id is null or i.branch_id=p_branch_id) and (p_priority is null or i.priority=p_priority) and (p_status is null or i.status=p_status)
 and (v_search is null or i.title ilike '%'||v_search||'%' or i.area ilike '%'||v_search||'%' or reporter.full_name ilike '%'||v_search||'%' or owner.full_name ilike '%'||v_search||'%');
 select coalesce(jsonb_agg(to_jsonb(item) order by item.created_at desc),'[]'::jsonb) into v_items from(
  select i.id,i.branch_id,i.title,i.area,i.priority,i.status,i.owner_id,i.created_at,i.resolved_at,reporter.full_name reporter_name,reporter.email reporter_email,owner.full_name owner_name
  from public.quality_issues i left join public.quality_reports r on r.id=i.report_id left join public.profiles reporter on reporter.id=r.reporter_id left join public.profiles owner on owner.id=i.owner_id
  where (p_branch_id is null or i.branch_id=p_branch_id) and (p_priority is null or i.priority=p_priority) and (p_status is null or i.status=p_status)
  and (v_search is null or i.title ilike '%'||v_search||'%' or i.area ilike '%'||v_search||'%' or reporter.full_name ilike '%'||v_search||'%' or owner.full_name ilike '%'||v_search||'%')
  order by i.created_at desc offset(v_page-1)*v_size limit v_size
 )item;
 select jsonb_build_object('open',count(*)filter(where i.status in('open','investigating')),'critical',count(*)filter(where i.priority='critical' and i.status not in('resolved','closed')),'in_progress',count(*)filter(where i.status='in_progress'),'resolved',count(*)filter(where i.status in('resolved','closed')))into v_metrics from public.quality_issues i where p_branch_id is null or i.branch_id=p_branch_id;
 return jsonb_build_object('metrics',v_metrics,'items',v_items,'pagination',jsonb_build_object('page',v_page,'page_size',v_size,'total',v_total),'server_time',now());
end$$;

create or replace function public.churchmetric_quality_issue_detail_v1(p_issue_id uuid)returns jsonb language sql security invoker set search_path='' stable as $$
 select to_jsonb(detail) from(select i.id,i.branch_id,i.title,i.description,i.area,i.priority,i.status,i.owner_id,i.created_at,i.updated_at,i.resolved_at,reporter.full_name reporter_name,reporter.email reporter_email,owner.full_name owner_name,
 coalesce((select jsonb_agg(jsonb_build_object('from_status',h.from_status,'to_status',h.to_status,'changed_by',h.changed_by,'created_at',h.created_at)order by h.created_at)from public.quality_status_history h where h.entity_type='issue' and h.entity_id=i.id),'[]'::jsonb)history
 from public.quality_issues i left join public.quality_reports r on r.id=i.report_id left join public.profiles reporter on reporter.id=r.reporter_id left join public.profiles owner on owner.id=i.owner_id where i.id=p_issue_id)detail
$$;

revoke all on function public.churchmetric_quality_issues_v1(uuid,text,text,text,integer,integer)from public,anon;
revoke all on function public.churchmetric_quality_issue_detail_v1(uuid)from public,anon;
grant execute on function public.churchmetric_quality_issues_v1(uuid,text,text,text,integer,integer)to authenticated;
grant execute on function public.churchmetric_quality_issue_detail_v1(uuid)to authenticated;
