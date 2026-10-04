begin;
alter table public.department_requests add column if not exists branch_id uuid references public.branches(id);
alter table public.department_requests add column if not exists reviewed_by uuid references public.profiles(id);
alter table public.department_requests add column if not exists reviewed_at timestamptz;
update public.department_requests r set branch_id=p.branch_id from public.profiles p
where p.id=r.user_id and r.branch_id is null;
alter table public.department_requests enable row level security;
revoke all on public.department_requests from anon,authenticated;
grant select on public.department_requests to authenticated;
create policy community_department_requests_read on public.department_requests for select to authenticated
using (user_id=auth.uid() or public.churchmetric_can_manage_branch(branch_id));

create or replace function public.community_request_department(p_department_id uuid)
returns uuid language plpgsql security definer set search_path=''
as $function$
declare v_uid uuid:=auth.uid(); v_branch uuid; v_id uuid;
begin
  if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
  -- Serializes requests by a member and prevents duplicate pending requests.
  select branch_id into v_branch from public.profiles where id=v_uid for update;
  if v_branch is null then raise exception 'A branch is required'; end if;
  if not exists(select 1 from public.departments where id=p_department_id) then raise exception 'Department not found'; end if;
  if exists(select 1 from public.profile_departments where profile_id=v_uid and department_id=p_department_id and branch_id=v_branch)
    or exists(select 1 from public.profiles where id=v_uid and department_id=p_department_id) then
    raise exception 'You already belong to this department';
  end if;
  select id into v_id from public.department_requests where user_id=v_uid and department_id=p_department_id and status='pending' limit 1;
  if v_id is not null then return v_id; end if;
  insert into public.department_requests(user_id,department_id,branch_id,status,created_at)
    values(v_uid,p_department_id,v_branch,'pending',now()) returning id into v_id;
  return v_id;
end;
$function$;
revoke all on function public.community_request_department(uuid) from public,anon;
grant execute on function public.community_request_department(uuid) to authenticated;

create or replace function public.community_review_department_request(p_request_id uuid,p_approve boolean)
returns void language plpgsql security definer set search_path=''
as $function$
declare v_request public.department_requests;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  select * into v_request from public.department_requests where id=p_request_id for update;
  if not found or not public.churchmetric_can_manage_branch(v_request.branch_id) then
    raise exception 'Not authorized' using errcode='42501';
  end if;
  if v_request.status <> 'pending' then raise exception 'Request already reviewed'; end if;
  if p_approve is null then raise exception 'Decision required'; end if;
  if p_approve then
    if not exists(select 1 from public.profiles where id=v_request.user_id and branch_id=v_request.branch_id) then
      raise exception 'Member branch changed; submit a new request';
    end if;
    insert into public.profile_departments(profile_id,department_id,branch_id)
      values(v_request.user_id,v_request.department_id,v_request.branch_id) on conflict do nothing;
  end if;
  update public.department_requests set status=case when p_approve then 'approved' else 'rejected' end,
    reviewed_by=auth.uid(),reviewed_at=now() where id=p_request_id;
end;
$function$;
revoke all on function public.community_review_department_request(uuid,boolean) from public,anon;
grant execute on function public.community_review_department_request(uuid,boolean) to authenticated;
-- The join directory reveals names only, not department content or member counts.
create or replace function public.community_department_directory()
returns table(department_id uuid,name text) language sql stable security definer set search_path=''
as $directory$
 select d.id,d.name from public.departments d
 where auth.uid() is not null
   and not exists(select 1 from public.profile_departments pd where pd.profile_id=auth.uid() and pd.department_id=d.id)
   and not exists(select 1 from public.profiles p where p.id=auth.uid() and p.department_id=d.id)
 order by d.name;
$directory$;
revoke all on function public.community_department_directory() from public,anon;
grant execute on function public.community_department_directory() to authenticated;

-- Preserve the existing RPC signature while closing its all-departments detail path.
do $patch$
declare definition text;
begin
 select pg_get_functiondef('public.community_departments(text)'::regprocedure) into definition;
 if position('from public.departments d where v_filter=''all''' in definition)=0 then
   raise exception 'community_departments changed; review membership restriction before applying';
 end if;
 definition:=replace(definition,'from public.departments d where v_filter=''all''',
   'from public.departments d where (v_filter=''all'' and public.wpcc_can_view_department(d.id,v_branch))');
 execute definition;
end;
$patch$;
insert into public.departments(name)
select 'SwitchGen' where not exists(select 1 from public.departments where lower(replace(name,' ',''))='switchgen');
commit;
