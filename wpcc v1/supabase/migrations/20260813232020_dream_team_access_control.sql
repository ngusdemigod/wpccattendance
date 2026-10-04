-- Dream Team module-level access control. Existing public.roles assignments remain authoritative.
create table if not exists public.admin_access_assignments (
  role_assignment_id uuid primary key references public.roles(id) on delete cascade,
  preset text not null check (preset in ('administrator','membership_admin','academy_admin','quality_control_admin','operations_admin','custom')),
  permission_overrides jsonb not null default '{}'::jsonb check (jsonb_typeof(permission_overrides) = 'object'),
  updated_by uuid references auth.users(id), updated_at timestamptz not null default now()
);
create table if not exists public.access_control_verifications (
  id uuid primary key default gen_random_uuid(), actor_id uuid not null references auth.users(id) on delete cascade,
  target_id uuid not null references auth.users(id) on delete cascade, operation text not null check (operation in ('grant','update','revoke')),
  payload_hash text not null, otp_hash text, expires_at timestamptz not null, attempts smallint not null default 0,
  consumed_at timestamptz, created_at timestamptz not null default now()
);
create table if not exists public.access_control_audit_log (
  id uuid primary key default gen_random_uuid(), actor_id uuid not null references auth.users(id),
  target_administrator_id uuid not null references auth.users(id), branch_id uuid references public.branches(id),
  action text not null check (action in ('granted','updated','revoked')), previous_preset text, new_preset text,
  previous_permissions text[] not null default '{}', new_permissions text[] not null default '{}',
  verification_method text not null check (verification_method in ('password','otp')),
  request_metadata jsonb not null default '{}'::jsonb, created_at timestamptz not null default now()
);
create index if not exists access_control_audit_created_idx on public.access_control_audit_log(created_at desc);
create index if not exists access_control_audit_branch_created_idx on public.access_control_audit_log(branch_id,created_at desc);
create index if not exists access_control_verification_lookup_idx on public.access_control_verifications(actor_id,target_id,created_at desc);
create or replace function private.prevent_access_control_audit_mutation() returns trigger language plpgsql security definer set search_path='' as 'begin raise exception ''access_control_history_is_append_only'' using errcode=''42501'';end';
revoke all on function private.prevent_access_control_audit_mutation() from public,anon,authenticated,service_role;
create trigger access_control_audit_append_only before update or delete on public.access_control_audit_log for each row execute function private.prevent_access_control_audit_mutation();
alter table public.admin_access_assignments enable row level security;
alter table public.access_control_verifications enable row level security;
alter table public.access_control_audit_log enable row level security;
revoke all on public.admin_access_assignments,public.access_control_verifications,public.access_control_audit_log from anon,authenticated;

create or replace function public.dream_team_permission_catalogue() returns text[] language sql immutable set search_path='' as $$
 select array['analytics.reports.read','analytics.reports.write','membership.members.read','membership.members.write','membership.events.read','membership.events.write','membership.soul_winning.read','membership.soul_winning.write','membership.departments.read','membership.departments.write','membership.enquiries.read','membership.enquiries.write','quality.reports.read','quality.reports.write','quality.queries.read','quality.queries.write','quality.issues.read','quality.issues.write','academy.classes.read','academy.classes.write','academy.enrolments.read','academy.enrolments.write','academy.instructors.read','academy.instructors.write','operations.follow_ups.read','operations.follow_ups.write','operations.targets.read','operations.targets.write','operations.awards.read','operations.awards.write','operations.export_data.read','operations.export_data.write','administration.access_control.read','administration.access_control.write']::text[]
$$;
create or replace function public.dream_team_preset_permissions(p_preset text) returns text[] language sql immutable set search_path='' as $$
 with catalogue as (select unnest(public.dream_team_permission_catalogue()) permission)
 select case p_preset when 'administrator' then array(select permission from catalogue where permission not like 'administration.access_control.%') when 'membership_admin' then array(select permission from catalogue where permission like 'membership.%') when 'academy_admin' then array(select permission from catalogue where permission like 'academy.%' or permission='membership.members.read') when 'quality_control_admin' then array(select permission from catalogue where permission like 'quality.%') when 'operations_admin' then array(select permission from catalogue where permission like 'operations.%') else '{}'::text[] end
$$;
create or replace function private.dream_team_effective_permissions(p_user_id uuid) returns text[] language plpgsql stable security definer set search_path='' as $$
declare v_role public.roles%rowtype;v_access public.admin_access_assignments%rowtype;v_permissions text[];v_key text;v_value jsonb;
begin
 select * into v_role from public.roles where memberid=p_user_id and is_active order by case when lower(rolename)='globaladmin' then 0 else 1 end,is_primary desc,assigned_at desc limit 1;
 if not found then return '{}'::text[];end if;if lower(v_role.rolename)='globaladmin' then return public.dream_team_permission_catalogue();end if;if lower(v_role.rolename)<>'admin' then return '{}'::text[];end if;
 select * into v_access from public.admin_access_assignments where role_assignment_id=v_role.id;v_permissions:=public.dream_team_preset_permissions(coalesce(v_access.preset,'administrator'));
 if v_access.role_assignment_id is not null then for v_key,v_value in select key,value from jsonb_each(v_access.permission_overrides) loop if v_key=any(public.dream_team_permission_catalogue()) then if v_value='true'::jsonb and not(v_key=any(v_permissions)) then v_permissions:=array_append(v_permissions,v_key);end if;if v_value='false'::jsonb then v_permissions:=array_remove(v_permissions,v_key);end if;end if;end loop;end if;
 foreach v_key in array coalesce(v_permissions,'{}'::text[]) loop if v_key like '%.write' and not(replace(v_key,'.write','.read')=any(v_permissions)) then v_permissions:=array_append(v_permissions,replace(v_key,'.write','.read'));end if;end loop;
 return array(select distinct permission from unnest(v_permissions) permission order by permission);
end $$;
revoke all on function private.dream_team_effective_permissions(uuid) from public,anon,authenticated;
create or replace function public.dream_team_has_permission(p_permission text) returns boolean language sql stable security definer set search_path='' as $$select auth.uid() is not null and p_permission=any(private.dream_team_effective_permissions(auth.uid()))$$;
revoke all on function public.dream_team_has_permission(text) from public,anon;grant execute on function public.dream_team_has_permission(text) to authenticated;

create or replace function public.churchmetric_admin_context() returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce((select jsonb_build_object('role',context.role_name,'branch_id',context.branch_id,'department_id',context.department_id,'permissions',private.dream_team_effective_permissions(auth.uid()),'preset',case when context.role_name='globaladmin' then 'super_admin' else coalesce((select aaa.preset from public.admin_access_assignments aaa join public.roles r on r.id=aaa.role_assignment_id where r.memberid=auth.uid() and r.is_active order by r.is_primary desc,r.assigned_at desc limit 1),'administrator') end) from private.churchmetric_current_context() context),'{}'::jsonb)
$$;
create or replace function public.dream_team_access_control_directory(p_search text default null,p_preset text default null) returns jsonb language sql stable security definer set search_path='' as $$
 select case when not public.dream_team_has_permission('administration.access_control.read') then jsonb_build_object('error','forbidden') else jsonb_build_object('administrators',coalesce((select jsonb_agg(item order by item->>'name') from(select jsonb_build_object('id',r.memberid,'role_assignment_id',r.id,'name',p.full_name,'email',p.email,'avatar',p.avatar,'branch_id',coalesce(r.branch_id,p.branch_id),'stored_role',lower(r.rolename),'preset',case when lower(r.rolename)='globaladmin' then 'super_admin' else coalesce(aaa.preset,'administrator') end,'permissions',private.dream_team_effective_permissions(r.memberid),'active',r.is_active,'updated_at',coalesce(aaa.updated_at,r.assigned_at)) item from public.roles r join public.profiles p on p.id=r.memberid left join public.admin_access_assignments aaa on aaa.role_assignment_id=r.id where r.is_active and lower(r.rolename) in('admin','globaladmin') and(public.churchmetric_role()='globaladmin' or coalesce(r.branch_id,p.branch_id)=public.churchmetric_branch_id()) and(nullif(btrim(p_search),'') is null or p.full_name ilike '%'||btrim(p_search)||'%' or p.email ilike '%'||btrim(p_search)||'%') and(nullif(p_preset,'') is null or(case when lower(r.rolename)='globaladmin' then 'super_admin' else coalesce(aaa.preset,'administrator') end)=p_preset))rows),'[]'::jsonb),'eligible_members',coalesce((select jsonb_agg(jsonb_build_object('id',p.id,'name',p.full_name,'email',p.email,'branch_id',p.branch_id) order by p.full_name) from public.profiles p where not exists(select 1 from public.roles r where r.memberid=p.id and r.is_active and lower(r.rolename) in('admin','globaladmin')) and(public.churchmetric_role()='globaladmin' or p.branch_id=public.churchmetric_branch_id()) and(nullif(btrim(p_search),'') is null or p.full_name ilike '%'||btrim(p_search)||'%' or p.email ilike '%'||btrim(p_search)||'%')),'[]'::jsonb)) end
$$;
create or replace function public.dream_team_access_control_recent_changes(p_limit integer default 50) returns jsonb language sql stable security definer set search_path='' as $$
 select case when not public.dream_team_has_permission('administration.access_control.read') then jsonb_build_object('error','forbidden') else coalesce((select jsonb_agg(jsonb_build_object('id',a.id,'action',a.action,'actor_id',a.actor_id,'actor_name',actor.full_name,'target_id',a.target_administrator_id,'target_name',target.full_name,'previous_preset',a.previous_preset,'new_preset',a.new_preset,'previous_permissions',a.previous_permissions,'new_permissions',a.new_permissions,'created_at',a.created_at) order by a.created_at desc) from(select * from public.access_control_audit_log where public.churchmetric_role()='globaladmin' or branch_id=public.churchmetric_branch_id() order by created_at desc limit least(greatest(p_limit,1),100))a left join public.profiles actor on actor.id=a.actor_id left join public.profiles target on target.id=a.target_administrator_id),'[]'::jsonb) end
$$;
revoke all on function public.dream_team_access_control_directory(text,text),public.dream_team_access_control_recent_changes(integer) from public,anon;
grant execute on function public.dream_team_access_control_directory(text,text),public.dream_team_access_control_recent_changes(integer) to authenticated;
insert into public.admin_access_assignments(role_assignment_id,preset) select id,'administrator' from public.roles where is_active and lower(rolename)='admin' on conflict(role_assignment_id) do nothing;

-- Restrictive capability policies compose with existing tenant/ownership RLS.
do $rbac$
declare item record;operation text;
begin
 for item in select * from (values
  ('profiles','membership.members'),('profiles_priv_info','membership.members'),('attendance','membership.events'),('events','membership.events'),
  ('souls','membership.soul_winning'),('soul_followups','membership.soul_winning'),('departments','membership.departments'),('profile_departments','membership.departments'),
  ('enquiries','membership.enquiries'),('enquiry_messages','membership.enquiries'),('quality_reports','quality.reports'),('quality_queries','quality.queries'),
  ('quality_query_assignees','quality.queries'),('quality_issues','quality.issues'),('quality_status_history','quality.issues'),('courses','academy.classes'),
  ('academy_modules','academy.classes'),('academy_sessions','academy.classes'),('course_enrollments','academy.enrolments'),('academy_instructors','academy.instructors'),
  ('academy_instructor_assignments','academy.instructors'),('broadcast_campaigns','operations.follow_ups'),('broadcast_recipients','operations.follow_ups'),
  ('targets','operations.targets'),('target_progress_events','operations.targets'),('target_achievements','operations.awards')
 ) mapping(table_name,module_key) where to_regclass('public.'||table_name) is not null loop
  execute format('create policy %I on public.%I as restrictive for select to authenticated using ((select public.dream_team_has_permission(%L)))','rbac_'||item.table_name||'_read',item.table_name,item.module_key||'.read');
  foreach operation in array array['insert','update','delete'] loop
   if operation='insert' then execute format('create policy %I on public.%I as restrictive for insert to authenticated with check ((select public.dream_team_has_permission(%L)))','rbac_'||item.table_name||'_insert',item.table_name,item.module_key||'.write');
   elsif operation='update' then execute format('create policy %I on public.%I as restrictive for update to authenticated using ((select public.dream_team_has_permission(%L))) with check ((select public.dream_team_has_permission(%L)))','rbac_'||item.table_name||'_update',item.table_name,item.module_key||'.write',item.module_key||'.write');
   else execute format('create policy %I on public.%I as restrictive for delete to authenticated using ((select public.dream_team_has_permission(%L)))','rbac_'||item.table_name||'_delete',item.table_name,item.module_key||'.write');end if;
  end loop;
 end loop;
end $rbac$;

create or replace function public.dream_team_apply_access_change(p_actor_id uuid,p_target_id uuid,p_operation text,p_preset text,p_permissions text[],p_verification_method text,p_metadata jsonb default '{}'::jsonb)
returns void language plpgsql security definer set search_path='' as $$
declare v_actor_role text;v_actor_branch uuid;v_target public.profiles%rowtype;v_role public.roles%rowtype;v_previous_preset text;v_previous_permissions text[];v_next_permissions text[];v_overrides jsonb:='{}'::jsonb;v_permission text;v_role_type uuid;
begin
 if not('administration.access_control.write'=any(private.dream_team_effective_permissions(p_actor_id))) then raise exception 'access_control_forbidden' using errcode='42501';end if;
 select lower(r.rolename),coalesce(r.branch_id,p.branch_id) into v_actor_role,v_actor_branch from public.roles r join public.profiles p on p.id=r.memberid where r.memberid=p_actor_id and r.is_active order by case when lower(r.rolename)='globaladmin' then 0 else 1 end,r.is_primary desc,r.assigned_at desc limit 1;
 select * into v_target from public.profiles where id=p_target_id;if not found then raise exception 'target_not_found' using errcode='P0002';end if;
 if v_actor_role<>'globaladmin' or (v_actor_branch is not null and v_target.branch_id<>v_actor_branch) then raise exception 'cross_tenant_or_super_admin_forbidden' using errcode='42501';end if;
 if p_actor_id=p_target_id then raise exception 'self_elevation_forbidden' using errcode='42501';end if;
 if p_operation not in('grant','update','revoke') then raise exception 'invalid_operation' using errcode='22023';end if;
 if p_preset is not null and p_preset not in('administrator','membership_admin','academy_admin','quality_control_admin','operations_admin','custom') then raise exception 'invalid_preset' using errcode='22023';end if;
 if exists(select 1 from unnest(coalesce(p_permissions,'{}'::text[])) p where not(p=any(public.dream_team_permission_catalogue()))) then raise exception 'invalid_permission' using errcode='22023';end if;
 select * into v_role from public.roles where memberid=p_target_id and is_active and lower(rolename) in('admin','globaladmin') order by case when lower(rolename)='globaladmin' then 0 else 1 end,is_primary desc,assigned_at desc limit 1;
 if found then v_previous_permissions:=private.dream_team_effective_permissions(p_target_id);v_previous_preset:=case when lower(v_role.rolename)='globaladmin' then 'super_admin' else coalesce((select preset from public.admin_access_assignments where role_assignment_id=v_role.id),'administrator') end;end if;
 if lower(coalesce(v_role.rolename,''))='globaladmin' then raise exception 'super_admin_immutable' using errcode='42501';end if;
 if p_operation='revoke' then
   if not found then raise exception 'administrator_not_found' using errcode='P0002';end if;
   update public.roles set is_active=false,is_primary=false where id=v_role.id;delete from public.admin_access_assignments where role_assignment_id=v_role.id;v_next_permissions:='{}'::text[];
 else
   if not found then
     select id into v_role_type from public.roletypes where lower(rolename)='admin' limit 1;if v_role_type is null then raise exception 'admin_role_type_missing';end if;
     insert into public.roles(memberid,full_name,roleid,rolename,branch_id,scope_type,is_active,is_primary) values(p_target_id,v_target.full_name,v_role_type,'admin',v_target.branch_id,'branch',true,true) returning * into v_role;
   end if;
   v_next_permissions:=array(select distinct p from unnest(coalesce(p_permissions,public.dream_team_preset_permissions(coalesce(p_preset,'administrator')))) p union select replace(p,'.write','.read') from unnest(coalesce(p_permissions,'{}'::text[])) p where p like '%.write');
   foreach v_permission in array public.dream_team_permission_catalogue() loop
     if (v_permission=any(v_next_permissions))<>(v_permission=any(public.dream_team_preset_permissions(coalesce(p_preset,'administrator')))) then v_overrides:=v_overrides||jsonb_build_object(v_permission,v_permission=any(v_next_permissions));end if;
   end loop;
   insert into public.admin_access_assignments(role_assignment_id,preset,permission_overrides,updated_by,updated_at) values(v_role.id,coalesce(p_preset,'administrator'),v_overrides,p_actor_id,now()) on conflict(role_assignment_id) do update set preset=excluded.preset,permission_overrides=excluded.permission_overrides,updated_by=excluded.updated_by,updated_at=excluded.updated_at;
 end if;
 insert into public.access_control_audit_log(actor_id,target_administrator_id,branch_id,action,previous_preset,new_preset,previous_permissions,new_permissions,verification_method,request_metadata) values(p_actor_id,p_target_id,v_target.branch_id,case when p_operation='grant' then 'granted' when p_operation='revoke' then 'revoked' else 'updated' end,v_previous_preset,case when p_operation='revoke' then null else p_preset end,coalesce(v_previous_permissions,'{}'),coalesce(v_next_permissions,'{}'),p_verification_method,coalesce(p_metadata,'{}'));
end $$;
revoke all on function public.dream_team_apply_access_change(uuid,uuid,text,text,text[],text,jsonb) from public,anon,authenticated;
grant execute on function public.dream_team_apply_access_change(uuid,uuid,text,text,text[],text,jsonb) to service_role;
