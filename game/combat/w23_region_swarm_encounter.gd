extends "res://game/combat/region_swarm_encounter.gd"

const W23ArtCatalogScript = preload("res://game/presentation/w23_world_event_art_catalog.gd")

var _w23_visual_by_entity: Dictionary = {}


func configure_region_profile(profile: Dictionary) -> bool:
    _w23_visual_by_entity.clear()
    return super.configure_region_profile(profile)


func clear_region_profile() -> void:
    _w23_visual_by_entity.clear()
    super.clear_region_profile()


func combat_target_snapshot() -> Array[Dictionary]:
    var targets: Array[Dictionary] = super.combat_target_snapshot()
    if (
        not is_instance_valid(_player)
        or not is_instance_valid(_phase_provider)
        or not _phase_provider.has_method("is_attack_path_blocked")
    ):
        return targets
    var phase_id := _current_phase()
    for index in range(targets.size()):
        var target: Dictionary = targets[index]
        if not bool(target.get("active", false)):
            continue
        var target_position: Vector2 = target.get("position", _player.global_position)
        if bool(_phase_provider.call(
            "is_attack_path_blocked",
            phase_id,
            _player.global_position,
            target_position
        )):
            target["active"] = false
            target["world_blocked"] = true
            targets[index] = target
    return targets


func _spawn_enemy(event: Dictionary) -> void:
    var before: Dictionary = {}
    for state: Dictionary in _pool.active_states():
        before[int(state.get("id", -1))] = true
    super._spawn_enemy(event)
    if str(event.get("archetype", "swarm")) == "boss":
        return
    var behavior_id := str(event.get("behavior_id", ""))
    if behavior_id.is_empty():
        behavior_id = _twilight_visual_for_spawn(str(event.get("spawn_id", "")))
    if behavior_id.is_empty() or W23ArtCatalogScript.enemy_entry(behavior_id).is_empty():
        return
    for state: Dictionary in _pool.active_states():
        var entity_id := int(state.get("id", -1))
        if not before.has(entity_id):
            _w23_visual_by_entity[entity_id] = behavior_id
            break
    queue_redraw()


func apply_target_damage(entity_id: int, damage: int) -> bool:
    var applied := super.apply_target_damage(entity_id, damage)
    if applied and _pool.state_for(entity_id).is_empty():
        _w23_visual_by_entity.erase(entity_id)
    return applied


func w23_art_binding_snapshot() -> Dictionary:
    return {
        "mapped_entities": _w23_visual_by_entity.duplicate(true),
        "active_region_behavior_ids": region_behavior_ids(),
        "twilight_visual_ids": W23ArtCatalogScript.TWILIGHT_ENEMY_IDS.duplicate(),
    }


func _twilight_visual_for_spawn(spawn_id: String) -> String:
    var ids: Array[String] = W23ArtCatalogScript.TWILIGHT_ENEMY_IDS
    if ids.is_empty():
        return ""
    var sequence := 0
    if spawn_id.length() >= 6:
        sequence = spawn_id.substr(spawn_id.length() - 6, 6).to_int()
    return ids[posmod(sequence, ids.size())]


func _fallback_visual_for_entity(entity_id: int) -> String:
    var ids := region_behavior_ids()
    if ids.is_empty():
        ids = W23ArtCatalogScript.TWILIGHT_ENEMY_IDS.duplicate()
    if ids.is_empty():
        return ""
    return ids[posmod(entity_id, ids.size())]


func _draw() -> void:
    super._draw()
    for state: Dictionary in _pool.active_states():
        if str(state.get("archetype", "")) == "boss":
            continue
        if not _is_phase_targetable(_phase_for_state(state)):
            continue
        var entity_id := int(state.get("id", -1))
        var visual_id := str(_w23_visual_by_entity.get(entity_id, ""))
        if visual_id.is_empty():
            visual_id = _fallback_visual_for_entity(entity_id)
        var texture := W23ArtCatalogScript.enemy_texture(visual_id)
        if texture == null:
            continue
        var radius := float(state.get("radius", 12.0))
        var native_size := texture.get_size()
        var height := radius * 2.55
        var width := height
        if native_size.y > 0.0:
            width = height * native_size.x / native_size.y
        var center: Vector2 = state.get("position", Vector2.ZERO)
        draw_texture_rect(texture, Rect2(center - Vector2(width, height) * 0.5, Vector2(width, height)), false)
        var health := float(state.get("health", 0))
        var max_health := maxf(1.0, float(state.get("max_health", 1)))
        draw_arc(
            center,
            radius + 5.0,
            -PI * 0.5,
            -PI * 0.5 + TAU * clampf(health / max_health, 0.0, 1.0),
            28,
            Color(1.0, 0.86, 0.64, 0.94),
            2.5,
            true
        )
