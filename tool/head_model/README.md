# Head model

| Item | Contract |
|---|---|
| Source | “Infinite, 3D Head Scan” by Lee Perry-Smith / [triplegangers.com](https://www.triplegangers.com/), distributed in the [three.js examples](https://github.com/mrdoob/three.js/tree/4500a366ccfd5a59aa2ed296c386fa42bb4edb8c/examples/models/gltf/LeePerrySmith) |
| License | [CC BY 3.0](https://creativecommons.org/licenses/by/3.0/); original notice in `source/LICENSE.txt`, bundled attribution in `assets/models/HEAD_LICENSE.txt` and the app's About screen |
| Original | `source/LeePerrySmith.glb`, SHA-256 `402b8a8ac9f03232e6d64b5962929703a069daf99d3c49ac8eb0e48bedc9c576` |
| Export | `python3 tool/head_model.py`; standard library only, no network or Blender required |
| Modifications | Crop shoulders/neck, close underside, split continuous visible geometry into 15 regions, normalize scale/center, use matte app materials; no textures or drawn facial ribbons |
| Output | `assets/models/head.glb`; software reference sheet at `build/head_preview.png` |
| Coordinates | Face +Z, up +Y, existing anatomical left -X; app camera/label projection is tested |
| Picking | Visible region meshes are the hit surface, including ears; preserve all existing `HeadRegion` IDs |
| Budget | ≤25,000 triangles, ≤1 MiB GLB, embedded buffers, no required decoder extensions |
| Boundaries | Plane clipping interpolates shared normals; regions meet without offset overlay meshes |
| Replacement | Owner rejected the procedural face on 2026-09-18. The scan replaces its geometry; interaction and persistence contracts remain unchanged. |

The preview is a software reference render. Validate front/profile/back, selected areas and zoom in the app renderer before accepting an export. `integration_test/head_scene_test.dart` produces render-tree captures in `build/head_scene_review/`; native iOS screenshots can capture the launch overlay instead.
