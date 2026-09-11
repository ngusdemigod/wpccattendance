# Page Prompt 02 - Departments list

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/02-departments-list.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement/refine the top-level Departments page with All / My Teams / Leading filters. Use compact department cards with 8 px internal padding. Department card tap navigates to Department Detail. Filtering should preserve smooth list motion and existing bottom navigation.

## Existing / suggested data layer

Reuse `departments`, `profile_departments`, `workers`, `leaders` and current department repositories. Determine `mine`/`leading` from existing relations rather than adding booleans.

## Permissions

Workers see their departments; leads see lead filter according to existing scope; higher roles can use existing branch/global access.

## Page-specific acceptance criteria

Black selected chips, 12 px text, no full-page horizontal overflow, correct empty state for filter with no results.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
