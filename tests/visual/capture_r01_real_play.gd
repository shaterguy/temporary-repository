extends SceneTree

const CampaignRuntimeW22Script = preload("res://game/world/campaign_runtime_w22.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")
const OUTPUT_DIR: String = "res://artifacts/r01"
const VIEWPORT_MATRIX := [Vector2i(1280, 720), Vector2i(2340, 1080)]
const KOREAN_PROBE_CODEPOINT: int = 0xC794
const SAFE_AREA_MARGIN_TOTAL: float = 96.0

var _failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_capture")


func _capture() -> void:
    var packed: Resource = load("res://game/ui/main_shell.tscn")
    _expect(packed is PackedScene, "R01 capture could not load main shell")
    if not packed is PackedScene:
        _finish()
        return
    var output_dir_absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
    if DirAccess.make_dir_recursive_absolute(output_dir_absolute) != OK:
        _failures.append("R01 capture output directory could not be created")
        _finish()
        return

    for viewport_size: Vector2i in VIEWPORT_MATRIX:
        var test_root := "user://ci_r01_capture_%dx%d" % [viewport_size.x, viewport_size.y]
        _clear_save(test_root)
        var viewport := SubViewport.new()
        viewport.name = "R01ReviewViewport_%dx%d" % [viewport_size.x, viewport_size.y]
        viewport.size = viewport_size
        viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
        root.add_child(viewport)

        var shell: Node = (packed as PackedScene).instantiate()
        shell.set("campaign", CampaignRuntimeW22Script.new(test_root))
        viewport.add_child(shell)
        await process_frame
        await process_frame
        await process_frame
        _assert_readability(shell, viewport_size, "slot")

        if not bool(shell.call("select_save_slot", 0)):
            _failures.append("R01 capture could not enter real HUB at %dx%d" % [viewport_size.x, viewport_size.y])
            viewport.queue_free()
            await process_frame
            _clear_save(test_root)
            continue
        await process_frame
        await process_frame
        _expect(str(shell.get("shell_mode")) == "HUB", "R01 capture HUB state mismatch at %dx%d" % [viewport_size.x, viewport_size.y])
        _assert_readability(shell, viewport_size, "hub")
        _save_capture(viewport, "%s/hub-%dx%d.png" % [OUTPUT_DIR, viewport_size.x, viewport_size.y], viewport_size, "hub")

        if not bool(shell.call("select_world_choice", 0)):
            _failures.append("R01 capture could not begin real expedition at %dx%d" % [viewport_size.x, viewport_size.y])
            viewport.queue_free()
            await process_frame
            _clear_save(test_root)
            continue
        await process_frame
        await physics_frame
        var overlay := shell.get_node_or_null("W25MobileControls")
        if overlay == null:
            _failures.append("R01 capture W25 overlay missing at %dx%d" % [viewport_size.x, viewport_size.y])
            viewport.queue_free()
            await process_frame
            _clear_save(test_root)
            continue
        var input_model: Variant = overlay.get("model")
        var layout: Dictionary = input_model.call("layout_snapshot")
        var stick_center: Vector2 = layout.get("stick_center", Vector2.ZERO)
        var stick_radius := float(layout.get("stick_radius", 82.0))
        var dodge_center: Vector2 = layout.get("dodge_center", Vector2.ZERO)
        _push_touch(viewport, 101, stick_center, true)
        _push_drag(viewport, 101, stick_center + Vector2(stick_radius * 0.88, -stick_radius * 0.18), Vector2(stick_radius * 0.88, -stick_radius * 0.18))
        _push_touch(viewport, 202, dodge_center, true)
        await process_frame
        await physics_frame
        await process_frame
        var touch_snapshot: Dictionary = overlay.call("runtime_snapshot")
        _expect(bool(touch_snapshot.get("enabled", false)), "R01 capture overlay is not enabled in real expedition")
        _expect(Vector2(touch_snapshot.get("movement", Vector2.ZERO)).length() > 0.6, "R01 capture real touch movement is not active")
        _expect(bool(touch_snapshot.get("dodge", false)), "R01 capture real dodge touch is not active")
        _assert_readability(shell, viewport_size, "expedition")
        _save_capture(viewport, "%s/expedition-touch-%dx%d.png" % [OUTPUT_DIR, viewport_size.x, viewport_size.y], viewport_size, "expedition-touch")
        _push_touch(viewport, 202, dodge_center, false)
        _push_touch(viewport, 101, stick_center, false)
        await process_frame

        shell.call("_settle_current", "success")
        await process_frame
        await process_frame
        await process_frame
        var campaign: Variant = shell.get("campaign")
        var world: Variant = campaign.get("world")
        _expect(str(shell.get("shell_mode")) == "HUB", "R01 capture settlement did not return to HUB")
        _expect(bool(world.call("has_pending_story_event")), "R01 capture settlement did not expose real story event")
        var event: Dictionary = campaign.call("current_story_event")
        var event_id := str(event.get("event_id", ""))
        var event_hud := shell.get_node_or_null("W23WorldEventHud")
        _expect(event_hud != null, "R01 capture story HUD missing")
        if event_hud != null:
            var event_snapshot: Dictionary = event_hud.call("event_snapshot")
            _expect(str(event_snapshot.get("event_id", "")) == event_id and not event_id.is_empty(), "R01 capture story HUD is not showing the real pending event")
        _assert_readability(shell, viewport_size, "story")
        _save_capture(viewport, "%s/story-%dx%d.png" % [OUTPUT_DIR, viewport_size.x, viewport_size.y], viewport_size, "story")

        _expect(bool(shell.call("select_world_choice", 0)), "R01 capture could not resolve real story choice")
        await process_frame
        _expect(bool(shell.call("select_world_choice", 0)), "R01 capture could not start next real expedition")
        await process_frame
        _expect(str(shell.get("shell_mode")) == "EXPEDITION", "R01 capture next real expedition did not start")
        print("R01_CAPTURE_%dx%d=PASS" % [viewport_size.x, viewport_size.y])

        viewport.queue_free()
        await process_frame
        await process_frame
        _clear_save(test_root)

    _finish()


func _assert_readability(shell: Node, viewport_size: Vector2i, state: String) -> void:
    var subtitle := shell.get_node_or_null("SafeArea/Content/Subtitle") as Label
    var status := shell.get_node_or_null("SafeArea/Content/Status") as Label
    _expect(subtitle != null, "R01 %s subtitle label missing" % state)
    _expect(status != null, "R01 %s status label missing" % state)
    if subtitle != null:
        var subtitle_font: Font = subtitle.get_theme_font("font")
        _expect(subtitle_font != null and subtitle_font.has_char(KOREAN_PROBE_CODEPOINT), "R01 %s resolved font lacks Korean glyph U+C794" % state)
    if status != null:
        var status_font: Font = status.get_theme_font("font")
        _expect(status_font != null and status_font.has_char(KOREAN_PROBE_CODEPOINT), "R01 %s status font lacks Korean glyph U+C794" % state)
        _expect(int(status.autowrap_mode) != 0, "R01 %s status autowrap is disabled" % state)
        var max_status_width := float(viewport_size.x) - SAFE_AREA_MARGIN_TOTAL + 1.0
        _expect(status.size.x <= max_status_width, "R01 %s status exceeds safe-area width: %.1f > %.1f" % [state, status.size.x, max_status_width])


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


func _save_capture(viewport: SubViewport, path: String, expected_size: Vector2i, label: String) -> bool:
    var image: Image = viewport.get_texture().get_image()
    if image == null or image.get_width() != expected_size.x or image.get_height() != expected_size.y:
        var actual := Vector2i.ZERO if image == null else Vector2i(image.get_width(), image.get_height())
        _failures.append("R01 %s capture size mismatch expected=%dx%d actual=%dx%d" % [label, expected_size.x, expected_size.y, actual.x, actual.y])
        return false
    var save_error := image.save_png(ProjectSettings.globalize_path(path))
    if save_error != OK:
        _failures.append("R01 %s capture save failed: %d" % [label, save_error])
        return false
    print("R01_CAPTURE_SHA256_%s_%dx%d=%s" % [label, expected_size.x, expected_size.y, FileAccess.get_sha256(path)])
    return true


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _finish() -> void:
    if _failures.is_empty():
        print("R01_KOREAN_GLYPH_FONT=PASS")
        print("R01_STATUS_WRAPPING=PASS")
        print("R01_REVIEW_IMAGE_COUNT=6")
        print("R01_REAL_PLAY_CAPTURE=PASS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("R01_CAPTURE_FAIL: %s" % failure)
    printerr("R01_REAL_PLAY_CAPTURE=FAIL")
    quit(1)


func _clear_save(test_root: String) -> void:
    for slot in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, test_root)
