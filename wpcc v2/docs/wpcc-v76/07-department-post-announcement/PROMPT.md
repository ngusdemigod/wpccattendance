# Page Prompt 07 - Department lead - Post announcement

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/19-department-post-announcement.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement department-scoped announcement composer with target audience controls only when existing announcement targeting supports them. Keep the screen simple: audience, title, body, optional attachment/media.

## Existing / suggested data layer

Reuse `announcements`, `announcement_media`, `announcement_comments` and existing storage. Do not invent a broadcast table when announcements already handle this.

## Permissions

Department lead/authorized higher roles. Members cannot access composer.

## Page-specific acceptance criteria

Published announcement appears for eligible members and Home announcement feed according to scope.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
