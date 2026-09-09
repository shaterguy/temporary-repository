extends SceneTree

const OUTPUT_DIR := "res://artifacts/w23d"
const VIEWPORT_MATRIX := [
    Vector2i(1280, 720),
    Vector2i(1920, 1080),
    Vector2i(2340, 1080),
    Vector2i(2640, 1080),
]


func _initialize() -> void:
    call_deferred("_capture")


func _capture() -> void:
    var packed_resource: Resource = load("res://game/ui/main_shell.tscn")
    if not packed_resource is PackedScene:
        printerr("W23D_CAPTURE=FAIL_SCENE")
        quit(2)
        return
    var output_dir_absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
    if DirAccess.make_dir_recursive_absolute(output_dir_absolute) != OK:
        printerr("W23D_CAPTURE=FAIL_DIRECTORY")
        quit(3)
        return

    for viewport_size: Vector2i in VIEWPORT_MATRIX:
        root.size = viewport_size
        var shell: Node = (packed_resource as PackedScene).instantiate()
        root.add_child(shell)
        await process_frame
        await process_frame
        shell.set_process(false)
        shell.set("selected_weapon_id", "shade_halo")
        shell.set("shell_mode", "EXPEDITION")
        var event_hud := shell.get_node_or_null("W23WorldEventHud")
        if event_hud != null:
            event_hud.call("clear_event")
        await process_frame
        await process_frame
        var combat_path := "%s/combat-%dx%d.png" % [OUTPUT_DIR, viewport_size.x, viewport_size.y]
        if not _save_capture(combat_path, viewport_size):
            shell.queue_free()
            quit(4)
            return

        shell.set("shell_mode", "HUB")
        if event_hud == null or not bool(event_hud.call("show_event", "ts_s01")):
            printerr("W23D_CAPTURE=FAIL_EVENT_%dx%d" % [viewport_size.x, viewport_size.y])
            shell.queue_free()
            quit(5)
            return
        event_hud.call("_process", 0.20)
        await process_frame
        await process_frame
        var story_path := "%s/story-%dx%d.png" % [OUTPUT_DIR, viewport_size.x, viewport_size.y]
        if not _save_capture(story_path, viewport_size):
            shell.queue_free()
            quit(6)
            return
        print("W23D_CAPTURE_%dx%d=PASS" % [viewport_size.x, viewport_size.y])
        shell.queue_free()
        await process_frame

    print("W23D_COMBAT_REVIEW_COUNT=4")
    print("W23D_STORY_REVIEW_COUNT=4")
    print("W23D_CAPTURE=PASS")
    quit(0)


func _save_capture(path: String, expected_size: Vector2i) -> bool:
    var image: Image = root.get_texture().get_image()
    if image == null or image.get_width() != expected_size.x or image.get_height() != expected_size.y:
        printerr("W23D_CAPTURE=FAIL_SIZE_%s" % path)
        return false
    var save_error := image.save_png(ProjectSettings.globalize_path(path))
    if save_error != OK:
        printerr("W23D_CAPTURE=FAIL_SAVE_%d_%s" % [save_error, path])
        return false
    print("W23D_CAPTURE_SHA256_%dx%d_%s=%s" % [
        expected_size.x,
        expected_size.y,
        "combat" if path.contains("combat-") else "story",
        FileAccess.get_sha256(path),
    ])
    return true
