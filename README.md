# attendamce

A new Flutter project.

## Getting Started

FlutterFlow projects are built to run on the Flutter _stable_ release.

## Docs

- [Google OAuth linking](/C:/Users/USER/Documents/dev/wpcc community/attendamce/attendamce/docs/google-oauth-linking.md)

## R2 Edge Function Env

Set the local Cloudflare R2 credentials in the root `.env.local`.

Required variables:
- `R2_ACCOUNT_ID`
- `R2_ACCESS_KEY_ID`
- `R2_SECRET_ACCESS_KEY`
- `R2_BUCKET_NAME=wpcc`
- `R2_PUBLIC_URL`

Run the local Edge Functions runtime with:

```bash
npm run serve:functions:r2
```

For the Windows local auth/profile runtime, use:

```bash
npm run serve:function:otp
```

This starts the local Supabase runtime and serves the auth and R2-related
functions needed by login, OTP verification, profile completion, and avatar
updates. It maps reserved `SUPABASE_*` variables from the single root
`.env.local` into a minimal temporary env file that the Functions runtime
accepts.
