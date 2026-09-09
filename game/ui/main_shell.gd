extends Control

const BuildIdentityScript = preload("res://game/core/build_identity.gd")
const SafeAreaScript = preload("res://platform/android/safe_area.gd")
const SurvivorControllerScript = preload("res://game/combat/survivor_controller.gd")
const SwarmEncounterScript = preload("res://game/combat/swarm_encounter.gd")
const BASE_MARGIN: int = 48

@onready var safe_area: MarginContainer = %SafeArea
@onready var status_label: Label = %Status

var movement_input: Vector2 = Vector2.ZERO
var dodge_pressed: bool = false
var phase_pressed: bool = false
var transient_input_generation: int = 0
var combat_preview: Node2D
var encounter_preview: Node2D


func _ready() -> void:
    get_viewport().size_changed.connect(_apply_safe_area)
    _apply_safe_area()
    _mount_w05_combat_preview()
    status_label.text = "W05 swarm foundation · %s · WASD/방향키 이동 · Space 회피 · Esc 일시정지" % BuildIdentityScript.VERSION_NAME


func _notification(what: int) -> void:
    if what == NOTIFICATION_APPLICATION_PAUSED or what == NOTIFICATION_APPLICATION_FOCUS_OUT:
        _clear_transient_input()
    elif what == NOTIFICATION_APPLICATION_RESUMED or what == NOTIFICATION_APPLICATION_FOCUS_IN:
        call_deferred("_apply_safe_area")


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


func _mount_w05_combat_preview() -> void:
    combat_preview = SurvivorControllerScript.new()
    combat_preview.name = "W05SurvivorPreview"
    combat_preview.set("camera_enabled", false)
    combat_preview.position = Vector2(640.0, 360.0)
    add_child(combat_preview)
    move_child(combat_preview, 1)

    encounter_preview = SwarmEncounterScript.new()
    encounter_preview.name = "W05SwarmPreview"
    add_child(encounter_preview)
    move_child(encounter_preview, 1)
    if encounter_preview.has_method("configure_player"):
        encounter_preview.call("configure_player", combat_preview)


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
