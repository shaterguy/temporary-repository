# W23B weapon/relic production-art packet

Task: `SR-20260909-150106-PPO12Y`
Baseline branch/SHA: `v1.0.0-dev1` / `8369fc658fcaecee34deedb4f40a9df602c8cad0`
Scope: W23B only — 18 curated weapon assets + 48 relic assets, presentation mapping, live HUD mapping, provenance, focused automated review evidence.

## Acceptance-criteria mapping

- AC-12: every existing W17 curated weapon ID and relic ID receives a distinct tracked runtime SVG; W23B manifest and provenance cover all 66 assets; placeholder count is zero for this packet. Production gameplay counts remain zero because human/balance/audio/final gates are not passed here.
- AC-13: the actual choice model carries the production `art_path`, the actual `main_shell.tscn` mounts a selected-build HUD, and CI imports all SVGs plus renders a 1280×720 review sheet. Automated render evidence is not human visual acceptance.
- AC-16: the W23B assets are recorded as project-original editable SVGs. Signing lineage, final APK identity and direct delivery are unchanged and remain later gates.

## Non-regression contract

- W17 trigger/delivery/transform recipes, energy budget, causal-chain depth, damage coefficients, relic effects and four-slot/family constraints are unchanged.
- Save/world schemas and selected-build persistence are unchanged.
- Package/version/signing configuration is unchanged; no secrets, permissions, network access, accounts, payments, analytics or dependencies are added.
- W23A six-character art/runtime mapping remains intact.

## Focused verification

`w23-art-ci` must validate exact 18/48 manifest counts, zero placeholders, 66 unique authored SVG payloads, Godot import, the W23B runtime smoke, main-scene HUD mounting, choice-card art mapping and the 1280×720 review capture. The existing W17 mechanical tests remain the retained behavior baseline because this packet intentionally does not alter those systems.
