-- The catalog now only keeps a small window of the newest items per source
-- (see MAX_PHOTOS / MAX_VIDEOS), and anything outside the window is deleted.
-- The full-pass bookkeeping column is no longer needed.

ALTER TABLE photos DROP COLUMN last_seen_run;
ALTER TABLE videos DROP COLUMN last_seen_run;
