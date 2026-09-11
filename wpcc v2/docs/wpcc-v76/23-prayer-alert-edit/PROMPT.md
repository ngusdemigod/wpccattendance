# Page Prompt 23 - Prayer Alert create/edit

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/41-prayer-alert-edit.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement create/edit reminder fields: time, label, repeat days, optional duration, sound/playlist metadata and supported vibration/snooze preference. The actual phase uses calendar-file + push notifications rather than building a native alarm engine.

## Existing / suggested data layer

Inspect current calendar/push abstraction. Persist only data needed by current strategy. If `.ics` fallback is used, generate timezone-aware recurrence/event data.

## Permissions

User edits own reminder. Global reminder editor belongs to existing admin surface and is not created here unless already designed.

## Page-specific acceptance criteria

Optional duration empty => prayer session count-up. Duration present => countdown. Save validates time/repeat and creates/updates calendar/push schedule.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
