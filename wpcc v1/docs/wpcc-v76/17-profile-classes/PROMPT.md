# Page Prompt 17 - Profile Classes

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/32-profile-classes.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement Classes tab/deep link from Home. Show completion/in-progress/due metrics and assignment/enrollment state. Empty state uses standard shimmer.

## Existing / suggested data layer

Reuse `courses`, `course_enrollments`, `course_publications`, academy module/session tables as existing architecture dictates.

## Permissions

User sees own enrollment data; instructor/admin capabilities remain outside this member prompt.

## Page-specific acceptance criteria

Deep-link works, metrics are derived not hardcoded, empty state correct.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
