# WPCC v76 — START HERE

This package is arranged so you can extract it directly into the root of the existing Flutter project.

After extraction, the project should contain:

```text
your-flutter-project/
├── lib/
├── android/
├── ios/
├── supabase/
├── pubspec.yaml
└── docs/
    └── wpcc-v76/
        ├── START_HERE.md
        ├── MASTER_CODEX_PROMPT.md
        ├── DATABASE_ARCHITECTURE.md
        ├── DESIGN_SYSTEM_ADDENDUM.md
        ├── SCREEN_INVENTORY.md
        ├── MANIFEST.json
        ├── 01-home/
        │   ├── PROMPT.md
        │   └── screenshots/
        ├── 02-departments-list/
        │   ├── PROMPT.md
        │   └── screenshots/
        ├── 03-department-detail/
        │   ├── PROMPT.md
        │   └── screenshots/
        └── ... through 26-counselling-entrypoint/
```

## Recommended Codex order

1. Open Codex from the Flutter project root.
2. Ask Codex to read `docs/wpcc-v76/MASTER_CODEX_PROMPT.md`.
3. Ask it to inspect the existing Flutter + Supabase architecture before making changes.
4. Implement one numbered page folder at a time.
5. For each page, Codex should read that folder's `PROMPT.md` and inspect every image in its `screenshots/` folder.
6. Existing Riverpod, GoRouter, Supabase tables, RLS, repositories, services, models, RPCs, Edge Functions and Storage are authoritative.
7. Reuse existing infrastructure when it satisfies the requirement. Only suggest the smallest missing data layer when the required support does not exist.
8. Do not perform unrelated refactors or destructive schema changes.

The numbered folders are already ordered for page-by-page implementation.
