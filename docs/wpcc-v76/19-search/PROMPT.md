# Page Prompt 19 - Search

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/34-search-default.png`
- `../../screenshots/35-search-results.png`
- `../../screenshots/36-search-empty.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement app-wide Search with back button, text field, dismissible Recent Search pills that wrap, compact result rows, deep links and minimal no-result state. Hide Recent searches heading when there are no terms.

## Existing / suggested data layer

Recent terms can be local/device state. Search should reuse existing repository searches. If there is no aggregate search endpoint, first consider a lightweight client aggregator; if scale requires server search, propose a Supabase RPC/view rather than a new search table.

## Permissions

Only return results current user is allowed to access.

## Page-specific acceptance criteria

Debounced server queries, keyboard behavior, clear action, deep-link correctness, no-result state exactly minimal.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
