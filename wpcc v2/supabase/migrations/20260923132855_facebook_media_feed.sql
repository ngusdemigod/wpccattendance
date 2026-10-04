begin;
create table public.community_media_feed (
  id uuid primary key default gen_random_uuid(),
  source_id text not null unique,
  page_id text not null,
  caption text not null default '',
  image_url text not null,
  permalink text not null,
  category text not null default 'photos' check (category in ('photos','choir')),
  published_at timestamptz,
  synced_at timestamptz not null default now(),
  is_active boolean not null default true
);
alter table public.community_media_feed enable row level security;
revoke all on public.community_media_feed from anon, authenticated;
grant select on public.community_media_feed to authenticated;
grant all on public.community_media_feed to service_role;
create policy community_media_read on public.community_media_feed for select to authenticated using (is_active and synced_at > now() - interval '24 hours');
create index community_media_feed_published on public.community_media_feed(published_at desc) where is_active;
commit;
