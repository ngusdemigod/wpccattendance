begin;
do $test$
declare u uuid:=gen_random_uuid(); other_u uuid:=gen_random_uuid(); branch uuid; dept uuid; request_id uuid;
begin
 select id into branch from public.branches limit 1;
 select id into dept from public.departments limit 1;
 insert into auth.users(id,email) values(u,'confirmation-'||u||'@example.invalid'),(other_u,'confirmation-'||other_u||'@example.invalid');
 insert into public.profiles(id,branch_id,firstname,lastname,full_name) values(u,branch,'Confirmation',u::text,'Confirmation '||u),(other_u,branch,'Other',other_u::text,'Other '||other_u);
 insert into public.profiles_priv_info(id,branch_id,firstname,lastname,full_name) values(u,branch,'Confirmation',u::text,'Confirmation '||u);
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated')::text,true);
 perform public.community_save_profile_confirmation(jsonb_build_object('full_name','Updated '||u,'occupation','Engineer, Entrepreneur','phone_number','08012345678','date_of_birth','1990-01-01','residential_address','Fixture address','emergency_contact','Contact | 08012345679'));
 if (select occupation from public.profiles_priv_info where id=u)<>'Engineer, Entrepreneur' then raise exception 'Allowed save failed'; end if;
 if (select full_name from public.profiles where id=u)<>'Updated '||u then raise exception 'Name synchronization failed'; end if;
 begin
  perform public.community_save_profile_confirmation('{"role":"globaladmin","points_balance":"9999"}'::jsonb);
  raise exception 'Privilege escalation accepted';
 exception when insufficient_privilege then null; end;
 begin
  perform public.community_save_profile_confirmation(jsonb_build_object('id',other_u,'occupation','Doctor'));
  raise exception 'Cross-user save accepted';
 exception when insufficient_privilege then null; end;
 request_id:=public.community_request_department(dept);
 if public.community_request_department(dept)<>request_id then raise exception 'Duplicate department request'; end if;
 if exists(select 1 from public.profile_departments where profile_id=u) then raise exception 'Request granted membership'; end if;
 if public.community_profile_confirmation_status()->>'awarded'<>'false' then raise exception 'Fabricated profile award'; end if;
 if public.rewards_check_profile() then raise exception 'Incomplete profile qualified'; end if;
 perform set_config('request.jwt.claims','{}',true);
 begin
  perform public.community_profile_confirmation_status();
  raise exception 'Anonymous read accepted';
 exception when insufficient_privilege then null; end;
 if has_function_privilege('anon','public.community_save_profile_confirmation(jsonb)','execute') then raise exception 'Anonymous execute granted'; end if;
end $test$;
rollback;
