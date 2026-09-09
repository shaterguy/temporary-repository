extends Node2D

const LightCircuitModelScript = preload("res://game/systems/circuit/light_circuit_model.gd")

signal circuit_activated(circuit_id: int, module_id: String, light_remaining: float)
signal circuit_expired(circuit_id: int)
signal circuit_rejected(reason: String)

var model = LightCircuitModelScript.new()
var _player: Node2D
var _ark: Node2D


func configure(player: Node2D, ark: Node2D) -> void:
    _player = player
    _ark = ark
    if is_instance_valid(_ark) and _ark.has_method("set_circuit_provider"):
        _ark.call("set_circuit_provider", model)
    queue_redraw()


func select_module(module_id: String) -> bool:
    var selected := model.select_module(module_id)
    if selected:
        queue_redraw()
    return selected


func set_world_phase(phase_id: String) -> bool:
    var changed := model.set_world_phase(phase_id)
    if changed:
        queue_redraw()
    return changed


func effect_provider() -> Object:
    return model


func state_snapshot() -> Dictionary:
    return model.snapshot()


func restore_state(snapshot_state: Dictionary) -> bool:
    var restored := model.restore_snapshot(snapshot_state)
    if restored:
        queue_redraw()
    return restored


func status_snapshot() -> Dictionary:
    return {
        "light": model.current_light,
        "active_count": model.active_circuit_count(),
        "cooldown_remaining": model.cooldown_remaining,
        "module": model.current_module,
        "phase": model.world_phase,
    }


func _physics_process(delta: float) -> void:
    if delta <= 0.0 or not is_instance_valid(_player):
        return
    var events := model.step(delta, _player.global_position, false)
    for event in events:
        var event_type := str(event.get("type", ""))
        if event_type == "circuit_activated":
            circuit_activated.emit(
                int(event.get("circuit_id", 0)),
                str(event.get("module", "")),
                float(event.get("light", model.current_light))
            )
        elif event_type == "circuit_expired":
            circuit_expired.emit(int(event.get("circuit_id", 0)))
        elif event_type == "circuit_rejected":
            circuit_rejected.emit(str(event.get("reason", "unknown")))
    queue_redraw()


func _draw() -> void:
    var trail := model.trail_points()
    if trail.size() >= 2:
        draw_polyline(_to_local_points(trail), Color(1.0, 0.84, 0.34, 0.82), 3.0, true)

    for circuit in model.active_circuits():
        var polygon: PackedVector2Array = circuit.get("polygon", PackedVector2Array())
        if polygon.size() < 3:
            continue
        var module_id := str(circuit.get("module", ""))
        var local_polygon := _to_local_points(polygon)
        var fill := Color(0.95, 0.66, 0.22, 0.13)
        var edge := Color(1.0, 0.82, 0.34, 0.88)
        if module_id == LightCircuitModelScript.MODULE_SNARE:
            fill = Color(0.24, 0.62, 0.88, 0.13)
            edge = Color(0.46, 0.82, 1.0, 0.90)
        elif module_id == LightCircuitModelScript.MODULE_ECHO_BEACON:
            fill = Color(0.70, 0.42, 0.92, 0.13)
            edge = Color(0.86, 0.65, 1.0, 0.90)
        draw_colored_polygon(local_polygon, fill)
        var outline := PackedVector2Array()
        for point in local_polygon:
            outline.append(point)
        outline.append(local_polygon[0])
        draw_polyline(outline, edge, 3.0, true)


func _to_local_points(world_points: PackedVector2Array) -> PackedVector2Array:
    var local_points := PackedVector2Array()
    for point in world_points:
        local_points.append(to_local(point))
    return local_points
