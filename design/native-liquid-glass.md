# Native Liquid Glass on iOS

The iOS 26+ Liquid Glass style uses `native_liquid_glass` 0.3.1 for selected navigation and control surfaces. The UI remains Flutter; the package does not convert Flutter children to UIKit controls.

Ported from fighxy/KometPro@028e316 onto `feature/FullStack`.

## Included

- Native backgrounds for chat header capsules, composer, search, message selection bars and call controls via `GlossyPill.nativeGlass` / `NativeGlassSurface`.
- Existing long presses, Lottie icons, text input, accessibility semantics and command callbacks remain Flutter-owned.
- Message bubbles, reactions, list rows and floating overlays are not converted.

Enable the Liquid Glass visual style in Settings → Appearance. On iOS 26+ the “System Liquid Glass” toggle switches native rendering on or off without changing the stored visual style.

## Compatibility

- iOS 26+ only; all other targets and older iOS keep Flutter rendering.
- Flutter >=3.41.2 / Dart >=3.11 are required by the dependency; CI uses Flutter 3.44.3.
- Compile with an iOS 26+ SDK. The minimum deployment target remains iOS 13.
- High contrast and reduced motion disable native rendering.
- Native theme follows the selected app theme; system mode clears the UIKit appearance override.
- Native surfaces fall back during route transitions and while custom overlays are visible.
- Theme reveal snapshots are skipped when native glass is enabled because Flutter snapshots do not capture UIKit surfaces.

## Verification on a physical device

1. Compare iOS 26+ native on/off with an older iOS and Android/desktop fallback.
2. Toggle Reduce Motion and high contrast. Check VoiceOver labels and large text.
3. Open/close search, message selection, composer attachments and a call.
4. Confirm draft text and focus persist after dismissing overlays.

A successful CI build does not establish visual correctness. Device QA is required before merging.
