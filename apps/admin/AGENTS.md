<!-- BEGIN:nextjs-agent-rules -->
# This is NOT the Next.js you know

This version has breaking changes — APIs, conventions, and file structure may all differ from your training data. Read the relevant guide in `node_modules/next/dist/docs/` before writing any code. Heed deprecation notices.
<!-- END:nextjs-agent-rules -->

# Dream Team admin UI rules

## Design reference

- Treat `../../prompts/churchmetric_complete_workspace_v11_member_profile_tabs_metrics (1).html` as the primary UI/UX and interaction reference for the admin application. The v11 member directory, pagination, status pills, member profile tabs and metrics, inline editing, authorization dialog, add-member dialog, and navigation badges supersede older prototype files.
- Match its component structure, placement, spacing, proportions, buttons, tables, and dialogs closely.
- Use Urbanist throughout the admin application, including controls and tabs.
- All button and tab typography is `12px` with a `400` font weight. This is the only exception to the general minimum typography size.
- All other admin application typography must be at least `13px`.
- Use the existing design tokens and shared styles before adding one-off styling.
- Use only the existing Phosphor icon package for interface icons.

## Application shell

- The product name is **Dream Team**.
- The brand subtitle is the authenticated branch name, such as **WPCC** or **His Glory Expression**. Do not use “Membership workspace” as the subtitle.
- The dashboard must fill the viewport without empty outer padding.
- Keep the only general-purpose search control in the header. Do not add duplicate page-level search controls.
- The header account control is the user avatar when available, otherwise an initials avatar. Do not show a logout button directly in the header.

## Responsive layout

- On mobile, every page-level metric group must remain a two-column grid so four metrics form a `2 × 2` layout.
- Page action buttons must remain in a row and size to their content. Do not stretch them to full width or stack them by default.
- Preserve usable horizontal overflow for tables and tab rows instead of compressing their content beyond recognition.

## Dialogs

- All dialogs and modals must be centered in the viewport.
- Match the reference modal hierarchy, spacing, controls, typography, and responsive behavior.
- Keep dialog actions and close controls keyboard accessible and explicitly labelled.

## Metrics

- Give negative or destructive metrics a subtle red surface, red-tinted border, and readable red text in both light and dark themes.
- Negative metrics include queries, missed services, inactive members, overdue items, critical issues, failures, unresolved items, pending actions, awaiting actions, absences, and equivalent labels.
- Do not apply destructive styling to neutral or positive metrics.

## Member contact details

- Render phone numbers as plain text.
- Place a call icon button and then a WhatsApp icon button beside the phone number. The `tel:` link belongs only to the call icon; the WhatsApp link belongs only to the WhatsApp icon.
- Render membership codes as text with a separate copy-icon button.
- Give icon-only controls accessible names and titles.
- Member inactive status is based on the most recent of the member’s last login and confirmed/present event clock-in. A member is active when either occurred within the last 30 days.

## Page-specific language

- Soul winning uses **Add campaign**, not “Add soul”.
- Departments uses **Download report**.
- Department cards show only the department icon and department name. Do not show “Auto-created from Excel”.

## Verification

- Run the admin test suite and TypeScript checks after implementation.
- Use Playwright to verify affected desktop and mobile UI behavior when the application and required authenticated test state are available.

## Progressive Web App

- Keep the admin application installable as **Dream Team Admin** using the
  App Router manifest at `src/app/manifest.ts`.
- Follow the bundled documentation in
  `node_modules/next/dist/docs/01-app/02-guides/progressive-web-apps.md` and
  the current Next.js metadata conventions before changing PWA behavior.
- Register the production service worker through
  `src/features/pwa/service-worker-registration.tsx` and keep its secure
  headers in `next.config.ts`.
- Treat the dashboard as an authenticated application. Never cache API
  responses, dashboard HTML, member data, authentication responses,
  Supabase requests, or other private tenant information in the service
  worker or browser Cache Storage.
- Offline support must remain limited to the offline shell and public static
  assets unless a separately reviewed encrypted offline-data design is
  explicitly requested.
- Update the service-worker cache name whenever the precached shell files or
  caching behavior changes, so old caches are removed during activation.
- Preserve `public/offline.html`, `public/sw.js`, the WPCC install icon,
  Apple web-app metadata, standalone display mode, and `/dashboard` as the
  installed start URL.
- Do not add a PWA library without approval. Prefer the current small native
  service worker unless requirements genuinely need a maintained library.
- After PWA changes, run the admin tests, `node --check public/sw.js`, and a
  production Next.js build. When browser state is available, verify install,
  standalone launch, service-worker updates, and the offline fallback over
  HTTPS or localhost.
