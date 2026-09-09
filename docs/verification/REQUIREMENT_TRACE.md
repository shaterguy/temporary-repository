# Requirement trace — W04 checkpoint

Task: `SR-20260909-150106-PPO12Y`
Branch target: `v1.0.0-dev1`

Status terms: `PARTIAL`, `BLOCKED`, `NOT_IMPLEMENTED`. No row in this checkpoint is a final game PASS.

| ID | Requirement | Current state | Evidence / next dependency |
| --- | --- | --- | --- |
| AC-01 | Android install→combat→settlement→hub→next run | NOT_IMPLEMENTED | No user-installable APK or complete expedition loop yet. |
| AC-02 | First user APK durable non-debug signing/update lineage | BLOCKED | Signing contract recorded; protected secret injection/key creation unavailable in current connector. No debug fallback. |
| AC-03 | Survivor core loop | PARTIAL | W04 adds normalized movement, deterministic dodge/invulnerability/cooldown, nearest-target auto attack, damage/armor, hit-feedback generation, pause semantics, a runtime controller/camera primitive, and a live training preview. W05 and later growth/boss integration remain. |
| AC-04 | N01 mobile fortress/routes | NOT_IMPLEMENTED | W06. |
| AC-05 | N02 movement-drawn circuits | NOT_IMPLEMENTED | W07. |
| AC-06 | N03 causal modular weapons | NOT_IMPLEMENTED | W09. |
| AC-07 | N04 prior-run tactical echo | NOT_IMPLEMENTED | W10. |
| AC-08 | N05 disclosed enemy doctrine | NOT_IMPLEMENTED | W11. |
| AC-09 | N06 persistent world graph | NOT_IMPLEMENTED | W12. |
| AC-10 | N07 dual-phase battlefield | NOT_IMPLEMENTED | W08. |
| AC-11 | Campaign/hub/save/retry/post-final loop | PARTIAL | Versioned checksum save envelope + primary/backup primitive only; world/campaign/migration still absent. |
| AC-12 | Distinct content manifest + no release placeholders | PARTIAL | Manifest holds the full planned counts and release gate; implemented content remains 0. W04 training targets are development-only combat instrumentation, not counted content. |
| AC-13 | Actual art/animation/audio/readability review | NOT_IMPLEMENTED | W04 preview geometry is development instrumentation, not presentation acceptance evidence. |
| AC-14 | Aspect ratio/multitouch/accessibility/lifecycle/save failures | PARTIAL | Safe-area scaling, pause/focus transient-input reset, and W04 virtual-input bridge/pause primitive exist; full touch/accessibility/platform matrix remains later. |
| AC-15 | Device performance/memory/soak/16KB | NOT_IMPLEMENTED | No device/runtime performance evidence. |
| AC-16 | Licenses/signing provenance/direct APK | PARTIAL | Asset provenance policy + pinned engine source; signing/APK delivery remain unresolved. |

## W04 fast-test contract

- Movement input is normalized before applying the configured speed.
- Pause freezes combat movement, cooldowns, and gameplay event emission.
- Directional dodge starts once, grants time-bounded invulnerability, and respects a cooldown.
- Damage applies non-negative armor reduction, advances hit-feedback generation exactly once, and does not apply through dodge invulnerability.
- Auto targeting ignores inactive/out-of-range targets and uses target ID as a deterministic tie-break.
- Auto attack fires at the configured cadence and emits target/damage/direction without requiring presentation code to settle damage rules.

## Non-regression and safety

- NR-01: no repository/application outside `shaterguy/temporary-repository` is mutated by this implementation.
- NR-02: private signing/key/password material must not enter Git, workflow logs, or artifacts.
- NR-03: completed settlement must eventually be idempotent across retries/crash recovery; the current envelope merely carries `settlement_id` and is not final idempotency implementation.
- NR-04: after first distribution, each package/certificate/storage/version lineage must remain update-compatible; no first distribution has occurred yet.
- NR-05: do not add payments, accounts, runtime networking, broad permissions, or untrusted signing paths without explicit review.
