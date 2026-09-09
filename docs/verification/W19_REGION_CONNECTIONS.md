# W19 Ash Railway + Eclipse Fortress verification contract

Task: `SR-20260909-150106-PPO12Y`
Baseline: W18 verified candidate `fedeeaa812338f1326c8cc0c57e6289cbdcf31da` on `v1.0.0-dev1`.

## Scope

W19 materializes the remaining two parent-region identities without prematurely rewriting the W18 campaign/save topology:

- `afterglow_frontier` becomes the Ash Railway runtime connection for `deep_rescue_patrol`.
- `far_lantern_chain` becomes the Eclipse Fortress runtime connection for `lighthouse_survey`.
- Each region supplies unique route geometry, material/shadow hazard rules, six deterministic enemy-behavior definitions and one original runtime environment vector.
- Existing `WorldCampaignModel` settlement semantics remain authoritative for persistent residents/lighthouse, horizontal unlocks, access rights, support/shop/threat metadata and recoverable failure.
- W18's region checkpoint schema remains unchanged. W19 explicitly verifies that inherited `character_id` and regional state survive the same checkpoint path.

## Non-goals

- Do not change `CAMPAIGN_SEGMENTS` or invalidate W18 saves. W21 owns final five-region campaign topology.
- Do not claim final production region/enemy counts before bosses, complete regional audio/assets and human quality gates.
- Do not change app version, package identity or signing lineage.
- Do not add network, account, storage, analytics, payment or Android permission surfaces.

## Acceptance criteria

- AC-W19-01: W19 catalog exposes exactly two new parent regions, two route profiles, two phase states per region, twelve unique regional behaviors and two persistent world connections.
- AC-W19-02: both W19 profiles validate through the retained W18 data-driven route/objective/spawn runtime without changing W18 route-profile counts.
- AC-W19-03: Ash Railway and Eclipse Fortress mount distinct route geometry, background assets, phase hazards and six behavior IDs through the actual `main_shell.tscn` runtime.
- AC-W19-04: the two existing post-final choices target the W19 profiles and keep their support/shop/threat metadata consistent with `WorldCampaignModel`.
- AC-W19-05: successful settlement persists the corresponding horizontal unlock and access right across snapshot restore; failed settlement remains recoverable and retains a valid departure path.
- NR-W19-01: W18 Glass Garden/Flooded Archive contract remains exactly 2 parent regions, 4 route profiles and 12 behavior definitions.
- NR-W19-02: W15/W16/W17 foundation flow remains valid.
- NR-W19-03: W19 checkpoint preserves inherited `character_id` plus regional objective state; no repeat of the W18 checkpoint-field regression.
- SAFE-W19-01: no new external I/O, permission, secret or trust-boundary surface.
- REL-W19-01: `1.0.0-dev1`, versionCode 1 and DEV/PROD package identities remain unchanged.

## Verification tiers

1. STATIC_PREFLIGHT: exact toolchain/version identity, manifest/accounting, asset provenance, no committed key material.
2. FAST_TEST: headless Godot import plus `w19_region_connections_smoke.gd`, which includes the W19 unit contract and actual-shell runtime/persistence checks.
3. REGRESSION: push-triggered `w18-region-ci` and `foundation-ci` remain required because W19 extends shared `region_catalog.gd` and is instantiated through the retained main shell.
4. EXPENSIVE_RUNTIME: Android device performance and human art/balance review remain later gates; headless CI does not claim them.

Production `implemented_content.regions` and `implemented_content.enemy_behaviors` remain zero in W19 by design.
