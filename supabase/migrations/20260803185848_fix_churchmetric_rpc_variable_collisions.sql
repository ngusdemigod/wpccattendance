-- Qualify PL/pgSQL variables that otherwise collide with target-table columns.
create or replace function public.churchmetric_create_quality_query(
  p_branch_id uuid, p_subject text, p_body text, p_priority text, p_due_at timestamptz, p_assignee_ids uuid[]
) returns uuid language plpgsql security invoker set search_path = '' as $$
declare new_id uuid; current_assignee_id uuid;
begin
  if not public.churchmetric_can_manage_branch(p_branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if coalesce(array_length(p_assignee_ids,1),0)=0 then raise exception 'assignee_required' using errcode='22023'; end if;
  if p_due_at is not null and p_due_at < now() then raise exception 'due_date_in_past' using errcode='22023'; end if;
  insert into public.quality_queries(branch_id,subject,body,priority,due_at,created_by)
  values(p_branch_id,btrim(p_subject),btrim(p_body),p_priority,p_due_at,auth.uid()) returning id into new_id;
  foreach current_assignee_id in array p_assignee_ids loop
    insert into public.quality_query_assignees(branch_id,query_id,assignee_id)
    values(p_branch_id,new_id,current_assignee_id)
    on conflict on constraint quality_query_assignees_query_id_assignee_id_key do nothing;
  end loop;
  insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_branch_id,auth.uid(),'quality_query_created','quality_query',new_id,jsonb_build_object('assignee_count',array_length(p_assignee_ids,1)));
  return new_id;
end $$;

create or replace function public.churchmetric_create_campaign(
  p_branch_id uuid,p_name text,p_channel text,p_subject text,p_body text,p_scheduled_at timestamptz,p_recipients jsonb
) returns uuid language plpgsql security invoker set search_path='' as $$
declare new_campaign_id uuid; recipient_record jsonb;
begin
  if not public.churchmetric_can_manage_branch(p_branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if jsonb_typeof(p_recipients)<>'array' or jsonb_array_length(p_recipients)=0 then raise exception 'recipient_required' using errcode='22023'; end if;
  if p_channel='email' and nullif(btrim(p_subject),'') is null then raise exception 'email_subject_required' using errcode='22023'; end if;
  insert into public.broadcast_campaigns(branch_id,name,channel,subject,body,status,scheduled_at,created_by)
  values(p_branch_id,btrim(p_name),p_channel,nullif(btrim(p_subject),''),btrim(p_body),case when p_scheduled_at is null or p_scheduled_at<=now() then 'dispatching' else 'scheduled' end,p_scheduled_at,auth.uid())
  returning id into new_campaign_id;
  for recipient_record in select value from jsonb_array_elements(p_recipients) loop
    insert into public.broadcast_recipients(branch_id,campaign_id,profile_id,destination)
    values(p_branch_id,new_campaign_id,nullif(recipient_record->>'profile_id','')::uuid,btrim(recipient_record->>'destination'))
    on conflict on constraint broadcast_recipients_campaign_id_destination_key do nothing;
  end loop;
  insert into public.notification_outbox(branch_id,event_type,aggregate_id,channel,payload,idempotency_key,available_at)
  values(p_branch_id,'broadcast_campaign_created',new_campaign_id,case when p_channel='call' then 'in_app' else p_channel end,jsonb_build_object('campaign_id',new_campaign_id),new_campaign_id::text,coalesce(p_scheduled_at,now()));
  return new_campaign_id;
end $$;
