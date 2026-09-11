extends HBoxContainer

const MainShellW24Script = preload("res://game/ui/main_shell_w24.gd")
const MODE_SLOT_SELECT: String = "SLOT_SELECT"
const MODE_HUB: String = "HUB"
const MODE_EXPEDITION: String = "EXPEDITION"
const MODE_RECOVERY_BLOCKED: String = "RECOVERY_BLOCKED"

@onready var choice_1: Button = %Choice1
@onready var choice_2: Button = %Choice2
@onready var choice_3: Button = %Choice3
@onready var menu_dimmer: ColorRect = %MenuDimmer
@onready var menu_card: Panel = %MenuCard
@onready var content: VBoxContainer = %Content
@onready var foundation: Label = %Foundation
@onready var status_label: Label = %Status

var _last_mode: String = ""


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    choice_1.pressed.connect(_on_choice_pressed.bind(0))
    choice_2.pressed.connect(_on_choice_pressed.bind(1))
    choice_3.pressed.connect(_on_choice_pressed.bind(2))
    _sync_mode(true)


func _process(_delta: float) -> void:
    _sync_mode(false)


func force_refresh() -> void:
    _sync_mode(true)


func _on_choice_pressed(index: int) -> void:
    var shell := _shell()
    if shell == null:
        return
    var mode := str(shell.get("shell_mode"))
    if mode == MODE_SLOT_SELECT:
        shell.call("select_save_slot", index)
    elif mode == MODE_HUB and index < 2:
        shell.call("select_world_choice", index)
    _sync_mode(true)


func _sync_mode(force: bool) -> void:
    var shell := _shell()
    if shell == null:
        visible = false
        return
    var mode := str(shell.get("shell_mode"))
    if not force and mode == _last_mode:
        return
    _last_mode = mode

    var menu_visible := mode == MODE_SLOT_SELECT or mode == MODE_HUB or mode == MODE_RECOVERY_BLOCKED
    menu_dimmer.visible = menu_visible
    menu_card.visible = menu_visible
    content.visible = menu_visible
    if not menu_visible:
        return

    if mode == MODE_SLOT_SELECT:
        _sync_slot_labels(shell)
    elif mode == MODE_HUB:
        _sync_hub_labels(shell)
    else:
        foundation.text = "여정을 복구할 수 없습니다"
        choice_1.visible = false
        choice_2.visible = false
        choice_3.visible = false


func _sync_slot_labels(shell: Node) -> void:
    foundation.text = "저장된 여정을 선택하세요"
    var metadata_all: Array = []
    var campaign_object: Object = shell.get("campaign")
    if campaign_object != null and campaign_object.has_method("slot_metadata_all"):
        metadata_all = campaign_object.call("slot_metadata_all")
    var buttons: Array[Button] = [choice_1, choice_2, choice_3]
    for index in range(buttons.size()):
        var occupied := false
        if index < metadata_all.size() and metadata_all[index] is Dictionary:
            var metadata: Dictionary = metadata_all[index]
            occupied = bool(metadata.get("occupied", false))
        buttons[index].visible = true
        buttons[index].disabled = false
        buttons[index].text = "슬롯 %d\n%s" % [
            index + 1,
            "계속하기" if occupied else "새 여정 시작",
        ]


func _sync_hub_labels(shell: Node) -> void:
    foundation.text = "다음 항로를 선택하세요"
    var options: Array = []
    var campaign_object: Object = shell.get("campaign")
    if campaign_object != null:
        var world_object: Object = campaign_object.get("world")
        if world_object != null and world_object.has_method("departure_options"):
            options = world_object.call("departure_options")
    var buttons: Array[Button] = [choice_1, choice_2]
    for index in range(buttons.size()):
        buttons[index].visible = true
        buttons[index].disabled = index >= options.size()
        if index < options.size() and options[index] is Dictionary:
            var option: Dictionary = options[index]
            var region_label := _player_label(str(option.get("next_region", "미지의 지역")))
            var route_label := _player_label(str(option.get("route_id", "항로")))
            buttons[index].text = "%d · %s\n%s" % [index + 1, region_label, route_label]
        else:
            buttons[index].text = "%d · 항로 준비 중" % (index + 1)
    choice_3.visible = false
    choice_3.disabled = true


func readability_snapshot() -> Dictionary:
    var panel_style := menu_card.get_theme_stylebox("panel") as StyleBoxFlat
    var normal_style := choice_1.get_theme_stylebox("normal") as StyleBoxFlat
    var pressed_style := choice_1.get_theme_stylebox("pressed") as StyleBoxFlat
    var focus_style := choice_1.get_theme_stylebox("focus") as StyleBoxFlat
    return {
        "mode": _last_mode,
        "menu_visible": menu_dimmer.visible and menu_card.visible and content.visible,
        "dimmer_alpha": menu_dimmer.color.a,
        "panel_alpha": panel_style.bg_color.a if panel_style != null else 0.0,
        "touch_height": minf(choice_1.custom_minimum_size.y, minf(choice_2.custom_minimum_size.y, choice_3.custom_minimum_size.y)),
        "status_font_size": status_label.get_theme_font_size("font_size"),
        "button_font_size": choice_1.get_theme_font_size("font_size"),
        "dimmer_blocks_input": menu_dimmer.mouse_filter == Control.MOUSE_FILTER_STOP,
        "normal_button_color": normal_style.bg_color if normal_style != null else Color.TRANSPARENT,
        "pressed_button_color": pressed_style.bg_color if pressed_style != null else Color.TRANSPARENT,
        "focus_border_width": focus_style.border_width_left if focus_style != null else 0,
        "choice_labels": [choice_1.text, choice_2.text, choice_3.text],
        "choice_visibility": [choice_1.visible, choice_2.visible, choice_3.visible],
    }


func _player_label(raw_value: String) -> String:
    return MainShellW24Script.polish_status_text(raw_value)


func _shell() -> Node:
    if owner != null and owner.has_method("select_save_slot") and owner.has_method("select_world_choice"):
        return owner
    return null
