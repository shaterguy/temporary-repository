# Requirement trace — foundation checkpoint

Task: `SR-20260909-150106-PPO12Y`
Branch target: `v1.0.0-dev1`

Status terms: `PARTIAL`, `BLOCKED`, `NOT_IMPLEMENTED`. No row in this checkpoint is a final game PASS.

| ID | Requirement | Foundation state | Evidence / next dependency |
| --- | --- | --- | --- |
| AC-01 | Android install→combat→settlement→hub→next run | NOT_IMPLEMENTED | No APK or combat loop yet. |
| AC-02 | First user APK durable non-debug signing/update lineage | BLOCKED | Signing contract recorded; protected secret injection/key creation unavailable in current connector. No debug fallback. |
| AC-03 | Survivor core loop | NOT_IMPLEMENTED | W04∼W05. |
| AC-04 | N01 mobile fortress/routes | NOT_IMPLEMENTED | W06. |
| AC-05 | N02 movement-drawn circuits | NOT_IMPLEMENTED | W07. |
| AC-06 | N03 causal modular weapons | NOT_IMPLEMENTED | W09. |
| AC-07 | N04 prior-run tactical echo | NOT_IMPLEMENTED | W10. |
| AC-08 | N05 disclosed enemy doctrine | NOT_IMPLEMENTED | W11. |
| AC-09 | N06 persistent world graph | NOT_IMPLEMENTED | W12. |
| AC-10 | N07 dual-phase battlefield | NOT_IMPLEMENTED | W08. |
| AC-11 | Campaign/hub/save/retry/post-final loop | PARTIAL | Versioned checksum save envelope + primary/backup primitive only; world/campaign/migration still absent. |
| AC-12 | Distinct content manifest + no release placeholders | PARTIAL | Manifest holds the full planned counts and release gate; implemented content remains 0. |
| AC-13 | Actual art/animation/audio/readability review | NOT_IMPLEMENTED | Foundation shell is not presentation acceptance evidence. |
| AC-14 | Aspect ratio/multitouch/accessibility/lifecycle/save failures | PARTIAL | Safe-area scaling and pause/focus transient-input reset primitive; full platform matrix remains later. |
| AC-15 | Device performance/memory/soak/16KB | NOT_IMPLEMENTED | No device/runtime performance evidence. |
| AC-16 | Licenses/signing provenance/direct APK | PARTIAL | Asset provenance policy + pinned engine source; signing/APK delivery remain unresolved. |

## Non-regression and safety

- NR-01: no repository/application outside `shaterguy/temporary-repository` is mutated by this implementation.
- NR-02: private signing/key/password material must not enter Git, workflow logs, or artifacts.
- NR-03: completed settlement must eventually be idempotent across retries/crash recovery; the current envelope merely carries `settlement_id` and is not final idempotency implementation.
- NR-04: after first distribution, each package/certificate/storage/version lineage must remain update-compatible; no first distribution has occurred yet.
- NR-05: do not add payments, accounts, runtime networking, broad permissions, or untrusted signing paths without explicit review.
