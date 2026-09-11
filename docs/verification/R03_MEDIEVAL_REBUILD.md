# R03 Medieval Fantasy Rebuild Contract

Status: W04 gameplay-authority alignment checkpoint in progress.
Baseline: `v1.0.0-dev1` at `670d552c15166fee843678ebcfee17183cc322e2`.
Work branch: `work/sr-20260911-medieval-rebuild`.

## Acceptance criteria

- AC-01 — Rebuild presentation as coherent high-quality medieval fantasy 2.5D. Final representative/final evidence must not rely on the current simplistic procedural/SVG presentation packet.
- AC-02 — Separate screen-space UI from world-space rendering. The playable field must span several viewports, movement must not be bounded by the display rectangle, and the camera must follow the player naturally.
- AC-03 — Preserve and improve weapon identity: visible weapon state, distinct attack/projectile/VFX/SFX, and readable activation → travel/swing → hit → response → damage → death causality.
- AC-04 — Rebuild menus/HUD for mobile readability with opaque/dimmed panels, safe-area handling, appropriate touch targets, and no touch leakage into gameplay.
- AC-05 — Replace production procedural synthesis with real licensed audio files for BGM/ambient, weapons, impact/death and UI; final audio approval requires listening-oriented evidence, not file/RMS checks alone.
- AC-06 — Improve movement, attack, hit, death, level/reward and boss feedback without obscuring gameplay state.
- AC-07 — Preserve large-world collision/spawn/performance invariants and existing save/campaign progression; add migration only when data layout actually changes.
- AC-08 — Perform fresh independent verification using new rendered gameplay/screenshots and a real Android installable APK. Prior graphics/audio/readability passes cannot be reused as final acceptance evidence.

## Non-regression constraints

- NR-01 — Existing valuable save/campaign/progression semantics remain compatible unless an explicit migration is implemented and verified.
- NR-02 — Preserve Git history and the established production/dev package and signing lineage. Do not use unrelated MuseVault signing material and do not introduce new permissions, services, accounts, analytics, ads, payments or runtime network dependencies without explicit scope expansion and security review.

## W03 checkpoint scope

W03 changed only rendering-space structure: a multi-screen world boundary, a player-follow camera in the active main shell, and a `CanvasLayer`-based screen UI boundary. Existing game rules, save schema, campaign data, package identifiers and signing configuration remained unchanged.

The old W13/W18/W19 SVG backgrounds remain only as temporary compatibility placeholders during the rebuild. They are explicitly not acceptable final art and must be replaced before AC-01 can pass.

## W04 gameplay-authority alignment checkpoint

This checkpoint advances AC-02 and AC-07 without making the 3D presentation layer authoritative.

- `game/world/medieval_world_layout.gd` defines the authoritative gameplay-space W04 world bounds, the bridge/ford, chapel/hamlet wayfinding coordinates, shared building footprints, the broad passable corridor, and deterministic spawn-safe terrain resolution.
- `phase_battlefield_model.gd` consumes those bounds and shared building footprints while retaining the existing material/shadow-only blocker and cover semantics. The same visible chapel/hamlet footprints therefore block both phases, while the central bridge/ford remains traversable.
- Spawn-safe resolution excludes visible river surface away from the ford, building footprints with padding, and the world edge. Runtime SpawnDirector wiring is not claimed in this checkpoint because the connector blocked that file mutation; it remains explicit W04 follow-up scope.
- The test contract advances from `r04-medieval-rebuild-field-v1` to `r04-medieval-rebuild-field-v2`. It verifies 2D world-bound alignment with the 3D presentation field, shared landmark coordinates, visible-building collision, passable bridge/ford, deterministic legal spawn resolution, retained asset-backed/depth composition, and the existing 19-suite regression set.
- Save schema, campaign schema, package identifiers, version identity and signing configuration remain unchanged.

Remaining W04 work after this checkpoint includes runtime SpawnDirector wiring to the authority resolver, enemy/projectile obstacle interaction review, multi-screen real traversal evidence through `CombatCamera`, spawn-density/object-lifetime observation, and culling/pooling/performance measurement. Therefore W04 is not complete merely because the v2 fast contract passes.

## Evidence policy

- Old visual/audio/readability evidence is treated as stale for AC-01, AC-02, AC-03, AC-04 and AC-05.
- New code-level tests may be reused only as regression support; final acceptance requires rendered/runtime evidence tied to the exact candidate commit.
- Before promotion to a `v*-dev*` branch, synchronize this contract into the canonical `docs/verification/REQUIREMENT_TRACE.md` and update any version-pinned CI contract in the same change set.
