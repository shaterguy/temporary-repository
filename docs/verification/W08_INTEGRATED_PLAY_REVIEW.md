# W08 Integrated Play Review

## Objective
W08 provides fresh final-candidate integration evidence for the medieval rebuild without treating pre-rebuild or isolated W04/W05/W06 quality PASS results as current user-quality proof. It exercises the actual `game/ui/main_shell.tscn` entry path and combines real menu transitions, mobile touch movement, long-field camera tracking, naturally emitted weapon combat, 3D medieval presentation, and the active external-audio runtime in one run.

## Test contract
The authoritative automated review is `tests/visual/w08_integrated_play_review.tscn` launched as a normal Godot scene, not with `--script`. The normal-scene launch is required because `AudioDirector` intentionally disables playback setup for script-entry tooling.

The run must prove all of the following on the same GitHub candidate SHA:

1. The real shell starts in `SLOT_SELECT`, opens a real save slot into `HUB`, then starts an actual expedition with `select_world_choice`.
2. The actual HUB readability controller reports an opaque/high-contrast mobile menu contract (`dimmer_alpha >= 0.72`, `panel_alpha >= 0.94`, touch height >= 72 px, status font >= 20 px, button font >= 22 px, input blocking enabled).
3. Actual `InputEventScreenTouch`/`InputEventScreenDrag` events travel through the mobile-control overlay and shell bridge; the player moves at least 1600 gameplay pixels while remaining in the expedition.
4. The enabled `CombatCamera` continuously follows the runtime player within the declared error bound and the run captures start, mid-field, and far-field review states.
5. A naturally emitted `weapon_damage` action identifies a real weapon and is captured at trigger/travel/impact review points; the test does not fabricate a showcase-only combat stage.
6. The normal runtime `AudioDirector` reports `external_cc0_files`, procedural runtime audio disabled, 29 external media files, external medieval exploration/ambience streams, and routed external weapon plus hit SFX after the natural weapon action.
7. Seven required screenshots are present and have distinct SHA-256 values. `runtime-evidence.json` records the integrated flow, movement/camera measurements, combat action, audio routing paths, and readability metrics.

Expected completion markers include:

- `W08_REAL_ENTRY_FLOW=PASS`
- `W08_HUB_MENU_READABILITY=PASS`
- `W08_NATURAL_WEAPON_ACTION=PASS`
- `W08_TRAVEL_DISTANCE=<value >= 1600>`
- `W08_CAMERA_TRACKING=PASS`
- `W08_EXTERNAL_AUDIO_RUNTIME=PASS`
- `W08_COMBAT_AUDIO_ROUTING=PASS`
- `W08_REVIEW_SCREENSHOT_COUNT=7`
- `W08_LISTENING_REVIEW=REQUIRED`
- `W08_INTEGRATED_REVIEW=PASS`

## Perceptual gate
The workflow uploads the exact same candidate's integrated screenshots/evidence together with the external medieval music, ambience, weapon, combat-feedback, and UI audio files. Automated resource loading and routing do not prove subjective audio quality. Human listening on representative playback remains required before AC-05 can be upgraded to full PASS; W08 completion only establishes that the current integrated runtime routes the intended production files and produces a review package tied to one candidate SHA.

## Mid-plan review trigger
A successful W08 automated evidence bundle is the reserved planning checkpoint. After it is obtained, the remaining W09-W11 expansion and final verification plan must be re-evaluated before further implementation.
