alter table public.notification_outbox
  add column if not exists locked_at timestamptz;

create index if not exists notification_outbox_email_ready_idx
  on public.notification_outbox(available_at, created_at)
  where channel = 'email' and processed_at is null;

create or replace function public.churchmetric_claim_email_outbox(p_limit integer default 10)
returns setof public.notification_outbox
language sql
security definer
set search_path = ''
as $$
  with candidates as (
    select item.id
    from public.notification_outbox item
    where item.channel = 'email'
      and item.event_type = 'broadcast_campaign_created'
      and item.processed_at is null
      and item.available_at <= now()
      and item.attempts < 5
      and (
        item.status in ('pending', 'retry')
        or (item.status = 'processing' and item.locked_at < now() - interval '15 minutes')
      )
    order by item.available_at, item.created_at
    for update skip locked
    limit greatest(1, least(coalesce(p_limit, 10), 50))
  )
  update public.notification_outbox item
  set status = 'processing',
      locked_at = now(),
      attempts = item.attempts + 1,
      last_error = null
  from candidates
  where item.id = candidates.id
  returning item.*
$$;

revoke all on function public.churchmetric_claim_email_outbox(integer) from public, anon, authenticated;
grant execute on function public.churchmetric_claim_email_outbox(integer) to service_role;
