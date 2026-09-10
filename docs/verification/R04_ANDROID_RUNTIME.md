# R04 Android production APK runtime verification

Task: `SR-20260910-121926-5B5U4L`
Continuation source task: `SR-20260909-150106-PPO12Y`
Product source SHA: `eb4b542275f13929334d72cc4e3eba492bb8ef9c`
Verification-only branch: `verify/r04-android-runtime`
Primary requirement mapping: `AC-14`
Non-regression mapping: `NR-03`, `NR-04`

`TEST_CONTRACT_PREFLIGHT=VALID`
`ACTION_PREFLIGHT=VALID`
`PREVENTION_RULES=PR-001,PR-002,PR-004,PR-007`
`SECURITY_DELTA=NONE`

## Immutable product under test

R04 reuses W28 production output without rebuilding, resigning or repackaging it.

- source SHA `eb4b542275f13929334d72cc4e3eba492bb8ef9c`
- W28 run `34445663426`
- artifact ID `10139569453`
- artifact archive SHA-256 `de7d0e1c0095eb80f26b9d7d8eec17b872a6e3928e5c7f510ac5b9352fff1169`
- APK `LANTERNFALL-1.0.0-dev1-production.apk`
- APK SHA-256 `5ff25fec7915ce9c05c7d3cadccde4b00c9821dc0b5069228b8b239dc6a1bba5`
- package `com.shaterguy.lanternfall`, version name `1.0.0-dev1`, version code `1`

The verification branch may differ from the product SHA only at `.github/workflows/r04-android-runtime.yml` and this document.

## Prior runtime findings

Run `34449013747` used Android 11 / API 30 Google APIs `x86_64` with ARM binary translation. The runtime exposed `x86_64,x86,arm64-v8a,armeabi-v7a,armeabi`, page size 4096, verified the exact W28 artifact hashes and v2/v3 production signature, and installed the exact APK successfully. The app then remained on the Godot splash and reached an Android ANR dialog before a valid game-ready state. Slot/hub/expedition screenshot hash changes from that run are therefore rejected as false-positive state evidence. Classification: `TRANSLATED_RUNTIME_ANR`.

Run `34449593508` tested GitHub's `ubuntu-24.04-arm` hosted runner as a native ARM64 host. The runner reported `aarch64` on Ubuntu 24.04.4 with 4 CPUs and about 16 GB RAM, but `/dev/kvm` was absent. Native ARM64 Android virtualization on that hosted runner is therefore blocked by environment capability. Classification: `NATIVE_ARM_HOST_KVM_UNAVAILABLE`. This is not an application failure.

## Current renderer retry

The failed translated-runtime probe used Emulator 37 with `-gpu swiftshader_indirect`, an option deprecated by current Android Emulator releases. Android's current graphics guidance recommends `swiftshader` or `software` when graphics emulation is problematic.

The current R04 workflow therefore retries the same exact Android 11 translated runtime with the supported `-gpu swiftshader` backend and stronger readiness evidence:

- exact W28 artifact and APK hash reuse is rechecked;
- package, version and production certificate identity are rechecked;
- logcat runs continuously from before application launch;
- Android ANR/system wait dialogs are checked through UIAutomator during startup and state transitions;
- the app is not considered game-ready while the screen remains dominated by the known white Godot splash; readiness requires the white-pixel ratio to fall below the bounded threshold and no ANR dialog;
- only after game readiness are slot-to-hub, expedition entry, actual Android touch injection, background checkpointing, process death/relaunch, saved-expedition reentry and Android resize/reentry exercised;
- actual screenshot dimensions are used to transform the game's 1280x720 logical touch coordinates, avoiding headless-orientation assumptions;
- all screenshots, runtime profile, package/signing data, live/final logcat and readiness probes are uploaded using run-ID/run-attempt evidence identity.

A failure before `R04_GAME_READY=PASS` is not allowed to masquerade as successful gameplay verification.

## Historical update, 16 KB and physical-device boundary

No prior user-installed production version exists in task evidence, so no fabricated in-place update test is performed. A genuine upgrade test requires an earlier production APK signed by the same certificate and a candidate with a higher `versionCode`.

W28 static/package evidence already verifies native 16 KB compatibility. The Android 11 translated runtime is a 4 KB runtime and is not labeled as an actual 16 KB runtime test.

Physical-device-only characteristics remain post-delivery checks: thermal throttling, OEM low-memory-killer behavior, device-specific cutouts and gesture navigation, haptic feel, sustained touch latency and human play feel.

## Completion rule

R04 may emit `R04_ANDROID_RUNTIME=PASS` only if the immutable W28 APK actually leaves the splash, reaches game readiness without an ANR, then completes install, launch, menu/expedition interaction, touch, lifecycle, process-death/relaunch, persistence reentry and resize reentry in the same run. If the current supported renderer still produces an ANR, R04 remains incomplete and the result must identify the remote Android environment gap instead of claiming success.
