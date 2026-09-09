# W20 ten-boss mechanical tranche verification contract

Task: `SR-20260909-150106-PPO12Y`
Baseline: W19 verified candidate `20717136b3da1b91787a60d9aa0b890272f681e1` on `v1.0.0-dev1`.

## Scope

This W20 tranche replaces the retained W05 region-boss primitive with a data-driven ten-boss combat layer while keeping the underlying once-per-director boss scheduling contract intact.

- Five parent-region identities expose exactly two boss profiles each: Twilight Shipyard, Glass Garden, Flooded Archive, Ash Railway and Eclipse Fortress.
- Every boss owns a unique pattern family, three health-gated phases, explicit pre-hit dodge guidance, attack cadence/radius/damage parameters, an exactly-once reward ID, an unlock ID and presentation cue identities.
- `RegionSpawnDirector` enriches the existing W05 boss warning/spawn with a selected W20 boss identity without changing `BOSS_TIME` or `BOSS_WARNING_LEAD`.
- `RegionSwarmEncounter` mounts the selected boss into the existing pool, resolves its timed attack telegraph before damage, moves its targetable body phase at health thresholds and queues one reward/unlock result on defeat.
- The W20 telegraph renderer gives each pattern family a distinct warning geometry. Final authored boss sprite/animation/audio assets, provenance manifest and human art/balance review remain the next W20 tranche and are not counted as production boss completion here.

## Acceptance criteria

- AC-W20M-01: catalog exposes exactly 10 valid unique boss IDs across exactly five parent regions with exactly two bosses each.
- AC-W20M-02: all ten bosses have unique pattern/phase signatures, three phases, two descending health thresholds, explicit dodge guidance, reward IDs, unlock IDs and presentation cues.
- AC-W20M-03: all ten identities can traverse the retained W05 dedicated boss warning and exactly-once spawn path through `RegionSpawnDirector` without changing the base director contract.
- AC-W20M-04: an actual `RegionSwarmEncounter` receives a selected W20 boss, emits a timed boss attack telegraph before the attack, advances phase from actual pooled health loss, and produces one claimable reward/unlock on lethal damage.
- NR-W20M-01: W18 remains 2 parent regions/4 route profiles/12 regional behavior definitions; W19 remains 2 added parent connections/2 route profiles/12 behavior definitions.
- NR-W20M-02: `content_manifest.implemented_content.bosses` remains 0 until final boss audiovisual assets, provenance and human quality gates are complete.
- NR-W20M-03: W21 still owns the five-region campaign topology. W20 does not change `CAMPAIGN_SEGMENTS` or save schema.
- REL-W20M-01: `1.0.0-dev1`, versionCode 1 and existing DEV/PROD package identities remain unchanged.
- SAFE-W20M-01: no network, account, permission, storage, secret, analytics, payment or signing-surface change.

## Test contract preflight

`TEST_CONTRACT_PREFLIGHT_STATUS=PASS`

- W20 focused expectations are derived from the catalog/model/director/encounter source in this candidate and are purpose-built for the new mechanical contract: VALID.
- W18 and W19 workflows keep their existing fixed count/status expectations because this tranche does not alter region catalogs or manifest accounting: VALID.
- Foundation CI keeps its W17 suite contract and retained W05 base-director checks. The base director is unchanged; W20 extends only the regional subclass/runtime: VALID.
- No stale version string, removed behavior, or old producer assumption is intentionally preserved as a W20 expectation.

## Action preflight

The branch update is an actual W20 source mutation, so this is a new GitHub Actions run rather than a rerun of a prior attempt. W20 produces no artifact consumed by a later workflow; artifact identity/provenance consumer checks are NOT_APPLICABLE. Existing W18/W19/foundation push workflows are intentional regression gates on the same candidate SHA.

Production boss completion is not claimed by this tranche. The next W20 tranche must add ten non-placeholder authored boss audiovisual identities/provenance, wire final presentation assets, update content accounting/requirement trace, then rerun the same candidate-bound regressions before W21.
