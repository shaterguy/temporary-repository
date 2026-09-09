# W21 campaign topology contract

Task: `SR-20260909-150106-PPO12Y`
Target branch: `v1.0.0-dev1`
Baseline: `0736f87815676412674cd1944cdbec1022dcd47a`

## Scope

W21 is the campaign-topology integration checkpoint. It promotes the four previously materialized regional expansions into the persistent campaign graph without changing the retained W12 outer save-envelope schema, settlement idempotency rules, Android package identity, version identity, signing policy, permissions or external trust boundaries.

The campaign now exposes five parent-region identities in deterministic order:

1. `twilight_shipyard`
2. `glass_garden`
3. `flooded_archive`
4. `ash_railway`
5. `eclipse_fortress`

The normal campaign has four successful progression segments. Segment 0 retains Twilight Shipyard. Segment 1 maps the retained W18 destinations to Glass Garden. Segment 2 maps them to Flooded Archive. Segment 3 is the final regional branch and offers the retained W19 Ash Railway and Eclipse Fortress connections as the two mutually exclusive departures. A successful segment-3 settlement advances to segment 4 and `POST_FINAL`. The same two W19 connection choices remain available after completion as the retained persistent continuation loop; post-final success increments only `post_final_cycle` and does not advance the completed campaign beyond segment 4.

## Save compatibility and migration

The authoritative inner world snapshot advances from `lanternfall-world-v1` to `lanternfall-world-v2`. The outer W12 save payload remains `lanternfall-save-payload-v1`, and the SaveStore envelope/checksum/sequence/settlement-ID path is unchanged.

Migration rules are explicit:

- v1 snapshots below segment 3 retain their segment, state, progression, cross-run data, access rights, unlocks and settlement ledger.
- A v1 segment-3 `POST_FINAL` snapshot with no evidence of a successful W19 connection becomes a v2 segment-3 `HUB`. This represents a campaign that completed the former three-segment graph but has not yet consumed the new final regional branch.
- A v1 segment-3 active first Ash Railway or Eclipse Fortress expedition remains an active v2 segment-3 expedition. Its next successful settlement completes the v2 campaign exactly once.
- A v1 snapshot with evidence that a W19 connection already succeeded becomes v2 segment 4. Evidence is any retained post-final cycle, completed W19 choice, W19 horizontal unlock or W19 access right. This prevents already-granted world effects from being replayed as a newly required final segment.
- v0 snapshots first migrate into the retained v1 semantic shape and then pass through the same W21 migration.
- `applied_settlement_ids` is preserved. Re-submitting a settlement already present in the ledger remains `ALREADY_APPLIED` and cannot duplicate salvage or progression.
- Failure in the new segment-3 final branch remains recoverable at segment 3 with both departure choices available.

## Runtime integration

`WorldCampaignModel` now exposes `parent_region_id` in public departure data and expedition context. `main_shell_w18.gd` exposes a read-only campaign-topology snapshot that joins authoritative world topology to the active W18/W19 regional runtime snapshot for verification. The shell bridge does not become authoritative for campaign, save, combat, route, circuit, phase, weapon, echo or doctrine state.

The focused W21 actual-scene smoke instantiates `main_shell.tscn` against isolated save roots and verifies both final branches through the real shell:

- Ash Railway: `deep_rescue_patrol` → `afterglow_frontier` → `ash_railway`, with the Ash Railway runtime environment and W18 regional checkpoint state.
- Eclipse Fortress: `lighthouse_survey` → `far_lantern_chain` → `eclipse_fortress`, with the Eclipse Fortress runtime environment.
- The Ash Railway final-branch checkpoint must reload at segment 3 as an active expedition with its regional state aligned to the world context.

## Acceptance contract

- AC-W21-01: `campaign_parent_region_ids()` exposes exactly five ordered parent identities: Twilight Shipyard, Glass Garden, Flooded Archive, Ash Railway and Eclipse Fortress.
- AC-W21-02: the normal campaign exposes four successful progression segments with exactly two departures at each hub; segment 3 is a two-parent Ash Railway/Eclipse Fortress final branch.
- AC-W21-03: the outer `lanternfall-save-payload-v1` contract remains readable while the inner world state migrates v0/v1→v2 according to the explicit matrix above.
- AC-W21-04: settlement ledger, salvage/progression state and persistent W19 unlock/access effects survive migration without duplicate application.
- AC-W21-05: both final branches mount through the actual main shell and retained regional runtime; a segment-3 active regional checkpoint survives save/reload.
- AC-W21-06: final-branch failure remains recoverable; post-final continuation stays available after campaign completion.
- AC-W21-07: foundation, W18, W19 and W20 retained regressions remain valid at the exact W21 candidate SHA in addition to the focused W21 gate.

## Non-goals and residual gates

W21 does not inflate `implemented_content.regions` or any other production content count. It does not claim final region art/audio quality, gameplay/fun/balance, Android-device lifecycle, performance/memory/soak, 16KB page-size, signing, installation, update compatibility or release acceptance. Those remain later work items and human/device gates.

W21 also does not alter version `1.0.0-dev1`, versionCode `1`, production/dev package IDs, signing lineage or release assets.

## Verification source

The authoritative automated evidence is the exact pushed W21 candidate SHA and its GitHub Actions runs. The focused workflow is `.github/workflows/w21-campaign-topology-ci.yml`; retained foundation/W18/W19/W20 workflows must also pass at the same candidate SHA. No local development/build/test result is treated as acceptance evidence for this checkpoint.
