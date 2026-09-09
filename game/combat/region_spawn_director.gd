extends "res://game/combat/spawn_director.gd"

const BossCatalogScript = preload("res://game/data/boss_catalog.gd")

var _region_profile: Dictionary = {}
var _boss_profile: Dictionary = {}


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
    var parent_region_id := str(profile.get("parent_region_id", ""))
    var boss_profile := BossCatalogScript.default_boss_for_parent(
        parent_region_id,
        BossCatalogScript.default_variant_for_region(str(profile.get("region_id", "")))
    )
    if boss_profile.is_empty():
        return false
    _region_profile = profile.duplicate(true)
    _boss_profile = boss_profile
    return true


func clear_region_profile() -> void:
    _region_profile = {}
    _boss_profile = BossCatalogScript.default_boss_for_parent(BossCatalogScript.PARENT_TWILIGHT_SHIPYARD, 0)


func configure_boss_id(boss_id: String) -> bool:
    var profile := BossCatalogScript.profile_for_boss(boss_id)
    if profile.is_empty() or not BossCatalogScript.validate_profile(profile):
        return false
    _boss_profile = profile
    return true


func configure_boss_variant(parent_region_id: String, variant: int) -> bool:
    var profile := BossCatalogScript.default_boss_for_parent(parent_region_id, variant)
    if profile.is_empty():
        return false
    _boss_profile = profile
    return true


func active_boss_profile() -> Dictionary:
    _ensure_boss_profile()
    return _boss_profile.duplicate(true)


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
    if archetype == "boss":
        _queue_boss_spawn(origin, scheduled_at, warning_lead, events, doctrine_response, formation)
        return
    if _region_profile.is_empty():
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


func _queue_boss_spawn(
    origin: Vector2,
    scheduled_at: float,
    warning_lead: float,
    events: Array[Dictionary],
    doctrine_response: bool,
    formation: String
) -> void:
    _ensure_boss_profile()
    var spawn_id := "w20-%06d" % _sequence
    var spawn_position := _spawn_position(_sequence, origin)
    var pending := {
        "spawn_id": spawn_id,
        "archetype": "boss",
        "position": spawn_position,
        "scheduled_at": scheduled_at,
        "spawn_at": scheduled_at + warning_lead,
        "telegraph_duration": warning_lead,
        "doctrine_response": doctrine_response,
        "doctrine_id": str(_doctrine_plan.get("doctrine_id", "none")) if doctrine_response else "",
        "formation": formation,
        "region_id": str(_region_profile.get("region_id", "twilight_shipyard")),
        "parent_region_id": str(_boss_profile.get("parent_region_id", BossCatalogScript.PARENT_TWILIGHT_SHIPYARD)),
        "boss_id": str(_boss_profile.get("boss_id", "")),
        "boss_display_name": str(_boss_profile.get("display_name", "")),
        "boss_max_health": int(_boss_profile.get("max_health", 540)),
        "boss_move_speed": float(_boss_profile.get("move_speed", 52.0)),
        "boss_radius": float(_boss_profile.get("radius", 36.0)),
        "boss_contact_damage": int(_boss_profile.get("contact_damage", 18)),
        "boss_intro_cue": str(_boss_profile.get("intro_cue", "")),
        "boss_pattern_shape": str(_boss_profile.get("pattern_shape", "")),
    }
    _pending.append(pending)
    var telegraph := pending.duplicate(true)
    telegraph["type"] = "telegraph"
    events.append(telegraph)
    _sequence += 1


func _ensure_boss_profile() -> void:
    if not _boss_profile.is_empty():
        return
    _boss_profile = BossCatalogScript.default_boss_for_parent(BossCatalogScript.PARENT_TWILIGHT_SHIPYARD, 0)


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
