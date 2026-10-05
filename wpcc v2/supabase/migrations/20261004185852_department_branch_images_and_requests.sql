begin;

create table public.department_branch_images (
  department_id uuid not null references public.departments(id) on delete cascade,
  branch_id uuid not null references public.branches(id) on delete cascade,
  cover_url text,
  avatar_url text,
  updated_by uuid references public.profiles(id),
  updated_at timestamptz not null default now(),
  primary key (department_id, branch_id)
);
create index department_branch_images_branch_idx on public.department_branch_images(branch_id);
alter table public.department_branch_images enable row level security;
revoke all on public.department_branch_images from public, anon, authenticated;
grant select on public.department_branch_images to authenticated;
create policy department_branch_images_read on public.department_branch_images
for select to authenticated using (
  branch_id = public.churchmetric_branch_id()
  and public.wpcc_can_view_department(department_id, branch_id)
);

create or replace function public.community_can_review_department(p_branch uuid, p_department uuid)
returns boolean language sql stable security invoker set search_path=''
as $$ select auth.uid() is not null and (
  public.churchmetric_can_manage_branch(p_branch)
  or public.can_manage_department_scope_event(p_branch,p_department)
) $$;
revoke all on function public.community_can_review_department(uuid,uuid) from public,anon;
grant execute on function public.community_can_review_department(uuid,uuid) to authenticated;

create or replace function public.community_update_department_images(
  p_department_id uuid, p_cover_url text default null, p_avatar_url text default null
) returns void language plpgsql security definer set search_path=''
as $$
declare v_branch uuid := public.churchmetric_branch_id(); v_url text; v_path text;
  v_prefix text := 'https://api.wisdompowercc.org/storage/v1/object/public/wpcc/';
begin
  if auth.uid() is null or v_branch is null or not public.community_can_review_department(v_branch,p_department_id) then
    raise exception 'Not authorized' using errcode='42501';
  end if;
  foreach v_url in array array[p_cover_url,p_avatar_url] loop
    if v_url is not null then
      v_path := substr(v_url,length(v_prefix)+1);
      if left(v_url,length(v_prefix)) <> v_prefix
        or left(v_path,length('departments/'||v_branch||'/'||p_department_id||'/')) <> 'departments/'||v_branch||'/'||p_department_id||'/'
        or not exists(select 1 from storage.objects o where o.bucket_id='wpcc' and o.name=v_path) then
        raise exception 'Image must belong to this department and branch' using errcode='22023';
      end if;
    end if;
  end loop;
  insert into public.department_branch_images(department_id,branch_id,cover_url,avatar_url,updated_by)
  values(p_department_id,v_branch,p_cover_url,p_avatar_url,auth.uid())
  on conflict(department_id,branch_id) do update set
    cover_url=coalesce(excluded.cover_url,department_branch_images.cover_url),
    avatar_url=coalesce(excluded.avatar_url,department_branch_images.avatar_url),
    updated_by=auth.uid(),updated_at=now();
end $$;
revoke all on function public.community_update_department_images(uuid,text,text) from public,anon;
grant execute on function public.community_update_department_images(uuid,text,text) to authenticated;

-- Retire the member-app endpoint that could edit shared department names.
create or replace function public.community_update_department_profile(
  p_department_id uuid,p_name text,p_description text default null,
  p_cover_url text default null,p_avatar_url text default null
) returns public.departments language plpgsql security invoker set search_path=''
as $$ begin raise exception 'Department names and descriptions are read-only. Use branch image settings.' using errcode='42501'; end $$;

create or replace function public.community_department_context(p_department_id uuid)
returns table(department_id uuid,name text,description text,cover_url text,avatar_url text,branch_id uuid,
  member_count bigint,is_member boolean,is_leading boolean,can_manage boolean)
language plpgsql stable security definer set search_path=''
as $$
declare v_uid uuid:=auth.uid(); v_branch uuid;
begin
  if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
  v_branch:=public.churchmetric_branch_id();
  if v_branch is null then select p.branch_id into v_branch from public.profiles p where p.id=v_uid; end if;
  return query select d.id,d.name,d.description,coalesce(b.cover_url,d.cover_url),coalesce(b.avatar_url,d.avatar_url),v_branch,
    (select count(distinct x.profile_id) from (
      select pd.profile_id from public.profile_departments pd where pd.department_id=d.id and pd.branch_id=v_branch
      union select p.id from public.profiles p where p.department_id=d.id and p.branch_id=v_branch
    ) x)::bigint,
    (exists(select 1 from public.profile_departments pd where pd.profile_id=v_uid and pd.department_id=d.id and pd.branch_id=v_branch)
      or exists(select 1 from public.profiles p where p.id=v_uid and p.department_id=d.id and p.branch_id=v_branch)),
    exists(select 1 from public.leaders l where l.user_id=v_uid and l.department_id=d.id and coalesce(l.is_active,true) and l.branch_id=v_branch),
    coalesce(public.community_can_review_department(v_branch,d.id),false)
  from public.departments d left join public.department_branch_images b on b.department_id=d.id and b.branch_id=v_branch
  where d.id=p_department_id and public.wpcc_can_view_department(d.id,v_branch);
end $$;

drop policy if exists community_department_requests_read on public.department_requests;
create policy community_department_requests_read on public.department_requests for select to authenticated
using(user_id=(select auth.uid()) or public.community_can_review_department(branch_id,department_id));
create index if not exists department_requests_review_queue_idx
  on public.department_requests(department_id,branch_id,created_at,id) where status='pending';

create or replace function public.community_department_pending_requests(p_department_id uuid)
returns table(id uuid,full_name text,created_at timestamp without time zone)
language plpgsql stable security definer set search_path=''
as $$
declare v_branch uuid:=public.churchmetric_branch_id();
begin
  if not coalesce(public.community_can_review_department(v_branch,p_department_id),false) then
    raise exception 'Not authorized' using errcode='42501';
  end if;
  return query select r.id,p.full_name,r.created_at from public.department_requests r
  join public.profiles p on p.id=r.user_id
  where r.department_id=p_department_id and r.branch_id=v_branch and r.status='pending'
  order by r.created_at,r.id limit 100;
end $$;
revoke all on function public.community_department_pending_requests(uuid) from public,anon;
grant execute on function public.community_department_pending_requests(uuid) to authenticated;

create or replace function public.community_review_department_request(p_request_id uuid,p_approve boolean)
returns void language plpgsql security definer set search_path=''
as $$
declare v_request public.department_requests;
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  select * into v_request from public.department_requests where id=p_request_id for update;
  if not found or not coalesce(public.community_can_review_department(v_request.branch_id,v_request.department_id),false) then
    raise exception 'Not authorized' using errcode='42501';
  end if;
  if v_request.status <> 'pending' then raise exception 'Request already reviewed'; end if;
  if p_approve is null then raise exception 'Decision required'; end if;
  if p_approve then
    perform 1 from public.profiles where id=v_request.user_id and branch_id=v_request.branch_id for update;
    if not found then raise exception 'Member branch changed; submit a new request'; end if;
    insert into public.profile_departments(profile_id,department_id,branch_id)
      values(v_request.user_id,v_request.department_id,v_request.branch_id) on conflict do nothing;
  end if;
  update public.department_requests set status=case when p_approve then 'approved' else 'rejected' end,
    reviewed_by=auth.uid(),reviewed_at=now() where id=p_request_id;
end $$;
revoke all on function public.community_review_department_request(uuid,boolean) from public,anon;
grant execute on function public.community_review_department_request(uuid,boolean) to authenticated;
commit;
