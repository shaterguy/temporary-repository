extends "res://game/ui/main_shell_w24.gd"

var _legacy_world_art_retired := false


func _process(delta: float) -> void:
    super._process(delta)
    _retire_legacy_world_art_once()
    _sync_medieval_presentation()


func _mount_runtime_preview() -> void:
    super._mount_runtime_preview()
    _retire_legacy_world_art_once()
    if not is_instance_valid(combat_preview):
        return
    combat_preview.set("camera_enabled", true)
    var combat_camera := combat_preview.get_node_or_null("CombatCamera") as Camera2D
    if combat_camera != null:
        combat_camera.enabled = true
    _sync_medieval_presentation()


func _on_weapon_action(action: Dictionary) -> void:
    super._on_weapon_action(action)
    var combat_visuals := get_node_or_null("WorldPresentation/SubViewport/MedievalCombatVisuals3D")
    if combat_visuals != null and combat_visuals.has_method("record_weapon_action"):
        combat_visuals.call("record_weapon_action", action, combat_preview, encounter_preview)


func _retire_legacy_world_art_once() -> void:
    if _legacy_world_art_retired:
        return
    for path in ["W13Environment", "W13RepresentativeArt"]:
        var legacy_node := get_node_or_null(path) as CanvasItem
        if legacy_node != null:
            legacy_node.visible = false
    _legacy_world_art_retired = true


func _sync_medieval_presentation() -> void:
    if not is_instance_valid(combat_preview):
        return
    var combat_camera := combat_preview.get_node_or_null("CombatCamera") as Camera2D
    if combat_camera == null:
        return
    var field := get_node_or_null("WorldPresentation/SubViewport/MedievalField3D")
    if field != null and field.has_method("set_gameplay_focus"):
        field.call("set_gameplay_focus", combat_camera.global_position)

    var expedition_active := shell_mode == MODE_EXPEDITION
    var combat_visuals := get_node_or_null("WorldPresentation/SubViewport/MedievalCombatVisuals3D")
    if combat_visuals != null and combat_visuals.has_method("sync_runtime"):
        combat_visuals.call("sync_runtime", combat_preview, encounter_preview, expedition_active)
        var player_canvas := combat_preview as CanvasItem
        var encounter_canvas := encounter_preview as CanvasItem
        if player_canvas != null:
            player_canvas.visible = not expedition_active
        if encounter_canvas != null:
            encounter_canvas.visible = not expedition_active


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
