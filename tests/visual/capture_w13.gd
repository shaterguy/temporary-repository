extends SceneTree

const OUTPUT_DIR := "res://artifacts/w13"
const OUTPUT_PATH := "res://artifacts/w13/representative-art.png"
const EXPECTED_SIZE := Vector2i(1280, 720)


func _initialize() -> void:
    call_deferred("_capture")


func _capture() -> void:
    root.size = EXPECTED_SIZE
    var packed_resource: Resource = load("res://game/presentation/w13_showcase.tscn")
    if not packed_resource is PackedScene:
        printerr("W13_RENDER=FAIL_SCENE")
        quit(2)
        return
    var packed_scene: PackedScene = packed_resource as PackedScene
    var scene: Node = packed_scene.instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame
    await process_frame
    await process_frame
    var image: Image = root.get_texture().get_image()
    if image == null or image.get_width() != EXPECTED_SIZE.x or image.get_height() != EXPECTED_SIZE.y:
        printerr("W13_RENDER=FAIL_SIZE")
        quit(3)
        return
    var output_dir_absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
    if DirAccess.make_dir_recursive_absolute(output_dir_absolute) != OK:
        printerr("W13_RENDER=FAIL_DIRECTORY")
        quit(4)
        return
    var output_absolute := ProjectSettings.globalize_path(OUTPUT_PATH)
    var save_error := image.save_png(output_absolute)
    if save_error != OK:
        printerr("W13_RENDER=FAIL_SAVE_%d" % save_error)
        quit(5)
        return
    print("W13_RENDER=PASS")
    print("W13_RENDER_SIZE=%dx%d" % [image.get_width(), image.get_height()])
    print("W13_RENDER_SHA256=%s" % FileAccess.get_sha256(OUTPUT_PATH))
    quit(0)
