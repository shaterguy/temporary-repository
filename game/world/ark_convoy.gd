extends Node2D

const ArkRouteModelScript = preload("res://game/world/ark_route_model.gd")

signal route_state_changed(status: String, route_id: String)

var model = ArkRouteModelScript.new()
var _origin_position: Vector2 = Vector2.ZERO
var _circuit_provider: Object


func _ready() -> void:
    _origin_position = position
    queue_redraw()


func configure_seed(seed: int) -> void:
    model.reset(seed)
    position = _origin_position
    queue_redraw()
    route_state_changed.emit(model.status, model.selected_route_id)


func configure_expedition(seed: int, route_id: String) -> bool:
    configure_seed(seed)
    return choose_route(route_id)


func set_circuit_provider(provider: Object) -> void:
    _circuit_provider = provider


func choose_route(route_id: String) -> bool:
    var changed := model.choose_route(ArkRouteModelScript.JUNCTION_ID, route_id)
    if changed:
        position = _origin_position + model.position
        queue_redraw()
        route_state_changed.emit(model.status, model.selected_route_id)
    return changed


func resume_after_rest() -> bool:
    var resumed := model.resume_after_rest()
    if resumed:
        position = _origin_position + model.position
        queue_redraw()
        route_state_changed.emit(model.status, model.selected_route_id)
    return resumed


func route_preview(route_id: String) -> Dictionary:
    return model.route_preview(route_id)


func route_combat_context() -> Dictionary:
    return model.route_combat_context()


func objective_global_position() -> Vector2:
    return global_position + model.objective_offset()


func objective_radius() -> float:
    return 24.0 if str(model.route_combat_context().get("defend_target", "ark_core")) == "supply_pod" else 34.0


func is_objective_visible() -> bool:
    var viewport := get_viewport()
    if viewport == null:
        return false
    var viewport_position := get_viewport_transform() * objective_global_position()
    return viewport.get_visible_rect().has_point(viewport_position)


func apply_objective_damage(raw_damage: int, warning_visible: bool = true) -> bool:
    var adjusted_damage := _circuit_adjusted_damage(objective_global_position(), raw_damage)
    var applied := model.apply_objective_damage(adjusted_damage, warning_visible)
    if applied:
        queue_redraw()
        route_state_changed.emit(model.status, model.selected_route_id)
    return applied


func apply_ark_damage(raw_damage: int, warning_visible: bool = true) -> bool:
    var adjusted_damage := _circuit_adjusted_damage(global_position, raw_damage)
    var applied := model.apply_ark_damage(adjusted_damage, warning_visible)
    if applied:
        queue_redraw()
        route_state_changed.emit(model.status, model.selected_route_id)
    return applied


func recover_from_failure() -> bool:
    var recovered := model.recover_from_failure()
    if recovered:
        queue_redraw()
        route_state_changed.emit(model.status, model.selected_route_id)
    return recovered


func state_snapshot() -> Dictionary:
    return model.snapshot()


func restore_state(snapshot_state: Dictionary) -> bool:
    if not model.restore_snapshot(snapshot_state):
        return false
    position = _origin_position + model.position
    queue_redraw()
    return true


func _circuit_adjusted_damage(world_position: Vector2, raw_damage: int) -> int:
    if raw_damage <= 0:
        return raw_damage
    if is_instance_valid(_circuit_provider) and _circuit_provider.has_method("mitigate_damage_at"):
        return maxi(0, int(_circuit_provider.call("mitigate_damage_at", world_position, raw_damage)))
    return raw_damage


func _physics_process(delta: float) -> void:
    var events := model.step(delta)
    position = _origin_position + model.position
    if not events.is_empty():
        route_state_changed.emit(model.status, model.selected_route_id)
    queue_redraw()


func _draw() -> void:
    var hull_color := Color(0.92, 0.58, 0.22, 0.98)
    if model.status == ArkRouteModelScript.STATUS_FAILED_RECOVERABLE:
        hull_color = Color(0.72, 0.22, 0.18, 0.98)
    draw_rect(Rect2(Vector2(-42.0, -22.0), Vector2(84.0, 44.0)), hull_color, true)
    draw_circle(Vector2.ZERO, 15.0, Color(1.0, 0.88, 0.45, 0.96))
    draw_arc(Vector2.ZERO, 48.0, 0.0, TAU, 48, Color(1.0, 0.72, 0.28, 0.42), 3.0, true)

    var durability_ratio := float(model.durability) / float(ArkRouteModelScript.MAX_DURABILITY)
    draw_rect(Rect2(Vector2(-44.0, -34.0), Vector2(88.0, 5.0)), Color(0.12, 0.13, 0.18, 0.90), true)
    draw_rect(Rect2(Vector2(-44.0, -34.0), Vector2(88.0 * durability_ratio, 5.0)), Color(0.94, 0.68, 0.32, 1.0), true)

    if str(model.route_combat_context().get("defend_target", "ark_core")) == "supply_pod":
        var pod_offset := model.objective_offset()
        var pod_ratio := float(model.supply_pod_integrity) / float(ArkRouteModelScript.MAX_SUPPLY_POD_INTEGRITY)
        draw_rect(Rect2(pod_offset - Vector2(18.0, 13.0), Vector2(36.0, 26.0)), Color(0.36, 0.70, 0.72, 0.96), true)
        draw_arc(pod_offset, 23.0, -PI * 0.5, -PI * 0.5 + TAU * pod_ratio, 28, Color(0.72, 0.96, 0.90, 0.95), 2.5, true)
