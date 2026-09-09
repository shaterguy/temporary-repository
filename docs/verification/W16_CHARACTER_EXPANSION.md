# W16 character expansion verification contract

Task: `SR-20260909-150106-PPO12Y`
Branch: `v1.0.0-dev1`

This checkpoint maps the W16 character expansion to the existing acceptance criteria in `REQUIREMENT_TRACE.md`. It does not claim final production character art/audio, final balance, Android-device acceptance, signing, or release completion.

## Acceptance-criteria mapping

- AC-03 Survivor core loop: six selectable roles now alter live survivor combat behavior through explicit role mechanics rather than stat-only duplicates.
- AC-04 N01 mobile fortress/routes: Close Escort and Ark Engineer consume actual Ark position/durability state; repair cannot revive an already failed Ark.
- AC-05 N02 movement-drawn circuits: Circuit Architect receives bounded charges only from actual circuit activation callbacks.
- AC-07 N04 tactical echo: Echo Recorder modifies the already limited replay-damage path without re-entering causal weapon resolution, rewards, or circuit generation.
- AC-10 N07 dual-phase battlefield: Phase Scout receives exactly two bounded attack charges after an accepted live phase transition.
- AC-12 distinct content/no placeholders: six gameplay-role definitions and four progression unlocks are tracked separately from production-content counts. Aurora/Cinder map to W13 visual identities; the remaining final character-specific art/audio/provenance gate stays open for W23.
- AC-14 lifecycle/save failures: the selected character ID is stored inside active-expedition runtime checkpoints and verified after persistent reload without changing the save schema.

## Role contract

1. Aurora / Circuit Architect: actual circuit activation grants up to two charges; each new attack cause consumes one for +35% resolved damage.
2. Cinder / Close Escort: while within 220 px of the Ark, primary damage is +20% and incoming armor gains +3.
3. Rivet / Ark Engineer: while within 300 px of the Ark, every fourth distinct attack cause repairs 8 Ark durability, capped at max durability and disabled after recoverable failure is entered.
4. Veil / Phase Scout: an accepted phase transition grants two charges; the next two distinct attack causes each gain +30% damage.
5. Mneme / Echo Recorder: N04 replay fire damage is multiplied by 1.50 after the existing limited-power replay calculation and remains outside the N03 causal resolver.
6. Vesper / Ranged Observer: once per distinct primary cause, one different active target within 720 px may receive a non-recursive 55% follow-up hit.

## Unlock contract

- Aurora and Cinder are available at a fresh campaign.
- Rivet unlocks through `field_refit`, a repaired lighthouse, or the segment-2 fallback.
- Veil unlocks through `phase_anchor`, a preserved route, or the segment-2 fallback.
- Mneme unlocks from a persisted tactical-echo record or the segment-1 fallback.
- Vesper unlocks after four rescued residents or the segment-2 fallback.
- The branch-specific first rescue settlement exposes five roles; segment 2 guarantees all six so mutually exclusive world choices cannot dead-end the roster.

## Automated verification

- `tests/unit/test_character_expansion.gd` validates six unique IDs/roles, required explanation/tutorial fields, branch/fallback unlock behavior, cause-idempotent role-state consumption, Ark repair cadence, phase charges, echo multiplier, and observer follow-up contract.
- `tests/integration/w16_character_roles_smoke.gd` instantiates the actual main scene, verifies 2 initial/6 total roster entries, rejects a locked character, selects Cinder, observes its live near-Ark damage reduction, settles progression to five unlocked roles, selects Rivet, checkpoints the active expedition, and reloads the selected character from persistent save state.
- The existing W15 vertical-slice smoke remains mandatory in the same CI job and therefore guards the prior slot→hub→expedition→settlement→next-run path.
- Headless import remains a script/scene compile gate. The fast runner retains the literal `suite.run()` call and advances to the W16 contract with 17 suites.

## Deferred production gates

- `implemented_content.characters` remains 0. W16 proves runtime mechanics, selection, unlocks, explanation, tutorial, and save integration only.
- Final unique character art, character-specific audio, complete provenance/license mapping, animation polish, human readability/fun review, and balance remain W23/W24/W25 dependencies.
- No Android permission, exported component, network, user-data, secret, dependency, signing, or distribution trust boundary changes are introduced by W16 (`SECURITY_DELTA=NONE`).
