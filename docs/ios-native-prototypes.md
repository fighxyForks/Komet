# iOS 26 native prototypes

Experimental, **off by default**. Gated by `IosGlass` + `AppIosGlass.nativeViews` (iOS 26+, Reduce Transparency off). Does **not** modify `native_liquid_glass`.

## Flags (Debug menu, iOS only)

| Flag | Pref key | Default |
|------|----------|---------|
| Native attachment sheet | `app_native_sheet_prototype` | off |
| Native tab minimize | `app_native_tab_minimize_prototype` | off |
| Native chat list | `app_native_chat_list_prototype` | off |
| Native calls & contacts | `app_native_lists_prototype` | off |

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
- **Budget:** 1 platform view for tab+accessory combined (replaces `IosNativeTabBar` when the flag is on). Chat list stays ≤ 2 PVs (folder strip may use another)

## Prototype 3 — UIKit chat list

Every expensive step happens off the main thread, and the main thread only applies finished results.

- Swift: `ios/Runner/KometChatList.swift` (platform view, navigation, diffable data source), `KometChatListCell.swift` (manual frame layout, no Auto Layout), `KometChatListModel.swift` (row decoding, preview text, avatar cache)
- Dart: `lib/core/native/native_chat_list_bridge.dart` (row model, diff, channel), `lib/frontend/native/native_chat_list_view.dart` (`UiKitView`)
- Channel: `ru.komet.app/native_chat_list/<viewId>` — Dart sends `apply` (`order` only when it changed, `rows` only for rows that changed) and `setChrome`; Swift sends `open`, `action`, `compose`, `menu`
- Dart stays the source of truth: `ChatListState` builds each row through the same `_rowFacts` as the Flutter row, so both lists show the same name, preview, draft and status. Swift only renders
- Swift decodes rows and builds the preview `NSAttributedString` on a serial background queue, then applies one diffable snapshot on main. Changed rows are reconfigured, not reloaded
- Avatars are downloaded, decoded and clipped to a circle off the main thread, cached in memory and in a `URLCache`; letter avatars use a seven-colour gradient palette
- `UINavigationController` hosts a large title, `UISearchController` (filters loaded chats by name) and two bar buttons that open the existing Flutter overflow and create menus
- Long press opens a `UIContextMenu`: mark read, pin, mute, archive, delete. Actions run the same Flutter handlers as the Flutter preview menu
- Only the chats tab uses it, and never in forward, share, archive or desktop split mode. Chat screens, menus and the tab bar stay Flutter

Not ported yet: stories, folders strip, archive entry, swipe actions, selection mode, online dots, typing, media thumbnails and message formatting in previews.

## Prototype 4 — UIKit calls and contacts

One generic native list drives both tabs. Dart describes the screen, UIKit renders it.

- Swift: `ios/Runner/KometNativeList.swift` — `UITableView` with a diffable data source inside a `UINavigationController`, custom cells laid out by frames. Avatars reuse `KometAvatarCache`
- Dart: `lib/core/native/native_list_bridge.dart` (sections, rows, row menus, diff, channel), `lib/frontend/native/native_list_view.dart`
- Channel: `ru.komet.app/native_list/<viewId>` — Dart sends `apply` (section layout only when it changed, rows only when they changed) and `setChrome`; Swift sends `tap`, `menu`, `button`, `segment`
- Chrome options: title, large title, a segmented control in the navigation bar, a local search field, a section index, bar buttons, loading and empty states
- Row menus become both the long-press `UIContextMenu` and, for destructive actions, the trailing swipe
- Calls: “All / Missed” segmented control, create and join rows at the top, long press or swipe to call back or delete
- Contacts: alphabetical sections with the side index, search by name, the bar button opens the existing search by phone or ID

## How Ivan tests on an iOS 26 iPhone

1. Build/install a Debug build of this branch
2. Enable **iOS interface** (style) so glass is active
3. Open **Debug → feature toggles**, enable the native prototypes
4. Attachment: open a chat → attach → confirm medium/large sheet + grabber; toggle flag off and confirm Flutter sheet returns
5. Tabs: on chat list, scroll down/up → tab bar should ease away/back; place a call and confirm the green accessory appears
6. Turn on **Reduce Transparency** → the sheet and tab prototypes must refuse native path
7. Calls and contacts: enable **Native calls & contacts**, switch All/Missed, swipe a call to delete, long-press to call back, scroll contacts with the side index, search by name
8. Chat list: enable **Native chat list**, scroll a long list, open a chat, long-press a row, search by name; send a message from another device and confirm the row moves to the top

## App Store / API notes

- No private selectors or undocumented frameworks
- Public: `UISheetPresentationController`, `FlutterEngineGroup`, `UITabBar`, `UIView` transforms
- Zoom transition uses public iOS 18+ `UIViewController.preferredTransition` when the SDK provides it

## Next steps

- Host the full `AttachmentSheet` widget tree in the secondary engine (plugin registration + action relay)
- Optionally adopt system tab minimize if/when Flutter exposes a first-party UITabBarController shell
- Instrument engine RSS before/after present for a hard memory budget
