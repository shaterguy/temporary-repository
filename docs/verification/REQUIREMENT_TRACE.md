# Requirement trace — W07 checkpoint

Task: `SR-20260909-150106-PPO12Y`
Branch target: `v1.0.0-dev1`

Status terms: `PARTIAL`, `BLOCKED`, `NOT_IMPLEMENTED`. No row in this checkpoint is a final game PASS.

| ID | Requirement | Current state | Evidence / next dependency |
| --- | --- | --- | --- |
| AC-01 | Android install→combat→settlement→hub→next run | NOT_IMPLEMENTED | No user-installable APK or complete expedition loop yet. |
| AC-02 | First user APK durable non-debug signing/update lineage | BLOCKED | Signing contract recorded; protected secret injection/key creation unavailable in current connector. No debug fallback. |
| AC-03 | Survivor core loop | PARTIAL | W04 movement/dodge/auto-attack/damage remains; W05 spatial pooling, deterministic warnings, route-compatible swarm pressure, contact damage, and a base-boss primitive remain connected. Combat growth and production integration remain. |
| AC-04 | N01 mobile fortress/routes | PARTIAL | W06 deterministic route previews, idempotent junction choice, route-specific movement/supply/threat/objective pressure, visible-objective damage gating, rest/arrival, recoverable failure and checkpoint restore remain. W07 adds an optional circuit-provider hook so an active N02 ark ward can reduce visible ark/objective damage without changing unprotected W06 behavior. Final campaign/save UI and production presentation remain later. |
| AC-05 | N02 movement-drawn circuits | PARTIAL | W07 adds 8-second world-space trail capture, closed-loop length/area validation, jitter/backtrack/self-intersection/teleport rejection, light cost/regeneration, 3-second reactivation cooldown, 2-circuit cap, timed area effects, phase-bound trail reset, active-circuit snapshot/restore, procedural trail/circuit feedback, live snare slowdown against swarm movement, and live N01 ark-ward mitigation. N07 runtime phase wiring and N04 echo replay remain later dependencies; procedural lines are not final art. |
| AC-06 | N03 causal modular weapons | NOT_IMPLEMENTED | W09. |
| AC-07 | N04 prior-run tactical echo | NOT_IMPLEMENTED | W10; W07 reserves an `echo_beacon` circuit module identity but does not count echo replay as implemented. |
| AC-08 | N05 disclosed enemy doctrine | NOT_IMPLEMENTED | W11. |
| AC-09 | N06 persistent world graph | NOT_IMPLEMENTED | W12. |
| AC-10 | N07 dual-phase battlefield | NOT_IMPLEMENTED | W08; W07 only prevents trail geometry from bridging explicit phase-token changes. |
| AC-11 | Campaign/hub/save/retry/post-final loop | PARTIAL | Versioned checksum save envelope + primary/backup primitive, W06 route snapshot/restore, and W07 active-circuit snapshot/restore exist; world/campaign/settlement migration still absent. |
| AC-12 | Distinct content manifest + no release placeholders | PARTIAL | Manifest holds the full planned counts and release gate; implemented production content remains 0. W04 training geometry, W05 swarm preview, W06 ark geometry and W07 circuit lines are development instrumentation, not counted content. |
| AC-13 | Actual art/animation/audio/readability review | NOT_IMPLEMENTED | W04∼W07 procedural preview geometry is development instrumentation, not presentation acceptance evidence. |
| AC-14 | Aspect ratio/multitouch/accessibility/lifecycle/save failures | PARTIAL | Safe-area scaling, pause/focus transient-input reset, virtual-input bridge, route pause/checkpoint and W07 pause-safe circuit timers exist; full touch/accessibility/platform matrix remains later. |
| AC-15 | Device performance/memory/soak/16KB | NOT_IMPLEMENTED | W05 spatial partition/state reuse foundations exist, but no device/runtime performance evidence exists. |
| AC-16 | Licenses/signing provenance/direct APK | PARTIAL | Asset provenance policy + pinned engine source; signing/APK delivery remain unresolved. |

## W04 retained fast-test contract

- Movement input is normalized before applying the configured speed.
- Pause freezes combat movement, cooldowns, and gameplay event emission.
- Directional dodge starts once, grants time-bounded invulnerability, and respects a cooldown.
- Damage applies non-negative armor reduction, advances hit-feedback generation exactly once, and does not apply through dodge invulnerability.
- Auto targeting ignores inactive/out-of-range targets and uses target ID as a deterministic tie-break.
- Auto attack fires at the configured cadence and emits target/damage/direction without requiring presentation code to settle damage rules.

## W05 retained fast-test contract

- Spatial neighbor queries return in-radius entities and exclude out-of-radius entities across cell boundaries.
- Released enemy-state slots are reused without reusing a live target identity; slot generation advances and lethal recycle is single-application.
- Contact cooldown state advances deterministically inside the pooled enemy state.
- With default route context, the same seed and origin produce the same spawn identity and warning position as the prior W05 contract.
- A regular enemy spawn is preceded by its configured telegraph and resolves after the warning lead time.
- The base boss receives a longer dedicated warning, resolves into the scheduled boss exactly once per director lifecycle, and remains a development combat primitive rather than completed boss content.
- Runtime swarm management consumes the same pooled states, rebuilds a spatial hash before local separation, routes W04 auto-attack damage through a target-provider adapter, and keeps the prior scene-group target path as fallback.

## W06 retained fast-test contract

- Risk and supply routes expose different threat, supply, enemy-entry and defended-objective previews before selection.
- Selecting the same route at the same junction is idempotent; a consumed junction cannot be switched to a conflicting route or charged twice.
- With the same seed and equal simulation time, the two routes produce different movement and combat-entry positions, then each reaches an explicit rest/destination state.
- Route completion applies its supply result exactly once, and the rest segment transitions explicitly to arrived rather than silently retargeting the destination.
- Ark durability is separate from player health; damage without visible objective exposure is rejected, destruction enters a recoverable failure state, and recovery consumes supply before resuming.
- The supply route changes the defended objective to a supply pod whose loss has a route-specific supply penalty exactly once.
- Pausing freezes route progress, and a save-ready primitive checkpoint restores route choice, progress, supply, durability and deterministic continuation without duplicate completion effects.
- Runtime swarm pressure consumes route threat and entry direction while retaining W04 player-target and W05 pooled-target integration.

## W07 fast-test contract

- An open movement line does not activate a circuit; a valid closed loop with minimum path length and enclosed area activates exactly once and charges light once.
- Stationary jitter, short backtracking, self-intersecting geometry and teleport-sized discontinuities cannot be used as valid closures.
- Trail samples are retained for 8 seconds in world space, so off-screen movement is not discarded merely because it is outside the viewport.
- Equivalent coarse and 60fps sampling of the same loop both activate, while a paused simulation advances neither trail time nor circuit timers.
- Explicit phase-token changes clear the in-progress trail so one circuit cannot bridge two phases; active effects only answer queries in their recorded phase.
- Activation consumes 35 light, regeneration is bounded to 100, reactivation waits 3 seconds, a maximum of 2 circuits may coexist, and active circuits expire after 10 seconds.
- The selected `snare` module applies its boundary-inclusive multiplier to live swarm movement inside the circuit, while the default `ark_ward` module halves visible damage only while the defended position lies inside an active ward.
- Ark/objective protection is opt-in through the W07 provider hook: no provider preserves W06 damage, while a live ward applies deterministic mitigation before the W06 model settles visible damage.
- Active circuit IDs, polygons, module/phase, remaining duration, light, cooldown and activation generation survive snapshot/restore; the transient in-progress trail intentionally resets on restore so a committed closure cannot fire twice.
- `echo_beacon` is a reserved module identity for W10 and is not evidence that tactical echo replay exists in W07.

## Non-regression and safety

- NR-01: no repository/application outside `shaterguy/temporary-repository` is mutated by this implementation.
- NR-02: private signing/key/password material must not enter Git, workflow logs, or artifacts.
- NR-03: completed settlement must eventually be idempotent across retries/crash recovery; the current envelope merely carries `settlement_id` and is not final idempotency implementation.
- NR-04: after first distribution, each package/certificate/storage/version lineage must remain update-compatible; no first distribution has occurred yet.
- NR-05: do not add payments, accounts, runtime networking, broad permissions, or untrusted signing paths without explicit review.
