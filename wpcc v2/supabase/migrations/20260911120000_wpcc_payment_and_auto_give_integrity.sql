-- Durable Auto Give claims and monotonic Paystack transaction recording.

create table if not exists private.auto_give_charge_attempts (
  id uuid primary key default gen_random_uuid(),
  mandate_id uuid not null references public.recurring_giving_mandates(id) on delete cascade,
  scheduled_for timestamptz not null,
  transaction_id uuid not null unique references public.giving_transactions(id) on delete cascade,
  paystack_reference text not null unique,
  claim_token uuid,
  claimed_until timestamptz,
  status text not null default 'pending',
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint auto_give_attempt_status_check check (status in ('pending','successful','failed')),
  constraint auto_give_attempt_occurrence_unique unique (mandate_id, scheduled_for)
);

create index if not exists auto_give_charge_attempts_claim_idx
  on private.auto_give_charge_attempts(status, claimed_until)
  where status = 'pending';

revoke all on table private.auto_give_charge_attempts from public, anon, authenticated;
grant select, insert, update on table private.auto_give_charge_attempts to service_role;

create or replace function public.wpcc_claim_due_auto_give(
  p_limit integer default 25,
  p_lease_seconds integer default 600
)
returns table(
  claim_id uuid, claim_token uuid, transaction_id uuid, paystack_reference text,
  mandate_id uuid, profile_id uuid, amount_kobo bigint, giving_type text,
  project_id uuid, branch_id uuid, authorization_code text, email text,
  scheduled_for timestamptz
)
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_m record;
  v_attempt private.auto_give_charge_attempts;
  v_transaction public.giving_transactions;
  v_token uuid;
  v_reference text;
begin
  if current_user not in ('service_role','postgres') then
    raise exception 'Service role required' using errcode='42501';
  end if;

  for v_m in
    select m.*, a.authorization_code, a.email
    from public.recurring_giving_mandates m
    join private.paystack_authorizations a on a.id = m.authorization_id
    where m.status = 'active'
      and m.next_charge_at is not null
      and m.next_charge_at <= now()
      and a.is_active
      and a.reusable
    order by m.next_charge_at
    for update of m skip locked
    limit greatest(1, least(coalesce(p_limit, 25), 100))
  loop
    v_attempt := null;
    select * into v_attempt
    from private.auto_give_charge_attempts x
    where x.mandate_id = v_m.id and x.scheduled_for = v_m.next_charge_at
    for update;

    if v_attempt.id is null then
      v_attempt.id := gen_random_uuid();
      v_reference := 'AUTO-' || v_attempt.id::text;
      insert into public.giving_transactions(
        profile_id, branch_id, giving_type, project_id, mandate_id, amount_kobo,
        currency, internal_reference, paystack_reference, status,
        initiated_at, created_at, updated_at
      ) values (
        v_m.profile_id, v_m.branch_id, v_m.giving_type, v_m.project_id, v_m.id,
        v_m.amount_kobo, 'NGN', 'AUTOGIVE-' || gen_random_uuid()::text,
        v_reference, 'pending', now(), now(), now()
      ) returning * into v_transaction;

      insert into private.auto_give_charge_attempts(
        id, mandate_id, scheduled_for, transaction_id, paystack_reference
      ) values (
        v_attempt.id, v_m.id, v_m.next_charge_at, v_transaction.id, v_reference
      ) returning * into v_attempt;
    end if;

    if v_attempt.status <> 'pending'
      or (v_attempt.claimed_until is not null and v_attempt.claimed_until > now()) then
      continue;
    end if;

    v_token := gen_random_uuid();
    update private.auto_give_charge_attempts x
    set claim_token = v_token,
        claimed_until = now() + make_interval(secs => greatest(60, least(coalesce(p_lease_seconds, 600), 3600))),
        updated_at = now()
    where x.id = v_attempt.id
    returning * into v_attempt;

    claim_id := v_attempt.id;
    claim_token := v_token;
    transaction_id := v_attempt.transaction_id;
    paystack_reference := v_attempt.paystack_reference;
    mandate_id := v_m.id;
    profile_id := v_m.profile_id;
    amount_kobo := v_m.amount_kobo;
    giving_type := v_m.giving_type;
    project_id := v_m.project_id;
    branch_id := v_m.branch_id;
    authorization_code := v_m.authorization_code;
    email := v_m.email;
    scheduled_for := v_attempt.scheduled_for;
    return next;
  end loop;
end;
$$;

revoke all on function public.wpcc_claim_due_auto_give(integer,integer) from public,anon,authenticated;
grant execute on function public.wpcc_claim_due_auto_give(integer,integer) to service_role;

create or replace function public.wpcc_complete_auto_give_claim(
  p_claim_id uuid,
  p_claim_token uuid,
  p_charged boolean
)
returns public.recurring_giving_mandates
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_attempt private.auto_give_charge_attempts;
  v_mandate public.recurring_giving_mandates;
  v_next timestamptz;
begin
  if current_user not in ('service_role','postgres') then
    raise exception 'Service role required' using errcode='42501';
  end if;

  select * into v_attempt
  from private.auto_give_charge_attempts x
  where x.id = p_claim_id
  for update;

  if v_attempt.id is null then raise exception 'Auto Give claim not found'; end if;
  if v_attempt.status <> 'pending' then
    select * into v_mandate from public.recurring_giving_mandates where id = v_attempt.mandate_id;
    return v_mandate;
  end if;
  if v_attempt.claim_token is distinct from p_claim_token then
    raise exception 'Auto Give claim is no longer owned' using errcode='42501';
  end if;

  select * into v_mandate
  from public.recurring_giving_mandates
  where id = v_attempt.mandate_id
  for update;

  if v_mandate.id is null then raise exception 'Mandate not found'; end if;
  if v_mandate.status = 'active' and v_mandate.next_charge_at = v_attempt.scheduled_for then
    v_next := private.next_auto_give_charge(
      v_mandate.profile_id, v_mandate.branch_id, v_mandate.rule_keys,
      v_mandate.timezone, v_mandate.local_charge_time, now() + interval '1 minute'
    );
    update public.recurring_giving_mandates
    set last_charge_at = case when p_charged then now() else last_charge_at end,
        next_charge_at = v_next,
        updated_at = now()
    where id = v_mandate.id
    returning * into v_mandate;
  end if;

  update private.auto_give_charge_attempts
  set status = case when p_charged then 'successful' else 'failed' end,
      completed_at = now(), claimed_until = null, updated_at = now()
  where id = v_attempt.id;

  return v_mandate;
end;
$$;

revoke all on function public.wpcc_complete_auto_give_claim(uuid,uuid,boolean) from public,anon,authenticated;
grant execute on function public.wpcc_complete_auto_give_claim(uuid,uuid,boolean) to service_role;

create or replace function public.wpcc_record_paystack_transaction(
  p_reference text, p_status text, p_channel text, p_source_summary text,
  p_provider_response jsonb, p_customer_code text, p_email text,
  p_authorization_code text, p_card_type text, p_bank text, p_last4 text,
  p_exp_month text, p_exp_year text, p_signature text, p_reusable boolean
)
returns public.giving_transactions
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_row public.giving_transactions;
  v_auth_id uuid;
  v_status text := lower(coalesce(p_status, ''));
  v_provider_amount bigint;
  v_provider_currency text;
begin
  if current_user not in ('service_role','postgres') then
    raise exception 'Service role required' using errcode='42501';
  end if;

  select * into v_row
  from public.giving_transactions
  where paystack_reference = p_reference or internal_reference = p_reference
  order by case when paystack_reference = p_reference then 0 else 1 end
  limit 1
  for update;
  if v_row.id is null then raise exception 'Giving transaction not found'; end if;

  if v_status = 'success' then
    begin
      v_provider_amount := nullif(p_provider_response ->> 'amount', '')::bigint;
    exception when invalid_text_representation or numeric_value_out_of_range then
      raise exception 'Invalid provider amount';
    end;
    v_provider_currency := upper(coalesce(p_provider_response ->> 'currency', ''));
    if v_provider_amount is distinct from v_row.amount_kobo
      or v_provider_currency is distinct from v_row.currency then
      raise exception 'Payment verification mismatch' using errcode='22000';
    end if;
  end if;

  update public.giving_transactions
  set status = case
        when v_row.status = 'successful' then 'successful'
        when v_status = 'success' then 'successful'
        else 'failed'
      end,
      payment_channel = case when v_row.status = 'successful' and v_status <> 'success' then v_row.payment_channel else nullif(p_channel,'') end,
      source_summary = case when v_row.status = 'successful' and v_status <> 'success' then v_row.source_summary else nullif(p_source_summary,'') end,
      provider_response = case when v_row.status = 'successful' and v_status <> 'success' then v_row.provider_response else coalesce(p_provider_response,'{}'::jsonb) end,
      paid_at = case when v_status = 'success' then coalesce(v_row.paid_at,now()) else v_row.paid_at end,
      failed_at = case
        when v_row.status = 'successful' or v_status = 'success' then v_row.failed_at
        else coalesce(v_row.failed_at,now())
      end,
      updated_at = now()
  where id = v_row.id
  returning * into v_row;

  if v_status = 'success' and coalesce(p_reusable,false)
    and coalesce(nullif(p_authorization_code,''),'') <> ''
    and coalesce(nullif(p_email,''),'') <> '' then
    insert into private.paystack_authorizations(
      profile_id,branch_id,customer_code,authorization_code,email,card_type,
      bank,last4,exp_month,exp_year,signature,reusable,is_active,created_at,updated_at
    ) values (
      v_row.profile_id,v_row.branch_id,nullif(p_customer_code,''),p_authorization_code,
      p_email,nullif(p_card_type,''),nullif(p_bank,''),nullif(p_last4,''),
      nullif(p_exp_month,''),nullif(p_exp_year,''),nullif(p_signature,''),true,true,now(),now()
    ) on conflict(authorization_code) do update set
      customer_code=excluded.customer_code,email=excluded.email,card_type=excluded.card_type,
      bank=excluded.bank,last4=excluded.last4,exp_month=excluded.exp_month,
      exp_year=excluded.exp_year,signature=excluded.signature,reusable=true,
      is_active=true,updated_at=now()
    returning id into v_auth_id;
  end if;
  return v_row;
end;
$$;

revoke all on function public.wpcc_record_paystack_transaction(text,text,text,text,jsonb,text,text,text,text,text,text,text,text,text,boolean) from public,anon,authenticated;
grant execute on function public.wpcc_record_paystack_transaction(text,text,text,text,jsonb,text,text,text,text,text,text,text,text,text,boolean) to service_role;
