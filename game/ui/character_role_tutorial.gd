extends Control

var _prompt_label: Label
var _selected_character_id: String = ""
var _prompt: String = ""


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    process_mode = Node.PROCESS_MODE_ALWAYS
    _build_prompt_label()
    call_deferred("_refresh_from_runtime")


func _process(_delta: float) -> void:
    _refresh_from_runtime()


func status_snapshot() -> Dictionary:
    return {
        "selected_character_id": _selected_character_id,
        "prompt": _prompt,
        "visible": is_instance_valid(_prompt_label) and _prompt_label.visible,
    }


func _refresh_from_runtime() -> void:
    var host := get_parent()
    if host == null or not host.has_method("character_tutorial_prompt"):
        _set_prompt("", "", false)
        return
    var shell_mode := str(host.get("shell_mode"))
    var should_show := shell_mode == "HUB" or shell_mode == "EXPEDITION"
    var character_id := str(host.get("selected_character_id"))
    var prompt := str(host.call("character_tutorial_prompt"))
    _set_prompt(character_id, prompt, should_show and not prompt.is_empty())


func _set_prompt(character_id: String, prompt: String, visible: bool) -> void:
    _selected_character_id = character_id
    _prompt = prompt
    if not is_instance_valid(_prompt_label):
        return
    _prompt_label.text = "W16 캐릭터 전술 · %s" % prompt if visible else ""
    _prompt_label.visible = visible


func _build_prompt_label() -> void:
    _prompt_label = Label.new()
    _prompt_label.name = "CharacterTutorialPrompt"
    _prompt_label.set_anchors_preset(Control.PRESET_CENTER_TOP)
    _prompt_label.position = Vector2(-410.0, 146.0)
    _prompt_label.size = Vector2(820.0, 72.0)
    _prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    _prompt_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    _prompt_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
    _prompt_label.add_theme_font_size_override("font_size", 16)
    _prompt_label.add_theme_color_override("font_color", Color(0.82, 0.91, 0.98, 1.0))
    _prompt_label.add_theme_color_override("font_shadow_color", Color(0.02, 0.03, 0.05, 0.92))
    _prompt_label.add_theme_constant_override("shadow_offset_x", 2)
    _prompt_label.add_theme_constant_override("shadow_offset_y", 2)
    add_child(_prompt_label)
    _prompt_label.visible = false
