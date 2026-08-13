alter table public.broadcast_campaigns
  add column if not exists audience_category text not null default 'individuals'
  check (audience_category in ('individuals','all','departments','souls','leaders'));

create index if not exists broadcast_campaigns_branch_created_idx
  on public.broadcast_campaigns(branch_id,created_at desc);

create or replace function public.churchmetric_create_email_campaign_v1(
  p_branch_id uuid,
  p_name text,
  p_subject text,
  p_body text,
  p_scheduled_at timestamptz,
  p_audience_category text,
  p_recipients jsonb
) returns uuid
language plpgsql
security invoker
set search_path=''
as $$
declare
  new_campaign_id uuid;
  recipient_record jsonb;
  destination_value text;
begin
  if not public.churchmetric_can_manage_branch(p_branch_id) then
    raise exception 'not_authorized' using errcode='42501';
  end if;
  if nullif(btrim(p_name),'') is null then raise exception 'campaign_name_required' using errcode='22023'; end if;
  if nullif(btrim(p_subject),'') is null then raise exception 'email_subject_required' using errcode='22023'; end if;
  if nullif(btrim(p_body),'') is null then raise exception 'message_required' using errcode='22023'; end if;
  if p_audience_category not in ('individuals','all','departments','souls','leaders') then
    raise exception 'invalid_audience_category' using errcode='22023';
  end if;
  if jsonb_typeof(p_recipients)<>'array' or jsonb_array_length(p_recipients)=0 then
    raise exception 'recipient_required' using errcode='22023';
  end if;

  insert into public.broadcast_campaigns(
    branch_id,name,channel,subject,body,status,scheduled_at,audience_category,created_by
  ) values (
    p_branch_id,btrim(p_name),'email',btrim(p_subject),btrim(p_body),
    case when p_scheduled_at is null or p_scheduled_at<=now() then 'dispatching' else 'scheduled' end,
    p_scheduled_at,p_audience_category,auth.uid()
  ) returning id into new_campaign_id;

  for recipient_record in select value from jsonb_array_elements(p_recipients) loop
    destination_value:=lower(btrim(recipient_record->>'destination'));
    if destination_value !~ '^[^[:space:]@]+@[^[:space:]@]+\.[^[:space:]@]+$' then
      raise exception 'invalid_email_destination' using errcode='22023';
    end if;
    insert into public.broadcast_recipients(branch_id,campaign_id,profile_id,destination)
    values(p_branch_id,new_campaign_id,nullif(recipient_record->>'profile_id','')::uuid,destination_value)
    on conflict on constraint broadcast_recipients_campaign_id_destination_key do nothing;
  end loop;

  insert into public.notification_outbox(
    branch_id,event_type,aggregate_id,channel,payload,idempotency_key,available_at
  ) values (
    p_branch_id,'broadcast_campaign_created',new_campaign_id,'email',
    jsonb_build_object('campaign_id',new_campaign_id),new_campaign_id::text,coalesce(p_scheduled_at,now())
  );
  insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_branch_id,auth.uid(),'broadcast_submitted','broadcast_campaign',new_campaign_id,
    jsonb_build_object('channel','email','audience_category',p_audience_category,'recipient_count',
      (select count(*) from public.broadcast_recipients where campaign_id=new_campaign_id)));
  return new_campaign_id;
end $$;

revoke all on function public.churchmetric_create_email_campaign_v1(uuid,text,text,text,timestamptz,text,jsonb) from public,anon;
grant execute on function public.churchmetric_create_email_campaign_v1(uuid,text,text,text,timestamptz,text,jsonb) to authenticated;

create or replace function public.churchmetric_followups_v1(
  p_branch_id uuid default null,
  p_search text default null,
  p_status text default null,
  p_page integer default 1,
  p_page_size integer default 25
) returns jsonb
language plpgsql
security invoker
set search_path=''
as $$
declare
  resolved_branch uuid;
  page_number integer:=greatest(coalesce(p_page,1),1);
  page_limit integer:=greatest(1,least(coalesce(p_page_size,25),100));
  total_count bigint;
  result jsonb;
begin
  resolved_branch:=public.churchmetric_resolve_branch(p_branch_id);
  with scoped as (
    select c.*,
      count(r.id)::integer total_recipients,
      count(r.id) filter(where r.status in ('sent','delivered'))::integer completed_recipients,
      count(r.id) filter(where r.status='failed')::integer failed_recipients
    from public.broadcast_campaigns c
    left join public.broadcast_recipients r on r.campaign_id=c.id and r.branch_id=c.branch_id
    where c.branch_id=resolved_branch
      and (nullif(btrim(p_search),'') is null or c.name ilike '%'||btrim(p_search)||'%' or c.subject ilike '%'||btrim(p_search)||'%')
      and (nullif(btrim(p_status),'') is null or c.status=p_status)
    group by c.id
  ), counted as (select count(*) total from scoped),
  page_rows as (
    select * from scoped order by created_at desc
    offset (page_number-1)*page_limit limit page_limit
  ), all_metrics as (
    select
      count(*) filter(where status='sent')::integer campaigns_sent,
      coalesce(sum(completed_recipients),0)::integer recipients_reached,
      coalesce(sum(completed_recipients),0)::numeric completed,
      coalesce(sum(total_recipients),0)::numeric total,
      count(*) filter(where channel='call' and status not in ('sent','cancelled','failed'))::integer calls_pending
    from scoped
  )
  select jsonb_build_object(
    'metrics',jsonb_build_object(
      'campaigns_sent',m.campaigns_sent,
      'recipients_reached',m.recipients_reached,
      'delivery_rate',case when m.total=0 then 0 else round(m.completed*100/m.total) end,
      'calls_pending',m.calls_pending
    ),
    'items',coalesce((select jsonb_agg(to_jsonb(x) order by x.created_at desc) from page_rows x),'[]'::jsonb),
    'pagination',jsonb_build_object('page',page_number,'page_size',page_limit,'total',(select total from counted))
  ) into result from all_metrics m;
  return result;
end $$;

revoke all on function public.churchmetric_followups_v1(uuid,text,text,integer,integer) from public,anon;
grant execute on function public.churchmetric_followups_v1(uuid,text,text,integer,integer) to authenticated;

comment on function public.churchmetric_followups_v1(uuid,text,text,integer,integer) is
  'Branch-authorized campaign history and full filtered-scope delivery metrics; recipient destinations and message bodies are excluded.';
