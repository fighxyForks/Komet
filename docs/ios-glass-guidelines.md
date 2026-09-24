# iOS glass budget and helpers

Rules for Flutter-drawn chrome when `IosGlass` is on. Goal: keep scroll jank low while preserving the glass look when the UI is idle.

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
| `showIosAlert` | Alert that prefers native liquid glass when available |
| `showIosSheet` | Modal sheet entry point for iOS chrome |
| `iosPageRoute` | Page route with iOS-appropriate transition |
| `IosSettingsScaffold` | Settings screen scaffold and navigation chrome |
| `IosTappable` | Press feedback without Material ink splash |

## Icons

Use `IosSymbols.*(context)` in build methods and other places with a `BuildContext`. Keep raw `Symbols.*` only for:

- `const` / static field initializers (no context)
- Brand or content glyphs with no SF equivalent
- The voice transcription pill glyphs (collapsed «→Т» / expanded chevron-up)

## Checklist before merging glass UI

- [ ] Platform-view count on the target screen is ≤ 2, none per row
- [ ] Scroll paths do not keep live blur over moving content
- [ ] New icons go through `IosSymbols` when a context is available
- [ ] `flutter analyze lib test` and `flutter test` are clean
