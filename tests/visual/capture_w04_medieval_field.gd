extends SceneTree

const OUTPUT_DIR := "res://artifacts/w04"
const SHELL_OUTPUT := "res://artifacts/w04/main-shell.png"
const FIELD_OUTPUT := "res://artifacts/w04/field-3d.png"
const EXPECTED_SIZE := Vector2i(1280, 720)
const SETTLE_FRAMES := 12

func _initialize() -> void:
    call_deferred("_capture")

func _capture() -> void:
    root.size = EXPECTED_SIZE
    var packed_resource: Resource = load("res://game/ui/main_shell.tscn")
    if not packed_resource is PackedScene:
        printerr("W04_RENDER=FAIL_SCENE")
        quit(2)
        return
    var scene: Node = (packed_resource as PackedScene).instantiate()
    root.add_child(scene)
    for _frame in range(SETTLE_FRAMES):
        await process_frame

    var field_viewport := scene.get_node_or_null("WorldPresentation/SubViewport") as SubViewport
    if field_viewport == null:
        printerr("W04_RENDER=FAIL_FIELD_VIEWPORT")
        quit(3)
        return

    var shell_image: Image = root.get_texture().get_image()
    var field_image: Image = field_viewport.get_texture().get_image()
    if not _has_expected_size(shell_image) or not _has_expected_size(field_image):
        printerr("W04_RENDER=FAIL_SIZE")
        quit(4)
        return

    var output_dir_absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
    if DirAccess.make_dir_recursive_absolute(output_dir_absolute) != OK:
        printerr("W04_RENDER=FAIL_DIRECTORY")
        quit(5)
        return
    if shell_image.save_png(ProjectSettings.globalize_path(SHELL_OUTPUT)) != OK:
        printerr("W04_RENDER=FAIL_SHELL_SAVE")
        quit(6)
        return
    if field_image.save_png(ProjectSettings.globalize_path(FIELD_OUTPUT)) != OK:
        printerr("W04_RENDER=FAIL_FIELD_SAVE")
        quit(7)
        return

    print("W04_RENDER=PASS")
    print("W04_RENDER_SIZE=%dx%d" % [EXPECTED_SIZE.x, EXPECTED_SIZE.y])
    print("W04_SHELL_SHA256=%s" % FileAccess.get_sha256(SHELL_OUTPUT))
    print("W04_FIELD_SHA256=%s" % FileAccess.get_sha256(FIELD_OUTPUT))
    scene.queue_free()
    await process_frame
    quit(0)

func _has_expected_size(image: Image) -> bool:
    return image != null and image.get_width() == EXPECTED_SIZE.x and image.get_height() == EXPECTED_SIZE.y
