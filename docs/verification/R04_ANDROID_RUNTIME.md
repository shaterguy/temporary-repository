# R04 Android production APK touch runtime verification

Task: `SR-20260910-121926-5B5U4L`
Continuation source task: `SR-20260909-150106-PPO12Y`
Product source SHA: `9d1743676e6c17fd573675d5065e346bef9546ea`
Verification-only branch: `verify/r04-android-runtime-touch-fix`
Primary requirement mapping: `AC-14`
Non-regression mapping: `NR-03`, `NR-04`

`TEST_CONTRACT_PREFLIGHT_STATUS=PASS`
`ACTION_PREFLIGHT_STATUS=PASS`
`PREVENTION_RULES=PR-001,PR-002,PR-004,PR-007`
`PREVENTION_COMPLIANCE_STATUS=PASS`
`SECURITY_DELTA=NONE`

## Immutable rebuilt production candidate

R04 reuses the new W28 production output without rebuilding, resigning or repackaging it.

- source SHA `9d1743676e6c17fd573675d5065e346bef9546ea`
- W28 run `34457263441`
- artifact ID `10144017998`
- artifact archive SHA-256 `63df625cba720ce3cdbc67edf3b71f74b1b0c872421a061e6cee5d5f069a70a5`
- APK `LANTERNFALL-1.0.0-dev1-production.apk`
- APK SHA-256 `8f0451935e4171021fc25a959dc99cdb25421e5980d2f72ffd218f01bbe4b2d0`
- package `com.shaterguy.lanternfall`, version name `1.0.0-dev1`, version code `1`
- production certificate SHA-256 `114bb489ccfdcd7137b70aeb3230bbdd29af08f0e3155ee817419e1afd8269ef`
- W28 package/version/signature/16 KB verification: PASS

The verification branch may differ from the product SHA only at `.github/workflows/r04-android-runtime.yml` and this document.

## Evidence reused from earlier R04 attempts

Android 11 / API 30 Google APIs x86_64 with ARM binary translation installed and launched the earlier production APK but later produced SIGILL inside Android's `libndk_translation.so`. The native crash was in the translated-runtime layer, not in the product source.

A GitHub hosted ARM64 runner was then proven unsuitable for native Android virtualization because `/dev/kvm` was absent. A separate x86_64-host ARM64-system-image preflight proved that the current Android Emulator refuses an arm64 guest on an x86_64 host with `System image must match the host architecture`.

API36 run `34455506910` established a newer viable translated runtime: Android 16 Google APIs x86_64 exposed `arm64-v8a`, installed the production APK and ran the application without the API30 translator SIGILL. That run exposed two distinct gaps:

1. Product gap: the first-run slot and hub transitions were keyboard-only, while touch input existed only after expedition entry. The W25 repair added standard Godot Button controls that forward to the existing authoritative `select_save_slot()` and `select_world_choice()` methods. W25 run `34456594450` independently verified the real scene transition `SLOT_SELECT -> HUB -> EXPEDITION` through those mounted controls.
2. Renderer gap: the API36 `-gpu swiftshader` run produced black screenshots and logged `active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`. A black frame must not be accepted as a valid ready state merely because it is not white.

The rebuilt production APK above includes the product touch repair and was signed by the same durable production certificate as the earlier production artifact.

R04 run `34458136289` on the rebuilt artifact stopped before Android provisioning. The artifact ZIP and APK SHA-256 both matched, but the verification harness compared the certificate metadata with case-sensitive text. The W28 metadata stores the same certificate SHA-256 in uppercase while R04 pins the normalized value in lowercase. Direct artifact readback confirmed all certificate bytes/digits match. Classification: `HARNESS_CERTIFICATE_CASE_NORMALIZATION`. The correction normalizes the metadata fingerprint before comparison; no product, signer, artifact or expected certificate identity changes.

## Current TEST_CONTRACT_PREFLIGHT

Status: `PASS` before the corrected Actions execution.

The test is bound to the exact product SHA, W28 artifact/archive/APK hashes, package/version, certificate lineage, API36 Google APIs x86_64 image and the production source contracts for save/checkpoint/touch behavior.

A valid R04 PASS requires all of the following in the same run:

- the verification branch differs from the product SHA only by the R04 workflow and this document;
- the exact W28 artifact archive and APK hashes are rechecked before installation;
- metadata certificate SHA-256 is case-normalized and equals the pinned production certificate lineage;
- API36 boots on x86_64, exposes both x86_64 and arm64-v8a ABI capability, and records the native bridge;
- the emulator uses current `-gpu software` selection rather than the already-failed `swiftshader` configuration;
- game readiness requires a visible, nonblank rendered frame with sufficient color/variance, not merely a low white-pixel fraction;
- the known API36 shader-limit error immediately fails the renderer gate;
- no keyboard input is used for the user-facing first-run navigation;
- an actual Android touchscreen tap on the mounted first slot Button creates the HUB/new_game save state;
- a second actual touchscreen Button tap creates the EXPEDITION/departure_initialized save state;
- an actual touchscreen virtual-stick drag changes the persisted player position, while dodge/phase touch paths are also injected;
- HOME/background creates an EXPEDITION/background checkpoint with increasing sequence;
- process death and relaunch preserve the same expedition ID, and touchscreen slot selection resumes the saved expedition;
- resize/relaunch at 1024x768 also resumes the same saved expedition through touch;
- package fatal exceptions, ANR, SIGILL and SIGSEGV tombstones are absent;
- the run does not label its 4 KB translated guest as an actual 16 KB runtime test; W28 binary compatibility remains reused static evidence.

The touchscreen choice helper scans only the vertical row where the standard Godot choice Button can exist and checks the authoritative save transition after each tap. It stops immediately when the target state is observed. This is an actual input-path test, not a direct method call or save-file fabrication.

## Current ACTION_PREFLIGHT

Status: `PASS` before mutation/execution.

- repository: `shaterguy/temporary-repository`
- product branch/source: `v1.0.0-dev1` / `9d1743676e6c17fd573675d5065e346bef9546ea`
- signing branch/source: `sign/w28-production` / same SHA
- W28 production run: `34457263441`
- R04 mutation boundary: only `.github/workflows/r04-android-runtime.yml` and `docs/verification/R04_ANDROID_RUNTIME.md`
- workflow contract changes from run `34458136289` only in certificate metadata normalization, so a new run is required rather than rerunning the old workflow identity;
- product code, package/version, signer, save schemas and production APK are immutable during R04;
- R04 evidence artifact identity contains both `github.run_id` and `github.run_attempt`.

Prevention compliance:

- PR-001 PASS: run logs and the immutable W28 artifact metadata were read directly before correcting the comparison; no mutation probe was used.
- PR-002 PASS: the verification commit changes the actual certificate verification behavior and is not a no-op/trigger-only commit.
- PR-004 PASS: R04 evidence artifacts are attempt-specific and consumers are bound to the exact new W28 artifact ID/hash.
- PR-007 PASS: API target, Build Tools, product identity and runtime selector are aligned to authoritative `toolchain.lock`; the already-failed renderer path is not silently reused.

## Completion rule

`R04_ANDROID_RUNTIME=PASS` is emitted only after the immutable rebuilt production APK passes visible render, real touchscreen first-run navigation, expedition touch input, background checkpoint, process-death/relaunch persistence and resize/reentry without fatal/ANR/native crash evidence.

If `-gpu software` still cannot render the actual game while package/runtime execution otherwise survives, R04 remains incomplete and the next automatic alternative is a separately preflighted renderer configuration. A renderer/environment failure is not converted into an application PASS, and a newly reproduced product defect is returned to BUILDER rather than worked around in the verification harness.
