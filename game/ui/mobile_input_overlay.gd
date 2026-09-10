extends Control

const MobileInputModelScript = preload("res://game/ui/mobile_input_model.gd")
const SafeAreaScript = preload("res://platform/android/safe_area.gd")
const EXPEDITION_MODE: String = "EXPEDITION"

var model = MobileInputModelScript.new()
var _enabled: bool = false
var _last_movement: Vector2 = Vector2.ZERO
var _last_dodge: bool = false
var _last_phase: bool = false

func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process_input(true)
    get_viewport().size_changed.connect(_on_viewport_size_changed)
    _refresh_geometry(false)
    _sync_enabled()

func _process(_delta: float) -> void:
    _sync_enabled()

func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        cancel_all_input()
    elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
        call_deferred("_refresh_geometry", true)

func _input(event: InputEvent) -> void:
    if not _enabled:
        return
    var consumed := false
    if event is InputEventScreenTouch:
        var touch := event as InputEventScreenTouch
        consumed = model.handle_touch(touch.index, touch.position, touch.pressed, touch.canceled)
    elif event is InputEventScreenDrag:
        var drag := event as InputEventScreenDrag
        consumed = model.handle_drag(drag.index, drag.position)
    if not consumed:
        return
    _emit_input_state(false)
    queue_redraw()
    get_viewport().set_input_as_handled()

func configure_accessibility(settings: Dictionary) -> Dictionary:
    var normalized: Dictionary = model.configure_accessibility(settings)
    _emit_input_state(true)
    queue_redraw()
    return normalized

func cancel_all_input() -> void:
    model.cancel_all()
    _emit_input_state(true)
    queue_redraw()

func runtime_snapshot() -> Dictionary:
    var snapshot: Dictionary = model.input_snapshot()
    snapshot["enabled"] = _enabled
    return snapshot

func _sync_enabled() -> void:
    var shell := get_parent()
    var should_enable := shell != null and str(shell.get("shell_mode")) == EXPEDITION_MODE
    if should_enable == _enabled:
        return
    _enabled = should_enable
    if not _enabled:
        model.cancel_all()
        _emit_input_state(true)
    queue_redraw()

func _refresh_geometry(cancel_input: bool = true) -> void:
    if not is_inside_tree():
        return
    var visible_size := get_viewport_rect().size
    var viewport_size := Vector2i(maxi(1, roundi(visible_size.x)), maxi(1, roundi(visible_size.y)))
    var margins := SafeAreaScript.margins_for(get_window().size, viewport_size, DisplayServer.get_display_safe_area())
    if cancel_input:
        model.cancel_all()
    model.configure_viewport(visible_size, Vector4(margins.x, margins.y, margins.z, margins.w))
    _emit_input_state(cancel_input)
    queue_redraw()

func _on_viewport_size_changed() -> void:
    _refresh_geometry(true)

func _emit_input_state(force: bool) -> void:
    var movement := model.movement_vector()
    var dodge := model.dodge_pressed()
    var phase := model.phase_pressed()
    if not force and movement.is_equal_approx(_last_movement) and dodge == _last_dodge and phase == _last_phase:
        return
    var haptic_edge: bool = bool(model.haptics_enabled) and ((dodge and not _last_dodge) or (phase and not _last_phase))
    _last_movement = movement
    _last_dodge = dodge
    _last_phase = phase
    var shell := get_parent()
    if shell != null and shell.has_method("set_transient_input"):
        shell.call("set_transient_input", movement, dodge, phase)
    if haptic_edge and OS.has_feature("mobile"):
        Input.vibrate_handheld(35)

func _draw() -> void:
    if not _enabled:
        return
    var layout := model.layout_snapshot()
    var snapshot := model.input_snapshot()
    var settings := model.settings_snapshot()
    var opacity := float(settings.get("control_opacity", 0.72))
    var stick_center: Vector2 = snapshot.get("stick_origin", layout.get("stick_center", Vector2.ZERO))
    var stick_position: Vector2 = snapshot.get("stick_position", stick_center)
    var stick_radius := float(layout.get("stick_radius", 82.0))
    var button_radius := float(layout.get("button_radius", 54.0))
    var dodge_center: Vector2 = layout.get("dodge_center", Vector2.ZERO)
    var phase_center: Vector2 = layout.get("phase_center", Vector2.ZERO)
    draw_circle(stick_center, stick_radius, Color(0.72, 0.84, 1.0, opacity * 0.18), true, -1.0, true)
    draw_circle(stick_center, stick_radius, Color(0.82, 0.90, 1.0, opacity * 0.72), false, 4.0, true)
    draw_circle(stick_position, stick_radius * 0.36, Color(0.90, 0.95, 1.0, opacity * 0.82), true, -1.0, true)
    var dodge_alpha := opacity * (0.72 if bool(snapshot.get("dodge", false)) else 0.38)
    draw_circle(dodge_center, button_radius, Color(0.98, 0.80, 0.42, dodge_alpha), true, -1.0, true)
    draw_circle(dodge_center, button_radius, Color(1.0, 0.91, 0.66, opacity * 0.86), false, 4.0, true)
    var phase_alpha := opacity * (0.72 if bool(snapshot.get("phase", false)) else 0.38)
    var diamond := PackedVector2Array([phase_center + Vector2(0.0, -button_radius), phase_center + Vector2(button_radius, 0.0), phase_center + Vector2(0.0, button_radius), phase_center + Vector2(-button_radius, 0.0)])
    draw_colored_polygon(diamond, Color(0.67, 0.58, 1.0, phase_alpha))
    var outline := PackedVector2Array([diamond[0], diamond[1], diamond[2], diamond[3], diamond[0]])
    draw_polyline(outline, Color(0.86, 0.82, 1.0, opacity * 0.90), 4.0, true)
