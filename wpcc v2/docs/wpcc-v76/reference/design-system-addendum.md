# Design System Addendum for v76

Use this addendum with `design-system.html` and the screenshots. It captures interaction/components introduced after the earlier design-system snapshot.

## Department tabs
- Tab content slides horizontally according to navigation direction.
- Movement is subtle (~18 logical px) and about 210 ms.
- Selected tab remains black, 12 px text.

## Expandable search controls
- Members, Attendance and Files use a small search glyph/control that expands into a compact search field.
- Expansion should feel like the icon becomes the field rather than a new large component appearing.
- Search field collapses when empty and focus is dismissed.

## Filter popovers
- Compact filter icon adjacent to search.
- Popover is frosted/light, readable width (not constrained by trigger width), anchored to the filter icon.
- Selected option uses black background.
- Tap outside dismisses.

## Filtered lists
- Rows entering a filtered result fade/slide in subtly.
- Rows being removed fade/translate out before layout closes.
- Avoid large-scale or bouncing transitions.

## Public member sheet
- Animated bottom sheet.
- Public data only: photo/initials, full name, phone, departments.
- Avatar is tappable and expands into a full-screen image/initials viewer.
- Full-screen initials viewer uses the standard initials gradient and a dark/frosted backdrop.

## Department Attendance
- First level is an event list.
- Event row: compact icon, title, date/time, present count, caret.
- Event tap opens a bottom sheet containing present members sorted by check-in time.
- Time detail shows exact check-in and relative timing to event start.

## Files
- Member-facing files are a 2-column thumbnail grid.
- Lead file-management grid adds top-right visibility icon:
  - black unlocked = public to department members + leaders
  - red locked = leaders only
- Lead-management cards include Remove File.
