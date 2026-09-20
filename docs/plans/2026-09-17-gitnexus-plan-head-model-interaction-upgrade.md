# GitNexus Engineering Plan
> Task: Improve HeadScene artwork, rotation, zoom and pain-region selection — Standard feature plan.
> Evidence: `d6761cdf84f7900397cfe2667bb6910dd5e400a2`; GitNexus unavailable, source-derived fallback; no PDG claims.
> Provenance schema 2; dirty digest `d5af755df90ea8f5c0338fbb8831ef4f2715eadfa4d7cc57303fe489fd140466`; 24 sorted cited paths; only this plan excluded.

## Objective (§1)
Deliver an authored, calm 3D head that users can rotate, zoom and tap to select multiple pain regions offline, without adding a log step.

## Current Behaviour (§2–3)
| Area | Before: verified source | After: proposed |
|---|---|---|
| Asset | `HeadSceneStore.asset = 'assets/models/head.glb'`; procedural `tool/head_model.py`; 424,884 bytes, 14,764 triangles, 15 region meshes + features + root | Blender master → validated GLB at the same asset path |
| Gesture | `onHorizontalDragUpdate: ... _handleDrag` in `head_scene.dart:223` | One scale-gesture path for yaw/pitch/pinch; tap is accepted only without drag/pinch |
| Camera | `PerspectiveCamera.framing(bounds, margin: 1.25)` at `head_scene.dart:173`; fixed after init | Stable rest-bounds framing plus explicit 1×–2× zoom; resize-aware camera and matching ray |
| Selection | `screenPointToRay` → `Scene.raycast` → `_regionOf` at `head_scene.dart:189`; `_toggle` orders values at `head_region_picker.dart:98` | Preserve mesh-derived picking, toggle behavior and persisted enum values |
| Fallback | `HeadDiagram` displays a tappable SVG while loading/on load failure | Keep offline fallback and named tiles; expose renderer capability so controls/side labels remain truthful |

## Findings (§4–5)
- [verified, source-derived] `HeadRegionPicker` owns yaw; `HeadDiagram` directly calls `HeadScene`; `LocationStep` and `LocationPickerSheet` use the picker; `_LocationDiagram` uses a read-only diagram. These are the source-confirmed caller paths, not a complete graph blast radius.
- [verified] `head_scene.dart:111–134` replaces imported materials; a better textured GLB alone will therefore lose its authored material appearance. Use geometry + normals as the primary visual upgrade and explicitly control material overrides.
- [verified] `_applyYaw` precedes `_frameCamera` (`head_scene.dart:90–92`); fit from immutable rest bounds before rotation to avoid initial-view-dependent framing. The current framing factory fits vertical FOV; portrait fitting must account for horizontal FOV too.
- [verified] `tool/head_model.py:24–41` copies region constants despite its header claiming to read them. Do not rely on that comment as geometric parity proof; existing model tests check names/primitives, not visible hit accuracy.
- [graph unavailable] MCP `query` and CLI `context HeadScene --repo .` failed: database version 43 versus runtime 42; `impact(HeadScene, upstream, depth=2)` returned `risk: UNKNOWN`, count null. Runner `.gitnexus/run.cjs` resolved CLI 1.6.12; stale/unknown analyzer provenance, no refresh or PDG run. Restore compatible tooling and run impact before implementation; no zero-risk claim.

## Proposed Changes (§6)
| Work | Contract and implementation |
|---|---|
| Art direction | Original neutral adult head, no neck/hair obstruction; smooth skull, recognizable brow/eye sockets/nose/cheek/jaw/ears in profile; matte `AppColors` surface with gentle directional shading, no bloom, skin photorealism or auto-spin. Selection uses primary tint plus selected-state text/check on tiles, not color alone. |
| Asset ownership | New `tool/head_model/head.blend`, `export_head.py`, README with source/license/export version; ship only `assets/models/head.glb`. Split a continuous surface into exactly `region_<HeadRegion.name>` objects after shaping; preserve matching seam positions/normals, apply transforms and export +Y up with the existing tested front/left convention. One optional `features` mesh is decorative; no hidden proxy hit mesh. |
| Region coverage | Every selectable surface belongs to exactly one of the existing 15 regions. Maintain underlying regional geometry beneath decorations; verify ear silhouettes do not raycast through to an unrelated far-side region. Add explicit boundary reference renders; preserve semantic region identity in the 2D fallback without claiming identical 2D/3D coordinates. |
| Export limits | Proposed budget: ≤25k triangles, ≤1 MiB GLB, embedded buffers, no animations/rig or decoder extensions. Start texture-free with smooth normals; preserve material independence per instance. Retire the old generator's production overwrite path once Blender export replaces it. |
| Pose ownership | Keep yaw/pitch/zoom together in picker presentation state; pass through `HeadDiagram` to `HeadScene`. Defaults: yaw from existing selection, pitch 0°, zoom 1×. One finger rotates 360° yaw with pitch clamped ±25°; two fingers zoom 1×–2× with fixed center and no pan/roll. View/grid remain derived from yaw. |
| Gesture arbitration | Replace horizontal-drag recognizer with scale start/update/end; record start pose and cumulative slop, cancel snap at gesture start, latch multiple-pointer participation until all pointers lift. Pinch/drag/cancel never invokes selection. Tap-up uses the currently rendered camera, viewport and pose. |
| Camera | Cache unrotated center/radius; rotate around that center, fit the tighter horizontal/vertical FOV at zoom 1×. Implement zoom by narrowing FOV from the baseline, keeping distance and valid clip planes; do not reuse a screen-space overlay to fake zoom. Resize recomputes fit; zoom may crop the outer silhouette intentionally, reset restores full fit. |
| Controls | Keep Front/Back tabs and region tiles; add localized zoom out/in/reset controls in reserved chrome outside excluded scene semantics. Buttons have ≥44pt targets; zoom buttons step 0.25×, reset restores current side's canonical yaw, pitch 0°, zoom 1×; tabs reset pitch and retain zoom. Disable animated snapping with Reduce Motion; no inertia or loops. |
| Fallback and detail | Keep the detail diagram read-only with default pose. Loading/failure never blocks recording; fallback uses its own mirrored side-label convention and hides unsupported orbit/zoom controls while tiles and SVG picking remain available. If fallback zoom is added later, transform drawing and hit coordinates together; it is not required for GPU-disabled devices in this scope. |
| Load/errors/localization | Validate duplicate/missing/empty region nodes before publishing `HeadSceneStore.template`; malformed assets fall back as a whole. Keep load-once behavior, selection on late load, mounted guards and per-scene materials. Log load, gesture completion, reset and errors with the flow tag, not per frame or health analytics. New text belongs in all seven ARBs. |

## Implementation Sequence (§7)
1. Restore compatible GitNexus runner/index; run upstream impact for each existing symbol before edits. Reconcile procedural-only/fixed-camera guidance in the actual feature file `lib/features/attacks/CLAUDE.md`; record the reason: authored geometry improves silhouette, intentional zoom preserves center. Commit any `AGENTS.md`/`docs/rules/` edits separately if needed; this planning run changes none.
2. Produce a Blender candidate and repeatable export, validate its contract, and capture front/45°/profile/back in the actual renderer with one selected temple. Review the concrete candidate before spending on final asset polish; do not treat an offline Python preview as device evidence.
3. Add pose math, camera fit and gesture arbitration; keep default arguments compatible with read-only callers. Build controls without shrinking/reflowing the head as selection or tabs change; verify short edit-sheet and large-text layouts.
4. Integrate the final GLB, materials, runtime validation/fallback and seven-locale strings; remove competing production asset generation. Verify loader/renderer failures, instance isolation, side labels and accessibility.
5. Run scoped tests and device checks below, then required analyzer and graph change analysis before any commit; commit locally only. Defer a renderer/SDK upgrade or compiled-asset pipeline until measured loading cost warrants a separate task.

## Test Strategy (§8)
| Layer | Scenarios and pass criteria |
|---|---|
| Existing unit/asset | Extend `head_model_test.dart` for uniqueness, finite/nonempty geometry, bounds and budgets; extend `head_pose_test.dart` for yaw 0/90/180, pitch limits, zoom 1/1.5/2, portrait fit and anatomical left/right. |
| Existing widget | Extend `head_region_picker_test.dart`: one tap toggles once; rotate/pinch never selects; tiles/model stay synchronized; snap interruption, reset, Reduce Motion, control semantics, unchanged viewport rect, short sheet/large text and fallback side labels. |
| New integration | New `integration_test/head_scene_test.dart`: real GPU selection on all 15 regions across view/zoom combinations, nearest visible hit, miss/occlusion, nose/crown/nape/ear boundaries, loading/failure, read-only detail, offline/resume and two simultaneous instances. Widget fallback tests do not prove GLB picking. |
| Device/performance | Profile on oldest supported physical iPhone plus a current iPhone; Android smoke check. Proposed gates: interaction p95 frame ≤16.7ms on 60Hz, selection highlight next frame, warm open no visible stall, cold load target ≤500ms; measure before claiming success. Record GLB bytes, triangles, load time, peak memory and repeated-open behavior. |
| Commands/status | `sh packages/system_design/tool/analyze.sh` passed with zero findings during planning. Run only scoped head test files during implementation (commands in §11); no tests/device runs were executed for this document. |

## Assumptions and Open Questions (§12)
| Item | Decision or remaining evidence |
|---|---|
| Visual direction | [assumed] Neutral, matte, original Blender artwork is the recommended default; actual screenshots must settle silhouette, contrast and boundary quality. No asset purchase or third-party service proposed. |
| Limits | [assumed] Zoom/pitch/performance budgets are prototype acceptance targets, not measurements; adjust after physical-device testing and record rationale. |
| Scope | Existing 15 region values, storage/sync and required logging steps stay unchanged. No neck, freehand pain painting, AR, background downloads or renderer migration. |
| Graph limitation | Risk remains UNKNOWN; source confirms listed callers but cannot establish exhaustive blast radius. Resolve runner provenance, then refresh with `node .gitnexus/run.cjs analyze --index-only --force` using a compatible engine; add `--pdg` only if needed. |
| Existing work | `ios/Runner/Info.plist` was already modified at start; preserve it. Feature `AGENTS.md` is absent; head-specific guidance currently lives in `lib/features/attacks/CLAUDE.md`. |
| Sources | Engine capability/reference: [flutter_scene 0.23.0](https://pub.dev/packages/flutter_scene/versions/0.23.0); installed camera implementation was checked. Asset workflow reference: [Blender glTF manual](https://docs.blender.org/manual/en/3.0/addons/import_export/scene_gltf2.html?highlight=gltf) search excerpt only; current exporter settings must be verified against installed Blender during implementation. |

## Definition of Done (§13)
Authored source + licensed/reproducible GLB; reliable rotate/zoom/multi-region selection; no drag/pinch false taps; correct anatomical labels and accessible alternatives; offline/load-failure fallback; stable log/edit/detail layouts; seven locales; scoped tests + real-device evidence; zero analyzer findings and resolved graph gates before commits.

## Implementation Context (§11)
```json
{
  "implementation_context": {
    "task_summary": "Improve HeadScene artwork with an authored GLB and add reliable rotation, zoom and pain-region selection. Standard feature plan; production code unchanged.",
    "evidence_provenance": {
      "schema_version": 2,
      "head_commit": "d6761cdf84f7900397cfe2667bb6910dd5e400a2",
      "generated_plan_path": "docs/plans/2026-09-17-gitnexus-plan-head-model-interaction-upgrade.md",
      "global_dirty_digest": {
        "algorithm": "sha256",
        "canonicalization": "gitnexus-evidence-provenance-v2 NUL-framed UTF-8 records",
        "value": "d5af755df90ea8f5c0338fbb8831ef4f2715eadfa4d7cc57303fe489fd140466"
      },
      "cited_path_manifest": [
        {
          "path": "PLAN.md",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:12b7dea8f80bb26ecc915a0c98157857001880d4f88e1cb4e402211a1262fb00",
          "index_digest": "sha256:12b7dea8f80bb26ecc915a0c98157857001880d4f88e1cb4e402211a1262fb00",
          "worktree_digest": "sha256:12b7dea8f80bb26ecc915a0c98157857001880d4f88e1cb4e402211a1262fb00",
          "untracked_digest": "absent"
        },
        {
          "path": "assets/models/head.glb",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:18038d0bb7247ab61e828e81b7dd2abbe5d64394f5af31505280f8bb0a60708c",
          "index_digest": "sha256:18038d0bb7247ab61e828e81b7dd2abbe5d64394f5af31505280f8bb0a60708c",
          "worktree_digest": "sha256:18038d0bb7247ab61e828e81b7dd2abbe5d64394f5af31505280f8bb0a60708c",
          "untracked_digest": "absent"
        },
        {
          "path": "docs/HEAD_3D_PLAN.md",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:a838f55a6851a9d44efcd494f72470e429a239b15ae68f0b1c1713e0b7512ccf",
          "index_digest": "sha256:a838f55a6851a9d44efcd494f72470e429a239b15ae68f0b1c1713e0b7512ccf",
          "worktree_digest": "sha256:a838f55a6851a9d44efcd494f72470e429a239b15ae68f0b1c1713e0b7512ccf",
          "untracked_digest": "absent"
        },
        {
          "path": "docs/rules/COMMANDS.md",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:f4dbd3061135b687583c4e8629a187a9583252edf8d2762882c09c5befccd0e2",
          "index_digest": "sha256:f4dbd3061135b687583c4e8629a187a9583252edf8d2762882c09c5befccd0e2",
          "worktree_digest": "sha256:f4dbd3061135b687583c4e8629a187a9583252edf8d2762882c09c5befccd0e2",
          "untracked_digest": "absent"
        },
        {
          "path": "docs/rules/DECISIONS.md",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:0c1639bc1a989699722388583bc4279121a0549238771211da6cbae92cfe6cfb",
          "index_digest": "sha256:0c1639bc1a989699722388583bc4279121a0549238771211da6cbae92cfe6cfb",
          "worktree_digest": "sha256:0c1639bc1a989699722388583bc4279121a0549238771211da6cbae92cfe6cfb",
          "untracked_digest": "absent"
        },
        {
          "path": "docs/rules/DESIGN_SYSTEM.md",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:8c229accf6c1d5b0a9970749822d1bdeafda58ccdf3ded9d93d93c24ba0160e8",
          "index_digest": "sha256:8c229accf6c1d5b0a9970749822d1bdeafda58ccdf3ded9d93d93c24ba0160e8",
          "worktree_digest": "sha256:8c229accf6c1d5b0a9970749822d1bdeafda58ccdf3ded9d93d93c24ba0160e8",
          "untracked_digest": "absent"
        },
        {
          "path": "docs/rules/TESTING.md",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:fdcdee24cefa83e01f41aa0234fb18d4b29516514a733b60cffc163bc0fc1f0c",
          "index_digest": "sha256:fdcdee24cefa83e01f41aa0234fb18d4b29516514a733b60cffc163bc0fc1f0c",
          "worktree_digest": "sha256:fdcdee24cefa83e01f41aa0234fb18d4b29516514a733b60cffc163bc0fc1f0c",
          "untracked_digest": "absent"
        },
        {
          "path": "lib/features/attacks/CLAUDE.md",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:b11c617f5f94c391eaea64f9b6ba18273eb6912d2e5b40811d55a4e9b6e79f6b",
          "index_digest": "sha256:b11c617f5f94c391eaea64f9b6ba18273eb6912d2e5b40811d55a4e9b6e79f6b",
          "worktree_digest": "sha256:b11c617f5f94c391eaea64f9b6ba18273eb6912d2e5b40811d55a4e9b6e79f6b",
          "untracked_digest": "absent"
        },
        {
          "path": "lib/features/attacks/domain/enums/head_region.dart",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:abcb6e3ee2a915f084bbb59f45c5a9cb1393cca77dfc14136c55a13fc307de2a",
          "index_digest": "sha256:abcb6e3ee2a915f084bbb59f45c5a9cb1393cca77dfc14136c55a13fc307de2a",
          "worktree_digest": "sha256:abcb6e3ee2a915f084bbb59f45c5a9cb1393cca77dfc14136c55a13fc307de2a",
          "untracked_digest": "absent"
        },
        {
          "path": "lib/features/attacks/presentation/screens/attack_detail_screen/attack_detail_screen_location_diagram.dart",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:2877989d62d5c1366ba8b88c258fdde67be539e07b42253bc54a4f72247b1b64",
          "index_digest": "sha256:2877989d62d5c1366ba8b88c258fdde67be539e07b42253bc54a4f72247b1b64",
          "worktree_digest": "sha256:2877989d62d5c1366ba8b88c258fdde67be539e07b42253bc54a4f72247b1b64",
          "untracked_digest": "absent"
        },
        {
          "path": "lib/features/attacks/presentation/widgets/head_diagram.dart",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:1eb15c23069cd7ef1d02baab66c70230bff8ff141e9da5a1b801ea01b4367605",
          "index_digest": "sha256:1eb15c23069cd7ef1d02baab66c70230bff8ff141e9da5a1b801ea01b4367605",
          "worktree_digest": "sha256:1eb15c23069cd7ef1d02baab66c70230bff8ff141e9da5a1b801ea01b4367605",
          "untracked_digest": "absent"
        },
        {
          "path": "lib/features/attacks/presentation/widgets/head_pose.dart",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:0c2fb4043f76c18b894d1899debbcff3f2aa16a72ad65cb62dafe944b69dac79",
          "index_digest": "sha256:0c2fb4043f76c18b894d1899debbcff3f2aa16a72ad65cb62dafe944b69dac79",
          "worktree_digest": "sha256:0c2fb4043f76c18b894d1899debbcff3f2aa16a72ad65cb62dafe944b69dac79",
          "untracked_digest": "absent"
        },
        {
          "path": "lib/features/attacks/presentation/widgets/head_region_grid.dart",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:0b4910d17e35f1fe5544e4a780f1df8a4295d2d21c8399e4064935212fc5fa2d",
          "index_digest": "sha256:0b4910d17e35f1fe5544e4a780f1df8a4295d2d21c8399e4064935212fc5fa2d",
          "worktree_digest": "sha256:0b4910d17e35f1fe5544e4a780f1df8a4295d2d21c8399e4064935212fc5fa2d",
          "untracked_digest": "absent"
        },
        {
          "path": "lib/features/attacks/presentation/widgets/head_region_picker.dart",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:eb8a67e48c0b1e7359163a5f41a811f885a668b057eb2b2b067a5963c038298a",
          "index_digest": "sha256:eb8a67e48c0b1e7359163a5f41a811f885a668b057eb2b2b067a5963c038298a",
          "worktree_digest": "sha256:eb8a67e48c0b1e7359163a5f41a811f885a668b057eb2b2b067a5963c038298a",
          "untracked_digest": "absent"
        },
        {
          "path": "lib/features/attacks/presentation/widgets/head_scene.dart",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:3788b9f7e6869f041ee6bdfe04d66adfe943f2ec094c17eff32d48035a9d7f37",
          "index_digest": "sha256:3788b9f7e6869f041ee6bdfe04d66adfe943f2ec094c17eff32d48035a9d7f37",
          "worktree_digest": "sha256:3788b9f7e6869f041ee6bdfe04d66adfe943f2ec094c17eff32d48035a9d7f37",
          "untracked_digest": "absent"
        },
        {
          "path": "lib/features/attacks/presentation/widgets/head_scene_store.dart",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:95a2569b9d5381ebd9b8e70ef71df55fed32aeddfcca20bb4cab0c4e81656723",
          "index_digest": "sha256:95a2569b9d5381ebd9b8e70ef71df55fed32aeddfcca20bb4cab0c4e81656723",
          "worktree_digest": "sha256:95a2569b9d5381ebd9b8e70ef71df55fed32aeddfcca20bb4cab0c4e81656723",
          "untracked_digest": "absent"
        },
        {
          "path": "lib/features/attacks/presentation/widgets/location_picker_sheet.dart",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:62aa92461642424836a32677290fd0d5dc8b788a6892ba61e10652a5f5c0122e",
          "index_digest": "sha256:62aa92461642424836a32677290fd0d5dc8b788a6892ba61e10652a5f5c0122e",
          "worktree_digest": "sha256:62aa92461642424836a32677290fd0d5dc8b788a6892ba61e10652a5f5c0122e",
          "untracked_digest": "absent"
        },
        {
          "path": "lib/features/attacks/presentation/widgets/location_step.dart",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:b136acc227ed5943d6aa25aecea3d66c9331f1c6cbd948aad65401ac649e3b40",
          "index_digest": "sha256:b136acc227ed5943d6aa25aecea3d66c9331f1c6cbd948aad65401ac649e3b40",
          "worktree_digest": "sha256:b136acc227ed5943d6aa25aecea3d66c9331f1c6cbd948aad65401ac649e3b40",
          "untracked_digest": "absent"
        },
        {
          "path": "packages/system_design/tool/analyze.sh",
          "object_kind": {
            "head": "absent",
            "index": "absent",
            "worktree": "absent",
            "untracked": "regular"
          },
          "state": "untracked",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "absent",
          "index_digest": "absent",
          "worktree_digest": "absent",
          "untracked_digest": "sha256:0eca69cd103c11257a36ef8e297e3556f1f6a95ec8681f11b92bde12be22bebd"
        },
        {
          "path": "pubspec.yaml",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:c4a220082e427bdd6fc135178b15ea8456b17391e93d0dced17bfcd791cf0091",
          "index_digest": "sha256:c4a220082e427bdd6fc135178b15ea8456b17391e93d0dced17bfcd791cf0091",
          "worktree_digest": "sha256:c4a220082e427bdd6fc135178b15ea8456b17391e93d0dced17bfcd791cf0091",
          "untracked_digest": "absent"
        },
        {
          "path": "test/features/attacks/head_model_test.dart",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:31efd3a1f36154e9247b34351f57521222e381155b7a733c05162781750836dd",
          "index_digest": "sha256:31efd3a1f36154e9247b34351f57521222e381155b7a733c05162781750836dd",
          "worktree_digest": "sha256:31efd3a1f36154e9247b34351f57521222e381155b7a733c05162781750836dd",
          "untracked_digest": "absent"
        },
        {
          "path": "test/features/attacks/head_pose_test.dart",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:eab69e0b4a6dea063ef0eaa384924ec4e687485cf040d2730d236efa4f3bda32",
          "index_digest": "sha256:eab69e0b4a6dea063ef0eaa384924ec4e687485cf040d2730d236efa4f3bda32",
          "worktree_digest": "sha256:eab69e0b4a6dea063ef0eaa384924ec4e687485cf040d2730d236efa4f3bda32",
          "untracked_digest": "absent"
        },
        {
          "path": "test/features/attacks/head_region_picker_test.dart",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:954b99c87455c123ea81151eaf50a68af672bf28bb4d20fcafd053cd7e1d932c",
          "index_digest": "sha256:954b99c87455c123ea81151eaf50a68af672bf28bb4d20fcafd053cd7e1d932c",
          "worktree_digest": "sha256:954b99c87455c123ea81151eaf50a68af672bf28bb4d20fcafd053cd7e1d932c",
          "untracked_digest": "absent"
        },
        {
          "path": "tool/head_model.py",
          "object_kind": {
            "head": "regular",
            "index": "regular",
            "worktree": "regular",
            "untracked": "absent"
          },
          "state": "clean",
          "rename_from": null,
          "rename_to": null,
          "head_digest": "sha256:7018e1a3b4224859ea66054f5d05cb3b73c5967494e8034e81fb317732d24205",
          "index_digest": "sha256:7018e1a3b4224859ea66054f5d05cb3b73c5967494e8034e81fb317732d24205",
          "worktree_digest": "sha256:7018e1a3b4224859ea66054f5d05cb3b73c5967494e8034e81fb317732d24205",
          "untracked_digest": "absent"
        }
      ]
    },
    "files_to_modify": [
      {
        "file": "assets/models/head.glb",
        "symbols": [],
        "intended_change": "Replace procedural artwork with the validated Blender export; retain 15 region node identities."
      },
      {
        "file": "tool/head_model/head.blend",
        "symbols": [],
        "intended_change": "New: editable master model outside bundled assets."
      },
      {
        "file": "tool/head_model/export_head.py",
        "symbols": [],
        "intended_change": "New: deterministic Blender export and asset-contract validation."
      },
      {
        "file": "tool/head_model/README.md",
        "symbols": [],
        "intended_change": "New: source/license, Blender version, coordinate contract, export recipe and preview checklist."
      },
      {
        "file": "tool/head_model.py",
        "symbols": [],
        "intended_change": "Retire production overwrite path; do not retain two GLB generators."
      },
      {
        "file": "lib/features/attacks/presentation/widgets/head_scene.dart",
        "symbols": [
          "HeadScene",
          "_HeadSceneState"
        ],
        "intended_change": "Apply pose and camera zoom, unified gestures, same-camera picking and per-instance materials."
      },
      {
        "file": "lib/features/attacks/presentation/widgets/head_pose.dart",
        "symbols": [
          "HeadPose"
        ],
        "intended_change": "Add pure pose/clamp/framing math; preserve tested anatomical side convention."
      },
      {
        "file": "lib/features/attacks/presentation/widgets/head_region_picker.dart",
        "symbols": [
          "HeadRegionPicker"
        ],
        "intended_change": "Own yaw/pitch/zoom, controls and animation cancellation; preserve selection ordering."
      },
      {
        "file": "lib/features/attacks/presentation/widgets/head_diagram.dart",
        "symbols": [
          "HeadDiagram"
        ],
        "intended_change": "Forward interaction state and expose actual 3D/fallback capability; keep fallback selection correct."
      },
      {
        "file": "lib/features/attacks/presentation/widgets/head_scene_store.dart",
        "symbols": [
          "HeadSceneStore"
        ],
        "intended_change": "Validate asset contract before exposing the cached template; degrade on failure."
      },
      {
        "file": "lib/features/attacks/presentation/widgets/head_region_grid.dart",
        "symbols": [
          "HeadRegionGrid"
        ],
        "intended_change": "Verify selected semantics and accessible targets within existing layout."
      },
      {
        "file": "lib/l10n/app_{en,vi,ja,de,es,fr,zh}.arb",
        "symbols": [],
        "intended_change": "Seven actual locale files: labels, tooltips, zoom status and gesture hint; regenerate through existing localization workflow."
      },
      {
        "file": "docs/HEAD_3D_PLAN.md",
        "symbols": [],
        "intended_change": "Update historical procedural-only/fixed-camera direction after implementation decisions land."
      },
      {
        "file": "lib/features/attacks/CLAUDE.md",
        "symbols": [],
        "intended_change": "Reconcile actual feature guidance: authored asset and intentional zoom retain a stable center; preserve no-neck and geometry-picking rules."
      }
    ],
    "tests": [
      {
        "file": "test/features/attacks/head_model_test.dart",
        "action": "extend",
        "scenarios": [
          "Exactly 15 unique region nodes, nonempty triangles, legal indices, finite positions/normals, embedded buffers only, no unsupported extensions",
          "Rest-pose origin/bounds/orientation and continuous seams; keep features non-pickable at runtime",
          "Asset size and triangle budget; validate source/license manifest"
        ]
      },
      {
        "file": "test/features/attacks/head_pose_test.dart",
        "action": "extend",
        "scenarios": [
          "Yaw 0/90/180/-90, pitch limits, zoom 1/1.5/2, aspect ratios and anatomical left/right",
          "Framing independent of initial selection and yaw; camera clip planes contain model at every allowed zoom",
          "Reset restores baseline pose; view snap uses shortest turn and retains zoom"
        ]
      },
      {
        "file": "test/features/attacks/head_region_picker_test.dart",
        "action": "extend",
        "scenarios": [
          "Tap toggles once; drag and two-finger pinch never toggle; second finger suppresses pending tap",
          "Tile and model share selection in enum order; rotate/zoom do not emit onChanged",
          "Controls outside excluded scene semantics; VoiceOver names/selected state; Reduce Motion disables animated turns",
          "Front/back retain viewport rect; short edit sheet and large text fit; fallback remains pickable with correct side labels"
        ]
      },
      {
        "file": "test/features/attacks/head_scene_interaction_test.dart",
        "action": "new",
        "scenarios": [
          "Test gesture-to-pose math without GPU; recompute camera/ray on viewport changes",
          "Loaded template is isolated across two scene instances; malformed model takes fallback",
          "Fallback transition during gesture cannot commit an accidental selection"
        ]
      },
      {
        "file": "integration_test/head_scene_test.dart",
        "action": "new",
        "scenarios": [
          "Real GPU model load, raycast visible points in all 15 regions across views and zooms, including nose/crown/nape",
          "Occluded far-side and background hits do not select; ear decorations do not pick through to far side",
          "Log flow, edit sheet, read-only detail, airplane mode, resume and repeated open/close",
          "iPhone device screenshots at yaw 0/45/90/180, zoom 1/2; profile startup/frame time; Android smoke check"
        ]
      }
    ],
    "verification_commands": [
      "sh packages/system_design/tool/analyze.sh",
      "fvm flutter test test/features/attacks/head_model_test.dart test/features/attacks/head_pose_test.dart test/features/attacks/head_region_picker_test.dart",
      "fvm flutter test test/features/attacks/head_scene_interaction_test.dart (after creation)",
      "fvm flutter test integration_test/head_scene_test.dart -d <connected-device-id> (after creation; use configured development build, never read secret files)"
    ],
    "assumptions": [
      "Proposed yaw 360 degrees, pitch -25 to +25 degrees and zoom 1 to 2 are initial usability values, not measured optimums.",
      "Original Blender-authored, neutral adult head with no neck; no paid asset or external service selected.",
      "Existing 15 HeadRegion values and persisted records remain unchanged.",
      "The existing build/head_preview.png is an offline preview, not evidence of device rendering."
    ],
    "open_questions": [
      "Art direction needs actual in-app front/profile/back review once a candidate exists.",
      "GitNexus risk UNKNOWN: CLI 1.6.12 and MCP cannot read storage version 43 using runtime 42; analyzer provenance unresolved, refresh skipped.",
      "Target oldest supported iPhone/device budget must be established in prototype; GPU render-failure fallback needs verification beyond load-time catches."
    ],
    "avoid": [
      "No production edits during planning; no new SDK, service, database migration or renderer upgrade in this plan.",
      "Never overwrite existing ios/Runner/Info.plist changes or read env/, env_assets/ or Generated.xcconfig.",
      "Never replace mesh picking with a projected ellipse, screen overlay or separately authored collider.",
      "Do not persist camera state as attack data, log pain selections to analytics, or add a required log step.",
      "Never run the whole test suite; never push; before implementation restore graph availability and run impact, and run detect_changes before any commit."
    ]
  }
}
```
