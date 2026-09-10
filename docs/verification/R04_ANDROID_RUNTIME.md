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

R04 reuses the rebuilt W28 production APK without rebuilding, resigning or repackaging it.

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

## Reused R04 evidence and repaired product gap

Earlier R04 attempts established the remote-environment boundaries before this candidate:

- Android 11/API30 x86_64 translation installed the older production APK but later crashed inside Android `libndk_translation.so` with SIGILL; that was classified as translated-runtime failure rather than application code failure.
- GitHub's hosted ARM64 runner had no `/dev/kvm`; the x86_64 hosted runner's emulator explicitly rejected a native arm64 system image because the guest architecture must match the host.
- Android 16/API36 Google APIs x86_64 exposed both `x86_64` and `arm64-v8a` through `libndk_translation.so` and installed the product successfully without the API30 translator SIGILL.
- API36 run `34455506910` exposed a real product usability gap: save-slot and hub departure were keyboard-only while touch controls activated only after expedition entry. The W25 repair added standard Godot Button controls that forward to the existing authoritative `select_save_slot()` and `select_world_choice()` methods. W25 run `34456594450` verified actual scene transitions `SLOT_SELECT -> HUB -> EXPEDITION` through the mounted controls.
- The same earlier API36 run using `-gpu swiftshader` rendered black and logged `active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`, so black frames are explicitly rejected and that renderer combination is not reused.

The rebuilt production APK contains the touch-entry repair and retains the same durable production signing certificate.

## Harness failures excluded from product evidence

R04 run `34458136289` stopped before Android provisioning because the metadata certificate fingerprint was compared case-sensitively. Direct artifact readback showed the same fingerprint digits with uppercase metadata versus lowercase pinned value. The harness now normalizes both.

R04 run `34458472387` advanced further: exact artifact reuse PASS, API36 `-gpu software` runtime PASS, package/version/certificate PASS, production APK install PASS and `adb root` PASS. It then stopped immediately after launch before the first rendered-frame assertion because Bash `set -u` evaluated `${idx}` inside a combined `local` declaration before `idx` was bound. Classification: `HARNESS_BASH_LOCAL_NOUNSET_ORDER`. This run provides no renderer or touch-navigation PASS/FAIL evidence. The correction separates dependent local declarations and simplifies the runtime harness; product SHA, APK, signer, Android image and renderer are unchanged.

## Current TEST_CONTRACT_PREFLIGHT

Status: `PASS` before the corrected run.

A valid R04 PASS requires all of the following in the same run:

- exact product ancestry and exactly two verification-only changed files;
- exact W28 artifact archive, APK SHA-256, package/version and production certificate lineage;
- API36 Google APIs x86_64 runtime with `arm64-v8a` translation ABI and recorded native bridge;
- current `-gpu software` renderer, with visible/nonblank screenshot evidence and immediate rejection of the known shader-uniform-limit error;
- first-install package state;
- real Android touchscreen input, not keyboard input, for first save-slot selection and hub departure;
- save JSON transition to `HUB` with `last_checkpoint_reason=new_game` after the first touch choice;
- save JSON transition to `EXPEDITION` with `last_checkpoint_reason=departure_initialized` after the second touch choice;
- actual virtual-stick touchscreen swipe changes the persisted player position, with dodge/phase touchscreen events injected as well;
- HOME/background creates a later EXPEDITION checkpoint with `last_checkpoint_reason=background`;
- process death/relaunch preserves the same expedition identity and touch reentry restores that expedition;
- 1024x768 resize/relaunch preserves the same expedition identity and remains visibly rendered;
- no package ANR, fatal exception, SIGILL or SIGSEGV evidence;
- 16 KB compatibility remains the exact W28 static/package evidence and is not falsely labeled as a 16 KB runtime test on the 4 KB translated guest.

## Current ACTION_PREFLIGHT

Status: `PASS`.

- repository: `shaterguy/temporary-repository`
- product source: `v1.0.0-dev1` / `9d1743676e6c17fd573675d5065e346bef9546ea`
- signing source: `sign/w28-production` / same SHA
- W28 production run: `34457263441`
- R04 mutation boundary: only `.github/workflows/r04-android-runtime.yml` and this document
- run `34458472387` is not rerun because the workflow execution identity changes to fix the confirmed Bash harness defect;
- no product code, package/version, signer, save schema or production artifact mutation occurs in R04.

Prevention compliance:

- PR-001 PASS: run-21 logs were read directly and the first failure was identified before mutation.
- PR-002 PASS: the next commit changes actual harness execution behavior and is not a no-op trigger commit.
- PR-004 PASS: R04 evidence artifacts contain both `github.run_id` and `github.run_attempt` in identity.
- PR-007 PASS: Android API, Build Tools, package/version and product identity remain aligned to authoritative `toolchain.lock`, and the previously failed renderer profile is not silently reused.

## Completion rule

`R04_ANDROID_RUNTIME=PASS` may be emitted only after the immutable rebuilt production APK completes visible render, real touchscreen first-run navigation, expedition touch input, background checkpoint, process-death/relaunch persistence and resize/reentry without fatal/ANR/native-crash evidence.

A renderer/environment failure remains an environment result and is not promoted to application PASS. A reproducible product defect returns to BUILDER rather than being bypassed in the R04 harness.
