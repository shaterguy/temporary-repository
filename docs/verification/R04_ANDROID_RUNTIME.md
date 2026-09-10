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

## Current fail-fast alternative

The next run is environment capability preflight only. It does not rebuild or install the product APK and does not claim application behavior. It tests whether an x86_64 GitHub hosted runner can install an Android 11 Google APIs `arm64-v8a` system image and boot that ARM64 guest with emulator acceleration disabled, thereby avoiding `libndk_translation`.

TEST_CONTRACT_BASELINE: environment-only R04 capability test; expected PASS requires SDK package availability, AVD creation, an ADB-visible booted API 30 guest and `ro.product.cpu.abi=arm64-v8a`. Any package rejection, emulator architecture rejection, ADB timeout or boot timeout is a valid environment BLOCKED result, not an application FAIL.

ACTION_PREFLIGHT_BASELINE: repository `shaterguy/temporary-repository`, branch `verify/r04-android-runtime`, pre-mutation HEAD `aedfb261c965773b3a43591776755fcd234d49a3`, immutable product SHA and W28 artifact identity unchanged. Workflow contract changes, so a new push-triggered run is required rather than rerunning a previous run.

Prevention compliance:
- PR-001 PASS: official Android documentation and existing run/tombstone evidence were read before creating this necessary environment run; no mutation is used merely to inspect tool schema or status.
- PR-002 PASS: the commit changes the actual R04 validation contract; no no-op or trigger-only commit is created.
- PR-004 PASS: diagnostic artifact identity includes both `github.run_id` and `github.run_attempt`.
- PR-007 PASS: product/version validation identity remains pinned and unchanged; this run changes only the runtime environment selector and cannot be mistaken for a release/version profile.

## Completion rule

R04 may be PASS only when the exact immutable W28 APK completes the required Android runtime lifecycle without relying on an invalid translated-runtime result. If all available remote native/translation-free Android alternatives are unavailable, the automated environment gap must be recorded explicitly; it must not be mislabeled as application failure or runtime PASS. Physical-device-only characteristics remain post-delivery checks under the root and VERIFICATION SKILL delivery contract.
