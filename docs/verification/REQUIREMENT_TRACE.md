# Requirement trace — W12 checkpoint

Task: `SR-20260909-150106-PPO12Y`
Branch target: `v1.0.0-dev1`

Status terms: `PARTIAL`, `BLOCKED`, `NOT_IMPLEMENTED`. No row in this checkpoint is a final game PASS.

| ID | Requirement | Current state | Evidence / next dependency |
| --- | --- | --- | --- |
| AC-01 | Android install→combat→settlement→hub→next run | NOT_IMPLEMENTED | W12 now supplies the actual runtime hub→choice→expedition→settlement→hub→next-expedition loop and persistent restart path, but no user-installable production-signed APK/device end-to-end evidence exists yet. |
| AC-02 | First user APK durable non-debug signing/update lineage | BLOCKED | Signing contract recorded; protected secret injection/key creation unavailable in current connector. No debug fallback. |
| AC-03 | Survivor core loop | PARTIAL | W04 movement/dodge/auto-attack/damage remains; W05 spatial pooling, deterministic warnings, route-compatible swarm pressure, contact damage, and a base-boss primitive remain connected. W08 adds phase-aware player movement collision and phase-filtered targets. W09 routes runtime auto-attack/dodge causes through the causal weapon resolver while preserving target-provider damage settlement. W10 adds a separate limited-power replay damage path that does not re-enter the causal resolver. W11 lets a disclosed doctrine reshape only a capped subset of W05 spawn composition/formation without universal health or damage inflation. W12 now mounts these systems into the persistent expedition runtime. Combat growth and production presentation remain. |
| AC-04 | N01 mobile fortress/routes | PARTIAL | W06 deterministic route previews, idempotent junction choice, route-specific movement/supply/threat/objective pressure, visible-objective damage gating, rest/arrival, recoverable failure and checkpoint restore remain. W07 adds an optional circuit-provider hook so an active N02 ark ward can reduce visible ark/objective damage without changing unprotected W06 behavior. W11 doctrine counterplay explicitly retains route bypass as a system-level response. W12 binds selected world choices to an actual ArkConvoy expedition, rest/recovery checkpoints and settlement return. Production presentation remains later. |
| AC-05 | N02 movement-drawn circuits | PARTIAL | W07 closed-loop geometry, light budget, cooldown/cap, timed area effects, snapshot/restore, live snare and ark ward remain. W08 drives the W07 phase token from an actual runtime phase switch. W09 consumes active circuit polygons as a real weapon-transform condition when an attack segment crosses a same-phase boundary. W10 turns an actual active `echo_beacon` circuit ID into a one-shot N04 replay trigger and consumes that activation ID. W11 doctrine counterplay explicitly retains light circuits as a system-level response. W12 persists/restores committed circuit state inside active expedition checkpoints. Procedural lines are not final art. |
| AC-06 | N03 causal modular weapons | PARTIAL | W09 adds 6 trigger parts, 6 delivery parts, 8 transform parts, explicit compatibility and energy budgets, a finite per-cause chain-depth limit, duplicate-cause suppression, 3 representative curated weapons, upgrade comparison data, snapshot/legacy migration, and runtime W04/W07/W08 damage integration. W10 records one fire input per W09 cause and routes replay damage outside the causal resolver to prevent recursion. W12 persists/restores the weapon snapshot as part of active expedition runtime state. Full 18-weapon curated content, production level-up screen/presentation and final balance remain W17+ dependencies. |
| AC-07 | N04 prior-run tactical echo | PARTIAL | W10 adds versioned ≤8-second relative move/fire records, compatible weapon validation with safe unequip reason, valid records from failed expeditions, pre-run record selection API, one concurrent replay, W07 echo-beacon activation, current W08 collision/phase handling, limited replay power, cancellation, save-ready selected-record/consumed-circuit snapshot, and explicit no-echo/no-reward/no-achievement/no-circuit-charge/no-causal-chain policy. W12 now finishes the current capture at settlement, persists the record through hub/restart, selects it for the next expedition, and preserves the W10 restore rule that cancels transient active replay/capture. Final presentation/balance remain later. |
| AC-08 | N05 disclosed enemy doctrine | PARTIAL | W11 adds deterministic doctrine selection from a prior observation summary, low-sample neutrality, repeated-failure relief, departure-readable disclosure data, combat prewarning, a ≤30% response-formation cap, actual W05 composition/placement changes, tamper-rejecting plan snapshots, and route/circuit/phase counterplay that is character-independent. W12 now accumulates runtime observations, derives/persists the next plan at settlement, reloads it across restart and configures the next SpawnDirector from that plan. Production departure UI/presentation/balance remain later. |
| AC-09 | N06 persistent world graph | PARTIAL | W12 implements a deterministic persistent world campaign with 3 normal segments plus POST_FINAL continuation, two mutually exclusive meaningful departure choices per segment, region/route/support/shop/threat/access/reward differences, no-dead-end failure recovery, and actual hub→choice→expedition→settlement→hub runtime/save integration. Production campaign breadth, map presentation and content remain later. |
| AC-10 | N07 dual-phase battlefield | PARTIAL | W08 adds same-coordinate material/shadow blockers and cover, destination safety preview, no-cost rejection, cooldown, pause/cancel gating, phase-aware player movement collision and enemy targeting, actual W07 circuit phase switching, explicit cross-phase boss warning before damage, and phase snapshot/restore. W09 supplies the current phase to causal weapon transforms. W10 resolves replay movement against the current phase geometry and suppresses recorded shots whose recorded phase differs from the current battlefield. W11 doctrine counterplay explicitly retains phase switching as a system-level response. W12 persists/restores phase and phase-bound encounter state in active expedition checkpoints. Production maps, final art and later content remain. |
| AC-11 | Campaign/hub/save/retry/post-final loop | PARTIAL | W12 now provides three persistent slots, new/load, versioned checksum envelopes, sequence monotonicity, tmp→verify→backup→atomic promote→readback, corrupt-primary backup recovery, v0 migration, transactional world choice and settlement, deterministic settlement idempotency, 15-second/background/rest/recovery checkpoints, active expedition suspend/resume, POST_FINAL continuation, and W10/W11 cross-run state transport. Full production campaign UI/content, Android lifecycle/device matrix and distribution verification remain later. |
| AC-12 | Distinct content manifest + no release placeholders | PARTIAL | Manifest holds the full planned counts and release gate; implemented production content remains 0. W04 training geometry, W05 swarm preview, W06 ark geometry, W07 circuit lines, W08 phase blockers and W10 echo rendering primitive are development instrumentation. W09 representative weapon definitions, W11 doctrine formations and W12 campaign shell are gameplay prototypes and do not count as final production content. |
| AC-13 | Actual art/animation/audio/readability review | NOT_IMPLEMENTED | W04∼W12 procedural preview/instrumentation is not presentation acceptance evidence. |
| AC-14 | Aspect ratio/multitouch/accessibility/lifecycle/save failures | PARTIAL | Safe-area scaling, pause/focus transient-input reset, virtual-input bridge, route pause/checkpoint, W07 pause-safe circuit timers, W08 phase input edge/reset, W09 paused weapon-resolution rejection and W10 pause-safe replay timing remain. W12 adds active-expedition background/focus checkpointing, 15-second periodic checkpoints, JSON-safe runtime serialization and semantic restore blocking on invalid runtime state. Full touch/accessibility/platform/device lifecycle matrix remains later. |
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

## W07 retained fast-test contract

- An open movement line does not activate a circuit; a valid closed loop with minimum path length and enclosed area activates exactly once and charges light once.
- Stationary jitter, short backtracking, self-intersecting geometry and teleport-sized discontinuities cannot be used as valid closures.
- Trail samples are retained for 8 seconds in world space, so off-screen movement is not discarded merely because it is outside the viewport.
- Equivalent coarse and 60fps sampling of the same loop both activate, while a paused simulation advances neither trail time nor circuit timers.
- Explicit phase-token changes clear the in-progress trail so one circuit cannot bridge two phases; active effects only answer queries in their recorded phase.
- Activation consumes 35 light, regeneration is bounded to 100, reactivation waits 3 seconds, a maximum of 2 circuits may coexist, and active circuits expire after 10 seconds.
- The selected `snare` module applies its boundary-inclusive multiplier to live swarm movement inside the circuit, while the default `ark_ward` module halves visible damage only while the defended position lies inside an active ward.
- Ark/objective protection is opt-in through the W07 provider hook: no provider preserves W06 damage, while a live ward applies deterministic mitigation before the W06 model settles visible damage.
- Active circuit IDs, polygons, module/phase, remaining duration, light, cooldown and activation generation survive snapshot/restore; the transient in-progress trail intentionally resets on restore so a committed closure cannot fire twice.
- `echo_beacon` is the W10 activation module. W10 consumes each observed echo-beacon circuit ID once, so restore or a long-lived active circuit cannot trigger a second replay.

## W08 retained fast-test contract

- Material and shadow share coordinates but use different blocker/cover layouts; movement cannot tunnel through the active phase blocker or leave world bounds.
- Before a switch, the target phase, destination validity and nearby target-phase threat count are available as preview data.
- A blocked destination, pause, cancellation or active cooldown rejects a switch without advancing transition generation or improperly consuming a new cooldown.
- A valid switch changes the active collision/targeting battlefield, arms the reuse cooldown and propagates the phase token into W07 circuits.
- A valid switch during W06 ark route travel leaves route status, progress and supply untouched, and route simulation continues afterward.
- Enemy archetypes are assigned deterministic phase identities; W04 auto targeting only receives enemies in the active phase.
- An opposite-phase boss cannot apply direct contact damage. Its only cross-phase damage path in this checkpoint creates a visible timed warning first and resolves only after that warning.
- A circuit recorded in material does not affect shadow queries at the same coordinate and becomes active again after returning to material.
- Phase, remaining cooldown, generation and last valid transition position survive snapshot/restore without replaying a transition.

## W09 retained fast-test contract

- The part catalog exposes exactly 6 trigger parts, 6 delivery parts and 8 transform parts, and every possible triple is deterministically classified as allowed or rejected by the same compatibility table.
- Every allowed recipe stays within the disclosed energy budget and carries the same finite maximum causal-chain depth; incompatible and over-budget recipes cannot be equipped as valid weapons.
- A single cause ID can resolve a given equipped weapon only once. Replayed causes after snapshot/restore remain consumed, and events at the maximum chain depth terminate without recursive damage or resource generation.
- Resolution order is always trigger → delivery → transform. Transform conditions are explicit input state rather than hidden coefficients.
- `sunwake_lance` turns a dodge cause into a piercing delivery and adds exactly one target only when the attack segment crosses an active same-phase W07 circuit boundary.
- The default `shade_halo` remains usable in material but its disclosed shadow transform raises actual resolved damage only in the shadow phase and reports its barrier-pressure coefficient.
- The survivor controller sends W04 auto-attack/dodge causes through the weapon model, obtains current W08 phase and active W07 circuit polygons, and settles resulting damage through the existing W05 target provider. The integration test verifies real pooled target health changes rather than only inspecting descriptive weapon metadata.
- Paused combat rejects causal weapon resolution. The comparison API discloses changed trigger/delivery/transform/base damage, energy delta, transform condition and hard limits for a candidate upgrade.
- Weapon state has a versioned snapshot and accepts the defined v0→v1 identity migration without re-consuming a previously resolved cause.
- This checkpoint contains 3 representative curated weapons. It does not claim the W17 target of 18 production-curated weapons or final level-up presentation/balance is complete.

## W10 retained fast-test contract

- Tactical records are versioned, JSON/save-envelope compatible and limited to at most 8 seconds and 128 ordered relative movement/fire events.
- A record validates its curated weapon identity and per-fire weapon identity before selection. Corrupt/incompatible records are safely unequipped with a reason instead of being partially replayed.
- `failed` is a valid source-expedition outcome; record validity does not require expedition completion.
- Capture stores relative movement and one fire input per causal source ID, preventing a multi-target W09 resolution from being mis-recorded as several player trigger pulls.
- An observed W07 `echo_beacon` circuit ID is consumed exactly once. At most one replay can be active; a second circuit observed during a replay is consumed and cannot fire retroactively after the first replay ends.
- Replays process the same compatible record in stable event-array order. Movement is applied relative to the new activation origin and resolved against the current W08 phase geometry rather than restoring old world coordinates.
- A recorded fire event whose phase differs from the current phase becomes an explicit `phase_mismatch` blocked event. Compatible shots target only current-world target snapshots.
- Replay damage is limited to 45% of recorded damage and bypasses the W09 causal resolver. Replay events explicitly disallow echo spawning, rewards, achievements, circuit charge and causal-chain recursion, and the runtime path does not emit regular player weapon/auto-attack signals for echo damage.
- Mid-replay cancellation stops later actions. Pause stops replay time because the survivor exits gameplay processing while paused.
- Snapshot/restore keeps the selected compatible record and consumed circuit IDs but cancels active replay and discards in-progress capture, preventing restore-time duplicate damage or activation.
- The runtime integration test closes a real W07 echo-beacon circuit, replays against a W08-aware W05 target provider, observes actual pooled enemy health loss and verifies W09 resolution generation does not advance.

## W11 fast-test contract

- Doctrine selection consumes only a stored observation summary, campaign seed and segment index; current movement/finger input is not part of selection.
- Fewer than 12 observed actions produce no major doctrine. Repeated failures tighten the dominance threshold and reduce the response-formation cap from 30% to 20%.
- Ranged-dominant history deterministically selects `cover_advance`; clustering-dominant history deterministically selects `dispersed_ambush`. Equal-score tie breaking is seed/segment deterministic, so same-summary/same-seed retry is reproducible.
- At most one major doctrine is active for a segment. Every active plan discloses title, rationale, formation, response cap and at least two character-independent responses drawn from route bypass, light circuit and phase shift.
- The W05 spawn director emits a doctrine warning before adaptive response spawns, tags the actual adaptive formation, and schedules adaptive regular enemies at a stride that remains at or below the disclosed cap.
- `cover_advance` changes a capped response subset to standard runner composition in covered columns; `dispersed_ambush` changes a capped response subset to separated spawn arcs. Neither plan adds universal health/damage multipliers, and responsive runners retain the existing W05 runner health contract.
- Valid doctrine plans can be snapshotted and restored. A modified response cap or other checksum-covered plan identity is rejected to a neutral plan instead of being partially trusted.
- W12 now persists the observation summary/selected doctrine through the real expedition→hub→next-region lifecycle and configures the next expedition from the restored plan; production departure disclosure/presentation remains later.

## W12 fast-test contract

- The campaign runtime exposes exactly three persistent slots. An empty slot starts a new campaign with an immediate durable checkpoint; an occupied slot loads the latest valid primary or backup save.
- Each hub segment exposes two mutually exclusive world choices. A selected choice is written before live state commit and binds the next region/route/support/shop/threat/access/reward context to the actual ArkConvoy expedition.
- The runtime performs checkpoints immediately after departure initialization, every 15 seconds during an expedition, on application pause/focus loss, at route rest and recoverable ark failure. A failed checkpoint rolls the in-memory world model back to the prior snapshot.
- Active runtime state is JSON-safe and round-trips through the save envelope: survivor health/position/cooldowns and weapon/echo state, Ark route state, active circuits, phase state, pooled enemies, spawn-director timing/doctrine, telegraphs/cross-phase attacks and W11 observation counters.
- Restore never replays an Ark transition signal, and invalid runtime schema/state is blocked instead of silently overwriting the slot. W10 active replay/capture remains transient and a resumed expedition begins a new capture while keeping the compatible selected prior-run record.
- Settlement uses `settlement:<expedition_id>` as a deterministic idempotency key, derives the W11 next-doctrine plan, persists W10 echo plus observation/plan state, saves the candidate world before committing it live, and returns to hub. Restart after settlement does not duplicate salvage or segment progression.
- Consecutive checkpoints create a valid prior backup. If the primary is corrupted, loading explicitly reports `RECOVERED_FROM_BACKUP` and restores the prior valid checkpoint rather than resetting progress.
- Legacy v0 campaign payloads migrate into the current world schema without changing mapped progression/salvage. Newer unsupported save schemas remain rejected by the retained SaveStore contract.
- The final W12 runtime verification contract is `w12-runtime-integration-v1`: retained W04∼W11 tests plus `campaign_runtime` and `runtime_state_codec`, for 13 suites total.

## Non-regression and safety

- NR-01: no repository/application outside `shaterguy/temporary-repository` is mutated by this implementation.
- NR-02: private signing/key/password material must not enter Git, workflow logs, or artifacts.
- NR-03: W12 settlement is idempotent across retry/restart through deterministic settlement IDs, the world model's settled-ID ledger, monotonic save sequence/checksum validation and save-before-live-commit ordering. The restart fixture confirms reward/progression is unchanged after reload.
- NR-04: after first distribution, each package/certificate/storage/version lineage must remain update-compatible; no first distribution has occurred yet.
- NR-05: do not add payments, accounts, runtime networking, broad permissions, or untrusted signing paths without explicit review.
