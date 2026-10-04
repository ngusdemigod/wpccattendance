begin;
create schema if not exists rewards_private;
revoke all on schema rewards_private from public, anon, authenticated;
create table rewards_private.settings (
  singleton boolean primary key default true check(singleton),
  enabled boolean not null default false,
  launched_at timestamptz not null default now()
);
insert into rewards_private.settings default values;
create table rewards_private.events (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null,
  kind text not null check(kind in ('attendance','giving','prayer','profile')),
  award_key text not null,
  source_id uuid,
  occurred_at timestamptz not null default now(),
  revision integer not null default 1,
  state text not null default 'pending' check(state in ('pending','leased','processed','failed')),
  lease_token uuid,
  lease_until timestamptz,
  attempts integer not null default 0,
  last_error text,
  updated_at timestamptz not null default now(),
  unique(profile_id,award_key)
);
create index rewards_claim_idx on rewards_private.events(state,lease_until,updated_at)
where state in ('pending','leased');
create index rewards_events_member_idx on rewards_private.events(profile_id,state);
create table rewards_private.balances (
  profile_id uuid primary key references public.profiles(id),
  balance bigint not null default 0 check(balance>=0),
  updated_at timestamptz not null default now()
);
create table rewards_private.entitlements (
  profile_id uuid not null,
  award_key text not null,
  points integer not null check(points in (0,15,30)),
  revision integer not null default 0,
  primary key(profile_id,award_key)
);
create table rewards_private.ledger (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null,
  event_id uuid not null references rewards_private.events(id),
  award_key text not null,
  kind text not null,
  delta integer not null check(delta in (-30,-15,15,30)),
  revision integer not null,
  rule_version integer not null default 1,
  created_at timestamptz not null default now(),
  unique(profile_id,award_key,revision)
);
create index rewards_history_idx on rewards_private.ledger(profile_id,created_at desc,id);
create table rewards_private.prayer_evidence (
  profile_id uuid not null,
  occurrence_id uuid not null,
  connected_seconds integer not null check(connected_seconds>0),
  verified_at timestamptz not null default now(),
  primary key(profile_id,occurrence_id)
);
create table rewards_private.payment_reversals (
  reference text primary key,
  provider_event_id text not null,
  created_at timestamptz not null default now()
);
create table rewards_private.admin_audit (
  id uuid primary key default gen_random_uuid(), actor uuid not null,
  action text not null, reason text not null, created_at timestamptz not null default now()
);
-- Private tables have no browser grants or policies.
alter table rewards_private.settings enable row level security;
alter table rewards_private.events enable row level security;
alter table rewards_private.balances enable row level security;
alter table rewards_private.entitlements enable row level security;
alter table rewards_private.ledger enable row level security;
alter table rewards_private.prayer_evidence enable row level security;
alter table rewards_private.payment_reversals enable row level security;
alter table rewards_private.admin_audit enable row level security;
revoke all on all tables in schema rewards_private from public,anon,authenticated;
alter table public.profiles add column if not exists points_balance bigint not null default 0;
comment on column public.profiles.points_balance is 'Server-owned display copy; rewards_private.ledger is authoritative.';
revoke update(points_balance),insert(points_balance) on public.profiles from public,anon,authenticated;

create function rewards_private.guard_points() returns trigger language plpgsql security invoker set search_path='' as $$
begin
  if current_user not in ('postgres','service_role','supabase_admin')
    or coalesce(auth.jwt()->>'role','') in ('anon','authenticated') then
    if tg_op='INSERT' and new.points_balance<>0 then raise exception 'Points are server-owned' using errcode='42501'; end if;
    if tg_op='UPDATE' and new.points_balance is distinct from old.points_balance then
      raise exception 'Points are server-owned' using errcode='42501';
    end if;
  end if;
  return new;
end $$;
create trigger rewards_guard_points before insert or update on public.profiles
for each row execute function rewards_private.guard_points();

create function rewards_private.append_only() returns trigger language plpgsql security invoker set search_path='' as $$
begin raise exception 'Reward history is append-only'; end $$;
create trigger rewards_ledger_immutable before update or delete on rewards_private.ledger
for each row execute function rewards_private.append_only();

create function rewards_private.enqueue(p_user uuid,p_kind text,p_key text,p_source uuid,p_time timestamptz)
returns void language plpgsql security definer set search_path='' as $$
begin
  if p_user is null then return; end if;
  insert into rewards_private.events(profile_id,kind,award_key,source_id,occurred_at)
  values(p_user,p_kind,p_key,p_source,coalesce(p_time,now()))
  on conflict(profile_id,award_key) do update set
    revision=rewards_private.events.revision+1,state='pending',lease_token=null,lease_until=null,
    attempts=0,last_error=null,updated_at=now();
end $$;

-- Browser-created attendance must never become eligible through a direct RPC.
revoke all on function public.wpcc_clock_out_attendance(uuid,numeric,numeric) from public,anon,authenticated;
grant execute on function public.wpcc_clock_out_attendance(uuid,numeric,numeric) to service_role;
create function rewards_private.guard_attendance() returns trigger language plpgsql security invoker set search_path='' as $$
begin
  if current_user not in ('postgres','service_role','supabase_admin') then
    if coalesce(public.churchmetric_role(),'') not in ('globaladmin','admin') then
      raise exception 'Attendance changes require the verified server flow' using errcode='42501';
    end if;
    if tg_op<>'DELETE' then new.confirmedby:=auth.uid(); end if;
  end if;
  if tg_op='DELETE' then return old; end if;
  return new;
end $$;
create trigger rewards_attendance_guard before insert or update or delete on public.attendance
for each row execute function rewards_private.guard_attendance();

create function rewards_private.attendance_event() returns trigger language plpgsql security definer set search_path='' as $$
declare r record;
begin
  if tg_op='DELETE' then r:=old; else r:=new; end if;
  if tg_op='UPDATE' and (new.user_id is distinct from old.user_id or new.event_id is distinct from old.event_id or new.clockout is distinct from old.clockout or new.status is distinct from old.status)
    and old.clockout >= (select launched_at from rewards_private.settings) then
    perform rewards_private.enqueue(old.user_id,'attendance','attendance:'||old.event_id,old.event_id,old.clockout);
  end if;
  if r.clockout is not null and r.clockout >= (select launched_at from rewards_private.settings) then
    perform rewards_private.enqueue(r.user_id,'attendance','attendance:'||r.event_id,r.event_id,r.clockout);
  end if;
  if tg_op='DELETE' then return old; end if;
  return new;
end $$;
create trigger rewards_attendance_event after insert or update or delete on public.attendance
for each row execute function rewards_private.attendance_event();

create index if not exists giving_rewards_lookup on public.giving_transactions(profile_id,paid_at)
where status='successful';
create function rewards_private.giving_event() returns trigger language plpgsql security definer set search_path='' as $$
begin
  if tg_op='UPDATE' and old.status='successful' and old.paid_at >= (select launched_at from rewards_private.settings)
    and (old.status is distinct from new.status or old.paid_at is distinct from new.paid_at or old.profile_id is distinct from new.profile_id) then
    perform rewards_private.enqueue(old.profile_id,'giving','giving:'||(old.paid_at at time zone 'Africa/Lagos')::date,old.id,old.paid_at);
  end if;
  if new.status='successful' and new.paid_at >= (select launched_at from rewards_private.settings)
    and (tg_op='INSERT' or old.status is distinct from new.status or old.paid_at is distinct from new.paid_at or old.profile_id is distinct from new.profile_id) then
    perform rewards_private.enqueue(new.profile_id,'giving',
      'giving:'||(new.paid_at at time zone 'Africa/Lagos')::date,new.id,new.paid_at);
  end if;
  return new;
end $$;
create trigger rewards_giving_event after insert or update on public.giving_transactions
for each row execute function rewards_private.giving_event();

-- Signed provider webhook ingress is server-only; its durable rows also drive reversals.
revoke insert,update,delete on public.provider_webhook_events from public,anon,authenticated;
create function rewards_private.refund_event() returns trigger language plpgsql security definer set search_path='' as $$
declare ref text; t public.giving_transactions;
begin
  if new.provider='paystack' and new.payload->>'event' in ('refund.processed','charge.dispute.create') then
    ref:=coalesce(new.payload#>>'{data,transaction,reference}',new.payload#>>'{data,reference}');
    if ref is not null then
      insert into rewards_private.payment_reversals(reference,provider_event_id)
        values(ref,new.provider_event_id) on conflict do nothing;
      select * into t from public.giving_transactions where paystack_reference=ref or internal_reference=ref limit 1;
      if t.paid_at >= (select launched_at from rewards_private.settings) then
        perform rewards_private.enqueue(t.profile_id,'giving','giving:'||(t.paid_at at time zone 'Africa/Lagos')::date,t.id,t.paid_at);
      end if;
    end if;
  end if;
  return new;
end $$;
create trigger rewards_refund_event after insert on public.provider_webhook_events
for each row execute function rewards_private.refund_event();

create function rewards_private.profile_complete(p_user uuid) returns boolean
language sql stable security definer set search_path='' as $$
select exists (
 select 1 from public.profiles p join public.profiles_priv_info q on q.id=p.id
 where p.id=p_user
 and length(btrim(coalesce(p.avatar,q.avatar,'')))>0
 and length(btrim(coalesce(q.full_name,p.full_name,'')))>=2
 and coalesce(q.date_of_birth,q.dob) between date '1900-01-01' and current_date
 and length(regexp_replace(coalesce(q.phone_number,q.phone,p.phone,''),'[^0-9]','','g'))>=7
 and length(btrim(coalesce(q.residential_address,q.address,'')))>=5
 and length(btrim(coalesce(q.occupation,'')))>=2
 and length(btrim(coalesce(q.emergency_contact,'')))>=2
 and length(regexp_replace(coalesce(q.emergency_contact,''),'[^0-9]','','g'))>=7
 and (p.department_id is not null or exists(select 1 from public.profile_departments d where d.profile_id=p.id)
      or exists(select 1 from public.department_requests j where j.user_id=p.id and j.status in ('pending','approved')))
);
$$;
create function rewards_private.profile_event() returns trigger language plpgsql security definer set search_path='' as $$
begin
  if rewards_private.profile_complete(new.id)
    and not exists(select 1 from rewards_private.events where profile_id=new.id and kind='profile' and (state in ('pending','leased','failed') or exists(select 1 from rewards_private.ledger where profile_id=new.id and kind='profile' and delta=15))) then
    perform rewards_private.enqueue(new.id,'profile','profile:completion',new.id,now());
  end if;
  return new;
end $$;
create trigger rewards_public_profile_event after update of full_name,avatar,phone,department_id on public.profiles
for each row execute function rewards_private.profile_event();
create trigger rewards_private_profile_event after update on public.profiles_priv_info
for each row execute function rewards_private.profile_event();
-- Allows the app to ask the server to check saved details, never to grant points.
create function public.rewards_check_profile() returns boolean language plpgsql security definer set search_path='' as $$
begin
  if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
  if not rewards_private.profile_complete(auth.uid()) then return false; end if;
  if not exists(select 1 from rewards_private.events where profile_id=auth.uid() and kind='profile' and (state in ('pending','leased','failed') or exists(select 1 from rewards_private.ledger where profile_id=auth.uid() and kind='profile' and delta=15))) then
    perform rewards_private.enqueue(auth.uid(),'profile','profile:completion',auth.uid(),now());
  end if;
  return true;
end $$;

create function public.rewards_claim_events(p_limit integer default 100)
returns jsonb language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
  if not (select enabled from rewards_private.settings) then return '[]'::jsonb; end if;
  with candidates as (
    select id from rewards_private.events
    where (state='pending' or (state='leased' and lease_until<now())) and attempts<20
    order by updated_at,id for update skip locked limit least(greatest(p_limit,1),100)
  ), claimed as (
    update rewards_private.events e set state='leased',lease_token=gen_random_uuid(),
      lease_until=now()+interval '5 minutes',attempts=attempts+1,updated_at=now()
    from candidates c where c.id=e.id
    returning e.id,e.lease_token,e.revision,e.kind
  ) select coalesce(jsonb_agg(to_jsonb(claimed)),'[]'::jsonb) into result from claimed;
  update rewards_private.events set state='failed',last_error='Lease retry limit reached',updated_at=now()
    where state='leased' and lease_until<now() and attempts>=20;
  return result;
end $$;

create function rewards_private.desired_points(e rewards_private.events) returns integer
language plpgsql security definer set search_path='' as $$
declare day_start timestamptz; seconds integer;
begin
  if e.kind='attendance' then
    if exists(select 1 from public.attendance a join (select id,event_end_at from public.global_events union all select id,event_end_at from public.branch_events union all select id,event_end_at from public.departmental_events) ev on ev.id=a.event_id
      where a.user_id=e.profile_id and a.event_id=e.source_id and lower(a.status)='present'
      and a.clockout is not null and a.clockout>=ev.event_end_at
      and a.clockout >= (select launched_at from rewards_private.settings)) then return 30; end if;
  elsif e.kind='giving' then
    day_start:=(substring(e.award_key from 8)::date::timestamp at time zone 'Africa/Lagos');
    if exists(select 1 from public.giving_transactions t
      where t.profile_id=e.profile_id and t.status='successful'
      and t.paid_at>=day_start and t.paid_at<day_start+interval '1 day'
      and t.paid_at >= (select launched_at from rewards_private.settings)
      and not exists(select 1 from rewards_private.payment_reversals r
        where r.reference=t.paystack_reference or r.reference=t.internal_reference)) then return 30; end if;
  elsif e.kind='prayer' then
    if exists(select 1 from rewards_private.prayer_evidence x
      join public.prayer_alert_occurrences o on o.id=x.occurrence_id
      join public.prayer_alerts a on a.id=o.prayer_alert_id
      where x.profile_id=e.profile_id and x.occurrence_id=e.source_id and a.scope='global'
      and a.duration_seconds>0 and o.status<>'cancelled'
      and x.connected_seconds>=least(ceil(a.duration_seconds/2.0)::integer,600)) then return 30; end if;
  elsif e.kind='profile' then
    -- A completed profile award is lifetime; subsequent edits do not repeatedly award/revoke it.
    if rewards_private.profile_complete(e.profile_id) or
      exists(select 1 from rewards_private.ledger where profile_id=e.profile_id and kind='profile' and delta=15)
      then return 15; end if;
  end if;
  return 0;
end $$;

create function public.rewards_settle_events(p_events jsonb) returns jsonb
language plpgsql security definer set search_path='' as $$
declare item jsonb; e rewards_private.events; desired integer; previous integer; v_revision integer;
  difference integer; results jsonb:='[]'; users uuid[]:='{}'; uid uuid;
begin
  if jsonb_typeof(p_events)<>'array' or jsonb_array_length(p_events)>100 then raise exception 'Invalid batch'; end if;
  if not (select enabled from rewards_private.settings) then raise exception 'Rewards paused'; end if;
  -- Serialize settlements/reconciliation before taking event/source row locks.
  -- This avoids deadlocks when batches overlap a member and a source correction races settlement.
  perform pg_advisory_xact_lock(824301,1);
  -- Deterministic event order within the transaction.
  for item in select x.value from jsonb_array_elements(p_events) x
    join rewards_private.events ev on ev.id=(x.value->>'id')::uuid
    order by ev.profile_id,ev.id
  loop
    select * into e from rewards_private.events where id=(item->>'id')::uuid for update;
    if e.state='processed' then results:=results||jsonb_build_array(jsonb_build_object('id',e.id,'status','duplicate')); continue; end if;
    if e.state<>'leased' or e.lease_token is distinct from (item->>'lease_token')::uuid
      or e.revision<>(item->>'revision')::integer or e.lease_until<now() then
      results:=results||jsonb_build_array(jsonb_build_object('id',e.id,'status','stale')); continue;
    end if;
    if (item->>'points')::integer is distinct from (case when e.kind='profile' then 15 else 30 end) then
      raise exception 'Invalid rule value';
    end if;
    insert into rewards_private.balances(profile_id) values(e.profile_id) on conflict do nothing;
    perform 1 from rewards_private.balances where profile_id=e.profile_id for update;
    insert into rewards_private.entitlements(profile_id,award_key,points)
      values(e.profile_id,e.award_key,0) on conflict do nothing;
    select points,ent.revision into previous,v_revision from rewards_private.entitlements ent
      where profile_id=e.profile_id and award_key=e.award_key for update;
    desired:=rewards_private.desired_points(e);
    difference:=desired-previous;
    if difference<>0 then
      insert into rewards_private.ledger(profile_id,event_id,award_key,kind,delta,revision)
        values(e.profile_id,e.id,e.award_key,e.kind,difference,v_revision+1);
      update rewards_private.entitlements set points=desired,revision=v_revision+1
        where profile_id=e.profile_id and award_key=e.award_key;
      update rewards_private.balances set balance=balance+difference,updated_at=now() where profile_id=e.profile_id;
      users:=array_append(users,e.profile_id);
    end if;
    update rewards_private.events set state='processed',lease_token=null,lease_until=null,last_error=null,updated_at=now() where id=e.id;
    results:=results||jsonb_build_array(jsonb_build_object('id',e.id,'status','processed','delta',difference));
  end loop;
  -- One display-copy write per affected member per batch.
  update public.profiles p set points_balance=b.balance from rewards_private.balances b
    where p.id=b.profile_id and p.id=any(users) and p.points_balance is distinct from b.balance;
  return results;
end $$;
create function public.rewards_fail_events(p_events jsonb) returns void language plpgsql security definer set search_path='' as $$
begin
  if jsonb_array_length(p_events)>100 then raise exception 'Invalid batch'; end if;
  update rewards_private.events e set state='failed',last_error='Queue retry limit reached',updated_at=now()
  from jsonb_array_elements(p_events) x
  where e.id=(x->>'id')::uuid and e.lease_token=(x->>'lease_token')::uuid and e.state='leased';
end $$;

create function public.rewards_prayer_context(p_user uuid,p_session uuid) returns jsonb
language plpgsql security definer set search_path='' as $$
declare result jsonb;
begin
 select jsonb_build_object('user',s.user_id,'occurrence',o.id,'start',extract(epoch from o.scheduled_for)*1000,
   'end',extract(epoch from o.scheduled_for+make_interval(secs=>a.duration_seconds))*1000,
   'threshold',least(ceil(a.duration_seconds/2.0)::integer,600))
 into result from public.prayer_sessions s
 join public.prayer_alerts a on a.id=s.prayer_alert_id
 join lateral (select x.* from public.prayer_alert_occurrences x where x.prayer_alert_id=a.id
   and (s.occurrence_id is null or x.id=s.occurrence_id) and x.status<>'cancelled'
   and now() between x.scheduled_for and x.scheduled_for+make_interval(secs=>a.duration_seconds)
   order by x.scheduled_for desc limit 1) o on true
 where s.id=p_session and s.user_id=p_user and s.completion_status='active' and s.ended_at is null
   and a.scope='global' and a.is_active and a.duration_seconds>0
   and o.scheduled_for >= (select launched_at from rewards_private.settings);
 return result;
end $$;
create function public.rewards_record_prayer(p_user uuid,p_occurrence uuid,p_seconds integer)
returns void language plpgsql security definer set search_path='' as $$
declare threshold integer; start_time timestamptz;
begin
 select least(ceil(a.duration_seconds/2.0)::integer,600),o.scheduled_for into threshold,start_time
 from public.prayer_alert_occurrences o join public.prayer_alerts a on a.id=o.prayer_alert_id
 where o.id=p_occurrence and a.scope='global' and a.duration_seconds>0 and o.status<>'cancelled';
 if threshold is null or p_seconds<threshold or p_seconds>86400 or now()<start_time+make_interval(secs=>threshold)
   or start_time<(select launched_at from rewards_private.settings) then raise exception 'Ineligible prayer'; end if;
 insert into rewards_private.prayer_evidence(profile_id,occurrence_id,connected_seconds)
 values(p_user,p_occurrence,p_seconds) on conflict do nothing;
 if found then perform rewards_private.enqueue(p_user,'prayer','prayer:'||p_occurrence,p_occurrence,now()); end if;
end $$;

create function public.rewards_my_summary() returns jsonb language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
 return jsonb_build_object('balance',coalesce((select balance from rewards_private.balances where profile_id=auth.uid()),0),
  'pending',(select count(*) from rewards_private.events where profile_id=auth.uid() and state in ('pending','leased')),
  'history',coalesce((select jsonb_agg(to_jsonb(h)) from (select id,kind,delta,created_at from rewards_private.ledger
    where profile_id=auth.uid() order by created_at desc,id desc limit 50) h),'[]'::jsonb));
end $$;
create function public.rewards_public_totals(p_users uuid[]) returns table(profile_id uuid,points_balance bigint)
language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null then raise exception 'Authentication required' using errcode='42501'; end if;
 if cardinality(p_users)>100 then raise exception 'Too many members'; end if;
 return query select p.id,p.points_balance from public.profiles p where p.id=any(p_users);
end $$;
create function public.rewards_admin_control(p_enabled boolean,p_reason text,p_retry_failed boolean default false)
returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or coalesce(public.churchmetric_role(),'')<>'globaladmin' then raise exception 'Global admin required' using errcode='42501'; end if;
 if coalesce(length(btrim(p_reason)),0)<5 then raise exception 'Reason required'; end if;
 update rewards_private.settings set enabled=p_enabled;
 if p_retry_failed then update rewards_private.events set state='pending',attempts=0,lease_token=null,lease_until=null,updated_at=now() where state='failed'; end if;
 insert into rewards_private.admin_audit(actor,action,reason) values(auth.uid(),'enabled='||p_enabled||';retry='||p_retry_failed,p_reason);
end $$;
create function public.rewards_reconcile(p_limit integer default 100) returns integer
language plpgsql security definer set search_path='' as $$
declare u record; actual bigint; fixed integer:=0;
begin
 perform pg_advisory_xact_lock(824301,1);
 for u in select profile_id from rewards_private.balances order by updated_at limit least(greatest(p_limit,1),100)
 loop
   perform 1 from rewards_private.balances where profile_id=u.profile_id for update;
   select coalesce(sum(delta),0) into actual from rewards_private.ledger where profile_id=u.profile_id;
   update rewards_private.balances set balance=actual,updated_at=now() where profile_id=u.profile_id;
   update public.profiles set points_balance=actual where id=u.profile_id and points_balance is distinct from actual;
   if found then fixed:=fixed+1; end if;
 end loop;
 return fixed;
end $$;

revoke all on all functions in schema rewards_private from public,anon,authenticated;
do $grants$
declare f record;
begin
 for f in select p.oid::regprocedure as signature from pg_proc p join pg_namespace n on n.oid=p.pronamespace
 where n.nspname='public' and p.proname like 'rewards_%'
 loop
 execute format('revoke all on function %s from public,anon,authenticated',f.signature);
 execute format('grant execute on function %s to service_role',f.signature);
 end loop;
end $grants$;
grant execute on function public.rewards_check_profile(),public.rewards_my_summary(),
 public.rewards_public_totals(uuid[]),public.rewards_admin_control(boolean,text,boolean) to authenticated;
notify pgrst,'reload schema';
commit;
