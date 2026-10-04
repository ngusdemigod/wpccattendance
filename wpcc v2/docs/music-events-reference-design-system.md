# Music Events Reference Design System

## Scope And Evidence

This is a reconstruction specification for the four mobile views in the two supplied images. It does not change WPCC application code, navigation, branding, or functionality.

References:
- A: `99ff0dbe1fd8f58d051d9647066afb2f.webp`, artist / events and artist / discography.
- B: `original-9f86dd34355239766d0d9f0cb1480596.webp`, discovery and filtered events / location sheet.
- Both supplied files are 1200 x 900 pixels. The white space surrounding the phones is presentation canvas, not application UI.

Reading this as: a premium mobile events product for music discovery, with artwork-led composition, dark tinted materials, compact rounded controls, and Apple-like hierarchy.

Audit dials: DESIGN_VARIANCE 4, MOTION_INTENSITY 3, VISUAL_DENSITY 5. These describe the reconstruction direction, not measured animation. The taste skill contributes audit, hierarchy, consistency, and anti-template judgment; its marketing layouts and React defaults do not apply to this Flutter product. The Apple skill contributes native interaction, materials, typography, and accessibility.

Evidence labels used below:
- **Measured:** image dimensions, sampled composite colors, approximate pixel bounding boxes.
- **Inferred:** original point size, font family, component radius, blur, opacity, source layers.
- **Specified:** a concrete starting implementation value or behavior chosen to make the system reproducible.

Bounding boxes are measured by inspection to about +/- 2 reference pixels. The WebP compression and antialiasing affect edge and color estimates. Fonts, opacity, blur, gradients, motion, and original technology cannot be recovered exactly from these flattened images.

**This is a replication baseline, not a claim of recovered original design tokens or a verified pixel-perfect implementation.**

## Audit Findings

1. **High: inconsistent date state.** B-right selects `12 May - 13 May`, groups results under `Thu, May 10`, and displays `May 27, 2025` in every row. A production implementation must derive filters, grouping, and metadata from the same event data. Reproduce those strings only in a visual reference fixture.
2. **Medium: faint secondary information.** Dates, inactive filters, locations, and dock icons appear low contrast. Artwork makes the effective background variable. Test actual foreground/background composites; do not assume a gray hex passes on glass. Use a more opaque material or brighter secondary text in the accessible product variant.
3. **Medium: controls need larger interaction regions.** Chip and streaming-link visuals are compact. Their apparent height is not proof of their hit target size. Preserve the visual silhouette while providing nonoverlapping targets of at least 44 logical pixels on iOS and 48 on Android.
4. **Medium: dock obscures content.** B-left's city cards continue behind the floating dock. The aesthetic is valid only if every card can scroll above the dock and safe area; reserve bottom content padding.
5. **Medium: icon meaning is not always clear.** The waveform could mean voice search, audio discovery, or listening. The abstract category pictures do not convey their category alone. Preserve category labels; give icon controls accessible names and desktop tooltips. Do not invent waveform functionality when applying the visual language elsewhere.
6. **Medium: truncation needs a full-content route.** The artist biography cuts off mid-sentence, while event titles vary substantially in length. Keep deliberate line limits for scanning, but offer complete information on the existing detail screen or an explicit expansion.
7. **Unverified: sheet behavior and accessibility.** A screenshot cannot establish focus trapping, dismissal, keyboard avoidance, scroll handoff, reduced motion, or VoiceOver support. These must be specified and tested rather than credited to the original design.

### What Works

- Photography and posters supply the emotion; interface chrome remains quiet.
- One left alignment line connects search, headings, rails, and lists.
- Repeated rows use stable thumbnail/date columns and compact metadata.
- Saturation is concentrated in artwork and small highlighted controls.
- Pill controls, rounded content containers, and circular utilities have distinct shape roles.
- Horizontal peeks communicate more content without explanatory text.
- White titles, subdued metadata, and stronger selected surfaces create a readable hierarchy at normal scale.

The system is **dark artwork-tinted frosted material**, not demonstrably Apple's Liquid Glass. There is no visible evidence of refraction or any particular native material implementation.

## How The Screens Can Be Built

The original toolchain is unknown. These could be Figma mockups or screens rendered by SwiftUI, UIKit, Flutter, or another framework. The images do not establish that a functioning app exists.

A plausible construction is:
1. A near-black full-viewport base.
2. One artwork-derived background tint layer, heavily blurred and darkened. B uses burgundy; A uses olive. These are contextual artwork hues, not separate page themes.
3. Sharp foreground photography, poster art, and album art. Do not blur the content images.
4. A bottom darkening overlay on the artist photograph and featured posters, allowing white text to remain readable.
5. Vertical scrolling content with independent horizontal rails.
6. Small translucent utility surfaces: search, chips, segments, and circular buttons.
7. Stronger translucent structural surfaces: dock and location sheet.
8. System safe areas. The status bar and home indicator shown in the mockups are not app widgets to recreate.

For Flutter, the dock or sheet can use `ClipRRect > BackdropFilter > DecoratedBox`, with sharp content painted after the filter. Keep the clip tight so blur does not affect an unintended region. Blur a standalone background image with `ImageFiltered` instead of using a full-screen backdrop filter. These distinctions and the performance tradeoff are documented in [Flutter's BackdropFilter API](https://api.flutter.dev/flutter/widgets/BackdropFilter-class.html).

Use existing native scroll, navigation, input, and gesture behavior. Custom materials do not require replacing the routing or state-management layer.

## Coordinate System

| Property | Reference image pixels | Reconstruction logical pixels |
| --- | ---: | ---: |
| Phone viewport | Approximately 335.5 x 727 | Assumed 393 x 852 |
| Sheet A-left origin | Approximately (227, 87) | (0, 0) |
| Sheet A-right origin | Approximately (637, 87) | (0, 0) |
| Sheet B-left origin | Approximately (226, 87) | (0, 0) |
| Sheet B-right origin | Approximately (637, 87) | (0, 0) |
| Content inset | 17-18 | 20 |
| Usable content width | Approximately 302 | 353 |
| Phone presentation corner | Approximately 34-36 | Approximately 40-42 |

The assumed 393 x 852 viewport fits the observed aspect ratio; it is not proof of a particular iPhone model. Conversion scale: `335.5 / 393 = 0.8536895674` reference pixels per logical pixel. Do not confuse this presentation downscale with device pixel ratio.

Convert a reference box with `logicalX = (referenceX - phoneOriginX) / scale`; likewise for Y, width, and height. For final matching, align each phone independently because their origins differ slightly between sheets.

A real app should fill its device viewport. Do not place the working application inside a white presentation board, fake phone frame, simulated status bar, or fake home-indicator bar.

## Layout And Spacing

Specified spacing scale: **4, 6, 8, 12, 16, 20, 24, 28, 32** logical pixels. The 6-pixel value supports dense list gaps; it is not a universal baseline grid recovered from the images.

- Page gutter: 20.
- Text / icon inline gap: 6.
- Chip / rail item gap: 8-12.
- Thumbnail-to-text gap: 12.
- Card inner padding: 12; sheet content padding: 20.
- Heading-to-content gap: 12-16.
- Section-to-section gap: 28-32.
- Title-to-streaming-links gap: 16; links-to-biography gap: 20-24.
- Main vertical content is left aligned. Center only glyphs, date tiles, category labels, and dock controls.
- Horizontal rails keep a next-item peek and use independent scrolling, not an auto-advancing carousel.
- Border strokes are inset and share the same clip as the surface. Avoid inconsistent one-pixel outer sizing changes.
- Reserve `safeArea.bottom + dockHeight + dockBottomGap + 16` for scrollable content beneath the dock.

### Reference Anchors

These are absolute `(x, y, width, height)` boxes on the supplied 1200 x 900 sheets. Text entries describe layout boxes, not recovered font metrics.

| View | Element | Approximate reference box |
| --- | --- | --- |
| A-left | Back / share buttons | (244, 146, 38, 38) / (508, 146, 38, 38) |
| A-left | Artist heading | (244, 371, 302, 40) |
| A-left | Streaming links | Starts at (244, 424), visual height 28 |
| A-left | Biography | (244, 470, 302, 51) |
| A-left | Segmented control | (244, 546, 302, 32) |
| A-left | First event row | (244, 595, 302, 63) |
| A-left | Second / third event rows | Y = 664 / 733, height approximately 62 |
| A-right | Artist heading | (655, 207, 302, 40) |
| A-right | Streaming links | Starts at (655, 258), visual height 28 |
| A-right | Biography | (655, 306, 302, 51) |
| A-right | Segmented control | (655, 381, 302, 32) |
| A-right | Album container | (655, 430, 302, 232) |
| A-right | Recent releases heading | Starts at (655, 685) |
| A-right | Album-art rail | Starts at (655, 726), first item approximately 146 wide |
| B-left | Search | (244, 152, 301, 38) |
| B-left | Filter rail | Starts at (244, 207), visual height 32 |
| B-left | Hot events heading | Starts at (244, 265) |
| B-left | Featured poster | (244, 295, 172, 215) |
| B-left | Next poster | Starts at X = 423; clipped by right viewport edge |
| B-left | Category heading | Starts at (244, 541) |
| B-left | Category art circles | Y = 570, diameter approximately 59, X step approximately 69 |
| B-left | Category labels | Starts around Y = 639 |
| B-left | Events by city heading | Starts at (244, 683) |
| B-left | City rail | Starts around (244, 713) |
| B-left | Floating dock | Approximately (311, 735, 152, 50) |
| B-right | Search / filter rail | (655, 152, 301, 38) / Y = 207 |
| B-right | Date heading | Starts at (655, 266) |
| B-right | Event rows | (655, 302, 302, 76), next Y = 385 / 467 |
| B-right | Location sheet | Approximately (644, 542, 322, 264) |
| B-right | Sheet grip | Approximately (791, 551, 28, 3) |
| B-right | Sheet search | Approximately (662, 569, 286, 38) |
| B-right | Popular Search heading | Starts at (662, 626) |
| B-right | City cards | Starts at (662, 662), approximately 127 x 128, gap 10 |

A-right's hero is absent from the visible view. This could be a scrolled/collapsed header or a separately composed tab state. Do not assume switching tabs must remove the photograph; confirm that behavior before implementation.

## Typography

### Family Identification

**Candidate, not verified:** SF Pro Rounded for the artist and large section headings; SF Pro Text / regular SF Pro for body and metadata. The large letters have soft terminals and an Apple-like proportion. SF Pro Display is a second comparison candidate if the rounded face does not match glyph outlines. Font identification from these compressed screenshots is not conclusive.

Apple documents SF Pro's optical sizes and rounded variant on its [fonts page](https://developer.apple.com/fonts/). That supports the candidate family, not attribution of this particular design.

On Apple platforms, compare the actual system face against the reference. Do not automatically bundle downloaded Apple fonts in Flutter web or Android; check the applicable font terms and target platform. Existing DM Sans is an acceptable WPCC adaptation fallback, **not a pixel-identical replacement**.

### Specified Type Scale

All sizes and line heights below are logical pixels under the assumed 393-wide artboard. Approximate displayed sizes equal logical size times 0.85369. Weight values are reconstruction choices. Letter spacing is **0 throughout**; any intrinsic optical spacing comes from the chosen font rather than a manual tracking adjustment.

| Token | Size / line height | Weight | Approximate displayed size | Usage |
| --- | --- | ---: | ---: | --- |
| artistTitle | 38 / 46 | 600 | 32.4 | Tyler, the Creator |
| largeSection | 28 / 34 | 600 | 23.9 | Date group, Popular Search, Recent Releases |
| section | 20 / 24 | 600 | 17.1 | Hot events, Category, Events by City |
| posterTitle | 17 / 23 | 500 | 14.5 | Featured event title, up to 3 lines |
| rowTitle | 16 / 21 | 500 | 13.7 | Event title, up to 2 lines |
| albumTitle | 17 / 22 | 600 | 14.5 | Album name |
| body | 15 / 21 | 400 | 12.8 | Artist biography, up to 3 lines |
| metadata | 14 / 18 | 400 | 12.0 | Date, city, album year and song count |
| control | 14 / 18 | 500 | 12.0 | Chips, streaming links, segments |
| trackTitle | 14 / 18 | 500 | 12.0 | Song title |
| categoryLabel | 13 / 17 | 500 | 11.1 | Category names |
| micro | 12 / 15 | 400 | 10.2 | Month, track number |
| badge | 12 / 15 | 600 | 10.2 | New |
| dateNumber | 16 / 20 | 500 | 13.7 | Day in venue date tile |
| systemTime | 17 / 22 | 600 | 14.5 | System chrome, not app content |

Use explicit text styles, not default Material typography. Set predictable line-height and font fallbacks. Match font metrics before adjusting spacing, because a changed font changes wraps, baselines, and component height.

Reference line rules: biography 3 lines with tail ellipsis; featured title up to 3; event row up to 2; metadata 1; chip 1. Production accessibility must allow rows/cards to grow with text scaling. Never shrink all text to force a large accessibility setting back into the reference fixture.

## Color System

### Measured Composite Samples

These are median RGB samples of flat regions, not recovered source-layer colors. They include backdrop, tint, opacity, and compression.

| Surface | Sample | Evidence region on source sheet |
| --- | --- | --- |
| Discovery page base | #151517 | B: (300, 523) to (500, 535) |
| Discovery upper burgundy | #3E1F23 | B: (775, 95) to (825, 105) |
| Discovery search composite | #3E2A31 | B: (460, 161) to (490, 182) |
| Discovery event-card composite | #231E1F | B: (920, 333) to (940, 348) |
| Location-sheet composite | #373639 | B: (920, 615) to (950, 625) |
| Dock edge composite | #404040 | B: (450, 746) to (459, 765) |
| Artist upper olive | #182411 | A: (775, 95) to (825, 105) |
| Artist event-card composite | #1E1C1A | A: (480, 615) to (510, 640) |
| Artist date-tile composite | #383934 | A: (258, 610) to (270, 620) |
| Album container composite | #25231D | A: (840, 455) to (920, 470) |
| Track-row composite | #292726 | A: (850, 573) to (925, 590) |

### Specified Semantic Palette

- background: #151517; artist background variant: #0C0C08.
- text.primary: #FAFAFA; secondary: #B5B3B5; tertiary: #929093.
- text.overArtwork: #FFFFFF, backed by a dark overlay.
- surface.cardFallback: #242224; trackFallback: #292726; sheetFallback: #373639; dockFallback: #404040.
- surface.selected: white at 10% above current background; inactive chip: white at 5%.
- border.subtle: white at 6%; top-edge highlight: white at 10%.
- context.discoveryTint: #3E1F23; context.artistTint: #182411.
- highlight gradient: #9E74F5 to #DB9860, left to right. This is an estimated reconstruction of Featured / New, not sampled source stops.
- category artwork anchor hues: orange #F15B16, violet #743FE8, blue #249CF0, green #08B86A, pink #E45A92. Artwork requires multiple shapes/shades, not five flat colored circles.
- Spotify / Apple Music marks: use supplied official brand assets, not generic glyph replacements or recolored library symbols.
- Focus: white 2-pixel outline, 2-pixel offset, visible against each material.

Secondary and tertiary tokens are a starting point, not a contrast certification. The accessible variant may require brighter values. Selected filters must have a non-color indicator such as weight, icon, and explicit selected semantics.

## Corners And Shape Roles

Radius values are **inferred starting values**, in logical pixels. The screenshot supports distinct roles, not one radius applied everywhere.

| Role | Radius | Approximate displayed radius | Application |
| --- | ---: | ---: | --- |
| Tiny image / date tile | 12 | 10.2 | Venue date tile, small event thumbnail |
| Track row | 12 | 10.2 | Album track item |
| Content card | 20 | 17.1 | Poster, city card, event list row, release artwork |
| Album group | 26 | 22.2 | Album overview container |
| Sheet top corners | 32 | 27.3 | Location picker; bottom edge follows device clipping |
| Dock shell | 32 | 27.3 | Floating navigation capsule |
| Search / chip / streaming link / segment | Height / 2 | Height / 2 | True capsule; never fixed radius independent of height |
| Utility / favorite / selected dock control | Diameter / 2 | Diameter / 2 | Circle |
| Outer mockup crop | Approximately 40-42 | Approximately 34-36 | Presentation only, not an in-app container |

Do not simulate continuous corners by stacking multiple mismatched outlines. Rounded rectangles are a baseline; use a continuous-corner shape if matching reveals a visible difference. Screenshots cannot identify the original corner algorithm.

## Icon System

The ordinary UI symbols resemble SF Symbols, but their source cannot be confirmed. Apple describes SF Symbols as designed to align with San Francisco on its [SF Symbols page](https://developer.apple.com/sf-symbols/). For WPCC adaptation, retain the existing Phosphor family; do not silently mix families.

Specified sizes: utility glyph 16, search 18, chip 14, metadata 13, segment 16, dock 22, favorite 18. Outline style is visually regular/light, approximately 1.5 logical pixels if using stroked SVG. Font icons use family weight rather than an independently adjustable stroke width.

| Meaning | Shape to match | Reference-style candidate | WPCC adaptation |
| --- | --- | --- | --- |
| Back | Thin left chevron | chevron.left | Existing Phosphor caret-left shape |
| Share | Up arrow emerging from tray | square.and.arrow.up | Existing Phosphor share/export shape |
| Search | Magnifying glass | magnifyingglass | Phosphor magnifying glass |
| Voice / audio action | Vertical waveform bars | waveform | Existing waveform asset; function must be confirmed |
| Featured / new | Small flame | flame.fill | Phosphor flame |
| Nearby / location | Filled map pin | mappin | Phosphor map pin |
| Newly added | Small clock | clock.fill | Phosphor clock |
| Date filter / metadata | Calendar | calendar | Phosphor calendar |
| Price | Tag | tag.fill | Phosphor tag |
| Favorite | Outline heart; filled when saved | heart / heart.fill | Phosphor heart regular / fill |
| Events segment | Confetti / party-popper shape | party.popper | Phosphor confetti |
| Discography | Album / records shape | square.stack candidate | Compare existing record/library glyph |
| Event row onward | Thin right chevron | chevron.right | Phosphor caret right |
| Home tab | Filled house | house.fill | Phosphor house fill |
| Tickets tab | Filled ticket | ticket.fill | Phosphor ticket fill |
| Profile tab | Filled bust | person.fill | Phosphor user fill |

Candidate symbol names describe the visual family, not proof of exact assets. Do not recreate logos or category illustrations by composing unrelated icons. Center glyphs optically; retain equal hit-target boxes even when glyph silhouettes have different widths.

## Materials, Overlays, And Depth

### Specified Starting Recipes

| Material | Fill above backdrop | Blur sigma, logical px | Border / highlight |
| --- | --- | ---: | --- |
| Search / ordinary chip | White 6% | 12 | None or white 4% |
| Selected segment | White 10% | 12 | None |
| Utility circle | White 8% | 12 | None |
| Event / album card | White 6% | 16 | White 6% inset stroke |
| Dock | #3A3A3C at 72% | 24 | White 8% stroke |
| Location sheet | #3B3B3D at 82% | 28 | White 8% top edge |

These recipes are guesses to calibrate against the measured composites, not uniquely recoverable filter values. Blur can be unnecessary for cards over an already-uniform background. Use the opaque fallback colors when transparency is reduced or rendering support is insufficient. Do not put a translucent foreground layer over another light translucent layer if text contrast suffers.

Shadows should be almost invisible on ordinary cards. Optional structural shadow for dock / sheet: black 22%, offset (0, 8), blur 24, spread 0. This is specified, not measured.

Artist photograph overlay starting stops, relative to hero height: black alpha 0.00 at 0%, 0.05 at 35%, 0.55 at 65%, 0.92 at 90%, 1.00 at 100%. Match the hero crop before tuning these stops. Poster lower overlay: transparent above 35%, black 25% at 65%, black 60% at 100%; the exact overlay must be tuned per original poster.

Keep background tints broad and artwork-derived. Do not add separate glowing orbs, animated blobs, or a gradient behind every component.

## Component Specifications

All dimensions are specified logical-pixel baselines. See reference anchors for the observed raster geometry. Do not use fixed text-card heights at large accessibility text sizes.

| Component | Geometry | Content rules |
| --- | --- | --- |
| Utility button | Visual diameter 44, target at least 44 | Back / share centered; no visible text label |
| Main search | Width = content width, height 44, capsule | Leading search icon, single-line placeholder, trailing waveform circle 32 |
| Filter chip | Visual height 36, horizontal padding 12, inline gap 6 | Single line, natural width, selected state; 44/48 target without overlapping neighbors |
| Streaming link | Visual height 32, horizontal padding 10, mark 16 | Official mark plus service name, 8 gap between links |
| Segmented control | Width 353, visual height 38, equal halves | Selected pill plus icon / label; keep content state per tab |
| Featured poster | Width 202, height 252, radius 20, next-item gap 8 | Full artwork; title bottom inset 12, date gap 4; favorite visual circle 32 at top-right inset 10 |
| Category item | Art diameter 68, column width 72, gap 8 | Label below art with 8 gap, centered; art is an asset, not a standard icon |
| City card | Width 148, minimum height 148, radius 20, gap 12 | City 16 medium; country 14 secondary; sharp skyline art anchored at bottom |
| Venue event row | Width 353, minimum height 74, radius 20, padding 12 | Date tile 48 square; month / day stack; title / location; right chevron |
| Date tile | 48 square, radius 12 | Month 12, day 16; centered stack |
| Search-result row | Width 353, minimum height 90, radius 20, padding 12 | Thumbnail 64 square, radius 12; gap 12; title up to 2 lines; metadata below |
| Album container | Width 353, minimum height 272, radius 26, padding 12 | Art 88 square; right-side badge / title / metadata; track rows below with 6-8 gap |
| New badge | Visual height 20, capsule, horizontal padding 8 | Small flame + New, gradient only here and Featured |
| Track row | Minimum height 42, radius 12, horizontal padding 12 | Number column 26; one-line track title; overflow ellipsis |
| Release artwork | 172 square, radius 20, gap 12 | Original square cover, no extra ornamental frame |
| Floating dock | 178 x 58 baseline, radius 32, padding 6 | Three equal control zones; selected circle 46, icon 22; bottom gap respects system safe area |
| Location sheet | Width viewport minus 16; top radius 32; reference visible height approximately 310 | Grip 32 x 4; inner gutter 20; search 44; large heading; horizontal city rail |

The mockup's dock has three destinations. That is part of the reference's information architecture, not permission to remove WPCC's five destinations. Likewise, music service links, ticket flows, and favorite controls are not implied WPCC features.

Nested track rows inside an album group are present in the reference. They are a specific track-group structure, not a general license to wrap every page section in additional cards.

## Artwork Inventory

Exact imagery is essential. A different crop or photograph will cause a larger visual difference than a one-pixel radius adjustment.

Required original assets:
- Tyler portrait with the visible chair, green hat, and vertical green backdrop.
- CHROMAKOPIA cover, pink-background release cover, and any additional release covers.
- Bad Bunny and j-hope event posters with their original printed typography.
- The Lumineers, Coldplay, and Linkin Park event thumbnails.
- Five abstract category illustrations; the originals contain layered forms and multiple shades.
- City skyline artwork for Manchester, Los Angeles, New York, and any further cards.
- Spotify and Apple Music brand marks.
- Exact font files or confirmed font-family / weight information, plus icon exports if available.

Use source images at suitable resolution, preserve aspect ratios, and define crop alignment for each component. Poster typography baked into the image should not be redrawn as live text. UI event titles above the lower overlay remain live text. A flattened screenshot is evidence, not a clean production asset pack.

## Interaction System

**No animation can be measured from these stills.** The following is an Apple-skill-informed specification, not a description of observed original behavior.

- Press feedback begins on pointer-down. Commit on release; allow cancellation by moving away.
- Normal button / favorite press: opacity or color change; optional scale 0.98, immediate onset, 120 ms release. No large ripple or delayed feedback.
- Segment indicator: critically damped spring, response approximately 0.25-0.30 seconds; input stays enabled; interrupted changes start from the current visible value.
- Sheet: direct 1:1 dragging, velocity-aware release, reversible dismissal; response approximately 0.30 seconds, damping ratio 1.0 by default. Slight momentum overshoot is optional, not mandatory.
- Horizontal rails: native momentum scrolling. No autoplay, forced tutorial, or looped animation.
- Detail navigation: native push / pop. Shared artwork transition only if it preserves clear spatial continuity and current routes.
- Reduced motion: eliminate slide, scale, overshoot, and parallax; preserve instant color feedback and short cross-fades.
- Reduced transparency: solid material fallbacks. Increased contrast: stronger borders and secondary ink.
- Favorites: immediate selected feedback with accessible state; revert and report a concise error if persistence fails. Implement only when the underlying product has that feature.
- Modal sheet: accessible name, contained focus, dismissal action, background interaction disabled, focus returned to opener; keyboard insets and internal scrolling respected. A nonmodal location panel would need a different focus contract, which is not established by the screenshot.

## Required States

These states are not visible in the references but are necessary for a complete implementation:
- Loading: static skeletons matching poster / row geometry; keep layout stable.
- Empty: short specific message and one relevant recovery action.
- Error: concise inline error and retry; avoid clearing filters or active tab.
- Selected: explicit selected semantics for filters, segments, dock, and favorites.
- Disabled: retain legibility and expose disabled semantics; do not hide functionality behind unexplained faint icons.
- Focus: visible outline that is not clipped by the rounded surface.
- Long content: defined truncation on previews, complete text on detail screens.
- Image failure: stable aspect-ratio placeholder; labels remain readable and actions remain usable.
- Large text / keyboard / rotation: grow layouts, scroll where needed, keep state and visible actions.

Flutter recommends screen-reader testing, sufficient contrast, and platform-appropriate target sizes in its [accessibility guidance](https://docs.flutter.dev/ui/accessibility).

## Responsive Contract

The references show only phones. Tablet behavior cannot be reverse-engineered from them.

For this existing project, any later adaptation must follow its established contract: phone below 600 local pixels; wider gutters / grids from 600; independent two-column sections at local width 900 or above. Preserve navigation, theme preference, state on rotation, installation gating, and existing logo / Phosphor icons. Do not add a desktop installation bypass or alter onboarding-specific design rules.

For phone matching, keep type sizes constant and use stable dimensions for art, icons, targets, and thumbnails. Let text content determine row height when required. Do not scale the entire application or font sizes with viewport width to force a screenshot match.

## Pixel-Matching Procedure

1. Obtain the original design file / inspectable component specs, clean artwork, exact fonts, and icon exports. Without these, promise a close reconstruction rather than exact recovered source values.
2. Build all four reference states with deterministic fixture data and no network-dependent imagery. Keep the date inconsistency only in this comparison fixture, not production logic.
3. Render at the assumed 393 x 852 logical viewport, fixed text scale 1.0, fixed locale, same renderer / platform and font availability.
4. Separate system chrome from application content. For presentation-only comparisons, system chrome can be part of the capture environment; never draw fake chrome in the working app.
5. Resample the capture to the measured phone crop once using the same method for every comparison. Align origins and outer clipping before judging internal geometry.
6. Compare a 50% overlay and an absolute image difference. Check anchor alignment, card dimensions, text baselines, wrapping, crop positions, radius silhouettes, then material composites.
7. Correct in this order: assets / crop, font / weight / metrics, layout geometry, corners / icons, colors / overlays, blur / shadow.
8. Geometry goal: approximately one reference pixel or less at major anchors. Antialiasing and WebP compression require a small color tolerance; do not claim zero pixel difference across different renderers.
9. Separately verify production behavior at 320, 393, 600, 768, and 1024 widths; text scaling 1.0 / 1.6 / 2.0; keyboard open; reduced motion; reduced transparency; contrast; screen reader; tap targets; scroll-under-dock clearance; tab / filter state preservation.

The supplied images provide no evidence for light mode. A light system would be a new design, not a recovered reference state.

## Deliverables And Boundaries

- This document: audit, construction explanation, visual specifications, states, and matching procedure.
- `music-events-reference.tokens.json`: machine-readable reconstruction tokens, with evidence / uncertainty recorded. This is a plain custom JSON structure, not an assertion of compliance with a token interchange standard.
- No application source was changed as part of this audit.
- The earlier purple medical-app reference is not used.
- These specifications do not authorize changing auth, profile confirmation, rewards, installation gating, API contracts, or backend data.

Exact original font selection, artwork files, layer opacities, blur kernels, native corner curves, dynamic sheet behavior, and implementation stack remain unverified. The next meaningful step for true pixel fidelity is inspecting the original source design and assets, not inventing more decimal precision.
