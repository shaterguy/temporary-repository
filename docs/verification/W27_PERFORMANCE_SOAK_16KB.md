# W27 performance, memory, soak, and Android 16 KB verification

Task: `SR-20260909-150106-PPO12Y`
Baseline branch: `v1.0.0-dev1`
Baseline commit before W27: `510dbda395b4a39fab16017a43a17bdb21b59f10`
Requirement mapping: `AC-15`, retained `AC-14` lifecycle/save durability, and non-regression `NR-01` through `NR-05`.

`TEST_CONTRACT_PREFLIGHT=VALID`
`ACTION_PREFLIGHT=VALID`

## Scope

W27 measures and gates the existing runtime foundations rather than adding new gameplay. The only W27 source-side additions are a remote performance/memory/save soak test, its dedicated GitHub Actions workflow, and this verification contract. It does not change gameplay rules, world/save schemas, package identity, version, signing lineage, permissions, networking, dependencies, content counts, or production release state.

The tested project contains no repository-owned `.so` or `.gdextension` native extension at this checkpoint. Android 16 KB compatibility is therefore checked against the exact pinned Godot `4.7.2-stable` Android release template that would supply the native engine libraries, while W28 remains responsible for the production-signed installable APK and update/install lineage.

## Automated contract

1. Pool/spatial pressure
   - Maintain a live set of exactly 384 pooled enemy states across 80 complete acquire/query/recycle waves.
   - Capacity must remain exactly 384 after the first wave; every wave must return to zero active entities.
   - Execute 8 spatial radius queries per wave for 640 total local-neighbor queries.
   - The bounded headless pressure section must finish within 8,000 ms on the GitHub-hosted runner.

2. Real scene lifecycle and memory/object growth
   - Load and instantiate the actual `game/ui/main_shell.tscn` entry point.
   - Warm the scene/resource path for 4 cycles, then perform 24 additional instantiate→expedition-input→cancel→free cycles.
   - After warmup, static-memory growth must be no greater than 64 MiB, object-count growth no greater than 24, node-count growth no greater than 8, and orphan-node growth exactly zero.
   - These are regression ceilings for the fixed CI environment, not a claim about final Android-device frame pacing.

3. Save/checkpoint soak
   - Create a clean W27 save root, then execute 96 sequential checkpoints.
   - Reload through a fresh runtime every 12 checkpoints.
   - Sequence numbers must remain monotonic and the final envelope readback must match the expected sequence.
   - The save-soak section must finish within 12,000 ms; total W27 headless soak must finish within 25,000 ms.

4. Android 16 KB binary compatibility
   - Verify the exact `toolchain.lock` Godot editor/template digests and Android Build Tools `35.0.1` identity before runtime work.
   - Download the pinned Godot Android export templates and locate `android_release.apk`.
   - Run Android `zipalign -c -P 16 -v 4` against that template APK.
   - Extract every `lib/arm64-v8a/*.so` and require each ELF `LOAD` segment alignment reported by `readelf -lW` to be at least `0x4000` (2^14 / 16 KiB).
   - Fail immediately if repository-owned `.so` or `.gdextension` files appear, because that would introduce a new native binary that requires its own 16 KB evidence.

Android’s official 16 KB guidance is the source for the ZIP and ELF checks: `https://developer.android.com/guide/practices/page-sizes`.

## Evidence boundaries

A passing W27 workflow establishes the fixed-runner pool/spatial regression ceiling, repeated real-scene lifecycle/object/memory ceiling, repeated save/checkpoint/reload integrity, and pinned Android-template 16 KB binary checks above. It does not establish real-device frame pacing, thermal behavior, low-memory-killer behavior, OEM-specific rendering behavior, or production-signed APK install/update acceptance. Those device-only observations remain explicitly `PENDING` rather than being inferred from headless CI.

W28 remains the first checkpoint allowed to create the production-signed installable APK and verify the durable production signing/update lineage required by the user.

## Preflight and prevention

- `PR-001`: satisfied by read-only repository/tool/workflow inspection before mutation; W27 does not create a probe workflow run or other state merely to discover capability.
- `PR-002`: satisfied by using a real W27 three-file change as the new CI identity; no no-op/zero-tree-diff trigger commit is allowed.
- Version-identity and formal-update-baseline rules are not triggered because W27 does not mutate version, package identity, or release baseline.
- New Actions execution is a `NEW_RUN` for the exact W27 commit identity, not a rerun of an older commit.

## Security delta

`SECURITY_DELTA=NONE`. W27 adds offline tests, CI inspection of pinned public toolchain binaries, and verification documentation only. It introduces no runtime network path, permission, credential handling, user-data flow, dependency change, signing-key operation, or deployment trust-boundary change.

## Result interpretation

`W27_AUTOMATED_RESULT=CI_GATED`. The authoritative result is the GitHub Actions run for the exact W27 commit. Real-device-only observations remain pending even if that run passes.
