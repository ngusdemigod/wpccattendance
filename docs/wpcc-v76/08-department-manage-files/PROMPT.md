# Page Prompt 08 - Department lead - Manage files

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/20-department-manage-files.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement Manage Files using a 2-column thumbnail grid. Upload new file. Each file shows a top-right visibility lock: black unlocked = public to members+leaders; red locked = leaders only. Include Remove File. Do not show a top-right Done action. Visibility toggle must persist and revert if backend rejects.

## Existing / suggested data layer

Reuse `department_attachments` and existing Supabase Storage. If visibility field/policy is missing, propose minimal backend extension. Private/leader files must not be accessible through a public URL.

## Permissions

Lead-only/higher scoped management. Member read access only to public department files.

## Page-specific acceptance criteria

Upload, remove, visibility toggle, optimistic rollback, loading/error, protected downloads and grid layout all work.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
