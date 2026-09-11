# Page Prompt 16 - Profile Overview

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/30-profile-overview.png`
- `../../screenshots/31-profile-overview-scrolled.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement/refine Profile Overview with avatar/initials, identity, member code and personal detail rows. Do not add the removed summary-stat card. Preserve verified update flows for editable fields.

## Existing / suggested data layer

Reuse `profiles`, `profiles_priv_info`, `worker_private_profiles`, `profileverification`, `member_update_verifications` as existing flows require.

## Permissions

User edits own allowed fields. Sensitive fields follow verification/admin rules already present.

## Page-specific acceptance criteria

Initials use exact design-system styling; long fields wrap; edits invalidate/refetch provider; no private field leakage.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
