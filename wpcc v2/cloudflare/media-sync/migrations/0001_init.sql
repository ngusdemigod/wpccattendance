-- Media catalog for the Media page (Gallery and Videos). Public content only:
-- Facebook page photos, and YouTube / Facebook videos and livestreams. Image
-- bytes live in R2; these tables hold metadata and where the copies are.
--
-- Facebook image URLs expire, so photos and Facebook video thumbnails start as
-- mirror_status 'pending' and the worker copies them into R2. The API only
-- returns rows that are mirrored.

CREATE TABLE photos (
  id            TEXT PRIMARY KEY,                -- Facebook photo id
  caption       TEXT NOT NULL DEFAULT '',
  permalink     TEXT NOT NULL,
  published_at  TEXT NOT NULL,                   -- ISO 8601, UTC
  width         INTEGER,
  height        INTEGER,
  source_url    TEXT NOT NULL,                   -- latest signed Facebook URL, only used while pending
  r2_key        TEXT,                            -- key prefix of the mirrored copies
  mirror_status TEXT NOT NULL DEFAULT 'pending' CHECK (mirror_status IN ('pending', 'done', 'failed')),
  is_active     INTEGER NOT NULL DEFAULT 1,
  last_seen_run TEXT                             -- id of the last full pass that saw this photo
);

CREATE INDEX photos_gallery ON photos (published_at DESC, id DESC)
  WHERE is_active = 1 AND mirror_status = 'done';
CREATE INDEX photos_pending ON photos (published_at DESC)
  WHERE is_active = 1 AND mirror_status = 'pending';

CREATE TABLE videos (
  id               TEXT PRIMARY KEY,             -- '<provider>:<external_id>'
  provider         TEXT NOT NULL CHECK (provider IN ('youtube', 'facebook')),
  external_id      TEXT NOT NULL,
  title            TEXT NOT NULL DEFAULT '',
  description      TEXT,
  thumbnail_url    TEXT,                         -- YouTube: stable URL. Facebook: signed, only used while pending
  r2_key           TEXT,                         -- mirrored Facebook thumbnail (key prefix)
  mirror_status    TEXT NOT NULL DEFAULT 'done' CHECK (mirror_status IN ('pending', 'done', 'failed')),
  permalink_url    TEXT NOT NULL,
  embed_url        TEXT,
  kind             TEXT NOT NULL DEFAULT 'video' CHECK (kind IN ('video', 'live')),
  published_at     TEXT NOT NULL,
  duration_seconds INTEGER,
  status           TEXT NOT NULL DEFAULT 'published' CHECK (status IN ('published', 'hidden')),
  last_seen_run    TEXT,
  UNIQUE (provider, external_id)
);

CREATE INDEX videos_feed ON videos (published_at DESC, id DESC) WHERE status = 'published';

-- One row per source, so a stalled sync is visible.
CREATE TABLE sync_state (
  source          TEXT PRIMARY KEY,              -- facebook_photos | facebook_videos | youtube
  last_success_at TEXT,
  last_error      TEXT,
  updated_at      TEXT NOT NULL
);
