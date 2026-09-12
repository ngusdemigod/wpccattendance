-- Spotify podcast synchronization and authenticated media feed.

create extension if not exists pg_net with schema extensions;
create extension if not exists pg_cron with schema pg_catalog;

create table if not exists public.media_sermons (
  id uuid primary key default gen_random_uuid(),
  provider text not null default 'spotify',
  provider_content_type text not null default 'episode',
  external_id text not null,
  collection_external_id text not null,
  title text not null,
  description text,
  description_html text,
  duration_ms integer,
  explicit boolean not null default false,
  source_published_at date,
  artwork_url text,
  provider_url text,
  embed_url text,
  status text not null default 'published'
    check (status in ('published', 'hidden')),
  last_synced_at timestamptz not null default now(),
  raw_payload jsonb not null default '{}'::jsonb,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (provider, external_id)
);

create index if not exists media_sermons_published_idx
  on public.media_sermons (source_published_at desc, created_at desc)
  where status = 'published';

alter table public.media_sermons enable row level security;

drop policy if exists media_sermons_authenticated_read
  on public.media_sermons;
create policy media_sermons_authenticated_read
  on public.media_sermons
  for select
  to authenticated
  using (status = 'published');

grant select on public.media_sermons to authenticated;
revoke all on public.media_sermons from anon;

create table if not exists public.media_sync_state (
  provider text not null,
  collection_id text not null,
  last_offset integer not null default 0,
  last_synced_at timestamptz,
  last_success_at timestamptz,
  last_error text,
  updated_at timestamptz not null default now(),
  primary key (provider, collection_id)
);

alter table public.media_sync_state enable row level security;
revoke all on public.media_sync_state from anon, authenticated;

create or replace function public.media_spotify_sync_config()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'client_id', (
      select decrypted_secret
      from vault.decrypted_secrets
      where name = 'spotify_client_id'
      limit 1
    ),
    'client_secret', (
      select decrypted_secret
      from vault.decrypted_secrets
      where name = 'spotify_client_secret'
      limit 1
    ),
    'show_id', (
      select decrypted_secret
      from vault.decrypted_secrets
      where name = 'spotify_show_id'
      limit 1
    ),
    'sync_secret', (
      select decrypted_secret
      from vault.decrypted_secrets
      where name = 'spotify_sync_secret'
      limit 1
    )
  );
$$;

revoke all on function public.media_spotify_sync_config() from public, anon, authenticated;
grant execute on function public.media_spotify_sync_config() to service_role;

do $$
declare
  existing_job bigint;
begin
  select jobid
  into existing_job
  from cron.job
  where jobname = 'sync-spotify-sermons-hourly'
  limit 1;

  if existing_job is not null then
    perform cron.unschedule(existing_job);
  end if;

  perform cron.schedule(
    'sync-spotify-sermons-hourly',
    '17 * * * *',
    $job$
      select net.http_post(
        url := 'https://pgpihzhvysbadrzjhvxw.supabase.co/functions/v1/sync-spotify-sermons',
        headers := jsonb_build_object(
          'Content-Type', 'application/json',
          'x-sync-secret', (
            select decrypted_secret
            from vault.decrypted_secrets
            where name = 'spotify_sync_secret'
            limit 1
          )
        ),
        body := jsonb_build_object('source', 'pg_cron'),
        timeout_milliseconds := 30000
      );
    $job$
  );
end
$$;

