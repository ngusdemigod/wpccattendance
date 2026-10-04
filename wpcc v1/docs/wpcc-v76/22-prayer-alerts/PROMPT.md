# Page Prompt 22 - Prayer Alerts

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/39-prayer-alerts.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement Prayer Alerts list for global church reminders and personal reminders. Global alerts are read-only for ordinary users. Personal alerts can be created/edited. The prototype leaderboard is DEFERRED and must not be implemented in this phase.

## Existing / suggested data layer

Inspect existing calendar and notification utilities. Reuse `notification_outbox`/broadcast pipeline where appropriate. Personal reminder persistence may be local unless cross-device sync already exists. If no calendar-file mechanism exists, propose `.ics` generation/import.

## Permissions

Global alerts: authorized admin/global admin publishing only. User controls own personal reminders.

## Page-specific acceptance criteria

No streak/leaderboard/score. Global and personal sections load cleanly. Calendar/push strategy is explicit and testable.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
