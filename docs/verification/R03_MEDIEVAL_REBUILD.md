# R03 Medieval Fantasy Rebuild Contract

Status: W01 baseline locked; W03 structural checkpoint in progress.
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

This checkpoint changes only rendering-space structure: a multi-screen world boundary, a player-follow camera in the active main shell, and a `CanvasLayer`-based screen UI boundary. Existing game rules, save schema, campaign data, package identifiers and signing configuration are intentionally unchanged.

The old W13/W18/W19 SVG backgrounds remain only as temporary compatibility placeholders during W03. They are explicitly not acceptable final art and must be replaced before AC-01 can pass.

## Evidence policy

- Old visual/audio/readability evidence is treated as stale for AC-01, AC-02, AC-03, AC-04 and AC-05.
- New code-level tests may be reused only as regression support; final acceptance requires rendered/runtime evidence tied to the exact candidate commit.
- Before promotion to a `v*-dev*` branch, synchronize this contract into the canonical `docs/verification/REQUIREMENT_TRACE.md` and update any version-pinned CI contract in the same change set.
