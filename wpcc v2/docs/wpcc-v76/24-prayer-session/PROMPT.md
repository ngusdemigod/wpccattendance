# Page Prompt 24 - Prayer session fullscreen

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/42-prayer-session-countdown.png`
- `../../screenshots/43-prayer-session-count-up.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement the minimal fullscreen prayer session: back button, prayer title, timer, circular progress for duration mode, and an internally scrolling playlist with one play/pause control per song. No stats, streak, session count, score or leaderboard. Playlist container fades at the bottom and does not make the whole page scroll.

## Existing / suggested data layer

Session may remain client state unless current backend tracks prayer sessions for another approved feature. Do not add score/streak tables. Playlist/audio metadata should reuse existing asset model if one exists.

## Permissions

Authenticated user only needs access to current reminder/session media. Global playlist content follows publication scope.

## Page-specific acceptance criteria

Countdown and count-up modes, lifecycle/pause handling, no page scroll caused by playlist, calm motion, background audio behavior only within supported platform limits.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
