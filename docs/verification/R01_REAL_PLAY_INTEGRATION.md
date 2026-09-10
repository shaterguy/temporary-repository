# R01 real-play integration contract

Task continuation: `SR-20260909-150106-PPO12Y` via `SR-20260910-121926-5B5U4L`
Baseline: `v1.0.0-dev1` initially at `57f721a089a87468fcd338455a52c0125e9c0de7`
Scope: signer-independent actual main-scene runtime integration evidence and the minimum presentation correction reproduced by that evidence.

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
- R01-06: the workflow must fail early on static/import/fast integration errors before rendering evidence. The evidence artifact must include test logs, render logs, current GitHub SHA/run identity, source hashes, six PNG hashes, and Korean-font resolution evidence.
- R01-07: the actual shared UI theme must resolve Korean U+C794 through the configured system-font/fallback chain, and the real status label must wrap within the main safe-area width at both capture resolutions.

## Reproduced presentation defect and correction boundary

Initial candidate `33e342f6044d8b30e6a66f2ce831e2ad3121ed1c` passed the mechanical R01 workflow, but direct inspection of its six PNG artifacts reproduced two user-visible defects: Korean text rendered as missing-glyph hexadecimal boxes, and long HUB status text extended beyond the horizontal safe area. Therefore that run is retained as mechanical evidence but is not accepted as visual/readability completion.

The correction is deliberately limited to presentation infrastructure in `game/ui/main_shell.tscn`: a shared `SystemFont` theme with Korean-capable names plus system fallback, and automatic wrapping for the status label. The R01 Linux review job provisions Noto CJK so its screenshot evidence is deterministic enough to catch missing-glyph regressions. This does not prove every Android vendor resolves system fonts identically; Android-device verification remains a later gate and a device failure must be fixed rather than waived.

## Action preflight correction

The initial mutation forecast incorrectly assumed only R01 and foundation workflows would start. Actual push evidence showed eight workflows started for `33e342f...`: `foundation-ci`, `r01-real-play-integration-ci`, `w18-region-ci`, `w19-region-ci`, `w20-boss-ci`, `w21-campaign-topology-ci`, `w22-endgame-ci`, and `w26-balance-ci`. Because this correction also changes `game/ui/main_shell.tscn`, path inspection additionally identifies `w25-android-hardening-ci` and `w27-performance-ci` as applicable. This known broader trigger set is part of the corrected action preflight; no empty or probe commit is used.

## Existing requirement-trace mapping

This delta strengthens existing `docs/verification/REQUIREMENT_TRACE.md` rows AC-01, AC-03, AC-11, AC-13 and AC-14 without converting Android-device, signing, listening, human gameplay-quality, performance or final release acceptance to PASS. AC-02/AC-15/AC-16 release-signing portions remain outside R01. The canonical trace must preserve historical evidence and receive the final R01 candidate/run after the corrective evidence is reviewed.

## Mutation boundary

Allowed in the corrective R01 iteration: the reproduced presentation defect in `main_shell.tscn`, the R01 visual harness, this contract, and the R01 workflow. Version identity, signing files/secrets, Android package IDs, gameplay authority, save schema and unrelated verification history remain immutable.

## Prevention-rule application

- PR-001 PROBE_SIDE_EFFECT: PASS — read-only repository/source discovery established both the original integration gap and the screenshot defect before mutation; no workflow was created merely to test tool capability.
- PR-002 NOOP_TRIGGER_COMMIT_DRIFT: PASS — both R01 commits contain substantive test or defect-correction changes; no empty trigger commit is permitted.
- PR-004 ACTIONS_ARTIFACT_RERUN_IDENTITY_COLLISION: NOT_APPLICABLE for each NEW_RUN. Artifact naming still includes both `github.run_id` and `github.run_attempt` so a later justified rerun cannot collide.

`PREVENTION_COMPLIANCE_STATUS=PASS`
