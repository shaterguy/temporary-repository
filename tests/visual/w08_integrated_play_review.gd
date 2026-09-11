extends Node

const CampaignRuntimeW22Script = preload("res://game/world/campaign_runtime_w22.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")

const TEST_ROOT: String = "user://ci_w08_integrated_play"
const OUTPUT_DIR: String = "res://artifacts/w08"
const EXPECTED_SIZE := Vector2i(1280, 720)
const MID_TRAVEL_DISTANCE: float = 800.0
const MIN_TRAVEL_DISTANCE: float = 1600.0
const MAX_TRAVEL_FRAMES: int = 900
const MAX_CAMERA_ERROR: float = 4.0

var _failures: Array[String] = []
var _first_weapon_action: Dictionary = {}


func _ready() -> void:
    call_deferred("_run")


func _run() -> void:
    get_window().size = EXPECTED_SIZE
    for _frame in range(4):
        await get_tree().process_frame
    _clear_save()
    var output_error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT_DIR))
    _expect(output_error == OK, "W08 artifact directory could not be created")

    var packed: Resource = load("res://game/ui/main_shell.tscn")
    _expect(packed is PackedScene, "W08 real main shell could not be loaded")
    if not packed is PackedScene:
        _finish(null)
        return

    var shell: Node = (packed as PackedScene).instantiate()
    shell.set("campaign", CampaignRuntimeW22Script.new(TEST_ROOT))
    add_child(shell)
    for _frame in range(8):
        await get_tree().process_frame

    _expect(str(shell.get("shell_mode")) == "SLOT_SELECT", "W08 did not start at the real slot-select entry state")
    var combat := shell.get("combat_preview") as Node2D
    _expect(is_instance_valid(combat), "W08 real combat runtime is missing")
    if is_instance_valid(combat) and combat.has_signal("weapon_action"):
        combat.connect("weapon_action", Callable(self, "_on_weapon_action"))

    var audio := get_node_or_null("/root/AudioDirector")
    _expect(audio != null, "W08 AudioDirector autoload is missing")
    var audio_snapshot: Dictionary = shell.call("audio_runtime_snapshot") if shell.has_method("audio_runtime_snapshot") else {}
    var external_audio: Dictionary = audio_snapshot.get("external_audio", {})
    _expect(str(external_audio.get("runtime_mode", "")) == "external_cc0_files", "W08 runtime audio is not using the external CC0 path")
    _expect(not bool(audio_snapshot.get("procedural_runtime", true)), "W08 procedural runtime audio unexpectedly remains enabled")
    _expect(int(external_audio.get("runtime_media_count", 0)) == 29, "W08 external runtime media count drifted from 29")
    _assert_music_stream(audio, "RegionMusic", "/music/medieval_exploration.mp3")
    _assert_music_stream(audio, "ForestAmbience", "/ambience/forest_ambience.mp3")

    _expect(bool(shell.call("select_save_slot", 0)), "W08 real slot selection failed")
    for _frame in range(4):
        await get_tree().process_frame
    _expect(str(shell.get("shell_mode")) == "HUB", "W08 real slot selection did not enter HUB")

    var controls := shell.get_node_or_null("ScreenUI/SafeArea/Content/TouchChoices")
    _expect(controls != null and controls.has_method("readability_snapshot"), "W08 real hub readability controller is missing")
    var hub_ui: Dictionary = {}
    if controls != null and controls.has_method("readability_snapshot"):
        if controls.has_method("force_refresh"):
            controls.call("force_refresh")
        await get_tree().process_frame
        hub_ui = controls.call("readability_snapshot")
        _expect(str(hub_ui.get("mode", "")) == "HUB", "W08 readability controller did not observe the real HUB state")
        _expect(bool(hub_ui.get("menu_visible", false)), "W08 real HUB menu is not visible")
        _expect(float(hub_ui.get("dimmer_alpha", 0.0)) >= 0.72, "W08 real HUB dimmer is below the readability contract")
        _expect(float(hub_ui.get("panel_alpha", 0.0)) >= 0.94, "W08 real HUB panel is not effectively opaque")
        _expect(float(hub_ui.get("touch_height", 0.0)) >= 72.0, "W08 real HUB touch targets are too small")
        _expect(int(hub_ui.get("status_font_size", 0)) >= 20, "W08 real HUB status text is too small")
        _expect(int(hub_ui.get("button_font_size", 0)) >= 22, "W08 real HUB choice text is too small")
        _expect(bool(hub_ui.get("dimmer_blocks_input", false)), "W08 real HUB dimmer does not block touch leakage")
    _save_capture("%s/hub-menu.png" % OUTPUT_DIR)

    _expect(bool(shell.call("select_world_choice", 0)), "W08 real HUB choice could not begin an expedition")
    await get_tree().process_frame
    await get_tree().physics_frame
    await get_tree().process_frame
    _expect(str(shell.get("shell_mode")) == "EXPEDITION", "W08 real HUB choice did not enter EXPEDITION")
    _save_capture("%s/expedition-start.png" % OUTPUT_DIR)

    combat = shell.get("combat_preview") as Node2D
    var camera: Camera2D = null
    if is_instance_valid(combat):
        camera = combat.get_node_or_null("CombatCamera") as Camera2D
    _expect(is_instance_valid(combat), "W08 expedition combat runtime is missing")
    _expect(camera != null and camera.enabled, "W08 real combat camera is not enabled")

    var overlay := shell.get_node_or_null("W25MobileControls")
    if overlay == null:
        overlay = shell.get_node_or_null("ScreenUI/W25MobileControls")
    _expect(overlay != null and overlay.has_method("runtime_snapshot"), "W08 mobile control overlay is missing")
    if overlay == null:
        _finish(shell)
        return

    var input_model: Variant = overlay.get("model")
    var layout: Dictionary = input_model.call("layout_snapshot")
    var stick_center: Vector2 = layout.get("stick_center", Vector2.ZERO)
    var stick_radius := float(layout.get("stick_radius", 82.0))
    var start_position: Vector2 = combat.global_position
    var start_camera: Vector2 = camera.global_position if camera != null else Vector2.ZERO

    _push_touch(get_viewport(), 801, stick_center, true)
    _push_drag(get_viewport(), 801, stick_center + Vector2(stick_radius * 0.92, 0.0), Vector2(stick_radius * 0.92, 0.0))
    await get_tree().process_frame
    var touch_snapshot: Dictionary = overlay.call("runtime_snapshot")
    var overlay_movement: Vector2 = touch_snapshot.get("movement", Vector2.ZERO)
    var shell_movement: Vector2 = shell.get("movement_input")
    _expect(overlay_movement.x > 0.70, "W08 real touch drag did not produce movement input")
    _expect(shell_movement.x > 0.70, "W08 real touch drag did not reach the shell bridge")

    var mid_saved := false
    var combat_stage := 0
    var combat_stage_frames := 0
    var max_camera_error := 0.0
    var reached_distance := 0.0
    var combat_audio_paths: Array[String] = []

    for _frame_index in range(MAX_TRAVEL_FRAMES):
        await get_tree().physics_frame
        await get_tree().process_frame
        if str(shell.get("shell_mode")) != "EXPEDITION":
            _failures.append("W08 left EXPEDITION before the integrated traversal completed")
            break
        if not is_instance_valid(combat):
            _failures.append("W08 combat runtime disappeared during traversal")
            break

        reached_distance = combat.global_position.distance_to(start_position)
        if camera != null:
            max_camera_error = maxf(max_camera_error, camera.global_position.distance_to(combat.global_position))

        if not mid_saved and reached_distance >= MID_TRAVEL_DISTANCE:
            _save_capture("%s/travel-mid.png" % OUTPUT_DIR)
            mid_saved = true

        if not _first_weapon_action.is_empty():
            if combat_stage == 0:
                _save_capture("%s/combat-trigger.png" % OUTPUT_DIR)
                combat_audio_paths = _collect_combat_audio_paths(audio)
                combat_stage = 1
                combat_stage_frames = 0
            else:
                combat_stage_frames += 1
                if combat_stage == 1 and combat_stage_frames >= 10:
                    _save_capture("%s/combat-travel.png" % OUTPUT_DIR)
                    combat_stage = 2
                    combat_stage_frames = 0
                elif combat_stage == 2 and combat_stage_frames >= 12:
                    _save_capture("%s/combat-impact.png" % OUTPUT_DIR)
                    combat_stage = 3
                    combat_stage_frames = 0

        if reached_distance >= MIN_TRAVEL_DISTANCE and combat_stage >= 3:
            break

    _push_touch(get_viewport(), 801, stick_center, false)
    await get_tree().process_frame
    touch_snapshot = overlay.call("runtime_snapshot")
    var released_movement: Vector2 = touch_snapshot.get("movement", Vector2.ZERO)
    _expect(released_movement.is_zero_approx(), "W08 released touch left movement latched")

    _expect(mid_saved, "W08 did not traverse far enough to capture the mid-field state")
    _expect(reached_distance >= MIN_TRAVEL_DISTANCE, "W08 real player traversal did not reach 1600 px")
    _expect(max_camera_error <= MAX_CAMERA_ERROR, "W08 combat camera did not continuously track the real player")
    _expect(combat_stage >= 3, "W08 natural weapon action did not produce a three-stage combat capture sequence")
    _expect(not _first_weapon_action.is_empty(), "W08 did not observe a natural weapon action from the real expedition runtime")
    _expect(str(_first_weapon_action.get("type", "")) == "weapon_damage", "W08 first natural combat action was not weapon damage")
    _expect(not str(_first_weapon_action.get("weapon_id", "")).is_empty(), "W08 natural weapon action did not identify its weapon")

    if combat_audio_paths.is_empty():
        combat_audio_paths = _collect_combat_audio_paths(audio)
    var weapon_audio_found := false
    var hit_audio_found := false
    for path: String in combat_audio_paths:
        if path.contains("/weapons/weapon_"):
            weapon_audio_found = true
        if path.ends_with("/combat/hit_metal.ogg"):
            hit_audio_found = true
    _expect(weapon_audio_found, "W08 natural combat action did not route an external weapon SFX")
    _expect(hit_audio_found, "W08 natural combat action did not route the external hit SFX")

    _save_capture("%s/travel-far.png" % OUTPUT_DIR)
    var end_position: Vector2 = combat.global_position if is_instance_valid(combat) else start_position
    var end_camera: Vector2 = camera.global_position if camera != null else start_camera
    _assert_screenshot_set()

    var combat_visuals := shell.get_node_or_null("WorldPresentation/SubViewport/MedievalCombatVisuals3D")
    var combat_visual_snapshot: Dictionary = {}
    if combat_visuals != null and combat_visuals.has_method("visual_debug_snapshot"):
        var raw_visual_snapshot: Dictionary = combat_visuals.call("visual_debug_snapshot")
        combat_visual_snapshot = {
            "enemy_visual_count": int(raw_visual_snapshot.get("enemy_visual_count", 0)),
            "visible_impact_cues": int(raw_visual_snapshot.get("visible_impact_cues", 0)),
            "visible_damage_cues": int(raw_visual_snapshot.get("visible_damage_cues", 0)),
            "visible_death_cues": int(raw_visual_snapshot.get("visible_death_cues", 0)),
            "visible_chain_cues": int(raw_visual_snapshot.get("visible_chain_cues", 0)),
            "visible_area_cues": int(raw_visual_snapshot.get("visible_area_cues", 0)),
        }

    var evidence := {
        "schema": "w08-integrated-play-review-v1",
        "viewport": [EXPECTED_SIZE.x, EXPECTED_SIZE.y],
        "entry_flow": ["SLOT_SELECT", "HUB", "EXPEDITION"],
        "hub_ui": {
            "dimmer_alpha": float(hub_ui.get("dimmer_alpha", 0.0)),
            "panel_alpha": float(hub_ui.get("panel_alpha", 0.0)),
            "touch_height": float(hub_ui.get("touch_height", 0.0)),
            "status_font_size": int(hub_ui.get("status_font_size", 0)),
            "button_font_size": int(hub_ui.get("button_font_size", 0)),
            "dimmer_blocks_input": bool(hub_ui.get("dimmer_blocks_input", false)),
        },
        "start_position": [start_position.x, start_position.y],
        "end_position": [end_position.x, end_position.y],
        "travel_distance": reached_distance,
        "start_camera": [start_camera.x, start_camera.y],
        "end_camera": [end_camera.x, end_camera.y],
        "max_camera_error": max_camera_error,
        "first_weapon_action": {
            "type": str(_first_weapon_action.get("type", "")),
            "weapon_id": str(_first_weapon_action.get("weapon_id", "")),
            "target_id": int(_first_weapon_action.get("target_id", -1)),
            "damage": int(_first_weapon_action.get("damage", 0)),
        },
        "combat_visual_snapshot": combat_visual_snapshot,
        "combat_audio_paths": combat_audio_paths,
        "audio_runtime": {
            "procedural_runtime": bool(audio_snapshot.get("procedural_runtime", true)),
            "runtime_mode": str(external_audio.get("runtime_mode", "")),
            "runtime_media_count": int(external_audio.get("runtime_media_count", 0)),
            "weapon_sfx": int(external_audio.get("weapon_sfx", 0)),
        },
        "listening_review": "REQUIRED",
    }
    var evidence_file := FileAccess.open("%s/runtime-evidence.json" % OUTPUT_DIR, FileAccess.WRITE)
    _expect(evidence_file != null, "W08 runtime evidence file could not be opened")
    if evidence_file != null:
        evidence_file.store_string(JSON.stringify(evidence, "  "))
        evidence_file.close()

    if _failures.is_empty():
        print("W08_REAL_ENTRY_FLOW=PASS")
        print("W08_HUB_MENU_READABILITY=PASS")
        print("W08_EXPEDITION_ENTRY=PASS")
        print("W08_NATURAL_WEAPON_ACTION=PASS")
        print("W08_COMBAT_SEQUENCE_CAPTURE=PASS")
        print("W08_TRAVEL_DISTANCE=%.1f" % reached_distance)
        print("W08_CAMERA_MAX_ERROR=%.3f" % max_camera_error)
        print("W08_CAMERA_TRACKING=PASS")
        print("W08_EXTERNAL_AUDIO_RUNTIME=PASS")
        print("W08_COMBAT_AUDIO_ROUTING=PASS")
        print("W08_REVIEW_SCREENSHOT_COUNT=7")
        print("W08_LISTENING_REVIEW=REQUIRED")
        print("W08_INTEGRATED_REVIEW=PASS")
    _finish(shell)


func _on_weapon_action(action: Dictionary) -> void:
    if _first_weapon_action.is_empty() and str(action.get("type", "")) == "weapon_damage":
        _first_weapon_action = action.duplicate(true)


func _assert_music_stream(audio: Node, player_name: String, expected_suffix: String) -> void:
    if audio == null:
        return
    var player := audio.get_node_or_null(player_name) as AudioStreamPlayer
    _expect(player != null and player.stream != null, "W08 %s stream is missing" % player_name)
    if player != null and player.stream != null:
        var resource_path := str(player.stream.resource_path)
        _expect(resource_path.ends_with(expected_suffix), "W08 %s is not routed to the expected external media" % player_name)


func _collect_combat_audio_paths(audio: Node) -> Array[String]:
    var paths: Array[String] = []
    if audio == null:
        return paths
    for child: Node in audio.get_children():
        if not child is AudioStreamPlayer:
            continue
        var player := child as AudioStreamPlayer
        if not str(player.name).begins_with("SfxVoice") or player.stream == null:
            continue
        var path := str(player.stream.resource_path)
        if not path.is_empty() and not paths.has(path):
            paths.append(path)
    paths.sort()
    return paths


func _save_capture(path: String) -> bool:
    var image: Image = get_viewport().get_texture().get_image()
    if image == null or image.get_width() != EXPECTED_SIZE.x or image.get_height() != EXPECTED_SIZE.y:
        var actual := Vector2i.ZERO if image == null else Vector2i(image.get_width(), image.get_height())
        _failures.append("W08 capture size mismatch for %s expected=%dx%d actual=%dx%d" % [path, EXPECTED_SIZE.x, EXPECTED_SIZE.y, actual.x, actual.y])
        return false
    var save_error := image.save_png(ProjectSettings.globalize_path(path))
    if save_error != OK:
        _failures.append("W08 capture save failed for %s: %d" % [path, save_error])
        return false
    return true


func _assert_screenshot_set() -> void:
    var names := [
        "hub-menu.png",
        "expedition-start.png",
        "combat-trigger.png",
        "combat-travel.png",
        "combat-impact.png",
        "travel-mid.png",
        "travel-far.png",
    ]
    var hashes: Dictionary = {}
    for raw_name: String in names:
        var path := "%s/%s" % [OUTPUT_DIR, raw_name]
        _expect(FileAccess.file_exists(path), "W08 required review screenshot is missing: %s" % raw_name)
        if FileAccess.file_exists(path):
            var hash_value := FileAccess.get_sha256(path)
            hashes[hash_value] = true
            print("W08_CAPTURE_SHA256_%s=%s" % [raw_name.replace("-", "_").replace(".", "_"), hash_value])
    _expect(hashes.size() == names.size(), "W08 integrated review screenshots are not all visually distinct")


func _push_touch(viewport: Viewport, pointer_id: int, position: Vector2, pressed: bool) -> void:
    var event := InputEventScreenTouch.new()
    event.index = pointer_id
    event.position = position
    event.pressed = pressed
    viewport.push_input(event, true)


func _push_drag(viewport: Viewport, pointer_id: int, position: Vector2, relative: Vector2) -> void:
    var event := InputEventScreenDrag.new()
    event.index = pointer_id
    event.position = position
    event.relative = relative
    viewport.push_input(event, true)


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _clear_save() -> void:
    for slot in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, TEST_ROOT)


func _finish(shell: Node) -> void:
    if is_instance_valid(shell):
        shell.queue_free()
    _clear_save()
    if _failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in _failures:
        printerr("W08_FAIL: %s" % failure)
    printerr("W08_INTEGRATED_REVIEW=FAIL")
    get_tree().quit(1)
