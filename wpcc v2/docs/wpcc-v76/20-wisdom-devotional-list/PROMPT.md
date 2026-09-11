# Page Prompt 20 - Wisdom Devotional feed

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/37-wisdom-devotional.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement Wisdom Devotional feed using compact post cards and existing page styling. Tapping a post opens the single-post route.

## Existing / suggested data layer

Prefer `posts`; use existing post type/category/tag field for Wisdom Devotional if available. Media follows current post storage.

## Permissions

Reading follows post scope. Publishing remains admin/content-authorized, not ordinary member by default.

## Page-specific acceptance criteria

Pagination/loading/empty/error; post cards use 14 px title/12 px body styling.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
