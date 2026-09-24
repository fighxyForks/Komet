# Emoji panel

Standard Unicode emoji keyboard used by the composer sticker/emoji panel.

## Data

- Generator: `tool/generate_emoji_data.py`
- Asset: `assets/emoji_data.json` (Unicode Emoji **16.0**)
- Sources (Unicode License — https://www.unicode.org/license.txt):
  - `https://www.unicode.org/Public/emoji/16.0/emoji-test.txt` (fully-qualified only)
  - CLDR annotations `en` / `ru` (+ derived) via `unicode-org/cldr-json`
  - Merged with legacy `assets/emoji_keywords.json`
- Regeneration: `python3 tool/generate_emoji_data.py` (downloads into `/tmp/emoji-src` when missing)

Only base glyphs are stored in the grid (~1900). Skin-tone variants are kept on the entry for the long-press picker (default + five Fitzpatrick tones).

## Rendering

Plain `Text` with the system emoji font (Apple Color Emoji on iOS). No bundled Apple emoji images and no platform views. Cells are fixed-size lazy `SliverGrid` children with stable keys.

## Version filter

`EmojiVersionFilter` hides glyphs newer than the host OS ships. iOS uses `DeviceInfoPlugin` `systemVersion` major.minor (not major-only). Android uses API level. Desktop is capped at Emoji 15.0.

| Emoji | iOS | Android API |
|-------|-----|-------------|
| ≤11.x | any | any |
| 12.0 / 12.1 | 13.2 | 29 |
| 13.0 / 13.1 | 14.5 | 30 |
| 14.0 | 15.4 | 31 |
| 15.0 | 16.4 | 34 |
| 15.1 | 17.4 | 35 |
| 16.0 | 18.4 | 36 |

## UX notes

- Search: RU/EN keywords + names, prefix/word ranking
- Tabs: Recents, Unicode categories, Animated (server animoji)
- Long-press skin tones persisted per base glyph
- iOS mode: Cupertino search field, `IosTappable` highlight, `IosHaptics.selectionChange`, 44 pt tabs

Inline emoji suggestions while typing are intentionally out of scope for this change.
