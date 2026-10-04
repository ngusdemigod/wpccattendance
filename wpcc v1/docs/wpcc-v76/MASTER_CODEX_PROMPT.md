# MASTER CODEX IMPLEMENTATION PROMPT - WPCC MOBILE v76

You are implementing a production Flutter feature set in an **existing** WPCC repository. Do not treat this as a greenfield build.

## Read these references before changing code

1. `PRD/WPCC_APP_PRD.md`
2. `reference/database-architecture.md`
3. `reference/screen-inventory.md`
4. `reference/design-system.html`
5. `reference/design-system-addendum.md`
6. `reference/prototype-v76.html`
7. The page-specific prompt I give you from `prompts/pages/`.
8. Every screenshot cited by that page-specific prompt.

## Fixed technical context

- Flutter.
- Riverpod.
- `MaterialApp.router` with `GoRouter`.
- Supabase/PostgreSQL.
- Paystack for payments.
- Canonical visual viewport: iPhone 15/16 logical viewport, 393 x 852.

## Non-negotiable operating rule

**Inspect first, reuse second, extend only when required.**

Before implementing the page:

1. Inspect existing GoRouter routes and shell/nested navigation.
2. Inspect existing Riverpod providers/notifiers/controllers.
3. Inspect models, repositories, services and Supabase client wrappers.
4. Inspect SQL migrations/schema, RLS, views, RPCs, Edge Functions and Storage buckets relevant to the feature.
5. Map the requested behavior onto what already exists.
6. Only if a required capability genuinely does not exist, propose the smallest compatible addition.

Do **not**:

- replace existing repositories because you prefer another pattern;
- create duplicate tables for domains already modeled;
- rename or consolidate event tables as a side project;
- bypass RLS;
- put service-role or Paystack secret credentials in Flutter;
- refactor unrelated features;
- invent unsupported fields or relationships without inspecting schema;
- implement prayer leaderboard, streak or score functionality in this phase.

## Required pre-implementation response

Before editing files, return a short implementation audit containing:

- Existing route(s) you will reuse/change.
- Existing provider/controller/repository you will reuse/change.
- Existing Supabase table/view/RPC/Edge Function/storage bucket you found relevant.
- Any missing capability.
- If a database change is required, the minimal suggested change and why existing structures cannot support it.
- Files you intend to touch.

Then proceed unless the proposed change is destructive or materially changes existing architecture. If it is destructive/material, stop and ask for approval.

## Design implementation rules

- Instrument Sans.
- Phosphor icon family / current Flutter equivalent.
- Card titles ~14 px/500; card body/support ~12 px; tabs/chips 12 px/500.
- Tabs/chips use black selected backgrounds, not purple.
- App background is white-first with restrained lavender/icy atmosphere.
- Default cards remain white/warm-neutral.
- Floating bottom nav uses frosted/liquid-glass treatment.
- Inner sticky headers become frosted after scroll where shown.
- Search icon normally has no outer circle.
- Initials avatars must match the exact design-system gradient.
- Section empty states are borderless shimmer surfaces; text/icon do not shimmer.
- Prevent screen-level horizontal overflow. Only explicit rails/grids may horizontally scroll.
- Apply the documented motion system, including directional Department tab transitions and reduced-motion support.

## Roles

Use the existing role model; do not create another role system:

- `member`
- `worker`
- `dept_leader`
- `Directorate`
- `admin`
- `globaladmin`

Authorization must exist in RLS/server logic, not only conditional widgets.

## Data principles

Known relevant domains already exist for profiles, departments, workers/leaders, announcements, attendance, event families, posts/comments/reactions, courses/academy, worker queries, notifications and souls. Inspect them before proposing schema.

Giving tables were not visible in the supplied table-name inventory; inspect the full project before concluding they are absent. If they really are absent, follow the minimal suggestions in `reference/database-architecture.md`.

## Paystack

- Secret operations are server-side only.
- Initialize transactions through existing secure backend/Edge Function or create the smallest compatible Edge Function if missing.
- Verify Paystack webhooks server-side and idempotently.
- Prefer existing `provider_webhook_events` if it is intended for provider webhooks.
- Never let Flutter mark a transaction successful by itself.

## Prayer Alerts scope

For this phase:

- use the existing calendar-file mechanism if present;
- otherwise propose iCalendar `.ics` as the fallback calendar-file implementation;
- use the existing push notification infrastructure / `notification_outbox` when compatible;
- no leaderboard;
- no streak;
- no highest-score logic;
- timer can count down when duration is set and count up when no duration is set.

## Quality gate for every page

Do not declare done until:

- visual hierarchy is compared with cited screenshots;
- 393 x 852 has no unintended horizontal overflow;
- loading/empty/error states exist;
- permissions are enforced;
- state survives normal rebuild/navigation correctly;
- the page uses existing data rather than static demo data;
- relevant unit/widget tests are added or updated;
- analyzer/tests for touched scope pass;
- you summarize changed files and any proposed/made backend changes.

## Page execution

Implement **only the page-specific prompt provided for the current task** and its directly required reusable components. Do not jump ahead to other pages. Page prompts are intentionally separable so the codebase can be implemented/reviewed incrementally.
