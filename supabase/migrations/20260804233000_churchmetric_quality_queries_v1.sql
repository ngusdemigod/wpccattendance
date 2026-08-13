alter table public.quality_queries add column if not exists category text not null default 'General';

create index if not exists quality_queries_branch_status_due_idx
  on public.quality_queries(branch_id, status, due_at, created_at desc);

create or replace function public.churchmetric_quality_queries_v1(
  p_branch_id uuid default null,
  p_search text default null,
  p_status text default null,
  p_page integer default 1,
  p_page_size integer default 25
) returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare
  v_page integer := greatest(coalesce(p_page, 1), 1);
  v_page_size integer := least(greatest(coalesce(p_page_size, 25), 1), 100);
  v_search text := nullif(trim(coalesce(p_search, '')), '');
  v_total bigint;
  v_items jsonb;
  v_metrics jsonb;
  v_members jsonb;
begin
  if p_branch_id is not null and not public.churchmetric_can_manage_branch(p_branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if p_status is not null and p_status not in ('open','awaiting_response','overdue','responded','closed') then raise exception 'invalid_status' using errcode='22023'; end if;

  select count(*) into v_total
  from public.quality_queries q
  where (p_branch_id is null or q.branch_id=p_branch_id)
    and (p_status is null or (p_status='overdue' and q.due_at<now() and q.status not in ('responded','closed')) or (p_status<>'overdue' and q.status=p_status))
    and (v_search is null or q.subject ilike '%'||v_search||'%' or q.category ilike '%'||v_search||'%' or q.id::text ilike '%'||v_search||'%'
      or exists(select 1 from public.quality_query_assignees a join public.profiles p on p.id=a.assignee_id where a.query_id=q.id and (p.full_name ilike '%'||v_search||'%' or p.email ilike '%'||v_search||'%' or p.membership_code ilike '%'||v_search||'%')));

  select coalesce(jsonb_agg(to_jsonb(item) order by item.created_at desc),'[]'::jsonb) into v_items
  from (
    select q.id,q.branch_id,q.subject,q.category,q.priority,q.status,q.issued_at,q.due_at,q.created_at,
      (q.due_at<now() and q.status not in ('responded','closed')) as overdue,
      coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'name',p.full_name,'email',p.email,'membership_code',p.membership_code,'responded_at',a.responded_at) order by p.full_name)
        from public.quality_query_assignees a join public.profiles p on p.id=a.assignee_id where a.query_id=q.id),'[]'::jsonb) as assignees
    from public.quality_queries q
    where (p_branch_id is null or q.branch_id=p_branch_id)
      and (p_status is null or (p_status='overdue' and q.due_at<now() and q.status not in ('responded','closed')) or (p_status<>'overdue' and q.status=p_status))
      and (v_search is null or q.subject ilike '%'||v_search||'%' or q.category ilike '%'||v_search||'%' or q.id::text ilike '%'||v_search||'%'
        or exists(select 1 from public.quality_query_assignees a join public.profiles p on p.id=a.assignee_id where a.query_id=q.id and (p.full_name ilike '%'||v_search||'%' or p.email ilike '%'||v_search||'%' or p.membership_code ilike '%'||v_search||'%')))
    order by q.created_at desc offset (v_page-1)*v_page_size limit v_page_size
  ) item;

  select jsonb_build_object(
    'open',count(*) filter(where q.status='open'),
    'awaiting_response',count(*) filter(where q.status='awaiting_response'),
    'overdue',count(*) filter(where q.due_at<now() and q.status not in ('responded','closed')),
    'responded',count(*) filter(where q.status in ('responded','closed'))
  ) into v_metrics from public.quality_queries q where p_branch_id is null or q.branch_id=p_branch_id;

  select coalesce(jsonb_agg(jsonb_build_object('id',p.id,'name',p.full_name,'email',p.email,'membership_code',p.membership_code) order by p.full_name),'[]'::jsonb)
  into v_members from public.profiles p where (p_branch_id is null or p.branch_id=p_branch_id) and p.full_name is not null limit 500;

  return jsonb_build_object('metrics',v_metrics,'items',v_items,'members',v_members,'pagination',jsonb_build_object('page',v_page,'page_size',v_page_size,'total',v_total),'server_time',now());
end $$;

create or replace function public.churchmetric_create_quality_query_v3(
  p_branch_id uuid,p_category text,p_subject text,p_body text,p_priority text,p_issued_at timestamptz,p_due_at timestamptz,p_assignee_ids uuid[]
) returns uuid
language plpgsql security invoker set search_path=''
as $$
declare v_id uuid; v_assignee uuid;
begin
  if not public.churchmetric_can_manage_branch(p_branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if coalesce(array_length(p_assignee_ids,1),0)=0 then raise exception 'assignee_required' using errcode='22023'; end if;
  if p_due_at<p_issued_at then raise exception 'due_date_before_issue_date' using errcode='22023'; end if;
  if p_priority not in ('low','medium','high','critical') then raise exception 'invalid_priority' using errcode='22023'; end if;
  if nullif(btrim(p_category),'') is null or nullif(btrim(p_subject),'') is null or nullif(btrim(p_body),'') is null then raise exception 'required_fields_missing' using errcode='22023'; end if;
  if exists(select 1 from unnest(p_assignee_ids) id left join public.profiles p on p.id=id and p.branch_id=p_branch_id where p.id is null) then raise exception 'invalid_assignee' using errcode='22023'; end if;
  insert into public.quality_queries(branch_id,category,subject,body,priority,status,issued_at,due_at,created_by)
  values(p_branch_id,btrim(p_category),btrim(p_subject),btrim(p_body),p_priority,'awaiting_response',p_issued_at,p_due_at,auth.uid()) returning id into v_id;
  foreach v_assignee in array p_assignee_ids loop insert into public.quality_query_assignees(branch_id,query_id,assignee_id) values(p_branch_id,v_id,v_assignee) on conflict(query_id,assignee_id) do nothing; end loop;
  insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_branch_id,auth.uid(),'quality_query_created','quality_query',v_id,jsonb_build_object('assignee_count',array_length(p_assignee_ids,1)));
  return v_id;
end $$;

revoke all on function public.churchmetric_quality_queries_v1(uuid,text,text,integer,integer) from public,anon;
revoke all on function public.churchmetric_create_quality_query_v3(uuid,text,text,text,text,timestamptz,timestamptz,uuid[]) from public,anon;
grant execute on function public.churchmetric_quality_queries_v1(uuid,text,text,integer,integer) to authenticated;
grant execute on function public.churchmetric_create_quality_query_v3(uuid,text,text,text,text,timestamptz,timestamptz,uuid[]) to authenticated;
