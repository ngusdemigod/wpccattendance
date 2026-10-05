-- Run after the migration. All fixture requests and memberships roll back.
begin;
create temporary table department_admin_fixture as
select r.memberid manager_id,r.branch_id,r.department_id,gen_random_uuid() request_id
from public.roles r join public.leadership_titles t on t.id=r.leadership_title_id
where r.is_active and r.rolename='dept_leader' and t.code in ('hod','pro')
  and exists(select 1 from public.profiles p where p.id=r.memberid and p.branch_id=r.branch_id)
limit 1;
do $$ begin
  if not exists(select 1 from department_admin_fixture) then raise exception 'An active HOD/PRO fixture is required'; end if;
end $$;
insert into public.department_requests(id,user_id,department_id,branch_id,status)
select request_id,manager_id,department_id,branch_id,'pending' from department_admin_fixture;
grant select on department_admin_fixture to authenticated;
insert into storage.objects(bucket_id,name,metadata)
select 'wpcc','departments/'||branch_id||'/'||department_id||'/'||request_id||'.png',
  '{"mimetype":"image/png","size":100}'::jsonb from department_admin_fixture;
insert into public.department_branch_images(department_id,branch_id)
select f.department_id,b.id from department_admin_fixture f
join public.branches b on b.id<>f.branch_id limit 1
on conflict do nothing;
set local role authenticated;
do $$
declare f record; denied boolean; reviewed boolean;
begin
  select * into f from department_admin_fixture;
  perform set_config('request.jwt.claim.sub',f.manager_id::text,true);
  perform set_config('request.jwt.claims',json_build_object('sub',f.manager_id,'role','authenticated')::text,true);
  if not public.community_can_review_department(f.branch_id,f.department_id) then raise exception 'Manager denied own department'; end if;
  if public.community_can_review_department(gen_random_uuid(),gen_random_uuid()) then raise exception 'Cross-branch scope leaked'; end if;
  if not exists(select 1 from public.department_requests where id=f.request_id) then raise exception 'Manager cannot read queue via RLS'; end if;
  perform public.community_update_department_images(f.department_id,
    'https://api.wisdompowercc.org/storage/v1/object/public/wpcc/departments/'||f.branch_id||'/'||f.department_id||'/'||f.request_id||'.png',null);
  if not exists(select 1 from public.department_branch_images where department_id=f.department_id and branch_id=f.branch_id and updated_by=f.manager_id) then
    raise exception 'Branch image update failed';
  end if;
  if exists(select 1 from public.department_branch_images where department_id=f.department_id and branch_id<>f.branch_id) then
    raise exception 'Cross-branch images visible through RLS';
  end if;
  denied:=false;
  begin update public.department_branch_images set avatar_url='https://untrusted.example';
  exception when insufficient_privilege then denied:=true; end;
  if not denied then raise exception 'Direct image table mutation was permitted'; end if;
  denied:=false;
  begin
    perform public.community_update_department_images(f.department_id,'https://untrusted.example/image.jpg',null);
  exception when invalid_parameter_value then denied:=true; end;
  if not denied then raise exception 'External image URL accepted'; end if;
  denied:=false;
  begin
    perform public.community_update_department_profile(f.department_id,'Renamed',null,null,null);
  exception when insufficient_privilege then denied:=true; end;
  if not denied then raise exception 'Department name remained editable'; end if;
  perform public.community_review_department_request(f.request_id,true);
  if not exists(select 1 from public.department_requests where id=f.request_id and status='approved' and reviewed_by=f.manager_id and reviewed_at is not null) then raise exception 'Approval audit missing'; end if;
  reviewed:=false;
  begin
    perform public.community_review_department_request(f.request_id,true);
  exception when raise_exception then reviewed:=true; end;
  if not reviewed then raise exception 'Repeated approval was accepted'; end if;
  perform set_config('request.jwt.claim.sub',gen_random_uuid()::text,true);
  perform set_config('request.jwt.claims',json_build_object('sub',current_setting('request.jwt.claim.sub'),'role','authenticated')::text,true);
  if exists(select 1 from public.department_requests where id=f.request_id) then raise exception 'Unrelated caller can read request'; end if;
  denied:=false;
  begin perform public.community_review_department_request(f.request_id,false);
  exception when insufficient_privilege then denied:=true; end;
  if not denied then raise exception 'Unrelated caller can review request'; end if;
  denied:=false;
  begin perform public.community_update_department_images(f.department_id,null,null);
  exception when insufficient_privilege then denied:=true; end;
  if not denied then raise exception 'Unrelated caller can edit images'; end if;
end $$;
reset role;
rollback;
