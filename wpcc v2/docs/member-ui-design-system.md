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

DM Sans typography uses zero letter spacing, with user text scaling retained.

**Compact scale (2026-10-05).** Member text was reduced because the earlier prototype-matched scale read too large on phones. This scale supersedes the type sizes in `wpcc-member-prototype.html`, which is left unchanged as a layout and interaction reference. Body is 12. Sizes are defined once in `buildMemberTheme` (`lib/core/theme/member_theme.dart`):

| Role | Flutter text theme | Size / Line Height | Weight |
| --- | --- | --- | --- |
| Display, tablet | `headlineLarge` | 32 / 40 | 600 |
| Display, phone | `headlineMedium` | 30 / 38 | 600 |
| Page title | `headlineSmall` | 24 / 30 | 600 |
| Section title | `titleLarge` | 17 / 23 | 600 |
| Row/card title | `titleMedium` | 14 / 20 | 500 |
| Small title | `titleSmall` | 13 / 18 | 600 |
| Long reading | `bodyLarge` | 14 / 22 | 400 |
| Body | `bodyMedium` | 12 / 18 | 400 |
| Secondary text | `bodySmall` | 11 / 16 | 400 |
| Command | `labelLarge` | 13 / 18 | 600 |
| Label | `labelMedium` | 12 / 17 | 400 |
| Caption, navigation | `labelSmall` | 10 / 14 | 400 |

Amounts and one-off emphasis sizes are 34 (payment result), 32 (prayer time), 30 (giving amount) and 26 (event title). Prefer a text theme role over a `fontSize` literal. Where a literal is needed, use a value from this table, and do not go below 10. The legacy `app_theme.dart` scale applies only to authentication and onboarding and is not part of this scale.

Radii: 12 thumbnails, 20 repeated content items, 26 album/detail artwork, 32 sheets/navigation, capsules for search/segments, circles for utility and shortcut buttons. Phone gutter 20; wider gutters 24/32. Item gaps 8-12; section gaps 28-32. Reference artwork retains its own colors instead of a decorative page tint.

## Shared Flutter Components

- `MemberTheme`: derives member styling from the existing brightness without mutating the protected global theme.
- `memberPagePadding`: responsive gutters plus inherited navigation/safe-area clearance. Content can scroll entirely above the floating dock even with enlarged text.
- `MemberPageHeader` and `MemberSectionHeader`: restrained headings with native utility actions.
- `MemberIconButton`: circular Phosphor control, tooltip/accessible label, 48px minimum target and immediate native press feedback. A button labelled `Back` or `Back to ...` is rendered by `MemberBackButton` (below), never as a plain caret.
- `MemberBackButton` / `MemberBackHost` (`lib/core/widgets/member_back.dart`): the single back control. The router (`_slide`, `_fade`, prayer session) wraps every non-tab member route in `MemberBackHost`, which pins one 48px target (40px glass circle, caret-left, tooltip and semantics `Back`, `AppPressMotion`) to the **top right**, inside the safe area (20px from the top and from the right gutter, 4px from the top on routes with a 56px app bar), above the scrolling content so it never scrolls away. It pops when it can and otherwise goes to the parent route from `MemberBackRule.of(path)` (always the parent for `/give/result`). It is absent from the five tab roots, authentication, onboarding, installation and award screens, and from full-screen viewers on the root navigator (gallery viewer, shorts), which keep their own close control.
  - Pages do not draw their own back. Inside a host, `MemberIconButton(label: 'Back')` renders an empty 48px-tall band, `MemberPageHeader` drops its leading back and reserves 56px on the right, and `MemberAppBar` (use it instead of `AppBar` on member pages) drops its leading and keeps its actions clear of the button. A row with a custom right-hand action appends `MemberBackScope.reserve(context)` so the action sits to the left of the button (Media message Share, Event flyer, Department Join/Manage). Without a host (isolated page tests) the same widgets draw one inline `MemberBackButton` on the left.
  - A page that must change what Back does wraps itself in `MemberBackOverride(onBack: ...)` (Service tools clears its selected department first, Join requests pops with its result, the prayer session ends the session).
- `MemberPosterCard`: sharp full-bleed artwork, concise title/date overlay, 20px clipping, optional Hero and truthful disabled state. A minimum 70% black scrim covers the complete text bounds for bright flyers.
- `MemberArtwork`: real artwork or a stable theme-aware fallback; no fabricated photos or imagery from unrelated music artists.
- `MemberListRow`: compact image/icon, readable title/metadata, optional action and trailing state; grows with text instead of fixed-height clipping.
- `MemberStatus`: concise empty/error message and native Retry where an action exists.
- `InitialsAvatar(memberStyle: true)`: scoped solid fallback with readable foreground; private-photo lookup and authorization are unchanged. Protected screens retain the existing default appearance.
- `PrayerAlertsContent`: testable native presentation, independent of browser Web Push/calendar services. Existing controller and repository callbacks still own operations.

The navigation retains Home, Media, Events, Give and Profile. Selected destinations use filled Phosphor icons on a flat circular indicator in the member theme's selected colour (ink: near-black in light, near-white in dark) that glides with the dock spring and fades with `AppMotion.tab`. Floating navigation uses an opaque-enough material with blur only in functional chrome; high contrast/accessibility navigation uses a solid fallback. Reduced motion bypasses moving player transitions. A separate semantics boundary around the nested route preserves the top player's accessible controls without exposing covered route content through modal barriers. Native scrolling, sheets and keyboard focus remain Flutter-owned.

**Sheets.** `showMemberSheet` is the single path for member sheets. It slides up from the bottom on `AppMotion.drawer` (260 ms in, 200 ms out on the flipped curve; centred sheets on tablets rise 48px and fade), the scrim fades in step, drag-to-dismiss still works and reduced motion is instant. The few remaining direct `showModalBottomSheet` calls (media player seek, department detail, giving service picker, Home announcement/resources, rewards) pass `AppMotion.sheetStyle`, so they use the same timing and curve.

## Page Adaptation

| Screen | Composition | Preserved Functions |
| --- | --- | --- |
| Home | Compact church/member identity, event posters first, five circular quick links in a 5-column grid (Prayer, Devotional, Souls, Service tools, Classes), announcement rows | Three existing providers, refresh, navigation; Classes disabled |
| Events | Shared upcoming posters, compact departmental and recurring rows | Original sections, pagination/refresh and detail routes |
| Event detail | Art-led overview, full uncropped zoomable flyer, metadata/action rows | Actual attendance eligibility/busy/error state, check-in/out, organizer, directions and authorized member visibility |
| Media | Top-level **Media | Gallery** switch, then circles (the livestream on air with a LIVE badge, or else the latest ended livestream, then the Spotify albums), then **All / Audio** filter pills, then a **Videos** feed of shelves in a random order each load: a short list (4), a horizontal scroll of 4 portrait Shorts, one wide 16:9 video, a grid of 6 small squares. Every row keeps its neutral Audio, Video or Livestream badge. A video opens on its own page and plays at once, with Open in YouTube or Open in Facebook easing in under it; a Short opens a full-screen vertical viewer (swipe, arrows or keyboard). Starting a video pauses audio. All motion uses the standard curve and durations from `AppMotion` (140 to 260 ms, exits faster than entrances, 0.97 press scale, instant under reduced motion) | Existing Spotify/provider links, album routes and controller play; sources load and fail independently; short and portrait videos never appear in the ordinary shelves |
| Media Gallery | Masonry grid of Facebook page photos (2 columns under 600, 3 from 600, 4 from 900, 8px gutters, 12px radius), tiles sized from stored width and height, no overlay text; a download button in the top right corner of every photo and of the viewer; full-screen viewer with swipe, pinch zoom, drag-down dismiss and a View on Facebook link | Catalog from the public media API (Cloudflare Worker + D1, `cloudflare/media-sync`); photos are mirrored to our own R2 storage because Facebook URLs expire, loaded 40 at a time with keyset pagination, with empty, error and retry states |
| Message detail | Large real artwork, title/date/duration, Play and description | Existing provider launch and playback controller |
| Give | Neutral account cards, concise giving actions, scheduled giving/history | Account copy, original payment extras and mandate/history routes |
| Profile | Identity first, existing Wisdom Points, expandable personal details, settings below | Photo/edit validation, field order/save, Appearance, password and logout; no ledger change |
| Departments | Actual covers/avatars, clear membership and pending status | Pending request flow and existing detail/approval navigation |
| Prayer alerts | Alarm-style screen. Large title, then a summary of the next active alert (large tabular time, `In 2 h 15 min`, label; `No active alerts` when none is on), a quiet dismissible `Turn on reminders` banner (only when push is available), then a featured church-wide card (time, label, days, primary `Pray now`, calendar icon) rendered only when a global alert exists, `From your church` rows for other non-personal alerts, and `My alerts` rows (time with smaller am/pm, label, M T W T F S S strip with repeat days bold, optimistic switch, inactive rows dimmed). A floating `New alert` pill sits above the dock (the empty state `No alerts yet` has one `Add your first alert` button instead). Quiet `Start prayer` and `Add to calendar` text actions close the list. Editor: large tappable time card with `Rings in ...`, label, seven day toggles, settings group, Save anchored above the safe area and keyboard. Session: always dark, calm countdown ring, `End session`. Alarm numerals (hero 56, editor 64, card 44, row 30) are the one exception to the type table and are clamped to 1.3x text scale | Existing start/edit/add/snooze/calendar/push operations; only personal alerts are editable, non-personal rows start a session; next-alert logic is the pure `PrayerSchedule` (`prayer_schedule.dart`); list loading and optimistic toggles live in `PrayerAlertsView` |
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
