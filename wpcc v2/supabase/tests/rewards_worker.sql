-- Execute after the rewards migration, within a transaction. All fixtures roll back.
begin;
do $test$
declare u uuid:=gen_random_uuid(); ev uuid:=gen_random_uuid(); att uuid; gift uuid;
 batch jsonb; renewed jsonb; result jsonb; amount bigint; branch uuid; award uuid; alert uuid:=gen_random_uuid(); occurrence uuid:=gen_random_uuid();
begin
 select id into branch from public.branches limit 1;
 insert into auth.users(id,email) values(u,'rewards-test-'||u||'@example.invalid');
 insert into public.profiles(id,branch_id,full_name,firstname,lastname) values(u,branch,'Rewards Test '||u,'Rewards','Test '||u);
 update rewards_private.settings set enabled=true,launched_at=now()-interval '1 day';
 insert into public.global_events(id,title,event_start_at,event_end_at,created_by)
 values(ev,'Rewards rollback test',now()-interval '2 hours',now()-interval '1 hour',u::text);
 insert into public.attendance(user_id,event_id,fullname,status,clockout)
 values(u,ev,'Rewards test','present',now()) returning id into att;
 batch:=public.rewards_claim_events(100);
 if not exists(select 1 from jsonb_array_elements(batch) x where x->>'kind'='attendance') then raise exception 'Attendance not queued'; end if;
 -- Crash before enqueue: expire the claim and claim again.
 update rewards_private.events set lease_until=now()-interval '1 second' where profile_id=u;
 renewed:=public.rewards_claim_events(100);
 select jsonb_agg(x||jsonb_build_object('points',30)) into batch from jsonb_array_elements(batch) x;
 result:=public.rewards_settle_events(batch);
 if exists(select 1 from rewards_private.ledger where profile_id=u) then raise exception 'Stale lease awarded'; end if;
 select jsonb_agg(x||jsonb_build_object('points',30)) into renewed from jsonb_array_elements(renewed) x;
 perform public.rewards_settle_events(renewed);
 perform public.rewards_settle_events(renewed);
 select balance into amount from rewards_private.balances where profile_id=u;
 if amount<>30 then raise exception 'Retry duplicated attendance: %',amount; end if;
 -- Corrected attendance reverses its existing award.
 update public.attendance set clockout=null,status='rejected' where id=att;
 select jsonb_agg(x||jsonb_build_object('points',30)) into batch from jsonb_array_elements(public.rewards_claim_events(100)) x;
 perform public.rewards_settle_events(batch);
 if (select balance from rewards_private.balances where profile_id=u)<>0 then raise exception 'Attendance reversal failed'; end if;
 -- Two different amounts on one date receive only one award.
 insert into public.giving_transactions(profile_id,giving_type,amount_kobo,internal_reference,status,paid_at)
 values(u,'offering',100,'rewards-test-a-'||u,'successful',now()),(u,'auto_give',999999,'rewards-test-b-'||u,'successful',now());
 select jsonb_agg(x||jsonb_build_object('points',30)) into batch from jsonb_array_elements(public.rewards_claim_events(100)) x;
 perform public.rewards_settle_events(batch);
 if (select balance from rewards_private.balances where profile_id=u)<>30 then raise exception 'Giving daily cap failed'; end if;
 insert into public.provider_webhook_events(provider,provider_event_id,payload)
 select 'paystack','test-refund-'||internal_reference,jsonb_build_object('event','refund.processed','data',jsonb_build_object('transaction',jsonb_build_object('reference',internal_reference)))
 from public.giving_transactions where profile_id=u;
 select jsonb_agg(x||jsonb_build_object('points',30)) into batch from jsonb_array_elements(public.rewards_claim_events(100)) x;
 perform public.rewards_settle_events(batch);
 if (select balance from rewards_private.balances where profile_id=u)<>0 then raise exception 'Refund reversal failed'; end if;
 if (select points_balance from public.profiles where id=u)<>0 then raise exception 'Display copy mismatch'; end if;
 -- Prayer accepts only server evidence meeting the official threshold.
 insert into public.prayer_alerts(id,created_by,scope,title,local_time,duration_seconds)
 values(alert,u,'global','Rollback prayer','12:00',1200);
 insert into public.prayer_alert_occurrences(id,prayer_alert_id,scheduled_for,local_scheduled_for)
 values(occurrence,alert,now()-interval '15 minutes',(now()-interval '15 minutes')::timestamp);
 begin
  perform public.rewards_record_prayer(u,occurrence,599);
  raise exception 'Short prayer accepted';
 exception when raise_exception then
  if sqlerrm<>'Ineligible prayer' then raise; end if;
 end;
 perform public.rewards_record_prayer(u,occurrence,600);
 perform public.rewards_record_prayer(u,occurrence,600);
 select jsonb_agg(x||jsonb_build_object('points',30)) into batch from jsonb_array_elements(public.rewards_claim_events(100)) x;
 perform public.rewards_settle_events(batch);
 if (select balance from rewards_private.balances where profile_id=u)<>30 then raise exception 'Prayer duplicate protection failed'; end if;
 -- Profile completion is checked from saved fields and awards only once.
 insert into public.profiles_priv_info(id,branch_id,full_name,date_of_birth,phone_number,residential_address,occupation,emergency_contact)
 values(u,branch,'Rewards fixture',date '1990-01-01','08012345678','Test address','Engineer','Contact 08012345679');
 update public.profiles set avatar='fixture-avatar',department_id=(select id from public.departments limit 1) where id=u;
 select jsonb_agg(x||jsonb_build_object('points',15)) into batch from jsonb_array_elements(public.rewards_claim_events(100)) x;
 perform public.rewards_settle_events(batch);
 if (select balance from rewards_private.balances where profile_id=u)<>45 then raise exception 'Profile completion failed'; end if;
 update public.profiles_priv_info set occupation='Doctor' where id=u;
 perform set_config('request.jwt.claims',jsonb_build_object('sub',u,'role','authenticated')::text,true);
 perform public.rewards_check_profile();
 if (public.rewards_my_summary()->>'balance')::integer<>45 then raise exception 'Own summary incorrect'; end if;
 perform set_config('request.jwt.claims','{}',true);
 if exists(select 1 from rewards_private.events where profile_id=u and kind='profile' and state<>'processed') then raise exception 'Lifetime profile award requeued'; end if;
 if (select count(*) from rewards_private.ledger where profile_id=u and kind='profile')<>1 then raise exception 'Profile duplicated'; end if;
 -- Manual withholding and global admin pause endpoints must not exist.
 if to_regprocedure('public.rewards_admin_review(uuid,boolean,text)') is not null then raise exception 'Manual reward review remains available'; end if;
 if to_regprocedure('public.rewards_admin_control(boolean,text,boolean)') is not null then raise exception 'Admin reward pause remains available'; end if;
 -- Even a historical withheld record cannot change the server entitlement.
 select id into award from rewards_private.events where profile_id=u and kind='profile';
 insert into rewards_private.corrections(event_id,withheld,actor,reason) values(award,true,u,'Historical hold fixture');
 perform rewards_private.enqueue(u,'profile','profile:completion',u,now());
 select jsonb_agg(x||jsonb_build_object('points',15)) into batch from jsonb_array_elements(public.rewards_claim_events(100)) x;
 perform public.rewards_settle_events(batch);
 if (select balance from rewards_private.balances where profile_id=u)<>45 then raise exception 'Historical hold reduced reward'; end if;
 if (select count(*) from rewards_private.ledger where profile_id=u and kind='profile')<>1 then raise exception 'Historical hold caused adjustment'; end if;
 if has_function_privilege('authenticated','public.rewards_claim_events(integer)','EXECUTE') then raise exception 'Member can claim'; end if;
 if has_function_privilege('anon','public.rewards_settle_events(jsonb)','EXECUTE') then raise exception 'Anonymous can settle'; end if;
 if has_function_privilege('authenticated','public.wpcc_clock_out_attendance(uuid,numeric,numeric)','EXECUTE') then raise exception 'Member can bypass checkout'; end if;
 if has_schema_privilege('authenticated','rewards_private','USAGE') then raise exception 'Private ledger exposed'; end if;
 begin
  update rewards_private.ledger set delta=15 where profile_id=u;
  raise exception 'Ledger mutation allowed';
 exception when raise_exception then
  if sqlerrm<>'Reward history is append-only' then raise; end if;
 end;
end $test$;
-- Exercise the trigger with ordinary member privileges even when table-level UPDATE is granted.
create temporary table rewards_guard_fixture(points_balance bigint) on commit drop;
insert into rewards_guard_fixture values(0);
create trigger rewards_guard before insert or update on rewards_guard_fixture for each row execute function rewards_private.guard_points();
grant select,insert,update on rewards_guard_fixture to authenticated;
set local role authenticated;
do $guard$
begin
 begin
  update pg_temp.rewards_guard_fixture set points_balance=999999;
  raise exception 'Member modified points';
 exception when insufficient_privilege then null;
 end;
end $guard$;
reset role;
rollback;
select 'rewards safety tests passed' as result;
