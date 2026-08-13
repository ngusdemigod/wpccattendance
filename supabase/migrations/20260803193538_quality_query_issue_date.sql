alter table public.quality_queries
  add column if not exists issued_at timestamptz not null default now();

create or replace function public.churchmetric_create_quality_query_v2(
  p_branch_id uuid, p_subject text, p_body text, p_priority text, p_issued_at timestamptz, p_due_at timestamptz, p_assignee_ids uuid[]
) returns uuid language plpgsql security invoker set search_path = '' as $$
declare new_id uuid; current_assignee_id uuid;
begin
  if not public.churchmetric_can_manage_branch(p_branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if coalesce(array_length(p_assignee_ids,1),0)=0 then raise exception 'assignee_required' using errcode='22023'; end if;
  if p_due_at is not null and p_due_at < p_issued_at then raise exception 'due_date_before_issue_date' using errcode='22023'; end if;
  insert into public.quality_queries(branch_id,subject,body,priority,issued_at,due_at,created_by)
  values(p_branch_id,btrim(p_subject),btrim(p_body),p_priority,p_issued_at,p_due_at,auth.uid()) returning id into new_id;
  foreach current_assignee_id in array p_assignee_ids loop
    insert into public.quality_query_assignees(branch_id,query_id,assignee_id)
    values(p_branch_id,new_id,current_assignee_id)
    on conflict on constraint quality_query_assignees_query_id_assignee_id_key do nothing;
  end loop;
  insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_branch_id,auth.uid(),'quality_query_created','quality_query',new_id,jsonb_build_object('assignee_count',array_length(p_assignee_ids,1)));
  return new_id;
end $$;
revoke all on function public.churchmetric_create_quality_query_v2(uuid,text,text,text,timestamptz,timestamptz,uuid[]) from public,anon;
grant execute on function public.churchmetric_create_quality_query_v2(uuid,text,text,text,timestamptz,timestamptz,uuid[]) to authenticated;
