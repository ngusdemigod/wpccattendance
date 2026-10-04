create table if not exists public.media_albums (
  id uuid primary key default gen_random_uuid(),
  title text not null check (length(trim(title)) between 1 and 160),
  featured_image text,
  description text,
  status text not null default 'draft'
    check (status in ('draft', 'published', 'archived')),
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.media_album_tracks (
  album_id uuid not null references public.media_albums(id) on delete cascade,
  episode_id uuid not null references public.media_sermons(id) on delete cascade,
  track_number integer not null check (track_number > 0),
  created_at timestamptz not null default now(),
  primary key (album_id, episode_id),
  unique (album_id, track_number)
);

create index if not exists media_albums_status_created_idx
  on public.media_albums(status, created_at desc);
create index if not exists media_album_tracks_episode_idx
  on public.media_album_tracks(episode_id);

alter table public.media_albums enable row level security;
alter table public.media_album_tracks enable row level security;

drop policy if exists media_albums_authenticated_read on public.media_albums;
create policy media_albums_authenticated_read
  on public.media_albums for select to authenticated
  using (status = 'published' or public.is_admin_or_global());

drop policy if exists media_albums_admin_manage on public.media_albums;
create policy media_albums_admin_manage
  on public.media_albums for all to authenticated
  using (public.is_admin_or_global())
  with check (public.is_admin_or_global());

drop policy if exists media_album_tracks_authenticated_read
  on public.media_album_tracks;
create policy media_album_tracks_authenticated_read
  on public.media_album_tracks for select to authenticated
  using (
    exists (
      select 1 from public.media_albums album
      where album.id = media_album_tracks.album_id
        and (album.status = 'published' or public.is_admin_or_global())
    )
  );

drop policy if exists media_album_tracks_admin_manage
  on public.media_album_tracks;
create policy media_album_tracks_admin_manage
  on public.media_album_tracks for all to authenticated
  using (public.is_admin_or_global())
  with check (public.is_admin_or_global());

grant select on public.media_albums, public.media_album_tracks to authenticated;
grant insert, update, delete on public.media_albums, public.media_album_tracks
  to authenticated;
revoke all on public.media_albums, public.media_album_tracks from anon;

create or replace function public.media_set_album_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists media_albums_set_updated_at on public.media_albums;
create trigger media_albums_set_updated_at
before update on public.media_albums
for each row execute function public.media_set_album_updated_at();
