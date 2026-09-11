extends "res://game/combat/region_swarm_encounter.gd"

const W23ArtCatalogScript = preload("res://game/presentation/w23_world_event_art_catalog.gd")

const MAX_ACTIVE_ENEMIES: int = 192
const REGULAR_ACTIVE_BUDGET: int = 191
const CULL_DISTANCE: float = 1800.0
const MAX_REGULAR_LIFETIME_SECONDS: float = 55.0

var _w23_visual_by_entity: Dictionary = {}
var _enemy_spawned_at: Dictionary = {}
var _budget_rejections: int = 0
var _distance_culls: int = 0
var _lifetime_culls: int = 0
var _peak_active_enemies: int = 0


func configure_region_profile(profile: Dictionary) -> bool:
    _w23_visual_by_entity.clear()
    return super.configure_region_profile(profile)


func clear_region_profile() -> void:
    _w23_visual_by_entity.clear()
    super.clear_region_profile()


func _physics_process(delta: float) -> void:
    if delta > 0.0 and is_instance_valid(_player):
        _cull_runtime_enemies()
    super._physics_process(delta)
    _peak_active_enemies = maxi(_peak_active_enemies, _pool.active_count())


func combat_target_snapshot() -> Array[Dictionary]:
    var targets: Array[Dictionary] = super.combat_target_snapshot()
    var state_by_id: Dictionary = {}
    for state: Dictionary in _pool.active_states():
        state_by_id[int(state.get("id", -1))] = state

    var phase_id := _current_phase()
    for index in range(targets.size()):
        var target: Dictionary = targets[index]
        var entity_id := int(target.get("id", -1))
        var state: Dictionary = state_by_id.get(entity_id, {})
        if not state.is_empty():
            var archetype := str(state.get("archetype", "swarm"))
            target["archetype"] = archetype
            target["health"] = int(state.get("health", 0))
            target["max_health"] = int(state.get("max_health", 1))
            var behavior_id := str(_w23_visual_by_entity.get(entity_id, ""))
            if behavior_id.is_empty() and archetype != "boss":
                behavior_id = _fallback_visual_for_entity(entity_id)
            target["behavior_id"] = behavior_id
            if archetype == "boss":
                target["boss_id"] = str(_boss_profile.get("boss_id", ""))

        if (
            bool(target.get("active", false))
            and is_instance_valid(_player)
            and is_instance_valid(_phase_provider)
            and _phase_provider.has_method("is_attack_path_blocked")
        ):
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
    var archetype := str(event.get("archetype", "swarm"))
    if archetype != "boss" and _pool.active_count() >= REGULAR_ACTIVE_BUDGET:
        _budget_rejections += 1
        return

    var before: Dictionary = {}
    for state: Dictionary in _pool.active_states():
        before[int(state.get("id", -1))] = true
    super._spawn_enemy(event)

    var new_entity_id := -1
    for state: Dictionary in _pool.active_states():
        var entity_id := int(state.get("id", -1))
        if not before.has(entity_id):
            new_entity_id = entity_id
            break
    if new_entity_id < 0:
        return

    _enemy_spawned_at[new_entity_id] = float(event.get("spawn_at", _director.elapsed_time))
    _peak_active_enemies = maxi(_peak_active_enemies, _pool.active_count())
    if archetype == "boss":
        return

    var behavior_id := str(event.get("behavior_id", ""))
    if behavior_id.is_empty():
        behavior_id = _twilight_visual_for_spawn(str(event.get("spawn_id", "")))
    if behavior_id.is_empty() or W23ArtCatalogScript.enemy_entry(behavior_id).is_empty():
        return
    _w23_visual_by_entity[new_entity_id] = behavior_id
    queue_redraw()


func apply_target_damage(entity_id: int, damage: int) -> bool:
    var applied := super.apply_target_damage(entity_id, damage)
    if applied and _pool.state_for(entity_id).is_empty():
        _w23_visual_by_entity.erase(entity_id)
        _enemy_spawned_at.erase(entity_id)
    return applied


func runtime_performance_snapshot() -> Dictionary:
    return {
        "active_enemies": _pool.active_count(),
        "pool_capacity": _pool.capacity(),
        "max_active_enemies": MAX_ACTIVE_ENEMIES,
        "regular_active_budget": REGULAR_ACTIVE_BUDGET,
        "peak_active_enemies": _peak_active_enemies,
        "budget_rejections": _budget_rejections,
        "distance_culls": _distance_culls,
        "lifetime_culls": _lifetime_culls,
        "tracked_lifetimes": _enemy_spawned_at.size(),
        "cull_distance": CULL_DISTANCE,
        "max_regular_lifetime_seconds": MAX_REGULAR_LIFETIME_SECONDS,
    }


func _cull_runtime_enemies() -> void:
    if not is_instance_valid(_player):
        return
    var now := float(_director.elapsed_time)
    var player_position := _player.global_position
    var cull_distance_squared := CULL_DISTANCE * CULL_DISTANCE
    var culled_any := false

    for state: Dictionary in _pool.active_states():
        if str(state.get("archetype", "swarm")) == "boss":
            continue
        var entity_id := int(state.get("id", -1))
        if entity_id < 0:
            continue
        if not _enemy_spawned_at.has(entity_id):
            _enemy_spawned_at[entity_id] = now
        var enemy_position: Vector2 = state.get("position", player_position)
        var cull_reason := ""
        if enemy_position.distance_squared_to(player_position) > cull_distance_squared:
            cull_reason = "distance"
        elif now - float(_enemy_spawned_at.get(entity_id, now)) > MAX_REGULAR_LIFETIME_SECONDS:
            cull_reason = "lifetime"
        if cull_reason.is_empty() or not _pool.release(entity_id):
            continue

        _enemy_phases.erase(entity_id)
        _cross_phase_attack_cooldowns.erase(entity_id)
        _w23_visual_by_entity.erase(entity_id)
        _enemy_spawned_at.erase(entity_id)
        if cull_reason == "distance":
            _distance_culls += 1
        else:
            _lifetime_culls += 1
        culled_any = true

    if culled_any:
        queue_redraw()


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
        if visual_id.is_empty():
            continue
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
