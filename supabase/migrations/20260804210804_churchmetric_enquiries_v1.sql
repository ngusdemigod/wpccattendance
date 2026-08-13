-- Prompt 08: RLS-scoped enquiry inbox, thread reads and audited workflows.
-- Dashboard tenancy remains branch-based; globaladmin is the only cross-branch role.

alter table public.notification_outbox
  drop constraint if exists notification_outbox_status_check;
alter table public.notification_outbox
  add constraint notification_outbox_status_check
  check (status in ('pending','processing','retry','processed','sent','failed','cancelled'));

create or replace function public.churchmetric_enquiries_inbox_v1(
  p_branch_id uuid default null,
  p_search text default null,
  p_status text default null,
  p_page integer default 1,
  p_page_size integer default 25
) returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare
  v_page integer := greatest(coalesce(p_page,1),1);
  v_page_size integer := greatest(1,least(coalesce(p_page_size,25),50));
  v_search text := nullif(btrim(coalesce(p_search,'')),'');
  v_status text := nullif(lower(btrim(coalesce(p_status,''))),'');
  v_total integer;
  v_items jsonb;
  v_metrics jsonb;
  v_handlers jsonb;
begin
  if p_branch_id is not null and not public.churchmetric_can_read_branch(p_branch_id) then
    raise exception 'not_authorized' using errcode='42501';
  end if;
  if v_status is not null and v_status not in ('open','in_progress','urgent','closed') then
    raise exception 'invalid_status_filter' using errcode='22023';
  end if;

  with scoped as (
    select e.id,e.branch_id,e.member_id,e.subject,e.category,e.priority,e.status,e.assigned_to,e.due_at,e.created_at,
      coalesce(nullif(p.full_name,''),'External contact') as sender_name,
      p.email as sender_email
    from public.enquiries e
    left join public.profiles p on p.id=e.member_id
    where (p_branch_id is null or e.branch_id=p_branch_id)
  ), filtered as (
    select * from scoped s
    where (v_search is null or s.subject ilike '%'||v_search||'%' or s.category ilike '%'||v_search||'%' or s.sender_name ilike '%'||v_search||'%')
      and (v_status is null
        or (v_status='open' and s.status='open' and s.priority not in ('high','critical'))
        or (v_status='in_progress' and s.status='in_progress')
        or (v_status='urgent' and s.status not in ('resolved','closed') and s.priority in ('high','critical'))
        or (v_status='closed' and s.status in ('resolved','closed')))
  )
  select count(*)::integer into v_total from filtered;

  with scoped as (
    select e.id,e.branch_id,e.member_id,e.subject,e.category,e.priority,e.status,e.assigned_to,e.due_at,e.created_at,
      coalesce(nullif(p.full_name,''),'External contact') as sender_name,
      p.email as sender_email
    from public.enquiries e
    left join public.profiles p on p.id=e.member_id
    where (p_branch_id is null or e.branch_id=p_branch_id)
  ), filtered as (
    select * from scoped s
    where (v_search is null or s.subject ilike '%'||v_search||'%' or s.category ilike '%'||v_search||'%' or s.sender_name ilike '%'||v_search||'%')
      and (v_status is null
        or (v_status='open' and s.status='open' and s.priority not in ('high','critical'))
        or (v_status='in_progress' and s.status='in_progress')
        or (v_status='urgent' and s.status not in ('resolved','closed') and s.priority in ('high','critical'))
        or (v_status='closed' and s.status in ('resolved','closed')))
    order by (s.priority in ('high','critical')) desc,s.created_at desc,s.id
    limit v_page_size offset (v_page-1)*v_page_size
  )
  select coalesce(jsonb_agg(jsonb_build_object(
    'id',f.id,'branch_id',f.branch_id,'subject',f.subject,'category',f.category,
    'priority',f.priority,'status',f.status,'assigned_to',f.assigned_to,
    'due_at',f.due_at,'created_at',f.created_at,'sender_name',f.sender_name,
    'sender_email',f.sender_email
  ) order by (f.priority in ('high','critical')) desc,f.created_at desc,f.id),'[]'::jsonb)
  into v_items from filtered f;

  select jsonb_build_object(
    'open',count(*) filter(where e.status='open'),
    'in_progress',count(*) filter(where e.status='in_progress'),
    'closed',count(*) filter(where e.status in ('resolved','closed')),
    'overdue',count(*) filter(where e.due_at<now() and e.status not in ('resolved','closed'))
  ) into v_metrics
  from public.enquiries e where (p_branch_id is null or e.branch_id=p_branch_id);

  select coalesce(jsonb_agg(jsonb_build_object('id',h.memberid,'name',h.full_name,'branch_id',h.branch_id) order by h.full_name),'[]'::jsonb)
  into v_handlers
  from (
    select distinct on (r.memberid) r.memberid,r.full_name,r.branch_id
    from public.roles r
    where r.is_active is true and lower(coalesce(r.rolename,'')) in ('admin','globaladmin')
      and (p_branch_id is null or r.branch_id=p_branch_id or lower(coalesce(r.rolename,''))='globaladmin')
    order by r.memberid,r.is_primary desc,r.assigned_at desc
  ) h;

  return jsonb_build_object(
    'metrics',coalesce(v_metrics,'{}'::jsonb),'items',v_items,'handlers',v_handlers,
    'pagination',jsonb_build_object('page',v_page,'page_size',v_page_size,'total',v_total,'total_pages',greatest(1,ceil(v_total::numeric/v_page_size)::integer))
  );
end $$;

create or replace function public.churchmetric_enquiry_thread_v1(p_enquiry_id uuid)
returns jsonb
language plpgsql
stable
security invoker
set search_path = ''
as $$
declare v_enquiry jsonb; v_messages jsonb;
begin
  select jsonb_build_object(
    'id',e.id,'branch_id',e.branch_id,'subject',e.subject,'body',e.body,'category',e.category,
    'priority',e.priority,'status',e.status,'assigned_to',e.assigned_to,'due_at',e.due_at,
    'resolved_at',e.resolved_at,'created_at',e.created_at,
    'sender_name',coalesce(nullif(p.full_name,''),'External contact'),'sender_email',p.email,
    'handler_name',(select r.full_name from public.roles r where r.memberid=e.assigned_to and r.is_active is true order by r.is_primary desc,r.assigned_at desc limit 1)
  ) into v_enquiry
  from public.enquiries e left join public.profiles p on p.id=e.member_id
  where e.id=p_enquiry_id;
  if v_enquiry is null then raise exception 'enquiry_not_found' using errcode='P0002'; end if;

  select coalesce(jsonb_agg(jsonb_build_object(
    'id',m.id,'body',m.body,'is_internal',m.is_internal,'delivery_status',m.delivery_status,
    'sender_id',m.sender_id,'created_at',m.created_at
  ) order by m.created_at,m.id),'[]'::jsonb) into v_messages
  from public.enquiry_messages m where m.enquiry_id=p_enquiry_id;
  return v_enquiry||jsonb_build_object('messages',v_messages);
end $$;

create or replace function public.churchmetric_reply_to_enquiry_v1(p_enquiry_id uuid,p_body text)
returns jsonb
language plpgsql
security invoker
set search_path = ''
as $$
declare v_enquiry public.enquiries%rowtype; v_message public.enquiry_messages%rowtype; v_email text;
begin
  if nullif(btrim(coalesce(p_body,'')),'') is null or char_length(btrim(p_body))>4000 then
    raise exception 'invalid_reply' using errcode='22023';
  end if;
  select * into v_enquiry from public.enquiries where id=p_enquiry_id for update;
  if not found then raise exception 'enquiry_not_found' using errcode='P0002'; end if;
  if not public.churchmetric_can_manage_branch(v_enquiry.branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  select p.email into v_email from public.profiles p where p.id=v_enquiry.member_id;
  insert into public.enquiry_messages(branch_id,enquiry_id,sender_id,body,is_internal,delivery_status)
  values(v_enquiry.branch_id,v_enquiry.id,auth.uid(),btrim(p_body),false,case when nullif(btrim(coalesce(v_email,'')),'') is null then 'sent' else 'queued' end)
  returning * into v_message;
  update public.enquiries set status=case when status='open' then 'in_progress' else status end,updated_at=now() where id=v_enquiry.id;
  if nullif(btrim(coalesce(v_email,'')),'') is not null then
    insert into public.notification_outbox(branch_id,event_type,aggregate_id,channel,payload,idempotency_key)
    values(v_enquiry.branch_id,'enquiry_response_created',v_message.id,'email',jsonb_build_object('message_id',v_message.id,'enquiry_id',v_enquiry.id),v_message.id::text);
  end if;
  insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata)
  values(v_enquiry.branch_id,auth.uid(),'enquiry_response_sent','enquiry',v_enquiry.id,jsonb_build_object('message_id',v_message.id,'delivery_queued',v_email is not null));
  return jsonb_build_object('id',v_message.id,'delivery_status',v_message.delivery_status,'created_at',v_message.created_at);
end $$;

create or replace function public.churchmetric_set_enquiry_status_v1(p_enquiry_id uuid,p_status text)
returns text
language plpgsql
security invoker
set search_path = ''
as $$
declare v_enquiry public.enquiries%rowtype; v_next text:=lower(btrim(coalesce(p_status,'')));
begin
  select * into v_enquiry from public.enquiries where id=p_enquiry_id for update;
  if not found then raise exception 'enquiry_not_found' using errcode='P0002'; end if;
  if not public.churchmetric_can_manage_branch(v_enquiry.branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if not ((v_enquiry.status in ('open','in_progress') and v_next in ('in_progress','resolved','closed')) or (v_enquiry.status in ('resolved','closed') and v_next='open') or v_next=v_enquiry.status) then
    raise exception 'invalid_status_transition' using errcode='22023';
  end if;
  update public.enquiries set status=v_next,resolved_at=case when v_next in ('resolved','closed') then coalesce(resolved_at,now()) else null end,updated_at=now() where id=v_enquiry.id;
  if v_next<>v_enquiry.status then
    insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata)
    values(v_enquiry.branch_id,auth.uid(),'enquiry_status_changed','enquiry',v_enquiry.id,jsonb_build_object('from',v_enquiry.status,'to',v_next));
  end if;
  return v_next;
end $$;

create or replace function public.churchmetric_assign_enquiry_v1(p_enquiry_id uuid,p_handler_id uuid default null)
returns uuid
language plpgsql
security invoker
set search_path = ''
as $$
declare v_enquiry public.enquiries%rowtype;
begin
  select * into v_enquiry from public.enquiries where id=p_enquiry_id for update;
  if not found then raise exception 'enquiry_not_found' using errcode='P0002'; end if;
  if not public.churchmetric_can_manage_branch(v_enquiry.branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if p_handler_id is not null and not exists(
    select 1 from public.roles r where r.memberid=p_handler_id and r.is_active is true
      and lower(coalesce(r.rolename,'')) in ('admin','globaladmin')
      and (r.branch_id=v_enquiry.branch_id or lower(coalesce(r.rolename,''))='globaladmin')
  ) then raise exception 'invalid_handler' using errcode='22023'; end if;
  update public.enquiries set assigned_to=p_handler_id,updated_at=now() where id=v_enquiry.id;
  insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata)
  values(v_enquiry.branch_id,auth.uid(),'enquiry_handler_assigned','enquiry',v_enquiry.id,jsonb_build_object('assigned',p_handler_id is not null));
  return p_handler_id;
end $$;

revoke all on function public.churchmetric_enquiries_inbox_v1(uuid,text,text,integer,integer) from public,anon;
revoke all on function public.churchmetric_enquiry_thread_v1(uuid) from public,anon;
revoke all on function public.churchmetric_reply_to_enquiry_v1(uuid,text) from public,anon;
revoke all on function public.churchmetric_set_enquiry_status_v1(uuid,text) from public,anon;
revoke all on function public.churchmetric_assign_enquiry_v1(uuid,uuid) from public,anon;
grant execute on function public.churchmetric_enquiries_inbox_v1(uuid,text,text,integer,integer) to authenticated;
grant execute on function public.churchmetric_enquiry_thread_v1(uuid) to authenticated;
grant execute on function public.churchmetric_reply_to_enquiry_v1(uuid,text) to authenticated;
grant execute on function public.churchmetric_set_enquiry_status_v1(uuid,text) to authenticated;
grant execute on function public.churchmetric_assign_enquiry_v1(uuid,uuid) to authenticated;

create or replace function public.churchmetric_claim_email_outbox(p_limit integer default 10)
returns setof public.notification_outbox
language sql
security definer
set search_path = ''
as $$
  with candidates as (
    select item.id from public.notification_outbox item
    where item.channel='email'
      and item.event_type in ('broadcast_campaign_created','enquiry_response_created')
      and item.processed_at is null and item.available_at<=now() and item.attempts<5
      and (item.status in ('pending','retry') or (item.status='processing' and item.locked_at<now()-interval '15 minutes'))
    order by item.available_at,item.created_at for update skip locked
    limit greatest(1,least(coalesce(p_limit,10),50))
  )
  update public.notification_outbox item set status='processing',locked_at=now(),attempts=item.attempts+1,last_error=null
  from candidates where item.id=candidates.id returning item.*
$$;
revoke all on function public.churchmetric_claim_email_outbox(integer) from public,anon,authenticated;
grant execute on function public.churchmetric_claim_email_outbox(integer) to service_role;
