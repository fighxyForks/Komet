# iOS 26 native prototypes

Experimental, **off by default**. Gated by `IosGlass` + `AppIosGlass.nativeViews` (iOS 26+, Reduce Transparency off). Does **not** modify `native_liquid_glass`.

## Flags (Debug menu, iOS only)

| Flag | Pref key | Default |
|------|----------|---------|
| Native attachment sheet | `app_native_sheet_prototype` | off |
| Native tab minimize | `app_native_tab_minimize_prototype` | off |

## Prototype 1 — `UISheetPresentationController`

- Swift: `ios/Runner/KometNativeSheet.swift`
- Channels: `ru.komet.app/native_sheet`, `…/native_sheet_events`, `…/native_sheet_content`
- Presents a page sheet with **medium + large** detents and a grabber
- Hosts Flutter via `FlutterEngineGroup` + entrypoint `nativeAttachmentSheetMain` (`lib/native_attachment_sheet_main.dart`)
- Main isolate calls `presentAttachmentSheet`; on failure, `showAttachmentSheet` falls back to `showIosSheet`
- **Zoom:** when iOS 18+ `preferredTransition` is available, a transparent anchor view is placed at the Flutter source rect; otherwise the standard sheet transition is used (documented limitation)
- iOS 26 liquid-glass inset chrome on the sheet is system-provided when available; we do not call private APIs
- **Memory:** one extra Flutter engine while the sheet is open (lazy `FlutterEngineGroup`, destroyed on dismiss). Expect tens of MB while open; measure on device with Instruments

**Platform views on the attachment path:** 0 (sheet is a presented `UIViewController`, not a Flutter `PlatformView`).

## Prototype 2 — minimizing tab chrome + call accessory

- Swift: `ios/Runner/KometTabChrome.swift` (single `UiKitView`)
- Channels: `ru.komet.app/native_tab_chrome`, events for accessory/tab selection
- Flutter scroll deltas → `TabScrollHysteresis` → `setMinimized`
- Call accessory reads `CallController.isBusy` (tap posts back to Flutter)
- **UIKit note:** `UITabBarController.tabBarMinimizeBehavior` cannot drive our custom Flutter shell. Minimize is a **local transform animation** on the hosted `UITabBar` (public API only)
- One platform view hosts the tab bar and its accessory together (replaces `IosNativeTabBar` when the flag is on)

## How Ivan tests on an iOS 26 iPhone

1. Build/install a Debug build of this branch
2. Enable **iOS interface** (style) so glass is active
3. Open **Debug → feature toggles**, enable the two native prototypes
4. Attachment: open a chat → attach → confirm medium/large sheet + grabber; toggle flag off and confirm Flutter sheet returns
5. Tabs: on chat list, scroll down/up → tab bar should ease away/back; place a call and confirm the green accessory appears
6. Turn on **Reduce Transparency** → both prototypes must refuse native path

## App Store / API notes

- No private selectors or undocumented frameworks
- Public: `UISheetPresentationController`, `FlutterEngineGroup`, `UITabBar`, `UIView` transforms
- Zoom transition uses public iOS 18+ `UIViewController.preferredTransition` when the SDK provides it

## Next steps

- Host the full `AttachmentSheet` widget tree in the secondary engine (plugin registration + action relay)
- Optionally adopt system tab minimize if/when Flutter exposes a first-party UITabBarController shell
- Instrument engine RSS before/after present for a hard memory budget
