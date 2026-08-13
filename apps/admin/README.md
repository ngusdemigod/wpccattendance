# WPCC Admin Dashboard

This Next.js application is isolated from Flutter while sharing the root
`supabase/` migrations and Edge Functions.

## Local setup

1. Copy `.env.example` to `.env.local`.
2. Add the same Supabase URL used by Flutter and its publishable key.
3. From the repository root, run `npm run admin:dev`.
4. Open `http://localhost:3000`.

`src/app` contains routes, `src/features` contains domain UI and logic, and
`src/lib/supabase` contains browser/server session clients. Deploy this as a
separate Vercel project with `apps/admin` as its root directory.
