extends Control

const BuildIdentityScript = preload("res://game/core/build_identity.gd")
const SafeAreaScript = preload("res://platform/android/safe_area.gd")
const SurvivorControllerScript = preload("res://game/combat/survivor_controller.gd")
const SwarmEncounterScript = preload("res://game/combat/swarm_encounter.gd")
const ArkConvoyScript = preload("res://game/world/ark_convoy.gd")
const BASE_MARGIN: int = 48

@onready var safe_area: MarginContainer = %SafeArea
@onready var status_label: Label = %Status

var movement_input: Vector2 = Vector2.ZERO
var dodge_pressed: bool = false
var phase_pressed: bool = false
var transient_input_generation: int = 0
var combat_preview: Node2D
var encounter_preview: Node2D
var ark_preview: Node2D


func _ready() -> void:
    get_viewport().size_changed.connect(_apply_safe_area)
    _apply_safe_area()
    _mount_w06_combat_preview()
    _show_route_choice_prompt()


func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        _clear_transient_input()
    elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
        call_deferred("_apply_safe_area")


func _unhandled_input(event: InputEvent) -> void:
    if not event is InputEventKey:
        return
    var key_event := event as InputEventKey
    if not key_event.pressed or key_event.echo:
        return
    if key_event.keycode == KEY_1:
        select_ark_route("risk_channel")
        get_viewport().set_input_as_handled()
    elif key_event.keycode == KEY_2:
        select_ark_route("supply_causeway")
        get_viewport().set_input_as_handled()


func set_transient_input(movement: Vector2, dodge: bool, phase: bool) -> void:
    movement_input = movement.limit_length(1.0)
    dodge_pressed = dodge
    phase_pressed = phase
    if is_instance_valid(combat_preview) and combat_preview.has_method("set_virtual_input"):
        combat_preview.call("set_virtual_input", movement_input, dodge_pressed)


func _clear_transient_input() -> void:
    movement_input = Vector2.ZERO
    dodge_pressed = false
    phase_pressed = false
    transient_input_generation += 1
    if is_instance_valid(combat_preview) and combat_preview.has_method("clear_transient_input"):
        combat_preview.call("clear_transient_input")


func select_ark_route(route_id: String) -> bool:
    if not is_instance_valid(ark_preview) or not ark_preview.has_method("choose_route"):
        return false
    var selected := bool(ark_preview.call("choose_route", route_id))
    if selected:
        var preview: Dictionary = ark_preview.call("route_preview", route_id)
        status_label.text = (
            "W06 %s · 위협 %d · 보급 %+d · %s · 이동/회피 전투 계속"
            % [
                route_id,
                int(preview.get("threat_level", 0)),
                int(preview.get("estimated_supply_delta", 0)),
                str(preview.get("defend_target", "ark_core")),
            ]
        )
    return selected


func _mount_w06_combat_preview() -> void:
    combat_preview = SurvivorControllerScript.new()
    combat_preview.name = "W06SurvivorPreview"
    combat_preview.set("camera_enabled", false)
    combat_preview.position = Vector2(640.0, 360.0)
    add_child(combat_preview)
    move_child(combat_preview, 1)

    ark_preview = ArkConvoyScript.new()
    ark_preview.name = "W06ArkPreview"
    ark_preview.position = Vector2(280.0, 360.0)
    add_child(ark_preview)
    move_child(ark_preview, 1)
    ark_preview.call("configure_seed", 20260909)
    ark_preview.connect("route_state_changed", Callable(self, "_on_ark_state_changed"))

    encounter_preview = SwarmEncounterScript.new()
    encounter_preview.name = "W06SwarmPreview"
    add_child(encounter_preview)
    move_child(encounter_preview, 1)
    if encounter_preview.has_method("configure_player"):
        encounter_preview.call("configure_player", combat_preview)
    if encounter_preview.has_method("configure_escort_target"):
        encounter_preview.call("configure_escort_target", ark_preview)


func _show_route_choice_prompt() -> void:
    status_label.text = "W06 이동 방주 · 1 위험 항로 / 2 보급 항로 선택 · WASD/방향키 이동 · Space 회피 · Esc 일시정지 · %s" % BuildIdentityScript.VERSION_NAME


func _on_ark_state_changed(route_status: String, route_id: String) -> void:
    if route_status == "AWAITING_ROUTE":
        _show_route_choice_prompt()
    elif route_status == "RESTING":
        status_label.text = "W06 %s 도착 · 휴식 구간 · 방주/보급 상태 저장 가능" % route_id
    elif route_status == "ARRIVED":
        status_label.text = "W06 %s 목적지 확보 · 다음 항로 준비" % route_id
    elif route_status == "FAILED_RECOVERABLE":
        status_label.text = "W06 방주 파손 · 보급을 사용한 복구 가능"


func _apply_safe_area() -> void:
    if not is_instance_valid(safe_area):
        return
    var window_size := get_window().size
    var visible_size := get_viewport_rect().size
    var viewport_size := Vector2i(roundi(visible_size.x), roundi(visible_size.y))
    var margins := SafeAreaScript.margins_for(
        window_size,
        viewport_size,
        DisplayServer.get_display_safe_area()
    )
    safe_area.add_theme_constant_override("margin_left", BASE_MARGIN + margins.x)
    safe_area.add_theme_constant_override("margin_top", BASE_MARGIN + margins.y)
    safe_area.add_theme_constant_override("margin_right", BASE_MARGIN + margins.z)
    safe_area.add_theme_constant_override("margin_bottom", BASE_MARGIN + margins.w)
