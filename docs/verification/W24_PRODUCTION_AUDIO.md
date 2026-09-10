# W24 Production Audio Verification Contract

Task: `SR-20260909-150106-PPO12Y`
Branch: `v1.0.0-dev1`
Baseline before W24: `2602a26016cef50918ec22f0249a691dd124ce47`

## Acceptance mapping

- AC-12 distinct content/no placeholders: W24 maps all five current region families, ten bosses, eighteen curated weapons and six main UI actions to non-placeholder project-original audio recipes. Existing W20 boss-event and W14 system cues remain explicit reused project-original sources rather than hidden placeholders.
- AC-13 actual music/SFX/readability: runtime AudioDirector now selects region/boss production music, resolves exact weapon IDs to attack cues, binds signals by capability rather than stale W12 node names, keeps bounded priority-based SFX concurrency, and gives warnings a low-volume salience curve that still honors zero mute. CI renders listening artifacts from the same runtime synthesis code.
- AC-16 rights/provenance: W24 uses only repository-authored procedural synthesis and retained project-original W14/W20 sources; `assets/licenses/W24_ORIGINAL_AUDIO.md` records the provenance boundary.

## Test contract preflight

`TEST_CONTRACT_PREFLIGHT=VALID`

The W24 focused smoke is requirement-derived rather than implementation-derived. It independently reads the existing W17 weapon catalog, W18/W19 region catalog and W20 boss catalog, then requires complete mapping into W24. It also renders every W24 primary cue and rejects silent/invalid streams. The retained foundation contract remains authoritative for W14 seven-cue compatibility and W15 main-scene behavior.

Required W24 focused outputs:
- `W24_REGION_FAMILIES=5`
- `W24_REGION_RUNTIME_IDS=11`
- `W24_BOSS_MUSIC=10`
- `W24_BOSS_EVENT_CUES=50`
- `W24_WEAPON_SFX=18`
- `W24_UI_SFX=6`
- `W24_PRIMARY_CUES=44`
- `W24_EFFECTIVE_CUES=97`
- `W24_WARNING_LOW_VOLUME=PASS`
- `W24_MAIN_SHELL_AUDIO_BRIDGE=PASS`
- `W24_PRODUCTION_AUDIO=PASS`

## Actions preflight

`ACTION_PREFLIGHT=VALID`

- Authoritative source: GitHub `shaterguy/temporary-repository`, branch `v1.0.0-dev1`.
- Baseline identity: commit `2602a26016cef50918ec22f0249a691dd124ce47`, tree `91ea37f360eab2e9ecd592cc6ffa84ccb680d619`.
- Existing `foundation-ci` triggers on every dev/RC push and therefore remains a required non-regression gate for this change.
- W24 uses the repository-pinned Godot `4.7.2-stable` editor and digest already enforced by foundation CI.
- Execution type: `NEW_RUN`; W24 changes runtime code and test identity, so no rerun of stale evidence is valid.
- Artifact identity: `w24-production-audio-${{ github.sha }}-${{ github.run_attempt }}` to avoid rerun collisions.
- No versionName/versionCode/package/save/world/signing mutation is part of this milestone.

## Prevention Rules applicability

- PR-001 PROBE_SIDE_EFFECT: applicable and satisfied. Capability/workflow/source state was established by read-only GitHub/Drive inspection before the first mutation.
- PR-002 NOOP_TRIGGER_COMMIT_DRIFT: applicable and satisfied by a substantive atomic W24 implementation commit; no trigger-only commit is permitted.
- PR-003 VERSION_ASSERTION_COUPLING: not applicable; version identity does not change.
- PR-004 ARTIFACT_RERUN_IDENTITY_COLLISION: applicable; focused artifact identity contains commit SHA plus run attempt and producer/consumer use the same path set.
- PR-005/PR-007/PR-009: not applicable; this is not a formal release/version-profile transition.
- PR-006: not applicable; no append-style Docs index mutation is used.
- PR-008: not applicable; no web-parser work.

## Automated versus human evidence

Automated PASS may establish mapping completeness, deterministic synthesis validity, non-silence, runtime bridge integration, bounded voice policy, warning-volume policy and review-artifact generation. It must not be converted into a human listening PASS.

Human listening must still assess each region family, all ten boss profiles, the eighteen weapon identities, UI cues, transition behavior, simultaneous combat masking, repeated-cue fatigue and the -18 dB review mixes. Until that occurs, W24 is `PASS_WITH_RESIDUAL_RISK`, not final AC-13 PASS.
