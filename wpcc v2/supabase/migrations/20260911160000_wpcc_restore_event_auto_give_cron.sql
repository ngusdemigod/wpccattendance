-- Restore event-day Auto Give and invoke the durable worker with Supabase Cron.

select cron.unschedule(jobid)
from cron.job
where jobname = 'wpcc-process-auto-give';

alter table public.recurring_giving_mandates
  drop constraint if exists recurring_giving_interval_check,
  drop constraint if exists recurring_giving_status_check;

alter table public.recurring_giving_mandates
  drop column if exists interval,
  drop column if exists paystack_plan_code,
  drop column if exists paystack_subscription_code,
  drop column if exists paystack_email_token,
  drop column if exists paystack_customer_code,
  drop column if exists provider_status,
  drop column if exists provider_response,
  drop column if exists activated_at,
  alter column rule_keys set not null,
  alter column authorization_id set not null;

alter table public.recurring_giving_mandates
  add constraint recurring_giving_status_check
    check (status in ('active','paused','cancelled')),
  add constraint recurring_giving_rules_check
    check (cardinality(rule_keys) > 0);

create index if not exists recurring_giving_due_idx
  on public.recurring_giving_mandates(status,next_charge_at)
  where status='active';

grant execute on function public.create_auto_give_mandate(bigint,text,uuid,text[],uuid,text,time)
  to authenticated;
grant execute on function public.cancel_auto_give_mandate(uuid)
  to authenticated;
grant execute on function public.wpcc_claim_due_auto_give(integer,integer)
  to service_role;
grant execute on function public.wpcc_complete_auto_give_claim(uuid,uuid,boolean)
  to service_role;

select cron.schedule(
  'wpcc-process-auto-give',
  '* * * * *',
  $job$
  select net.http_post(
    url := (select decrypted_secret from vault.decrypted_secrets where name='wpcc_project_url') || '/functions/v1/process-auto-give',
    headers := jsonb_build_object(
      'Content-Type','application/json',
      'x-worker-secret',(select decrypted_secret from vault.decrypted_secrets where name='wpcc_giving_worker_secret')
    ),
    body := jsonb_build_object('scheduled_at',now()),
    timeout_milliseconds := 30000
  );
  $job$
);
