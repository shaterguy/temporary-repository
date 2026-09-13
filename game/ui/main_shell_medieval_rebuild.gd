extends "res://game/ui/main_shell_w24.gd"

const MEDIEVAL_PRESENTATION_REGION_IDS := [
    "twilight_shipyard",
    "glass_garden",
    "flooded_archive",
    "ash_railway",
    "eclipse_fortress",
]
const SHIPPED_UI_FONT_PATH: String = "res://assets/runtime/fonts/NotoSansKR-wght.ttf"

var _legacy_world_art_retired := false
var _shipped_ui_font: Font = null


func _ready() -> void:
    _install_shipped_ui_font()
    super._ready()


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


func _install_shipped_ui_font() -> void:
    if not ResourceLoader.exists(SHIPPED_UI_FONT_PATH):
        push_warning("Deterministic Korean UI font is not materialized: %s" % SHIPPED_UI_FONT_PATH)
        return
    var font_resource: Resource = load(SHIPPED_UI_FONT_PATH)
    if not font_resource is Font:
        push_error("Deterministic Korean UI font failed to load as Font: %s" % SHIPPED_UI_FONT_PATH)
        return
    var runtime_theme := Theme.new()
    if theme != null:
        runtime_theme = theme.duplicate(true) as Theme
    runtime_theme.default_font = font_resource as Font
    theme = runtime_theme
    _shipped_ui_font = font_resource as Font


func ui_font_snapshot() -> Dictionary:
    var active_font: Font = null
    if theme != null:
        active_font = theme.default_font
    return {
        "expected_path": SHIPPED_UI_FONT_PATH,
        "resource_path": active_font.resource_path if active_font != null else "",
        "deterministic": active_font != null and active_font.resource_path == SHIPPED_UI_FONT_PATH,
    }


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

    _anchor_world_presentation_to_camera(combat_camera)

    var region_id := _medieval_region_id()
    var field := get_node_or_null("WorldPresentation/SubViewport/MedievalField3D")
    if field != null:
        if field.has_method("set_gameplay_focus"):
            field.call("set_gameplay_focus", combat_camera.global_position)
        if field.has_method("set_region_id"):
            field.call("set_region_id", region_id)

    var expedition_active := shell_mode == MODE_EXPEDITION
    var combat_visuals := get_node_or_null("WorldPresentation/SubViewport/MedievalCombatVisuals3D")
    if combat_visuals != null:
        if combat_visuals.has_method("set_player_character"):
            combat_visuals.call("set_player_character", selected_character_id)
        if combat_visuals.has_method("sync_runtime"):
            combat_visuals.call("sync_runtime", combat_preview, encounter_preview, expedition_active)
        var player_canvas := combat_preview as CanvasItem
        var encounter_canvas := encounter_preview as CanvasItem
        if player_canvas != null:
            player_canvas.visible = not expedition_active
        if encounter_canvas != null:
            encounter_canvas.visible = not expedition_active


func _anchor_world_presentation_to_camera(combat_camera: Camera2D) -> void:
    var world_presentation := get_node_or_null("WorldPresentation") as Control
    if world_presentation == null:
        return
    world_presentation.position = combat_camera.global_position - get_viewport_rect().size * 0.5


func _medieval_region_id() -> String:
    if region_model != null and region_model.has_method("is_active") and bool(region_model.call("is_active")):
        var active_parent := str(region_model.call("parent_region_id")) if region_model.has_method("parent_region_id") else ""
        if MEDIEVAL_PRESENTATION_REGION_IDS.has(active_parent):
            return active_parent

    var context: Dictionary = {}
    if campaign != null and campaign.world != null:
        context = campaign.world.expedition_context()
    var context_parent := str(context.get("parent_region_id", ""))
    if MEDIEVAL_PRESENTATION_REGION_IDS.has(context_parent):
        return context_parent
    var context_region := str(context.get("region_id", ""))
    if MEDIEVAL_PRESENTATION_REGION_IDS.has(context_region):
        return context_region
    return W24_DEFAULT_REGION_ID


func medieval_presentation_snapshot() -> Dictionary:
    var field := get_node_or_null("WorldPresentation/SubViewport/MedievalField3D")
    var combat_visuals := get_node_or_null("WorldPresentation/SubViewport/MedievalCombatVisuals3D")
    var field_spec: Dictionary = {}
    var combat_spec: Dictionary = {}
    if field != null and field.has_method("presentation_spec"):
        field_spec = field.call("presentation_spec")
    if combat_visuals != null and combat_visuals.has_method("visual_debug_snapshot"):
        combat_spec = combat_visuals.call("visual_debug_snapshot")
    return {
        "selected_character_id": selected_character_id,
        "region_id": _medieval_region_id(),
        "field": field_spec,
        "combat": combat_spec,
    }


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
