begin;
-- No app role, including global admin, may withhold rewards or pause their processing.
drop function if exists public.rewards_admin_review(uuid,boolean,text);
drop function if exists public.rewards_admin_control(boolean,text,boolean);
create or replace function rewards_private.desired_points(e rewards_private.events) returns integer
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


-- Keep historical review records for audit only. They no longer affect eligibility.
revoke all on rewards_private.corrections from public,anon,authenticated,service_role;
comment on table rewards_private.corrections is 'Retired manual-review records. Not consulted by reward rules; retained for audit only.';
-- Recover any award previously withheld without editing the append-only ledger.
do $$
declare e rewards_private.events;
begin
 for e in select ev.* from rewards_private.events ev
 join rewards_private.corrections c on c.event_id=ev.id where c.withheld
 loop
  perform rewards_private.enqueue(e.profile_id,e.kind,e.award_key,e.source_id,e.occurred_at);
 end loop;
end $$;
update rewards_private.settings set enabled=true;
notify pgrst,'reload schema';
commit;
