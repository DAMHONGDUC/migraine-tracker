# The head diagram as one 3D block

The location step's head stops being two flat SVG views and becomes a single
model the user turns. Owner's call, 2026-09-17.

The rules that already govern this widget live in
[`lib/features/attacks/CLAUDE.md`](../lib/features/attacks/CLAUDE.md) ("The head
diagram"). Nothing here replaces them — every one of them still has to hold
after the change, and the sections below say how.

**What this costs, stated once.** An SDK bump, a new rendering stack, a model
pipeline, a fallback renderer and a test rewrite, for a step that lasts about
three seconds. It is worth it for two reasons and no others: the current head is
already unapproved artwork that has to be redone, and in 3D the pickable areas
are exact *by construction* rather than by a hand-traced curve that has to be
kept in step with a drawing.

## Decided up front

| Question | Answer | Why |
|---|---|---|
| How it is rendered | `flutter_scene` + a `.glb` model | The only package that loads GLB and raycasts into the same mesh it draws |
| The region set | The same 15, unchanged | A new region is a schema change: Drift converter, sync codec, doctor report, `HeadLocation` mapping and seven ARB files |
| The Front/Back tabs | Kept, as snap buttons | They carry the per-side count badge and are the VoiceOver door onto the answer |
| Flutter SDK | 3.44.5 → 3.47.2, in its own PR first | `flutter_scene` >= 0.21.0 needs 3.47 for Flutter GPU; 3.47.2 is the current stable |
| Where the model comes from | A Python script in `tool/`, stdlib only | Reproducible, reviewable as a diff, no Blender on the machine, no licence question |

## Why `flutter_scene` and not the others

| Package | Likes / last publish | GLB | Picking | Verdict |
|---|---|---|---|---|
| `flutter_scene` 0.23.0 | 336 / 2026-08-26, publisher `bdero.dev` | `Node.fromGlbAsset` at runtime | `Scene.raycast` returns the node that was hit | Chosen |
| `three_js` 0.3.0 | 74 / 2026-05 | Yes | three.js `Raycaster` port | Older, less used, and drags ANGLE in |
| `model_viewer_plus` | — | Yes | None | A WebView; cannot sit inside the log flow |

**336 likes is below this repo's ">1k likes" bar, deliberately.** No 3D package
clears it, and a WebView in the log flow is worse than an exception. This goes in
[`rules/DECISIONS.md`](rules/DECISIONS.md) the way `flutter_file_dialog`'s
exception did.

## The API this rests on — all of it verified

Every call below was read off the published API docs, not assumed. The plan has
no hand-waved step between a finger and a `HeadRegion`.

| Call | Signature | Used for |
|---|---|---|
| `Node.fromGlbAsset` | `static Future<Node> fromGlbAsset(String)` | Loading the head, once |
| `Node.getChildByName` | `Node? getChildByName(String)` | `region_occipitalL` → its node |
| `Node.name` | `String` | Reading the answer back off a hit |
| `Node.raycastable` | `bool` | `false` on the face features, so a brow never eats a tap |
| `Node.highlightColor` + `Scene.highlightStyle` | — | The selected outline, built in — may remove the material swap entirely |
| `Camera.screenPointToRay` | maps a position in a view (logical px, origin top-left) to a world ray | The tap → ray step |
| `Scene.raycast` | `SceneRaycastHit? raycast(Ray, {maxDistance, layerMask, where, includeInvisible})` | Nearest hit, or null |
| `SceneRaycastHit` | `node`, `distance`, `worldPoint`, `worldNormal`, `uv`, `barycentrics`, `triangleIndex`, `primitiveIndex` | `hit.node.name` is the answer |

```
tap at (187, 240) in a 345x428 view
   │
   ├─► camera.screenPointToRay((187, 240), viewport) ─► Ray
   ├─► scene.raycast(ray)      hit.node.name = "region_occipitalL", distance 0.42
   │                           skipped: "features" (raycastable: false)
   └─► _toggle(HeadRegion.occipitalL)          // a miss returns null, as today
```

## The GLB contract

**One mesh node per region, named `region_<enum name>`.** A ray hits a node, and
that node *is* the answer — which is how the owner's rule that the pickable areas
follow the drawing exactly survives the move to 3D. In 2D `HeadRegionGeometry`
guaranteed it by owning both the fill and the hit test; here the model owns both,
and nothing sits between them to drift.

One mesh with a triangle-to-region side table was the alternative, and it is
rejected: `Scene.raycast` hands back a `Node`, and `highlightColor` is per node,
so a side table would be a second owner of the same fact — the thing this
feature's rules exist to prevent.

| Node | Count | Notes |
|---|---|---|
| `region_<enum name>` | 15 | `region_crown`, `region_foreheadL`, … `region_nape` |
| `features` | 1 | Brows, eyes, bridge, lips. `raycastable: false` |

## Prerequisite: the SDK bump, on its own

| File | From | To |
|---|---|---|
| `.fvmrc` | 3.44.5 | 3.47.2 |
| `.github/workflows/ci.yml:25` | 3.44.5 | 3.47.2 |
| `.github/workflows/release-ios.yml:89` | 3.44.5 | 3.47.2 |
| `ios/Runner/Info.plist` | — | Flutter GPU flag |
| `android/app/src/main/AndroidManifest.xml` | — | Flutter GPU flag (Android only has to keep compiling) |

It touches every screen in the app, so it lands and is verified — `analyze.sh`
clean, tests green — before a line of the head work starts.

## Phases

**The artwork gate comes first, because it is the cheapest thing that can kill
the whole plan.** A revolved parametric head can read as an egg with a face
painted on, and finding that out after an SDK bump is finding it out three days
late. Phase 0 needs no Flutter, no package and no SDK: run the script, render a
still, look at it.

| # | What | Done when |
|---|---|---|
| 0 | **The model, and a still render of it.** `tool/head_model.py` + a plain PNG from four angles | The owner looks at it and says yes. **No** if it does not beat the current SVG |
| 1 | **The SDK bump**, its own PR | `analyze.sh` clean, tests green on 3.47.2 |
| 2 | **Spike**, throwaway branch: package added, the head rendered static in the location step | Three numbers: fps on a real device, what `flutter test` does when the widget is pumped, IPA delta |
| 3 | `HeadScene` + region highlight, static, front only | A saved attack's areas light up |
| 4 | Tap → raycast → region; tabs animate the 180° turn | A tap and a tile write the same answer |
| 5 | The display-only 2D fallback | Widget tests pass, and a device without Flutter GPU still draws a head |
| 6 | Drag to turn freely | Only if phase 4 shipped clean — see the risks |
| 7 | Tests, `analyze.sh`, docs | `attacks/CLAUDE.md` "The head diagram" rewritten in its own `docs:` commit |

## Four corrections to the first version of this plan

1. **Free drag is demoted to phase 6, behind a gate.** "The head never moves" is
   an owner's rule, and the person using this screen is mid-migraine. The win
   over the cross-fade is the animated half-turn showing that front and back are
   one object — that is phase 4 and needs no drag at all. Drag is polish, and it
   also has to clear the iOS back-swipe: the head starts `w24` from the screen
   edge and the system edge-pop zone is about 20pt, so there is 4pt between a
   turn and a route pop.
2. **The 2D fallback is display-only and never pickable.** A fallback that also
   hit-tests is a second owner of the geometry, and worse, it would mean every
   widget test exercises the fallback rather than the code that ships.
3. **The real guard on picking is a GPU-free unit test**, not a widget test: parse
   the shipped `.glb` in a Dart test, cast rays at known angles with plain maths,
   and assert the region — plus the node names equal `HeadRegion.values` in both
   directions. The nose once spent a release unpickable and was reported as
   missing rather than as broken; this is what catches that in CI.
4. **The model loads once, not per screen.** `Node.fromGlbAsset` is async and
   re-parses on every call. Hard rule 4 says nothing in the log flow waits, so the
   node is loaded into a Riverpod provider and kept; if the parse is measurable,
   the build-time `.fsceneb` conversion replaces it.

## Files

| File | Work |
|---|---|
| `tool/head_model.py` (new) | Builds the parametric head from the cut constants, splits it into 15 objects, writes glTF |
| `presentation/widgets/head_scene.dart` (new) | `SceneView`, the loaded node, per-region highlight, fixed camera |
| `presentation/widgets/head_pose_controller.dart` (new) | Yaw, and the animated snap to 0°/180° on a tab press |
| `presentation/widgets/head_diagram.dart` | Same API (`selected`, `view`, `onRegionTapped`); the SVG body is replaced, the 2D painter stays as the display-only fallback |
| `presentation/widgets/head_region_picker.dart` | Tabs become snap buttons; `view` is derived from yaw (`abs(yaw) < 90°` is front), so `HeadRegionGrid` is untouched |
| `presentation/widgets/head_region_geometry.dart` | Unchanged. It is the number source the model script reads, and the fallback renderer |
| `providers.dart` | The loaded head node, once |
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
| Turning the head | Two tabs, a 260ms cross-fade between two flat drawings | The same two tabs, animating a half-turn of one object |
| What a tap tests | `path.contains` on a 2D path | A ray against the mesh being drawn |
| Hidden areas | No such idea — each view is one flat sheet | The nape cannot be tapped while the face is turned forward |
| Head size while turning | Fixed | Fixed — the camera is set from the model's bounding sphere, so the "head never moves" rule holds |
| Regions | 15 | 15 |
| The detail screen | A still drawing at `primaryView` | A still 3D head at a fixed yaw. **It never turns on its own** — hard rule 3, the reader is photophobic |

## Risks

| Risk | Mitigation |
|---|---|
| The parametric head looks worse than the SVG | Phase 0, before anything else is spent |
| Grazing angles make the temples a smaller target than they are today — a regression against the very reason the tiles exist | Measure the projected area of `templeL` at yaw 0 in phase 3; if it is worse, the resting yaw moves off dead-centre |
| `flutter test` has no GPU, and `log_flow_test`, `attack_detail_test` and `screen_overflow_test` all pump this step | Phase 2 measures it; phase 5's display-only fallback is the answer, built the way `AttackLiveActivity` is — one interface, a real implementation and a no-op |
| The SDK bump regresses something far from this feature | Its own PR, merged and verified before the spike |
| App size | Measured in phase 2. `flutter_scene` rides on Flutter GPU rather than shipping its own GL stack, which is most of why it was chosen over `three_js` |
| Flutter GPU fails to initialise on a device | The fallback again, and it must not reach the bootstrap error screen — a head that cannot be drawn is not a broken build |

## Checked and found not to be a risk

| Worry | Finding |
|---|---|
| The share card captures the head into a PNG, and a GPU texture may not capture | `AttackShareCard` prints the region *label* only. It never draws the head |
| `HeadRegion.crown` belongs to both views and would need drawing twice | One node on one object. The dual membership now only means "listed in both tile grids", which is what `HeadRegionGrid` already reads it as |
