extends "res://game/combat/spawn_director.gd"

var _region_profile: Dictionary = {}


func configure_region_profile(profile: Dictionary) -> bool:
    var raw_behaviors: Variant = profile.get("enemy_behaviors", null)
    if not raw_behaviors is Array or raw_behaviors.size() != 6:
        return false
    var seen: Array[String] = []
    for raw_behavior: Variant in raw_behaviors:
        if not raw_behavior is Dictionary:
            return false
        var behavior: Dictionary = raw_behavior
        var behavior_id := str(behavior.get("behavior_id", ""))
        if behavior_id.is_empty() or seen.has(behavior_id):
            return false
        if not ["swarm", "runner"].has(str(behavior.get("base_archetype", ""))):
            return false
        seen.append(behavior_id)
    _region_profile = profile.duplicate(true)
    return true


func clear_region_profile() -> void:
    _region_profile = {}


func region_behavior_ids() -> Array[String]:
    var result: Array[String] = []
    var raw_behaviors: Variant = _region_profile.get("enemy_behaviors", [])
    if not raw_behaviors is Array:
        return result
    for raw_behavior: Variant in raw_behaviors:
        if raw_behavior is Dictionary:
            result.append(str(raw_behavior.get("behavior_id", "")))
    return result


func _queue_spawn(
    archetype: String,
    origin: Vector2,
    scheduled_at: float,
    warning_lead: float,
    events: Array[Dictionary],
    doctrine_response: bool = false,
    formation: String = "baseline"
) -> void:
    if archetype == "boss" or _region_profile.is_empty():
        super._queue_spawn(archetype, origin, scheduled_at, warning_lead, events, doctrine_response, formation)
        return

    var behavior := _behavior_for_sequence(_sequence)
    if behavior.is_empty():
        super._queue_spawn(archetype, origin, scheduled_at, warning_lead, events, doctrine_response, formation)
        return
    var resolved_archetype := archetype if doctrine_response else str(behavior.get("base_archetype", archetype))
    var telegraph_scale := clampf(float(behavior.get("telegraph_scale", 1.0)), 0.65, 1.60)
    var resolved_lead := maxf(0.20, warning_lead * telegraph_scale)
    var spawn_position := _doctrine_spawn_position(_sequence, origin) if doctrine_response else _region_spawn_position(_sequence, origin, str(behavior.get("entry_pattern", "baseline")))
    var spawn_id := "w18-%06d" % _sequence
    var pending := {
        "spawn_id": spawn_id,
        "archetype": resolved_archetype,
        "position": spawn_position,
        "scheduled_at": scheduled_at,
        "spawn_at": scheduled_at + resolved_lead,
        "telegraph_duration": resolved_lead,
        "doctrine_response": doctrine_response,
        "doctrine_id": str(_doctrine_plan.get("doctrine_id", "none")) if doctrine_response else "",
        "formation": formation,
        "region_id": str(_region_profile.get("region_id", "")),
        "parent_region_id": str(_region_profile.get("parent_region_id", "")),
        "behavior_id": str(behavior.get("behavior_id", "")),
        "entry_pattern": str(behavior.get("entry_pattern", "baseline")),
        "phase_preference": str(behavior.get("phase_preference", "material")),
    }
    _pending.append(pending)
    var telegraph := pending.duplicate(true)
    telegraph["type"] = "telegraph"
    events.append(telegraph)
    _sequence += 1


func _behavior_for_sequence(sequence: int) -> Dictionary:
    var raw_behaviors: Variant = _region_profile.get("enemy_behaviors", [])
    if not raw_behaviors is Array or raw_behaviors.is_empty():
        return {}
    var raw_behavior: Variant = raw_behaviors[posmod(sequence, raw_behaviors.size())]
    return raw_behavior.duplicate(true) if raw_behavior is Dictionary else {}


func _region_spawn_position(sequence: int, origin: Vector2, pattern: String) -> Vector2:
    var axis := _entry_direction
    if axis.is_zero_approx():
        axis = Vector2.RIGHT.rotated(_sample01(sequence, 307) * TAU)
    var tangent := Vector2(-axis.y, axis.x)
    var base_distance := 360.0 + _sample01(sequence, 311) * 145.0
    var side := -1.0 if sequence % 2 == 0 else 1.0
    match pattern:
        "split_lane":
            return origin + axis * base_distance + tangent * side * (105.0 + _sample01(sequence, 313) * 45.0)
        "wide_arc":
            return origin + axis.rotated(side * (0.68 + _sample01(sequence, 317) * 0.26)) * (base_distance + 40.0)
        "escort_pressure":
            return origin + axis * (base_distance - 55.0) + tangent * side * 42.0
        "phase_flank":
            return origin + axis.rotated(side * (1.02 + _sample01(sequence, 331) * 0.22)) * base_distance
        "close_pressure":
            return origin + axis.rotated(side * 0.24) * maxf(300.0, base_distance - 85.0)
        "far_pressure":
            return origin + axis.rotated(side * 0.18) * (base_distance + 110.0)
        "current_arc":
            return origin + axis.rotated(side * (0.42 + _sample01(sequence, 337) * 0.30)) * (base_distance + 30.0)
        "column_push":
            return origin + axis * base_distance + tangent * float((sequence % 3) - 1) * 52.0
    return _spawn_position(sequence, origin)
