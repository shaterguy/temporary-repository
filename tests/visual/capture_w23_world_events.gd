extends SceneTree

const OUTPUT_DIR := "res://artifacts/w23"
const ENEMY_REGION_PATH := "res://artifacts/w23/enemy-region-review.png"
const EVENT_PATH := "res://artifacts/w23/choice-event-review.png"
const EXPECTED_SIZE := Vector2i(1280, 720)


func _initialize() -> void:
    call_deferred("_capture")


func _capture() -> void:
    root.size = EXPECTED_SIZE
    var packed_resource: Resource = load("res://game/presentation/w23_world_event_showcase.tscn")
    if not packed_resource is PackedScene:
        printerr("W23C_REVIEW_CAPTURE=FAIL_SCENE")
        quit(2)
        return
    var scene: Node = (packed_resource as PackedScene).instantiate()
    root.add_child(scene)
    scene.call("set_page", "enemy_region")
    await process_frame
    await process_frame
    await process_frame
    if not _save_capture(ENEMY_REGION_PATH):
        quit(3)
        return
    print("W23C_ENEMY_REGION_REVIEW=PASS")
    print("W23C_ENEMY_REGION_REVIEW_SHA256=%s" % FileAccess.get_sha256(ENEMY_REGION_PATH))

    scene.call("set_page", "events")
    await process_frame
    await process_frame
    await process_frame
    if not _save_capture(EVENT_PATH):
        quit(4)
        return
    print("W23C_CHOICE_EVENT_REVIEW=PASS")
    print("W23C_CHOICE_EVENT_REVIEW_SHA256=%s" % FileAccess.get_sha256(EVENT_PATH))
    print("W23C_REVIEW_SIZE=%dx%d" % [EXPECTED_SIZE.x, EXPECTED_SIZE.y])
    quit(0)


func _save_capture(path: String) -> bool:
    var image: Image = root.get_texture().get_image()
    if image == null or image.get_width() != EXPECTED_SIZE.x or image.get_height() != EXPECTED_SIZE.y:
        printerr("W23C_REVIEW_CAPTURE=FAIL_SIZE_%s" % path)
        return false
    var output_dir_absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
    if DirAccess.make_dir_recursive_absolute(output_dir_absolute) != OK:
        printerr("W23C_REVIEW_CAPTURE=FAIL_DIRECTORY")
        return false
    var save_error := image.save_png(ProjectSettings.globalize_path(path))
    if save_error != OK:
        printerr("W23C_REVIEW_CAPTURE=FAIL_SAVE_%d" % save_error)
        return false
    return true
