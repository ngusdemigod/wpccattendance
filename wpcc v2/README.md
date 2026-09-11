# WPCC Community

Greenfield Flutter web/PWA implementation built against the existing WPCC Community Supabase project.

## Runtime configuration

```bash
flutter run -d chrome \
  --dart-define=SUPABASE_URL=https://pgpihzhvysbadrzjhvxw.supabase.co \
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
