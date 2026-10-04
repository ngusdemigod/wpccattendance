begin;
alter table public.department_requests add column if not exists branch_id uuid references public.branches(id);
alter table public.department_requests add column if not exists reviewed_by uuid references public.profiles(id);
alter table public.department_requests add column if not exists reviewed_at timestamptz;
update public.department_requests r set branch_id=p.branch_id from public.profiles p
where p.id=r.user_id and r.branch_id is null;
alter table public.department_requests enable row level security;
revoke all on public.department_requests from anon,authenticated;
grant select on public.department_requests to authenticated;
drop policy if exists community_department_requests_read on public.department_requests;
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


create or replace function public.community_save_profile_confirmation(p_details jsonb)
returns void language plpgsql security definer set search_path=''
as $fn$
declare v_uid uuid:=auth.uid(); v_name text; v_dob date; v_key text;
begin
 if v_uid is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if jsonb_typeof(p_details)<>'object' or p_details is null then raise exception 'Details must be an object'; end if;
 for v_key in select jsonb_object_keys(p_details) loop
  if v_key <> all(array['full_name','date_of_birth','phone_number','residential_address','occupation','emergency_contact']) then
   raise exception 'This field cannot be changed' using errcode='42501';
  end if;
  if jsonb_typeof(p_details->v_key)<>'string' or length(p_details->>v_key)>1000 then raise exception 'Invalid field value'; end if;
 end loop;
 if p_details ? 'full_name' then
  v_name:=regexp_replace(btrim(p_details->>'full_name'),'\s+',' ','g');
  if length(v_name)<2 or length(v_name)>160 then raise exception 'Enter your full name'; end if;
 end if;
 if p_details ? 'date_of_birth' then
  v_dob:=(p_details->>'date_of_birth')::date;
  if v_dob not between date '1900-01-01' and current_date then raise exception 'Enter a valid date of birth'; end if;
 end if;
 if p_details ? 'phone_number' and length(regexp_replace(p_details->>'phone_number','[^0-9]','','g'))<7 then raise exception 'Enter a valid phone number'; end if;
 if p_details ? 'residential_address' and length(btrim(p_details->>'residential_address'))<5 then raise exception 'Enter your address'; end if;
 if p_details ? 'occupation' and length(btrim(p_details->>'occupation'))<2 then raise exception 'Enter your occupation'; end if;
 if p_details ? 'emergency_contact' and (length(btrim(p_details->>'emergency_contact'))<2 or length(regexp_replace(p_details->>'emergency_contact','[^0-9]','','g'))<7) then raise exception 'Enter a contact name and phone number'; end if;
 -- Never accept an ID, role, branch, verification status, avatar pointer or balance from the caller.
 perform 1 from public.profiles where id=v_uid for update;
 if not found then raise exception 'Member profile not found'; end if;
 if not exists(select 1 from public.profiles_priv_info where id=v_uid) then raise exception 'Private member record is missing; contact the church office'; end if;
 update public.profiles_priv_info set
  firstname=case when v_name is null then firstname else split_part(v_name,' ',1) end,
  lastname=case when v_name is null then lastname else nullif(substr(v_name,length(split_part(v_name,' ',1))+2),'') end,
  full_name=coalesce(v_name,full_name),
  date_of_birth=coalesce(v_dob,date_of_birth),
  phone_number=case when p_details ? 'phone_number' then btrim(p_details->>'phone_number') else phone_number end,
  residential_address=case when p_details ? 'residential_address' then btrim(p_details->>'residential_address') else residential_address end,
  occupation=case when p_details ? 'occupation' then btrim(p_details->>'occupation') else occupation end,
  emergency_contact=case when p_details ? 'emergency_contact' then btrim(p_details->>'emergency_contact') else emergency_contact end
 where id=v_uid;
end $fn$;
revoke all on function public.community_save_profile_confirmation(jsonb) from public,anon;
grant execute on function public.community_save_profile_confirmation(jsonb) to authenticated;

create or replace function public.community_profile_confirmation_status()
returns jsonb language plpgsql stable security definer set search_path=''
as $fn$
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
 return jsonb_build_object(
 'complete',rewards_private.profile_complete(auth.uid()),
 'awarded',exists(select 1 from rewards_private.ledger where profile_id=auth.uid() and kind='profile' and delta=15),
 'pending',exists(select 1 from rewards_private.events where profile_id=auth.uid() and kind='profile' and state in ('pending','leased','failed')),
 'departments',coalesce((select jsonb_agg(to_jsonb(d)) from (
  select d.id,d.name,'member'::text status from public.departments d where d.id in (
   select department_id from public.profile_departments where profile_id=auth.uid()
   union select department_id from public.profiles where id=auth.uid())
  union
  select d.id,d.name,'pending'::text from public.department_requests r join public.departments d on d.id=r.department_id
   where r.user_id=auth.uid() and r.status='pending'
 ) d),'[]'::jsonb));
end $fn$;
revoke all on function public.community_profile_confirmation_status() from public,anon;
grant execute on function public.community_profile_confirmation_status() to authenticated;
commit;
