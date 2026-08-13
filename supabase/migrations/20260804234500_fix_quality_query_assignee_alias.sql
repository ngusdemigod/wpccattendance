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
  if exists(
    select 1 from unnest(p_assignee_ids) as candidate(assignee_id)
    left join public.profiles p on p.id=candidate.assignee_id and p.branch_id=p_branch_id
    where p.id is null
  ) then raise exception 'invalid_assignee' using errcode='22023'; end if;
  insert into public.quality_queries(branch_id,category,subject,body,priority,status,issued_at,due_at,created_by)
  values(p_branch_id,btrim(p_category),btrim(p_subject),btrim(p_body),p_priority,'awaiting_response',p_issued_at,p_due_at,auth.uid()) returning id into v_id;
  foreach v_assignee in array p_assignee_ids loop insert into public.quality_query_assignees(branch_id,query_id,assignee_id) values(p_branch_id,v_id,v_assignee) on conflict(query_id,assignee_id) do nothing; end loop;
  insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_branch_id,auth.uid(),'quality_query_created','quality_query',v_id,jsonb_build_object('assignee_count',array_length(p_assignee_ids,1)));
  return v_id;
end $$;

revoke all on function public.churchmetric_create_quality_query_v3(uuid,text,text,text,text,timestamptz,timestamptz,uuid[]) from public,anon;
grant execute on function public.churchmetric_create_quality_query_v3(uuid,text,text,text,text,timestamptz,timestamptz,uuid[]) to authenticated;
