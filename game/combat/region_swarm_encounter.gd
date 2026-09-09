extends "res://game/combat/swarm_encounter.gd"

const RegionSpawnDirectorScript = preload("res://game/combat/region_spawn_director.gd")
const BossCatalogScript = preload("res://game/data/boss_catalog.gd")
const BossEncounterModelScript = preload("res://game/combat/boss_encounter_model.gd")

var _boss_model = BossEncounterModelScript.new()
var _boss_profile: Dictionary = {}
var _boss_entity_id: int = -1
var _boss_event_log: Array[Dictionary] = []
var _boss_reward_queue: Array[Dictionary] = []
var _boss_visual_warnings: Array[Dictionary] = []


func _init() -> void:
    _director = RegionSpawnDirectorScript.new()
    _sync_boss_profile()


func configure_region_profile(profile: Dictionary) -> bool:
    if not bool(_director.call("configure_region_profile", profile)):
        return false
    _reset_boss_runtime()
    _sync_boss_profile()
    return not _boss_profile.is_empty()


func clear_region_profile() -> void:
    _director.call("clear_region_profile")
    _reset_boss_runtime()
    _sync_boss_profile()


func configure_boss_id(boss_id: String) -> bool:
    if not bool(_director.call("configure_boss_id", boss_id)):
        return false
    _reset_boss_runtime()
    _sync_boss_profile()
    return true


func region_behavior_ids() -> Array[String]:
    var result: Array[String] = []
    var raw_ids: Variant = _director.call("region_behavior_ids")
    if raw_ids is Array:
        for raw_id: Variant in raw_ids:
            result.append(str(raw_id))
    return result


func boss_profile_snapshot() -> Dictionary:
    return _boss_profile.duplicate(true)


func boss_runtime_snapshot() -> Dictionary:
    return {
        "active_entity_id": _boss_entity_id,
        "profile": _boss_profile.duplicate(true),
        "model": _boss_model.snapshot(),
        "reward_queue_size": _boss_reward_queue.size(),
        "event_count": _boss_event_log.size(),
    }


func boss_event_log() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for event in _boss_event_log:
        result.append(event.duplicate(true))
    return result


func claim_boss_rewards() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    for reward in _boss_reward_queue:
        result.append(reward.duplicate(true))
    _boss_reward_queue.clear()
    return result


func _physics_process(delta: float) -> void:
    super._physics_process(delta)
    if delta <= 0.0 or not is_instance_valid(_player):
        return
    _adopt_restored_boss_if_needed()
    _advance_boss_visual_warnings(delta)
    for event in _boss_model.step(delta):
        _consume_boss_model_event(event)
    queue_redraw()


func _consume_director_event(event: Dictionary) -> void:
    var event_type := str(event.get("type", ""))
    var archetype := str(event.get("archetype", ""))
    if archetype == "boss" and event_type == "telegraph":
        _record_boss_event({
            "type": "boss_spawn_telegraph",
            "boss_id": str(event.get("boss_id", "")),
            "telegraph_duration": float(event.get("telegraph_duration", 0.0)),
            "position": event.get("position", Vector2.ZERO),
            "presentation_cue": str(event.get("boss_intro_cue", "")),
        })
        super._consume_director_event(event)
        return
    if archetype == "boss" and event_type == "spawn":
        _spawn_w20_boss(event)
        return
    super._consume_director_event(event)


func apply_target_damage(entity_id: int, damage: int) -> bool:
    var state_before := _pool.state_for(entity_id)
    var was_active_boss := entity_id == _boss_entity_id and not state_before.is_empty()
    var resolved_damage := damage
    if was_active_boss:
        resolved_damage = _cap_boss_damage_to_next_phase(state_before, damage)
    var applied := super.apply_target_damage(entity_id, resolved_damage)
    if not was_active_boss or not applied:
        return applied
    var state_after := _pool.state_for(entity_id)
    if state_after.is_empty():
        for event in _boss_model.defeat():
            _consume_boss_model_event(event)
        _boss_entity_id = -1
        return true
    for event in _boss_model.apply_health(
        int(state_after.get("health", 0)),
        int(state_after.get("max_health", 1))
    ):
        _consume_boss_model_event(event)
    return true


func _cap_boss_damage_to_next_phase(state: Dictionary, damage: int) -> int:
    var resolved_damage := maxi(0, damage)
    var phase_index := int(_boss_model.snapshot().get("phase_index", 0))
    var thresholds: Variant = _boss_profile.get("phase_thresholds", [])
    if not thresholds is Array or phase_index >= thresholds.size():
        return resolved_damage
    var current_health := int(state.get("health", 0))
    var max_health := int(state.get("max_health", 1))
    var phase_floor := maxi(1, int(ceil(float(max_health) * float(thresholds[phase_index]))))
    if current_health - resolved_damage < phase_floor:
        return maxi(0, current_health - phase_floor)
    return resolved_damage


func _spawn_w20_boss(event: Dictionary) -> void:
    var boss_id := str(event.get("boss_id", ""))
    var profile := BossCatalogScript.profile_for_boss(boss_id)
    if profile.is_empty():
        profile = _boss_profile.duplicate(true)
    if profile.is_empty() or not BossCatalogScript.validate_profile(profile):
        super._consume_director_event(event)
        return
    _boss_profile = profile
    if not _boss_model.configure(_boss_profile):
        super._consume_director_event(event)
        return

    var state := _pool.acquire(
        "boss",
        event.get("position", Vector2.ZERO),
        int(_boss_profile.get("max_health", 540)),
        float(_boss_profile.get("move_speed", 52.0)),
        float(_boss_profile.get("radius", 36.0)),
        int(_boss_profile.get("contact_damage", 18))
    )
    if state.is_empty():
        return
    _boss_entity_id = int(state.get("id", -1))
    var first_phase: Dictionary = _boss_profile.get("phases", [])[0]
    _enemy_phases[_boss_entity_id] = str(first_phase.get("body_phase", "material"))
    for model_event in _boss_model.begin(_boss_entity_id):
        _consume_boss_model_event(model_event)


func _consume_boss_model_event(event: Dictionary) -> void:
    var record := event.duplicate(true)
    var boss_state := _pool.state_for(_boss_entity_id) if _boss_entity_id >= 0 else {}
    var boss_position: Vector2 = boss_state.get("position", Vector2.ZERO)
    if not record.has("position"):
        record["position"] = boss_position
    _record_boss_event(record)

    match str(record.get("type", "")):
        "boss_phase_changed":
            if _boss_entity_id >= 0:
                _enemy_phases[_boss_entity_id] = str(record.get("body_phase", "material"))
        "boss_telegraph":
            var warning := record.duplicate(true)
            var duration := maxf(0.05, float(warning.get("telegraph_duration", 0.8)))
            warning["duration"] = duration
            warning["remaining"] = duration
            _boss_visual_warnings.append(warning)
        "boss_attack":
            _resolve_boss_attack(record, boss_position)
        "boss_defeated":
            _boss_reward_queue.append({
                "boss_id": str(record.get("boss_id", "")),
                "reward_id": str(record.get("reward_id", "")),
                "unlock_id": str(record.get("unlock_id", "")),
                "presentation_cue": str(record.get("presentation_cue", "")),
            })
    queue_redraw()


func _resolve_boss_attack(event: Dictionary, boss_position: Vector2) -> void:
    if not is_instance_valid(_player) or not _player.has_method("take_damage"):
        return
    var active_phase := str(event.get("active_phase", "any"))
    if active_phase != "any" and active_phase != _current_phase():
        return
    if BossEncounterModelScript.attack_hits_position(event, boss_position, _player.global_position):
        _player.call("take_damage", int(event.get("damage", 0)))


func _sync_boss_profile() -> void:
    var raw_profile: Variant = _director.call("active_boss_profile")
    _boss_profile = raw_profile.duplicate(true) if raw_profile is Dictionary else {}
    if not _boss_profile.is_empty():
        _boss_model.configure(_boss_profile)


func _reset_boss_runtime() -> void:
    _boss_entity_id = -1
    _boss_event_log.clear()
    _boss_reward_queue.clear()
    _boss_visual_warnings.clear()
    _boss_model.reset_runtime()


func _adopt_restored_boss_if_needed() -> void:
    if _boss_entity_id >= 0 or _boss_profile.is_empty():
        return
    for state in _pool.active_states():
        if str(state.get("archetype", "")) != "boss":
            continue
        _boss_entity_id = int(state.get("id", -1))
        if not _boss_model.configure(_boss_profile):
            _boss_entity_id = -1
            return
        for event in _boss_model.begin(_boss_entity_id):
            _consume_boss_model_event(event)
        for event in _boss_model.apply_health(
            int(state.get("health", 0)),
            int(state.get("max_health", 1))
        ):
            _consume_boss_model_event(event)
        return


func _record_boss_event(event: Dictionary) -> void:
    _boss_event_log.append(event.duplicate(true))
    while _boss_event_log.size() > 96:
        _boss_event_log.pop_front()


func _advance_boss_visual_warnings(delta: float) -> void:
    for index in range(_boss_visual_warnings.size() - 1, -1, -1):
        var warning: Dictionary = _boss_visual_warnings[index]
        var remaining := maxf(0.0, float(warning.get("remaining", 0.0)) - delta)
        if remaining <= 0.0:
            _boss_visual_warnings.remove_at(index)
        else:
            warning["remaining"] = remaining
            var state := _pool.state_for(int(warning.get("entity_id", _boss_entity_id)))
            if not state.is_empty():
                warning["position"] = state.get("position", warning.get("position", Vector2.ZERO))
            _boss_visual_warnings[index] = warning


func _draw() -> void:
    super._draw()
    var warning_color := Color(1.0, 0.80, 0.34, 0.92)
    for warning in _boss_visual_warnings:
        var origin: Vector2 = warning.get("position", Vector2.ZERO)
        var radius := float(warning.get("radius", 220.0))
        var width := maxf(5.0, float(warning.get("width", 24.0)))
        var angle := float(warning.get("angle", 0.0))
        var direction := Vector2.RIGHT.rotated(angle)
        var tangent := Vector2(-direction.y, direction.x)
        match str(warning.get("telegraph_shape", "circle")):
            "line":
                draw_line(origin - direction * radius, origin + direction * radius, warning_color, 5.0, true)
            "ring":
                draw_arc(origin, radius * 0.68, 0.0, TAU, 64, warning_color, 5.0, true)
            "cone":
                draw_arc(origin, radius, angle - 0.58, angle + 0.58, 32, warning_color, 5.0, true)
                draw_line(origin, origin + direction.rotated(-0.58) * radius, warning_color, 3.0, true)
                draw_line(origin, origin + direction.rotated(0.58) * radius, warning_color, 3.0, true)
            "cross":
                draw_line(origin - direction * radius, origin + direction * radius, warning_color, 5.0, true)
                draw_line(origin - tangent * radius, origin + tangent * radius, warning_color, 5.0, true)
            "lanes":
                var lane_gap := width * 2.8
                for lane in [-lane_gap, 0.0, lane_gap]:
                    draw_line(origin - direction * radius + tangent * lane, origin + direction * radius + tangent * lane, warning_color, 4.0, true)
            "orbit":
                draw_arc(origin, radius * 0.66, angle + 0.48, angle + TAU - 0.48, 64, warning_color, 5.0, true)
            "sweep":
                draw_line(origin, origin + direction * radius, warning_color, 6.0, true)
                draw_arc(origin, radius * 0.72, angle - 0.55, angle + 0.55, 28, warning_color, 3.0, true)
            "pillars":
                for pillar in 4:
                    var center := origin + Vector2.RIGHT.rotated(angle + TAU * float(pillar) / 4.0) * radius * 0.62
                    draw_circle(center, width * 1.45, Color(1.0, 0.72, 0.24, 0.15))
                    draw_arc(center, width * 1.45, 0.0, TAU, 24, warning_color, 4.0, true)
            "spiral":
                for band in [0.32, 0.56, 0.80]:
                    draw_arc(origin, radius * band, angle, angle + PI * 1.45, 40, warning_color, 4.0, true)
            "collapse":
                draw_arc(origin, radius * 0.50, 0.0, TAU, 48, warning_color, 4.0, true)
                draw_arc(origin, radius, 0.0, TAU, 64, warning_color, 6.0, true)
