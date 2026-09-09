# Foundation checkpoint — W01∼W03

Task: `SR-20260909-150106-PPO12Y`

This checkpoint establishes the remote repository baseline, toolchain identity, safe shell, save envelope/recovery primitive, test runner, and low-cost CI. It is not a vertical slice and is not evidence that the requested game or premium-quality target is complete.

## Fixed foundation decisions

- Engine: Godot `4.7.2-stable`, Standard build, typed GDScript, GL Compatibility.
- Base viewport: 1280×720 landscape-oriented design; supported aspect-ratio behavior is validated in later runtime packets.
- Android baseline: API 29+, arm64 primary; x86_64 is an emulator validation identity only.
- Runtime product baseline: offline single-player, Korean-first, no ads/IAP/accounts/runtime networking.
- Planned application IDs: PROD `com.shaterguy.lanternfall`; DEV `com.shaterguy.lanternfall.dev`.
- Planned version: `1.0.0-dev1`, versionCode `1` for the initial DEV lineage.

## Signing gate

A user-installable build must not be delivered until a durable non-debug key exists in an approved protected store, recovery has been verified, the certificate fingerprint is recorded without exposing private material, and the matching package/version lineage is verified on the APK itself. Debug keys, random per-build keys, unrelated app keys, repository files, workflow logs, and ordinary artifacts are prohibited signing-key stores.

The current connected GitHub tool surface can read Actions state but does not expose Secrets creation/update. Therefore this checkpoint does not create or claim a signing key. Secret-independent implementation and CI may proceed. The signing gate remains unresolved until a protected injection/recovery path is actually available.

## Save primitive

`SaveStore` provides a versioned envelope containing sequence, settlement identifier, payload, and SHA-256 checksum. Writes use temporary-file readback before promotion and retain the previous valid primary as backup. Reads select the primary first and then a checksum-valid backup. The product-level settlement idempotency ledger, migration graph, and expedition checkpoint policy remain later work and must not be inferred from this primitive.

## Android shell primitive

The main scene scales Android display-safe-area insets into viewport space and clears transient movement/dodge/phase state on application pause or focus loss. It is a lifecycle/input boundary for later controls, not finished combat UI.

## Validation tiers

This checkpoint's remote CI intentionally stops at STATIC_PREFLIGHT and FAST_TEST. Android export, emulator runtime, device performance, signed-update tests, audio/visual review, and delivery are later tiers and remain NOT_RUN until their prerequisites exist.
