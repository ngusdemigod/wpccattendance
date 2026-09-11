# Page Prompt 26 - Counselling Quick Action integration

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/01-home.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

The v76 prototype contains a Counselling Quick Action but no counselling target-page design. Inspect the production app for an existing counselling/enquiry workflow and connect the tile if present. Otherwise report the missing page design rather than inventing a new screen.

## Existing / suggested data layer

Inspect `enquiries`, `enquiry_messages` and existing counselling-specific code before deciding the target.

## Permissions

Follow existing privacy and counselor/admin access rules.

## Page-specific acceptance criteria

No unsupported counselling page is fabricated from the Home tile.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
