# W26 balance and long-run verification

Task: `SR-20260909-150106-PPO12Y`
Baseline branch: `v1.0.0-dev1`
Baseline commit: `0e5950e4e43da7300c5355196de52df3da1966ab`
Requirement trace mapping: `AC-03`, `AC-06`, `AC-08`, `AC-09`, `AC-11`; non-regression `NR-01` through `NR-05`.

## Scope

W26 audits the existing W16-W22 gameplay/economy surfaces for dominant choices, runaway accumulation, progression exhaustion, deterministic variety collapse, and bounded adaptive pressure. It performs minimum corrections only. It does not change Android package identity, version, signing lineage, world schema, save payload schema, networking, permissions, production content counts, or the horizontal-only endgame policy.

Human visual quality, listening quality, touch ergonomics, device soak, production signing/install, and subjective long-term fun remain separate acceptance work. Automated W26 evidence prints `W26_HUMAN_FUN=PENDING`; it is not a proxy for human acceptance.

## Findings and corrections

1. `salvage` had repeated positive settlement/event gains but no repeatable runtime spend path. This allowed monotonic reserve growth. W26 bounds only future positive growth at 160. Existing saves already above 160 are not destructively clamped; they simply stop receiving additional positive reserve until ordinary spending/failure brings them below the bound.
2. Successful post-final progression increments `post_final_cycle` and `expedition_attempt` together. Selecting a variant from `run_seed % 4` therefore reused correlated low bits and could collapse a long successful sequence to only one or two of the four authored variants. W26 preserves the deterministic `run_seed` itself but selects the variant from the higher `run_seed / 97` band. Stored active variants and exact same-seed retries remain unchanged; future new runs avoid the low-bit lockstep.
3. Post-final play now has a repeatable horizontal sink: 20 salvage prepares one recon reroute for the next new post-final expedition. The recon rotates the authored variant/challenge pair while preserving the deterministic run seed and all world/save schemas. Preparing the same recon twice is idempotent and does not charge twice.
4. Same-seed retry retains its W22 contract. The normal hub UI requires the retry decision before a new recon can be prepared, so the player-facing path cannot spend recon currency on a same-seed retry. The runtime also defensively prevents any preexisting recon marker from altering retry seed/variant/challenge at retry start.
5. `phase_afterglow` previously had a disclosed condition and energy cost but no causal runtime output. W26 gives an active afterglow one additional target, restoring the intended area-control tradeoff for `dodge_fan` without changing causal depth or duplicate suppression.
6. `ark_resonance` at 1.20 left its focused Ark-pressure niche too weak against adjacent coverage choices. W26 raises the conditional multiplier to 1.35. The live causal comparison requires `ward_halo` to gain at least 25% damage when Ark pressure is active instead of enforcing an arbitrary absolute-damage target. The all-weapon audit still keeps no-relic causal actions inside the 32-damage / 4-target / 6-barrier-pressure band.
7. Enemy doctrine remains capped by the retained W11 contract, including repeated-failure relief and no universal health/damage inflation. Character role ceilings remain the retained W16 contract. No W26 correction is applied to those systems because their retained tests pass.

## Automated contract

`tests/integration/w26_balance_longrun_smoke.gd` performs:

- retained W16 character, W17 weapon/relic, W11 doctrine, and W22 endgame unit contracts;
- a deterministic 96-run successful post-final sequence that must cover all four authored variants, all six authored challenges, at least 12 distinct variant/challenge pairs, exactly 96 horizontal mastery marks, and the retained 16-entry seed-history bound;
- all 18 curated weapons through live causal resolution under a broad bounded context, explicit `dodge_fan` afterglow coverage, and active-vs-inactive `ward_halo` Ark-resonance uplift;
- reserve cap behavior for a normal near-cap state and a legacy over-cap state;
- recon charge, idempotency, save/reload persistence, deterministic-seed preservation, variant/challenge rotation, and active-marker disclosure;
- exact same-seed retry under a defensively preexisting recon marker, while the player-facing UI blocks creating that combination.

`.github/workflows/w26-balance-ci.yml` pins the existing Godot `4.7.2-stable` archive and digest, verifies unchanged identity/schema constants, imports the candidate headlessly, and runs the W26 smoke with explicit failure/leak/timeout gates.

## Verified evidence

Code-under-test commit: `6db70cee51425a19698fa506e25d89bf3d0a87ba`
Workflow: `w26-balance-ci`
Run: `34427050345`
Job/check: `102714405794`
Result: `success`
Measured W26 action time: `73 ms`

The successful log emitted all required markers: retained contracts, long-run variants, weapon balance, economy, recon save/reload, same-seed retry, and overall W26 balance/long-run `PASS`. It also emitted `W26_HUMAN_FUN=PENDING` to preserve the human acceptance boundary.

## Evidence interpretation

A passing W26 workflow establishes the quantified automated balance/long-run invariants above for the tested code. It does not establish subjective fun, premium presentation, Android-device ergonomics, device performance/soak, signing, installation, or final release acceptance.

Security delta: `NONE`. The W26 diff changes internal offline game logic, a local hub command, tests, and CI only; it adds no authentication, permission, secret, personal-data, external-input, network, dependency, signing, update, or deployment trust boundary.
