# WPCC Community

Greenfield Flutter web/PWA implementation built against the existing WPCC Community Supabase project.

## Runtime configuration

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://api.wisdompowercc.org \
  --dart-define=SUPABASE_PUBLISHABLE_KEY=<publishable-key> \
  --dart-define=APP_ORIGIN=http://localhost:3000 \
  --dart-define=VAPID_PUBLIC_KEY=<web-push-public-key>
```

Authoritative timestamps are generated server-side. Flutter sends scheduling preferences and user intent, never check-in/session/delivery timestamps.

## Required deployment configuration

The Flutter web build uses `--dart-define` for public runtime values:

- `APP_ORIGIN=https://<production-domain>`
- `VAPID_PUBLIC_KEY=<public-vapid-key>`

Supabase Edge Function secrets required for prayer Web Push:

- `PRAYER_DISPATCH_SECRET`
- `VAPID_SUBJECT` (normally the production HTTPS origin or an approved `mailto:` contact)
- `VAPID_PUBLIC_KEY`
- `VAPID_PRIVATE_KEY`

`dispatch-prayer-alerts` is deployed but intentionally returns HTTP 503 until those secrets are configured. No private VAPID material is stored in Flutter or in this repository.

### Server-authoritative time

Flutter must not write authoritative timestamps. Prayer session start/end, prayer occurrence scheduling/delivery, attendance check-in, attendance clock-out and audit timestamps are generated in PostgreSQL/Edge infrastructure. Local timers are display-only and periodically resynchronise against database-derived elapsed time.

## Giving / Paystack deployment secrets

The Paystack Edge Functions require server-only configuration:

- `PAYSTACK_SECRET_KEY`
- `WPCC_APP_ORIGIN=https://<production-domain>` for the Paystack callback URL
- `WPCC_GIVING_WORKER_SECRET` for the scheduled Auto Give worker

Do not expose these values through Flutter `--dart-define` or commit them to the repository.

The public Flutter build uses `APP_ORIGIN`; the server-side Paystack function uses the separate `WPCC_APP_ORIGIN` Edge secret.

## Implementation reference

The approved v76 implementation package is copied under `docs/wpcc-v76/`. See `IMPLEMENTATION_STATUS.md` for a page-by-page implementation map and the two intentionally unresolved target-page design gaps (Souls and Counselling).


## Rewards worker

`cloudflare/rewards` owns the minute cron, queue consumer and prayer participation timing.
The app never triggers award processing. Verified source changes transactionally enqueue
`rewards_private.events`; the cron claims up to 100 events with five-minute leases and
sends them to Cloudflare Queues. A crash before sending is recovered by lease expiry.
Consumers settle batches through the HMAC-authenticated `rewards-worker` Edge Function.
Only a successful database transaction acknowledges a queue delivery. Stale leases and
duplicate deliveries cannot add points. After retry exhaustion, events remain failed for
administrative retry rather than disappearing.

Awards: attendance checkout 30 WP per event; official global prayer 30 WP per occurrence;
successful giving 30 WP per Africa/Lagos date regardless of amount; complete profile 15 WP
once per lifetime. No historical activity backfill. Giving refunds/disputes exclude the
reversed payment and recompute the day's entitlement. Another valid payment on that date
retains the single award. Attendance corrections recompute the event entitlement.

The append-only private ledger is authoritative. Private balances are transactionally
maintained totals, and `profiles.points_balance` is a server-owned display copy. Members
cannot write either balance through table updates; only their own history is available
through `rewards_my_summary`. `rewards_public_totals` exposes totals (no history) to signed-in
members. Reward settlement serializes short database transactions and updates each public
balance once per batch; it does not remove all database work.

Prayer uses a per-member/per-occurrence Durable Object. The server issues five-minute
participation tickets for an active session in an official scheduled occurrence. Heartbeats
use Cloudflare time, cap qualification at half the scheduled duration or 600 seconds, and
exclude gaps over 90 seconds. Two devices share the same counter. Browser timers and client
point values are never accepted as authoritative. This verifies connected participation,
not a person's physical attention or prayer.

Deployment requires the same random `WPCC_REWARDS_WORKER_SECRET` in Cloudflare Secrets and
Supabase function environment, plus `WPCC_REWARDS_WORKER_URL` on Supabase. Never ship these
secrets to Flutter. The self-hosted function gateway delegates authentication for this
specific route to its HMAC/user-JWT handler. Main and failed queues are `wpcc-rewards` and
`wpcc-rewards-failed`. Production origin is `https://my.wisdompowercc.org`.

Apply the rewards migration, deploy the Edge Function and worker, verify signed requests,
then enable rewards. No app role, including global admin, can withhold, restore, manually
adjust or pause rewards. Only the automatic verified-source rules determine entitlement.
Historical review records are retained for audit but never consulted by the award rules.
Refunds and invalid-activity corrections still produce automatic compensating entries.
Failed events remain durable for backend operational recovery; retrying cannot duplicate
an award. Hourly reconciliation checks 100 private balances against the ledger and repairs
their public display copies. Never edit ledger rows to correct a balance.


Validation: `npm ci && npm run check && npm test` in `cloudflare/rewards`.
`supabase/tests/rewards_worker.sql` exercises lease recovery, stale/duplicate delivery,
daily giving caps, reversals and member permission guards inside a rollback transaction.
The private tables intentionally have RLS with no browser policies; authenticated definer
RPCs intentionally enforce self-access checks and fixed output shapes.
