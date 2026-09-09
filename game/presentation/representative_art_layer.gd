extends Node2D

const Catalog = preload("res://game/presentation/art_catalog.gd")
const PLAYER_SIZE := Vector2(76.0, 92.0)
const ARK_SIZE := Vector2(176.0, 110.0)
const BOSS_SIZE := Vector2(126.0, 145.0)
const BURST_LIFETIME: float = 0.46

var low_vfx_mode: bool = false
var _elapsed: float = 0.0
var _textures: Dictionary = {}
var _player: Node2D
var _encounter: Node2D
var _ark: Node2D
var _circuit: Node2D
var _phase: Node2D
var _bursts: Array[Dictionary] = []


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    _cache_textures()
    call_deferred("_bind_runtime")
    queue_redraw()


func _process(delta: float) -> void:
    _elapsed += maxf(0.0, delta)
    if not _runtime_bound():
        _bind_runtime()
    for index in range(_bursts.size() - 1, -1, -1):
        var burst: Dictionary = _bursts[index]
        burst["age"] = float(burst.get("age", 0.0)) + maxf(0.0, delta)
        if float(burst["age"]) >= BURST_LIFETIME:
            _bursts.remove_at(index)
        else:
            _bursts[index] = burst
    queue_redraw()


func set_low_vfx_mode(enabled: bool) -> void:
    low_vfx_mode = enabled
    queue_redraw()


func _cache_textures() -> void:
    _textures.clear()
    for asset_id in Catalog.all_asset_ids():
        var resource_path := Catalog.path_for(asset_id)
        var resource := load(resource_path)
        if resource is Texture2D:
            _textures[asset_id] = resource


func _bind_runtime() -> void:
    var host := get_parent()
    if host == null:
        return
    _player = host.get("combat_preview") as Node2D
    _encounter = host.get("encounter_preview") as Node2D
    _ark = host.get("ark_preview") as Node2D
    _circuit = host.get("circuit_preview") as Node2D
    _phase = host.get("phase_preview") as Node2D
    if is_instance_valid(_player):
        var weapon_callback := Callable(self, "_on_weapon_action")
        if _player.has_signal("weapon_action") and not _player.is_connected("weapon_action", weapon_callback):
            _player.connect("weapon_action", weapon_callback)
    if is_instance_valid(_phase):
        var phase_callback := Callable(self, "_on_phase_changed")
        if _phase.has_signal("phase_changed") and not _phase.is_connected("phase_changed", phase_callback):
            _phase.connect("phase_changed", phase_callback)


func _runtime_bound() -> bool:
    return is_instance_valid(_player) and is_instance_valid(_encounter) and is_instance_valid(_ark)


func _is_expedition() -> bool:
    var host := get_parent()
    return host != null and str(host.get("shell_mode")) == "EXPEDITION"


func _draw() -> void:
    if not _is_expedition() or not _runtime_bound():
        return
    _draw_circuits()
    _draw_ark()
    _draw_enemies()
    _draw_player()
    _draw_weapon_bursts()
    _draw_danger_telegraphs()


func _draw_player() -> void:
    var model := _player.get("model")
    var health := 100.0
    if model != null:
        health = float(model.get("health"))
    var center := _player.global_position + Vector2(0.0, sin(_elapsed * 2.6) * 2.2)
    draw_circle(center + Vector2(0.0, 25.0), 23.0, Color(0.055, 0.075, 0.11, 0.94))
    var slot := 0
    var host := get_parent()
    var campaign = host.get("campaign") if host != null else null
    if campaign != null:
        var raw_slot: Variant = campaign.get("active_slot")
        if raw_slot != null:
            slot = int(raw_slot)
    var texture_id := Catalog.player_id_for_slot(slot)
    _draw_texture_centered(_textures.get(texture_id), center, PLAYER_SIZE, sin(_elapsed * 1.7) * 0.012)
    var ratio := clampf(health / 100.0, 0.0, 1.0)
    draw_arc(center, 29.0, -PI * 0.5, -PI * 0.5 + TAU * ratio, 36, Color(1.0, 0.86, 0.54, 0.95), 3.0, true)


func _draw_ark() -> void:
    var center := _ark.global_position + Vector2(0.0, sin(_elapsed * 1.35) * 1.3)
    draw_rect(Rect2(center - Vector2(62.0, 35.0), Vector2(124.0, 70.0)), Color(0.045, 0.065, 0.095, 0.96), true)
    var pulse := 1.0 + sin(_elapsed * 2.1) * 0.018
    _draw_texture_centered(_textures.get("ark_lantern_bastion"), center, ARK_SIZE * pulse)
    if _ark.has_method("state_snapshot"):
        var state: Dictionary = _ark.call("state_snapshot")
        var durability := clampf(float(state.get("durability", 0.0)) / 240.0, 0.0, 1.0)
        draw_rect(Rect2(center + Vector2(-56.0, -48.0), Vector2(112.0, 5.0)), Color(0.07, 0.09, 0.13, 0.90), true)
        draw_rect(Rect2(center + Vector2(-56.0, -48.0), Vector2(112.0 * durability, 5.0)), Color(0.98, 0.66, 0.30, 0.96), true)


func _enemy_states() -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    if not is_instance_valid(_encounter):
        return result
    var pool = _encounter.get("_pool")
    if pool == null or not pool.has_method("active_states"):
        return result
    var raw: Variant = pool.call("active_states")
    if not raw is Array:
        return result
    for value in raw:
        if value is Dictionary and bool(value.get("active", false)):
            result.append((value as Dictionary).duplicate(true))
    return result


func _draw_enemies() -> void:
    for state in _enemy_states():
        var entity_id := int(state.get("id", -1))
        var archetype := str(state.get("archetype", "swarm"))
        var center: Vector2 = state.get("position", Vector2.ZERO)
        var phase_id := "material"
        if _encounter.has_method("enemy_phase_for_id"):
            phase_id = str(_encounter.call("enemy_phase_for_id", entity_id))
        var hostile_visible := true
        if is_instance_valid(_phase) and _phase.has_method("is_enemy_targetable"):
            hostile_visible = bool(_phase.call("is_enemy_targetable", phase_id))
        if not hostile_visible:
            continue
        var is_boss := archetype == "boss"
        var texture_id := Catalog.enemy_visual_id(archetype, entity_id)
        var base_radius := float(state.get("radius", 13.0))
        var size := BOSS_SIZE if is_boss else Vector2.ONE * maxf(48.0, base_radius * 3.4)
        var sway := sin(_elapsed * (1.5 if is_boss else 2.3) + float(entity_id % 17)) * (0.018 if is_boss else 0.045)
        draw_circle(center, maxf(17.0, base_radius * 1.25), Color(0.045, 0.06, 0.09, 0.96))
        var modulate := Color.WHITE if phase_id == "material" else Color(0.84, 0.76, 1.0, 0.95)
        _draw_texture_centered(_textures.get(texture_id), center, size, sway, modulate)
        var health := float(state.get("health", 0.0))
        var max_health := maxf(1.0, float(state.get("max_health", 1.0)))
        var width := 84.0 if is_boss else 38.0
        var y := center.y - size.y * 0.48
        draw_rect(Rect2(Vector2(center.x - width * 0.5, y), Vector2(width, 4.0)), Color(0.08, 0.09, 0.13, 0.92), true)
        draw_rect(Rect2(Vector2(center.x - width * 0.5, y), Vector2(width * clampf(health / max_health, 0.0, 1.0), 4.0)), Color(0.88, 0.48, 0.48, 0.96), true)


func _draw_circuits() -> void:
    if not is_instance_valid(_circuit) or not _circuit.has_method("active_circuits"):
        return
    var raw: Variant = _circuit.call("active_circuits")
    if not raw is Array:
        return
    for value in raw:
        if not value is Dictionary:
            continue
        var circuit: Dictionary = value
        var polygon: PackedVector2Array = circuit.get("polygon", PackedVector2Array())
        if polygon.size() < 3:
            continue
        var phase_id := str(circuit.get("phase", "material"))
        var fill := Color(0.94, 0.62, 0.27, 0.10) if phase_id == "material" else Color(0.58, 0.43, 0.96, 0.10)
        var line := Color(1.0, 0.77, 0.38, 0.78) if phase_id == "material" else Color(0.76, 0.62, 1.0, 0.80)
        draw_colored_polygon(polygon, fill)
        var closed := PackedVector2Array(polygon)
        closed.append(polygon[0])
        draw_polyline(closed, line, 3.0, true)


func _draw_danger_telegraphs() -> void:
    if not is_instance_valid(_encounter):
        return
    var regular: Variant = _encounter.get("_telegraphs")
    if regular is Array:
        for value in regular:
            if not value is Dictionary:
                continue
            var warning: Dictionary = value
            var duration := maxf(0.001, float(warning.get("duration", 1.0)))
            var remaining := clampf(float(warning.get("remaining", 0.0)) / duration, 0.0, 1.0)
            var radius := float(warning.get("radius", 30.0))
            var center: Vector2 = warning.get("position", Vector2.ZERO)
            draw_circle(center, radius, Color(0.95, 0.33, 0.19, 0.08))
            draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - remaining), 48, Color(1.0, 0.72, 0.30, 0.98), 5.0, true)
    if _encounter.has_method("cross_phase_warning_snapshot"):
        var cross: Variant = _encounter.call("cross_phase_warning_snapshot")
        if cross is Array:
            for value in cross:
                if not value is Dictionary:
                    continue
                var warning: Dictionary = value
                var duration := maxf(0.001, float(warning.get("duration", 0.8)))
                var remaining := clampf(float(warning.get("remaining", 0.0)) / duration, 0.0, 1.0)
                var radius := float(warning.get("radius", 54.0))
                var center: Vector2 = warning.get("position", Vector2.ZERO)
                draw_circle(center, radius, Color(0.52, 0.28, 0.84, 0.11))
                draw_arc(center, radius, -PI * 0.5, -PI * 0.5 + TAU * (1.0 - remaining), 48, Color(0.89, 0.68, 1.0, 0.98), 5.0, true)


func _on_weapon_action(action: Dictionary) -> void:
    var target_id := int(action.get("target_id", -1))
    if target_id < 0:
        return
    for state in _enemy_states():
        if int(state.get("id", -1)) != target_id:
            continue
        _bursts.append({"position": state.get("position", Vector2.ZERO), "age": 0.0, "kind": "impact"})
        break


func _on_phase_changed(_phase_id: String, _threat_count: int) -> void:
    if is_instance_valid(_player):
        _bursts.append({"position": _player.global_position, "age": 0.0, "kind": "phase"})


func _draw_weapon_bursts() -> void:
    if low_vfx_mode:
        return
    var texture: Texture2D = _textures.get("vfx_phase_burst")
    if texture == null:
        return
    for burst in _bursts:
        var progress := clampf(float(burst.get("age", 0.0)) / BURST_LIFETIME, 0.0, 1.0)
        var size := Vector2.ONE * lerpf(42.0, 112.0, progress)
        var alpha := 1.0 - progress
        _draw_texture_centered(texture, burst.get("position", Vector2.ZERO), size, progress * 0.55, Color(1.0, 1.0, 1.0, alpha))


func _draw_texture_centered(texture: Variant, center: Vector2, size: Vector2, rotation: float = 0.0, modulate: Color = Color.WHITE) -> void:
    if not texture is Texture2D:
        return
    draw_set_transform(center, rotation, Vector2.ONE)
    draw_texture_rect(texture, Rect2(-size * 0.5, size), false, modulate)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
