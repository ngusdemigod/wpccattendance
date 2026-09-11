# Page Prompt 04 - Department lead - New wallet

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/16-department-new-wallet.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement the lead-only New Wallet page opened from Department Actions. Keep the form compact and consistent with the design system. This page creates/configures the department's displayable wallet/account record; it is not a generic finance administration redesign.

## Existing / suggested data layer

First inspect for an existing department/church account model. If absent, propose the smallest compatible account table described in database-architecture.md. Never store Paystack secrets here.

## Permissions

Department lead access only if product permission explicitly allows; Directorate/admin/globaladmin according to existing higher-scope rules. Enforce server-side.

## Page-specific acceptance criteria

Form validation, duplicate account prevention if appropriate, pending state, success feedback, and navigation back to department.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
