# The head diagram as one 3D block

The location step's head stops being two flat SVG views and becomes a single
model the user spins. Owner's call, 2026-09-17.

The rules that already govern this widget live in
[`lib/features/attacks/CLAUDE.md`](../lib/features/attacks/CLAUDE.md) ("The head
diagram"). Nothing here replaces them — every one of them still has to hold
after the change, and the sections below say how.

## Decided up front

| Question | Answer | Why |
|---|---|---|
| How it is rendered | `flutter_scene` + a `.glb` model | Only package that loads GLB and raycasts into the same mesh it draws |
| The region set | The same 15, unchanged | A new region is a schema change: Drift converter, sync codec, doctor report, `HeadLocation` mapping and seven ARB files |
| The Front/Back tabs | Kept, as snap buttons | They carry the per-side count badge and are the VoiceOver door onto the answer |
| Flutter SDK | 3.44.5 → 3.47.x, in its own PR first | `flutter_scene` >= 0.21.0 needs 3.47 for Flutter GPU |
| Where the model comes from | A Python script in `tool/`, stdlib only | Reproducible, reviewable as a diff, no Blender on the machine, no licence question |

## Why `flutter_scene` and not the others

| Package | Likes / last publish | GLB | Picking | Verdict |
|---|---|---|---|---|
| `flutter_scene` 0.23.0 | 336 / 2026-08-26, publisher `bdero.dev` | `Node.fromGlbAsset` at runtime | Raycast built in: subtree filter, layer mask, `Node.raycastable`, predicate | Chosen |
| `three_js` 0.3.0 | 74 / 2026-05 | Yes | three.js `Raycaster` port | Older, less used, and drags ANGLE in |
| `model_viewer_plus` | — | Yes | None | A WebView; cannot sit inside the log flow |

**336 likes is below this repo's ">1k likes" bar, deliberately.** No 3D package
clears it, and a WebView in the log flow is worse than an exception. This goes in
[`rules/DECISIONS.md`](rules/DECISIONS.md) the same way `flutter_file_dialog`'s
exception did.

## The GLB contract

**One mesh node per region, named `region_<enum name>`.** A ray hits a node, and
that node *is* the answer — which is how the owner's rule that the pickable areas
follow the drawing exactly survives the move to 3D. In 2D
`HeadRegionGeometry` guaranteed it by owning both the fill and the hit test; here
the model owns both, and nothing sits between them to drift.

```
drag 38pt ─► yaw 142°        tap at (187, 240) in a 345x428 box
   │                              │
   └──────────────────────────────┴─► scene.raycast(ray)
                                        hit: node "region_occipitalL", t = 0.42
                                        skipped: node "features" (raycastable: false)
                                      ─► _toggle(HeadRegion.occipitalL)
```

| Node | Count | Notes |
|---|---|---|
| `region_<enum name>` | 15 | `region_crown`, `region_foreheadL`, … `region_nape` |
| `features` | 1 | Brows, eyes, bridge, lips. `raycastable: false`, so a feature never eats a tap |

A test reads the node names out of the shipped `.glb` and compares them to
`HeadRegion.values` — equal in both directions. The nose spent a release
unpickable and was reported as missing rather than as broken; a name that does
not match is the same failure, and this is what catches it in CI instead.

## Prerequisite: the SDK bump, on its own

| File | From | To |
|---|---|---|
| `.fvmrc` | 3.44.5 | 3.47.x |
| `.github/workflows/ci.yml:25` | 3.44.5 | 3.47.x |
| `.github/workflows/release-ios.yml:89` | 3.44.5 | 3.47.x |
| `ios/Runner/Info.plist` | — | Flutter GPU flag |
| `android/app/src/main/AndroidManifest.xml` | — | Flutter GPU flag (Android only has to keep compiling) |

It touches every screen in the app, so it lands and is verified — `analyze.sh`
clean, tests green — before a line of the head work starts.

## Phases

| # | What | Done when |
|---|---|---|
| 0 | **Spike, on a throwaway branch.** SDK bumped, package added, a cube rendered in the location step | Three numbers reported: fps on a real device, what `flutter test` does when the widget is pumped, IPA size delta |
| 1 | `tool/head_model.py` → `assets/models/head.glb`, 16 nodes | Node-name test passes |
| 2 | `HeadScene`, read-only, wired into the detail screen's `_LocationDiagram` | A saved attack's areas light up at a fixed yaw, nothing spins on its own |
| 3 | Interaction: drag → yaw, tap → raycast, tab → snap | A tap and a tile still write the same answer |
| 4 | The 2D fallback | Widget tests pass, and a device without Flutter GPU still draws a head |
| 5 | Tests rewritten, `analyze.sh`, docs | `attacks/CLAUDE.md` "The head diagram" rewritten in its own `docs:` commit |

**Phase 0 gates the rest.** If the fps or the test result comes back wrong, the
plan changes there, not at phase 4.

## Files

| File | Work |
|---|---|
| `tool/head_model.py` (new) | Builds the parametric head from the cut constants, splits it into 15 objects, writes glTF |
| `presentation/widgets/head_scene.dart` (new) | `SceneView`, GLB load, per-region material, fixed camera, lighting |
| `presentation/widgets/head_pose_controller.dart` (new) | yaw/pitch, snap to 0°/180° on a tab press, pitch clamped to ±20° |
| `presentation/widgets/head_diagram.dart` | Same API (`selected`, `view`, `onRegionTapped`); the SVG body is replaced, the 2D painter stays as the fallback |
| `presentation/widgets/head_region_picker.dart` | Tabs become snap buttons; `view` is derived from yaw (`abs(yaw) < 90°` is front), so `HeadRegionGrid` is untouched |
| `presentation/widgets/head_region_geometry.dart` | Unchanged. It is the number source the model script reads, and the fallback renderer |
| `pubspec.yaml` | `flutter_scene`, and `assets/models/` |

## The model script

The cuts are already the right numbers in the wrong coordinates. `_hairline = 62`
on the 200x248 box is latitude `+34°`; `_brow = 102` is `+7°`; `_centre = 100` is
longitude `0°`; `_templeEdgeL = 46` is `-52°`. The script reads them, revolves a
head profile, tags every triangle by (latitude band, longitude sector) and writes
one glTF mesh per tag — so the 3D areas and the 2D fallback come from one set of
constants rather than two.

A sculpted model can replace it later without a code change, as long as it keeps
the 16 node names.

## What changes for the user

| What | Before | After |
|---|---|---|
| Turning the head | Two tabs, a 260ms cross-fade between two flat drawings | Drag to spin; the tabs snap to 0° and 180°, badges unchanged |
| What a tap tests | `path.contains` on a 2D path | A ray against the mesh being drawn |
| Hidden areas | No such idea — each view is one flat sheet | The nape cannot be tapped while the face is turned forward |
| Head size while spinning | Fixed | Fixed — the camera is set from the model's bounding sphere, so the "head never moves" rule holds |
| Regions | 15 | 15 |
| The detail screen | A still drawing at `primaryView` | A still 3D head at a fixed yaw. **It never spins on its own** — hard rule 3, the reader is photophobic |

## Risks

| Risk | Mitigation |
|---|---|
| `flutter test` has no GPU, and `log_flow_test`, `attack_detail_test` and `screen_overflow_test` all pump this step | Phase 0 measures it; phase 4's fallback is the answer, built the way `AttackLiveActivity` is — one interface, a real implementation and a no-op |
| The SDK bump regresses something far from this feature | Its own PR, merged and verified before phase 0 |
| App size | Measured in phase 0. `flutter_scene` rides on Flutter GPU rather than shipping its own GL stack, which is most of why it was chosen over `three_js` |
| The 3D head is not approved artwork | The SVGs are deleted only after the owner approves the new head. `attacks/CLAUDE.md` already says the current one is not approved either |
