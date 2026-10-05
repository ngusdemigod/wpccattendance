begin;

create table private.community_report_reviewers (
  id uuid primary key default gen_random_uuid(),
  reviewer_id uuid not null references public.profiles(id),
  destination text not null check (destination in ('branch','central')),
  branch_id uuid references public.branches(id),
  check ((destination='branch') = (branch_id is not null))
);
create unique index community_report_reviewer_scope on private.community_report_reviewers
  (reviewer_id,destination,coalesce(branch_id,'00000000-0000-0000-0000-000000000000'::uuid));
create index community_report_destination on private.community_report_reviewers(destination,branch_id);
create table private.community_anonymous_reports (
  id uuid primary key default gen_random_uuid(),
  destination text not null check (destination in ('branch','central')),
  branch_id uuid references public.branches(id),
  department_id uuid references public.departments(id),
  body text not null check (char_length(btrim(body)) between 20 and 5000),
  status text not null default 'Submitted' check (status in ('Submitted','In review','Closed')),
  created_at timestamptz not null default now(),
  check ((destination='branch') = (branch_id is not null))
);
create index community_anonymous_inbox on private.community_anonymous_reports(destination,branch_id,created_at desc);
create table private.community_anonymous_senders (
  report_id uuid primary key references private.community_anonymous_reports(id),
  sender_id uuid not null references public.profiles(id),
  retry_key uuid not null,
  created_at timestamptz not null default now(),
  unique(sender_id,retry_key)
);
create index community_anonymous_rate on private.community_anonymous_senders(sender_id,created_at);
create table private.community_report_audit (
  id bigint generated always as identity primary key,
  actor_id uuid not null references public.profiles(id),
  report_id uuid references private.community_anonymous_reports(id),
  action text not null,
  details jsonb not null default '{}',
  created_at timestamptz not null default now()
);
alter table private.community_report_reviewers enable row level security;
alter table private.community_anonymous_reports enable row level security;
alter table private.community_anonymous_senders enable row level security;
alter table private.community_report_audit enable row level security;
revoke all on private.community_report_reviewers,private.community_anonymous_reports,
  private.community_anonymous_senders,private.community_report_audit from public,anon,authenticated;

create function public.community_anonymous_destinations()
returns table(destination text) language sql stable security definer set search_path='' as $$
  select distinct r.destination from private.community_report_reviewers r
  where auth.uid() is not null and (r.destination='central' or r.branch_id=
    (select p.branch_id from public.profiles p where p.id=auth.uid()))
$$;

create function public.community_submit_anonymous(p_destination text,p_body text,p_retry_key uuid,p_department_id uuid default null)
returns uuid language plpgsql security definer set search_path='' as $$
declare v_uid uuid:=auth.uid(); v_branch uuid; v_id uuid;
begin
  if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
  select p.branch_id into v_branch from public.profiles p where p.id=v_uid for update;
  if not found then raise exception 'Profile required' using errcode='42501'; end if;
  if p_retry_key is null then raise exception 'Retry key required' using errcode='22023'; end if;
  select s.report_id into v_id from private.community_anonymous_senders s where s.sender_id=v_uid and s.retry_key=p_retry_key;
  if v_id is not null then return v_id; end if;
  if p_destination is null or p_destination not in ('branch','central') or p_body is null
    or char_length(btrim(p_body)) not between 20 and 5000 then
    raise exception 'Choose a destination and enter 20 to 5000 characters' using errcode='22023';
  end if;
  if p_department_id is not null and not (
    exists(select 1 from public.profile_departments d where d.profile_id=v_uid and d.branch_id=v_branch and d.department_id=p_department_id)
    or exists(select 1 from public.profiles p where p.id=v_uid and p.department_id=p_department_id)
  ) then raise exception 'Active department membership required' using errcode='42501'; end if;
  if not exists(select 1 from private.community_report_reviewers r where r.destination=p_destination
    and (p_destination='central' or r.branch_id=v_branch)) then
    raise exception 'No reviewers available for this destination' using errcode='22023';
  end if;
  if (select count(*) from private.community_anonymous_senders s where s.sender_id=v_uid and s.created_at>now()-interval '24 hours')>=3 then
    raise exception 'Submission limit reached. Please try tomorrow.' using errcode='54000';
  end if;
  insert into private.community_anonymous_reports(destination,branch_id,department_id,body)
    values(p_destination,case when p_destination='branch' then v_branch end,p_department_id,btrim(p_body)) returning id into v_id;
  insert into private.community_anonymous_senders(report_id,sender_id,retry_key) values(v_id,v_uid,p_retry_key);
  return v_id;
end $$;

create function public.community_anonymous_reports(p_inbox boolean default false)
returns table(id uuid,destination text,department_id uuid,body text,status text,created_at timestamptz)
language sql stable security definer set search_path='' as $$
  select r.id,r.destination,r.department_id,r.body,r.status,r.created_at
  from private.community_anonymous_reports r where auth.uid() is not null and
  case when p_inbox then exists(select 1 from private.community_report_reviewers a
    where a.reviewer_id=auth.uid() and a.destination=r.destination and a.branch_id is not distinct from r.branch_id)
  else exists(select 1 from private.community_anonymous_senders s where s.report_id=r.id and s.sender_id=auth.uid()) end
  order by r.created_at desc limit 100
$$;

create function public.community_review_anonymous(p_id uuid,p_status text)
returns void language plpgsql security definer set search_path='' as $$
declare v_old text;
begin
  select r.status into v_old from private.community_anonymous_reports r where r.id=p_id and exists(
    select 1 from private.community_report_reviewers a where a.reviewer_id=auth.uid()
    and a.destination=r.destination and a.branch_id is not distinct from r.branch_id) for update;
  if not found then raise exception 'Not authorized' using errcode='42501'; end if;
  if p_status is null or not ((v_old='Submitted' and p_status in ('In review','Closed')) or (v_old='In review' and p_status='Closed')) then
    raise exception 'Invalid status transition' using errcode='22023'; end if;
  update private.community_anonymous_reports set status=p_status where id=p_id;
  insert into private.community_report_audit(actor_id,report_id,action,details)
    values(auth.uid(),p_id,'status',jsonb_build_object('from',v_old,'to',p_status));
end $$;

create function public.community_assign_report_reviewer(p_reviewer uuid,p_destination text,p_branch uuid default null,p_remove boolean default false)
returns void language plpgsql security definer set search_path='' as $$
begin
  if auth.uid() is null or not exists(select 1 from public.current_access_scope() s where s.is_global_admin) then
    raise exception 'Global administrator required' using errcode='42501'; end if;
  if p_destination is null or p_destination not in ('branch','central') or (p_destination='branch')<>(p_branch is not null) then
    raise exception 'Invalid destination' using errcode='22023'; end if;
  if p_remove then
    delete from private.community_report_reviewers where reviewer_id=p_reviewer and destination=p_destination and branch_id is not distinct from p_branch;
  else
    insert into private.community_report_reviewers(reviewer_id,destination,branch_id) values(p_reviewer,p_destination,p_branch) on conflict do nothing;
  end if;
  insert into private.community_report_audit(actor_id,action,details) values(auth.uid(),
    case when p_remove then 'reviewer_removed' else 'reviewer_assigned' end,
    jsonb_build_object('reviewer',p_reviewer,'destination',p_destination,'branch',p_branch));
end $$;

revoke all on function public.community_anonymous_destinations(),public.community_submit_anonymous(text,text,uuid,uuid),
  public.community_anonymous_reports(boolean),public.community_review_anonymous(uuid,text),
  public.community_assign_report_reviewer(uuid,text,uuid,boolean) from public,anon;
grant execute on function public.community_anonymous_destinations(),public.community_submit_anonymous(text,text,uuid,uuid),
  public.community_anonymous_reports(boolean),public.community_review_anonymous(uuid,text),
  public.community_assign_report_reviewer(uuid,text,uuid,boolean) to authenticated;
commit;
