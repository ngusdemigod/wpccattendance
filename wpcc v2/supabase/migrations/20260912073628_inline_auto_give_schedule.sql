alter table public.giving_transactions
  add column if not exists pending_auto_give jsonb;

comment on column public.giving_transactions.pending_auto_give is
  'Validated schedule requested during the initial Paystack payment; cleared after mandate creation.';

create or replace function private.next_auto_give_charge(
  p_profile_id uuid,
  p_branch_id uuid,
  p_rule_keys text[],
  p_timezone text,
  p_local_time time,
  p_from timestamptz default now()
)
returns timestamptz
language plpgsql stable set search_path=''
as $$
declare
  v_local_now timestamp := p_from at time zone p_timezone;
  v_rule text;
  v_date date;
  v_candidate timestamptz;
  v_best timestamptz;
  v_day int;
  v_month int;
  v_year int;
  i int;
begin
  foreach v_rule in array p_rule_keys loop
    v_date := null;
    if v_rule ~ '^weekday:[1-7](:[0-9a-f-]{36})?$' then
      v_day := split_part(v_rule,':',2)::int;
      for i in 0..14 loop
        if extract(isodow from v_local_now::date + i)::int = v_day then
          v_date := v_local_now::date + i;
          v_candidate := make_timestamptz(extract(year from v_date)::int,extract(month from v_date)::int,extract(day from v_date)::int,extract(hour from p_local_time)::int,extract(minute from p_local_time)::int,extract(second from p_local_time),p_timezone);
          if v_candidate > p_from then exit; else v_candidate := null; end if;
        end if;
      end loop;
    elsif v_rule ~ '^event:[0-9]{4}-[0-9]{2}-[0-9]{2}:[0-9a-f-]{36}$' then
      begin v_date := split_part(v_rule,':',2)::date; exception when others then v_date := null; end;
      if v_date is not null then
        v_candidate := make_timestamptz(extract(year from v_date)::int,extract(month from v_date)::int,extract(day from v_date)::int,extract(hour from p_local_time)::int,extract(minute from p_local_time)::int,extract(second from p_local_time),p_timezone);
        if v_candidate <= p_from then v_candidate := null; end if;
      end if;
    elsif v_rule ~ '^monthly:([1-9]|[12][0-9]|3[01])(:[0-9a-f-]{36})?$' then
      v_day := split_part(v_rule,':',2)::int;
      for i in 0..13 loop
        v_year := extract(year from (v_local_now::date + make_interval(months=>i)))::int;
        v_month := extract(month from (v_local_now::date + make_interval(months=>i)))::int;
        if v_day <= extract(day from (make_date(v_year,v_month,1) + interval '1 month - 1 day'))::int then
          v_date := make_date(v_year,v_month,v_day);
          v_candidate := make_timestamptz(v_year,v_month,v_day,extract(hour from p_local_time)::int,extract(minute from p_local_time)::int,extract(second from p_local_time),p_timezone);
          if v_candidate > p_from then exit; else v_candidate := null; end if;
        end if;
      end loop;
    elsif v_rule ~ '^yearly:([1-9]|1[0-2]):([1-9]|[12][0-9]|3[01])(:[0-9a-f-]{36})?$' then
      v_month := split_part(v_rule,':',2)::int;
      v_day := split_part(v_rule,':',3)::int;
      for i in 0..2 loop
        v_year := extract(year from v_local_now)::int + i;
        begin
          v_date := make_date(v_year,v_month,v_day);
          v_candidate := make_timestamptz(v_year,v_month,v_day,extract(hour from p_local_time)::int,extract(minute from p_local_time)::int,extract(second from p_local_time),p_timezone);
          if v_candidate > p_from then exit; else v_candidate := null; end if;
        exception when datetime_field_overflow then v_candidate := null;
        end;
      end loop;
    elsif v_rule='sunday_service' or v_rule='wednesday' or v_rule='thursday' then
      v_day := case v_rule when 'sunday_service' then 7 when 'wednesday' then 3 else 4 end;
      for i in 0..14 loop
        if extract(isodow from v_local_now::date + i)::int=v_day then
          v_date:=v_local_now::date+i;
          v_candidate:=make_timestamptz(extract(year from v_date)::int,extract(month from v_date)::int,extract(day from v_date)::int,extract(hour from p_local_time)::int,extract(minute from p_local_time)::int,extract(second from p_local_time),p_timezone);
          if v_candidate>p_from then exit; else v_candidate:=null; end if;
        end if;
      end loop;
    elsif v_rule='special' then
      select min(x.event_start_at) into v_candidate from (
        select g.event_start_at from public.global_events g where g.closed_at is null and g.event_type='special' and g.event_start_at>p_from
        union all
        select b.event_start_at from public.branch_events b where b.closed_at is null and b.event_type='special' and b.branch_id=p_branch_id and b.event_start_at>p_from
      ) x;
    end if;
    if v_candidate is not null and (v_best is null or v_candidate<v_best) then v_best:=v_candidate; end if;
    v_candidate:=null;
  end loop;
  return v_best;
end;
$$;

create or replace function private.activate_pending_auto_give()
returns trigger
language plpgsql
security definer
set search_path=''
as $$
declare
  v_tx public.giving_transactions;
  v_rules text[];
  v_timezone text;
  v_time time;
  v_next timestamptz;
  v_mandate_id uuid;
begin
  if not new.reusable or not new.is_active then return new; end if;
  select * into v_tx from public.giving_transactions
  where profile_id=new.profile_id and status='successful'
    and pending_auto_give is not null and mandate_id is null
  order by paid_at desc nulls last, created_at desc limit 1 for update;
  if v_tx.id is null then return new; end if;

  select coalesce(array_agg(value),array[]::text[]) into v_rules
  from jsonb_array_elements_text(v_tx.pending_auto_give->'rule_keys');
  v_timezone:=coalesce(nullif(v_tx.pending_auto_give->>'timezone',''),'Africa/Lagos');
  begin v_time:=(v_tx.pending_auto_give->>'local_charge_time')::time; exception when others then return new; end;
  if cardinality(v_rules)=0 or exists(select 1 from unnest(v_rules) r where r !~ '^((weekday:[1-7]|monthly:([1-9]|[12][0-9]|3[01])|yearly:([1-9]|1[0-2]):([1-9]|[12][0-9]|3[01]))(:[0-9a-f-]{36})?|event:[0-9]{4}-[0-9]{2}-[0-9]{2}:[0-9a-f-]{36})$') then return new; end if;
  v_next:=private.next_auto_give_charge(v_tx.profile_id,v_tx.branch_id,v_rules,v_timezone,v_time,now());
  if v_next is null then return new; end if;
  insert into public.recurring_giving_mandates(profile_id,branch_id,giving_type,project_id,amount_kobo,rule_keys,timezone,local_charge_time,authorization_id,status,next_charge_at,consent_at,created_at,updated_at)
  values(v_tx.profile_id,v_tx.branch_id,v_tx.giving_type,v_tx.project_id,v_tx.amount_kobo,v_rules,v_timezone,v_time,new.id,'active',v_next,now(),now(),now())
  returning id into v_mandate_id;
  update public.giving_transactions set mandate_id=v_mandate_id,pending_auto_give=null,updated_at=now() where id=v_tx.id;
  return new;
end;
$$;

drop trigger if exists activate_pending_auto_give_after_authorization on private.paystack_authorizations;
create trigger activate_pending_auto_give_after_authorization
after insert or update of reusable,is_active,updated_at on private.paystack_authorizations
for each row execute function private.activate_pending_auto_give();
