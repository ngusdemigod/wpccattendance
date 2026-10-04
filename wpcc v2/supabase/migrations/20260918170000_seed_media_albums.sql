create unique index if not exists media_albums_title_unique_idx
  on public.media_albums (lower(trim(title)));

insert into public.media_albums (title, description, featured_image, status)
select
  'Marriage, Family & Relationships',
  'Practical, faith-centered teaching for stronger marriages, healthier relationships, and intentional family life.',
  artwork_url,
  'published'
from public.media_sermons
where title = 'Building healthy relationships and marriages'
limit 1
on conflict do nothing;

insert into public.media_albums (title, description, featured_image, status)
select
  'Faith, Growth & Spiritual Alignment',
  'Messages on trusting God, spiritual positioning, breakthrough, purpose, and sustaining a disciplined life of faith.',
  artwork_url,
  'published'
from public.media_sermons
where title = 'Joy In Greatness'
limit 1
on conflict do nothing;

insert into public.media_albums (title, description, featured_image, status)
select
  'Power Touch 2025',
  'Conference teachings and ministry sessions from Power Touch 2025.',
  artwork_url,
  'published'
from public.media_sermons
where title = 'PT25 Rev Adeshina Gentry Word'
limit 1
on conflict do nothing;

with marriage_tracks(title, track_number) as (
  values
    ('A good marriage ', 1),
    ('Building healthy relationships and marriages', 2),
    ('Submission in marriage - Pst Adonis Nwammah', 3),
    ('BE- attitudes of marriage PT1', 4),
    ('BE-Attitudes of marriage PT2', 5),
    ('BE Attitudes of marriage 3', 6),
    ('BE Attitudes of marriage 4', 7),
    ('BE Attitudes of marriage 5', 8),
    ('BE Attitudes of marriage 6', 9),
    ('Seasons in Marriage', 10),
    ('Becoming A Better Father ', 11)
)
insert into public.media_album_tracks (album_id, episode_id, track_number)
select album.id, episode.id, tracks.track_number
from marriage_tracks tracks
join public.media_sermons episode on episode.title = tracks.title
join public.media_albums album
  on lower(trim(album.title)) = lower('Marriage, Family & Relationships')
on conflict do nothing;

with growth_tracks(title, track_number) as (
  values
    ('Spiritual Positioning', 1),
    ('After fasting what next', 2),
    ('The blessedness of waiting on the lord ', 3),
    ('The blessedness of waiting on the lord Pt2', 4),
    ('Breaking Forth', 5),
    ('Joy In Greatness', 6)
)
insert into public.media_album_tracks (album_id, episode_id, track_number)
select album.id, episode.id, tracks.track_number
from growth_tracks tracks
join public.media_sermons episode on episode.title = tracks.title
join public.media_albums album
  on lower(trim(album.title)) = lower('Faith, Growth & Spiritual Alignment')
on conflict do nothing;

with power_touch_tracks(title, track_number) as (
  values
    ('Consecration Day 1', 1),
    ('Day 1 Business Session Morning', 2),
    ('Pst Yemi David Morning Session PT25 ', 3),
    ('PT25 Pst Yemi Davids Day 2', 4),
    ('PT25 Rev Adeshina Gentry Mid morning Business class ', 5),
    ('PT25 Rev Adeshina Gentry Word', 6),
    ('Day 6 Rev. George Izunwa PT25', 7)
)
insert into public.media_album_tracks (album_id, episode_id, track_number)
select album.id, episode.id, tracks.track_number
from power_touch_tracks tracks
join public.media_sermons episode on episode.title = tracks.title
join public.media_albums album
  on lower(trim(album.title)) = lower('Power Touch 2025')
on conflict do nothing;
