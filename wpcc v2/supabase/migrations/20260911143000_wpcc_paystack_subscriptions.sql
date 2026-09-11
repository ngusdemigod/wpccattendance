-- Paystack-managed Auto Give subscriptions replace locally scheduled authorization charges.

drop index if exists public.recurring_giving_due_idx;

alter table public.recurring_giving_mandates
  drop constraint if exists recurring_giving_rules_check,
  drop constraint if exists recurring_giving_status_check,
  alter column rule_keys drop not null,
  alter column authorization_id drop not null,
  add column if not exists interval text,
  add column if not exists paystack_plan_code text,
  add column if not exists paystack_subscription_code text,
  add column if not exists paystack_email_token text,
  add column if not exists paystack_customer_code text,
  add column if not exists provider_status text,
  add column if not exists provider_response jsonb not null default '{}'::jsonb,
  add column if not exists activated_at timestamptz;

alter table public.recurring_giving_mandates
  add constraint recurring_giving_status_check
    check (status in ('pending','active','paused','cancelled')),
  add constraint recurring_giving_interval_check
    check (interval in ('weekly','monthly','quarterly','biannually','annually'));

create unique index if not exists recurring_giving_plan_code_unique
  on public.recurring_giving_mandates(paystack_plan_code)
  where paystack_plan_code is not null;
create unique index if not exists recurring_giving_subscription_code_unique
  on public.recurring_giving_mandates(paystack_subscription_code)
  where paystack_subscription_code is not null;
create index if not exists recurring_giving_customer_idx
  on public.recurring_giving_mandates(paystack_customer_code,status);

-- The provider must be disabled before local cancellation, so clients can no
-- longer bypass Paystack by calling the former database-only RPC.
revoke all on function public.create_auto_give_mandate(bigint,text,uuid,text[],uuid,text,time)
  from public,anon,authenticated;
revoke all on function public.cancel_auto_give_mandate(uuid)
  from public,anon,authenticated;

-- The local charge worker is retired. Keep its audit tables/functions private
-- so old deployments cannot create new recurring charges.
revoke all on function public.wpcc_claim_due_auto_give(integer,integer)
  from public,anon,authenticated,service_role;
revoke all on function public.wpcc_complete_auto_give_claim(uuid,uuid,boolean)
  from public,anon,authenticated,service_role;

