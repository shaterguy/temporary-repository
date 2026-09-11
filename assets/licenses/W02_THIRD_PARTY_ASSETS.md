# W02 Third-Party Asset Provenance

This ledger is the admission gate for external art/audio used by the medieval rebuild. A file is not considered production-approved until its source, license, immutable upstream identity, local modifications, target identity, intended use, and validation state are recorded here.

## KayKit Medieval Hexagon Pack 1.0

- Author/publisher: Kay Lousberg / KayKit
- Upstream repository: `KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0`
- Upstream branch: `main`
- Pinned upstream commit: `84fa4e91af6a88989be7c99e0891cede11f2ca38`
- Pinned upstream tree: `79be3f757c62c3f6ea35a80ccd907b784b0ce69f`
- License: CC0 1.0 Universal (`LICENSE.txt` upstream blob `db3b53b5425c48afc0f606bfc0de84e51d834e95`)
- Redistribution: permitted under CC0; attribution is not required, but provenance is retained here for auditability.

### Existing W04 terrain and nature checkpoint

| Target file | Upstream blob | Local modification | Target Git blob | Intended use | State |
| --- | --- | --- | --- | --- | --- |
| `terrain/hex_grass.bin` | `eae1af657f2acffc11bace562df95a8f25e0e465` | None; byte-identical | `eae1af657f2acffc11bace562df95a8f25e0e465` | 2.5D terrain geometry | RUNTIME_INTEGRATED_VALIDATED |
| `terrain/hex_grass.gltf` | `b2a4608f8935afbbc3261dd71af015900d8ec925` | Atlas dependency removed; mesh/accessor/buffer layout retained; local rough moss PBR material | `b3adb9e6dcde1f1c39197f119fa7547cc927ebec` | MultiMesh terrain | RUNTIME_INTEGRATED_VALIDATED |
| `nature/tree_single_A.bin` | `a3baf092cbc2c649bbfc40b9ffe81d6b27dd60ea` | None; byte-identical | `a3baf092cbc2c649bbfc40b9ffe81d6b27dd60ea` | Forest geometry | RUNTIME_INTEGRATED_VALIDATED |
| `nature/tree_single_A.gltf` | `0c230093dab0c16d5dd65974917fd95bd119eb04` | Atlas dependency removed; geometry/UV/normal layout retained; local forest PBR color | `f5b591458fefc4b8aafc1eed374f1f20e06d7124` | Forest silhouette/shadow | RUNTIME_INTEGRATED_VALIDATED |
| `nature/rock_single_A.bin` | `f2201a5a7a3a7f9f41414134a093ca4223bee52f` | None; byte-identical | `f2201a5a7a3a7f9f41414134a093ca4223bee52f` | Rock geometry | RUNTIME_INTEGRATED_VALIDATED |
| `nature/rock_single_A.gltf` | `5f073d602b53ec59fd623f5c2962fc0e2627c37f` | Atlas dependency removed; geometry/UV/normal layout retained; local moonstone PBR color | `0351c8a02cafe1f8cd069610b2745f904ae0a0f4` | Rock silhouette/shadow | RUNTIME_INTEGRATED_VALIDATED |

Paths above are relative to `assets/third_party/kaykit_medieval_hexagon/`.

### W04 landmark, route, water, and elevation admission

All files below were initially copied from the pinned commit through remote GitHub Actions run `34589407338`. That import verified each downloaded file with `git hash-object` before bot commit `f3ecfceb4228284d4c22a66d47dc0f94cd920b28`. Binary geometry and PNG atlases remain byte-identical to upstream. Four GLTF descriptors were later modified only in PBR material factors after direct rendered review; their mesh/accessor/buffer/UV structure and paired BIN bytes remain unchanged.

| Target file | Upstream blob | Local modification | Target Git blob | Intended use | State |
| --- | --- | --- | --- | --- | --- |
| `landmarks/blue/building_home_A_blue.gltf` | `885c5741a74ac355cdf136d7d6753d0ac0eb0568` | None; byte-identical | `885c5741a74ac355cdf136d7d6753d0ac0eb0568` | Hamlet landmark | RUNTIME_INTEGRATED_VALIDATED |
| `landmarks/blue/building_home_A_blue.bin` | `e39e8b69221983fa326441b148cfe06318aa6720` | None; byte-identical | `e39e8b69221983fa326441b148cfe06318aa6720` | Hamlet geometry | RUNTIME_INTEGRATED_VALIDATED |
| `landmarks/blue/building_church_blue.gltf` | `df0c0308da6d739ecadefa731385d66b0e5cc916` | None; byte-identical | `df0c0308da6d739ecadefa731385d66b0e5cc916` | Chapel landmark | RUNTIME_INTEGRATED_VALIDATED |
| `landmarks/blue/building_church_blue.bin` | `7ed9f2419a33cc2cf6ddf88544939facb15ecf03` | None; byte-identical | `7ed9f2419a33cc2cf6ddf88544939facb15ecf03` | Chapel geometry | RUNTIME_INTEGRATED_VALIDATED |
| `landmarks/blue/hexagons_medieval.png` | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | None; byte-identical | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | Blue-building atlas | RUNTIME_DEPENDENCY_VALIDATED |
| `landmarks/neutral/building_bridge_A.gltf` | `df1ed184db0f1f8aade09280fd52017ff6fa3d6b` | None; byte-identical | `df1ed184db0f1f8aade09280fd52017ff6fa3d6b` | Central bridge landmark | RUNTIME_INTEGRATED_VALIDATED |
| `landmarks/neutral/building_bridge_A.bin` | `e069007b0a5ed7a05924353be9f591fe48032fe7` | None; byte-identical | `e069007b0a5ed7a05924353be9f591fe48032fe7` | Bridge geometry | RUNTIME_INTEGRATED_VALIDATED |
| `landmarks/neutral/hexagons_medieval.png` | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | None; byte-identical | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | Neutral-building atlas | RUNTIME_DEPENDENCY_VALIDATED |
| `terrain/roads/hex_road_A.gltf` | `1de60d28b32742161229764d00d969dc6284d2d3` | Texture retained; added `baseColorFactor=[0.34,0.42,0.30,1]`, roughness `0.82` after first landmark render review | `a22d8d4e300b46d617d22e78b235a19cd25b2261` | Crossroads route | RUNTIME_INTEGRATED_VALIDATED |
| `terrain/roads/hex_road_A.bin` | `518d3a050387bfedc7c145e74b44fd2e5c3e6fc5` | None; byte-identical | `518d3a050387bfedc7c145e74b44fd2e5c3e6fc5` | Road geometry | RUNTIME_INTEGRATED_VALIDATED |
| `terrain/roads/hexagons_medieval.png` | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | None; byte-identical | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | Road atlas | RUNTIME_DEPENDENCY_VALIDATED |
| `terrain/rivers/hex_river_A.gltf` | `befc84d61ce2e09865b4cf34f7ea3e31c925ad79` | Texture retained; added `baseColorFactor=[0.34,0.48,0.58,1]`, roughness `0.76` after first landmark render review | `c8af6d24008001a52edda75d6b59945d7886211f` | River route | RUNTIME_INTEGRATED_VALIDATED |
| `terrain/rivers/hex_river_A.bin` | `7b33f4ba61279278c723b3ebec6af57b6ac0e0ba` | None; byte-identical | `7b33f4ba61279278c723b3ebec6af57b6ac0e0ba` | River geometry | RUNTIME_INTEGRATED_VALIDATED |
| `terrain/rivers/hex_river_crossing_A.gltf` | `23353abf1cd8b6110a215d3f242edd2d9ea518f1` | Texture retained; added `baseColorFactor=[0.34,0.48,0.58,1]`, roughness `0.76` after first landmark render review | `c85cd1a5668d73196e0e32f22ac4808572c2f220` | Ford/crossing | RUNTIME_INTEGRATED_VALIDATED |
| `terrain/rivers/hex_river_crossing_A.bin` | `f6b94a4c839cb532d08c1582836ca2c36b1573d4` | None; byte-identical | `f6b94a4c839cb532d08c1582836ca2c36b1573d4` | Crossing geometry | RUNTIME_INTEGRATED_VALIDATED |
| `terrain/rivers/hexagons_medieval.png` | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | None; byte-identical | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | River atlas | RUNTIME_DEPENDENCY_VALIDATED |
| `terrain/elevation/hex_grass_sloped_high.gltf` | `08f88dc13291f32fb60cbdea94695fce9e482cd1` | Texture retained; added `baseColorFactor=[0.31,0.39,0.27,1]`, roughness `0.84`; runtime ridge moved beyond spawn view and scaled to `0.72` | `54300d517a8a22044f2959bad2804a24e17c751a` | Distant ridge/elevation break | RUNTIME_INTEGRATED_VALIDATED |
| `terrain/elevation/hex_grass_sloped_high.bin` | `4f491e464f6a8dd2d16fbd662fb4f5081d3d4d0c` | None; byte-identical | `4f491e464f6a8dd2d16fbd662fb4f5081d3d4d0c` | Ridge geometry | RUNTIME_INTEGRATED_VALIDATED |
| `terrain/elevation/hexagons_medieval.png` | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | None; byte-identical | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | Elevation atlas | RUNTIME_DEPENDENCY_VALIDATED |

### W04 runtime and visual evidence

Previous nature checkpoint:
- Source HEAD `47b69b323d5e38d0021a4b798bca866ac9eff75f`
- Actions run `34588158182`, Godot `4.7.2-stable`
- `r04-medieval-rebuild-field-v1`, 19 suites: PASS
- Actual 1280×720 main-shell + isolated field render: PASS
- Artifact `w04-render-34588158182-1`, ID `10194483061`, ZIP digest `sha256:734212be54c1b84d98830dd1f0c668bdc2c801b0fc0aeea0d9d9ec966ec91852`
- Direct visual readback: forest/rock silhouettes and shadows visible; legacy W13 world-art overlay absent.

First landmark composition, rejected as a visual-quality checkpoint:
- Source HEAD `3cc0bef2d7a605f036a9b3ffa7377615ecf69772`
- Actions run `34589811555`, job `103232260455`: import PASS, 19 suites PASS, actual render PASS, artifact upload PASS
- Artifact `w04-render-34589811555-1`, ID `10195150124`, ZIP digest `sha256:aa65d5469da31c22b5cd13ebe3420bd884b605c473a9d7b980ccc405921d42e5`
- Direct visual readback: bridge/hamlet were identifiable, but route/water tiles had a bright lime edge against the moss field and the spawn-visible high-slope ridge formed oversized repeated blocks. Technical PASS was therefore not accepted as visual-quality PASS.

Palette/ridge rework checkpoint:
- Source HEAD `e9992ab651e62b46f24d641323b3e52d5e5032d9`
- Actions run `34590205745`, job `103233509029`: import PASS, `r04-medieval-rebuild-field-v1` 19 suites PASS, actual 1280×720 render PASS, artifact upload PASS
- Artifact `w04-render-34590205745-1`, ID `10195302321`, ZIP digest `sha256:4c3e651f8ee7c1ab3d4a112c9af2c85e11508d00e377a2bf5cf213c195b78014`
- Directly inspected field PNG SHA-256 `db8ff8693707beaf3c91f312d9c0ff1f3407892d669a7f9ef988ccd4af229e9b`
- Directly inspected main-shell PNG SHA-256 `adb2ef8f42942104e7fdb5387c5851c656aeee55631b0150551319e97f3c62d4`
- Visual readback: oversized spawn-screen ridge blocks are gone; bridge, blue-roof hamlet, trees and rocks remain legible; route/water palette is materially less discordant. The hex-edge route pattern remains visually strong, so this is an accepted intermediate W04 wayfinding checkpoint, not final production-art approval.

`game/presentation/medieval_field_2_5d.gd` now composes 2,232 grass instances, deterministic nature clusters, a crossroads/river-ford pattern, bridge, chapel, east hamlet and distant ridge as a presentation-only 3D layer. Authoritative collision/spawn/campaign/save behavior remains in the existing 2D model and `CombatCamera` remains the focus source.

W04 remains incomplete: authoritative 2D collision/spawn alignment around visual landmarks, continuous multi-screen traversal evidence, enemy/projectile readability across the expanded field, culling/pooling/performance measurement, and broader route/elevation/material/decorative variety remain outstanding. This ledger state validates this import/render checkpoint only; it does not declare final graphics, final gameplay quality, release readiness, or AC-08 completion.

## Vetted but not yet imported

- KayKit Medieval Hexagon Pack larger building, coast, decoration, wall, and terrain variants: CC0; candidates for remaining W04 composition/density work.
- KayKit Character Pack: Adventurers: CC0; candidate for character/weapon presentation after skeleton/animation import compatibility is validated.
- Kenney RPG Audio, Impact Sounds, and Interface Sounds: CC0; candidates for W07. No audio file is production-integrated by this W04 checkpoint.

## Admission rules

1. Prefer official publisher/repository sources; mirrors or scraped asset hosts are not authoritative provenance.
2. Record license before copying bytes into the repository.
3. Record immutable upstream commit/tree/blob identity when available.
4. Record every material, geometry, audio, metadata, or format modification.
5. Store target content identity using Git blob SHA; add package checksums when upstream publishes them.
6. Runtime integration is separate from import. Validation state applies only to the exact source/checkpoint evidence recorded here.
7. Final representative art/audio requires new evidence under AC-07/AC-08; provenance or an intermediate W04 validation checkpoint alone does not satisfy those gates.
