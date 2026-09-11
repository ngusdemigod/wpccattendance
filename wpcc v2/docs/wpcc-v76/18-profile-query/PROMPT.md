# Page Prompt 18 - Profile Query

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/33-profile-query.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement Query tab/deep link with concise help copy, textarea and submit. Preserve existing workflow/status handling if query history exists elsewhere.

## Existing / suggested data layer

Prefer `worker_queries` and existing query service. Do not redirect into quality-control tables unless current architecture already does so.

## Permissions

Member/worker submits own query; authorized handlers access through existing admin surface.

## Page-specific acceptance criteria

Validation, pending state, success/error, provider invalidation, no duplicate submits.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
