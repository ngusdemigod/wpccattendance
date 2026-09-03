# Page Prompt 09 - Events list

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/21-events-list.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement/refine the top-level Events page with compact category filters, ongoing-service empty state and recurring/upcoming cards. Event tap goes to Event Detail. Keep chips 12 px with black selected state.

## Existing / suggested data layer

Use existing department/branch/global event repositories. Avoid creating a new master events table merely to render this page; use adapter/view/RPC only if current code needs one.

## Permissions

Event visibility follows existing branch/global/department rules.

## Page-specific acceptance criteria

Ongoing empty shimmer is borderless; filters work; recurring cards are performant/paginated as needed; taps carry event source identity safely.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
