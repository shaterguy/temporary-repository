# W02 Third-Party Asset Provenance

This ledger is the admission gate for external art/audio used by the medieval rebuild. A file is not considered production-approved until its source, license, upstream identity, modifications, content identity, and intended use are recorded here.

## KayKit Medieval Hexagon Pack 1.0

- Author/publisher: Kay Lousberg / KayKit
- Upstream repository: `KayKit-Game-Assets/KayKit-Medieval-Hexagon-Pack-1.0`
- Upstream branch: `main`
- Upstream tree observed for this import: `79be3f757c62c3f6ea35a80ccd907b784b0ce69f`
- License: CC0 1.0 Universal (`LICENSE.txt` upstream blob `db3b53b5425c48afc0f606bfc0de84e51d834e95`)
- Redistribution: permitted under CC0; attribution is not required, but provenance is retained here for auditability.

| Target file | Upstream path / blob | Modification | Target Git blob | Intended use | State |
| --- | --- | --- | --- | --- | --- |
| `assets/third_party/kaykit_medieval_hexagon/terrain/hex_grass.bin` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/base/hex_grass.bin` / `eae1af657f2acffc11bace562df95a8f25e0e465` | None; byte-identical copy | `eae1af657f2acffc11bace562df95a8f25e0e465` | Runtime 2.5D terrain geometry | RUNTIME_INTEGRATED_UNVALIDATED |
| `assets/third_party/kaykit_medieval_hexagon/terrain/hex_grass.gltf` | `addons/kaykit_medieval_hexagon_pack/Assets/gltf/tiles/base/hex_grass.gltf` / `b2a4608f8935afbbc3261dd71af015900d8ec925` | Removed external atlas dependency and replaced material with a local PBR baseColorFactor/roughness so this first geometry sample is self-contained; mesh/accessor/buffer layout retained | `9875281b78e8e4aa3c416b16cc02ae00d64581f7` | Runtime 2.5D terrain projected through `MultiMeshInstance3D` | RUNTIME_INTEGRATED_UNVALIDATED |

The modified `.gltf` is not claimed to be byte-identical to upstream. The paired `.bin` is byte-identical and its Git blob SHA is therefore both the upstream and target content identity.

Runtime integration checkpoint: `game/presentation/medieval_field_2_5d.gd` mounts the admitted KayKit grass geometry as a non-authoritative 3D `MultiMeshInstance3D`; `game/ui/main_shell.tscn` renders it in a `SubViewport`, and `game/ui/main_shell_medieval_rebuild.gd` mirrors the authoritative `CombatCamera` focus into the 3D presentation camera. This state remains unvalidated until Godot runtime/render evidence is captured.

## Vetted but not yet imported

- KayKit Medieval Hexagon Pack building, nature, decoration, road, coast, and river geometry: CC0; candidates for W04 field composition after the terrain import path is runtime-validated.
- KayKit Character Pack: Adventurers: CC0; candidate for character/weapon presentation after skeleton/animation import compatibility is validated.
- Kenney RPG Audio, Impact Sounds, and Interface Sounds: CC0; candidates for W07. No audio file is marked imported or production-integrated by this W02 checkpoint.

## Admission rules

1. Prefer official publisher/repository sources. Mirrors or scraped asset hosts are not authoritative provenance.
2. Record license before copying bytes into the repository.
3. Record an immutable upstream commit/tree/blob identity when available.
4. Record every material, geometry, audio, metadata, or format modification.
5. Store content identity using Git blob SHA; add package-provided checksums when an upstream package publishes them.
6. Runtime integration is a separate state from import. `RUNTIME_INTEGRATED_UNVALIDATED` does not mean visually validated or release-approved.
7. Final representative art/audio requires new runtime evidence under AC-07/AC-08; provenance alone does not satisfy those gates.
