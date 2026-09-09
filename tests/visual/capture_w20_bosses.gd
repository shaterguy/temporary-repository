extends SceneTree

const OUTPUT_DIR := "res://artifacts/w20"
const OUTPUT_PATH := "res://artifacts/w20/boss-contact-sheet.png"
const EXPECTED_SIZE := Vector2i(1280, 720)


func _initialize() -> void:
    call_deferred("_capture")


func _capture() -> void:
    root.size = EXPECTED_SIZE
    var packed_resource: Resource = load("res://game/presentation/w20_boss_showcase.tscn")
    if not packed_resource is PackedScene:
        printerr("W20_VISUAL_CONTACT_SHEET=FAIL_SCENE")
        quit(2)
        return
    var scene: Node = (packed_resource as PackedScene).instantiate()
    root.add_child(scene)
    await process_frame
    await process_frame
    await process_frame
    await process_frame
    var image: Image = root.get_texture().get_image()
    if image == null or image.get_width() != EXPECTED_SIZE.x or image.get_height() != EXPECTED_SIZE.y:
        printerr("W20_VISUAL_CONTACT_SHEET=FAIL_SIZE")
        quit(3)
        return
    var output_dir_absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
    if DirAccess.make_dir_recursive_absolute(output_dir_absolute) != OK:
        printerr("W20_VISUAL_CONTACT_SHEET=FAIL_DIRECTORY")
        quit(4)
        return
    var save_error := image.save_png(ProjectSettings.globalize_path(OUTPUT_PATH))
    if save_error != OK:
        printerr("W20_VISUAL_CONTACT_SHEET=FAIL_SAVE_%d" % save_error)
        quit(5)
        return
    print("W20_VISUAL_CONTACT_SHEET=PASS")
    print("W20_VISUAL_CONTACT_SHEET_SIZE=%dx%d" % [image.get_width(), image.get_height()])
    print("W20_VISUAL_CONTACT_SHEET_SHA256=%s" % FileAccess.get_sha256(OUTPUT_PATH))
    print("W20_HUMAN_VISUAL_REVIEW=PENDING")
    quit(0)
