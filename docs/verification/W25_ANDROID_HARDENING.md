# W25 Android input, accessibility, lifecycle and save-failure hardening

Task: `SR-20260909-150106-PPO12Y`
Branch: `v1.0.0-dev1`
Baseline before W25: `59403b5a2673728b3ab8570ac065605f2763ed41`
Primary requirement mapping: `AC-14`
Non-regression mapping: `NR-03`, `NR-04`

`TEST_CONTRACT_PREFLIGHT=VALID`
`ACTION_PREFLIGHT=VALID`
`PREVENTION_RULES=PR-001,PR-002`

## Scope

W25 is a bounded Android/mobile hardening slice. It adds a runtime touch-control component without replacing the already verified W24 shell entry point. Version identity, package identity, signing lineage, save schema and campaign settlement semantics are unchanged.

Implemented contract:

- independent pointer IDs for movement, dodge and phase input; a second movement pointer cannot steal the active stick;
- fixed or floating virtual stick, left/right-handed inversion, bounded control scale and opacity, haptics opt-out, reduced-flash and reduced-motion preference flags;
- circular dodge and diamond phase controls so the two primary actions are not distinguished by color alone;
- safe-area-aware control layout checked at 1280x720, 1600x720, 1760x720 and 1024x768 logical viewports;
- application pause/focus loss and viewport changes cancel transient touch ownership before stale pointers can remain latched;
- the overlay forwards only transient movement/dodge/phase state into the existing W12+ combat bridge; auto attack and prior gameplay semantics remain unchanged;
- existing SaveStore durability is exercised against stale temporary files, interrupted primary-to-backup promotion, corrupt-primary recovery, an invalid storage parent and double corruption.

## TEST_CONTRACT_PREFLIGHT

Status: `VALID`.

Authority sources were the current W24 shell, `platform/android/safe_area.gd`, `game/core/save_store.gd`, existing SaveStore unit coverage, and the current scene. The new W25 tests assert observable state and file outcomes rather than implementation-only constants. Existing foundation/W22/W23/W24 expectations are reused unchanged because the scene continues to point directly at `main_shell_w24.gd`; W25 is an additive child control.

Expected W25 smoke markers:

- `W25_LAYOUT_MATRIX=1280x720,1600x720,1760x720,1024x768`
- `W25_MULTITOUCH=PASS`
- `W25_ACCESSIBILITY=PASS`
- `W25_LIFECYCLE_INPUT_RESET=PASS`
- `W25_SAVE_RECOVERY=PASS`
- `W25_ANDROID_HARDENING=PASS`

The test does not claim physical-device cutout/gesture-navigation coverage, genuine low-storage exhaustion, OS kill/relaunch, thermal/performance acceptance, or production signing. Those remain later Android/device gates, principally W27/V02/REL.

## ACTION_PREFLIGHT

Status: `VALID`.

- baseline SHA: `59403b5a2673728b3ab8570ac065605f2763ed41`
- intended mutation: W25 input model + overlay + scene mount + W25 unit/integration tests + this document + W25 workflow
- unchanged identity: `versionName=1.0.0-dev1`, `versionCode=1`, PROD package `com.shaterguy.lanternfall`, DEV suffix `.dev`
- unchanged persistence identity: `lanternfall-world-v2`, `lanternfall-save-payload-v1`
- no new network access, account system, broad storage permission, analytics, advertising, payment, Android permission or signing material
- CI uses the repository-pinned Godot version/digest and a pinned checkout action; no test-only product behavior or no-op trigger commit is introduced

## Residual risk

Headless CI can validate pointer ownership, deterministic layout geometry, scene integration and file recovery semantics but cannot replace real-device feel, touch latency, cutout/gesture-nav behavior or low-storage fault injection. Those are retained as explicit later gates rather than being reported as W25 PASS.
