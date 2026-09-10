# R04 Android production APK runtime verification

Task: `SR-20260910-121926-5B5U4L`
Continuation source task: `SR-20260909-150106-PPO12Y`
Product source SHA: `eb4b542275f13929334d72cc4e3eba492bb8ef9c`
Verification-only branch: `verify/r04-android-runtime`
Primary requirement mapping: `AC-14`
Non-regression mapping: `NR-03`, `NR-04`

`TEST_CONTRACT_PREFLIGHT=VALID`
`PREVENTION_RULES=PR-001,PR-002,PR-004,PR-007`
`SECURITY_DELTA=NONE`

## Immutable product under test

R04 reuses the already-built W28 production APK without rebuilding, resigning or repackaging it.

- source SHA `eb4b542275f13929334d72cc4e3eba492bb8ef9c`
- W28 run `34445663426`
- artifact ID `10139569453`
- artifact `lanternfall-1.0.0-dev1-production-34445663426-1`
- artifact archive SHA-256 `de7d0e1c0095eb80f26b9d7d8eec17b872a6e3928e5c7f510ac5b9352fff1169`
- APK `LANTERNFALL-1.0.0-dev1-production.apk`
- APK SHA-256 `5ff25fec7915ce9c05c7d3cadccde4b00c9821dc0b5069228b8b239dc6a1bba5`
- package `com.shaterguy.lanternfall`, version name `1.0.0-dev1`, version code `1`

The verification branch may differ from the product SHA only at `.github/workflows/r04-android-runtime.yml` and this document.

## Completed translated-runtime probe

GitHub Actions run `34449013747` used an Android 11 / API 30 Google APIs `x86_64` emulator exposing `x86_64,x86,arm64-v8a,armeabi-v7a,armeabi` through ARM binary translation. The runtime page size was 4096 bytes. The exact W28 archive and APK digests passed, APK v2/v3 signature verification passed, production certificate SHA-256 was `114bb489ccfdcd7137b70aeb3230bbdd29af08f0e3155ee817419e1afd8269ef`, and the exact APK installed successfully.

The translated runtime did not reach a valid game-ready state. Evidence screenshots show the Godot splash persisting after launch and later an Android application-not-responding dialog. Therefore no slot, hub, expedition, touch, lifecycle or save-recovery transition from this run is accepted as R04 PASS evidence. The translated-runtime outcome is classified as `TRANSLATED_RUNTIME_ANR`, not as a proven production defect on a native arm64 Android device.

## Native ARM64 escalation rationale

The product APK contains only `arm64-v8a` native code. Because the translated x86_64 runtime produced an ANR before game readiness, the next verification target is a native Linux ARM64 host running an arm64 Android system image, if the hosted environment provides the required KVM capability.

GitHub currently exposes `ubuntu-24.04-arm` hosted runners. Android's emulator release notes describe Linux ARM64-host support for arm64 system images with KVM through an ARM64 emulator build. GitHub's ARM runner image does not preinstall Android SDK tooling, so native execution requires separate emulator/toolchain provisioning after host capability is established.

The current workflow is intentionally limited to a low-cost host preflight. It validates:

- runner architecture is `aarch64`;
- product source remains byte-for-byte unchanged outside the two verification files;
- `/dev/kvm` exists and is readable/writable;
- baseline Java, Python and curl tooling is present;
- package availability information needed for native provisioning is captured.

Only after this preflight succeeds may an expensive ARM64 emulator build/provisioning path be added. A preflight failure is an environment limitation and must not be represented as an application failure.

## Historical update, 16 KB and physical-device boundary

There is no prior user-installed production version in the task evidence, so R04 does not fabricate an in-place upgrade test. A future upgrade test requires a genuine earlier production APK signed by the same certificate and a candidate with a higher `versionCode`.

W28's native 16 KB compatibility evidence remains valid static/package evidence. Neither the translated Android 11 probe nor this host preflight is an actual 16 KB runtime test.

Physical-device-only characteristics remain post-delivery checks: thermal throttling, OEM low-memory-killer behavior, device-specific cutouts and gesture navigation, haptic feel, sustained touch latency and human play feel.

## Completion rule

R04 may be marked complete only from a runtime that actually reaches the game UI and demonstrates the required install, launch, interaction, lifecycle, process-death/relaunch and save-recovery outcomes on the immutable W28 APK. The translated x86_64 run does not satisfy that rule.
