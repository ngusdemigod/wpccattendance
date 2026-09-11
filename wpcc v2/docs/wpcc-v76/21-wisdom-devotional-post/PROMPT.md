# Page Prompt 21 - Wisdom Devotional post

Use this **after** `../MASTER_CODEX_PROMPT.md`. The master prompt remains binding.

## Visual references

- `../../screenshots/38-wisdom-devotional-post.png`

Prototype source: `../../reference/prototype-v76.html`  
Design system: `../../reference/design-system.html`

## Task

Implement single devotional post including body, reactions and comments at the end. Preserve the design language and back navigation to feed.

## Existing / suggested data layer

Reuse `post_reactions` and `comments`. Use existing optimistic reaction/comment architecture if present.

## Permissions

Authenticated users may react/comment only if existing community rules allow; post publication permissions unchanged.

## Page-specific acceptance criteria

Reaction count updates safely; comments paginate; duplicate reaction semantics match backend; moderation rules preserved.

## Required implementation behavior

1. Start with the master-prompt audit: inspect routes, Riverpod state, repositories, schema/RLS and existing UI components.
2. Reuse existing theme/widgets before adding new components.
3. Implement loading, data, empty and error states.
4. Match typography, spacing, motion and selected states from the visual references.
5. Verify at 393 x 852 and at a narrower device; no unintended screen-level horizontal overflow.
6. Add/update tests appropriate to the changed logic.
7. At the end, report changed files, backend changes (if any), tests run and any unresolved architecture gap.
