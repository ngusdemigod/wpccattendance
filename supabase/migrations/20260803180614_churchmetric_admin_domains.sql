-- ChurchMetric admin domains. Additive only: existing Flutter tables remain authoritative.
-- Dashboard tenancy maps to public.branches; globaladmin is the only cross-branch role.

create or replace function public.churchmetric_role()
returns text language sql stable security invoker set search_path = ''
as $$ select coalesce(auth.jwt() ->> 'wprole', '') $$;

create or replace function public.churchmetric_branch_id()
returns uuid language sql stable security invoker set search_path = ''
as $$ select nullif(auth.jwt() ->> 'wpbranch_id', '')::uuid $$;

create or replace function public.churchmetric_can_read_branch(target_branch uuid)
returns boolean language sql stable security invoker set search_path = ''
as $$
  select auth.uid() is not null and (
    public.churchmetric_role() = 'globaladmin'
    or (public.churchmetric_role() in ('admin', 'superuser') and target_branch = public.churchmetric_branch_id())
  )
$$;

create or replace function public.churchmetric_can_manage_branch(target_branch uuid)
returns boolean language sql stable security invoker set search_path = ''
as $$
  select auth.uid() is not null and (
    public.churchmetric_role() = 'globaladmin'
    or (public.churchmetric_role() = 'admin' and target_branch = public.churchmetric_branch_id())
  )
$$;

revoke all on function public.churchmetric_role() from public, anon;
revoke all on function public.churchmetric_branch_id() from public, anon;
revoke all on function public.churchmetric_can_read_branch(uuid) from public, anon;
revoke all on function public.churchmetric_can_manage_branch(uuid) from public, anon;
grant execute on function public.churchmetric_role() to authenticated;
grant execute on function public.churchmetric_branch_id() to authenticated;
grant execute on function public.churchmetric_can_read_branch(uuid) to authenticated;
grant execute on function public.churchmetric_can_manage_branch(uuid) to authenticated;

create table if not exists public.evangelism_events (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), title text not null,
  description text, location text, starts_at timestamptz not null, ends_at timestamptz,
  status text not null default 'scheduled' check (status in ('scheduled','active','completed','cancelled')),
  created_by uuid not null references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check (ends_at is null or ends_at>=starts_at)
);
create table if not exists public.souls (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id),
  evangelism_event_id uuid not null references public.evangelism_events(id), recorded_by uuid not null references auth.users(id),
  full_name text not null, email text, phone text, status text not null default 'awaiting_contact'
    check (status in ('awaiting_contact','contacted','integrating','integrated','closed')),
  won_at timestamptz not null default now(), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.soul_followups (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), soul_id uuid not null references public.souls(id) on delete cascade,
  assigned_to uuid references auth.users(id), completed_by uuid references auth.users(id), channel text check (channel in ('call','sms','email','whatsapp','visit','other')),
  status text not null default 'pending' check (status in ('pending','completed','cancelled')), due_at timestamptz, completed_at timestamptz,
  notes text, created_by uuid not null references auth.users(id), created_at timestamptz not null default now()
);
create table if not exists public.enquiries (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), member_id uuid references public.profiles(id),
  category text not null, subject text not null, body text not null, status text not null default 'open' check (status in ('open','in_progress','resolved','closed')),
  priority text not null default 'medium' check (priority in ('low','medium','high','critical')), assigned_to uuid references auth.users(id),
  created_by uuid not null references auth.users(id), due_at timestamptz, resolved_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.enquiry_messages (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), enquiry_id uuid not null references public.enquiries(id) on delete cascade,
  sender_id uuid not null references auth.users(id), body text not null, is_internal boolean not null default false, created_at timestamptz not null default now()
);

create table if not exists public.quality_reports (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), reporter_id uuid references public.profiles(id),
  source text not null, category text not null, subject text not null, description text not null,
  priority text not null default 'medium' check (priority in ('low','medium','high','critical')),
  status text not null default 'open' check (status in ('open','in_review','resolved','closed')), assigned_to uuid references auth.users(id),
  created_by uuid not null references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.quality_queries (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), report_id uuid references public.quality_reports(id) on delete set null,
  subject text not null, body text not null, status text not null default 'open' check (status in ('open','awaiting_response','responded','closed')),
  priority text not null default 'medium' check (priority in ('low','medium','high','critical')), due_at timestamptz,
  created_by uuid not null references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.quality_query_assignees (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), query_id uuid not null references public.quality_queries(id) on delete cascade,
  assignee_id uuid not null references auth.users(id), responded_at timestamptz, response text, created_at timestamptz not null default now(), unique(query_id, assignee_id)
);
create table if not exists public.quality_issues (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), report_id uuid references public.quality_reports(id) on delete set null,
  title text not null, description text not null, area text not null, priority text not null default 'medium' check (priority in ('low','medium','high','critical')),
  status text not null default 'open' check (status in ('open','investigating','in_progress','resolved','closed')), owner_id uuid references auth.users(id),
  created_by uuid not null references auth.users(id), resolved_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.quality_status_history (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), entity_type text not null check (entity_type in ('report','query','issue')),
  entity_id uuid not null, from_status text, to_status text not null, changed_by uuid not null references auth.users(id), created_at timestamptz not null default now()
);

alter table public.courses add column if not exists status text not null default 'draft' check (status in ('draft','active','archived'));
alter table public.courses add column if not exists code text;
alter table public.course_enrollments add column if not exists branch_id uuid references public.branches(id);
alter table public.course_enrollments add column if not exists status text not null default 'not_started' check (status in ('not_started','in_progress','completed','withdrawn'));
alter table public.course_enrollments add column if not exists progress_percent integer not null default 0 check (progress_percent between 0 and 100);
alter table public.course_enrollments add column if not exists completed_at timestamptz;
update public.course_enrollments ce set branch_id = c.branch_id from public.courses c where ce.course_id = c.id and ce.branch_id is null;

create table if not exists public.academy_modules (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), course_id uuid not null references public.courses(id) on delete cascade,
  title text not null, description text, position integer not null default 0, created_by uuid not null references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.department_attachments (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), department_id uuid not null references public.departments(id) on delete cascade,
  object_path text not null unique, file_name text not null, mime_type text not null, size_bytes bigint not null check(size_bytes>0),
  created_by uuid not null references auth.users(id), created_at timestamptz not null default now()
);
create table if not exists public.academy_module_attachments (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), module_id uuid not null references public.academy_modules(id) on delete cascade,
  object_path text not null unique, file_name text not null, mime_type text not null, size_bytes bigint not null check (size_bytes > 0), created_by uuid not null references auth.users(id), created_at timestamptz not null default now()
);
create table if not exists public.academy_sessions (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), course_id uuid not null references public.courses(id) on delete cascade,
  title text not null, starts_at timestamptz not null, ends_at timestamptz, location text, capacity integer check (capacity is null or capacity > 0),
  status text not null default 'scheduled' check (status in ('scheduled','active','completed','cancelled')), created_by uuid not null references auth.users(id), created_at timestamptz not null default now()
);
create table if not exists public.academy_instructors (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), profile_id uuid not null references public.profiles(id),
  active boolean not null default true, bio text, created_by uuid not null references auth.users(id), created_at timestamptz not null default now(), unique(branch_id, profile_id)
);
create table if not exists public.academy_instructor_assignments (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), instructor_id uuid not null references public.academy_instructors(id) on delete cascade,
  course_id uuid not null references public.courses(id) on delete cascade, session_id uuid references public.academy_sessions(id) on delete cascade,
  created_by uuid not null references auth.users(id), created_at timestamptz not null default now(), unique(instructor_id, course_id, session_id)
);

create table if not exists public.communication_templates (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), name text not null, channel text not null check (channel in ('email','sms','whatsapp','call','in_app')),
  subject text, body text not null, active boolean not null default true, created_by uuid not null references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.broadcast_campaigns (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), name text not null, channel text not null check (channel in ('email','sms','whatsapp','call','in_app')),
  template_id uuid references public.communication_templates(id), subject text, body text not null,
  status text not null default 'draft' check (status in ('draft','scheduled','dispatching','sent','cancelled','failed')), scheduled_at timestamptz, sent_at timestamptz,
  created_by uuid not null references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table if not exists public.broadcast_recipients (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), campaign_id uuid not null references public.broadcast_campaigns(id) on delete cascade,
  profile_id uuid references public.profiles(id), destination text not null, status text not null default 'pending' check (status in ('pending','queued','sent','delivered','failed','cancelled')),
  provider_message_id text, created_at timestamptz not null default now(), unique(campaign_id, destination)
);
create table if not exists public.broadcast_delivery_events (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), recipient_id uuid not null references public.broadcast_recipients(id) on delete cascade,
  provider_event_id text not null, event_type text not null, occurred_at timestamptz not null, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now(), unique(provider_event_id)
);
create table if not exists public.provider_webhook_events (
  id uuid primary key default gen_random_uuid(), provider text not null, provider_event_id text not null, payload jsonb not null,
  received_at timestamptz not null default now(), processed_at timestamptz, processing_error text, unique(provider, provider_event_id)
);

create table if not exists public.targets (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), title text not null, metric text not null,
  period_type text not null check (period_type in ('day','week','month','quarter','year','event')), starts_at timestamptz not null, ends_at timestamptz not null,
  goal_value numeric not null check (goal_value > 0), current_value numeric not null default 0 check (current_value >= 0), progress_step numeric not null default 1 check (progress_step > 0),
  notification_channels text[] not null default '{}', status text not null default 'active' check (status in ('draft','active','achieved','cancelled','expired')),
  created_by uuid not null references auth.users(id), created_at timestamptz not null default now(), updated_at timestamptz not null default now(), check (ends_at >= starts_at)
);
create table if not exists public.target_progress_events (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), target_id uuid not null references public.targets(id) on delete cascade,
  delta numeric not null, value_after numeric not null check (value_after >= 0), source_type text not null, source_id uuid,
  idempotency_key text not null unique, recorded_by uuid not null references auth.users(id), created_at timestamptz not null default now()
);
create table if not exists public.target_achievements (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), target_id uuid not null references public.targets(id) on delete cascade,
  title text not null, achieved_at timestamptz not null default now(), created_at timestamptz not null default now(), unique(target_id)
);
create table if not exists public.notification_outbox (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), event_type text not null, aggregate_id uuid not null,
  channel text not null check (channel in ('email','sms','whatsapp','in_app')), payload jsonb not null, idempotency_key text not null unique,
  status text not null default 'pending' check (status in ('pending','processing','sent','failed','cancelled')), attempts integer not null default 0, available_at timestamptz not null default now(), processed_at timestamptz, last_error text, created_at timestamptz not null default now()
);
create table if not exists public.churchmetric_audit_events (
  id uuid primary key default gen_random_uuid(), branch_id uuid not null references public.branches(id), actor_id uuid not null references auth.users(id),
  action text not null, entity_type text not null, entity_id uuid not null, metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);

-- Operational indexes: tenant filter first, then common status/date and foreign-key lookups.
create index if not exists evangelism_events_branch_starts_idx on public.evangelism_events(branch_id,starts_at desc);
create index if not exists souls_branch_status_won_idx on public.souls(branch_id,status,won_at desc);
create index if not exists souls_event_idx on public.souls(evangelism_event_id);
create index if not exists soul_followups_soul_due_idx on public.soul_followups(soul_id,due_at);
create index if not exists enquiries_branch_status_created_idx on public.enquiries(branch_id,status,created_at desc);
create index if not exists enquiry_messages_enquiry_created_idx on public.enquiry_messages(enquiry_id,created_at);
create index if not exists quality_reports_branch_status_idx on public.quality_reports(branch_id,status,created_at desc);
create index if not exists quality_queries_branch_status_due_idx on public.quality_queries(branch_id,status,due_at);
create index if not exists quality_query_assignees_query_idx on public.quality_query_assignees(query_id);
create index if not exists quality_issues_branch_status_idx on public.quality_issues(branch_id,status,created_at desc);
create index if not exists quality_status_history_entity_idx on public.quality_status_history(entity_type,entity_id,created_at);
create index if not exists academy_modules_course_position_idx on public.academy_modules(course_id,position);
create index if not exists department_attachments_department_idx on public.department_attachments(department_id,created_at desc);
create index if not exists academy_sessions_course_starts_idx on public.academy_sessions(course_id,starts_at);
create index if not exists academy_assignments_course_idx on public.academy_instructor_assignments(course_id,session_id);
create index if not exists course_enrollments_branch_status_idx on public.course_enrollments(branch_id,status,created_at desc);
create index if not exists broadcast_campaigns_branch_status_idx on public.broadcast_campaigns(branch_id,status,created_at desc);
create index if not exists broadcast_recipients_campaign_status_idx on public.broadcast_recipients(campaign_id,status);
create index if not exists targets_branch_status_ends_idx on public.targets(branch_id,status,ends_at);
create index if not exists target_progress_target_created_idx on public.target_progress_events(target_id,created_at);
create index if not exists notification_outbox_dispatch_idx on public.notification_outbox(status,available_at) where status in ('pending','failed');
create index if not exists churchmetric_audit_branch_created_idx on public.churchmetric_audit_events(branch_id,created_at desc);

-- Explicit Data API exposure and restrictive branch-aware RLS.
do $policies$
declare table_name text;
begin
  foreach table_name in array array[
    'evangelism_events','souls','soul_followups','enquiries','enquiry_messages','quality_reports','quality_queries','quality_query_assignees','quality_issues','quality_status_history',
    'department_attachments','academy_modules','academy_module_attachments','academy_sessions','academy_instructors','academy_instructor_assignments',
    'communication_templates','broadcast_campaigns','broadcast_recipients','broadcast_delivery_events','targets','target_progress_events','target_achievements','notification_outbox','churchmetric_audit_events'
  ] loop
    execute format('alter table public.%I enable row level security', table_name);
    execute format('revoke all on table public.%I from anon', table_name);
    execute format('grant select, insert, update, delete on table public.%I to authenticated', table_name);
    execute format('create policy %I on public.%I for select to authenticated using (public.churchmetric_can_read_branch(branch_id))', table_name || '_admin_select', table_name);
    execute format('create policy %I on public.%I for insert to authenticated with check (public.churchmetric_can_manage_branch(branch_id))', table_name || '_admin_insert', table_name);
    execute format('create policy %I on public.%I for update to authenticated using (public.churchmetric_can_manage_branch(branch_id)) with check (public.churchmetric_can_manage_branch(branch_id))', table_name || '_admin_update', table_name);
    execute format('create policy %I on public.%I for delete to authenticated using (public.churchmetric_can_manage_branch(branch_id))', table_name || '_admin_delete', table_name);
  end loop;
end
$policies$;

alter table public.provider_webhook_events enable row level security;
revoke all on table public.provider_webhook_events from anon, authenticated;
grant all on table public.provider_webhook_events to service_role;

-- Existing academy tables retain their policies; dashboard access is layered additively.
create policy courses_churchmetric_select on public.courses for select to authenticated using (public.churchmetric_can_read_branch(branch_id));
create policy courses_churchmetric_insert on public.courses for insert to authenticated with check (public.churchmetric_can_manage_branch(branch_id));
create policy courses_churchmetric_update on public.courses for update to authenticated using (public.churchmetric_can_manage_branch(branch_id)) with check (public.churchmetric_can_manage_branch(branch_id));
create policy course_enrollments_churchmetric_select on public.course_enrollments for select to authenticated using (public.churchmetric_can_read_branch(branch_id));
create policy course_enrollments_churchmetric_insert on public.course_enrollments for insert to authenticated with check (public.churchmetric_can_manage_branch(branch_id));
create policy course_enrollments_churchmetric_update on public.course_enrollments for update to authenticated using (public.churchmetric_can_manage_branch(branch_id)) with check (public.churchmetric_can_manage_branch(branch_id));

create or replace function public.churchmetric_create_quality_query(
  p_branch_id uuid, p_subject text, p_body text, p_priority text, p_due_at timestamptz, p_assignee_ids uuid[]
) returns uuid language plpgsql security invoker set search_path = '' as $$
declare new_id uuid; assignee_id uuid;
begin
  if not public.churchmetric_can_manage_branch(p_branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if coalesce(array_length(p_assignee_ids,1),0)=0 then raise exception 'assignee_required' using errcode='22023'; end if;
  if p_due_at is not null and p_due_at < now() then raise exception 'due_date_in_past' using errcode='22023'; end if;
  insert into public.quality_queries(branch_id,subject,body,priority,due_at,created_by)
  values(p_branch_id,btrim(p_subject),btrim(p_body),p_priority,p_due_at,auth.uid()) returning id into new_id;
  foreach assignee_id in array p_assignee_ids loop
    insert into public.quality_query_assignees(branch_id,query_id,assignee_id) values(p_branch_id,new_id,assignee_id) on conflict(query_id,assignee_id) do nothing;
  end loop;
  insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata)
  values(p_branch_id,auth.uid(),'quality_query_created','quality_query',new_id,jsonb_build_object('assignee_count',array_length(p_assignee_ids,1)));
  return new_id;
end $$;

create or replace function public.churchmetric_transition_quality_issue(p_issue_id uuid,p_next_status text,p_note text default null)
returns void language plpgsql security invoker set search_path='' as $$
declare current_row public.quality_issues%rowtype;
begin
  select * into current_row from public.quality_issues where id=p_issue_id for update;
  if not found then raise exception 'issue_not_found' using errcode='P0002'; end if;
  if not public.churchmetric_can_manage_branch(current_row.branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if not ((current_row.status='open' and p_next_status='investigating') or (current_row.status='investigating' and p_next_status='in_progress') or (current_row.status='in_progress' and p_next_status='resolved') or (current_row.status='resolved' and p_next_status='closed')) then
    raise exception 'invalid_status_transition' using errcode='22023';
  end if;
  update public.quality_issues set status=p_next_status,resolved_at=case when p_next_status='resolved' then now() else resolved_at end,updated_at=now() where id=p_issue_id;
  insert into public.quality_status_history(branch_id,entity_type,entity_id,from_status,to_status,changed_by)
  values(current_row.branch_id,'issue',p_issue_id,current_row.status,p_next_status,auth.uid());
  insert into public.churchmetric_audit_events(branch_id,actor_id,action,entity_type,entity_id,metadata)
  values(current_row.branch_id,auth.uid(),'quality_issue_transitioned','quality_issue',p_issue_id,jsonb_build_object('from',current_row.status,'to',p_next_status,'has_note',nullif(btrim(p_note),'') is not null));
end $$;

create or replace function public.churchmetric_create_campaign(
  p_branch_id uuid,p_name text,p_channel text,p_subject text,p_body text,p_scheduled_at timestamptz,p_recipients jsonb
) returns uuid language plpgsql security invoker set search_path='' as $$
declare campaign_id uuid; recipient jsonb;
begin
  if not public.churchmetric_can_manage_branch(p_branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  if jsonb_typeof(p_recipients)<>'array' or jsonb_array_length(p_recipients)=0 then raise exception 'recipient_required' using errcode='22023'; end if;
  if p_channel='email' and nullif(btrim(p_subject),'') is null then raise exception 'email_subject_required' using errcode='22023'; end if;
  insert into public.broadcast_campaigns(branch_id,name,channel,subject,body,status,scheduled_at,created_by)
  values(p_branch_id,btrim(p_name),p_channel,nullif(btrim(p_subject),''),btrim(p_body),case when p_scheduled_at is null or p_scheduled_at<=now() then 'dispatching' else 'scheduled' end,p_scheduled_at,auth.uid()) returning id into campaign_id;
  for recipient in select value from jsonb_array_elements(p_recipients) loop
    insert into public.broadcast_recipients(branch_id,campaign_id,profile_id,destination)
    values(p_branch_id,campaign_id,nullif(recipient->>'profile_id','')::uuid,btrim(recipient->>'destination')) on conflict(campaign_id,destination) do nothing;
  end loop;
  insert into public.notification_outbox(branch_id,event_type,aggregate_id,channel,payload,idempotency_key,available_at)
  values(p_branch_id,'broadcast_campaign_created',campaign_id,case when p_channel='call' then 'in_app' else p_channel end,jsonb_build_object('campaign_id',campaign_id),campaign_id::text,coalesce(p_scheduled_at,now()));
  return campaign_id;
end $$;

create or replace function public.churchmetric_add_target_progress(p_target_id uuid,p_delta numeric,p_idempotency_key text,p_source_type text default 'manual',p_source_id uuid default null)
returns table(value_after numeric,achieved boolean) language plpgsql security invoker set search_path='' as $$
declare target_row public.targets%rowtype; next_value numeric; newly_achieved boolean:=false; channel_name text;
begin
  if p_delta=0 then raise exception 'progress_delta_required' using errcode='22023'; end if;
  select * into target_row from public.targets where id=p_target_id for update;
  if not found then raise exception 'target_not_found' using errcode='P0002'; end if;
  if not public.churchmetric_can_manage_branch(target_row.branch_id) then raise exception 'not_authorized' using errcode='42501'; end if;
  select tpe.value_after into next_value from public.target_progress_events tpe where tpe.idempotency_key=p_idempotency_key;
  if found then return query select next_value,target_row.status='achieved'; return; end if;
  next_value:=greatest(0,target_row.current_value+p_delta);
  insert into public.target_progress_events(branch_id,target_id,delta,value_after,source_type,source_id,idempotency_key,recorded_by)
  values(target_row.branch_id,p_target_id,p_delta,next_value,p_source_type,p_source_id,p_idempotency_key,auth.uid());
  if next_value>=target_row.goal_value and target_row.status<>'achieved' then newly_achieved:=true; end if;
  update public.targets set current_value=next_value,status=case when newly_achieved then 'achieved' else status end,updated_at=now() where id=p_target_id;
  if newly_achieved then
    insert into public.target_achievements(branch_id,target_id,title) values(target_row.branch_id,p_target_id,target_row.title) on conflict(target_id) do nothing;
    foreach channel_name in array target_row.notification_channels loop
      if channel_name in ('email','sms','whatsapp','in_app') then
        insert into public.notification_outbox(branch_id,event_type,aggregate_id,channel,payload,idempotency_key)
        values(target_row.branch_id,'target_achieved',p_target_id,channel_name,jsonb_build_object('target_id',p_target_id),p_target_id::text||':'||channel_name) on conflict(idempotency_key) do nothing;
      end if;
    end loop;
  end if;
  return query select next_value,target_row.status='achieved' or newly_achieved;
end $$;

revoke all on function public.churchmetric_create_quality_query(uuid,text,text,text,timestamptz,uuid[]) from public,anon;
revoke all on function public.churchmetric_transition_quality_issue(uuid,text,text) from public,anon;
revoke all on function public.churchmetric_create_campaign(uuid,text,text,text,text,timestamptz,jsonb) from public,anon;
revoke all on function public.churchmetric_add_target_progress(uuid,numeric,text,text,uuid) from public,anon;
grant execute on function public.churchmetric_create_quality_query(uuid,text,text,text,timestamptz,uuid[]) to authenticated;
grant execute on function public.churchmetric_transition_quality_issue(uuid,text,text) to authenticated;
grant execute on function public.churchmetric_create_campaign(uuid,text,text,text,text,timestamptz,jsonb) to authenticated;
grant execute on function public.churchmetric_add_target_progress(uuid,numeric,text,text,uuid) to authenticated;

create or replace function public.churchmetric_membership_overview(p_start_at timestamptz,p_end_at timestamptz,p_branch_id uuid default null)
returns jsonb language sql stable security invoker set search_path='' as $$
  with scoped_profiles as (
    select p.id,p.department_id,p.created_at from public.profiles p
    where (p_branch_id is null or p.branch_id=p_branch_id)
  ), active_members as (
    select count(distinct a.user_id)::integer as value from public.attendance a
    where (p_branch_id is null or a.branch_id=p_branch_id) and a.created_at>=p_start_at and a.created_at<p_end_at and a.status in ('confirmed','present')
  ), department_counts as (
    select d.id,d.name,count(sp.id)::integer as member_count from public.departments d left join scoped_profiles sp on sp.department_id=d.id group by d.id,d.name order by member_count desc,d.name
  )
  select jsonb_build_object(
    'total_members',(select count(*) from scoped_profiles),
    'active_members',(select value from active_members),
    'souls_won',(select count(*) from public.souls s where (p_branch_id is null or s.branch_id=p_branch_id) and s.won_at>=p_start_at and s.won_at<p_end_at),
    'new_members',(select count(*) from scoped_profiles where created_at>=p_start_at and created_at<p_end_at),
    'open_enquiries',(select count(*) from public.enquiries e where (p_branch_id is null or e.branch_id=p_branch_id) and e.status in ('open','in_progress')),
    'departments',(select coalesce(jsonb_agg(to_jsonb(dc)),'[]'::jsonb) from department_counts dc)
  )
$$;
revoke all on function public.churchmetric_membership_overview(timestamptz,timestamptz,uuid) from public,anon;
grant execute on function public.churchmetric_membership_overview(timestamptz,timestamptz,uuid) to authenticated;
