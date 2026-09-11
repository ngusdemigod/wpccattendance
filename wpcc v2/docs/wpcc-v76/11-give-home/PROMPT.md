# Page Prompt 11 - Give Home

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/24-give-home.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement Give Home: church account rail, copy account number, Quick Actions (Offering, Tithe, Prophet offering, Auto give), 2-column Projects grid, and History action. Do not put recent transaction list on the home page.

## Existing / suggested data layer

Inspect for existing giving/account/project schema first. If absent, propose minimal tables from database-architecture.md. Account cards are display/copy surfaces. Projects are active backend data, not hardcoded.

## Permissions

Authenticated user. Branch/global account/project visibility according to backend scope.

## Page-specific acceptance criteria

Account copy works; project tap can initiate project giving if the production flow supports it; history navigates to dedicated page; typography stays compact.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
