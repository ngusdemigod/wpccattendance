# Page Prompt 06 - Department lead - Create event

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/18-department-create-event.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement Department Create Event. Use the existing event component conventions and allow only the fields supported by current department event schema. Type chips can represent service, meeting, rehearsal, training when compatible.

## Existing / suggested data layer

Prefer `departmental_events` and `departmental_recurring_events`. Inspect recurrence conventions before adding any field. Reuse existing event repository/model.

## Permissions

`dept_leader` only within their department; Directorate/admin/globaladmin by existing scope.

## Page-specific acceptance criteria

Server timestamp/timezone handling is explicit; form cannot create event for unauthorized department; new event appears in Events/Department Attendance after refresh.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
