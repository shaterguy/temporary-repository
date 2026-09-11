# W02 Third-Party Asset Provenance

This ledger is the admission gate for external art/audio used by the medieval rebuild. A file is not considered production-approved until its source, license, upstream identity, modifications, content identity, and intended use are recorded here.

## KayKit Medieval Hexagon Pack 1.0

- Author/publisher: Kay Lousberg / KayKit
- Upstream repository: `KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0`
- Upstream branch: `main`
- Upstream commit observed for this import: `84fa4e91af6a88989be7c99e0891cede11f2ca38`
- Upstream tree observed for this import: `79be3f757c62c3f6ea35a80ccd907b784b0ce69f`
- License: CC0 1.0 Universal (`LICENSE.txt` upstream blob `db3b53b5425c48afc0f606bfc0de84e51d834e95`)
- Redistribution: permitted under CC0; attribution is not required, but provenance is retained here for auditability.

| Target file | Upstream path / blob | Modification | Target Git blob | Intended use | State |
| --- | --- | --- | --- | --- | --- |
| `assets/third_party/kaykit_medieval_hexagon/terrain/hex_grass.bin` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/base/hex_grass.bin` / `eae1af657f2acffc11bace562df95a8f25e0e465` | None; byte-identical copy | `eae1af657f2acffc11bace562df95a8f25e0e465` | Runtime 2.5D terrain geometry | RUNTIME_INTEGRATED_VALIDATED |
| `assets/third_party/kaykit_medieval_hexagon/terrain/hex_grass.gltf` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/base/hex_grass.gltf` / `b2a4608f8935afbbc3261dd71af015900d8ec925` | Removed external atlas dependency; mesh/accessor/buffer layout retained; material replaced with a local rough PBR material and deepened to the W04 moss palette after rendered review | `b3adb9e6dcde1f1c39197f119fa7547cc927ebec` | Runtime 2.5D terrain projected through `MultiMeshInstance3D` | RUNTIME_INTEGRATED_VALIDATED |
| `assets/third_party/kaykit_medieval_hexagon/nature/tree_single_A.bin` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/decoration/nature/tree_single_A.bin` / `a3baf092cbc2c649bbfc40b9ffe81d6b27dd60ea` | None; byte-identical copy | `a3baf092cbc2c649bbfc40b9ffe81d6b27dd60ea` | Runtime forest-cluster geometry | RUNTIME_INTEGRATED_VALIDATED |
| `assets/third_party/kaykit_medieval_hexagon/nature/tree_single_A.gltf` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/decoration/nature/tree_single_A.gltf` / `0c230093dab0c16d5dd65974917fd95bd119eb04` | External atlas dependency removed; original mesh/accessor/buffer/UV/normal layout retained and material replaced with local rough forest-green PBR color | `f5b591458fefc4b8aafc1eed374f1f20e06d7124` | Runtime forest clusters, height silhouette and cast-shadow depth cue | RUNTIME_INTEGRATED_VALIDATED |
| `assets/third_party/kaykit_medieval_hexagon/nature/rock_single_A.bin` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/decoration/nature/rock_single_A.bin` / `f2201a5a7a3a7f9f41414134a093ca4223bee52f` | None; byte-identical copy | `f2201a5a7a3a7f9f41414134a093ca4223bee52f` | Runtime rock-cluster geometry | RUNTIME_INTEGRATED_VALIDATED |
| `assets/third_party/kaykit_medieval_hexagon/nature/rock_single_A.gltf` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/decoration/nature/rock_single_A.gltf` / `5f073d602b53ec59fd623f5c2962fc0e2627c37f` | External atlas dependency removed; original mesh/accessor/buffer/UV/normal layout retained and material replaced with local rough moonstone PBR color | `0351c8a02cafe1f8cd069610b2745f904ae0a0f4` | Runtime rock clusters and foreground/midground silhouette | RUNTIME_INTEGRATED_VALIDATED |

### W04 landmark, route, water, and elevation import

The following files were copied byte-identically from the same immutable KayKit upstream commit. The import workflow verified every downloaded file with `git hash-object` before committing it to the working branch. These assets are integrated by the W04 field composition in this source change, but their state remains pending the new runtime/render checkpoint until the corresponding Actions run is complete.

| Target file | Upstream path / blob | Modification | Target Git blob | Intended use | State |
| --- | --- | --- | --- | --- | --- |
| `assets/third_party/kaykit_medieval_hexagon/landmarks/blue/building_home_A_blue.gltf` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/buildings/blue/building_home_A_blue.gltf` / `885c5741a74ac355cdf136d7d6753d0ac0eb0568` | None; byte-identical copy | `885c5741a74ac355cdf136d7d6753d0ac0eb0568` | Runtime hamlet landmark | RUNTIME_INTEGRATED_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/landmarks/blue/building_home_A_blue.bin` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/buildings/blue/building_home_A_blue.bin` / `e39e8b69221983fa326441b148cfe06318aa6720` | None; byte-identical copy | `e39e8b69221983fa326441b148cfe06318aa6720` | Runtime hamlet landmark geometry | RUNTIME_INTEGRATED_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/landmarks/blue/building_church_blue.gltf` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/buildings/blue/building_church_blue.gltf` / `df0c0308da6d739ecadefa731385d66b0e5cc916` | None; byte-identical copy | `df0c0308da6d739ecadefa731385d66b0e5cc916` | Runtime chapel wayfinding landmark | RUNTIME_INTEGRATED_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/landmarks/blue/building_church_blue.bin` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/buildings/blue/building_church_blue.bin` / `7ed9f2419a33cc2cf6ddf88544939facb15ecf03` | None; byte-identical copy | `7ed9f2419a33cc2cf6ddf88544939facb15ecf03` | Runtime chapel geometry | RUNTIME_INTEGRATED_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/landmarks/blue/hexagons_medieval.png` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/buildings/blue/hexagons_medieval.png` / `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | None; byte-identical copy | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | Blue-building PBR atlas dependency | RUNTIME_DEPENDENCY_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/landmarks/neutral/building_bridge_A.gltf` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/buildings/neutral/building_bridge_A.gltf` / `df1ed184db0f1f8aade09280fd52017ff6fa3d6b` | None; byte-identical copy | `df1ed184db0f1f8aade09280fd52017ff6fa3d6b` | Runtime central stone bridge landmark | RUNTIME_INTEGRATED_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/landmarks/neutral/building_bridge_A.bin` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/buildings/neutral/building_bridge_A.bin` / `e069007b0a5ed7a05924353be9f591fe48032fe7` | None; byte-identical copy | `e069007b0a5ed7a05924353be9f591fe48032fe7` | Runtime bridge geometry | RUNTIME_INTEGRATED_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/landmarks/neutral/hexagons_medieval.png` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/buildings/neutral/hexagons_medieval.png` / `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | None; byte-identical copy | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | Neutral-building PBR atlas dependency | RUNTIME_DEPENDENCY_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/terrain/roads/hex_road_A.gltf` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/roads/hex_road_A.gltf` / `1de60d28b32742161229764d00d969dc6284d2d3` | None; byte-identical copy | `1de60d28b32742161229764d00d969dc6284d2d3` | Runtime crossroads route tiles | RUNTIME_INTEGRATED_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/terrain/roads/hex_road_A.bin` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/roads/hex_road_A.bin` / `518d3a050387bfedc7c145e74b44fd2e5c3e6fc5` | None; byte-identical copy | `518d3a050387bfedc7c145e74b44fd2e5c3e6fc5` | Runtime road geometry | RUNTIME_INTEGRATED_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/terrain/roads/hexagons_medieval.png` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/roads/hexagons_medieval.png` / `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | None; byte-identical copy | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | Road PBR atlas dependency | RUNTIME_DEPENDENCY_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/terrain/rivers/hex_river_A.gltf` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/rivers/hex_river_A.gltf` / `befc84d61ce2e09865b4cf34f7ea3e31c925ad79` | None; byte-identical copy | `befc84d61ce2e09865b4cf34f7ea3e31c925ad79` | Runtime river route tiles | RUNTIME_INTEGRATED_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/terrain/rivers/hex_river_A.bin` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/rivers/hex_river_A.bin` / `7b33f4ba61279278c723b3ebec6af57b6ac0e0ba` | None; byte-identical copy | `7b33f4ba61279278c723b3ebec6af57b6ac0e0ba` | Runtime river geometry | RUNTIME_INTEGRATED_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/terrain/rivers/hex_river_crossing_A.gltf` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/rivers/hex_river_crossing_A.gltf` / `23353abf1cd8b6110a215d3f242edd2d9ea518f1` | None; byte-identical copy | `23353abf1cd8b6110a215d3f242edd2d9ea518f1` | Runtime ford/crossing tile | RUNTIME_INTEGRATED_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/terrain/rivers/hex_river_crossing_A.bin` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/rivers/hex_river_crossing_A.bin` / `f6b94a4c839cb532d08c1582836ca2c36b1573d4` | None; byte-identical copy | `f6b94a4c839cb532d08c1582836ca2c36b1573d4` | Runtime ford/crossing geometry | RUNTIME_INTEGRATED_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/terrain/rivers/hexagons_medieval.png` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/rivers/hexagons_medieval.png` / `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | None; byte-identical copy | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | River PBR atlas dependency | RUNTIME_DEPENDENCY_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/terrain/elevation/hex_grass_sloped_high.gltf` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/base/hex_grass_sloped_high.gltf` / `08f88dc13291f32fb60cbdea94695fce9e482cd1` | None; byte-identical copy | `08f88dc13291f32fb60cbdea94695fce9e482cd1` | Runtime elevated ridge silhouette | RUNTIME_INTEGRATED_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/terrain/elevation/hex_grass_sloped_high.bin` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/base/hex_grass_sloped_high.bin` / `4f491e464f6a8dd2d16fbd662fb4f5081d3d4d0c` | None; byte-identical copy | `4f491e464f6a8dd2d16fbd662fb4f5081d3d4d0c` | Runtime elevated ridge geometry | RUNTIME_INTEGRATED_PENDING_W04 |
| `assets/third_party/kaykit_medieval_hexagon/terrain/elevation/hexagons_medieval.png` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/base/hexagons_medieval.png` / `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | None; byte-identical copy | `14cdc253646e4dba3cb7a267a6f7399b78ba2231` | Elevation PBR atlas dependency | RUNTIME_DEPENDENCY_PENDING_W04 |

The modified `.gltf` files in the original grass/nature checkpoint are not claimed to be byte-identical to upstream. Their paired `.bin` files are byte-identical. The W04 landmark/route/water/elevation files listed above are all byte-identical to the pinned upstream commit.

W04 previous runtime validation checkpoint:

- Candidate branch: `work/sr-20260911-medieval-rebuild`
- Validated source HEAD before the landmark/route expansion: `47b69b323d5e38d0021a4b798bca866ac9eff75f`
- GitHub Actions run: `34588158182` (`validate-field-composition`)
- Godot: `4.7.2-stable`
- Import: PASS
- Fast-test contract: `r04-medieval-rebuild-field-v1`, 19 suites, PASS
- Actual rendered output: 1280x720 main shell plus isolated 3D field, PASS
- Evidence artifact: `w04-render-34588158182-1`, artifact ID `10194483061`, ZIP digest `sha256:734212be54c1b84d98830dd1f0c668bdc2c801b0fc0aeea0d9d9ec966ec91852`
- Inspected field image SHA-256: `f503320beaa2563ae6290bf73f57b81ba395a4379260d0701f830a09a4304c93`
- Inspected main-shell image SHA-256: `a71f265b40e5894136285d828241842d71b5b310f8001231a7023767e617c51d`
- Visual readback: the initial expedition view contains visible forest and rock clusters, vertical silhouettes, and cast shadows; the previous W13 world-art overlay is suppressed by `main_shell_medieval_rebuild.gd`. This validates that earlier asset import and 2.5D render path, not the new landmark/route expansion and not final field quality.

`game/presentation/medieval_field_2_5d.gd` keeps the existing 2,232 KayKit grass instances and deterministic nature clusters, and now composes byte-identical KayKit road, river, crossing, bridge, chapel, hamlet, and sloped-grass assets as presentation-only wayfinding geometry. Gameplay authority remains in the existing 2D model and `CombatCamera` remains the camera focus source.

The W04 field is still incomplete. Gameplay collision/spawn alignment around visual landmarks, broader route/elevation variety, pooling/culling/performance measurement, and representative continuous-travel evidence remain outstanding. `RUNTIME_INTEGRATED_PENDING_W04` explicitly does not claim the new assets passed runtime/render validation yet.

## Vetted but not yet imported

- KayKit Medieval Hexagon Pack larger building, coast, decoration, wall, and terrain variants: CC0; candidates for the remaining W04 field composition and world-density work.
- KayKit Character Pack: Adventurers: CC0; candidate for character/weapon presentation after skeleton/animation import compatibility is validated.
- Kenney RPG Audio, Impact Sounds, and Interface Sounds: CC0; candidates for W07. No audio file is marked imported or production-integrated by this W02 checkpoint.

## Admission rules

1. Prefer official publisher/repository sources. Mirrors or scraped asset hosts are not authoritative provenance.
2. Record license before copying bytes into the repository.
3. Record an immutable upstream commit/tree/blob identity when available.
4. Record every material, geometry, audio, metadata, or format modification.
5. Store content identity using Git blob SHA; add package-provided checksums when an upstream package publishes them.
6. Runtime integration is a separate state from import. `RUNTIME_INTEGRATED_UNVALIDATED` or `RUNTIME_INTEGRATED_PENDING_W04` means integration exists without a new runtime evidence checkpoint; `RUNTIME_INTEGRATED_VALIDATED` means the specific import/render checkpoint has runtime evidence but is not automatically production-art or release approval.
7. Final representative art/audio requires new runtime evidence under AC-07/AC-08; provenance or an intermediate W04 validation checkpoint alone does not satisfy those gates.
