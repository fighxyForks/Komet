# iOS glass budget and helpers

Rules for Flutter-drawn chrome when `IosGlass` is on. Goal: keep scroll jank low while preserving the glass look when the UI is idle.


## Two-tier model (style vs native glass)

| Flag | Meaning | When true |
|------|---------|-----------|
| `AppIosGlass.styleSupported` / `supported` | Device can use the Flutter iOS look | Any iOS (deployment target 13+) |
| `AppIosGlass.active` / `IosGlass.of(context)` | User toggle on **and** style supported | Style tier: typography, SF symbols, metrics, Cupertino sheets/alerts, opaque chrome |
| `AppIosGlass.nativeGlassSupported` | OS can host `native_liquid_glass` UiKitViews | iOS 26+ only |
| `AppIosGlass.nativeViews` | Native platform views may be created | `active && nativeGlassSupported && !ReduceTransparency` |

**Which flag to use**

- Use `IosGlass.of(context)` for layout, typography, icons, hit targets, sheets, alerts, and Flutter-drawn chrome.
- Use `AppIosGlass.nativeViews` (or `NativeGlassGate`) **only** when constructing a `native_liquid_glass` widget (`LiquidGlassTabBar`, `LiquidGlassContainer`, `LiquidGlassAlert`, segmented control, …). Never assume `IosGlass.of` implies a UiKitView.
- On iOS 13–25 with style on: Flutter opaque/tinted surfaces (`IosPalette`, hairline separators). No `BackdropFilter` over scrolling content; style-tier glass helpers prefer opaque fills. Do not leave an empty `SizedBox` where a tab bar or control should be — use the Flutter fallback (`SlidingPillNav`, `GlassSegmentTrack`, Cupertino alerts).
- Material / Android / desktop: both tiers stay off.

## Glass budget

1. **At most 1–2 native platform views per screen** (tab bar, a glass menu, an alert, a segmented control). Never put a platform view in a list row or message bubble.
2. **No live `BackdropFilter` / `ImageFilter.blur` over scrolling content.** Chat list nav/FAB and chat composer use `forceOpaque` (or equivalent tinted fill) while scrolling, with a short idle hold (~120 ms) so chrome does not flicker between opaque and blur.
3. Prefer opaque or lightly tinted fallbacks during drag and ballistic scroll; restore blur only after scroll settles.
4. Use hysteresis for header / stories open-close thresholds so slow drags around the boundary do not flip-flop layout.
5. Prefer fixed extent and stable keys on long lists when row height is known.

## Helpers

| Helper | Role |
|--------|------|
| `IosMetrics` | Spacing and control sizes aligned with iOS metrics |
| `IosTypography` | Text styles (callout, list title/subtitle, tabular digits) |
| `IosSymbols` | SF-style icons in iOS mode; Material Symbols in Material mode |
| `IosSymbols.adapt` | Map a Material `IconData` key to the Cupertino glyph when iOS mode is on |
| `showIosAlert` | Alert that prefers native liquid glass when available |
| `showIosSheet` | Modal sheet entry point for iOS chrome |
| `iosPageRoute` | Page route with iOS-appropriate transition |
| `IosSettingsScaffold` | Settings scaffold with collapsing large title and scroll-edge bar |
| `IosTappable` | Press feedback without Material ink splash |

## Icons

Use `IosSymbols.*(context)` in build methods and other places with a `BuildContext`. Keep raw `Symbols.*` only for:

- `const` / static field initializers and data tables (no context); paint through `IosSymbols.adapt(context, icon)` or a shared tile that adapts
- Brand or content glyphs with no SF equivalent
- The voice transcription pill glyphs (collapsed «→Т» / expanded chevron-up)

Do not leave raw `Icon(Symbols…)` / `icon: Symbols…` paint paths that run in iOS mode without `adapt` or an `IosSymbols.*` helper.

## Message actions menu

In iOS mode the long-press actions sheet should read like a system context menu:

- Reaction strip above the menu
- Grouped rows with hairline separators
- Destructive actions in red, last, with a separator above the destructive group
- Trailing SF-style icons; label leading
- Row height ≥ 44 pt (`IosMetrics.minHitTarget`); body typography from `IosTypography`
- Preview bubble scales slightly on appear; keep Part 1 spring / Reduce Motion behavior

Prefer one Flutter-drawn frosted surface (no live blur over the chat, `GlassSuppression` held). Do not add a native platform view per row.

## Call controls

In iOS mode call buttons use Flutter-drawn glass (tint + rim + shadow) and `IosTappable` highlight — never Material `InkWell` ripple. Respect the platform-view budget: prefer one shared native glass container for a tight button **group**, or Flutter-drawn glass for spaced circular controls with labels (do **not** allocate one platform view per button). Targets ≥ 44 pt; expose VoiceOver labels via `Semantics` / tooltips.

## Settings large title

`IosSettingsScaffold` in iOS mode uses `CupertinoSliverNavigationBar` with a large title that collapses into the inline middle title on scroll. Scroll-edge behavior: transparent bar at the top, opaque/soft edge once content has scrolled under the bar. Material mode keeps `Scaffold` + `AppBar` / `ConnectionTitleBar` unchanged. Body widgets should be scrollable (`ListView`, `SingleChildScrollView`, …) so the large title can collapse.

## Accessibility

- **VoiceOver:** every icon-only control in chrome you touch needs a Russian label (`tooltip` on `IconButton`, or `Semantics(label: …)`). Prefer existing `AppLocalizations` strings when present.
- **Reduce Motion:** `IosMotion.reduceMotionOf` / `MediaQuery.disableAnimationsOf` — see [ios-motion-guidelines.md](./ios-motion-guidelines.md).
- **Increase Contrast:** `MediaQuery.highContrastOf` forces Flutter glass (`GlassBackground` and similar) into an opaque fill (no `BackdropFilter`).
- **Reduce Transparency:** Flutter 3.47 `AccessibilityFeatures` / `MediaQuery` still expose **no** `reduceTransparency` flag. Komet reads `UIAccessibility.isReduceTransparencyEnabled` via `ru.komet.app/accessibility` (+ event channel) into `IosReduceTransparency.enabled`. When on: `AppIosGlass.nativeViews` is false, `GlassBackground` / style chrome use opaque `IosPalette` fills (no `BackdropFilter`, no UiKitViews). Override with `IosReduceTransparency.debugOverride` in tests.

## Checklist before merging glass UI

- [ ] Platform-view count on the target screen is ≤ 2, none per row
- [ ] Scroll paths do not keep live blur over moving content
- [ ] New icons go through `IosSymbols` / `adapt` when painted in iOS mode
- [ ] Icon-only chrome has VoiceOver labels
- [ ] High contrast / Reduce Transparency force opaque glass fallback
- [ ] `flutter analyze lib test` and `flutter test` are clean

## Related

- Gestures and motion: [ios-motion-guidelines.md](./ios-motion-guidelines.md)
