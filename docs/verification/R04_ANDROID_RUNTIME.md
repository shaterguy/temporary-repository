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

R04 reuses W28 production output without rebuilding, resigning or repackaging it. Product SHA remains `eb4b542275f13929334d72cc4e3eba492bb8ef9c`, W28 artifact ID `10139569453`, artifact ZIP SHA-256 `de7d0e1c0095eb80f26b9d7d8eec17b872a6e3928e5c7f510ac5b9352fff1169`, APK SHA-256 `5ff25fec7915ce9c05c7d3cadccde4b00c9821dc0b5069228b8b239dc6a1bba5`, package `com.shaterguy.lanternfall`, version `1.0.0-dev1` / code `1`. The verification branch may differ from product SHA only at this document and `.github/workflows/r04-android-runtime.yml`.

## Exhausted Android 11 alternatives

Android 11 API30 x86_64 ARM translation run `34450534977` passed artifact identity, package/version/signature and first install, left the Godot splash, then died with `SIGILL` in `/system/lib64/libndk_translation.so` ARM SIMD/FP decode paths. Classification: `ANDROID_NDK_TRANSLATION_SIGILL`; this runtime is invalid as R04 evidence.

GitHub ARM hosted run `34449593508` confirmed `aarch64` host architecture but no `/dev/kvm`, so accelerated native ARM64 Android virtualization is unavailable there.

Translation-free guest run `34453580060` confirmed Android 11 `system-images;android-30;google_apis;arm64-v8a` and `qemu-system-aarch64` install successfully on the x86_64 host, but Emulator 37 rejects launch with `Avd's CPU Architecture 'arm64' is not supported by the QEMU2 emulator on x86_64 host. System image must match the host architecture.` Classification: `X64_HOST_ARM64_GUEST_UNSUPPORTED`. Thus the translation-free ARM64 guest alternative is environment BLOCKED.

## Current Android 16 API36 contract

The next automatic alternative is Android 16 / API36 Google APIs x86_64 with the current Emulator 37 SwiftShader renderer and its newer ARM64 NDK translation layer. This aligns the runtime API with the product target/compile SDK 36 while preserving the exact W28 APK.

TEST_CONTRACT_BASELINE:
- Environment gate: API 36 boot succeeds; `ro.product.cpu.abilist` contains both `x86_64` and `arm64-v8a`; native bridge and actual page size are recorded.
- Artifact gate: exact W28 artifact ZIP and APK hashes pass; package, versionCode/versionName, minSdk 24, targetSdk 36, `arm64-v8a`, and production certificate self-consistency pass; first install returns `Success`.
- Stable-launch gate: process remains alive and foreground, leaves the white Godot startup screen within 60 seconds, and no package-associated SIGILL, fatal signal, `libndk_translation` crash or ANR marker appears.
- State gate from product source: first `KEYCODE_1` creates slot 0 with save JSON `world.state=HUB` and `last_checkpoint_reason=new_game`; second `KEYCODE_1` reaches `world.state=EXPEDITION` with `last_checkpoint_reason=departure_initialized` and a valid `w12-runtime-state-v1` snapshot.
- Touch gate from `MobileInputModel`: at 1280x720 default safe geometry the fixed stick center is `(108,612)`, dodge center `(1200,640)`, and phase center `(1200,508)`. Injected Android touchscreen movement must cause the background-checkpoint player position to differ materially from origin `(640,360)`.
- Background/save gate: HOME must produce a newer save sequence with `last_checkpoint_reason=background`, preserving the same active expedition id.
- Process-death/relaunch gate: background process death followed by cold launch and slot selection must restore the expedition; a subsequent background checkpoint must advance sequence while preserving expedition id and the saved player position.
- Resize gate: after force-stop and `wm size 1024x768`, cold launch and slot selection must restore the same expedition, remain alive/foreground and checkpoint successfully; no runtime crash/ANR marker may appear.
- W28 static 16KB compatibility remains authoritative for 16KB packaging; thermal/LMK/haptic feel remains a physical-device post-delivery check; historical in-place update is N/A because no prior user version exists.

ACTION_PREFLIGHT_BASELINE: repository `shaterguy/temporary-repository`, branch `verify/r04-android-runtime`, pre-mutation HEAD `32028eb7eb55443289e6a0dd5752aff4c9f43b26`, product SHA and W28 artifact identity unchanged. The runtime contract changes from environment-only ARM64 guest probing to an actual API36 application R04 run, so a new commit/run identity is required rather than rerunning run 14.

Prevention compliance:
- PR-001 PASS: product input/save/runtime source and run-14 failure logs were read before mutation; no write was used to discover schema or state.
- PR-002 PASS: the commit changes the substantive runtime/test contract; it is not a trigger-only/no-op mutation.
- PR-004 PASS: R04 evidence artifact identity contains both `github.run_id` and `github.run_attempt`.
- PR-007 PASS: product/version/artifact validation identity remains pinned; only the Android validation environment changes.

## Completion rule

R04 is PASS only if the exact immutable W28 APK passes all API36 automated gates above. If API36 is environment-incompatible or repeats a native-bridge-only failure, the failure is classified by first root cause and the next compatible Android runtime alternative is tried automatically. A product/Godot crash outside the runtime bridge is not masked as environment failure. Physical-device-only characteristics may remain explicit `POST_DELIVERY_CHECK` items under the VERIFICATION SKILL delivery contract.
