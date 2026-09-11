# WPCC Mobile App - Product Requirements Document

**Prototype source of truth:** `reference/prototype-v76.html`  
**Canonical implementation viewport:** iPhone 15/16 logical viewport, **393 x 852 px**  
**Frontend:** Flutter  
**State management:** Riverpod  
**Navigation:** `MaterialApp.router` + `GoRouter`  
**Backend:** Supabase / PostgreSQL  
**Payments:** Paystack  
**Implementation target:** OpenAI Codex  
**PRD date:** 2026-09-03

---

## 1. Purpose

This PRD defines the implementation requirements for the WPCC member mobile experience represented by prototype v76. It is intentionally written for an **existing Flutter + Supabase application**. The implementation must **not assume that a missing prototype concept implies a missing production data layer**, and it must not replace existing architecture simply to make the code match this PRD.

The coding agent must always inspect the repository, Riverpod providers, GoRouter configuration, Supabase migrations/schema, repositories/services, storage buckets, Edge Functions and RLS policies before adding new structures.

### Mandatory architecture rule

> **Inspect first, reuse second, extend only when required.** If an existing table, column, view, RPC, provider, model, repository, route, storage bucket, permission abstraction or event adapter already supports a requirement, reuse it. If support does not exist, propose the smallest compatible extension. Do not rename, replace or parallel an existing data layer merely because this PRD suggests a possible schema.

---

## 2. Product goals

1. Present a coherent, modern church member experience across Home, Departments, Events, Giving, Profile, Search, Wisdom Devotional and Prayer Alerts.
2. Preserve the existing app's role and branch/department isolation rules.
3. Make department membership, events, attendance, files and lead actions easy to navigate on mobile.
4. Provide a safe Paystack-based giving flow with transaction history and receipts.
5. Reuse the existing posts/comments/reactions infrastructure for Wisdom Devotional whenever compatible.
6. Reuse existing event, attendance, announcement and academy/course data layers rather than creating duplicates.
7. Keep the interface light, simple, readable and motion-polished without distracting animation.

### Explicitly deferred

- Prayer streaks.
- Prayer highest-score calculations.
- Prayer leaderboard implementation.

The v76 prototype contains a prayer leaderboard reference screen because it existed during prototyping. Treat screenshot `40-prayer-leaderboard-deferred.png` as **historical/deferred reference only**. Do not implement leaderboard/streak backend or UI in this phase.

---

## 3. Design system and visual language

The implementation must use `reference/design-system.html` plus the v76 screenshots as visual references. When there is a conflict, use the **latest explicit rules in this PRD** and preserve established production component conventions when they already match the intent.

### 3.1 Typography

- Font: **Instrument Sans** throughout the member application.
- Card/list title: typically **14 px / 500**.
- Body/supporting text inside cards: typically **12 px / 400**.
- Tabs and choice chips: **12 px / 500**.
- Compact transaction titles: **12 px / 500**.
- Section headings such as `Files`, `Projects`, `Quick actions`: approximately **14 px / 500**.
- Large page identity can use approximately 24-30 px, weight 600-650, but avoid oversized text.
- Do not introduce serif typography.

### 3.2 Icons

- Use **Phosphor Icons** or the Flutter equivalent already used by the codebase.
- Search icons are standalone glyphs without an outer circle unless a specific component calls for a circular icon button.
- Default initials avatars use the exact visual treatment documented in `reference/design-system.html` and visible in the department screenshots.

### 3.3 Surfaces and color

- App screens use a very light white-first lavender/icy background.
- Main cards remain white or warm-neutral rather than saturated purple.
- Black remains the default selected state for tabs/choice chips.
- Purple is an accent, not the default chip/tab background.
- Bottom floating navigation is translucent/frosted/liquid-glass.
- Inner-page sticky headers may regain frosted translucency after scroll.
- Empty-state surfaces are **borderless** and use a subtle shimmer with static readable icon/text.

### 3.4 Empty-state component

Every section-level empty state should use the standard component:

- Borderless shimmer area.
- Icon remains static.
- One concise status line remains static.
- Shimmer belongs to the container, not the text.
- Avoid extra paragraphs or CTA buttons unless required by the workflow.
- Search no-result state is a special minimal variant: centered search icon + `No result found`.
- Hide section headings such as `Recent searches` when there is no content for the section.

### 3.5 Motion system

Use the motion system documented in the design reference:

- Screen forward entrance: about 210 ms, fade + roughly 10 px rise.
- Back navigation: about 190 ms, restrained reverse directional entrance.
- First 2-4 major visible surface groups may stagger by about 40 ms.
- Department tab content slides left/right based on tab direction.
- Search/filter results animate in/out when filtering.
- Bottom sheets: backdrop fade + approximately 22 px upward sheet entrance, around 220 ms.
- Popover menus: about 160 ms opacity + tiny scale/translate anchored to trigger.
- Prayer fullscreen is calmer, about 260 ms fade with minimal translation.
- Respect `MediaQuery.disableAnimations`, platform reduced-motion settings, and any existing app accessibility motion conventions.

---

## 4. Navigation model

Primary bottom navigation:

1. Home
2. Teams / Departments
3. Events
4. Give
5. Profile

Use the existing `MaterialApp.router` / `GoRouter` architecture. Do not introduce a parallel Navigator stack if the app already has established nested routes or shell routes.

### Inner navigation

- Top-level pages do not use a hamburger menu.
- Inner pages use a back button to return to their owning top-level page.
- Inner headers remain visible/sticky where specified.
- Search is a focused inner screen opened from search icons.
- Home Quick Actions may deep-link directly to a specific tab or feature screen.

---

## 5. Roles and authorization

| Role | Meaning | Required implementation scope |
|---|---|---|
| `member` | Regular church member | Standard community access; not a department worker. |
| `worker` | Member belonging to a department | Worker workflows, department participation, attendance, events, community content, own profile. |
| `dept_leader` | Department-scoped leader | Department lead actions, department events/announcements/files/profile/wallet functions where supported, member lookup within department. |
| `Directorate` | Workers directorate | Branch-scoped leadership across one or more departments. |
| `admin` | Branch administrator | Branch admin surface with configured permission presets such as membership, academy, quality control or operations. |
| `globaladmin` | Church-wide/global administrator | Cross-branch/global publishing and full super-admin permission set. |

### Authorization principles

- UI visibility is not authorization. All sensitive mutations require server-side/RLS enforcement.
- `dept_leader` lead actions are department-scoped.
- `Directorate` can have cross-department permissions inside authorized branch scope.
- `admin` actions are governed by existing branch admin presets/assignments.
- `globaladmin` may act across branches.
- Preserve existing `admin_access_assignments`, `roles`, `roletypes`, `leaders`, `global_admins` and related permission models when they already represent these rules.
- Do not create a second role system.

---

## 6. Existing Supabase tables

The known database already contains:

- `academy_instructor_assignments`
- `academy_instructors`
- `academy_module_attachments`
- `academy_modules`
- `academy_sessions`
- `access_control_audit_log`
- `access_control_verifications`
- `admin_access_assignments`
- `announcement_acknowledgements`
- `announcement_comments`
- `announcement_media`
- `announcements`
- `attendance`
- `attendance_audit_logs`
- `branch_events`
- `branch_recurring_events`
- `branches`
- `broadcast_campaigns`
- `broadcast_delivery_events`
- `broadcast_recipients`
- `churchmetric_audit_events`
- `comments`
- `communication_templates`
- `course_enrollments`
- `course_publications`
- `courses`
- `department_attachments`
- `department_requests`
- `departmental_events`
- `departmental_recurring_events`
- `departments`
- `email_rate_limits`
- `enquiries`
- `enquiry_messages`
- `evangelism_events`
- `events_legacy`
- `global_admins`
- `global_events`
- `global_recurring_events`
- `leaders`
- `leadership_titles`
- `member_deletion_authorizations`
- `member_update_verifications`
- `membership_code_sequences`
- `membershipcode`
- `notification_outbox`
- `otp_cooldowns`
- `penalties`
- `post_reactions`
- `posts`
- `profile_departments`
- `profile_key_recipients`
- `profiles`
- `profiles_priv_info`
- `profileverification`
- `provider_webhook_events`
- `quality_issues`
- `quality_queries`
- `quality_query_assignees`
- `quality_reports`
- `quality_status_history`
- `recurring_events_legacy`
- `roles`
- `roletypes`
- `soul_followups`
- `souls`
- `target_achievements`
- `target_progress_events`
- `targets`
- `worker_private_profiles`
- `worker_queries`
- `workers`

These table names are **evidence of an existing domain model, not permission to guess their columns**. Codex must inspect migrations/schema before writing queries or proposing schema changes.

---

## 7. Recommended data-layer mapping

### 7.1 Identity and membership

Prefer inspecting/reusing:

- `profiles`
- `profiles_priv_info`
- `worker_private_profiles`
- `workers`
- `profile_departments`
- `departments`
- `leaders`
- `leadership_titles`
- `roles`
- `roletypes`
- `admin_access_assignments`
- `global_admins`

The public member bottom sheet must expose only approved public fields. If phone number currently lives only in a private table protected from department peers, **do not bypass RLS**. Use an existing safe view/RPC/public-contact field if one exists; otherwise propose the smallest privacy-safe mechanism.

### 7.2 Events

Prefer existing event families:

- `departmental_events`, `departmental_recurring_events`
- `branch_events`, `branch_recurring_events`
- `global_events`, `global_recurring_events`
- legacy tables only where the current repository still depends on them

The Flutter layer should preferably expose one domain model/adaptor for displaying mixed event sources. Do not migrate all event tables into a new table unless the existing architecture already has an approved consolidation plan.

### 7.3 Attendance

Prefer:

- `attendance`
- `attendance_audit_logs`

Attendance event detail must rank **present members by earliest check-in time**, using the event's start time to calculate the visible label such as `13 min early`, `On time`, or `3 min late`.

If the current attendance table does not directly support all required event source IDs, first inspect existing event/attendance adapters. If necessary, propose a compatible view/RPC rather than destructive schema replacement.

### 7.4 Announcements

Prefer:

- `announcements`
- `announcement_media`
- `announcement_comments`
- `announcement_acknowledgements`

Department lead announcements should reuse scope/target fields already present. Only add a missing scope discriminator or relation if the current model cannot represent department targeting.

### 7.5 Department files

Prefer `department_attachments` plus the existing Supabase Storage model.

Required file visibility states:

- **Public**: department members + department leaders.
- **Private**: department leaders only.

If `department_attachments` already has a visibility/access field, use it. Otherwise propose a minimal field such as `visibility` or `leaders_only` and corresponding Storage/RLS policies. Do not trust the Flutter lock icon as access control.

### 7.6 Wisdom Devotional

Prefer:

- `posts`
- `post_reactions`
- `comments`

If the existing posts model supports categories/types/tags, represent Wisdom Devotional through that existing mechanism. Only add a devotional-specific table if the current posts domain fundamentally cannot support publication, reactions and comments.

### 7.7 Classes / academy

Prefer:

- `courses`
- `course_enrollments`
- `course_publications`
- `academy_modules`
- `academy_module_attachments`
- `academy_sessions`
- instructor tables where relevant

The profile Classes tab is primarily an enrollment/progress surface. Reuse existing course logic.

### 7.8 Queries

Prefer `worker_queries` for member/worker query submission if compatible. Inspect existing workflow before introducing new query tables. Quality-control tables should remain reserved for the quality domain unless existing code intentionally maps user queries there.

### 7.9 Souls and counselling

`Souls` has supporting tables (`souls`, `soul_followups`) but v76 does not define a full target screen. `Counselling` is also a prototype quick-action stub without a defined screen in v76.

For this implementation phase:

- Inspect whether production screens/routes already exist and connect the quick action to them if they do.
- Do not invent replacement UI solely from the Home tile.
- If no production screen exists, preserve a safe placeholder/TODO and document the gap for a future design pass.

### 7.10 Giving / Paystack - likely gap to inspect

No obvious giving-specific table names were provided. **Do not assume there are none**; inspect the schema, migrations and code first.

If a giving data layer truly does not exist, the minimum suggested model is:

- `church_bank_accounts` - bank account cards shown on Give home.
- `giving_projects` - active giving projects.
- `giving_transactions` - Paystack transaction record, user, type, amount, status, reference, provider reference, project if applicable, timestamps.
- `giving_receipts` only if generated assets must be persisted; otherwise receipts may be rendered from transaction data.
- `recurring_giving_mandates` or equivalent - explicit Auto Give consent, Paystack authorization reference/token metadata, event-day rule, amount, status, next eligible charge.

Use existing `provider_webhook_events` for idempotent Paystack webhook intake if that is its intended purpose. If it is provider-agnostic and already used, extend it rather than creating a competing webhook ledger.

**Paystack secrets must never live in Flutter.** Transaction initialization, authorization charging and webhook signature verification must occur in a Supabase Edge Function or existing secure server component.

### 7.11 Prayer Alerts - suggested model only if missing

This phase should **not implement a native OS alarm engine, prayer leaderboard or streak system**.

Required delivery model:

- Calendar-file integration plus push notifications.
- Inspect existing notification/calendar utilities first.
- If no calendar-file mechanism exists, propose an iCalendar-compatible `.ics` generation/import workflow rather than replacing existing notification infrastructure.
- Reuse `notification_outbox` and existing broadcast/notification infrastructure when appropriate.
- Global/church-managed prayer alerts must be server-authorized and publishable only by approved admin roles.
- Personal alert preferences may remain local if cross-device sync is not already part of the product; if sync is required and no table exists, propose a small `prayer_alerts` table.

Arbitrary user-selected audio cannot be assumed to play reliably as a background OS push sound. Preserve selected playlist/sound metadata for the in-app prayer session and use only supported notification sound behavior for background delivery.

---

## 8. Cross-cutting Flutter architecture requirements

### Riverpod

- Follow the existing Riverpod generation/provider style already in the repo.
- Prefer feature-scoped controllers/notifiers and repositories rather than global mutable state.
- Async states must visibly handle loading, data, empty and error.
- Avoid duplicating fetched entities across unrelated providers when the existing repository/cache already solves this.

### GoRouter

- Reuse existing route names/paths when present.
- Support deep links for Home Quick Actions (for example Profile -> Classes or Query).
- Department tabs may be local state unless the current app uses query parameters for tab deep links.
- Back navigation must return to the correct owning page.

### Supabase

- Use typed models/converters consistent with the codebase.
- Prefer repository abstractions already used by the app.
- Never use service-role credentials on device.
- RLS is mandatory for user-facing tables.
- Every mutation must preserve branch/department scope.

### Storage

- Inspect existing buckets before creating a new one.
- Department file access must mirror database visibility.
- Devotional/announcement media should reuse existing storage strategy.

---

## 9. Detailed screen requirements

### 9.1 Home

References: `01-home.png`.

- Header shows church/branch identity and member name; standalone search icon on the right.
- Upcoming-event hero occupies the full available card width respecting page padding.
- If no event is available, show the standard shimmering event card with visible `No upcoming events` text.
- Quick Actions: **8 Actions** in a 4 x 2 grid:
  1. Prayer alerts
  2. Wisdom Devotional
  3. Events
  4. Department
  5. Souls
  6. Classes
  7. Counselling
  8. Query
- Announcements section lists current announcements and supports `View all` if existing functionality is present.
- Classes quick action deep-links to Profile -> Classes.
- Query quick action deep-links to Profile -> Query.
- Souls/Counselling must use existing routes if present; otherwise do not invent screens.

### 9.2 Departments list

Reference: `02-departments-list.png`.

- Tabs: All, My Teams, Leading, 12 px labels and black selected state.
- Department list card uses compact 8 px padding.
- Card shows logo, department name, compact membership/primary context and primary badge.
- Tapping department opens Department Detail.

### 9.3 Department Detail

References: `03` through `15`.

- Full-bleed image hero extends edge-to-edge and to the top.
- Image has dark gradient overlay for readable title/description.
- Header initially floats over hero; on vertical scroll it becomes full-width frosted glass.
- Header actions: back + department lead-only options (`...`). No chat icon.
- Lead menu opens only when tapped; tapping outside dismisses.
- Lead menu order:
  1. Post announcement
  2. Create event
  3. Manage files
  4. Change profile
  5. New wallet
- No destructive action.
- Tabs: Overview, Members, Attendance, Files. Tab content slides directionally left/right.

**Overview**
- Horizontal leadership profiles; no outer card.
- Initials/avatar, name, position under avatar.
- Only the leadership rail horizontally scrolls; the screen itself must never horizontally overflow.
- Department wallet uses standard borderless shimmer empty state if unavailable.
- Attendance ranking overview list has no numeric rank circles.

**Members**
- Search icon expands to search field.
- Filter popover fits readable width and dismisses outside.
- Filtered rows animate in/out.
- Member list does not show event-count number on the right.
- Tapping member opens animated public-profile bottom sheet containing:
  - profile image or initials
  - full name
  - phone number
  - list of all departments
- Tapping the profile image/initials opens a full-screen expandable viewer.
- Only approved public data may be fetched.

**Attendance**
- Show a list of department events first, not a flat all-time member ranking.
- Search and filter operate on events.
- Tapping an event opens a bottom sheet of present members.
- Present members are ordered by earliest check-in timestamp.
- Show each check-in time plus relative-to-start label (`early`, `On time`, `late`).

**Files**
- 2-column thumbnail grid, not a list.
- Search expands from small icon.
- Filter supports file categories.
- Empty search/filter uses standard shimmer state.
- Public/member-facing Files tab only returns files the current viewer is authorized to see.

### 9.4 Department lead pages

References: `16`-`20`.

**New wallet**
- Lead-only.
- Create department wallet/account profile if business permissions allow.
- Inspect whether existing bank/account data layer exists before adding tables.

**Change profile**
- Update cover image, department identity assets and description.
- Reuse department update policies and storage.

**Create event**
- Department-scoped event creation.
- Use `departmental_events` / `departmental_recurring_events` where compatible.

**Post announcement**
- Department-scoped announcement creation.
- Reuse announcements/media system.

**Manage files**
- Thumbnail grid.
- Upload button.
- Each file has a top-right access icon:
  - black unlocked = public to members + leaders
  - red locked = department leaders only
- Each file has Remove File action.
- No top-right `Done` button.
- File access changes must persist to backend policy/data, not only icon state.

### 9.5 Events

Reference: `21-events-list.png`.

- Categories/chips use 12 px text, black selected state.
- Ongoing-service section uses standard borderless shimmer empty state when none.
- Recurring/upcoming events are compact cards.
- Tapping event opens Event Detail.

### 9.6 Event Detail

References: `22-event-detail-overview.png`, `23-event-detail-attendance.png`.

- Full-bleed visual hero and sticky/frosted inner header behavior.
- Tabs: Overview and Attendance.
- Overview includes event description, date, time, location, current user's check-in/out, host/organizer and directions.
- If location unavailable: standard borderless shimmer direction area and disabled/unavailable action.
- Attendance tab shows present/attendance data according to viewer permission.
- Event source may be department/branch/global; do not hardcode one table.

### 9.7 Give Home

Reference: `24-give-home.png`.

- Header includes History action.
- Horizontal church account rail with copy-account action.
- Account cards preserve dark / white / warm-neutral palette.
- Quick actions: Offering, Tithe, Prophet offering, Auto give in a 4-column grid styled like Home Quick Actions.
- Projects replace recent transactions on Give Home: two project cards per row.
- History button opens dedicated Giving History.

### 9.8 Giving Payment / Auto Give

References: `25-give-payment.png`, `26-auto-give.png`.

- Amount entry uses numeric keypad.
- Payment method/source is explicit.
- Standard flows: Offering, Tithe, Prophet Offering, project contribution if invoked from project card.
- Paystack initialization must occur server-side.
- Auto Give allows user to select event-day recurrence rules and amount.
- Auto Give requires explicit consent and must be cancelable/manageable in the production data model.
- Reuse Paystack reusable authorization only through secure backend logic.

### 9.9 Give Success / History / Invoice

References: `27`, `28`, `29`.

- Success page shows status, amount, type, reference and payment source.
- History is a separate page.
- Transaction row title is compact 12 px.
- Clicking history item opens invoice bottom sheet.
- Invoice provides Download PDF and Download Image actions.
- Generated receipt must be derived from trusted transaction data; do not trust amount/reference supplied only from client state.

### 9.10 Profile

References: `30`-`33`.

**Overview**
- Initials avatar uses design-system gradient; photo may replace it.
- Profile identity, status, tags and personal details.
- No extra four-stat summary card.
- Editable fields must follow existing member update verification workflows where required.

**Classes**
- Enrollment metrics + class state.
- Empty state uses standard shimmer.
- Reuse course/academy data.

**Query**
- Query form and submission.
- Prefer `worker_queries` if compatible.

### 9.11 Search

References: `34`, `35`, `36`.

- Minimal back + search field.
- Recent searches are dismissible pills, horizontal/wrapping.
- If no recent search terms remain, hide the heading entirely.
- Results follow compact thumbnail/title/metadata/description rows.
- No-result state only shows centered search icon and `No result found`.
- Recent searches are device/local preference data; no server table is required unless existing cross-device sync already exists.
- Results may deep-link into Give, Events, Departments and Profile tabs.

### 9.12 Wisdom Devotional

References: `37`, `38`.

- Feed of devotional posts.
- Single post view.
- Reactions and comments at end of post.
- Prefer `posts`, `post_reactions`, `comments`.
- Publishing permissions should use existing admin/content roles; do not let ordinary members publish unless already supported by product rules.

### 9.13 Prayer Alerts

References: `39`, `41`, `42`, `43`. `40` is deferred.

- Home Quick Action opens Prayer Alerts.
- Church/global alerts are admin-managed/read-only for ordinary users.
- Personal alerts can be created/edited by user.
- Recurrence/day selection and optional duration.
- **Delivery approach for this phase:** calendar-file integration + push notifications.
- Inspect existing push/notification/calendar implementation first.
- If calendar-file support is missing, propose `.ics` generation/import.
- Do not implement prayer leaderboard, streak or score logic.

**Prayer session fullscreen**
- Back button top-left.
- Prayer title.
- Timer.
- If duration configured: countdown and circular progress.
- If no duration: count upward; circular countdown progress is omitted/non-progress mode.
- Playlist area has its own internal scroll and fades near bottom; page itself should not scroll because of playlist.
- Each song card only needs play/pause control.
- No stats/streak/score widgets.

---

## 10. Giving / Paystack security requirements

1. Flutter requests transaction initialization from a secure Supabase Edge Function/existing backend endpoint.
2. Server generates Paystack reference and sends secret-key request.
3. Flutter launches Paystack checkout using public-safe initialization response.
4. Server verifies webhook signature and records provider event idempotently.
5. Transaction state is updated from verified backend/provider data.
6. Client may poll/refetch after callback but cannot mark its own payment successful.
7. Auto Give requires stored Paystack authorization metadata, explicit consent and a server-side charging process.
8. Avoid storing raw card PAN/CVV.
9. Use integer minor units or a consistent numeric strategy already established by the backend; do not use floating point for money.

---

## 11. Notifications and calendar files

- Reuse `notification_outbox`, broadcast infrastructure and any existing push provider integration.
- Prayer personal reminders may generate/import a calendar file and optionally schedule push reminders.
- Global prayer alerts should be issued only by authorized admin roles and sent through existing notification infrastructure.
- Event reminders may reuse the same notification pipeline if already supported.
- Calendar-file creation should carry title, start time, recurrence where supported, timezone and useful description/deep link.

---

## 12. RLS and privacy checklist

Before shipping each feature:

- Verify member can only mutate own profile/preferences where intended.
- Verify worker/department queries are limited to authorized department scope.
- Verify department leads cannot mutate other departments.
- Verify Directorate is branch-scoped.
- Verify admin permissions honor existing presets/assignments.
- Verify globaladmin cross-branch behavior is explicit.
- Verify private department files cannot be fetched through signed/public URLs by workers.
- Verify public member sheet cannot leak private-profile-only fields.
- Verify giving transaction rows are visible only to owning user and authorized finance/admin surfaces.
- Verify Paystack webhook endpoint is not exposed with service credentials to client.

---

## 13. Loading, empty, error and offline behavior

Every network-backed page should define:

- Initial loading: skeleton/shimmer matching final layout.
- Empty: standard component where applicable.
- Error: concise inline retry state without losing navigation.
- Refresh: use existing refresh convention.
- Mutation pending: disable duplicate submissions.
- Optimistic updates only where rollback is safe (for example local visibility toggle may visually update, but must revert if backend rejects).

---

## 14. Performance

- Paginate potentially unbounded announcements, events, posts, comments, files and history.
- Avoid loading full profile/private records for member list rows.
- Use thumbnail transformations for media where supported.
- Cache stable lookup data (departments, leadership titles) using current repository conventions.
- Search must debounce server requests if server-backed.
- Avoid N+1 Supabase calls for member departments; use joins/views/RPC compatible with current schema.

---

## 15. Accessibility

- Minimum practical touch target about 44 logical px for primary controls.
- Screen-reader labels for icon-only controls.
- Selected tabs expose selected state.
- Bottom sheets are focus-contained where platform conventions require.
- Do not rely only on lock color; include semantic tooltip/label (`Public`, `Leads only`).
- Respect text scaling where possible without clipping.
- Reduced motion support.

---

## 16. Testing strategy

### Flutter tests

- Widget tests for major empty/loading/data states.
- Provider/controller unit tests.
- GoRouter deep-link tests for Quick Actions.
- Golden tests may use the screenshot references at 393 x 852 where useful, allowing for platform font rendering differences.

### Supabase/backend tests

- RLS role matrix tests.
- Paystack webhook idempotency/signature tests.
- Department file privacy tests.
- Attendance ordering and relative-time calculation tests.
- Announcement/event scope tests.

### End-to-end critical paths

1. Home -> Department -> Members -> member public sheet.
2. Department -> Attendance -> event -> time-ranked attendees.
3. Dept leader -> actions -> post announcement/create event/manage file visibility.
4. Events -> detail -> attendance.
5. Give -> Offering -> Paystack -> success -> history -> invoice.
6. Give -> Auto Give consent/schedule creation.
7. Home -> Search -> deep link.
8. Home -> Wisdom Devotional -> post -> reaction/comment.
9. Home -> Prayer Alerts -> create reminder -> calendar/push path -> prayer session.
10. Profile -> Classes / Query.

---

## 17. Recommended implementation order

1. Audit current repository/data layer and create a mapping document - no code changes yet.
2. Integrate design tokens/components and motion system with existing theme.
3. Home + navigation/deep links.
4. Departments + tabs + public member sheet + attendance event flow + files.
5. Department lead actions.
6. Events + event detail.
7. Giving + Paystack secure backend + history/receipt.
8. Profile Classes/Query integration.
9. Search.
10. Wisdom Devotional.
11. Prayer Alerts using calendar-file + push approach; exclude leaderboard/streak.
12. RLS/security regression and visual polish.

---

## 18. Definition of done

A page is not complete merely because it visually resembles the prototype. It is complete only when:

- The route/navigation works in the existing GoRouter structure.
- Riverpod state follows existing architecture.
- Correct existing backend data is used, or the smallest approved extension is added when missing.
- RLS/permission behavior is correct.
- Loading/empty/error states are implemented.
- Motion and typography match the design system.
- The page is responsive at 393 x 852 and does not horizontally overflow.
- Relevant screenshot reference has been visually compared.
- Tests cover the critical state/logic.
- No unrelated architecture has been refactored without need.
