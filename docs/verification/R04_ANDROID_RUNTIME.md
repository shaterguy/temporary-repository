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

Current remote readback before this renderer repair reconfirmed both `v1.0.0-dev1` and `sign/w28-production` at the exact product SHA. W28 run `34457263441` remains successful and artifact `10144017998` is unexpired with the pinned archive digest. `toolchain.lock` still pins API 36, Build Tools 36.1.0, primary ABI arm64-v8a, production package identity and Godot `gl_compatibility` rendering.

The verification branch may differ from the product SHA only at `.github/workflows/r04-android-runtime.yml` and this document.

## Reused R04 evidence and repaired product gap

Earlier R04 attempts established the remote-environment boundaries before this candidate:

- Android 11/API30 x86_64 translation installed the older production APK but later crashed inside Android `libndk_translation.so` with SIGILL; that was classified as translated-runtime failure rather than application code failure.
- GitHub's hosted ARM64 runner had no `/dev/kvm`; the x86_64 hosted runner's emulator explicitly rejected a native arm64 system image because the guest architecture must match the host.
- Android 16/API36 Google APIs x86_64 exposed both `x86_64` and `arm64-v8a` through `libndk_translation.so` and installed the product successfully without the API30 translator SIGILL.
- API36 run `34455506910` exposed a real product usability gap: save-slot and hub departure were keyboard-only while touch controls activated only after expedition entry. The W25 repair added standard Godot Button controls that forward to the existing authoritative `select_save_slot()` and `select_world_choice()` methods. W25 run `34456594450` verified actual scene transitions `SLOT_SELECT -> HUB -> EXPEDITION` through the mounted controls.
- An earlier API36 run using `-gpu swiftshader` rendered black and logged `active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS (261)`; that renderer combination is not reused.
- R04 run `34459160737` used Android Emulator 37.1.11 with API36 x86_64 translation and `-gpu software`. Exact artifact reuse, API36 translated runtime preparation, APK identity, production certificate and first install all passed. The first visible-frame check then stopped with the same `active uniforms exceed GL_MAX_FRAGMENT_UNIFORM_VECTORS` condition before any touch lifecycle step. Classification: `EMULATOR_RENDERER_GLSL_UNIFORM_LIMIT`; no application defect was established by that run.

The rebuilt production APK contains the touch-entry repair and retains the same durable production signing certificate.

## Harness failures excluded from product evidence

R04 run `34458136289` stopped before Android provisioning because the metadata certificate fingerprint was compared case-sensitively. Direct artifact readback showed the same fingerprint digits with uppercase metadata versus lowercase pinned value. The harness now normalizes both.

R04 run `34458472387` advanced further: exact artifact reuse PASS, API36 translated runtime PASS, package/version/certificate PASS, production APK install PASS and `adb root` PASS. It then stopped immediately after launch before the first rendered-frame assertion because Bash `set -u` evaluated `${idx}` inside a combined `local` declaration before `idx` was bound. Classification: `HARNESS_BASH_LOCAL_NOUNSET_ORDER`. This run provides no renderer or touch-navigation PASS/FAIL evidence. The correction separated dependent local declarations; product SHA, APK, signer and Android image were unchanged.

## Renderer decision for the next execution identity

Current Android Emulator source still recognizes `swangle` and normalizes it to the SwANGLE indirect backend on Linux. Current emulator release guidance also distinguishes explicit renderer modes from `-gpu software`, which chooses the best available software backend automatically. Therefore the next R04 identity uses explicit `-gpu swangle`, not the already failed automatic `software` profile and not the already failed `swiftshader` profile.

This is a verification-environment change only. It does not change the product source, APK, package/version, signing identity, save schema, toolchain lock or W28 artifact. The existing visible-frame rejection remains in place: a black/blank frame or the shader uniform-vector-limit signature cannot be promoted to application PASS.

## TEST_CONTRACT_PREFLIGHT for the SwANGLE run

Status: `PASS` after staging readback.

- exact product ancestry and two-file verification-only boundary: `VALID`; comparison against target head `ef7da392a2919c6c8b0877a84f42677d802456da` shows only `.github/workflows/r04-android-runtime.yml` and this document changed;
- exact W28 artifact archive, APK SHA-256, package/version and production certificate lineage: `VALID` from current remote/artifact readback plus in-run recheck;
- API36 Google APIs x86_64 runtime with arm64-v8a translation ABI and recorded native bridge: `VALID` and unchanged from the preceding R04 identity;
- renderer contract: `VALID`; workflow commit `9ee5841b46ecf1adb2f68de4101ea006bb85b43f` changes only the launch renderer `software -> swangle`, runtime renderer evidence label and final `R04_RENDERER` label;
- visible/nonblank screenshot assertion plus immediate known shader-limit rejection: `VALID` and retained;
- real Android touchscreen save-slot selection, hub departure, expedition movement, background checkpoint, process relaunch persistence and 1024x768 reentry: `VALID` and unchanged;
- package ANR/fatal/SIGILL/SIGSEGV checks: `VALID` and unchanged;
- 16 KB compatibility: `VALID` by exact W28 static/package evidence and is not relabeled as a 16 KB runtime test on the 4 KB translated guest;
- physical-device thermal/LMK/haptics: `POST_DELIVERY_CHECK`, not a fabricated emulator PASS;
- historical in-place update: `NOT_APPLICABLE` because there is no earlier user production version in this lineage.

A valid R04 PASS still requires all touch/lifecycle/persistence conditions in one successful runtime execution. No result from the failed `software` or `swiftshader` renderer identities is reused as visible-render or touch PASS evidence.

## ACTION_PREFLIGHT for the target branch advance

Status: `PASS` for a new workflow identity after target/artifact baseline readback.

The target action is a fast-forward of `verify/r04-android-runtime-touch-fix` from its read-back head to the fully reviewed staging commit. The target workflow is push-triggered on exactly the two R04 verification files, so both file changes were staged away from the trigger branch and the target ref is advanced only after final preflight. This prevents partial-file intermediate Actions runs.

Baseline locked for the final preflight:

- repository: `shaterguy/temporary-repository`
- product source branch/SHA: `v1.0.0-dev1` / `9d1743676e6c17fd573675d5065e346bef9546ea`
- signing source branch/SHA: `sign/w28-production` / same product SHA
- W28 production run: `34457263441`, conclusion `success`
- W28 production artifact: `10144017998`, unexpired, archive digest `sha256:63df625cba720ce3cdbc67edf3b71f74b1b0c872421a061e6cee5d5f069a70a5`
- immutable APK SHA-256: `8f0451935e4171021fc25a959dc99cdb25421e5980d2f72ffd218f01bbe4b2d0`
- target verification branch pre-change head: `ef7da392a2919c6c8b0877a84f42677d802456da`
- workflow: `.github/workflows/r04-android-runtime.yml`
- execution change: explicit `swangle` renderer and matching evidence label only; no product/build/signing mutation
- execution decision: `NEW_RUN`, because renderer/workflow execution identity changes; failed run `34459160737` is not rerun

Prevention compliance:

- PR-001 `PASS`: read-only branch, artifact, workflow, run-log and emulator renderer support checks preceded the mutation; no diagnostic Actions run was used as a probe.
- PR-002 `PASS`: the target advance contains a real renderer execution-contract change; no empty/no-op trigger commit was created.
- PR-004 `PASS`: R04 evidence artifact names continue to contain both `github.run_id` and `github.run_attempt`; the new workflow identity is executed as a new run.
- PR-007 `PASS`: API/Build Tools/ABI/package/version remain pinned to the current authoritative `toolchain.lock`; no stale version profile is substituted.

Immediately before target fast-forward, the target branch head and W28 artifact identity are read back once more. Any drift invalidates this preflight and blocks the target mutation rather than silently executing against a changed baseline.

## Completion rule

`R04_ANDROID_RUNTIME=PASS` may be emitted only after the immutable rebuilt production APK completes visible render, real touchscreen first-run navigation, expedition touch input, background checkpoint, process-death/relaunch persistence and resize/reentry without fatal/ANR/native-crash evidence.

A renderer/environment failure remains an environment result and is not promoted to application PASS. A reproducible product defect returns to BUILDER rather than being bypassed in the R04 harness.
