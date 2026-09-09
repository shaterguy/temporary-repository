# W18 region expansion verification contract

Task: `SR-20260909-150106-PPO12Y`
Branch: `v1.0.0-dev1`
Milestone: W18 — Glass Garden + Flooded Archive.

## Product-AC mapping

- `AC-04 N01 mobile fortress/routes`: W18 must supply four route geometries for the stage-1/stage-2 campaign destinations while retaining W06 idempotent route choice, supply/threat/objective semantics and recovery behavior.
- `AC-08 N05 disclosed enemy doctrine`: W18 regional spawn entry patterns may layer on normal pressure but doctrine-response spawns must retain the W11 doctrine path rather than being replaced by regional flavor.
- `AC-09 N06 persistent world graph`: existing save-compatible destination IDs remain authoritative; W18 maps them to two parent regions rather than rewriting the campaign schema.
- `AC-10 N07 dual-phase battlefield`: every W18 parent region exposes material and shadow rules, and the region objective requires observed access to both phases.
- `AC-12 distinct content manifest`: two runtime environment vectors and twelve regional enemy-entry behavior definitions are tracked without advancing production region/enemy counts.
- `AC-16 provenance`: both W18 runtime SVGs must have source-direction and original-art provenance records.

## W18 acceptance contract

1. Region catalog exposes exactly two parent regions: `glass_garden`, `flooded_archive`.
2. Existing campaign destinations map to exactly four W18 route profiles: `brine_veins`, `blackglass_spires`, `drowned_archive`, `storm_crown`.
3. Every W18 route profile validates its existing campaign route ID and supplies unique route geometry, travel pressure and an actual runtime background asset.
4. Glass Garden and Flooded Archive each expose both material and shadow rule records with different hazard identities.
5. Region objective state is mechanical: initial material observation plus an actual shadow transition, required circuit activations and `RESTING` route state are required before the Ark may leave the rest gate.
6. Region objective snapshot/restore is save-compatible and does not alter the W12 runtime schema; it is carried as an optional `w18_region` extension in the active expedition checkpoint.
7. Exactly twelve unique W18 regional enemy-entry behavior definitions exist, six per parent region. They alter deterministic entry pattern/base regular archetype while doctrine-response placement remains owned by the W11 path.
8. Stage-0 Twilight Shipyard behavior remains the inherited W15-W17 path with no W18 route/spawn override.
9. `main_shell.tscn` mounts `main_shell_w18.gd`; stage-1/stage-2 departures configure W18 route/spawn/background/objective state while W17 character/weapon/relic bridges remain inherited.
10. `content_manifest.json` reports W18 runtime-mechanics integration but keeps `implemented_content.regions` and `implemented_content.enemy_behaviors` at 0 until later boss/audio/full production asset and human review gates.
11. W18 SVG manifest contains exactly two non-placeholder environment assets and each resolves to the W18 source/provenance records.
12. Remote regression must include the existing `foundation-ci` for retained W15-W17 behavior and focused `w18-region-ci` evidence for this contract on the exact same candidate SHA.

## Non-regression contract

- No version/package/signing-lineage change in W18.
- No network, account, analytics, ads, payment or new Android-permission surface.
- No change to `WorldCampaignModel.SCHEMA`, destination IDs or W12 required runtime-state fields.
- No production-count inflation from definitions, route profiles or representative environment vectors.
- No debug signing fallback or signing material committed to the repository.

## Remaining product gates after W18

W19-W28, full region/boss/choice-event production breadth, region-specific final audio/animation/FX, human art/fun/balance/readability review, Android device lifecycle/performance/memory/soak/16KB evidence, durable protected signing, APK install/update evidence and release operations remain open.
