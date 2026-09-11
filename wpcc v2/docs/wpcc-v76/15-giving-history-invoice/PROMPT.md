# Page Prompt 15 - Giving History and invoice

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/28-giving-history.png`
- `../../screenshots/29-giving-invoice-sheet.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement dedicated Giving History page. Rows are compact; transaction title 12 px. Tapping a transaction opens animated invoice bottom sheet with status, amount, date, reference, source and Download PDF / Download Image.

## Existing / suggested data layer

Use existing/proposed transaction table. Receipt may be generated from transaction data; persist receipt assets only if existing product pattern requires. Download must use trusted backend values.

## Permissions

User reads own transactions; finance/admin visibility follows existing admin surface, not this member page.

## Page-specific acceptance criteria

Paginated history, status mapping, invoice sheet outside-tap dismiss, reliable PDF/image export/share behavior.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
