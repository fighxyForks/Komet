# iOS gestures and motion

Companion to [ios-glass-guidelines.md](./ios-glass-guidelines.md). Shared springs,
thresholds, and gesture arbitration for interactive UI. Values live in
`lib/frontend/motion/ios_motion.dart`.

## Spring presets (`IosMotion`)

| Preset | Role |
|--------|------|
| `soft` | Overdamped underlay / push |
| `standard` | Default interactive settle (hero-ish, zoom) |
| `dismissSnap` | Gallery dismiss snap-back |
| `bounce` | Light overshoot on lift |
| `press` | List press (SpringyTap) |
| `preview` | Overlay / preview grow |

Use `animateSpring(controller, target: …)` or `animateMatrixSpring` for matrix zoom.

## Gallery thresholds

| Constant | Value | Meaning |
|----------|-------|---------|
| `dismissDistanceDivisor` | 12 | Commit when `|dy| > height/12` |
| `dismissFlingVelocity` | 1000 px/s | Commit on vertical fling |
| `dismissDimPixels` | 80 | Background dim distance |
| `dismissChromePixels` | 50 | Chrome fade distance |
| `zoomSoftMax` / `zoomHardMax` | 3.0 / 3.6 | Soft limit; rubber-band ceiling |
| `doubleTapZoomScale` | 2.75 | Double-tap target scale |
| `singleTapDelay` | 200 ms | Deferred chrome toggle so double-tap can win |
| `doubleTapEdgeInset` | 44 | Edge taps toggle chrome only |
| `galleryPageGap` | 20 | Visual gap between pages |

## Gesture arbitration (media viewer)

1. **Pinch / zoomed** (`scale > 1.01` or ≥2 pointers) wins over dismiss and paging.
2. **Vertical drag** at fit scale → interactive dismiss (`GalleryDismissDragRecognizer`).
3. **Horizontal drag** → page change (`PageView`).
4. **Double-tap** (within `singleTapDelay`, away from edges) → spring zoom to point / back to fit.
5. **Single tap** → chrome toggle after `singleTapDelay` (cancelled by double-tap).

During dismiss drag: update `Transform` / opacity via `AnimatedBuilder` — do not rebuild the pager subtree. No live blur over the drag (see glass budget).

## Swipe to reply

| Constant | Value |
|----------|-------|
| `replyTriggerIncoming` | 48 |
| `replyTriggerOutgoing` | 60 |
| `replyBandingStart` | 60 |
| `replyMaxVisual` | 120 |

Axis-locked leftward recognizer; rubber-band past banding start; heavy haptic when crossing the trigger; spring snap-back.

## Hero transition

- Open / close durations: `heroOpen` (340 ms) / `heroClose` (300 ms) with `Curves.easeOutCubic` flight progress.
- Dim: `dimIn` 150 ms on open, `dimOut` 100 ms on close.
- Interactive dismiss can hand off offset / scale / velocity into reverse flight via `PhotoHeroController`.

## Overlay appearance

Message actions and glass menus use `Curves.easeOutCubic` (aligned with `IosMotion.preview` settle) instead of back-easing. Pair with a medium haptic on open.

## Testing checklist

- [ ] Gallery: dismiss commit vs snap-back; zoom blocks dismiss; double-tap zoom / unzoom
- [ ] Gallery: page gap visible; neighbor images precache without spikes
- [ ] Video: scrubber thickens while dragging; seek debounced; hides with chrome
- [ ] Swipe-to-reply: incoming vs outgoing thresholds; vertical scroll not hijacked
- [ ] Hero: open/close feel ~0.3–0.35 s; dismiss handoff into thumbnail
- [ ] Overlays: appear/disappear without harsh overshoot; haptics fire once
- [ ] `flutter analyze lib test` and `flutter test` clean
- [ ] Glass budget still respected on touched screens
