extends RefCounted

const PhaseBattlefieldModelScript = preload("res://game/world/phase_battlefield_model.gd")
const MedievalWorldLayoutScript = preload("res://game/world/medieval_world_layout.gd")
const SpawnDirectorScript = preload("res://game/combat/spawn_director.gd")
const SurvivorControllerScript = preload("res://game/combat/survivor_controller.gd")
const W23RegionSwarmEncounterScript = preload("res://game/combat/w23_region_swarm_encounter.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []
    _check_phase_specific_spawn(failures)
    _check_world_attack_blockers(failures)
    _check_multiscreen_camera_traversal(failures)
    return failures


static func _check_phase_specific_spawn(failures: Array[String]) -> void:
    var terrain = PhaseBattlefieldModelScript.new()
    var shadow_blocked := Vector2(760.0, 340.0)
    if not terrain.is_spawn_position_allowed_for_phase(
        PhaseBattlefieldModelScript.PHASE_MATERIAL,
        shadow_blocked
    ):
        failures.append("R04 phase-spawn fixture is no longer material-legal")
    if terrain.is_spawn_position_allowed_for_phase(
        PhaseBattlefieldModelScript.PHASE_SHADOW,
        shadow_blocked
    ):
        failures.append("R04 shadow-only blocker is still accepted as a shadow spawn")
    var relocated := terrain.resolve_spawn_position_for_phase(
        shadow_blocked,
        Vector2.ZERO,
        PhaseBattlefieldModelScript.PHASE_SHADOW
    )
    if relocated.is_equal_approx(shadow_blocked):
        failures.append("R04 phase-aware spawn resolver did not relocate a shadow-blocked candidate")
    elif not terrain.is_spawn_position_allowed_for_phase(
        PhaseBattlefieldModelScript.PHASE_SHADOW,
        relocated
    ):
        failures.append("R04 phase-aware spawn resolver returned terrain illegal in the enemy phase")

    var director = SpawnDirectorScript.new()
    director.reset(20260911)
    director.configure_world_provider(terrain)
    var events: Array[Dictionary] = []
    director.call(
        "_queue_spawn",
        "runner",
        Vector2.ZERO,
        1.0,
        SpawnDirectorScript.TELEGRAPH_LEAD,
        events
    )
    director.call(
        "_queue_spawn",
        "boss",
        Vector2.ZERO,
        2.0,
        SpawnDirectorScript.BOSS_WARNING_LEAD,
        events
    )
    if events.size() != 2:
        failures.append("R04 explicit runner/boss spawn contract did not emit two telegraphs")
        return
    for event in events:
        var archetype := str(event.get("archetype", ""))
        var phase_id := str(event.get("phase", ""))
        var position: Vector2 = event.get("position", Vector2.ZERO)
        if archetype in ["runner", "boss"] and phase_id != PhaseBattlefieldModelScript.PHASE_SHADOW:
            failures.append("R04 %s telegraph lost its shadow-phase identity" % archetype)
        if not terrain.is_spawn_position_allowed_for_phase(phase_id, position):
            failures.append("R04 %s telegraph was placed on terrain blocked in its own phase" % archetype)


static func _check_world_attack_blockers(failures: Array[String]) -> void:
    var terrain = PhaseBattlefieldModelScript.new()
    var player = SurvivorControllerScript.new()
    player.position = Vector2(-1000.0, -520.0)
    player.model.reset(player.position)
    var encounter = W23RegionSwarmEncounterScript.new()
    encounter.configure_player(player)
    encounter.configure_phase_provider(terrain)

    var blocked_enemy: Dictionary = encounter._pool.acquire(
        "swarm",
        Vector2(-520.0, -520.0),
        24,
        80.0,
        13.0,
        8
    )
    var blocked_id := int(blocked_enemy.get("id", -1))
    var blocked_target := _target_for_id(encounter.combat_target_snapshot(), blocked_id)
    if blocked_target.is_empty():
        failures.append("R04 world-blocker test enemy was not exposed by the runtime target provider")
    elif bool(blocked_target.get("active", true)) or not bool(blocked_target.get("world_blocked", false)):
        failures.append("R04 chapel footprint did not occlude a runtime weapon target")

    encounter._pool.set_position(blocked_id, Vector2(-1000.0, -180.0))
    var open_target := _target_for_id(encounter.combat_target_snapshot(), blocked_id)
    if open_target.is_empty() or not bool(open_target.get("active", false)):
        failures.append("R04 open attack lane remained blocked after moving the target clear of the chapel")

    if not terrain.is_attack_path_blocked(
        PhaseBattlefieldModelScript.PHASE_MATERIAL,
        Vector2(-1000.0, -520.0),
        Vector2(-520.0, -520.0)
    ):
        failures.append("R04 authoritative attack-path query did not report the chapel blocker")
    if terrain.is_attack_path_blocked(
        PhaseBattlefieldModelScript.PHASE_MATERIAL,
        Vector2(-1000.0, -520.0),
        Vector2(-1000.0, -180.0)
    ):
        failures.append("R04 authoritative attack-path query blocked an open vertical lane")

    encounter.free()
    player.free()


static func _check_multiscreen_camera_traversal(failures: Array[String]) -> void:
    var terrain = PhaseBattlefieldModelScript.new()
    var player = SurvivorControllerScript.new()
    player.camera_enabled = true
    player._ready()
    player.set_phase_provider(terrain)
    var camera := player.get_node_or_null("CombatCamera") as Camera2D
    if camera == null or not camera.enabled:
        failures.append("R03 runtime CombatCamera was not created and enabled")
        player.free()
        return
    if camera.get_parent() != player or not camera.position.is_zero_approx():
        failures.append("R03 CombatCamera is not parent-anchored to the moving player")
        player.free()
        return
    if not camera.position_smoothing_enabled or camera.position_smoothing_speed <= 0.0:
        failures.append("R03 CombatCamera lost its configured follow smoothing")

    var traversal_points := [
        Vector2.ZERO,
        MedievalWorldLayoutScript.CHAPEL_GAMEPLAY_POSITION + Vector2(-340.0, 220.0),
        Vector2(1400.0, -240.0),
        Vector2(1400.0, 760.0),
        Vector2(1400.0, 1200.0),
        MedievalWorldLayoutScript.RIDGE_WAYFINDING_CENTER,
        MedievalWorldLayoutScript.BRIDGE_GAMEPLAY_POSITION,
    ]
    var previous: Vector2 = traversal_points[0]
    var max_origin_distance := 0.0
    player.global_position = previous
    player.model.position = previous
    for index in range(1, traversal_points.size()):
        var requested: Vector2 = traversal_points[index]
        var resolved := terrain.resolve_player_position(previous, requested)
        if not resolved.is_equal_approx(requested):
            failures.append("R03 multi-screen traversal was blocked before waypoint %d: %s" % [index, requested])
            break
        player.global_position = resolved
        player.model.position = resolved
        if camera.get_parent() != player or not camera.position.is_zero_approx():
            failures.append("R03 CombatCamera detached from the player at waypoint %d" % index)
            break
        max_origin_distance = maxf(max_origin_distance, resolved.distance_to(Vector2.ZERO))
        previous = resolved

    if max_origin_distance < 1600.0:
        failures.append("R03 traversal never moved far enough to prove a multi-screen battlefield")
    if not previous.is_equal_approx(MedievalWorldLayoutScript.BRIDGE_GAMEPLAY_POSITION):
        failures.append("R03 traversal did not return through the central bridge/ford corridor")
    player.free()


static func _target_for_id(targets: Array[Dictionary], target_id: int) -> Dictionary:
    for target in targets:
        if int(target.get("id", -1)) == target_id:
            return target
    return {}
