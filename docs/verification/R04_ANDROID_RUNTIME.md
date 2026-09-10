# R04 Android production APK runtime verification

Task: `SR-20260910-121926-5B5U4L`
Continuation source task: `SR-20260909-150106-PPO12Y`
Product source SHA: `eb4b542275f13929334d72cc4e3eba492bb8ef9c`
Verification-only branch: `verify/r04-android-runtime`
Primary requirement mapping: `AC-14`
Non-regression mapping: `NR-03`, `NR-04`

`TEST_CONTRACT_PREFLIGHT_STATUS=PASS`
`ACTION_PREFLIGHT_STATUS=PASS`
`APPLICABLE_PREVENTION_RULES=PR-001,PR-002,PR-004,PR-007`
`PREVENTION_COMPLIANCE_STATUS=PASS`
`SECURITY_DELTA=NONE`

## Immutable product under test

R04 reuses W28 production output without rebuilding, resigning or repackaging it. Product SHA remains `eb4b542275f13929334d72cc4e3eba492bb8ef9c`, W28 artifact ID `10139569453`, APK SHA-256 `5ff25fec7915ce9c05c7d3cadccde4b00c9821dc0b5069228b8b239dc6a1bba5`, package `com.shaterguy.lanternfall`, version `1.0.0-dev1` / code `1`. The verification branch may differ from product SHA only at this document and `.github/workflows/r04-android-runtime.yml`.

## Confirmed translated-runtime failure

Run `34450534977` used Android 11 API 30 Google APIs x86_64, current Emulator 37 SwiftShader, ABI list `x86_64,x86,arm64-v8a,armeabi-v7a,armeabi`, page size 4096. Exact W28 artifact hash, APK hash, package/version and production v2/v3 signature passed, and first install returned `Success`.

The app left the white Godot splash: readiness white fraction changed from `0.9636675` in probes 1-4 to `0.0069584` in probe 5. Immediately afterward the application process died. Logcat/tombstone recorded `Fatal signal 4 (SIGILL)` for `com.shaterguy.lanternfall` GL thread, with the native backtrace inside `/system/lib64/libndk_translation.so`, specifically ARM SIMD/FP decode paths. Classification: `ANDROID_NDK_TRANSLATION_SIGILL`. This translated x86_64 runtime is not accepted as R04 product evidence.

GitHub `ubuntu-24.04-arm` was separately preflighted in run `34449593508`: host architecture was `aarch64`, but `/dev/kvm` was absent. Native ARM64 Android virtualization on that hosted runner is therefore unavailable.

## Translation-free ARM64 guest preflight

Run `34453215991` did not reach the intended environment capability test. The first failure was a harness ordering defect: the current hosted x64 runner did not have `$ANDROID_HOME/emulator/emulator` preinstalled, but the workflow invoked `emulator -version` before `sdkmanager` installed the `emulator` package. Classification: `HARNESS_EMULATOR_INSTALL_ORDER`; it provides no evidence for or against ARM64 guest support.

The corrected run preserves the same test contract and only changes provisioning order: first read the stable SDK package list, require `system-images;android-30;google_apis;arm64-v8a`, install `platform-tools`, `emulator`, and that ARM64 image, then invoke the emulator. If package availability and AVD creation succeed, it attempts an API 30 arm64-v8a guest with acceleration disabled so `libndk_translation` is not involved.

TEST_CONTRACT_BASELINE: environment-only R04 capability test; expected PASS requires SDK package availability, AVD creation, an ADB-visible booted API 30 guest and `ro.product.cpu.abi=arm64-v8a`. Package absence, architecture rejection, ADB timeout or boot timeout is a valid environment BLOCKED result, not an application FAIL.

ACTION_PREFLIGHT_BASELINE: repository `shaterguy/temporary-repository`, branch `verify/r04-android-runtime`, product SHA and W28 artifact identity unchanged. The harness provisioning sequence changed after the run-13 defect, so the affected new run uses a new commit/run identity rather than rerunning run 13.

Prevention compliance:
- PR-001 PASS: read-only logs identified the first run-13 failure before mutation; the next mutation is only the minimal harness-order correction needed to execute the already-approved capability test.
- PR-002 PASS: the commit changes actual provisioning behavior and is not a no-op/trigger-only commit.
- PR-004 PASS: diagnostic artifact identity includes both `github.run_id` and `github.run_attempt`.
- PR-007 PASS: product/version validation identity remains pinned; only the R04 environment selector/provisioning changes.

## Completion rule

R04 may be PASS only when the exact immutable W28 APK completes the required Android runtime lifecycle without relying on an invalid translated-runtime result. If all available remote native/translation-free Android alternatives are unavailable, the automated environment gap must be recorded explicitly; it must not be mislabeled as application failure or runtime PASS. Physical-device-only characteristics remain post-delivery checks under the root and VERIFICATION SKILL delivery contract.
