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

## Scope

R04 is an expensive remote Android runtime gate for the already-built W28 production APK. It must not rebuild, resign, repackage, or otherwise alter the product under test.

Canonical product inputs are pinned before runtime execution:

- source SHA `eb4b542275f13929334d72cc4e3eba492bb8ef9c`;
- W28 run `34445663426`;
- artifact ID `10139569453`;
- artifact `lanternfall-1.0.0-dev1-production-34445663426-1`;
- artifact archive SHA-256 `de7d0e1c0095eb80f26b9d7d8eec17b872a6e3928e5c7f510ac5b9352fff1169`;
- APK `LANTERNFALL-1.0.0-dev1-production.apk`;
- APK SHA-256 `5ff25fec7915ce9c05c7d3cadccde4b00c9821dc0b5069228b8b239dc6a1bba5`;
- package `com.shaterguy.lanternfall`, version name `1.0.0-dev1`, version code `1`;
- production certificate identity verified against immutable W28 metadata.

The verification branch may differ from the product SHA only at `.github/workflows/r04-android-runtime.yml` and this document. Product code, assets, project/export configuration and toolchain identity remain sourced from the product SHA.

## TEST_CONTRACT_PREFLIGHT

Status: `VALID`.

The source contract establishes Godot 4.7.2, JDK 17, min API 24, target API 36, build-tools 36.1.0, production ABI `arm64-v8a`, CI emulator ABI `x86_64`, production package/version identity and the Android main scene. W25 already verifies deterministic touch ownership, pause/focus cancellation, safe-area geometry and save recovery in headless tests while explicitly leaving OS kill/relaunch and actual Android execution to a later gate. W28 already verifies package identity, production signing, APK integrity and native 16 KB compatibility.

R04 therefore validates observable Android runtime outcomes on the exact W28 APK: artifact reuse, translated ARM64 runtime availability, fresh install, package/version/certificate consistency, launch, slot-to-hub transition, expedition entry, real Android touch injection, background checkpoint path, process death/relaunch, saved-expedition reentry and Android window-size override/reentry without fatal runtime errors.

## ACTION_PREFLIGHT

Status: `VALID`.

Execution is bounded to a GitHub-hosted Ubuntu 24.04 x64 runner with KVM and an Android 11 / API 30 Google APIs `x86_64` emulator. That Android 11 image family supports ARM binary translation; R04 additionally requires the booted image to expose both `x86_64` and `arm64-v8a` in `ro.product.cpu.abilist` before installing the arm64-only production APK.

The runner's actual AVD directory is discovered from `avdmanager` output conventions and bound through `ANDROID_AVD_HOME`; no fixed `$HOME/.android` assumption is used. ADB device exposure and Android boot have bounded waits with emulator diagnostics on failure. Runtime display orientation is not assumed in headless mode: screenshot dimensions are recorded, and touch coordinates are transformed from the game's 1280x720 logical viewport into the actual captured display. The resize path applies a 1024x768 window-size override, relaunches and re-enters the saved slot, records the actual resulting screenshot dimensions and checks that the app remains foreground without a fatal exception.

The pre-existing W28 artifact is downloaded by artifact ID and verified by archive digest, APK digest and metadata before use. No signing secret or keystore is accessed, no product artifact is rebuilt, and no tag or GitHub Release is created. Evidence artifact names include run ID and run attempt.

## Historical update-path handling

There is no prior user-installed production version in the task evidence, so R04 does not fabricate an in-place upgrade test. A future upgrade test requires a genuine earlier production APK signed by the same certificate and a candidate with a higher `versionCode`.

Expected marker: `R04_HISTORICAL_IN_PLACE_UPDATE=NA_NO_PRIOR_USER_VERSION`.

## 16 KB and physical-device boundary

W28's native 16 KB compatibility evidence is reused; R04's Android 11 translated emulator is a 4 KB runtime and is not mislabeled as an actual 16 KB runtime test.

Expected marker: `R04_16KB_RUNTIME=NOT_EXERCISED_REUSE_W28_STATIC`.

Physical-device-only characteristics remain post-delivery checks: thermal throttling, OEM low-memory-killer behavior, device-specific cutouts and gesture navigation, haptic feel, sustained touch latency and human play feel.

Expected marker: `R04_PHYSICAL_DEVICE_THERMAL_LMK_HAPTICS=POST_DELIVERY_CHECK`.

## Completion

The workflow may emit `R04_ANDROID_RUNTIME=PASS` only after all preflight, exact artifact identity, emulator environment, installation, launch, interaction, lifecycle, persistence-reentry, resize and fatal-log checks have passed in the same run.
