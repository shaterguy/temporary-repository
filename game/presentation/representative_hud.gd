extends Control

const Catalog = preload("res://game/presentation/art_catalog.gd")

var _panel_texture: Texture2D
var _safe_area: Control
var _status_label: Label
var _player: Node2D
var _ark: Node2D
var _circuit: Node2D
var _phase: Node2D


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    process_mode = Node.PROCESS_MODE_ALWAYS
    var loaded := load(Catalog.path_for("hud_lantern_panel"))
    if loaded is Texture2D:
        _panel_texture = loaded
    call_deferred("_bind_runtime")
    queue_redraw()


func _exit_tree() -> void:
    if is_instance_valid(_safe_area):
        _safe_area.visible = true


func _process(_delta: float) -> void:
    if not _runtime_bound():
        _bind_runtime()
    var expedition := _is_expedition()
    if is_instance_valid(_safe_area):
        _safe_area.visible = not expedition
    queue_redraw()


func _bind_runtime() -> void:
    var host := get_parent()
    if host == null:
        return
    _safe_area = host.get_node_or_null("SafeArea") as Control
    if is_instance_valid(_safe_area):
        _status_label = _safe_area.get_node_or_null("Content/Status") as Label
    _player = host.get("combat_preview") as Node2D
    _ark = host.get("ark_preview") as Node2D
    _circuit = host.get("circuit_preview") as Node2D
    _phase = host.get("phase_preview") as Node2D


func _runtime_bound() -> bool:
    return is_instance_valid(_player) and is_instance_valid(_ark)


func _is_expedition() -> bool:
    var host := get_parent()
    return host != null and str(host.get("shell_mode")) == "EXPEDITION"


static func layout_for(viewport_size: Vector2) -> Dictionary:
    var pad := maxf(18.0, minf(viewport_size.x, viewport_size.y) * 0.025)
    var weapon_width := minf(600.0, viewport_size.x - pad * 2.0)
    var notice_width := minf(720.0, viewport_size.x - pad * 2.0)
    return {
        "player": Rect2(Vector2(pad, pad), Vector2(250.0, 76.0)),
        "ark": Rect2(Vector2(viewport_size.x * 0.5 - 176.0, pad), Vector2(352.0, 76.0)),
        "pause": Rect2(Vector2(viewport_size.x - pad - 92.0, pad), Vector2(92.0, 76.0)),
        "weapon": Rect2(Vector2(viewport_size.x * 0.5 - weapon_width * 0.5, viewport_size.y - pad - 90.0), Vector2(weapon_width, 90.0)),
        "notice": Rect2(Vector2(viewport_size.x * 0.5 - notice_width * 0.5, viewport_size.y - pad - 154.0), Vector2(notice_width, 56.0)),
    }


func _draw() -> void:
    if not _is_expedition() or not _runtime_bound():
        return
    var layout := layout_for(get_viewport_rect().size)
    _draw_panel(layout["player"], "SURVIVOR", _player_line(), Color(0.96, 0.70, 0.34, 1.0))
    _draw_panel(layout["ark"], "LANTERN ARK", _ark_line(), Color(0.96, 0.62, 0.28, 1.0))
    _draw_panel(layout["pause"], "PAUSE", "II", Color(0.63, 0.78, 0.90, 1.0))
    _draw_panel(layout["weapon"], "CAUSAL LOADOUT", _combat_line(), Color(0.57, 0.77, 0.92, 1.0))
    if is_instance_valid(_status_label):
        var field_log := _status_label.text
        if field_log.length() > 84:
            field_log = field_log.substr(0, 83) + "…"
        _draw_panel(layout["notice"], "FIELD LOG", field_log, Color(0.72, 0.62, 0.96, 1.0), 13)


func _player_line() -> String:
    var health := 0
    var paused := false
    var model: Variant = _player.get("model")
    if model != null:
        health = int(model.get("health"))
        paused = bool(model.get("paused"))
    return "HP %03d   %s" % [health, "PAUSED" if paused else "ACTIVE"]


func _ark_line() -> String:
    if not _ark.has_method("state_snapshot"):
        return "ARK TELEMETRY LINKING"
    var state: Dictionary = _ark.call("state_snapshot")
    return "HULL %03d   ROUTE %s   %s" % [
        int(state.get("durability", 0)),
        str(state.get("selected_route_id", "UNSET")).to_upper(),
        str(state.get("status", "READY")).to_upper(),
    ]


func _combat_line() -> String:
    var weapon := "UNARMED"
    if _player.has_method("weapon_status_snapshot"):
        var weapon_state: Dictionary = _player.call("weapon_status_snapshot")
        weapon = str(weapon_state.get("weapon_id", "unarmed")).to_upper()
    var module_id := "NONE"
    var light := 0
    if is_instance_valid(_circuit) and _circuit.has_method("status_snapshot"):
        var circuit_state: Dictionary = _circuit.call("status_snapshot")
        module_id = str(circuit_state.get("selected_module", "none")).to_upper()
        light = roundi(float(circuit_state.get("light", 0.0)))
    var phase_id := "MATERIAL"
    if is_instance_valid(_phase) and _phase.has_method("current_phase_id"):
        phase_id = str(_phase.call("current_phase_id")).to_upper()
    return "%s   CIRCUIT %s/%03d   PHASE %s" % [weapon, module_id, light, phase_id]


func _draw_panel(rect: Rect2, title: String, line: String, accent: Color, line_size: int = 16) -> void:
    if _panel_texture != null:
        draw_texture_rect(_panel_texture, rect, false, Color(1.0, 1.0, 1.0, 0.96))
    else:
        draw_rect(rect, Color(0.04, 0.07, 0.11, 0.92), true)
        draw_rect(rect, Color(0.32, 0.39, 0.48, 0.95), false, 2.0)
    draw_rect(Rect2(rect.position + Vector2(12.0, 13.0), Vector2(5.0, rect.size.y - 26.0)), accent, true)
    var font := ThemeDB.fallback_font
    draw_string(font, rect.position + Vector2(28.0, 27.0), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 42.0, 13, Color(0.75, 0.82, 0.90, 1.0))
    draw_string(font, rect.position + Vector2(28.0, rect.size.y - 20.0), line, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 42.0, line_size, Color(0.96, 0.93, 0.86, 1.0))
