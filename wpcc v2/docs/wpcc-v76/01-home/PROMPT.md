# Page Prompt 01 - Home

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/01-home.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement/refine the Home page exactly around the v76 hierarchy: member/church identity, standalone search action, upcoming event hero/empty state, 8 Quick Actions, announcements and persistent bottom navigation. Quick Actions must deep-link to existing pages where available. Classes -> Profile Classes; Query -> Profile Query. Souls and Counselling must route to existing production screens if they exist; otherwise keep a non-destructive placeholder and report the missing design/route rather than inventing a page.

## Existing / suggested data layer

Prefer existing `profiles`, `branches`, event repositories and `announcements`. Upcoming event aggregation should reuse current event source logic. Do not create a home-specific cache table.

## Permissions

Member/worker normal access. Announcement visibility follows current scope/RLS.

## Page-specific acceptance criteria

No horizontal overflow; 4x2 actions; shimmer upcoming-event empty state; Recent/empty headings are not rendered when irrelevant; search action opens Search.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
