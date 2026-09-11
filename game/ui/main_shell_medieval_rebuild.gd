extends "res://game/ui/main_shell_w24.gd"


func _process(delta: float) -> void:
    super._process(delta)
    _sync_medieval_presentation()


func _mount_runtime_preview() -> void:
    super._mount_runtime_preview()
    if not is_instance_valid(combat_preview):
        return
    combat_preview.set("camera_enabled", true)
    var combat_camera := combat_preview.get_node_or_null("CombatCamera") as Camera2D
    if combat_camera != null:
        combat_camera.enabled = true
    _sync_medieval_presentation()


func _sync_medieval_presentation() -> void:
    if not is_instance_valid(combat_preview):
        return
    var combat_camera := combat_preview.get_node_or_null("CombatCamera") as Camera2D
    if combat_camera == null:
        return
    var field := get_node_or_null("WorldPresentation/SubViewport/MedievalField3D")
    if field != null and field.has_method("set_gameplay_focus"):
        field.call("set_gameplay_focus", combat_camera.global_position)


func _sync_story_event_art() -> void:
    var hud := get_node_or_null("ScreenUI/W23WorldEventHud")
    if hud == null:
        return
    if campaign != null and campaign.world != null and campaign.world.has_pending_story_event():
        var event: Dictionary = campaign.current_story_event()
        var event_id := str(event.get("event_id", ""))
        if not event_id.is_empty() and bool(hud.call("show_event", event_id)):
            return
    hud.call("clear_event")


func _clear_story_event_art() -> void:
    var hud := get_node_or_null("ScreenUI/W23WorldEventHud")
    if hud != null:
        hud.call("clear_event")
