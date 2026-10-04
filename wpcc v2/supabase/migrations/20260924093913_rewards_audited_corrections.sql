begin;
-- An administrator may withhold/restore a verified entitlement, never invent a point amount.
create table rewards_private.corrections (
 event_id uuid primary key references rewards_private.events(id),
 withheld boolean not null,
 actor uuid not null,
 reason text not null check(length(btrim(reason))>=5),
 updated_at timestamptz not null default now()
);
alter table rewards_private.corrections enable row level security;
revoke all on rewards_private.corrections from public,anon,authenticated;
create or replace function rewards_private.desired_points(e rewards_private.events) returns integer
language plpgsql security definer set search_path='' as $$
declare day_start timestamptz; seconds integer;
begin
  if exists(select 1 from rewards_private.corrections c where c.event_id=e.id and c.withheld) then return 0; end if;
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


create function public.rewards_admin_review(p_event uuid,p_withhold boolean,p_reason text)
returns void language plpgsql security definer set search_path='' as $$
declare e rewards_private.events;
begin
 if auth.uid() is null or coalesce(lower(public.get_my_role()),'')<>'globaladmin' then
  raise exception 'Global admin required' using errcode='42501';
 end if;
 if p_withhold is null or coalesce(length(btrim(p_reason)),0)<5 then raise exception 'Decision and reason required'; end if;
 select * into e from rewards_private.events where id=p_event for update;
 if not found then raise exception 'Reward event not found'; end if;
 insert into rewards_private.corrections(event_id,withheld,actor,reason)
 values(e.id,p_withhold,auth.uid(),p_reason)
 on conflict(event_id) do update set withheld=excluded.withheld,actor=excluded.actor,reason=excluded.reason,updated_at=now();
 insert into rewards_private.admin_audit(actor,action,reason)
 values(auth.uid(),'review:'||e.id||';withhold='||p_withhold,p_reason);
 perform rewards_private.enqueue(e.profile_id,e.kind,e.award_key,e.source_id,e.occurred_at);
end $$;
revoke all on function public.rewards_admin_review(uuid,boolean,text) from public,anon,authenticated;
grant execute on function public.rewards_admin_review(uuid,boolean,text) to authenticated,service_role;
create or replace function public.rewards_admin_control(p_enabled boolean,p_reason text,p_retry_failed boolean default false)
returns void language plpgsql security definer set search_path='' as $$
begin
 if auth.uid() is null or coalesce(lower(public.get_my_role()),'')<>'globaladmin' then raise exception 'Global admin required' using errcode='42501'; end if;
 if coalesce(length(btrim(p_reason)),0)<5 then raise exception 'Reason required'; end if;
 update rewards_private.settings set enabled=p_enabled;
 if p_retry_failed then update rewards_private.events set state='pending',attempts=0,lease_token=null,lease_until=null,updated_at=now() where state='failed'; end if;
 insert into rewards_private.admin_audit(actor,action,reason) values(auth.uid(),'enabled='||p_enabled||';retry='||p_retry_failed,p_reason);
end $$;
create or replace function rewards_private.guard_attendance() returns trigger language plpgsql security invoker set search_path='' as $$
begin
  if current_user not in ('postgres','service_role','supabase_admin') then
    if coalesce(lower(public.get_my_role()),'') not in ('globaladmin','admin') then
      raise exception 'Attendance changes require the verified server flow' using errcode='42501';
    end if;
    if tg_op<>'DELETE' then new.confirmedby:=auth.uid(); end if;
  end if;
  if tg_op='DELETE' then return old; end if;
  return new;
end $$;
notify pgrst,'reload schema';
commit;
