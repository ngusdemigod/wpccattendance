create or replace function public.churchmetric_transition_quality_report(
  p_report_id uuid,
  p_action text
) returns text
language plpgsql
security invoker
set search_path = ''
as $$
declare report_row public.quality_reports%rowtype; next_status text;
begin
  select * into report_row from public.quality_reports where id=p_report_id for update;
  if not found then raise exception 'report_not_found' using errcode='P0002'; end if;
  if not public.churchmetric_can_manage_branch(report_row.branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if p_action='resolve' and report_row.status in ('open','in_review') then next_status:='resolved';
  elsif p_action='escalate' and report_row.status in ('open','in_review') then next_status:='in_review';
  else raise exception 'invalid_status_transition' using errcode='22023';
  end if;
  update public.quality_reports set status=next_status,updated_at=now() where id=p_report_id;
  insert into public.quality_status_history(branch_id,entity_type,entity_id,from_status,to_status,changed_by)
  values(report_row.branch_id,'report',report_row.id,report_row.status,next_status,auth.uid());
  if p_action='escalate' and not exists(select 1 from public.quality_issues where report_id=report_row.id) then
    insert into public.quality_issues(branch_id,report_id,title,description,area,priority,status,created_by)
    values(report_row.branch_id,report_row.id,report_row.subject,report_row.description,report_row.category,report_row.priority,'open',auth.uid());
  end if;
  insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata)
  values(report_row.branch_id,auth.uid(),'quality_report_'||p_action,'quality_report',report_row.id,jsonb_build_object('from',report_row.status,'to',next_status));
  return next_status;
end $$;
revoke all on function public.churchmetric_transition_quality_report(uuid,text) from public,anon;
grant execute on function public.churchmetric_transition_quality_report(uuid,text) to authenticated;
