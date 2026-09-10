extends Control

const Catalog = preload("res://game/presentation/art_catalog.gd")
const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")

var _panel_texture: Texture2D
var _safe_area: Control
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
    var combat_width := minf(330.0, viewport_size.x * 0.26)
    var notice_width := minf(520.0, viewport_size.x * 0.40)
    var second_row_y := pad + 92.0
    return {
        "player": Rect2(Vector2(pad, pad), Vector2(250.0, 76.0)),
        "ark": Rect2(Vector2(viewport_size.x * 0.5 - 176.0, pad), Vector2(352.0, 76.0)),
        "pause": Rect2(Vector2(viewport_size.x - pad - 92.0, pad), Vector2(92.0, 76.0)),
        "weapon": Rect2(Vector2(pad, second_row_y), Vector2(combat_width, 82.0)),
        "notice": Rect2(Vector2(viewport_size.x * 0.5 - notice_width * 0.5, second_row_y), Vector2(notice_width, 54.0)),
    }


static func localize_route_id(route_id: String) -> String:
    match route_id:
        "supply_causeway":
            return "보급 둑길"
        "risk_channel":
            return "위험 수로"
        "":
            return "항로 선택 전"
        _:
            return "선택 항로"


static func localize_route_status(status_id: String) -> String:
    match status_id:
        "AWAITING_ROUTE":
            return "항로 선택 대기"
        "TRAVELING":
            return "항해 중"
        "RESTING":
            return "휴식 지점"
        "ARRIVED":
            return "도착"
        "FAILED_RECOVERABLE":
            return "복구 필요"
        _:
            return "진행 중"


static func localize_module_id(module_id: String) -> String:
    match module_id:
        "ark_ward":
            return "방주 방벽"
        "snare":
            return "구속 회로"
        "echo_beacon":
            return "잔향 표지"
        _:
            return "회로 모듈"


static func localize_phase_id(phase_id: String) -> String:
    match phase_id:
        "material":
            return "물질"
        "shadow":
            return "그림자"
        _:
            return "전환 중"


static func localize_weapon_id(weapon_id: String) -> String:
    var card: Dictionary = WeaponPartCatalogScript.choice_card(weapon_id)
    return str(card.get("label", "기본 무장")) if not card.is_empty() else "기본 무장"


func _draw() -> void:
    if not _is_expedition() or not _runtime_bound():
        return
    var layout := layout_for(get_viewport_rect().size)
    _draw_panel(layout["player"], "생존자", _player_line(), Color(0.96, 0.70, 0.34, 1.0))
    _draw_panel(layout["ark"], "등불 방주", _ark_line(), Color(0.96, 0.62, 0.28, 1.0))
    _draw_panel(layout["pause"], "일시정지", "Ⅱ", Color(0.63, 0.78, 0.90, 1.0))
    _draw_panel(layout["weapon"], "전투 상태", _combat_line(), Color(0.57, 0.77, 0.92, 1.0), 14)
    _draw_panel(layout["notice"], "원정 조작", _guidance_line(), Color(0.72, 0.62, 0.96, 1.0), 13)


func _player_line() -> String:
    var health := 0
    var paused := false
    var model: Variant = _player.get("model")
    if model != null:
        health = int(model.get("health"))
        paused = bool(model.get("paused"))
    return "체력 %03d · %s" % [health, "정지" if paused else "전투 중"]


func _ark_line() -> String:
    if not _ark.has_method("state_snapshot"):
        return "방주 상태 확인 중"
    var state: Dictionary = _ark.call("state_snapshot")
    return "내구 %03d · %s · %s" % [
        int(state.get("durability", 0)),
        localize_route_id(str(state.get("selected_route_id", ""))),
        localize_route_status(str(state.get("status", ""))),
    ]


func _combat_line() -> String:
    var weapon_label := "기본 무장"
    if _player.has_method("weapon_status_snapshot"):
        var weapon_state: Dictionary = _player.call("weapon_status_snapshot")
        weapon_label = localize_weapon_id(str(weapon_state.get("weapon_id", "")))
    var module_label := "회로 모듈"
    var light := 0
    if is_instance_valid(_circuit) and _circuit.has_method("status_snapshot"):
        var circuit_state: Dictionary = _circuit.call("status_snapshot")
        module_label = localize_module_id(str(circuit_state.get("selected_module", "")))
        light = roundi(float(circuit_state.get("light", 0.0)))
    var phase_label := "물질"
    if is_instance_valid(_phase) and _phase.has_method("current_phase_id"):
        phase_label = localize_phase_id(str(_phase.call("current_phase_id")))
    return "%s · %s %d · %s 위상" % [weapon_label, module_label, light, phase_label]


func _guidance_line() -> String:
    return "왼쪽 패드 이동 · 원형 버튼 회피 · 마름모 버튼 위상전환"


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
