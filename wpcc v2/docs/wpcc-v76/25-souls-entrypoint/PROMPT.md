# Page Prompt 25 - Souls Quick Action integration

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/01-home.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

The v76 prototype contains a Souls Quick Action but no Souls target-page design. Inspect the current production app. If a Souls screen already exists, wire the Home tile to that route and preserve its existing UI/data architecture. If none exists, do not invent a page in this task; leave/report the gap for a separate design prompt.

## Existing / suggested data layer

Existing domain tables: `souls`, `soul_followups`. Reuse them if the target feature exists.

## Permissions

Follow current souls permissions and branch scope.

## Page-specific acceptance criteria

No new UI invented without design approval.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
