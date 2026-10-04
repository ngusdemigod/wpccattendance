# Page Prompt 03 - Department Detail and tabs

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/03-department-overview.png`
- `../../screenshots/04-department-actions-menu.png`
- `../../screenshots/05-department-members.png`
- `../../screenshots/06-department-member-public-sheet.png`
- `../../screenshots/07-department-member-avatar-expanded.png`
- `../../screenshots/08-department-members-search.png`
- `../../screenshots/09-department-members-filter.png`
- `../../screenshots/10-department-attendance-events.png`
- `../../screenshots/11-department-attendance-event-members.png`
- `../../screenshots/12-department-attendance-filter.png`
- `../../screenshots/13-department-files.png`
- `../../screenshots/14-department-files-search.png`
- `../../screenshots/15-department-files-filter.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement the Department Detail page and all four tabs. Hero is full bleed with overlay; sticky header is transparent over hero and frosted after scrolling. Department options menu is lead-only, opens on tap and dismisses outside. Tabs slide directionally left/right. Overview has horizontal leadership profiles and wallet empty state. Members has animated search/filter and a public-profile bottom sheet; avatar expands full screen. Attendance shows events first; tapping an event shows present members ranked by earliest check-in. Files is a 2-column thumbnail grid with animated search/filter.

## Existing / suggested data layer

Reuse `departments`, `leaders`, `leadership_titles`, `profile_departments`, `profiles`/safe public projection, `attendance`, departmental event tables, and `department_attachments`. Public member phone must come only from an authorized public projection. For attendance calculate check-in delta against event start. For files apply backend visibility/RLS.

## Permissions

Basic department data is visible according to existing membership rules. Lead menu hidden for unauthorized users. `dept_leader`, authorized `Directorate`, `admin`, `globaladmin` get only their allowed scoped mutations.

## Page-specific acceptance criteria

Only explicit leadership/file/search rails scroll horizontally; page never x-overflows. Member sheet shows photo/initials, name, phone, departments only. Attendance sorts check-in ascending. Filters animate. File results respect visibility.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
