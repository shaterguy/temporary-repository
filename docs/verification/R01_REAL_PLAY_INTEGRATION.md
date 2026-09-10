# R01 real-play integration contract

Task continuation: `SR-20260909-150106-PPO12Y` via `SR-20260910-121926-5B5U4L`
Baseline: `v1.0.0-dev1` at `57f721a089a87468fcd338455a52c0125e9c0de7`
Scope: signer-independent actual main-scene runtime integration evidence only.

`TEST_CONTRACT_PREFLIGHT=VALID`
`ACTION_PREFLIGHT=VALID`
`SECURITY_DELTA=NONE`
`VERSION_CHANGE=NONE`
`SIGNING_PATH=NOT_TOUCHED`

## Acceptance contract

- R01-01: the actual `game/ui/main_shell.tscn` enters `SLOT_SELECT → HUB → EXPEDITION` through `select_save_slot()` and `select_world_choice()`; tests must not set `shell_mode` directly.
- R01-02: W25 touch input is injected as `InputEventScreenTouch`/`InputEventScreenDrag` through the active Viewport and must reach the overlay, shell bridge, and combat runtime. The test must not call `set_transient_input()` to manufacture this evidence.
- R01-03: an actual expedition checkpoint is written, the main scene is destroyed, a new main scene loads the same isolated save root through `select_save_slot()`, and the same expedition identity resumes with W25 controls active.
- R01-04: settlement runs through the actual shell/campaign settlement path, returns to HUB, schedules the real W21 pending story event, binds W23 story art to that event, resolves the choice through the shell choice path, and begins a distinct next expedition.
- R01-05: Xvfb/SubViewport captures at 1280×720 and 2340×1080 record real HUB, real touch-active EXPEDITION, and real pending-story states. No capture may set `shell_mode` or manually inject a canonical event ID.
- R01-06: the workflow must fail early on static/import/fast integration errors before rendering evidence. The evidence artifact must include test logs, render logs, current GitHub SHA/run identity, source hashes, and six PNG hashes.

## Existing requirement-trace mapping

This delta strengthens existing `docs/verification/REQUIREMENT_TRACE.md` rows AC-01, AC-03, AC-11, AC-13 and AC-14 without converting Android-device, signing, listening, human visual-quality, performance or final release acceptance to PASS. AC-02/AC-15/AC-16 release-signing portions remain outside R01. The historical W23–W28 record remains authoritative and must not be overwritten by this contract.

## Mutation boundary

Allowed in R01: this contract, the R01 integration/visual harnesses, and the R01 workflow. Product source, version identity, signing files/secrets, Android package IDs and unrelated verification history are immutable unless the new runtime test reproduces an actual in-scope blocker that requires a subsequent separately evidenced fix.

## Prevention-rule application

- PR-001 PROBE_SIDE_EFFECT: PASS — read-only repository/source discovery established the gap before any mutation; no workflow was created merely to test tool capability.
- PR-002 NOOP_TRIGGER_COMMIT_DRIFT: PASS — the candidate commit contains substantive test/workflow/documentation changes; no empty trigger commit is permitted.
- PR-004 ACTIONS_ARTIFACT_RERUN_IDENTITY_COLLISION: NOT_APPLICABLE for the initial NEW_RUN, with artifact naming still including both `github.run_id` and `github.run_attempt` so a later justified rerun cannot collide.

`PREVENTION_COMPLIANCE_STATUS=PASS`
