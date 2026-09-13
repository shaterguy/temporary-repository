extends SceneTree

const OUTPUT_DIR := "res://artifacts/w06"
const EXPECTED_UI_FONT_PATH: String = "res://assets/runtime/fonts/NotoSansKR-wght.ttf"
const HANGUL_PROBE := ["잔", "광", "여", "정", "슬", "롯", "선", "택"]
const VIEWPORT_MATRIX := [
    Vector2i(1280, 720),
    Vector2i(2340, 1080),
]


func _initialize() -> void:
    call_deferred("_capture")


func _capture() -> void:
    var packed_resource: Resource = load("res://game/ui/main_shell.tscn")
    if not packed_resource is PackedScene:
        printerr("W06_CAPTURE=FAIL_SCENE")
        quit(2)
        return
    var output_dir_absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
    if DirAccess.make_dir_recursive_absolute(output_dir_absolute) != OK:
        printerr("W06_CAPTURE=FAIL_DIRECTORY")
        quit(3)
        return

    var glyph_regression_checked := false
    for viewport_size: Vector2i in VIEWPORT_MATRIX:
        var viewport := SubViewport.new()
        viewport.name = "W06MenuViewport_%dx%d" % [viewport_size.x, viewport_size.y]
        viewport.size = viewport_size
        viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
        root.add_child(viewport)

        var shell: Node = (packed_resource as PackedScene).instantiate()
        viewport.add_child(shell)
        for _frame in range(8):
            await process_frame

        if not glyph_regression_checked:
            if not await _verify_rendered_hangul(shell as Control):
                viewport.queue_free()
                quit(8)
                return
            glyph_regression_checked = true

        var controls := shell.get_node_or_null("ScreenUI/SafeArea/Content/TouchChoices")
        if controls == null or not controls.has_method("force_refresh"):
            printerr("W06_CAPTURE=FAIL_CONTROLLER_%dx%d" % [viewport_size.x, viewport_size.y])
            viewport.queue_free()
            quit(4)
            return

        controls.call("force_refresh")
        await process_frame
        await process_frame
        var slot_path := "%s/slot-%dx%d.png" % [OUTPUT_DIR, viewport_size.x, viewport_size.y]
        if not _save_capture(viewport, slot_path, viewport_size):
            viewport.queue_free()
            quit(5)
            return

        shell.set("shell_mode", "HUB")
        controls.call("force_refresh")
        await process_frame
        await process_frame
        var hub_path := "%s/hub-%dx%d.png" % [OUTPUT_DIR, viewport_size.x, viewport_size.y]
        if not _save_capture(viewport, hub_path, viewport_size):
            viewport.queue_free()
            quit(6)
            return

        var slot_hash := FileAccess.get_sha256(slot_path)
        var hub_hash := FileAccess.get_sha256(hub_path)
        if slot_hash == hub_hash:
            printerr("W06_CAPTURE=FAIL_IDENTICAL_STATES_%dx%d" % [viewport_size.x, viewport_size.y])
            viewport.queue_free()
            quit(7)
            return
        print("W06_CAPTURE_%dx%d=PASS" % [viewport_size.x, viewport_size.y])
        print("W06_SLOT_SHA256_%dx%d=%s" % [viewport_size.x, viewport_size.y, slot_hash])
        print("W06_HUB_SHA256_%dx%d=%s" % [viewport_size.x, viewport_size.y, hub_hash])
        viewport.queue_free()
        await process_frame

    print("W06_CAPTURE_COUNT=4")
    print("W06_CAPTURE=PASS")
    quit(0)


func _verify_rendered_hangul(shell: Control) -> bool:
    if shell == null or shell.theme == null or shell.theme.default_font == null:
        printerr("W06_HANGUL_RENDER=FAIL_NO_FONT")
        return false
    var active_font: Font = shell.theme.default_font
    if active_font.resource_path != EXPECTED_UI_FONT_PATH:
        printerr("W06_HANGUL_RENDER=FAIL_FONT_PATH_%s" % active_font.resource_path)
        return false
    for glyph: String in HANGUL_PROBE:
        if not active_font.has_char(glyph.unicode_at(0)):
            printerr("W06_HANGUL_RENDER=FAIL_MISSING_GLYPH_%s" % glyph)
            return false

    var probe_viewport := SubViewport.new()
    probe_viewport.name = "W06HangulGlyphProbe"
    probe_viewport.size = Vector2i(128, 128)
    probe_viewport.transparent_bg = true
    probe_viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
    root.add_child(probe_viewport)

    var label := Label.new()
    label.position = Vector2.ZERO
    label.size = Vector2(128, 128)
    label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
    label.theme = shell.theme
    label.add_theme_font_size_override("font_size", 64)
    probe_viewport.add_child(label)

    var fingerprints: Dictionary = {}
    for glyph: String in HANGUL_PROBE:
        label.text = glyph
        await process_frame
        await process_frame
        var image: Image = probe_viewport.get_texture().get_image()
        if image == null or image.is_empty():
            printerr("W06_HANGUL_RENDER=FAIL_EMPTY_IMAGE_%s" % glyph)
            probe_viewport.queue_free()
            return false
        var fingerprint := image.get_data().hex_encode().sha256_text()
        fingerprints[fingerprint] = true

    probe_viewport.queue_free()
    await process_frame
    if fingerprints.size() != HANGUL_PROBE.size():
        printerr("W06_HANGUL_RENDER=FAIL_TOFU_FINGERPRINT_%d_OF_%d" % [fingerprints.size(), HANGUL_PROBE.size()])
        return false
    print("W06_HANGUL_FONT_PATH=%s" % EXPECTED_UI_FONT_PATH)
    print("W06_HANGUL_RENDER_UNIQUE=%d" % fingerprints.size())
    print("W06_HANGUL_RENDER_FINGERPRINT=PASS")
    return true


func _save_capture(viewport: SubViewport, path: String, expected_size: Vector2i) -> bool:
    var image: Image = viewport.get_texture().get_image()
    if image == null or image.get_width() != expected_size.x or image.get_height() != expected_size.y:
        var actual := Vector2i.ZERO if image == null else Vector2i(image.get_width(), image.get_height())
        printerr("W06_CAPTURE=FAIL_SIZE_%s_EXPECTED_%dx%d_ACTUAL_%dx%d" % [
            path,
            expected_size.x,
            expected_size.y,
            actual.x,
            actual.y,
        ])
        return false
    var save_error := image.save_png(ProjectSettings.globalize_path(path))
    if save_error != OK:
        printerr("W06_CAPTURE=FAIL_SAVE_%d_%s" % [save_error, path])
        return false
    return true
