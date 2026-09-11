# Page Prompt 10 - Event Detail

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/22-event-detail-overview.png`
- `../../screenshots/23-event-detail-attendance.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement Event Detail with full-bleed hero, sticky/frosted inner header, Overview/Attendance tabs, event facts, current-user check-in/out, host and directions. Attendance tab should use existing permissions. Location unavailable uses standard shimmer state.

## Existing / suggested data layer

Event can originate from department/branch/global tables. Reuse source-aware repository. Use `attendance` for user/check-in data. Do not hardcode table assumptions into the widget.

## Permissions

Overview visible to eligible attendees. Attendance roster visibility follows existing role rules.

## Page-specific acceptance criteria

Correct event timezone, clean no-location behavior, tabs switch smoothly, attendance state loads without N+1 queries.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
