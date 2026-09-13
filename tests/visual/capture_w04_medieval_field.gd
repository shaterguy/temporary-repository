extends SceneTree

const MedievalWorldLayoutScript = preload("res://game/world/medieval_world_layout.gd")

const OUTPUT_DIR := "res://artifacts/w04"
const SHELL_OUTPUT := "res://artifacts/w04/main-shell.png"
const FIELD_OUTPUT := "res://artifacts/w04/field-3d.png"
const WAYPOINT_OUTPUTS := [
    "res://artifacts/w04/field-waypoint-01-bridge.png",
    "res://artifacts/w04/field-waypoint-02-chapel.png",
    "res://artifacts/w04/field-waypoint-03-hamlet.png",
    "res://artifacts/w04/field-waypoint-04-ridge.png",
    "res://artifacts/w04/field-waypoint-05-outer-march.png",
]
const EXPECTED_SIZE := Vector2i(1280, 720)
const SETTLE_FRAMES := 12
const WAYPOINT_SETTLE_FRAMES := 8
const MIN_WAYPOINT_SEPARATION := 3000.0
const SAMPLE_STEP := 24
const SAMPLE_OFFSET := 12
const COLOR_BUCKET_LEVELS := 6
const MIN_COLOR_BUCKETS := 10
const MIN_EDGE_CONTRAST_RATIO := 0.035
const MAX_GREEN_DOMINANCE_RATIO := 0.90
const MIN_EDGE_COLOR_DELTA := 0.14

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
        MedievalWorldLayoutScript.HAMLET_WAYFINDING_CENTER,
        MedievalWorldLayoutScript.RIDGE_WAYFINDING_CENTER,
        Vector2(2750.0, 1900.0),
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
    var minimum_color_buckets := 1_000_000
    var minimum_edge_contrast := 1.0
    var maximum_green_dominance := 0.0
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

        var composition := _analyze_visual_composition(field_image)
        var color_buckets := int(composition.get("color_buckets", 0))
        var green_dominance := float(composition.get("green_dominance", 1.0))
        var edge_contrast := float(composition.get("edge_contrast", 0.0))
        minimum_color_buckets = mini(minimum_color_buckets, color_buckets)
        maximum_green_dominance = maxf(maximum_green_dominance, green_dominance)
        minimum_edge_contrast = minf(minimum_edge_contrast, edge_contrast)
        print("W04_WAYPOINT_%d_POSITION=%.1f,%.1f" % [index + 1, waypoint.x, waypoint.y])
        print("W04_WAYPOINT_%d_SHA256=%s" % [index + 1, waypoint_hashes[index]])
        print("W04_WAYPOINT_%d_COLOR_BUCKETS=%d" % [index + 1, color_buckets])
        print("W04_WAYPOINT_%d_GREEN_DOMINANCE=%.4f" % [index + 1, green_dominance])
        print("W04_WAYPOINT_%d_EDGE_CONTRAST=%.4f" % [index + 1, edge_contrast])
        if not bool(composition.get("passes", false)):
            printerr("W04_RENDER=FAIL_VISUAL_COMPOSITION_%d" % (index + 1))
            quit(15)
            return

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

    print("W04_VISUAL_MIN_COLOR_BUCKETS=%d" % minimum_color_buckets)
    print("W04_VISUAL_MIN_EDGE_CONTRAST=%.4f" % minimum_edge_contrast)
    print("W04_VISUAL_MAX_GREEN_DOMINANCE=%.4f" % maximum_green_dominance)
    print("W04_VISUAL_COMPOSITION=PASS")
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

func _analyze_visual_composition(image: Image) -> Dictionary:
    var color_buckets: Dictionary = {}
    var sample_count := 0
    var green_samples := 0
    var edge_count := 0
    var contrast_edges := 0
    for y in range(SAMPLE_OFFSET, image.get_height(), SAMPLE_STEP):
        var previous := Color.BLACK
        var has_previous := false
        for x in range(SAMPLE_OFFSET, image.get_width(), SAMPLE_STEP):
            var pixel := image.get_pixel(x, y)
            var red_bucket := clampi(int(floor(pixel.r * float(COLOR_BUCKET_LEVELS))), 0, COLOR_BUCKET_LEVELS - 1)
            var green_bucket := clampi(int(floor(pixel.g * float(COLOR_BUCKET_LEVELS))), 0, COLOR_BUCKET_LEVELS - 1)
            var blue_bucket := clampi(int(floor(pixel.b * float(COLOR_BUCKET_LEVELS))), 0, COLOR_BUCKET_LEVELS - 1)
            color_buckets["%d:%d:%d" % [red_bucket, green_bucket, blue_bucket]] = true
            if pixel.g > pixel.r * 1.18 and pixel.g > pixel.b * 1.08 and pixel.g > 0.16:
                green_samples += 1
            if has_previous:
                edge_count += 1
                var color_delta := absf(pixel.r - previous.r) + absf(pixel.g - previous.g) + absf(pixel.b - previous.b)
                if color_delta >= MIN_EDGE_COLOR_DELTA:
                    contrast_edges += 1
            previous = pixel
            has_previous = true
            sample_count += 1
    var green_dominance := float(green_samples) / maxf(float(sample_count), 1.0)
    var edge_contrast := float(contrast_edges) / maxf(float(edge_count), 1.0)
    return {
        "color_buckets": color_buckets.size(),
        "green_dominance": green_dominance,
        "edge_contrast": edge_contrast,
        "passes": (
            color_buckets.size() >= MIN_COLOR_BUCKETS
            and edge_contrast >= MIN_EDGE_CONTRAST_RATIO
            and green_dominance <= MAX_GREEN_DOMINANCE_RATIO
        ),
    }

func _has_expected_size(image: Image) -> bool:
    return image != null and image.get_width() == EXPECTED_SIZE.x and image.get_height() == EXPECTED_SIZE.y
