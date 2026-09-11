# Page Prompt 12 - Give Payment

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/25-give-payment.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement standard giving amount-entry screen for Offering/Tithe/Prophet Offering/project contribution. Keep custom keypad and payment source summary consistent with screenshot. Continue initializes a Paystack transaction through secure backend.

## Existing / suggested data layer

Use existing Paystack backend if present. Otherwise create minimal Edge Function for initialize. Record/refresh transaction through existing or proposed giving transaction model. Secret key server-only.

## Permissions

Authenticated user can initiate own giving transaction.

## Page-specific acceptance criteria

No client-forged success; double-submit prevented; amounts validated; backend reference generated; cancellation/error states handled.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
