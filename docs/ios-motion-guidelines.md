# iOS gestures and motion

Companion to [ios-glass-guidelines.md](./ios-glass-guidelines.md). Shared springs,
thresholds, and gesture arbitration for interactive UI. Values live in
`lib/frontend/motion/ios_motion.dart`. Semantic haptics: `ios_haptics.dart`.

## Spring presets (`IosMotion`)

| Preset | Role |
|--------|------|
| `soft` | Overdamped underlay / push / fly-off |
| `standard` | Default interactive settle (zoom) |
| `hero` | Critically damped photo hero open/close |
| `overlay` | Critically damped menu / message-actions appear |
| `dismissSnap` | Gallery dismiss snap-back |
| `bounce` | Light overshoot on lift |
| `press` | List press (SpringyTap) |
| `preview` | Chat preview grow |

Use `animateSpring(controller, target: …, velocity: …)` or `animateMatrixSpring`
for matrix zoom. Re-calling `animateSpring` mid-flight with
`velocity: controller.velocity` preserves momentum (no jump).

Route transitions that opt into physics override `TransitionRoute.createSimulation`
(Flutter 3.47+) so `PhotoHeroRoute` drives open/close with `SpringSimulation`
instead of timed curves. Durations (`heroOpen` / `heroClose`) are upper-bound
fallbacks when a simulation is not used.

## Gallery thresholds

| Constant | Value | Meaning |
|----------|-------|---------|
| `dismissDistanceDivisor` | 12 | Commit when `|dy| > height/12` |
| `dismissFlingVelocity` | 1000 px/s | Commit on vertical fling |
| `dismissDimPixels` | 80 | Background dim distance |
| `dismissChromePixels` | 50 | Chrome fade distance |
| `zoomSoftMax` / `zoomHardMax` | 3.0 / 3.6 | Soft limit; rubber-band ceiling |
| `doubleTapZoomScale` | 2.75 | Double-tap target scale |
| `singleTapDelay` | 200 ms | Deferred chrome toggle **only when** double-tap zoom is possible |
| `doubleTapEdgeInset` | 44 | Edge taps toggle chrome immediately |
| `galleryPageGap` | 20 | Visual gap between pages |

### Single-tap delay rule

Delay chrome toggle by `singleTapDelay` (200 ms) **only** when a double-tap zoom
can claim the second tap: zoomable still image, Reduce Motion off, and tap not
in the 44 pt edge inset. Otherwise toggle chrome immediately (videos already
use an immediate surface tap).

## Gesture arbitration (media viewer)

1. **Pinch / zoomed** (`scale > 1.01` or ≥2 pointers) wins over dismiss and paging.
2. **Vertical drag** at fit scale → interactive dismiss (`GalleryDismissDragRecognizer`).
3. **Horizontal drag** → page change (`PageView`).
4. **Double-tap** (within `singleTapDelay`, away from edges, when zoomable) → spring zoom to point / back to fit.
5. **Single tap** → chrome toggle (delayed only per rule above).

During dismiss drag: update `Transform` / opacity via `AnimatedBuilder` — do not rebuild the pager subtree. No live blur over the drag (see glass budget).

## Velocity handoff

- `GalleryDismissController.gestureVelocityY` stores the drag-end velocity (px/s).
  Do **not** read `animation.velocity` after a manual drag — it is typically ~0.
- Commit with a thumbnail: write `dismissMediaOffset` / `dismissMediaScale` /
  `dismissVelocityY` into `PhotoHeroController`, then pop. Reverse
  `createSimulation` feeds that velocity into the closing spring
  (toward animation value 0).
- Commit without a thumbnail: `flyOff(velocityY: …)` continues off-screen with a
  spring that starts at the gesture velocity.

## Swipe to reply

| Constant | Value |
|----------|-------|
| `replyTriggerIncoming` | 48 |
| `replyTriggerOutgoing` | 60 |
| `replyBandingStart` | 60 |
| `replyMaxVisual` | 120 |

Axis-locked leftward recognizer; rubber-band past banding start; heavy haptic
(`IosHaptics.swipeToReplyThreshold`) when crossing the trigger; spring snap-back.

## Hero transition

- Open / close: `IosMotion.hero` critically damped `SpringSimulation` via
  `PhotoHeroRoute.createSimulation`.
- Dim: `dimIn` 150 ms on open, `dimOut` 100 ms on close (as fractions of progress).
- Interactive dismiss hands offset / scale / velocity into reverse flight.

## Overlay appearance

Message actions (iOS mode) and glass menus use `IosMotion.overlay` springs.
Reversing mid-appear keeps `controller.velocity`. Scale morph is disabled under
Reduce Motion (fade only). Pair open with `IosHaptics.menuOpen` /
`IosHaptics.longPress`.

## Reduce Motion

Single helper: `IosMotion.reduceMotionOf(context)` →
`MediaQuery.disableAnimationsOf(context)`.

| Surface | Reduced behavior |
|---------|------------------|
| Hero | Cross-fade only (`SnapSimulation`); no zoom flight |
| Gallery dismiss snap-back | Instant reset |
| Gallery fly-off | Instant off-screen |
| Zoom / double-tap | Set matrix immediately |
| Overlays / menus | Fade only, no scale; instant if needed |
| Swipe-to-reply | No rubber-band; snap settle without spring |
| Page step (keyboard) | `jumpToPage` |
| `iosPageRoute` | Short cross-fade (`IosMotion.pageCrossFade`, 200 ms); no parallax (`delegatedTransition` is identity). Edge back-swipe still drives the route controller (opacity follows the drag). |
| `showIosSheet` | Same short duration via `sheetAnimationStyle` (Material sheet slide kept, no custom cross-fade). |

Haptics stay enabled under Reduce Motion (animations are cut, not feedback).

## Haptics map (`IosHaptics`)

Use under `IosGlass` paths instead of ad-hoc `Haptics` / `HapticFeedback`:

| Event | Feedback |
|-------|----------|
| `selectionChange` | selection click |
| `swipeToReplyThreshold` | heavy |
| `dismissThreshold` | medium (first cross of distance threshold) |
| `menuOpen` / `longPress` | medium |
| `toggle` | selection |
| `vote` | light |
| `warning` | medium |
| `itemActivate` | light |
| `destructiveActivate` | medium |
| `success` / `error` | composite patterns |

Under `IosGlass`, settings / glass controls / polls / NFC (and other wired iOS paths) call `IosHaptics`. Material / Android call sites keep using `Haptics` or raw `HapticFeedback` exactly as before. Chat send / media controllers and similar shared paths may still call `Haptics` directly until wired.

## Page routes

`iosPageRoute` returns `IosCupertinoPageRoute` in iOS mode. When `IosMotion.reduceMotionOf(context)` is true at push time, the route uses `pageCrossFade` and a fade transition (no horizontal slide / parallax). When false, behavior matches stock `CupertinoPageRoute`. Material mode still returns `MaterialPageRoute` unchanged.

## Root tab switch (`IosTabSwitcher`)

A root tab is built the first time it is opened and then stays mounted: hidden tabs sit in an `Offstage` with tickers off, so switching never reloads a tab or loses its scroll position. On a switch the new tab fades in over 0.1 s, then settles from a 3 pt smaller scale over 0.15 s; the old tab shrinks by the same 3 pt over 0.12 s and is hidden once the new one is opaque. Reduce Motion switches instantly.

## Testing checklist

- [ ] Gallery: dismiss commit vs snap-back; zoom blocks dismiss; double-tap zoom / unzoom
- [ ] Gallery: velocity handoff into hero; fly-off continues with fling velocity
- [ ] Gallery: page gap visible; neighbor images precache without spikes
- [ ] Video: scrubber thickens while dragging; seek debounced; hides with chrome; chrome tap is immediate
- [ ] Swipe-to-reply: incoming vs outgoing thresholds; vertical scroll not hijacked
- [ ] Hero: spring open/close; dismiss velocity feeds reverse spring
- [ ] Overlays: spring appear; reverse mid-flight keeps velocity; Reduce Motion = fade only
- [ ] Reduce Motion: hero cross-fade, no zoom flights, menus fade-only, reply snaps, page routes cross-fade
- [ ] `flutter analyze lib test` and `flutter test` clean
- [ ] Glass budget still respected on touched screens
