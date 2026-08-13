alter table public.quality_reports
  add column if not exists resolved_at timestamptz;

update public.quality_reports
set resolved_at = coalesce(resolved_at, updated_at)
where status in ('resolved', 'closed') and resolved_at is null;

create index if not exists quality_reports_branch_source_status_created_idx
  on public.quality_reports(branch_id, source, status, created_at desc);

create or replace function public.churchmetric_quality_reports_inbox_v1(
  p_branch_id uuid default null,
  p_search text default null,
  p_source text default null,
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
  v_handlers jsonb;
begin
  if p_branch_id is not null and not public.churchmetric_can_manage_branch(p_branch_id) then
    raise exception 'not_authorized' using errcode = '42501';
  end if;
  if p_source is not null and p_source not in ('member', 'leader') then
    raise exception 'invalid_source' using errcode = '22023';
  end if;
  if p_status is not null and p_status not in ('open', 'in_review', 'resolved', 'closed') then
    raise exception 'invalid_status' using errcode = '22023';
  end if;

  select count(*) into v_total
  from public.quality_reports r
  left join public.profiles reporter on reporter.id = r.reporter_id
  where (p_branch_id is null or r.branch_id = p_branch_id)
    and (p_source is null or lower(r.source) = p_source)
    and (p_status is null or r.status = p_status)
    and (v_search is null or r.subject ilike '%' || v_search || '%'
      or r.category ilike '%' || v_search || '%'
      or r.id::text ilike '%' || v_search || '%'
      or reporter.full_name ilike '%' || v_search || '%'
      or reporter.email ilike '%' || v_search || '%');

  select coalesce(jsonb_agg(to_jsonb(item) order by item.created_at desc), '[]'::jsonb) into v_items
  from (
    select r.id, r.branch_id, r.subject, r.source, r.category, r.priority, r.status,
      r.assigned_to, r.created_at, reporter.full_name as reporter_name,
      reporter.email as reporter_email, handler.full_name as handler_name
    from public.quality_reports r
    left join public.profiles reporter on reporter.id = r.reporter_id
    left join public.profiles handler on handler.id = r.assigned_to
    where (p_branch_id is null or r.branch_id = p_branch_id)
      and (p_source is null or lower(r.source) = p_source)
      and (p_status is null or r.status = p_status)
      and (v_search is null or r.subject ilike '%' || v_search || '%'
        or r.category ilike '%' || v_search || '%'
        or r.id::text ilike '%' || v_search || '%'
        or reporter.full_name ilike '%' || v_search || '%'
        or reporter.email ilike '%' || v_search || '%')
    order by r.created_at desc
    offset (v_page - 1) * v_page_size limit v_page_size
  ) item;

  select jsonb_build_object(
    'open_reports', count(*) filter (where r.status in ('open', 'in_review')),
    'active_queries', (select count(*) from public.quality_queries q where (p_branch_id is null or q.branch_id = p_branch_id) and q.status in ('open', 'awaiting_response')),
    'open_issues', (select count(*) from public.quality_issues i where (p_branch_id is null or i.branch_id = p_branch_id) and i.status in ('open', 'investigating', 'in_progress')),
    'average_resolution_hours', coalesce(round(avg(extract(epoch from (r.resolved_at - r.created_at)) / 3600) filter (where r.resolved_at is not null), 1), 0)
  ) into v_metrics
  from public.quality_reports r
  where p_branch_id is null or r.branch_id = p_branch_id;

  select coalesce(jsonb_agg(jsonb_build_object('id', p.id, 'name', p.full_name) order by p.full_name), '[]'::jsonb)
  into v_handlers
  from public.roles role
  join public.profiles p on p.id = role.memberid
  where role.is_active is true and lower(role.rolename) in ('admin', 'globaladmin')
    and (p_branch_id is null or role.branch_id = p_branch_id or lower(role.rolename) = 'globaladmin');

  return jsonb_build_object(
    'metrics', v_metrics,
    'items', v_items,
    'handlers', v_handlers,
    'pagination', jsonb_build_object('page', v_page, 'page_size', v_page_size, 'total', v_total)
  );
end $$;

create or replace function public.churchmetric_quality_report_detail_v1(p_report_id uuid)
returns jsonb
language sql
security invoker
set search_path = ''
stable
as $$
  select to_jsonb(detail)
  from (
    select r.id, r.branch_id, r.subject, r.description, r.source, r.category, r.priority,
      r.status, r.assigned_to, r.created_at, r.updated_at, r.resolved_at,
      reporter.full_name as reporter_name, reporter.email as reporter_email,
      handler.full_name as handler_name
    from public.quality_reports r
    left join public.profiles reporter on reporter.id = r.reporter_id
    left join public.profiles handler on handler.id = r.assigned_to
    where r.id = p_report_id
  ) detail
$$;

create or replace function public.churchmetric_transition_quality_report(
  p_report_id uuid,
  p_action text
) returns text
language plpgsql
security invoker
set search_path = ''
as $$
declare
  report_row public.quality_reports%rowtype;
  next_status text;
begin
  select * into report_row from public.quality_reports where id = p_report_id for update;
  if not found then raise exception 'report_not_found' using errcode = 'P0002'; end if;
  if not public.churchmetric_can_manage_branch(report_row.branch_id) then raise exception 'not_authorized' using errcode = '42501'; end if;

  if p_action = 'resolve' and report_row.status in ('open', 'in_review') then next_status := 'resolved';
  elsif p_action = 'escalate' and report_row.status = 'open' then next_status := 'in_review';
  elsif p_action = 'reopen' and report_row.status in ('resolved', 'closed') then next_status := 'open';
  else raise exception 'invalid_status_transition' using errcode = '22023';
  end if;

  update public.quality_reports
  set status = next_status,
      resolved_at = case when next_status = 'resolved' then now() when next_status = 'open' then null else resolved_at end,
      updated_at = now()
  where id = p_report_id;

  insert into public.quality_status_history(branch_id, entity_type, entity_id, from_status, to_status, changed_by)
  values(report_row.branch_id, 'report', report_row.id, report_row.status, next_status, auth.uid());

  if p_action = 'escalate' and not exists(select 1 from public.quality_issues where report_id = report_row.id) then
    insert into public.quality_issues(branch_id, report_id, title, description, area, priority, status, created_by)
    values(report_row.branch_id, report_row.id, report_row.subject, report_row.description, report_row.category, report_row.priority, 'open', auth.uid());
  end if;

  insert into public.churchmetric_audit_events(branch_id, actor_id, action, entity_type, entity_id, metadata)
  values(report_row.branch_id, auth.uid(), 'quality_report_' || p_action, 'quality_report', report_row.id,
    jsonb_build_object('from', report_row.status, 'to', next_status));
  return next_status;
end $$;

create or replace function public.churchmetric_assign_quality_report(p_report_id uuid, p_assignee_id uuid)
returns void
language plpgsql
security invoker
set search_path = ''
as $$
declare report_row public.quality_reports%rowtype;
begin
  select * into report_row from public.quality_reports where id = p_report_id for update;
  if not found then raise exception 'report_not_found' using errcode = 'P0002'; end if;
  if not public.churchmetric_can_manage_branch(report_row.branch_id) then raise exception 'not_authorized' using errcode = '42501'; end if;
  if p_assignee_id is not null and not exists(
    select 1 from public.roles role where role.memberid = p_assignee_id and role.is_active is true
      and (role.branch_id = report_row.branch_id or lower(role.rolename) = 'globaladmin')
  ) then raise exception 'invalid_assignee' using errcode = '22023'; end if;
  update public.quality_reports set assigned_to = p_assignee_id, updated_at = now() where id = p_report_id;
  insert into public.churchmetric_audit_events(branch_id, actor_id, action, entity_type, entity_id, metadata)
  values(report_row.branch_id, auth.uid(), 'quality_report_assigned', 'quality_report', report_row.id,
    jsonb_build_object('assignee_id', p_assignee_id));
end $$;

revoke all on function public.churchmetric_quality_reports_inbox_v1(uuid,text,text,text,integer,integer) from public, anon;
revoke all on function public.churchmetric_quality_report_detail_v1(uuid) from public, anon;
revoke all on function public.churchmetric_transition_quality_report(uuid,text) from public, anon;
revoke all on function public.churchmetric_assign_quality_report(uuid,uuid) from public, anon;
grant execute on function public.churchmetric_quality_reports_inbox_v1(uuid,text,text,text,integer,integer) to authenticated;
grant execute on function public.churchmetric_quality_report_detail_v1(uuid) to authenticated;
grant execute on function public.churchmetric_transition_quality_report(uuid,text) to authenticated;
grant execute on function public.churchmetric_assign_quality_report(uuid,uuid) to authenticated;
