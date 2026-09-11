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

The modified `.gltf` files are not claimed to be byte-identical to upstream. The paired `.bin` files are byte-identical and their Git blob SHAs are therefore both the upstream and target content identities.

W04 runtime validation checkpoint:

- Candidate branch: `work/sr-20260911-medieval-rebuild`
- Validated source HEAD before this ledger-only update: `47b69b323d5e38d0021a4b798bca866ac9eff75f`
- GitHub Actions run: `34588158182` (`validate-field-composition`)
- Godot: `4.7.2-stable`
- Import: PASS
- Fast-test contract: `r04-medieval-rebuild-field-v1`, 19 suites, PASS
- Actual rendered output: 1280x720 main shell plus isolated 3D field, PASS
- Evidence artifact: `w04-render-34588158182-1`, artifact ID `10194483061`, ZIP digest `sha256:734212be54c1b84d98830dd1f0c668bdc2c801b0fc0aeea0d9d9ec966ec91852`
- Inspected field image SHA-256: `f503320beaa2563ae6290bf73f57b81ba395a4379260d0701f830a09a4304c93`
- Inspected main-shell image SHA-256: `a71f265b40e5894136285d828241842d71b5b310f8001231a7023767e617c51d`
- Visual readback: the initial expedition view now contains visible forest and rock clusters, vertical silhouettes, and cast shadows; the previous W13 world-art overlay is suppressed by `main_shell_medieval_rebuild.gd`. This validates the current asset import and 2.5D render path, not final field quality.

`game/presentation/medieval_field_2_5d.gd` currently mounts 2,232 KayKit grass instances plus deterministic forest and rock clusters, including four forest and two rock clusters staged around the initial expedition view. The 3D layer remains presentation-only; gameplay authority stays in the existing 2D model and `CombatCamera` remains the source for camera focus.

The W04 field is still incomplete. Buildings, roads, coast/river treatment, stronger elevation/landmarks, gameplay collision alignment, spawn-density validation, pooling/culling/performance measurement, and representative travel evidence remain outstanding. `RUNTIME_INTEGRATED_VALIDATED` therefore means the current imported asset and render path passed the recorded W04 checkpoint; it does not mean production art approval or release approval.

## Vetted but not yet imported

- KayKit Medieval Hexagon Pack building, larger nature, decoration, road, coast, and river geometry: CC0; candidates for the remaining W04 field composition, landmark, collision and world-density work.
- KayKit Character Pack: Adventurers: CC0; candidate for character/weapon presentation after skeleton/animation import compatibility is validated.
- Kenney RPG Audio, Impact Sounds, and Interface Sounds: CC0; candidates for W07. No audio file is marked imported or production-integrated by this W02 checkpoint.

## Admission rules

1. Prefer official publisher/repository sources. Mirrors or scraped asset hosts are not authoritative provenance.
2. Record license before copying bytes into the repository.
3. Record an immutable upstream commit/tree/blob identity when available.
4. Record every material, geometry, audio, metadata, or format modification.
5. Store content identity using Git blob SHA; add package-provided checksums when an upstream package publishes them.
6. Runtime integration is a separate state from import. `RUNTIME_INTEGRATED_UNVALIDATED` means integration exists without runtime evidence; `RUNTIME_INTEGRATED_VALIDATED` means the specific import/render checkpoint has runtime evidence but is not automatically production-art or release approval.
7. Final representative art/audio requires new runtime evidence under AC-07/AC-08; provenance or an intermediate W04 validation checkpoint alone does not satisfy those gates.
