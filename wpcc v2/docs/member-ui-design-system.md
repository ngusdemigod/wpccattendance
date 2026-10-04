# WPCC Member UI Design System

## Source And Scope

Use the existing `music-events-prototype.html`, reference specification and token JSON as the visual composition guide. This Flutter adaptation uses WPCC's actual content, bundled DM Sans and Phosphor, not unverified SF Pro assets or the prototype's invented booking features.

Reading this as a modern, minimal member community app with artwork-led discovery and Apple-inspired native controls. Design variance 4, motion intensity 3, visual density 5. `apple-design` guides product interaction and accessibility; `design-taste-frontend` contributes contextual hierarchy and consistency auditing, not marketing layouts or framework substitutions.

The member theme is scoped in the router. Global authentication, onboarding, installation, confirmation and award presentation retain their existing theme and design.md references. System/Light/Dark preference is unchanged.

## Tokens

| Role | Light | Dark |
| --- | --- | --- |
| Background | #F7F8F9 | #151517 |
| Item surface | #FFFFFF | #242224 |
| Raised control | #EEF0F2 | #302E31 |
| Primary text | #202124 | #FAFAFA |
| Secondary text | #62656B | #B5B3B5 |
| Outline | #DDE0E4 | #48454B |
| Selected accent | #683793 | #CAA9E8 |

DM Sans typography uses zero letter spacing, with user text scaling retained:

| Role | Size / Line Height | Weight |
| --- | --- | --- |
| Large detail | 32 / 40 | 600 |
| Page title | 28 / 34 | 600 |
| Section title | 20 / 26 | 600 |
| Row/card title | 16 / 22 | 600 or 500 |
| Long reading | 15 / 21 | 400 |
| Body | 14 / 20 | 400 |
| Command | 14 / 18 | 600 |
| Metadata | 12 / 16 | 400 |
| Navigation | 11 / 14 | 500 |

Radii: 12 thumbnails, 20 repeated content items, 26 album/detail artwork, 32 sheets/navigation, capsules for search/segments, circles for utility and shortcut buttons. Phone gutter 20; wider gutters 24/32. Item gaps 8-12; section gaps 28-32. Reference artwork retains its own colors instead of a decorative page tint.

## Shared Flutter Components

- `MemberTheme`: derives member styling from the existing brightness without mutating the protected global theme.
- `memberPagePadding`: responsive gutters plus inherited navigation/safe-area clearance. Content can scroll entirely above the floating dock even with enlarged text.
- `MemberPageHeader` and `MemberSectionHeader`: restrained headings with native utility actions.
- `MemberIconButton`: circular Phosphor control, tooltip/accessible label, 48px minimum target and immediate native press feedback.
- `MemberPosterCard`: sharp full-bleed artwork, concise title/date overlay, 20px clipping, optional Hero and truthful disabled state. A minimum 70% black scrim covers the complete text bounds for bright flyers.
- `MemberArtwork`: real artwork or a stable theme-aware fallback; no fabricated photos or imagery from unrelated music artists.
- `MemberListRow`: compact image/icon, readable title/metadata, optional action and trailing state; grows with text instead of fixed-height clipping.
- `MemberStatus`: concise empty/error message and native Retry where an action exists.
- `InitialsAvatar(memberStyle: true)`: scoped solid fallback with readable foreground; private-photo lookup and authorization are unchanged. Protected screens retain the existing default appearance.
- `PrayerAlertsContent`: testable native presentation, independent of browser Web Push/calendar services. Existing controller and repository callbacks still own operations.

The navigation retains Home, Media, Events, Give and Profile. Selected destinations use filled Phosphor icons. Floating navigation uses an opaque-enough material with blur only in functional chrome; high contrast/accessibility navigation uses a solid fallback. Reduced motion bypasses moving player transitions. A separate semantics boundary around the nested route preserves the top player's accessible controls without exposing covered route content through modal barriers. Native scrolling, sheets and keyboard focus remain Flutter-owned.

## Page Adaptation

| Screen | Composition | Preserved Functions |
| --- | --- | --- |
| Home | Compact church/member identity, event posters first, seven circular quick links, announcement rows | Three existing providers, refresh, navigation; Classes/Counselling disabled |
| Events | Shared upcoming posters, compact departmental and recurring rows | Original sections, pagination/refresh and detail routes |
| Event detail | Art-led overview, full uncropped zoomable flyer, metadata/action rows | Actual attendance eligibility/busy/error state, check-in/out, organizer, directions and authorized member visibility |
| Media Messages | Channel identity, featured real episode, album rail, numbered track sheet and latest rows | Existing Spotify/provider links, album track loading, episode routes and controller play |
| Media Church life | Photo/ministration feed with short captions and independent state | Original external permalinks and refresh/retry |
| Message detail | Large real artwork, title/date/duration, Play and description | Existing provider launch and playback controller |
| Give | Neutral account cards, concise giving actions, scheduled giving/history | Account copy, original payment extras and mandate/history routes |
| Profile | Identity first, existing Wisdom Points, expandable personal details, settings below | Photo/edit validation, field order/save, Appearance, password and logout; no ledger change |
| Departments | Actual covers/avatars, clear membership and pending status | Pending request flow and existing detail/approval navigation |
| Prayer alerts | Church/personal schedule groups, native Start/Calendar actions and personal switch | Existing start/edit/add/snooze/calendar/push operations |
| Devotional | Latest actual post and compact reading rows, no invented reading times | Pagination, refresh and original post route |
| Souls | Avatar/status rows and existing entry sheet | Original fields/validation/payload and detail route |
| Search | Capsule input, actual section filters, recents and compact results | Debounce/stale-response protection, stored recents, result routes and member visibility |

No ticketing, favourites, voice search, fake counters or fabricated reward state was added. No database, backend, payment implementation or installation-gating changes belong to this design system.

## Verification Contract

Test both themes at 320, 393, 600, 768 and 1024 logical pixels, text scales 1/1.6/2, keyboard insets and rotation. Maintain native semantic activation and 48px targets, contrast over both solid surfaces and bright artwork, retained state, loading/empty/repeated-error retry and dock clearance with nonzero safe areas.

Fixture captures validate layout and fallbacks; live browser screenshots validate actual artwork/navigation. Mock tests do not prove completed live payments, attendance mutations, private-photo uploads or a successful external Spotify session. Those operations must never be performed merely to make a design preview look successful.

## Verified Delivery

139 Flutter tests and 13 installation-policy tests pass. The release web build succeeds, and scoped analysis reports no issues; the full repository analyzer retains 21 pre-existing informational style findings outside the redesigned sources. Independent UI/accessibility audit passed after contrast, semantics and dock-clearance repairs.

Live browser checks confirmed actual event/message artwork, uncropped event flyers, album-track navigation, responsive Profile layout, Give accounts and persistent player controls across routes. The player is now exposed in the live accessibility tree, including native Close and seek controls. The Church life integration returned an unavailable response during verification; its error/retry presentation was verified, not a successful live feed. External Spotify audio success remains unverified.
