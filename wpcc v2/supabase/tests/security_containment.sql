begin;
-- Run in a transaction and roll back; fixtures never touch member records.
create temporary table security_guard_fixture
  (id uuid, role text, branch_id uuid, department_id uuid, verified boolean, bio text)
  on commit drop;
insert into security_guard_fixture values
  ('10000000-0000-0000-0000-000000000001','member',
   '20000000-0000-0000-0000-000000000001',null,false,'original');
create trigger security_guard before insert or update on security_guard_fixture
  for each row execute function public.community_guard_profile_authority();
grant select,insert,update on security_guard_fixture to authenticated,service_role;
set local role authenticated;
do $member_test$
begin
  begin
    update pg_temp.security_guard_fixture set role='globaladmin';
    raise exception 'FAIL: role escalation allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    update pg_temp.security_guard_fixture set branch_id='30000000-0000-0000-0000-000000000001';
    raise exception 'FAIL: branch reassignment allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    update pg_temp.security_guard_fixture set verified=true;
    raise exception 'FAIL: self-verification allowed';
  exception when insufficient_privilege then null;
  end;
  begin
    insert into pg_temp.security_guard_fixture(id,role) values(gen_random_uuid(),'admin');
    raise exception 'FAIL: privileged profile insertion allowed';
  exception when insufficient_privilege then null;
  end;
  update pg_temp.security_guard_fixture set bio='personal edit';
  if not exists(select 1 from pg_temp.security_guard_fixture where bio='personal edit' and role='member') then
    raise exception 'FAIL: personal-detail update blocked';
  end if;
end;
$member_test$;
reset role;
set local role service_role;
update pg_temp.security_guard_fixture set role='admin';
insert into pg_temp.security_guard_fixture(id,role) values(gen_random_uuid(),'member');
reset role;

do $catalog_test$
declare fn record; col text;
begin
  for fn in select p.oid,p.oid::regprocedure as name from pg_proc p
    join pg_namespace n on n.oid=p.pronamespace
    where n.nspname='public' and p.proname in ('media_spotify_sync_config','relink_profile_identity','backfill_seed_auth_users','churchmetric_claim_email_outbox','claim_due_prayer_alert_occurrences','create_prayer_alert_deliveries','mark_prayer_alert_delivery_result','mark_prayer_alert_occurrence_result','mark_push_subscription_success','materialize_prayer_alert_occurrences','deactivate_push_subscription','wpcc_claim_due_auto_give','wpcc_complete_auto_give_claim','wpcc_due_auto_give','wpcc_advance_auto_give','wpcc_record_paystack_transaction','wpcc_initialize_giving_transaction','sync_global_admin_role_for_user','sync_dept_leader_role_for_user','sync_recurring_events_for_week','request_email_login_otp')
  loop
    if has_function_privilege('anon',fn.oid,'EXECUTE') or
       has_function_privilege('authenticated',fn.oid,'EXECUTE') or
       not has_function_privilege('service_role',fn.oid,'EXECUTE') then
      raise exception 'FAIL: unexpected backend grants %',fn.name;
    end if;
  end loop;
  foreach col in array array['role','id','branch_id','department_id','verified','membership_code','email'] loop
    if has_column_privilege('authenticated','public.profiles_priv_info',col,'UPDATE') or
       has_column_privilege('authenticated','public.profiles_priv_info',col,'INSERT') then
      raise exception 'FAIL: private authority column writable %',col;
    end if;
  end loop;
  if not has_column_privilege('authenticated','public.profiles_priv_info','bio','UPDATE') or
     not has_column_privilege('authenticated','public.profiles_priv_info','date_of_birth','UPDATE') then
    raise exception 'FAIL: personal fields not editable';
  end if;
  if has_table_privilege('anon','public.systemreports','SELECT') or not exists(
    select 1 from pg_class where oid='public.systemreports'::regclass
      and reloptions @> array['security_invoker=true']) then
    raise exception 'FAIL: unsafe reporting view';
  end if;
  if exists(select 1 from pg_policies where schemaname='storage'
    and tablename='objects' and policyname='profile_avatars_public_read') then
    raise exception 'FAIL: public avatar listing remains';
  end if;
  if exists(select 1 from pg_class c join pg_namespace n on n.oid=c.relnamespace
    where n.nspname='public' and c.relkind in ('r','p')
    and (has_table_privilege('anon',c.oid,'TRUNCATE') or
         has_table_privilege('authenticated',c.oid,'TRUNCATE'))) then
    raise exception 'FAIL: client truncate grants remain';
  end if;
  if exists(select 1 from pg_proc where oid in (
     'public.relink_current_auth_profile()'::regprocedure,
     'public.resolve_current_profile_identity()'::regprocedure)
     and (prosrc like '%raw_user_meta_data%' or prosrc not like '%email_confirmed_at%')) then
    raise exception 'FAIL: identity lookup trusts unverified claims';
  end if;
end;
$catalog_test$;
drop table pg_temp.security_guard_fixture;

rollback;
