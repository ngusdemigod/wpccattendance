# Page Prompt 14 - Give Success

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/27-give-success.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement success/result screen from trusted backend/provider transaction state. Show amount, giving type, reference, payment source and receipt actions.

## Existing / suggested data layer

Refetch/verify transaction from backend after Paystack callback/webhook. Do not trust only route arguments.

## Permissions

User sees own transaction result.

## Page-specific acceptance criteria

Success/pending/failure variants are supported even if screenshot shows success; back returns to Give.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
