extends SceneTree

const MedievalWorldLayoutScript = preload("res://game/world/medieval_world_layout.gd")

const OUTPUT_DIR := "res://artifacts/w04"
const SHELL_OUTPUT := "res://artifacts/w04/main-shell.png"
const FIELD_OUTPUT := "res://artifacts/w04/field-3d.png"
const WAYPOINT_OUTPUTS := [
    "res://artifacts/w04/field-waypoint-01-bridge.png",
    "res://artifacts/w04/field-waypoint-02-chapel.png",
    "res://artifacts/w04/field-waypoint-03-ridge.png",
]
const EXPECTED_SIZE := Vector2i(1280, 720)
const SETTLE_FRAMES := 12
const WAYPOINT_SETTLE_FRAMES := 8
const MIN_WAYPOINT_SEPARATION := 1200.0

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
    var combat_preview := scene.get("combat_preview") as Node2D
    if field_viewport == null:
        printerr("W04_RENDER=FAIL_FIELD_VIEWPORT")
        quit(3)
        return
    if combat_preview == null:
        printerr("W04_RENDER=FAIL_COMBAT_PREVIEW")
        quit(4)
        return
    var combat_camera := combat_preview.get_node_or_null("CombatCamera") as Camera2D
    if combat_camera == null or not combat_camera.enabled:
        printerr("W04_RENDER=FAIL_COMBAT_CAMERA")
        quit(5)
        return

    combat_preview.set_process(false)
    combat_preview.set_physics_process(false)

    var output_dir_absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
    if DirAccess.make_dir_recursive_absolute(output_dir_absolute) != OK:
        printerr("W04_RENDER=FAIL_DIRECTORY")
        quit(6)
        return

    var waypoints := [
        MedievalWorldLayoutScript.BRIDGE_GAMEPLAY_POSITION,
        MedievalWorldLayoutScript.CHAPEL_GAMEPLAY_POSITION + Vector2(-340.0, 220.0),
        MedievalWorldLayoutScript.RIDGE_WAYFINDING_CENTER,
    ]
    var max_waypoint_separation := 0.0
    for first_index in range(waypoints.size()):
        for second_index in range(first_index + 1, waypoints.size()):
            max_waypoint_separation = maxf(
                max_waypoint_separation,
                waypoints[first_index].distance_to(waypoints[second_index])
            )
    if max_waypoint_separation < MIN_WAYPOINT_SEPARATION:
        printerr("W04_RENDER=FAIL_WAYPOINT_SEPARATION")
        quit(7)
        return

    var waypoint_hashes: Array[String] = []
    for index in range(waypoints.size()):
        var waypoint: Vector2 = waypoints[index]
        combat_preview.global_position = waypoint
        var model: Variant = combat_preview.get("model")
        if model != null:
            model.set("position", waypoint)
        if scene.has_method("_sync_medieval_presentation"):
            scene.call("_sync_medieval_presentation")
        for _frame in range(WAYPOINT_SETTLE_FRAMES):
            await process_frame
        if not combat_camera.global_position.is_equal_approx(waypoint):
            printerr("W04_RENDER=FAIL_CAMERA_WAYPOINT_%d" % (index + 1))
            quit(8)
            return

        var field_image: Image = field_viewport.get_texture().get_image()
        if not _has_expected_size(field_image):
            printerr("W04_RENDER=FAIL_FIELD_SIZE_%d" % (index + 1))
            quit(9)
            return
        var waypoint_output: String = WAYPOINT_OUTPUTS[index]
        if field_image.save_png(ProjectSettings.globalize_path(waypoint_output)) != OK:
            printerr("W04_RENDER=FAIL_WAYPOINT_SAVE_%d" % (index + 1))
            quit(10)
            return
        waypoint_hashes.append(FileAccess.get_sha256(waypoint_output))
        print("W04_WAYPOINT_%d_POSITION=%.1f,%.1f" % [index + 1, waypoint.x, waypoint.y])
        print("W04_WAYPOINT_%d_SHA256=%s" % [index + 1, waypoint_hashes[index]])

        if index == 0:
            var shell_image: Image = root.get_texture().get_image()
            if not _has_expected_size(shell_image):
                printerr("W04_RENDER=FAIL_SHELL_SIZE")
                quit(11)
                return
            if shell_image.save_png(ProjectSettings.globalize_path(SHELL_OUTPUT)) != OK:
                printerr("W04_RENDER=FAIL_SHELL_SAVE")
                quit(12)
                return
            if field_image.save_png(ProjectSettings.globalize_path(FIELD_OUTPUT)) != OK:
                printerr("W04_RENDER=FAIL_FIELD_SAVE")
                quit(13)
                return

    var distinct_hashes: Dictionary = {}
    for hash_value in waypoint_hashes:
        distinct_hashes[hash_value] = true
    if distinct_hashes.size() != waypoints.size():
        printerr("W04_RENDER=FAIL_WAYPOINT_HASH_COLLISION")
        quit(14)
        return

    print("W04_RENDER=PASS")
    print("W04_RENDER_SIZE=%dx%d" % [EXPECTED_SIZE.x, EXPECTED_SIZE.y])
    print("W04_WAYPOINT_RENDER_COUNT=%d" % waypoints.size())
    print("W04_WAYPOINT_MAX_SEPARATION=%.1f" % max_waypoint_separation)
    print("W04_WAYPOINT_HASHES_DISTINCT=PASS")
    print("W04_SHELL_SHA256=%s" % FileAccess.get_sha256(SHELL_OUTPUT))
    print("W04_FIELD_SHA256=%s" % FileAccess.get_sha256(FIELD_OUTPUT))
    scene.queue_free()
    await process_frame
    quit(0)

func _has_expected_size(image: Image) -> bool:
    return image != null and image.get_width() == EXPECTED_SIZE.x and image.get_height() == EXPECTED_SIZE.y
