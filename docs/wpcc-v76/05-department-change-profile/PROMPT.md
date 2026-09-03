# Page Prompt 05 - Department lead - Change profile

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/17-department-change-profile.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement the lead-only department profile editor for cover/avatar/description and supported department identity fields. Preserve the current hero preview and simple save interaction.

## Existing / suggested data layer

Reuse `departments` and the existing image storage bucket/asset fields. Do not create a second department profile table.

## Permissions

Department-scoped mutation for authorized leaders/higher roles only.

## Page-specific acceptance criteria

Image upload handles progress/error; text validates lengths; saved state immediately reflects in Department Detail after repository refresh/invalidation.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
