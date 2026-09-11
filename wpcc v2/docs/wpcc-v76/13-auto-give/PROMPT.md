# Page Prompt 13 - Auto Give

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/26-auto-give.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement Auto Give as an explicit recurring-giving setup using selected event days/rules and fixed amount. Keep same payment screen family but reveal recurrence controls.

## Existing / suggested data layer

Inspect existing recurring-payment data. If absent, minimal `recurring_giving_mandates` is suggested. Store Paystack reusable authorization metadata server-side; never raw card details.

## Permissions

Authenticated user manages only own mandate. Authorized finance/admin reads only where current product requires.

## Page-specific acceptance criteria

Explicit consent, active/inactive status, cancellation path in data model, secure scheduled charge process, no silent client-side recurring charge.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
