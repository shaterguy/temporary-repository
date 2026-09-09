extends RefCounted

const PhaseBattlefieldModelScript = preload("res://game/world/phase_battlefield_model.gd")
const LightCircuitModelScript = preload("res://game/systems/circuit/light_circuit_model.gd")
const SwarmEncounterScript = preload("res://game/combat/swarm_encounter.gd")
const SurvivorControllerScript = preload("res://game/combat/survivor_controller.gd")
const ArkRouteModelScript = preload("res://game/world/ark_route_model.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []

    var terrain = PhaseBattlefieldModelScript.new()
    var material_blocked := Vector2(560.0, 340.0)
    var shadow_blocked := Vector2(760.0, 340.0)
    if terrain.is_position_walkable(PhaseBattlefieldModelScript.PHASE_MATERIAL, material_blocked):
        failures.append("material-only blocker did not block the material battlefield")
    if not terrain.is_position_walkable(PhaseBattlefieldModelScript.PHASE_SHADOW, material_blocked):
        failures.append("same coordinate did not become walkable in the shadow battlefield")
    if terrain.is_position_walkable(PhaseBattlefieldModelScript.PHASE_SHADOW, shadow_blocked):
        failures.append("shadow-only blocker did not block the shadow battlefield")
    if not terrain.is_position_walkable(PhaseBattlefieldModelScript.PHASE_MATERIAL, shadow_blocked):
        failures.append("same coordinate did not remain walkable in the material battlefield")

    var blocked_generation: int = int(terrain.transition_generation)
    var blocked := terrain.request_transition(shadow_blocked, 2, false, false)
    if bool(blocked.get("accepted", false)) or str(blocked.get("reason", "")) != "blocked_destination":
        failures.append("phase transition accepted a blocked destination")
    if terrain.transition_generation != blocked_generation or terrain.cooldown_remaining > 0.0:
        failures.append("failed phase transition consumed generation or cooldown")

    var valid_position := Vector2(400.0, 360.0)
    var preview := terrain.transition_preview(valid_position, 3)
    if (
        not bool(preview.get("valid", false))
        or str(preview.get("target_phase", "")) != PhaseBattlefieldModelScript.PHASE_SHADOW
        or int(preview.get("immediate_threat_count", 0)) != 3
    ):
        failures.append("phase preview did not disclose valid destination and immediate threat count")

    var switched := terrain.request_transition(valid_position, 3, false, false)
    if (
        not bool(switched.get("accepted", false))
        or terrain.current_phase != PhaseBattlefieldModelScript.PHASE_SHADOW
        or terrain.cooldown_remaining <= 0.0
    ):
        failures.append("valid phase transition did not enter shadow and arm cooldown")
    var repeated := terrain.request_transition(valid_position, 0, false, false)
    if bool(repeated.get("accepted", false)) or str(repeated.get("reason", "")) != "cooldown":
        failures.append("phase transition ignored its reuse cooldown")

    var paused = PhaseBattlefieldModelScript.new()
    var paused_result := paused.request_transition(valid_position, 0, true, false)
    if bool(paused_result.get("accepted", false)) or paused.last_rejection_reason != "paused":
        failures.append("paused phase request was not rejected without transition")
    var cancelled_result := paused.request_transition(valid_position, 0, false, true)
    if bool(cancelled_result.get("accepted", false)) or paused.last_rejection_reason != "cancelled":
        failures.append("cancelled phase request was not rejected without transition")
    if paused.transition_generation != 0 or paused.cooldown_remaining > 0.0:
        failures.append("paused or cancelled phase request consumed transition state")

    var movement = PhaseBattlefieldModelScript.new()
    var from_position := Vector2(440.0, 340.0)
    var through_material_wall := Vector2(650.0, 340.0)
    if movement.resolve_player_position(from_position, through_material_wall) != from_position:
        failures.append("material collision mask allowed movement through a material blocker")
    movement.request_transition(valid_position, 0, false, false)
    if movement.resolve_player_position(from_position, through_material_wall) != through_material_wall:
        failures.append("shadow collision mask did not expose the alternate same-coordinate path")
    if movement.resolve_player_position(from_position, Vector2(20.0, 340.0)) != from_position:
        failures.append("phase movement allowed escape through the map edge")

    var traveling_ark = ArkRouteModelScript.new()
    traveling_ark.reset(808)
    if not traveling_ark.choose_route(ArkRouteModelScript.JUNCTION_ID, "risk_channel"):
        failures.append("ark route setup failed before phase-transition integration check")
    traveling_ark.step(1.0)
    var route_status_before: String = str(traveling_ark.status)
    var route_distance_before: float = float(traveling_ark.distance_travelled)
    var route_supply_before: int = int(traveling_ark.supply)
    var route_phase = PhaseBattlefieldModelScript.new()
    var route_switch := route_phase.request_transition(valid_position, 1, false, false)
    if not bool(route_switch.get("accepted", false)):
        failures.append("valid phase switch failed while ark route was traveling")
    if (
        traveling_ark.status != route_status_before
        or absf(traveling_ark.distance_travelled - route_distance_before) > 0.001
        or traveling_ark.supply != route_supply_before
    ):
        failures.append("phase switch mutated ark route progress, status or supply")
    traveling_ark.step(0.25)
    if traveling_ark.status == ArkRouteModelScript.STATUS_TRAVELING and traveling_ark.distance_travelled <= route_distance_before:
        failures.append("ark route stopped progressing after a phase switch")

    var saved = PhaseBattlefieldModelScript.new()
    saved.request_transition(valid_position, 4, false, false)
    saved.step(1.25, false)
    var snapshot := saved.snapshot()
    var restored = PhaseBattlefieldModelScript.new()
    if not restored.restore_snapshot(snapshot):
        failures.append("valid phase snapshot could not be restored")
    elif (
        restored.current_phase != saved.current_phase
        or restored.transition_generation != saved.transition_generation
        or absf(restored.cooldown_remaining - saved.cooldown_remaining) > 0.001
    ):
        failures.append("phase snapshot restore changed phase, generation or cooldown")

    var snare = LightCircuitModelScript.new()
    snare.select_module(LightCircuitModelScript.MODULE_SNARE)
    _feed(snare, _square(Vector2.ZERO, 60.0), 0.10)
    if absf(snare.movement_multiplier_at(Vector2(60.0, 0.0)) - LightCircuitModelScript.SNARE_MOVEMENT_MULTIPLIER) > 0.001:
        failures.append("material circuit was not active before W08 phase integration check")
    snare.set_world_phase(PhaseBattlefieldModelScript.PHASE_SHADOW)
    if absf(snare.movement_multiplier_at(Vector2(60.0, 0.0)) - 1.0) > 0.001:
        failures.append("material circuit leaked its effect into the shadow battlefield")
    snare.set_world_phase(PhaseBattlefieldModelScript.PHASE_MATERIAL)
    if absf(snare.movement_multiplier_at(Vector2(60.0, 0.0)) - LightCircuitModelScript.SNARE_MOVEMENT_MULTIPLIER) > 0.001:
        failures.append("returning to material did not restore the recorded material circuit effect")

    var phase_filter = PhaseBattlefieldModelScript.new()
    var filter_player := Node2D.new()
    filter_player.position = valid_position
    var filtered_encounter = SwarmEncounterScript.new()
    filtered_encounter.configure_player(filter_player)
    filtered_encounter.configure_phase_provider(phase_filter)
    var material_enemy: Dictionary = filtered_encounter._pool.acquire("swarm", Vector2(430.0, 360.0), 24, 80.0, 13.0, 8)
    var shadow_enemy: Dictionary = filtered_encounter._pool.acquire("runner", Vector2(450.0, 360.0), 32, 100.0, 12.0, 10)
    var material_id := int(material_enemy.get("id", -1))
    var shadow_id := int(shadow_enemy.get("id", -1))
    var material_targets := filtered_encounter.combat_target_snapshot()
    if _active_target_ids(material_targets) != [material_id]:
        failures.append("material phase targeting did not hide shadow enemies")
    phase_filter.request_transition(valid_position, 0, false, false)
    var shadow_targets := filtered_encounter.combat_target_snapshot()
    if _active_target_ids(shadow_targets) != [shadow_id]:
        failures.append("shadow phase targeting did not swap to shadow enemies")
    filtered_encounter.free()
    filter_player.free()

    var cross_phase = PhaseBattlefieldModelScript.new()
    var cross_player = SurvivorControllerScript.new()
    cross_player.position = valid_position
    cross_player.model.reset(valid_position)
    var cross_encounter = SwarmEncounterScript.new()
    cross_encounter.configure_player(cross_player)
    cross_encounter.configure_phase_provider(cross_phase)
    var boss: Dictionary = cross_encounter._pool.acquire("boss", Vector2(620.0, 360.0), 540, 52.0, 36.0, 18)
    var boss_id := int(boss.get("id", -1))
    cross_encounter._enemy_phases[boss_id] = PhaseBattlefieldModelScript.PHASE_SHADOW
    var health_before := int(cross_player.model.health)
    cross_encounter._advance_swarm(0.10)
    if int(cross_player.model.health) != health_before:
        failures.append("opposite-phase boss applied direct contact damage without a telegraph")
    if cross_encounter.cross_phase_warning_snapshot().size() != 1:
        failures.append("opposite-phase boss did not create an explicit cross-phase attack telegraph")
    cross_encounter.advance_cross_phase_attacks(SwarmEncounterScript.CROSS_PHASE_TELEGRAPH_SECONDS * 0.5)
    if int(cross_player.model.health) != health_before:
        failures.append("cross-phase attack damaged the player before its warning completed")
    cross_encounter.advance_cross_phase_attacks(SwarmEncounterScript.CROSS_PHASE_TELEGRAPH_SECONDS * 0.5 + 0.05)
    if int(cross_player.model.health) >= health_before:
        failures.append("telegraphed cross-phase attack never resolved after its warning")
    cross_encounter.free()
    cross_player.free()

    return failures


static func _active_target_ids(targets: Array[Dictionary]) -> Array[int]:
    var result: Array[int] = []
    for target in targets:
        if bool(target.get("active", false)):
            result.append(int(target.get("id", -1)))
    return result


static func _feed(model, points: PackedVector2Array, delta: float) -> void:
    for point in points:
        model.step(delta, point, false)


static func _square(center: Vector2, radius: float) -> PackedVector2Array:
    return PackedVector2Array([
        center + Vector2(-radius, -radius),
        center + Vector2(radius, -radius),
        center + Vector2(radius, radius),
        center + Vector2(-radius, radius),
        center + Vector2(-radius, -radius),
    ])
