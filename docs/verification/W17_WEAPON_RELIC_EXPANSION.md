# W17 weapon/relic expansion verification contract

Task: `SR-20260909-150106-PPO12Y`
Branch: `v1.0.0-dev1`
Baseline parent: `da01a35d0a937990b422a4478868333f89868b51`
Requirement mapping: `docs/verification/REQUIREMENT_TRACE.md` AC-06, with AC-03/AC-11/AC-12 non-regression.

Status vocabulary: this W17 checkpoint can establish runtime-mechanics integration only. It does not by itself establish final production art/audio/provenance, human balance/fun/readability, Android-device performance/lifecycle, signing, release, or completed-game acceptance.

## W17 acceptance conditions

- W17-01: Retain the W09 causal base of exactly 6 trigger, 6 delivery and 8 transform parts, compatibility checks, energy budget and maximum causal chain depth 3.
- W17-02: Expose exactly 18 curated weapon definitions. Every curated recipe must pass the same compatibility/energy validator, use a unique trigger/delivery/transform signature, and disclose handling, purpose, condition, energy and hard limits. Theoretical part triples are not counted as curated weapons.
- W17-03: Expose exactly 48 relic definitions as 8 gameplay families x 6 bounded variants. A loadout has at most 4 relics and at most one relic per family. Relics may change bounded damage/target/pressure outputs but may not change cause identity or causal chain depth.
- W17-04: Provide six representative builds whose curated weapon and relic loadouts all pass the same production runtime validators.
- W17-05: Selection data exposes three deterministic weapon and relic choices, weapon comparison deltas, relic condition/effect/magnitude/tradeoff and hard limits. Combat-time application is accepted only while the caller supplies a paused level-up state; the hub may preconfigure the next expedition separately.
- W17-06: Runtime resolution keeps the retained W09 trigger -> delivery -> transform order, applies relic effects afterward, rejects duplicate cause IDs, terminates at the same chain-depth limit and rejects paused causal resolution.
- W17-07: Versioned weapon state persists the relic loadout and consumed causes; W09 v1 and v0 weapon snapshots remain migratable without inventing relic state or replaying consumed causes.
- W17-08: The actual main shell can select a representative build, depart with it and persist/reload that build through the existing W12 runtime checkpoint/save path. W15 and W16 actual-scene smokes remain required non-regression evidence.
- W17-09: `content_manifest.json` records 18 weapon definitions and 48 relic definitions as W17 runtime mechanics while keeping `implemented_content.curated_weapons` and `implemented_content.relics` at 0 until final per-item production asset/provenance and human balance gates are complete.

## Remote verification contract

1. Static preflight: unchanged `1.0.0-dev1` identity/package contract, W13/W14/W15/W16 retained manifest checks, W17 exact counts/files, no key material.
2. Pinned Godot 4.7.2 headless import with parse/script-error rejection.
3. Fast runner: `TEST_CONTRACT=w17-weapon-relic-expansion-v1`, 18 suites, `RESULT=PASS`.
4. Existing W15 actual vertical-slice smoke remains blocking.
5. Existing W16 actual character-role smoke remains blocking.
6. New W17 actual weapon/relic smoke must report exact 18/48/6 counts, selection UI PASS, persistent build PASS and overall PASS within the same 2500 ms sanity budget.
7. Existing W13 render and W14 audio evidence remain blocking presentation-regression evidence; they do not become human review PASS.

## Explicit non-goals for this checkpoint

- No versionName/versionCode/package/signing change.
- No main merge, tag, GitHub Release or production APK.
- No new network/account/storage/advertising/payment/analytics/Android-permission boundary.
- No claim that 18 weapons or 48 relics have final item-specific art/audio/provenance or human balance acceptance.
