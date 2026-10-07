# WPCC entry and profile-confirmation design

## Reference and scope
The onboarding flow was redesigned on the user's request: same styling, more mature and modern. This specification supersedes the earlier prototype-derived visual tables (the `wpcc_full_prototype_updated_award_footer10px...` entry prototype, the install-guide prototype and `docs/mobile onboarding prototype v3.html`). Only the visuals and layout changed; every behaviour, invariant and the flow described below is unchanged. The rest of the app retains its existing theme. Existing WPCC branding, bundled Manrope 800 / DM Sans and Phosphor icons are retained.

Screens covered: startup splash and install guide (`web/index.html` splash block, `web/wpcc-install.css`, `web/wpcc-install.js` markup), photo onboarding (`pwa_onboarding.dart`), authentication (`prototype_auth_view.dart`), profile confirmation (`profile_confirmation_page.dart`) and the award screen (`profile_reward_screen.dart`). Shared tokens and components live in `lib/features/onboarding/onboarding_style.dart` (`Onb`, `OnbScrim`, `OnbBackButton`, `OnbPrimaryButton`, `OnbSecondaryButton`, `OnbTextAction`, `OnbField`, `OnbMessage`, `OnbChip`, `OnbStepSegments`).

Design read: premium consumer church community app, calm, confident, modern, for members on phones and tablets. Dials: variance 6, motion 5, density 3. The photographic blurred backdrop and the purple identity are kept; they are used with restraint (one accent hue in two tones, no neon glows, no coloured shadows on black).

## Visual system
| Element | Specification |
| --- | --- |
| Headings | Manrope 800, tracking -.035em, line height 1.08 to 1.1. Auth/confirmation 32px (30px at height <= 780, 28px at width <= 370); photo welcome 36px (32px / 30px on short canvases); award 34px (30px short); install guide 28px (26px <= 380, 32px >= 600). Left aligned, except the done and award screens which are centred compositions |
| Body | DM Sans 15px (14px compact), line height 1.5, off-white at 74% to 80%. Helper and error text 13px |
| Labels | DM Sans 13px semibold, off-white at 86%, always above the input. No placeholder-as-label; hints are examples only |
| Colour | Canvas `#0b0910`, ink `#f6f3fa` (no pure black or white), accent `#8b6cf6` with light tone `#b9a6fb` for focus, progress and selected state, error `#ffa3a3`. Web guide: light `#f6f5fa` / dark `#131019`, action `#6a4ad8` (light) or `#8b6cf6` (dark), both at least 4.5:1 with their label |
| Spacing | 4/8 scale: 4, 8, 12, 16, 20, 24, 32, 40, 48. Phone gutter 24 (20 compact), 32 from 600px. Reading widths: authentication 520, confirmation 600, install guide 440 / 560 / 1000 two-column |
| Radii | 12 inputs, chips, back control, secondary buttons, tabs; 20 cards, photographs and install panel; full pill only for the one primary action on a screen. Concentric exception: the install tab control is 16 around 12 tabs |
| Depth | 1px inner borders (off-white at 14% to 22%) and tinted shadows. Cards are avoided; groups use spacing. No outer glows |
| Backdrop | Selected onboarding photograph (blur 7px in confirmation, blur 0/2/10px in authentication, scale 1.07), then `OnbScrim`: canvas tint, vertical fade to 86% to 90% and one restrained accent radial at the bottom edge |
| Targets | Every control at least 48 logical pixels (back 48x48, primary 56 high, secondary 52, text actions 48, chips 48) and grows with text scale. Tested at 2x text on 375x667 |

## Components
- **Step indicator**: segmented 4px bars (one per step, filled to the current step, animated colour at the control duration) under the top bar, with the plain-words count centred in the top bar ("Step 3 of 8"). The count is the accessible label; the bars are decorative. Hidden on the done step.
- **Top bar**: 48 back control at the left, count centred, Skip as a quiet text action at the right. Onboarding screens never use the member sticky back button.
- **Field**: label above, 56px input at 12 radius (off-white 8% fill, 22% border), calm 1.5px light-accent focus border, helper or error line below (error uses a warning icon and the error tone, announced as a live region and scrolled into view once). The border turns to the error tone when an error is shown.
- **Primary action**: off-white pill with dark ink, anchored above the safe area and keyboard; disabled uses 14% fill and 40% text. One per screen. Secondary actions are outlined 12-radius buttons; tertiary actions are text buttons. Press feedback is the shared 0.97 scale (`AppPressMotion`).
- **Chips** (occupation suggestions, departments): 12 radius, selected or already-linked uses the accent fill at 28%; pending departments carry a "Pending" word, not a dot.
- **Loading**: skeleton bars in the shape of the final layout instead of a spinner.

## Screens
| Screen | Layout |
| --- | --- |
| Photo welcome | Blurred photo backdrop and the draggable photo strip (20 radius cards with an inner border); left-aligned two-line heading, one short paragraph and a full-width "Get Started" pill (maximum 420px) |
| Authentication | Left-aligned logo, heading, one line of body, then either the chooser (membership-code pill, outlined email button, text link for password) or a single field with Continue and quiet mode links; terms and privacy on two quiet lines with 48px link targets. Verification uses six 12-radius digit boxes, Continue and an outlined resend button |
| Profile confirmation | Top bar, segments, heading, one sentence, the field(s) for the step, inline error, and the pinned Continue. Departments show linked and chosen departments as chips and the remaining ones as a two-column list. Done step is centred with the celebration burst |
| Award | Centred composition on indigo-black; badge asset unchanged, one violet halo, lavender and off-white particles, "+15WP" or "Reward on its way", a Continue pill and the quiet Learn more footer |
| Install guide | Logo tile, 28px heading, intro, segmented tabs, numbered steps in a 20-radius panel, optional Install pill and a status note. Two columns from 900px (heading left, steps right) |
| Splash | Logo tile, 26px title, status line and a slim accent progress track; the installed-launch variant (white, 45px logo only) is unchanged so it hands over to the Flutter splash |

## Motion
Fast ease-out in, faster out, press scale 0.97, instant under reduced motion. Tokens live in `lib/core/theme/app_motion.dart`.

| Interaction | Duration and curve |
| --- | --- |
| Tab feedback | 140ms, cubic(.23,1,.32,1) |
| Controls, step segments and auth mode fields/size | 180ms, cubic(.23,1,.32,1) |
| Confirmation step | 220ms total; heading, sentence and form enter staggered at 0 / 10% / 20% of the duration, each with one fade and 16 logical pixels of directional travel (Back reverses). Blocks are siblings, so nothing fades twice |
| Route exit | 180ms |
| Sheets | 260ms entrance / 200ms exit |
| Install tabs and panel | 180ms, cubic(.23,1,.32,1); initial install page entrance 480ms unchanged |
| Press feedback | 100ms press / 140ms release, scale .97 (install buttons use the same timings) |

Authentication keeps its single 680ms screen entrance and the single 180ms mode-field entrance (one opacity, at most 8 logical pixels of translation, no animated blur). The reduced-motion path omits the animated size wrapper. Splash and photo choreography (3100ms entrance, drift, hand-over clip) are unchanged. The completion burst and the award keyframes (badge 480ms/1080ms bounce, halo, text at 1020ms, footer and Continue at 1300ms, 4800ms float) are kept as signature exceptions. Reduced motion presents final states immediately and removes particles, ambient movement and press transforms. No motion timing delays validation, saving, navigation callbacks or installation eligibility.

## Rendering performance
Keep photo-strip motion in its own listenable/repaint boundary; do not rebuild the entire onboarding page for each drift or drag frame. Repaint-isolate the blurred backdrop. The sign-in zoom transforms a cached blur/image child instead of rebuilding that subtree each frame; the scrim is a sibling above it so the zoom never repaints it. No backdrop blur is placed over moving content.

## Flow and server behavior
1. Fresh authenticated sign-in → photo → full name → DOB → phone → address → occupation → close contact → departments → details verified.
2. Existing profile data is prefilled. Continue saves before advancing; failures remain on the field with retry guidance. Skip preserves saved data. Back keeps unsaved drafts.
3. Photo selection uploads immediately through the authenticated private-storage function; only validated JPG/PNG/WebP up to 5 MB is accepted.
4. Occupation supports multiple comma-separated entries and common suggestions, as requested. DOB stays in the private profile. Close contact stores structured name/phone text in the existing private field.
5. Existing departments remain visible. New selections submit idempotent pending join requests. Pending entries are labelled; membership/content access remains approval-controlled.
6. Completion is checked from saved server data. Incomplete/skipped profiles do not earn points. A previously rewarded member returns to the community without another award. A newly completed profile may briefly show “Reward on its way” while Cloudflare processes it; leaving the screen does not cancel the reward. +15WP is shown only after ledger confirmation.
7. A restored session or token refresh does not replay confirmation. Signing out and signing back in does. Back from the first step signs out instead of pretending the previous OTP remains unconsumed.
8. Terms/privacy remain non-published placeholder links per the user's instruction. Learn more explains current earning rules without inventing redemption benefits.

## Audit decisions
| Before | After | Why |
| --- | --- | --- |
| Prototype fields were local mock values | Saved profile fields and restricted self-only RPC | Persist actual edits without exposing role/points controls |
| Mock completion always displayed +15 | Pending/confirmed ledger status; lifetime deduplication | No fabricated or repeat awards |
| Three-digit code was treated literally | Numeric code canonicalized on app and server | Match four-digit member records and rate-limit aliases consistently |
| R2 secrets existed only in server .env | Explicit private-storage environment mapping | Functions require their own environment configuration; the avatar gateway validates sessions with Supabase Auth to support rotated asymmetric tokens |
| Avatar endpoint only checked object ownership | Current object reference plus existing department-visibility authorization | Protect private objects while supporting permitted member avatars |
| Prototype removed any department chip | Only unsent selections removable | Confirmation must not silently change existing membership |
| Entry/confirmation visuals followed the earlier prototype (centred 34px type, 18-radius 58px fields, 42px back control, pill buttons everywhere) | Mature onboarding system: left-aligned hierarchy, 12/20/pill radii, 56px fields with labels above, 48px targets, segmented progress with "Step n of 8" | User request: same styling, more mature and modern |
| Errors sat in a bar above the action and fields used placeholder hints as the only description | Inline helper/error text below the field, announced as a live region and scrolled into view | Errors belong next to the input and must not be missed under the keyboard |
| Confirmation avatar action was a 31px overlay button; chips were stock Material chips | 48px "Choose photo" button; shared 12-radius chips with 48px targets | Accessibility and contrast |
| Material icons for back and password visibility mixed with Phosphor | Phosphor throughout | One icon family |
| Auth used a zero-duration AnimatedSize under reduced motion (re-lays itself out in debug) | The animated wrapper is omitted under reduced motion | Avoids a debug assertion and respects reduced motion |
| Welcome screen carried a "Community moments scrolling live" caption and a 188px floating button | Caption removed, full-width primary action | The caption was decoration and made an unsupported "live" claim |
| Terms placeholder dialog used an em dash | Plain sentence, same meaning | No em dashes in copy |

## Verification
Run scoped Flutter tests for membership normalization, fresh-login tracking, profile saves/skips, compact layout, authentication and existing entry motion. Run `supabase/tests/profile_confirmation.sql` inside its rollback transaction for self-only saves, field allowlisting, pending request deduplication and incomplete reward rejection. Type-check the touched Edge Functions. Verify authenticated upload/read/replacement and unauthorized object reads against private storage using disposable fixtures; never real member data.

## Installation guide and tablet layouts
Visual design: see the visual system above. The guide uses the bundled Manrope 800 / DM Sans (`InstallManrope`, `InstallDM`), the existing WPCC logo, a flat tinted background (no gradients), a segmented tab control with 48px tabs, numbered steps in a 20-radius panel with an inner border, and a full-pill Install action. The sheet is 440px wide on phones, 560px from 600px and a two-column 1000px layout from 900px. It is centred horizontally and vertically when space permits; auto margins collapse on short screens so all steps remain scrollable from the top. Dark mode follows the stored theme/system preference (`data-startup-theme`). Safe areas, visible keyboard focus, selected-tab semantics, arrow/Home/End navigation and reduced motion are required. Element ids (`tab-ios`, `tab-android`, `steps-ios`, `steps-android`, `install-action`, `install-status`) are part of the gate's contract and the tests; do not rename them.

Device policy is independent of viewport width: iPhone/iPad (including Macintosh identification with multiple touch points) selects iOS; Android selects Android. Manual tab selection remains available. Windows touch computers and macOS desktops are desktop devices. Desktop browsers and desktop installed apps show “Use a phone or tablet”. Supported mobile/tablet browsers show installation instructions until actually launched in installed mode; accepting an install prompt or receiving appinstalled does not unlock that tab. `window.wpccInstalledLaunch` resolves only for supported installed launches. This is presentation gating, not an authorization boundary.

Safari is the supported iOS fallback: Share → Add to Home Screen → enable Open as Web App where offered → Add. Android exposes a real install button only when beforeinstallprompt is supplied; otherwise manual Chrome instructions remain. Cancellation/errors preserve the guide.

App backgrounds fill the viewport. Authentication forms retain a 520px reading width and confirmation forms a 600px reading width. Main-app typography, colours, icons and bottom navigation are unchanged. Below 600px retain phone layouts; at 600–899px expand spacing and card grids; sections with at least 900px available width use two columns. Layouts use local constraints, not device identity. Independent Home, Media, Events, Give and Profile sections adapt, as do department cards. Stable widget trees preserve state during resizing. Navigation remains centred with a 720px maximum control width; the app body is not constrained to that width.

| Before | After | Why |
| --- | --- | --- |
| Generic installation instructions | Device-selected accessible tabs with numbered steps | Match the visitor's installation steps |
| Installed-mode check could admit desktop | Device policy checked first | Desktop installations cannot bypass the selected mobile/tablet policy |
| Authentication had a 430px outer frame | Full-width background and bounded form | Adapt to tablet orientation without oversized fields |
| Sections mostly stacked | Responsive card grids and independent two-column sections | Use tablet space while retaining readable content |
| 15px guide heading, 42px tabs, 12px body, faint gradients and a low-contrast note | 28px heading, 48px tabs, 14px to 15px body, flat background, 5.9:1 action and 5.4:1 note | Stronger hierarchy, readable type and AA contrast in both themes |
| One narrow column on tablets | Two columns from 900px | Use landscape tablet width; the reading column stays bounded |

Verification: run `node --test test/install_gate_test.cjs`, scoped Flutter layout/auth/profile/media tests, Flutter analysis and a release web build. Device-policy tests cover iPhone, iPad desktop identification, Android phone/tablet, Windows touch and macOS, plus prompt cancellation/acceptance and installed-mode changes. Real iOS/Android installation still requires physical-device verification; simulated detection does not establish browser-specific installation support.

## Award screen
The badge is the user-supplied transparent PNG `assets/images/profile_reward_badge.png`, used unchanged (never a medal icon or generated badge). The close control keeps the Phosphor close icon, now a 48px 12-radius control.

Layout is unchanged where tests and the badge geometry depend on it: on screens taller than 780px content starts at 68px, then a 14px gap and a 310px badge showcase with a 212px badge; at 780px or shorter, 62px top, no extra gap, a 246px showcase and a 176px badge. Safe-area insets are added. Title is Manrope 800 at 34px (30px compact), summary DM Sans 15px bounded to 320px at 78% off-white. Below the copy sit a full-pill Continue (maximum 420px) that closes exactly like the close control, then the quiet Learn more footer at 12px (maximum 340px) with an inline underlined link. Content scrolls on unusually short screens.

Background: a calm indigo-to-near-black vertical gradient with one violet radial near the badge and one faint indigo radial at the top (the earlier pink/green layers were removed). The badge keeps a tinted depth shadow and a single faint violet shadow; the halo is one violet radial. Twenty sparse particles in lavender and off-white replace the 28 multicoloured ones.

Motion schedule (relative to opening) is unchanged: background 1050ms; stars fade at 180ms over 750ms; badge enters at 480ms over 1080ms using the 0/56/76/100% keyframes and cubic(.18,1.32,.36,1); halo at 520ms over 1100ms; close at 720ms over 500ms; text at 1020ms over 760ms; Continue and footer at 1300ms over 740ms. Badge floats from 1620ms over a 4800ms cycle; halo pulses on a 4400ms cycle. Cache badge/shadow artwork and static gradients; repaint animation layers independently. Pause ambient ticking when the application is backgrounded. Reduced motion shows the final layout immediately and removes particles and ambient movement.

Close fades out over 180ms and continues to the community. Learn more temporarily reads “More ways to earn WP coming soon” for 1800ms and then restores itself; it does not open a different modal. The existing server-confirmed lifetime award rule is unchanged: pending state explains processing, and +15WP appears only when confirmed.

| Before | After | Why |
| --- | --- | --- |
| Generic medal in a purple circle | Exact supplied transparent badge | Match the approved artwork |
| Simplified bounce and continuously moving full composition | Staggered keyframes with isolated animated layers | Avoid unnecessary iOS rendering work |
| Different summary, footer and Learn more modal | Prototype copy, inline link and timed replacement | Match the requested interaction |
| Award opened with an unbundled Light font request | Bundled font | Prevent a late font fetch and unstable text layout |
| Navy, blue, pink and green radial layers, cyan and magenta badge glows, multicoloured particles | Indigo-black with one violet accent, depth shadow only, lavender particles | Calm and mature; no neon glow |
| 10px footer and a 42px close icon as the only exit | 12px footer, 48px close control and a clear Continue pill | Readable copy, 48px targets and one obvious primary action |

Checks: `test/profile_reward_screen_test.dart` verifies badge asset/size, title position, compact/tall/tablet/short-screen layouts, timed Learn more, close, delayed badge reveal and pending-vs-awarded copy. `CAPTURE_AWARD=true` exports local render screenshots to the system temp directory. Existing profile-confirmation tests protect save/skip/reward flow.

## Confirmation dialog host
ProfileConfirmationGate is mounted above the router in MaterialApp.builder. It must create ProfileConfirmationFlow's own Navigator/Overlay before rendering confirmation fields, tooltips and modal pickers. A MaterialApp(home: confirmation) test alone does not reproduce production ancestry. The regression test must mount the flow inside MaterialApp.builder and open, cancel, reopen and confirm the DOB picker without saving until Continue.
