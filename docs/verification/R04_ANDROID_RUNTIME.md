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

R04 is an expensive remote Android runtime gate for the already-built and already-verified W28 production APK. It must not rebuild, resign, repackage, or otherwise change the product under test.

Canonical product inputs are pinned before runtime execution:

- source SHA `eb4b542275f13929334d72cc4e3eba492bb8ef9c`;
- W28 run `34445663426`;
- artifact ID `10139569453`;
- artifact name `lanternfall-1.0.0-dev1-production-34445663426-1`;
- artifact archive SHA-256 `de7d0e1c0095eb80f26b9d7d8eec17b872a6e3928e5c7f510ac5b9352fff1169`;
- APK `LANTERNFALL-1.0.0-dev1-production.apk`;
- APK SHA-256 `5ff25fec7915ce9c05c7d3cadccde4b00c9821dc0b5069228b8b239dc6a1bba5`;
- package `com.shaterguy.lanternfall`, version name `1.0.0-dev1`, version code `1`;
- production certificate identity is verified against the immutable metadata carried by the same W28 artifact.

The R04 harness runs only on the verification branch. The cumulative diff from the product SHA must contain exactly this workflow and this document; all product code, assets, project configuration, export configuration and toolchain identity remain byte-for-byte sourced from the product SHA.

## TEST_CONTRACT_PREFLIGHT

Status: `VALID`.

The source contract was checked before creating the runtime action:

- `toolchain.lock` pins Godot 4.7.2, JDK 17, min API 24, target API 36, build-tools 36.1.0, production ABI `arm64-v8a`, CI emulator ABI `x86_64`, production package identity and version identity;
- `project.godot` pins the main scene and a 1280x720 logical viewport;
- `game/ui/main_shell.tscn` mounts the W25 mobile input overlay;
- the main shell starts in slot selection, accepts slot choice and expedition choice, checkpoints every 15 seconds and on application pause/focus loss, and resumes an occupied saved expedition;
- the mobile overlay consumes real Android touch/drag events in expedition mode and cancels transient pointers on pause/focus loss;
- W25 already validates deterministic touch ownership, safe-area geometry and save recovery in headless tests, while explicitly leaving OS kill/relaunch and actual Android runtime execution to a later gate;
- W28 already validates package identity, production signature, APK integrity and native 16 KB compatibility.

R04 therefore validates observable Android runtime outcomes rather than reasserting internal constants: exact artifact reuse, first install, package/version/certificate consistency, launch, slot-to-hub transition, expedition entry, real touch injection, background checkpoint path, process death and relaunch, saved-expedition reentry and a 1024x768 Android window resize/relaunch.

## ACTION_PREFLIGHT

Status: `VALID`.

Execution path is intentionally bounded:

- GitHub-hosted Ubuntu 24.04 x64 runner with KVM;
- Android 11 / API 30 Google APIs `x86_64` emulator image;
- the runtime must report both `x86_64` and `arm64-v8a` in `ro.product.cpu.abilist`, proving that the selected image exposes ARM translation before the arm64-only production APK is installed;
- runtime page size is recorded and required to be 4096 bytes for this R04 environment;
- physical screen is forced to 1280x720 for the primary path and 1024x768 for the resize path, with screenshot dimensions asserted rather than assumed;
- the pre-existing W28 artifact is downloaded by artifact ID and verified by archive digest and APK digest before use;
- no signing secret or keystore is accessed;
- no GitHub Release or version tag is created;
- no product artifact is rebuilt;
- evidence artifact naming includes both GitHub run ID and run attempt to avoid rerun identity collision.

Android 11 Google APIs x86/x86_64 images are selected because that generation provides ARM binary translation support for ARM-only applications while retaining hardware-accelerated x86_64 emulation. The workflow records the actual emulator version, installed SDK packages, ABI list, page size, package dump, signing dump, screenshots and logcat so the environment assumption is testable rather than implicit.

## Historical update-path handling

There is no prior user-installed production version in the task evidence. R04 therefore does not fabricate an in-place upgrade test. The current APK is verified as a fresh production-lineage install. Future production deployment testing must use a genuine prior production APK signed by the same certificate and a newer `versionCode` for the candidate update.

Expected marker:

`R04_HISTORICAL_IN_PLACE_UPDATE=NA_NO_PRIOR_USER_VERSION`

## 16 KB and physical-device boundary

The production APK's native 16 KB compatibility is reused from W28 and is not re-labeled as an actual 16 KB Android runtime test. The R04 emulator is intentionally a 4 KB Android 11 runtime used to execute the arm64-only production artifact through ARM translation.

Expected marker:

`R04_16KB_RUNTIME=NOT_EXERCISED_REUSE_W28_STATIC`

Physical-device-only characteristics remain post-delivery checks: thermal throttling, low-memory-killer behavior, OEM cutout and gesture-navigation behavior, haptic feel, sustained touch latency and human play feel. Their absence does not weaken the automated R04 install/lifecycle/save-recovery evidence, but they are not represented as remotely verified.

Expected marker:

`R04_PHYSICAL_DEVICE_THERMAL_LMK_HAPTICS=POST_DELIVERY_CHECK`

## Completion

The workflow may emit `R04_ANDROID_RUNTIME=PASS` only after all preflight, artifact identity, emulator environment, installation, launch, interaction, lifecycle, persistence-reentry, resize and fatal-log checks have passed in the same run.
