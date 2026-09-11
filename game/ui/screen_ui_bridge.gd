extends CanvasLayer


func _get(property: StringName) -> Variant:
    var host := _host()
    if host == null:
        return null
    return host.get(property)


func set_transient_input(movement: Vector2, dodge_pressed: bool, phase_pressed: bool) -> void:
    var host := _host()
    if host != null and host.has_method("set_transient_input"):
        host.call("set_transient_input", movement, dodge_pressed, phase_pressed)


func character_tutorial_prompt() -> String:
    var host := _host()
    if host != null and host.has_method("character_tutorial_prompt"):
        return str(host.call("character_tutorial_prompt"))
    return ""


func _host() -> Node:
    if owner != null:
        return owner
    return get_parent()
