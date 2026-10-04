# WPCC entry and profile-confirmation design

## Reference and scope
Visual source: `wpcc_full_prototype_updated_award_footer10px_typography_updated_title_reverted.html`, supplied by the user from Downloads. This supersedes the earlier splash-only HTML for entry, authentication, verification, profile confirmation and award presentation. The rest of the app retains its existing theme. Existing WPCC branding and Phosphor icons are intentionally retained.

## Typography and layout
| Element | Specification |
| --- | --- |
| Headings | Manrope 800; profile 34px, 30px at height ≤780, 29px at width ≤370; line height .99; tracking −.055em |
| Body | DM Sans 14px (13px compact), 1.42 line height; white at 68% |
| Kicker / labels | DM Sans 12px semibold; white at 58% / 70% |
| Copy alignment | Centred; heading maximum width 330px |
| Background | Selected onboarding photograph; blur 7px, scale 1.07, brightness .58, dark vertical overlay, subtle bottom purple glow |
| Navigation | 42px circular back control, top padding 18px/20px, Skip at right; 3px progress track with 24px horizontal inset |
| Content | 28px horizontal / 56px top; compact 24px / 34px; department top 38px / 24px |
| Fields | 58px high, radius 18px, white 10.5% fill and 15% border; 15px medium text; address multiline |
| Continue | 54px pill; white with dark text; disabled white 16% fill / 38% text; anchored above safe area and keyboard |
| Award footer | 10px DM Sans, including Learn more |

## Motion
- Profile entrance: 720ms, cubic(.22,.72,.18,1), 20px directional translation, 7px blur to clear, opacity to 1. Back reverses direction; only the new screen enters, avoiding overlapping double fades.
- Authentication keeps its single 460ms mode-field entrance and 680ms screen entrance; selected onboarding photo continues into confirmation.
- Completion: avatar scales from .72 with a soft overshoot, with a deterministic confetti burst.
- Award: 1080ms badge entrance delayed 480ms, slight rotation and overshoot; 4800ms floating cycle. Text enters after 1020ms over 760ms. Dark blue/purple background, sparse coloured particles, bottom footer.
- Reduced motion presents final layouts immediately and stops ambient movement. Back/Skip/Continue are disabled during saves to prevent races.
- Short screens and keyboard openings scroll the content, keeping the primary action reachable. No simulated system bottom bar.

## App-wide motion override
The approved interaction-motion pass supersedes the older auth-mode and confirmation-step timings above, without replacing the signature opening or award choreography. Shared Flutter tokens live in `lib/core/theme/app_motion.dart`.

| Interaction | Duration and curve |
| --- | --- |
| Tab feedback | 140ms, cubic(.23,1,.32,1) |
| Controls and auth mode fields/size | 180ms, cubic(.23,1,.32,1) |
| Page and confirmation steps | 220ms, cubic(.23,1,.32,1) |
| Route exit | 180ms |
| Sheets | 260ms entrance / 200ms exit |
| Install tabs and panel | 180ms, cubic(.23,1,.32,1) |
| Install press feedback | 100ms press / 140ms release |

Auth mode changes use one opacity entrance with no animated blur and at most 8 logical pixels of translation. Confirmation steps enter once with 16 logical pixels of directional travel; Back reverses direction. Their static photographic backdrop blur is unchanged. Reduced motion presents final states immediately and removes install press transforms.

Keep the 680ms authentication screen entrance, splash/photo choreography and photo drift unchanged. Keep the 480ms initial install-page entrance unchanged. Completion celebration, v3 award keyframes, staggered timing and ambient cycles are exceptions to the everyday interaction tokens and remain unchanged. No motion timing delays validation, saving, navigation callbacks or installation eligibility.

## Rendering performance
Keep photo-strip motion in its own listenable/repaint boundary; do not rebuild the entire onboarding page for each drift or drag frame. Repaint-isolate the blurred backdrop. The sign-in zoom must transform a cached blur/image child instead of rebuilding that subtree each frame. Preserve the existing timing, appearance and reduced-motion behavior.

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

## Verification
Run scoped Flutter tests for membership normalization, fresh-login tracking, profile saves/skips, compact layout, authentication and existing entry motion. Run `supabase/tests/profile_confirmation.sql` inside its rollback transaction for self-only saves, field allowlisting, pending request deduplication and incomplete reward rejection. Type-check the touched Edge Functions. Verify authenticated upload/read/replacement and unauthorized object reads against private storage using disposable fixtures; never real member data.

## Installation guide and tablet layouts
Reference: `wpcc_install_guide_refined_typography.html`. The pre-Flutter guide uses Manrope 800 headings and DM Sans body text, the existing WPCC logo, purple segmented tabs, numbered circles and the prototype's light background. The guide is centred horizontally and vertically when space permits; auto margins collapse on short screens so all steps remain scrollable from the top. Dark mode follows the stored theme/system preference. Safe areas, visible keyboard focus, selected-tab semantics, arrow/Home/End navigation and reduced motion are required.

Device policy is independent of viewport width: iPhone/iPad (including Macintosh identification with multiple touch points) selects iOS; Android selects Android. Manual tab selection remains available. Windows touch computers and macOS desktops are desktop devices. Desktop browsers and desktop installed apps show “Use a phone or tablet”. Supported mobile/tablet browsers show installation instructions until actually launched in installed mode; accepting an install prompt or receiving appinstalled does not unlock that tab. `window.wpccInstalledLaunch` resolves only for supported installed launches. This is presentation gating, not an authorization boundary.

Safari is the supported iOS fallback: Share → Add to Home Screen → enable Open as Web App where offered → Add. Android exposes a real install button only when beforeinstallprompt is supplied; otherwise manual Chrome instructions remain. Cancellation/errors preserve the guide.

App backgrounds fill the viewport. Authentication forms retain a 520px reading width and confirmation forms a 600px reading width. Main-app typography, colours, icons and bottom navigation are unchanged. Below 600px retain phone layouts; at 600–899px expand spacing and card grids; sections with at least 900px available width use two columns. Layouts use local constraints, not device identity. Independent Home, Media, Events, Give and Profile sections adapt, as do department cards. Stable widget trees preserve state during resizing. Navigation remains centred with a 720px maximum control width; the app body is not constrained to that width.

| Before | After | Why |
| --- | --- | --- |
| Generic installation instructions | Prototype guide with device-selected accessible tabs | Match supplied styling and the visitor's installation steps |
| Installed-mode check could admit desktop | Device policy checked first | Desktop installations cannot bypass the selected mobile/tablet policy |
| Authentication had a 430px outer frame | Full-width background and bounded form | Adapt to tablet orientation without oversized fields |
| Sections mostly stacked | Responsive card grids and independent two-column sections | Use tablet space while retaining readable content |

Verification: run `node --test test/install_gate_test.cjs`, scoped Flutter layout/auth/profile/media tests, Flutter analysis and a release web build. Device-policy tests cover iPhone, iPad desktop identification, Android phone/tablet, Windows touch and macOS, plus prompt cancellation/acceptance and installed-mode changes. Real iOS/Android installation still requires physical-device verification; simulated detection does not establish browser-specific installation support.

## Award screen: v3 reference
For the award screen, `docs/mobile onboarding prototype v3.html` supersedes the earlier award implementation. Use the user-supplied transparent PNG `assets/images/profile_reward_badge.png` unchanged; never substitute a medal icon or generated badge. Keep the existing Phosphor close icon.

The full-viewport background combines the prototype's navy vertical gradient with blue, purple and lower pink/green radial layers. On screens taller than 780px, content starts at 68px, then a 14px gap and 310px badge showcase; badge is 212px, title 31px/1.06 Manrope 800 with −.05em tracking. At 780px or shorter use 62px top, no extra gap, 246px showcase, 176px badge and 28px title. Safe-area insets are added. Summary is bounded to 320px, DM Sans 14px/1.42, −.015em tracking and 70% white. Match the prototype's rendered bundled regular-weight fallback, avoiding an unbundled Light font request. Footer uses an inline underlined Learn more link, maximum 330px; 10px on tall screens and 13px paragraph/10px link on compact screens, matching the supplied CSS. Keep content scrollable on unusually short screens.

Motion schedule (relative to opening): background 1050ms; stars fade at 180ms over 750ms; badge enters at 480ms over 1080ms using the CSS 0/56/76/100% keyframes and cubic(.18,1.32,.36,1); halo at 520ms over 1100ms; close at 720ms over 500ms; text at 1020ms over 760ms; footer at 1300ms over 740ms. Badge floats from 1620ms over a 4800ms cycle; halo pulses on a 4400ms cycle. Reproduce the 28 particle positions, durations, offsets, sizes and colours from v3. Cache badge/shadow artwork and static gradients; repaint animation layers independently. Pause ambient ticking when the application is backgrounded. Reduced motion shows the final layout immediately and removes particles and ambient movement.

Close fades out over 180ms and continues to the community. Learn more temporarily reads “More ways to earn WP coming soon” for 1800ms and then restores itself; it does not open a different modal. The existing server-confirmed lifetime award rule is unchanged: pending state explains processing, and +15WP appears only when confirmed.

| Before | After | Why |
| --- | --- | --- |
| Generic medal in a purple circle | Exact supplied transparent badge with prototype glow | Match the approved artwork |
| Simplified bounce and continuously moving full composition | Staggered v3 keyframes with isolated animated layers | Preserve timing and avoid unnecessary iOS rendering work |
| Different summary, footer and Learn more modal | Prototype copy, inline link and timed replacement | Match the requested interaction |
| Award opened with an unbundled Light font request | Bundled font matching the HTML fallback | Prevent a late font fetch and unstable text layout |

Checks: `test/profile_reward_screen_test.dart` verifies badge asset/size, title position, compact/tall/tablet/short-screen layouts, timed Learn more, close, delayed badge reveal and pending-vs-awarded copy. `CAPTURE_AWARD=true` exports local render screenshots to the system temp directory. Existing profile-confirmation tests protect save/skip/reward flow.

## Confirmation dialog host
ProfileConfirmationGate is mounted above the router in MaterialApp.builder. It must create ProfileConfirmationFlow's own Navigator/Overlay before rendering confirmation fields, tooltips and modal pickers. A MaterialApp(home: confirmation) test alone does not reproduce production ancestry. The regression test must mount the flow inside MaterialApp.builder and open, cancel, reopen and confirm the DOB picker without saving until Continue.
