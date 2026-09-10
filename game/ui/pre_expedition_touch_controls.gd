extends HBoxContainer

const MODE_SLOT_SELECT: String = "SLOT_SELECT"
const MODE_HUB: String = "HUB"

@onready var choice_1: Button = %Choice1
@onready var choice_2: Button = %Choice2
@onready var choice_3: Button = %Choice3

var _last_mode: String = ""


func _ready() -> void:
    process_mode = Node.PROCESS_MODE_ALWAYS
    choice_1.pressed.connect(_on_choice_pressed.bind(0))
    choice_2.pressed.connect(_on_choice_pressed.bind(1))
    choice_3.pressed.connect(_on_choice_pressed.bind(2))
    _sync_mode(true)


func _process(_delta: float) -> void:
    _sync_mode(false)


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
    visible = mode == MODE_SLOT_SELECT or mode == MODE_HUB
    if not visible:
        return
    choice_1.visible = true
    choice_2.visible = true
    if mode == MODE_SLOT_SELECT:
        choice_1.text = "슬롯 1"
        choice_2.text = "슬롯 2"
        choice_3.text = "슬롯 3"
        choice_3.visible = true
    else:
        choice_1.text = "선택 1"
        choice_2.text = "선택 2"
        choice_3.visible = false


func _shell() -> Node:
    if owner != null and owner.has_method("select_save_slot") and owner.has_method("select_world_choice"):
        return owner
    return null
