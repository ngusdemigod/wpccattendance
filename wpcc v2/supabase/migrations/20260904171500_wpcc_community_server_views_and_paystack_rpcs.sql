-- Server-time event reads, local-time event creation, and service-only Paystack state transitions.

create or replace function public.community_visible_events(
  p_mode text default 'upcoming',
  p_event_type text default 'all',
  p_limit integer default 50,
  p_offset integer default 0
)
returns table(
  event_id uuid,
  title text,
  description text,
  event_scope text,
  source_table text,
  branch_id uuid,
  department_id uuid,
  event_start_at timestamptz,
  event_end_at timestamptz,
  featured_image text,
  location text,
  latitude double precision,
  longitude double precision,
  event_type text,
  is_ongoing boolean,
  is_upcoming boolean
)
language sql
stable
security invoker
set search_path=''
as $$
  select e.event_id,e.title,e.description,e.event_scope,e.source_table,e.branch_id,e.department_id,
         e.event_start_at,e.event_end_at,e.featured_image,e.location,e.latitude,e.longitude,e.event_type,
         (e.event_start_at <= now() and coalesce(e.event_end_at,e.event_start_at + interval '4 hours') >= now()) as is_ongoing,
         (e.event_start_at > now()) as is_upcoming
  from public.my_events e
  where e.is_active
    and (lower(coalesce(p_event_type,'all'))='all' or e.event_type=lower(p_event_type))
    and (
      lower(coalesce(p_mode,'upcoming'))='all'
      or (lower(p_mode)='upcoming' and e.event_start_at>now())
      or (lower(p_mode)='ongoing' and e.event_start_at<=now() and coalesce(e.event_end_at,e.event_start_at+interval '4 hours')>=now())
      or (lower(p_mode)='recent' and coalesce(e.event_end_at,e.event_start_at)<now())
    )
  order by
    case when lower(coalesce(p_mode,'upcoming'))='recent' then null else e.event_start_at end asc,
    case when lower(coalesce(p_mode,'upcoming'))='recent' then e.event_start_at end desc
  limit greatest(1,least(coalesce(p_limit,50),100)) offset greatest(0,coalesce(p_offset,0));
$$;
grant execute on function public.community_visible_events(text,text,integer,integer) to authenticated;

create or replace function public.community_create_department_event_local(
  p_department_id uuid,
  p_event_type text,
  p_title text,
  p_description text,
  p_start_local timestamp without time zone,
  p_end_local timestamp without time zone,
  p_timezone text,
  p_featured_url text,
  p_location text,
  p_latitude double precision default null,
  p_longitude double precision default null
)
returns jsonb
language plpgsql
security definer
set search_path=''
as $$
declare
  v_start timestamptz;
  v_end timestamptz;
begin
  if coalesce(nullif(btrim(p_timezone),''),'')='' then raise exception 'Timezone is required'; end if;
  -- PostgreSQL validates the IANA timezone. Conversion is server-owned and never
  -- depends on the browser/device timezone.
  v_start := p_start_local at time zone p_timezone;
  v_end := p_end_local at time zone p_timezone;
  return public.community_create_department_event(
    p_department_id,p_event_type,p_title,p_description,v_start,v_end,p_featured_url,p_location,p_latitude,p_longitude
  );
end;
$$;
revoke all on function public.community_create_department_event_local(uuid,text,text,text,timestamp without time zone,timestamp without time zone,text,text,text,double precision,double precision) from public,anon;
grant execute on function public.community_create_department_event_local(uuid,text,text,text,timestamp without time zone,timestamp without time zone,text,text,text,double precision,double precision) to authenticated;

create or replace function public.wpcc_initialize_giving_transaction(
  p_profile_id uuid,
  p_giving_type text,
  p_project_id uuid,
  p_amount_kobo bigint,
  p_internal_reference text,
  p_paystack_reference text
)
returns public.giving_transactions
language plpgsql
security definer
set search_path=''
as $$
declare v_branch uuid; v_row public.giving_transactions;
begin
  if current_user not in ('service_role','postgres') then raise exception 'Service role required' using errcode='42501'; end if;
  if p_amount_kobo<100 then raise exception 'Amount is too small'; end if;
  if p_giving_type not in ('offering','tithe','prophet_offering','project','auto_give') then raise exception 'Invalid giving type'; end if;
  if p_giving_type='project' and (p_project_id is null or not exists(select 1 from public.giving_projects gp where gp.id=p_project_id and gp.status='active')) then raise exception 'Project is not available'; end if;
  select p.branch_id into v_branch from public.profiles p where p.id=p_profile_id;
  insert into public.giving_transactions(profile_id,branch_id,giving_type,project_id,amount_kobo,currency,internal_reference,paystack_reference,status,initiated_at,created_at,updated_at)
  values(p_profile_id,v_branch,p_giving_type,p_project_id,p_amount_kobo,'NGN',p_internal_reference,p_paystack_reference,'initialized',now(),now(),now())
  returning * into v_row;
  return v_row;
end;
$$;
revoke all on function public.wpcc_initialize_giving_transaction(uuid,text,uuid,bigint,text,text) from public,anon,authenticated;
grant execute on function public.wpcc_initialize_giving_transaction(uuid,text,uuid,bigint,text,text) to service_role;

create or replace function public.wpcc_record_paystack_transaction(
  p_reference text,
  p_status text,
  p_channel text,
  p_source_summary text,
  p_provider_response jsonb,
  p_customer_code text,
  p_email text,
  p_authorization_code text,
  p_card_type text,
  p_bank text,
  p_last4 text,
  p_exp_month text,
  p_exp_year text,
  p_signature text,
  p_reusable boolean
)
returns public.giving_transactions
language plpgsql
security definer
set search_path=''
as $$
declare v_row public.giving_transactions; v_auth_id uuid;
begin
  if current_user not in ('service_role','postgres') then raise exception 'Service role required' using errcode='42501'; end if;
  select * into v_row from public.giving_transactions where paystack_reference=p_reference or internal_reference=p_reference limit 1;
  if v_row.id is null then raise exception 'Giving transaction not found'; end if;

  update public.giving_transactions
  set status=case when lower(p_status)='success' then 'successful' else 'failed' end,
      payment_channel=nullif(p_channel,''),source_summary=nullif(p_source_summary,''),provider_response=coalesce(p_provider_response,'{}'::jsonb),
      paid_at=case when lower(p_status)='success' then coalesce(paid_at,now()) else paid_at end,
      failed_at=case when lower(p_status)<>'success' then coalesce(failed_at,now()) else failed_at end,
      updated_at=now()
  where id=v_row.id returning * into v_row;

  if lower(p_status)='success' and coalesce(p_reusable,false) and coalesce(nullif(p_authorization_code,''),'')<>'' and coalesce(nullif(p_email,''),'')<>'' then
    insert into private.paystack_authorizations(profile_id,branch_id,customer_code,authorization_code,email,card_type,bank,last4,exp_month,exp_year,signature,reusable,is_active,created_at,updated_at)
    values(v_row.profile_id,v_row.branch_id,nullif(p_customer_code,''),p_authorization_code,p_email,nullif(p_card_type,''),nullif(p_bank,''),nullif(p_last4,''),nullif(p_exp_month,''),nullif(p_exp_year,''),nullif(p_signature,''),true,true,now(),now())
    on conflict(authorization_code) do update set customer_code=excluded.customer_code,email=excluded.email,card_type=excluded.card_type,bank=excluded.bank,last4=excluded.last4,exp_month=excluded.exp_month,exp_year=excluded.exp_year,signature=excluded.signature,reusable=true,is_active=true,updated_at=now()
    returning id into v_auth_id;
  end if;
  return v_row;
end;
$$;
revoke all on function public.wpcc_record_paystack_transaction(text,text,text,text,jsonb,text,text,text,text,text,text,text,text,text,boolean) from public,anon,authenticated;
grant execute on function public.wpcc_record_paystack_transaction(text,text,text,text,jsonb,text,text,text,text,text,text,text,text,text,boolean) to service_role;

create or replace function public.wpcc_due_auto_give(p_limit integer default 25)
returns table(
  mandate_id uuid, profile_id uuid, amount_kobo bigint, giving_type text, project_id uuid,
  branch_id uuid, authorization_code text, email text, next_charge_at timestamptz,
  rule_keys text[], timezone text, local_charge_time time
)
language plpgsql
security definer
set search_path=''
as $$
begin
  if current_user not in ('service_role','postgres') then raise exception 'Service role required' using errcode='42501'; end if;
  return query
  select m.id,m.profile_id,m.amount_kobo,m.giving_type,m.project_id,m.branch_id,a.authorization_code,a.email,m.next_charge_at,m.rule_keys,m.timezone,m.local_charge_time
  from public.recurring_giving_mandates m
  join private.paystack_authorizations a on a.id=m.authorization_id
  where m.status='active' and m.next_charge_at is not null and m.next_charge_at<=now() and a.is_active and a.reusable
  order by m.next_charge_at
  for update of m skip locked
  limit greatest(1,least(coalesce(p_limit,25),100));
end;
$$;
revoke all on function public.wpcc_due_auto_give(integer) from public,anon,authenticated;
grant execute on function public.wpcc_due_auto_give(integer) to service_role;

create or replace function public.wpcc_advance_auto_give(p_mandate_id uuid,p_charged boolean)
returns public.recurring_giving_mandates
language plpgsql security definer set search_path=''
as $$
declare v_row public.recurring_giving_mandates; v_next timestamptz;
begin
  if current_user not in ('service_role','postgres') then raise exception 'Service role required' using errcode='42501'; end if;
  select * into v_row from public.recurring_giving_mandates where id=p_mandate_id for update;
  if v_row.id is null then raise exception 'Mandate not found'; end if;
  if v_row.status<>'active' then return v_row; end if;
  v_next:=private.next_auto_give_charge(v_row.profile_id,v_row.branch_id,v_row.rule_keys,v_row.timezone,v_row.local_charge_time,now()+interval '1 minute');
  update public.recurring_giving_mandates
  set last_charge_at=case when p_charged then now() else last_charge_at end,next_charge_at=v_next,updated_at=now()
  where id=p_mandate_id returning * into v_row;
  return v_row;
end;
$$;
revoke all on function public.wpcc_advance_auto_give(uuid,boolean) from public,anon,authenticated;
grant execute on function public.wpcc_advance_auto_give(uuid,boolean) to service_role;
