class_name MobileInputModel
extends RefCounted

const STICK_FIXED: String = "fixed"
const STICK_FLOATING: String = "floating"
const DEFAULT_VIEWPORT: Vector2 = Vector2(1280.0, 720.0)
const BASE_STICK_RADIUS: float = 82.0
const BASE_BUTTON_RADIUS: float = 54.0
const BASE_EDGE_PADDING: float = 26.0
const BASE_BUTTON_GAP: float = 24.0
const DEAD_ZONE: float = 0.12
const MIN_CONTROL_SCALE: float = 0.80
const MAX_CONTROL_SCALE: float = 1.40
const MIN_CONTROL_OPACITY: float = 0.35
const MAX_CONTROL_OPACITY: float = 1.00

var left_handed: bool = false
var stick_mode: String = STICK_FIXED
var control_scale: float = 1.0
var control_opacity: float = 0.72
var haptics_enabled: bool = true
var reduced_flash: bool = false
var reduced_motion: bool = false

var _viewport_size: Vector2 = DEFAULT_VIEWPORT
var _safe_margins: Vector4 = Vector4.ZERO
var _stick_pointer_id: int = -1
var _stick_origin: Vector2 = Vector2.ZERO
var _stick_position: Vector2 = Vector2.ZERO
var _dodge_pointers: Dictionary = {}
var _phase_pointers: Dictionary = {}
var _generation: int = 0

func configure_viewport(viewport_size: Vector2, safe_margins: Vector4 = Vector4.ZERO) -> void:
    _viewport_size = Vector2(maxf(1.0, viewport_size.x), maxf(1.0, viewport_size.y))
    _safe_margins = Vector4(maxf(0.0, safe_margins.x), maxf(0.0, safe_margins.y), maxf(0.0, safe_margins.z), maxf(0.0, safe_margins.w))
    if _stick_pointer_id < 0:
        _reset_idle_stick()
    elif stick_mode == STICK_FIXED:
        _stick_origin = _fixed_stick_center()
        _stick_position = _clamp_to_stick(_stick_position)

func configure_accessibility(settings: Dictionary) -> Dictionary:
    var previous := settings_snapshot()
    left_handed = bool(settings.get("left_handed", left_handed))
    var requested_mode := str(settings.get("stick_mode", stick_mode))
    if requested_mode == STICK_FIXED or requested_mode == STICK_FLOATING:
        stick_mode = requested_mode
    control_scale = clampf(float(settings.get("control_scale", control_scale)), MIN_CONTROL_SCALE, MAX_CONTROL_SCALE)
    control_opacity = clampf(float(settings.get("control_opacity", control_opacity)), MIN_CONTROL_OPACITY, MAX_CONTROL_OPACITY)
    haptics_enabled = bool(settings.get("haptics_enabled", haptics_enabled))
    reduced_flash = bool(settings.get("reduced_flash", reduced_flash))
    reduced_motion = bool(settings.get("reduced_motion", reduced_motion))
    if previous != settings_snapshot():
        cancel_all()
        _reset_idle_stick()
    return settings_snapshot()

func settings_snapshot() -> Dictionary:
    return {"left_handed": left_handed, "stick_mode": stick_mode, "control_scale": control_scale, "control_opacity": control_opacity, "haptics_enabled": haptics_enabled, "reduced_flash": reduced_flash, "reduced_motion": reduced_motion}

func layout_snapshot() -> Dictionary:
    var safe_rect := _safe_rect()
    var safe_end := safe_rect.position + safe_rect.size
    var midpoint_x := safe_rect.position.x + safe_rect.size.x * 0.5
    var stick_radius := BASE_STICK_RADIUS * control_scale
    var button_radius := BASE_BUTTON_RADIUS * control_scale
    var edge_padding := BASE_EDGE_PADDING * control_scale
    var button_gap := BASE_BUTTON_GAP * control_scale
    var stick_x := safe_rect.position.x + edge_padding + stick_radius
    var action_x := safe_end.x - edge_padding - button_radius
    if left_handed:
        stick_x = safe_end.x - edge_padding - stick_radius
        action_x = safe_rect.position.x + edge_padding + button_radius
    var bottom_y := safe_end.y - edge_padding
    var stick_center := Vector2(stick_x, bottom_y - stick_radius)
    var dodge_center := Vector2(action_x, bottom_y - button_radius)
    var phase_center := Vector2(action_x, dodge_center.y - button_radius * 2.0 - button_gap)
    var movement_rect: Rect2
    if left_handed:
        movement_rect = Rect2(Vector2(midpoint_x, safe_rect.position.y), Vector2(maxf(1.0, safe_end.x - midpoint_x), safe_rect.size.y))
    else:
        movement_rect = Rect2(safe_rect.position, Vector2(maxf(1.0, midpoint_x - safe_rect.position.x), safe_rect.size.y))
    return {"safe_rect": safe_rect, "movement_rect": movement_rect, "stick_center": stick_center, "dodge_center": dodge_center, "phase_center": phase_center, "stick_radius": stick_radius, "button_radius": button_radius}

func handle_touch(pointer_id: int, position: Vector2, pressed: bool, cancelled: bool = false) -> bool:
    if pointer_id < 0:
        return false
    if cancelled or not pressed:
        return release_pointer(pointer_id)
    if _pointer_owned(pointer_id):
        return true
    var layout := layout_snapshot()
    var button_radius := float(layout.get("button_radius", BASE_BUTTON_RADIUS))
    if _point_in_circle(position, layout.get("dodge_center", Vector2.ZERO), button_radius * 1.15):
        _dodge_pointers[pointer_id] = true
        _generation += 1
        return true
    if _point_in_circle(position, layout.get("phase_center", Vector2.ZERO), button_radius * 1.15):
        _phase_pointers[pointer_id] = true
        _generation += 1
        return true
    if _stick_pointer_id >= 0 or not _movement_accepts(position, layout):
        return false
    _stick_pointer_id = pointer_id
    _stick_origin = _clamp_floating_origin(position, layout) if stick_mode == STICK_FLOATING else layout.get("stick_center", Vector2.ZERO)
    _stick_position = _stick_origin
    _update_stick(position)
    _generation += 1
    return true

func handle_drag(pointer_id: int, position: Vector2) -> bool:
    if pointer_id == _stick_pointer_id:
        _update_stick(position)
        return true
    return _dodge_pointers.has(pointer_id) or _phase_pointers.has(pointer_id)

func release_pointer(pointer_id: int) -> bool:
    var consumed := false
    if pointer_id == _stick_pointer_id:
        _stick_pointer_id = -1
        _reset_idle_stick()
        consumed = true
    if _dodge_pointers.has(pointer_id):
        _dodge_pointers.erase(pointer_id)
        consumed = true
    if _phase_pointers.has(pointer_id):
        _phase_pointers.erase(pointer_id)
        consumed = true
    if consumed:
        _generation += 1
    return consumed

func cancel_all() -> void:
    _stick_pointer_id = -1
    _dodge_pointers.clear()
    _phase_pointers.clear()
    _reset_idle_stick()
    _generation += 1

func movement_vector() -> Vector2:
    if _stick_pointer_id < 0:
        return Vector2.ZERO
    var radius := maxf(1.0, BASE_STICK_RADIUS * control_scale)
    var raw := (_stick_position - _stick_origin) / radius
    var raw_length := raw.length()
    if raw_length <= DEAD_ZONE:
        return Vector2.ZERO
    var strength := clampf((raw_length - DEAD_ZONE) / (1.0 - DEAD_ZONE), 0.0, 1.0)
    return raw.normalized() * strength

func dodge_pressed() -> bool:
    return not _dodge_pointers.is_empty()

func phase_pressed() -> bool:
    return not _phase_pointers.is_empty()

func generation() -> int:
    return _generation

func input_snapshot() -> Dictionary:
    return {"movement": movement_vector(), "dodge": dodge_pressed(), "phase": phase_pressed(), "stick_pointer_id": _stick_pointer_id, "stick_origin": _stick_origin, "stick_position": _stick_position, "generation": _generation, "settings": settings_snapshot(), "layout": layout_snapshot()}

func _movement_accepts(position: Vector2, layout: Dictionary) -> bool:
    var movement_rect: Rect2 = layout.get("movement_rect", Rect2())
    if not movement_rect.has_point(position):
        return false
    if stick_mode == STICK_FLOATING:
        return true
    var center: Vector2 = layout.get("stick_center", Vector2.ZERO)
    var radius := float(layout.get("stick_radius", BASE_STICK_RADIUS)) * 1.55
    return _point_in_circle(position, center, radius)

func _clamp_floating_origin(position: Vector2, layout: Dictionary) -> Vector2:
    var movement_rect: Rect2 = layout.get("movement_rect", Rect2(Vector2.ZERO, _viewport_size))
    var rect_end := movement_rect.position + movement_rect.size
    var radius := float(layout.get("stick_radius", BASE_STICK_RADIUS))
    var min_x := movement_rect.position.x + radius
    var max_x := rect_end.x - radius
    var min_y := movement_rect.position.y + radius
    var max_y := rect_end.y - radius
    if min_x > max_x:
        min_x = movement_rect.position.x + movement_rect.size.x * 0.5
        max_x = min_x
    if min_y > max_y:
        min_y = movement_rect.position.y + movement_rect.size.y * 0.5
        max_y = min_y
    return Vector2(clampf(position.x, min_x, max_x), clampf(position.y, min_y, max_y))

func _update_stick(position: Vector2) -> void:
    _stick_position = _stick_origin + (position - _stick_origin).limit_length(BASE_STICK_RADIUS * control_scale)

func _clamp_to_stick(position: Vector2) -> Vector2:
    return _stick_origin + (position - _stick_origin).limit_length(BASE_STICK_RADIUS * control_scale)

func _reset_idle_stick() -> void:
    _stick_origin = _fixed_stick_center()
    _stick_position = _stick_origin

func _fixed_stick_center() -> Vector2:
    return layout_snapshot().get("stick_center", Vector2.ZERO)

func _safe_rect() -> Rect2:
    var left := clampf(_safe_margins.x, 0.0, _viewport_size.x)
    var top := clampf(_safe_margins.y, 0.0, _viewport_size.y)
    var right := clampf(_safe_margins.z, 0.0, _viewport_size.x - left)
    var bottom := clampf(_safe_margins.w, 0.0, _viewport_size.y - top)
    return Rect2(Vector2(left, top), Vector2(maxf(1.0, _viewport_size.x - left - right), maxf(1.0, _viewport_size.y - top - bottom)))

func _pointer_owned(pointer_id: int) -> bool:
    return pointer_id == _stick_pointer_id or _dodge_pointers.has(pointer_id) or _phase_pointers.has(pointer_id)

func _point_in_circle(point: Vector2, center: Vector2, radius: float) -> bool:
    return point.distance_squared_to(center) <= radius * radius
