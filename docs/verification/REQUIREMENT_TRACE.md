# Requirement trace — W21 checkpoint

Task: `SR-20260909-150106-PPO12Y`
Branch target: `v1.0.0-dev1`

Status terms: `PARTIAL`, `BLOCKED`, `NOT_IMPLEMENTED`. No row in this checkpoint is a final game PASS.

The AC table below is the retained W15 baseline and remains verbatim evidence for W04-W15. Authoritative W16-W21 deltas follow after the W15 contract; read both together for the current checkpoint. Neither retained nor new automated/headless evidence converts into human visual, listening, fun, Android-device, signing, or release acceptance.

| ID | Requirement | W15 retained state | Evidence / next dependency |
| --- | --- | --- | --- |
| AC-01 | Android install→combat→settlement→hub→next run | NOT_IMPLEMENTED | W12 now supplies the actual runtime hub→choice→expedition→settlement→hub→next-expedition loop and persistent restart path, but no user-installable production-signed APK/device end-to-end evidence exists yet. |
| AC-02 | First user APK durable non-debug signing/update lineage | BLOCKED | Signing contract recorded; protected secret injection/key creation unavailable in current connector. No debug fallback. |
| AC-03 | Survivor core loop | PARTIAL | W04 movement/dodge/auto-attack/damage remains; W05 spatial pooling, deterministic warnings, route-compatible swarm pressure, contact damage, and a base-boss primitive remain connected. W08 adds phase-aware player movement collision and phase-filtered targets. W09 routes runtime auto-attack/dodge causes through the causal weapon resolver while preserving target-provider damage settlement. W10 adds a separate limited-power replay damage path that does not re-enter the causal resolver. W11 lets a disclosed doctrine reshape only a capped subset of W05 spawn composition/formation without universal health or damage inflation. W12 now mounts these systems into the persistent expedition runtime. W13 overlays representative player/enemy/Ark presentation without changing those gameplay semantics. Combat growth and final production presentation remain. |
| AC-04 | N01 mobile fortress/routes | PARTIAL | W06 deterministic route previews, idempotent junction choice, route-specific movement/supply/threat/objective pressure, visible-objective damage gating, rest/arrival, recoverable failure and checkpoint restore remain. W07 adds an optional circuit-provider hook so an active N02 ark ward can reduce visible ark/objective damage without changing unprotected W06 behavior. W11 doctrine counterplay explicitly retains route bypass as a system-level response. W12 binds selected world choices to an actual ArkConvoy expedition, rest/recovery checkpoints and settlement return. W13 gives the Ark a representative authored vector identity but does not claim route/content completion. |
| AC-05 | N02 movement-drawn circuits | PARTIAL | W07 closed-loop geometry, light budget, cooldown/cap, timed area effects, snapshot/restore, live snare and ark ward remain. W08 drives the W07 phase token from an actual runtime phase switch. W09 consumes active circuit polygons as a real weapon-transform condition when an attack segment crosses a same-phase boundary. W10 turns an actual active `echo_beacon` circuit ID into a one-shot N04 replay trigger and consumes that activation ID. W11 doctrine counterplay explicitly retains light circuits as a system-level response. W12 persists/restores committed circuit state inside active expedition checkpoints. W13 presentation redraws active polygons above the environment while preserving their W07 model state. |
| AC-06 | N03 causal modular weapons | PARTIAL | W09 adds 6 trigger parts, 6 delivery parts, 8 transform parts, explicit compatibility and energy budgets, a finite per-cause chain-depth limit, duplicate-cause suppression, 3 representative curated weapons, upgrade comparison data, snapshot/legacy migration, and runtime W04/W07/W08 damage integration. W10 records one fire input per W09 cause and routes replay damage outside the causal resolver to prevent recursion. W12 persists/restores the weapon snapshot as part of active expedition runtime state. W13 adds representative weapon-impact VFX only. Full 18-weapon curated content, production level-up screen/presentation and final balance remain W17+ dependencies. |
| AC-07 | N04 prior-run tactical echo | PARTIAL | W10 adds versioned ≤8-second relative move/fire records, compatible weapon validation with safe unequip reason, valid records from failed expeditions, pre-run record selection API, one concurrent replay, W07 echo-beacon activation, current W08 collision/phase handling, limited replay power, cancellation, save-ready selected-record/consumed-circuit snapshot, and explicit no-echo/no-reward/no-achievement/no-circuit-charge/no-causal-chain policy. W12 now finishes the current capture at settlement, persists the record through hub/restart, selects it for the next expedition, and preserves the W10 restore rule that cancels transient active replay/capture. Final presentation/balance remain later. |
| AC-08 | N05 disclosed enemy doctrine | PARTIAL | W11 adds deterministic doctrine selection from a prior observation summary, low-sample neutrality, repeated-failure relief, departure-readable disclosure data, combat prewarning, a ≤30% response-formation cap, actual W05 composition/placement changes, tamper-rejecting plan snapshots, and route/circuit/phase counterplay that is character-independent. W12 now accumulates runtime observations, derives/persists the next plan at settlement, reloads it across restart and configures the next SpawnDirector from that plan. W13 adds eight visual enemy identities mapped over the existing behavior families without falsely treating visual variants as eight completed behaviors. |
| AC-09 | N06 persistent world graph | PARTIAL | W12 implements a deterministic persistent world campaign with 3 normal segments plus POST_FINAL continuation, two mutually exclusive meaningful departure choices per segment, region/route/support/shop/threat/access/reward differences, no-dead-end failure recovery, and actual hub→choice→expedition→settlement→hub runtime/save integration. W13 contributes the representative Twilight Shipyard environment only; production campaign breadth/map presentation/content remain later. |
| AC-10 | N07 dual-phase battlefield | PARTIAL | W08 adds same-coordinate material/shadow blockers and cover, destination safety preview, no-cost rejection, cooldown, pause/cancel gating, phase-aware player movement collision and enemy targeting, actual W07 circuit phase switching, explicit cross-phase boss warning before damage, and phase snapshot/restore. W09 supplies the current phase to causal weapon transforms. W10 resolves replay movement against the current phase geometry and suppresses recorded shots whose recorded phase differs from the current battlefield. W11 doctrine counterplay explicitly retains phase switching as a system-level response. W12 persists/restores phase and phase-bound encounter state in active expedition checkpoints. W13 redraws danger/phase telegraphs above decorative art and adds phase-burst VFX. Production maps and final art remain later. |
| AC-11 | Campaign/hub/save/retry/post-final loop | PARTIAL | W12 now provides three persistent slots, new/load, versioned checksum envelopes, sequence monotonicity, tmp→verify→backup→atomic promote→readback, corrupt-primary backup recovery, v0 migration, transactional world choice and settlement, deterministic settlement idempotency, 15-second/background/rest/recovery checkpoints, active expedition suspend/resume, POST_FINAL continuation, and W10/W11 cross-run state transport. W13 does not alter save/campaign semantics. Full production campaign UI/content, Android lifecycle/device matrix and distribution verification remain later. |
| AC-12 | Distinct content manifest + no release placeholders | PARTIAL | W13 now tracks 15 non-placeholder authored runtime vectors: Twilight Shipyard, 2 player visual identities, 8 enemy visual identities, Ark, boss, HUD and VFX. Each is mapped through a runtime manifest plus source/edit and project-original provenance records. `implemented_content` counts intentionally remain 0 because visual identities alone are not falsely counted as completed gameplay roles. Full production manifest breadth and final no-placeholder release audit remain later. |
| AC-13 | Actual art/animation/audio/readability review | PARTIAL | W13 replaces the prior all-procedural presentation baseline with actual authored SVG art, runtime idle/engine/enemy animation treatment, VFX, combat HUD, telegraph precedence and an Xvfb 1280×720 PNG render-capture contract. Automated render generation is not human visual PASS; the produced PNG still requires actual inspection, and production audio remains a later milestone. |
| AC-14 | Aspect ratio/multitouch/accessibility/lifecycle/save failures | PARTIAL | Safe-area scaling, pause/focus transient-input reset, virtual-input bridge, route pause/checkpoint, W07 pause-safe circuit timers, W08 phase input edge/reset, W09 paused weapon-resolution rejection and W10 pause-safe replay timing remain. W12 adds active-expedition background/focus checkpointing, 15-second periodic checkpoints, JSON-safe runtime serialization and semantic restore blocking on invalid runtime state. W13 HUD anchors to viewport dimensions and preserves danger information in low-VFX mode, but the full aspect-ratio/touch/accessibility/device matrix remains later. |
| AC-15 | Device performance/memory/soak/16KB | NOT_IMPLEMENTED | W05 spatial partition/state reuse foundations exist, but no device/runtime performance evidence exists. W13 adds visual resources without claiming device performance acceptance. |
| AC-16 | Licenses/signing provenance/direct APK | PARTIAL | W13 adds project-original provenance/source-edit tracking for every representative runtime vector. Signing/APK delivery and final all-asset license audit remain unresolved. |

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
- A record validates its curated weapon identity and per-fire weapon identity before selection. Corrupt/incompatible records are safely unequipped with a reason instead of being partially trusted.
- `failed` is a valid source-expedition outcome; record validity does not require expedition completion.
- Capture stores relative movement and one fire input per causal source ID, preventing a multi-target W09 resolution from being mis-recorded as several player trigger pulls.
- An observed W07 `echo_beacon` circuit ID is consumed exactly once. At most one replay can be active; a second circuit observed during a replay is consumed and cannot fire retroactively after the first replay ends.
- Replays process the same compatible record in stable event-array order. Movement is applied relative to the new activation origin and resolved against the current W08 phase geometry rather than restoring old world coordinates.
- A recorded fire event whose phase differs from the current phase becomes an explicit `phase_mismatch` blocked event. Compatible shots target only current-world target snapshots.
- Replay damage is limited to 45% of recorded damage and bypasses the W09 causal resolver. Replay events explicitly disallow echo spawning, rewards, achievements, circuit charge and causal-chain recursion, and the runtime path does not emit regular player weapon/auto-attack signals for echo damage.
- Mid-replay cancellation stops later actions. Pause stops replay time because the survivor exits gameplay processing while paused.
- Snapshot/restore keeps the selected compatible record and consumed circuit IDs but cancels active replay and discards in-progress capture, preventing restore-time duplicate damage or activation.
- The runtime integration test closes a real W07 echo-beacon circuit, replays against a W08-aware W05 target provider, observes actual pooled enemy health loss and verifies W09 resolution generation does not advance.

## W11 retained fast-test contract

- Doctrine selection consumes only a stored observation summary, campaign seed and segment index; current movement/finger input is not part of selection.
- Fewer than 12 observed actions produce no major doctrine. Repeated failures tighten the dominance threshold and reduce the response-formation cap from 30% to 20%.
- Ranged-dominant history deterministically selects `cover_advance`; clustering-dominant history deterministically selects `dispersed_ambush`. Equal-score tie breaking is seed/segment deterministic, so same-summary/same-seed retry is reproducible.
- At most one major doctrine is active for a segment. Every active plan discloses title, rationale, formation, response cap and at least two character-independent responses drawn from route bypass, light circuit and phase shift.
- The W05 spawn director emits a doctrine warning before adaptive response spawns, tags the actual adaptive formation, and schedules adaptive regular enemies at a stride that remains at or below the disclosed cap.
- `cover_advance` changes a capped response subset to standard runner composition in covered columns; `dispersed_ambush` changes a capped response subset to separated spawn arcs. Neither plan adds universal health/damage multipliers, and responsive runners retain the existing W05 runner health contract.
- Valid doctrine plans can be snapshotted and restored. A modified response cap or other checksum-covered plan identity is rejected to a neutral plan instead of being partially trusted.
- W12 now persists the observation summary/selected doctrine through the real expedition→hub→next-region lifecycle and configures the next expedition from the restored plan; production departure disclosure/presentation remains later.

## W12 retained fast-test contract

- The campaign runtime exposes exactly three persistent slots. An empty slot starts a new campaign with an immediate durable checkpoint; an occupied slot loads the latest valid primary or backup save.
- Each hub segment exposes two mutually exclusive world choices. A selected choice is written before live state commit and binds the next region/route/support/shop/threat/access/reward context to the actual ArkConvoy expedition.
- The runtime performs checkpoints immediately after departure initialization, every 15 seconds during an expedition, on application pause/focus loss, at route rest and recoverable ark failure. A failed checkpoint rolls the in-memory world model back to the prior snapshot.
- Active runtime state is JSON-safe and round-trips through the save envelope: survivor health/position/cooldowns and weapon/echo state, Ark route state, active circuits, phase state, pooled enemies, spawn-director timing/doctrine, telegraphs/cross-phase attacks and W11 observation counters.
- Restore never replays an Ark transition signal, and invalid runtime schema/state is blocked instead of silently overwriting the slot. W10 active replay/capture remains transient and a resumed expedition begins a new capture while keeping the compatible selected prior-run record.
- Settlement uses `settlement:<expedition_id>` as a deterministic idempotency key, derives the W11 next-doctrine plan, persists W10 echo plus observation/plan state, saves the candidate world before committing it live, and returns to hub. Restart after settlement does not duplicate salvage or segment progression.
- Consecutive checkpoints create a valid prior backup. If the primary is corrupted, loading explicitly reports `RECOVERED_FROM_BACKUP` and restores the prior valid checkpoint rather than resetting progress.
- Legacy v0 campaign payloads migrate into the current world schema without changing mapped progression/salvage. Newer unsupported save schemas remain rejected by the retained SaveStore contract.
- The final W12 runtime verification contract was `w12-runtime-integration-v1`: retained W04∼W11 tests plus `campaign_runtime` and `runtime_state_codec`, for 13 suites total.

## W13 fast-test and render contract

- The representative-art manifest contains exactly 15 non-placeholder runtime vectors: 1 Twilight Shipyard region, 2 players, 8 enemy visual identities, 1 boss, 1 Ark, 1 HUD and 1 VFX set.
- Every W13 runtime vector has an authored path, gradient treatment, unique SVG payload, Godot Texture2D import result, project-original provenance record and source/edit history. No W13 art entry is allowed to claim placeholder state false while omitting its runtime file.
- `main_shell.tscn` mounts the W13 environment below existing runtime nodes and mounts separate representative art/HUD layers above them. Presentation reads existing W04∼W12 runtime state rather than replacing combat/save models.
- The presentation layer maps existing swarm/runner behavior families across eight visual silhouettes without claiming eight new behavior implementations; `implemented_content.enemy_behaviors` therefore remains unchanged.
- Active circuit visualization and regular/cross-phase danger telegraphs are redrawn after decorative actor art. Low-VFX mode may suppress decorative burst VFX but cannot suppress danger telegraphs or HUD state.
- Two player visual identities are selected deterministically from save-slot identity; the Ark, enemies and boss receive authored vector presentation while their existing gameplay state remains authoritative.
- `w13-representative-art-v1` retains all 13 W04∼W12 suites and adds `representative_art`, for 14 suites total.
- CI must produce an actual 1280×720 PNG from `w13_showcase.tscn` under Xvfb/OpenGL compatibility rendering and upload it with `run_id` + `run_attempt` artifact identity. Import-only evidence is not visual evidence.
- Automated PNG production does not itself equal AC-13 visual PASS. The rendered artifact still requires actual visual inspection for silhouette separation, hierarchy, clipping/overlap and obvious presentation defects. Production audio remains outside W13.

## W14 representative-audio contract

- W14 supplies 7 project-original, non-placeholder runtime audio identities for Twilight Shipyard: 3 music layers and 4 event cues, tracked by `assets/runtime/w14/audio_manifest.json`, source direction, and license/provenance records.
- `AudioDirector` is the runtime autoload and exposes region/boss intensity transitions plus bounded SFX voice handling without becoming authoritative for combat, save, world, circuit, phase, weapon, echo, or doctrine state.
- `w14-representative-audio-v1` retained W04∼W13 regression coverage and added representative-audio checks, for 15 fast suites total.
- CI renders normal, -18dB, and warning WAV evidence at 32000 Hz PCM16 mono, validates required contract markers, and uploads the WAV evidence with run identity.
- Automated WAV generation and checksum evidence do not equal human listening PASS. Warning audibility, mix balance, repetition fatigue, and presentation quality remain pending listening review.

## W15 vertical-slice integration contract

- `main_shell.tscn` mounts the W13 representative art/HUD and W15 first-expedition tutorial while the W14 `AudioDirector` remains the actual runtime autoload.
- The first-expedition tutorial is observation-only presentation: it latches real slot, departure, movement, circuit, phase-switch, and settlement milestones and never becomes authoritative for gameplay or save state.
- `tests/integration/w15_vertical_slice_smoke.gd` instantiates the actual main scene and proves the first persistent slot→hub choice→expedition→settlement→hub loop against an isolated `user://ci_w15_vertical_slice` save root.
- The smoke verifies all seven differentiating systems are present in the real runtime path: N01 Ark route configured from the departure choice; N02 active circuit through the real controller/model; N03 equipped causal weapon recipe; N04 tactical echo persisted at settlement; N05 doctrine plan available; N06 two mutually exclusive next world choices; N07 main-scene phase transition generation advances.
- Settlement is reloaded through a new `CampaignRuntime` instance and must remain at `HUB` with segment index 1, proving the W12 save boundary preserves the W15 settlement rather than only checking in-memory state.
- The tutorial unit contract verifies monotonic milestone latching, required earlier steps, and completion hiding. `w15-vertical-slice-v1` retains prior suites and adds the tutorial suite, for 16 fast suites total.
- CI rejects Godot script/runtime errors, `ObjectDB instances leaked`, `Resources still in use`, W15 explicit failures, missing contract markers, and a headless action interval above 2500ms. This 2500ms check is a CI sanity budget only, not Android frame-time/device-performance evidence.
- Candidate `e26051b57b750624b10bcd453a3201c0af6bb2eb` passed `foundation-ci` run 34354127805/job 102474375656, including import, 16 fast suites, W15 actual-main-scene smoke, W13 render, and W14 audio render. W13 artifact 10104985356 and W14 artifact 10105003802 are tied to that candidate.
- AC mapping: W15 adds direct integrated evidence to AC-03∼AC-11 and preserves AC-12∼AC-14 presentation/save boundaries. It does not satisfy AC-01/AC-02 because no production-signed Android APK/device path exists, and it does not satisfy AC-15 because headless timing is not device performance.
- Human visual inspection, W14 listening review, first-slice fun/readability review, and actual Android performance remain residual verification. W15 mechanical integration success must not be presented as final AAA, sellable-quality, or release acceptance.

## W16-W21 cumulative acceptance delta

- AC-01 remains `NOT_IMPLEMENTED`: W16-W21 add runtime/content/campaign systems but still do not provide a production-signed Android APK installed on a device through the full install→combat→settlement→hub→next-run path.
- AC-02 remains `BLOCKED`: no debug-signing fallback is accepted, and durable protected production-key injection/update-lineage evidence remains a later release gate.
- AC-03 remains `PARTIAL`: W16 adds six mechanically distinct selectable survivor roles with live combat effects; W17 expands actual causal loadouts to 18 curated weapon definitions and 48 bounded relic definitions while retaining duplicate-cause and chain-depth constraints; W20 replaces the boss primitive with ten data-driven boss profiles. W21 changes campaign topology only. Human fun/balance and final production presentation remain open.
- AC-04 remains `PARTIAL`: W16 Close Escort/Ark Engineer consume actual Ark state; W18 adds four route profiles across Glass Garden/Flooded Archive; W19 adds Ash Railway/Eclipse Fortress runtime connections while preserving W06 route semantics and recoverable failure; W21 integrates those destinations into the four-segment/five-parent campaign graph. Final mobile/device quality and production presentation remain open.
- AC-05 remains `PARTIAL`: W16 Circuit Architect grants bounded charges only from actual circuit activations; retained W07/W09/W10 circuit semantics remain authoritative. W21 does not change circuit authority. Final content presentation/balance remains open.
- AC-06 remains `PARTIAL`: W17 exposes exactly 18 curated weapon definitions and 48 relic definitions, deterministic choices/comparison data, representative builds, persistent relic loadouts and the same causal chain-depth limit. `implemented_content.curated_weapons` and `implemented_content.relics` remain 0 until per-item production asset/provenance and human balance gates close.
- AC-07 remains `PARTIAL`: W16 Echo Recorder modifies only the already-limited replay-damage path and still does not re-enter N03 causal resolution, rewards or circuit generation. W21 retains cross-run state while migrating world topology. Final echo presentation/balance remains open.
- AC-08 remains `PARTIAL`: W18/W19 add region-specific deterministic enemy-entry behavior definitions while explicitly preserving W11 ownership of doctrine-response placement/counterplay. W21 only connects those region runtimes to the persistent world graph. Production enemy-behavior counts remain 0 pending final content/human gates.
- AC-09 remains `PARTIAL`: W18 materializes Glass Garden/Flooded Archive, W19 materializes Ash Railway/Eclipse Fortress, and W21 now integrates Twilight Shipyard plus those four parent regions into a deterministic five-parent world graph with four normal progression segments, a two-parent final branch and retained post-final continuation. Production map presentation/content breadth and human quality remain later.
- AC-10 remains `PARTIAL`: W16 Phase Scout consumes accepted live phase transitions for bounded attack charges; W18/W19 give each new parent region distinct material/shadow hazard rules and actual phase-dependent objective state. W21 does not change those phase rules. Final maps/readability/device acceptance remain open.
- AC-11 remains `PARTIAL`: W16 selected character, W17 weapon/relic build, W18 regional objective extension and W19 horizontal unlock/access outcomes all use the retained W12 checkpoint path. W21 advances the inner world snapshot to `lanternfall-world-v2` with explicit v0/v1 migration while preserving the outer `lanternfall-save-payload-v1`, settlement IDs and post-final continuation. Android lifecycle/device and distribution verification remain open.
- AC-12 remains `PARTIAL`: W16 adds six gameplay-role definitions; W17 adds 18 weapon/48 relic definitions; W18/W19 add four non-placeholder environment identities plus 24 regional entry-behavior definitions; W20 adds ten authored boss visual identities and ten boss audio identities; W21 records campaign topology without inflating production counts. `implemented_content` counts remain intentionally uninflated until their explicit production/human gates close.
- AC-13 remains `PARTIAL`: W20 produces a 1280×720 ten-boss contact sheet and deterministic 50-cue review mix. Static contact-sheet inspection is preliminary only; live visual readability, human listening/mix and actual gameplay/fun/balance are still pending, and W21 adds no human-quality evidence.
- AC-14 remains `PARTIAL`: W16 character identity, W17 loadout, W18 regional state and W19 inherited state are checkpointed through the retained runtime path. W21 adds v1→v2 world migration and an actual-main-shell final-branch checkpoint/reload contract while retaining the W18 regional checkpoint payload. The full aspect-ratio/multitouch/accessibility/Android lifecycle/device matrix remains later.
- AC-15 remains `NOT_IMPLEMENTED`: automated regressions are headless/CI evidence only; no Android-device frame-time, memory, soak or 16KB-page-size acceptance exists yet.
- AC-16 remains `PARTIAL`: W18/W19 environment art and W20 boss audiovisual identities carry project-original source/provenance records; W21 changes no asset provenance or signing lineage. Final all-asset audit, protected signing, production APK and update-path evidence remain unresolved.

## W16 retained character-expansion contract

- The selectable roster contains exactly six mechanically distinct roles; Aurora and Cinder are initially available and four additional roles have explicit horizontal/fallback unlock paths so world-choice branches cannot dead-end the roster.
- Role mechanics are event/state coupled rather than stat-only duplicates: Circuit Architect consumes real circuit activations, Close Escort and Ark Engineer consume Ark state, Phase Scout consumes accepted phase transitions, Echo Recorder stays on the limited replay path, and Ranged Observer applies one bounded non-recursive follow-up per distinct primary cause.
- Role-state consumption is cause-idempotent and bounded. Ark repair cannot revive an already failed Ark; echo modifiers remain outside the causal resolver; phase/circuit charges are finite.
- The actual main scene rejects locked selection, exercises live role effects, progresses unlocks, checkpoints an expedition and reloads the selected character through persistent save state.
- `implemented_content.characters` remains 0 because W16 proves mechanics/selection/unlocks/save integration, not final unique character art/audio/provenance, human readability/fun or balance.

## W17 retained weapon/relic expansion contract

- The retained N03 catalog still contains exactly 6 trigger, 6 delivery and 8 transform parts with the same compatibility/energy validator and maximum causal chain depth 3.
- Exactly 18 curated weapon definitions exist; every curated recipe validates under the same compatibility/energy rules and has a unique trigger/delivery/transform signature.
- Exactly 48 relic definitions exist as 8 gameplay families × 6 bounded variants. A loadout is capped at 4 relics and one relic per family; relics do not change cause identity or causal chain depth.
- Six representative builds pass the same runtime validators. Selection data provides deterministic weapon/relic choices, comparison deltas, conditions, magnitudes, tradeoffs and hard limits.
- Runtime resolution retains trigger→delivery→transform order, applies relic effects afterward, rejects duplicate cause IDs, rejects paused causal resolution and terminates at the same chain-depth limit.
- Versioned weapon state persists relic loadout and consumed causes while retained W09 v1/v0 snapshots remain migratable without replaying consumed causes.
- Actual-main-shell smoke persists/reloads the selected representative build through the W12 save path and retains W15/W16 actual-scene non-regression.
- Production weapon/relic counts remain 0 until item-specific final art/audio/provenance and human balance/readability gates close.

## W18 retained region-expansion contract

- Exactly two parent regions are introduced: `glass_garden` and `flooded_archive`, mapped from existing campaign destination IDs instead of rewriting the save schema.
- Exactly four W18 route profiles supply distinct route geometry/travel pressure/runtime environment assets while preserving W06 route choice, supply, threat, objective and recovery semantics.
- Both parent regions expose distinct material/shadow hazard rule records; the mechanical region objective requires actual phase/circuit/rest-state observations before the Ark may leave the rest gate.
- Regional objective state snapshots/restores as optional `w18_region` state without changing the W12 required runtime schema.
- Exactly 12 deterministic regional enemy-entry behavior definitions exist, six per parent region, while doctrine-response placement remains owned by the W11 path.
- Stage-0 Twilight Shipyard remains the inherited W15-W17 path; W18 does not inflate production region/enemy counts or alter version/package/signing identity.

## W19 retained region-connection contract

- `afterglow_frontier` maps to Ash Railway through `deep_rescue_patrol`; `far_lantern_chain` maps to Eclipse Fortress through `lighthouse_survey` without rewriting the then-current W18 campaign/save topology.
- Each added parent region has distinct route geometry, material/shadow hazards, six deterministic regional behavior IDs and one original runtime environment vector.
- Existing `WorldCampaignModel` settlement semantics remain authoritative for residents/lighthouse, horizontal unlocks, access rights, support/shop/threat metadata and recoverable failure.
- Successful settlement persists the corresponding horizontal unlock/access right; failed settlement remains recoverable and retains a valid departure path.
- The W18 checkpoint schema remains unchanged and preserves inherited `character_id` plus regional objective state. W19 intentionally left the final five-region campaign-topology integration to W21.
- Production region/enemy counts remain 0 by design pending complete regional audiovisual coverage and human quality gates.

## W20 retained boss mechanics/presentation contract

- Five parent-region identities expose exactly ten unique boss profiles, two per region. Every boss owns a unique pattern family, three health-gated phases, explicit pre-hit dodge guidance, attack cadence/radius/damage parameters, exactly-once reward/unlock IDs and presentation cue identities.
- `RegionSpawnDirector` preserves the retained W05 dedicated boss warning/once-per-director spawn timing while selecting W20 boss identity; `RegionSwarmEncounter` emits timed attack telegraphs before damage, advances phases from actual pooled health loss and queues reward/unlock exactly once on defeat.
- All ten boss IDs resolve one-to-one to non-placeholder project-authored SVG identities with runtime motion; danger telegraphs remain drawn after decorative boss art and retain information priority.
- Ten boss audio identities resolve five mechanical presentation cues each for exactly 50 deterministic PCM16/32kHz cues. `AudioDirector` resolves presentation cues without becoming combat authority.
- `w20-boss-ci` produces attempt-unique `w20-boss-review-<run_id>-<run_attempt>` evidence containing a 1280×720 contact sheet, deterministic 50-cue review WAV and machine-readable parameter/audio metrics.
- Final candidate `c508a49b087f6d48bf6122abfb58b78adde4ce50` passed the W20, W19, W18 and foundation push regressions. W20 run `34379024390` produced artifact `10115068634`; the reviewed ZIP SHA-256 is `9c2cbb0975ead50f0687905c4c7e6e852ceaf3e5c65f6a6305e69e2c50c7c983`.
- Automated W20 balance evidence is `PASS_SANITY_ONLY`. Static contact-sheet inspection is preliminary only; human live visual readability, listening/mix/timbral separation and gameplay/fun/difficulty balance remain pending.
- `implemented_content.bosses` remains 0 until those human gates explicitly pass. W20 does not change app version/package identity, signing lineage, permissions or external trust boundaries.

## W21 retained campaign-topology contract

- The persistent campaign exposes exactly five ordered parent-region identities: Twilight Shipyard, Glass Garden, Flooded Archive, Ash Railway and Eclipse Fortress.
- Normal progression consists of four successful segments. Segment 3 is the final regional branch with exactly two departures: Ash Railway via `deep_rescue_patrol` and Eclipse Fortress via `lighthouse_survey`. Success advances once to segment 4/`POST_FINAL`; the same two W19 connections remain available as post-final continuation thereafter.
- The inner world schema advances from `lanternfall-world-v1` to `lanternfall-world-v2`, while the outer W12 `lanternfall-save-payload-v1`, SaveStore envelope, sequence/checksum rules and deterministic settlement IDs remain unchanged.
- A fresh pre-W21 segment-3 completion with no successful W19 connection migrates to the new segment-3 hub; an active first W19 expedition is adopted as the final branch; a save that already completed a W19 connection migrates to segment 4 so persistent rewards/unlocks are not replayed.
- v0 snapshots migrate through the retained pre-W21 semantic shape. `applied_settlement_ids`, salvage/progression, access rights, horizontal unlocks and cross-run state remain preserved.
- Failed final-branch settlements remain recoverable at segment 3 with both departures available; successful settlement remains idempotent across retry/restart.
- The actual main-shell W21 contract validates both final parent branches through W18/W19 regional runtime integration and requires a segment-3 regional checkpoint to reload with world/region identity aligned.
- `implemented_content.regions` remains 0. W21 proves persistent topology/save compatibility, not human region quality, Android lifecycle/device performance, signing, install/update or release acceptance.

## Non-regression and safety

- NR-01: no repository/application outside `shaterguy/temporary-repository` is mutated by this implementation.
- NR-02: private signing/key/password material must not enter Git, workflow logs, or artifacts.
- NR-03: W12 settlement remains idempotent across retry/restart through deterministic settlement IDs, the world model's settled-ID ledger, monotonic save sequence/checksum validation and save-before-live-commit ordering. W21 migration must preserve the ledger and may not replay already-applied W19 world effects.
- NR-04: after first distribution, each package/certificate/storage/version lineage must remain update-compatible; no first distribution has occurred yet.
- NR-05: do not add payments, accounts, runtime networking, broad permissions, or untrusted signing paths without explicit review.
- NR-06: W13/W14/W15 presentation may read runtime state but must not become authoritative for combat, world, save, doctrine, circuit, phase, weapon or echo semantics.
- NR-07: W16-W21 mechanics/presentation/topology bridges must preserve the same authority split: role/UI/art/audio layers may consume authoritative state but may not bypass retained combat/world/save/circuit/phase/weapon/echo/doctrine invariants.
- NR-08: W16-W21 definition, audiovisual or topology counts must not be copied into production `implemented_content` counts before their explicit production/human gates pass.
