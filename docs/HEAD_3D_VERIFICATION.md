# Head interaction upgrade — verification

## Before and after

| Area | Before | After |
|---|---|---|
| Shape | Procedural face with floating eye/brow ribbons | Licensed Lee Perry-Smith scan, cropped and partitioned; facial landmarks stay in the visible surface |
| Gesture | `onHorizontalDragUpdate: _handleDrag` | `HeadGestureSurface(pose: _pose, onChanged: _changePose)` handles rotation and pinch without false taps |
| Camera | `PerspectiveCamera.framing(bounds, margin: 1.25)` | `HeadViewportUtils.camera(_bounds, _viewSize, widget.zoom)` shares the rendered viewport with raycasting |
| Pose | Yaw only | Yaw, pitch ±85°, zoom 1–2×; state never enters the attack record |
| Controls | Front/Back and region tiles | Same alternatives plus localized zoom out/in/reset controls in all seven locales |
| Model contract | Named region lookup | Reject missing/duplicate regions and unbounded/empty models before publishing the template |

## Evidence

| Check | Result |
|---|---|
| Asset | 575,620 bytes; 21,048 triangles; all 15 region IDs; embedded geometry; no external decoder |
| Export | Standard-library Python; preserved source checksum; exported bytes reproduce exactly |
| Scoped tests | 34 passed: head model, pose, gestures, picker, locale parity, About screen |
| Simulator | 2 integration tests passed on iPhone 17 Pro Max, iOS 26.4: all 15 regions reachable at 1×/2× across sampled poses, actual nose taps/misses, zoom/reset/drag, two independent read-only scenes, malformed model rejection |
| Static analysis | App CI analyzer and independent design-system analyzer: zero findings |
| Captures | `build/head_scene_review/head-front.png`, `head-zoom.png`, `head-profile.png`, `head-back.png`; render-tree captures because native iOS screenshot collection returned the launch overlay |
| Graph | GitNexus 1.6.12, schema-4 runner identity; generic `build`/method links overconnect unrelated processes. Verified source consumers are the attack picker, log/edit/detail diagrams, tests and About attribution. No backend behavior changed. |

## Remaining device acceptance

| Item | Status |
|---|---|
| Physical iPhone profiling: p95 frame time, cold load, memory, repeated opens | Not measured; no physical iPhone connected |
| Android GPU smoke test | Not run; no Android device connected |
| Full app offline/resume, VoiceOver and large Dynamic Type on device | Not yet validated end to end |
| Runtime render failure after a successful load | Existing renderer limitation; model-load failures use the tappable SVG fallback |
| Blender master | Not supplied; Python exports the preserved licensed scan reproducibly |

Run the scoped files with `fvm flutter test`, the simulator harness with `fvm flutter drive --driver test_driver/head_scene_driver.dart --target integration_test/head_scene_test.dart -d <device-id> --no-pub`, and `sh packages/system_design/tool/analyze.sh`. Do not substitute these results for physical-device performance acceptance.

## Rotation follow-up — 2026-09-18

| Before | After |
|---|---|
| `yaw + dx * 0.6` moved against the screen drag | `yaw - dx * 0.8` follows the finger |
| Pitch limited to ±25° | ±85° exposes crown and underside without inversion; yaw remains unrestricted |
| Every delta read `widget.pose`, potentially stale between frames | Gesture-local accumulation retains every delta and rebases on the next gesture |

The regression test failed against the prior implementation for direction/accumulation and the pitch limit. Camera projection assertions verify screen movement, not just angle signs.

Follow-up checks: 24 scoped tests and 2 iPhone simulator integration tests passed, including the ±85° poses. App and standalone design-system analyzers reported zero findings.
