-- Lets the app show short-form and portrait videos in their own vertical
-- shelf (like YouTube Shorts) and highlight a livestream that is on air now.
--
--   format    'short' = Short or Reel, 'portrait' = taller than wide but long,
--             'standard' = ordinary landscape video
--   live_now  1 while a livestream is on air, 0 once it has ended

ALTER TABLE videos ADD COLUMN format TEXT NOT NULL DEFAULT 'standard' CHECK (format IN ('standard', 'short', 'portrait'));
ALTER TABLE videos ADD COLUMN live_now INTEGER NOT NULL DEFAULT 0;
