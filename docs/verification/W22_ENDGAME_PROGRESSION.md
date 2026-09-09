# W22 endgame progression verification

Task: `SR-20260909-150106-PPO12Y`
Target branch: `v1.0.0-dev1`
Requirement mapping: `AC-09`, `AC-11`, `AC-12`, `NR-03`

## Implemented contract

- W22 adds post-campaign world-variant expeditions only after the retained W21 four-segment campaign reaches `POST_FINAL`.
- Four authored variant profiles choose a deterministic positive run seed. The run seed is routed through the actual main-shell expedition seed path, so Ark/encounter deterministic generation consumes the W22 seed rather than a display-only label.
- Six authored challenges consume actual route, phase/circuit observation and W17 selected weapon/relic state. Challenge completion and mastery are records/badges only; no permanent damage, health, speed or generic stat multiplier is granted.
- A failed post-final run keeps the retained W21 failure consequences. After the retained W21 story event is resolved, the user may explicitly start a same-seed retry. The retry preserves run seed/variant/challenge but receives a fresh expedition ID and therefore a fresh settlement ID.
- Settlement idempotency remains owned by the retained W12/W21 applied-settlement ledger. W22 long-run counters and mastery update only when the underlying settlement returns `applied=true`.
- W22 state is added inside the world snapshot while retaining `lanternfall-world-v2` and the outer `lanternfall-save-payload-v1`. A W21 snapshot with no `endgame_state` restores to an empty W22 progression state without inventing rewards.
- Active W22 variant state survives checkpoint/save reload. Old post-final expeditions that began before W22 and therefore have no active variant remain valid and simply do not award W22 mastery on that already-started run.
- `game/data/endgame_progression_manifest.json` records four variant profiles, six challenge definitions, horizontal-only mastery, same-seed retry semantics, unchanged save schema and zero production-content count delta.

## Non-regression boundaries

- Existing W21 story/topology, W19 world effects, W17 weapon/relic authority, W12 SaveStore envelope/checksum/sequence and settlement IDs remain authoritative.
- Same-seed retry does not roll back salvage loss, tension increase, failure count, story consequences or any already-applied world effect.
- No package name, version name/code, signing lineage, permissions, runtime networking, accounts, analytics or external trust boundary is changed.
- Root `implemented_content` counts remain unchanged. W22 system definitions are not promoted into production content counts and do not imply final art/audio/human balance quality.

## Automated evidence contract

- `tests/unit/test_w22_endgame_progression.gd` verifies authored counts, horizontal-only mastery, deterministic variant metadata, failure recovery, settlement idempotency, same-seed retry identity separation, save compatibility and challenge completion.
- `tests/integration/w22_endgame_progression_smoke.gd` instantiates the actual `main_shell.tscn`, routes a W22 seed through `_expedition_seed`, fails a run, resolves the retained W21 story gate, retries the same seed, settles successfully and reloads a fresh W22 runtime from SaveStore.
- `.github/workflows/w22-endgame-ci.yml` pins the retained Godot toolchain, rejects secret-key files, preserves root production-count zeros, imports the project and requires all W22 markers plus a 4000ms headless action sanity budget.

## Residual verification

W22 does not close human fun/balance/readability, production audiovisual breadth, Android device lifecycle/performance, signing/install/update or release acceptance. Those remain W23-W28/V01/V02/REL dependencies and must not be represented as complete game quality evidence.
