# wpcc-media-sync

Everything for the Media page's **Videos** and **Gallery** runs on this one Cloudflare Worker, with no Supabase changes:

- **Sync** (cron + queue): pulls the church's Facebook page photos and videos and its YouTube channel, and stores the catalog in **D1** (`wpcc-media`).
- **Image mirroring** (queue + R2): copies Facebook images into the public R2 bucket `wpcc` (served at `https://storage.wisdompowercc.org`) as **two compressed WebP files**, `w1600.webp` (quality 80) and `w480.webp` (quality 75), under `media-sync/fb/<photo|video>-<id>/`. The original is not kept. Facebook image URLs expire, so nothing hotlinks them. Source images over **3 MB** are refused.
- **Small on purpose:** only the newest items are kept (`MAX_PHOTOS`, `MAX_VIDEOS` in `wrangler.jsonc`, 50 each by default). Everything older is deleted from D1 and R2, and no history is imported. Videos are links and metadata only: nothing is downloaded, and playback streams from YouTube or Facebook.
- **Public read API** on `https://media-api.wisdompowercc.org` that the Flutter app calls.

The data is public content, so the API has no login. It is protected by rate limiting, an Origin allow-list, strict parameters and an edge cache (below).

## How it runs

| Piece | What it does |
|---|---|
| Cron `*/30 * * * *` | Only enqueues three **sync tasks** (Facebook photos, Facebook videos, YouTube). Each task fetches its newest window in one request. The 02:00 UTC (03:00 Lagos) run also retries images that failed to copy. A single cron keeps the account within the 5 cron limit of the free Workers plan. |
| Queue `wpcc-media` | One message per invocation. A sync task makes many outbound requests, so it gets its own request budget (free plan: 50 per invocation). Image copy jobs use the same queue. Failures retry with backoff (60 s up to 15 min, 4 retries). |
| Queue `wpcc-media-failed` | Dead letters. Marks the image `failed` in D1; the 02:00 UTC run retries it. |
| D1 `wpcc-media` | Tables `photos`, `videos`, `sync_state` (`migrations/`). Writes are conditional, so an unchanged item writes nothing (free plan: 100,000 row writes per day). |

After every run, anything the source did not just return, whether older than the window or deleted at the source, is deleted from D1 and its R2 files are removed. Queued image copies for removed items are dropped. The cleanup is skipped when the source returned less than half of what we hold, so one odd response cannot empty the catalog.

## The public API

```
GET /v1/gallery?limit=40&before=<published_at>|<id>   Facebook photos, newest first (only mirrored ones)
GET /v1/videos?limit=50&before=<published_at>|<id>    YouTube and Facebook videos and livestreams, each with
                                                       format (standard | short | portrait) and live_now (0 | 1)
GET /v1/photos/<id>/file                               the stored photo as a download (attachment, CORS for the app)
GET /v1/status                                        last successful sync per source (for monitoring)
```

Responses are `{ "items": [...], "next": "<cursor>" | null }`. Defence in depth, in order:

1. Only `GET` and `OPTIONS`, only these three paths.
2. **Origin allow-list** (`ALLOWED_ORIGINS`): data routes answer 403 to requests from other origins or with no Origin at all (curl, scripts, crawlers). This is friction, not security: an Origin header can be forged.
3. **Rate limit (soft)**: 120 requests per minute per IP through the Workers rate limiter, before any D1 work; over the limit gets `429` with `Retry-After`. Cloudflare documents this limiter as approximate and per location, and a burst of 600 parallel requests in testing was **not** stopped, so treat it as a soft layer. The sturdy limit is the zone rule below.
4. **Strict parameters**: only `limit` (1 to 50) and `before`; anything else is ignored and cannot create new queries. All queries use partial indexes.
5. **Edge cache**: identical reads are served from Cloudflare's cache for 2 minutes and never reach D1. The cache key is normalised, so extra or reordered query parameters cannot bust it.
6. Generic error bodies (no internals), `nosniff`, `no-referrer`.

## Zone rules to add (dashboard, Security > WAF)

The deploy token has no firewall permission, so these are created by hand (or add the *Zone WAF: Edit* permission and ask for them to be applied). Both target only the media API host, so nothing else on `wisdompowercc.org` is affected.

1. **Rate limiting rule** (the free plan allows one). Expression: `http.host eq "media-api.wisdompowercc.org"`. Count requests per IP, **40 per 10 seconds**, action **Block** for 10 seconds.
2. **Custom rule** (blocks scripts before the Worker runs, saving Workers request quota). Action **Block** when:

   ```
   http.host eq "media-api.wisdompowercc.org"
   and http.request.uri.path ne "/v1/status"
   and not any(http.request.headers["origin"][*] in {"https://my.wisdompowercc.org" "http://localhost:8801" "http://127.0.0.1:8801"})
   ```

**Not enabled on purpose:** Cloudflare *Bot Fight Mode*. It is a zone-wide switch that cannot be skipped per path, so it would also hit `api.wisdompowercc.org` and the payment webhooks on the same zone. If more protection is needed, add a **zone rate-limiting rule** (the free plan allows one) scoped to the host `media-api.wisdompowercc.org`.

## Credentials

This Worker has no `.env`. All Cloudflare credentials live in the shared `../.env` and every script passes `--env-file ../.env`. `npm run deploy` runs `../scripts/assert-account.mjs` first and refuses to deploy unless the token works on the pinned `account_id`.

## First-time setup (already done for D1, queues and the Worker)

```bash
npx wrangler d1 create wpcc-media --env-file ../.env
npx wrangler d1 migrations apply wpcc-media --remote --env-file ../.env
npx wrangler queues create wpcc-media --env-file ../.env
npx wrangler queues create wpcc-media-failed --env-file ../.env
npm run deploy
```

## To start syncing (needs your values)

1. Edit `wrangler.jsonc` `vars`: `FACEBOOK_PAGE_ID` (numeric Page id), `YOUTUBE_CHANNEL_ID` (starts with `UC`), and check `FACEBOOK_GRAPH_VERSION` against Meta's current version.
2. Set the two secrets (the value is read from your keyboard, never stored in a file):
   ```bash
   npx wrangler secret put FACEBOOK_PAGE_ACCESS_TOKEN --env-file ../.env
   npx wrangler secret put YOUTUBE_API_KEY --env-file ../.env
   ```
   The Facebook token needs access to the Page's photos and videos. Until both are set, each source records `not configured` in `sync_state` (see `/v1/status`) and nothing else breaks.
3. `npm run deploy`, then watch `/v1/status` after the next half hour.

## Monitoring

- Workers Logs are on: look for `media_sync_run`, `media_sync_failed`, `media_mirror_*` and `media_api_*` events.
- `GET /v1/status`: `last_success_at` per source should never be older than about an hour. Alert if it is.
- Check the `wpcc-media-failed` queue if photos stay `failed`.

## Development

```bash
npm test          # vitest; D1 is a real SQLite database (node:sqlite), no Cloudflare account needed
npm run check     # tsc --noEmit
```

## Shorts, portrait videos and "live now"

Each video row carries two fields the app uses to lay out the Media page:

- `format`: `short` (a YouTube Short, a Facebook Reel, or a portrait clip of 3 minutes or less), `portrait` (taller than wide but longer than that) or `standard`. The app shows `short` and `portrait` in a vertical shelf and opens them in a full-screen swipe viewer. A livestream is never a short.
- `live_now`: `1` while a livestream is on air. The app shows it as a LIVE circle; when nothing is on air it shows the latest ended livestream instead.

How they are worked out:

- **Facebook**: the Graph `format` field gives the frame size of each encoding (the largest decides), and a `/reel/` link is a short. If Facebook refuses the `format` field for the token, the sync retries without it and videos count as landscape unless their link says Reel.
- **YouTube**: the API does not expose the frame size. A video of 3 minutes or less that is not a livestream is a candidate, and the sync asks `https://www.youtube.com/shorts/<id>` without following redirects (200 = Short, redirect = ordinary video). If that request fails, a clip of about a minute or less counts as a short. At most 20 candidates are checked per run, inside the 50 subrequest budget.

`live_now` is only as fresh as the sync: up to 30 minutes after a stream starts or ends, plus the 2 minute edge cache. The migration is `migrations/0003_video_format.sql`; run `npm run deploy` after applying it to the remote database.

## Photo downloads

The image host sends no CORS headers, so a browser app cannot fetch the bytes from it to save them. `GET /v1/photos/<id>/file` serves the stored 1600px WebP with `Content-Disposition: attachment`, under the same Origin allow-list and rate limit as the other routes. The original is not stored, so this is the compressed copy.
