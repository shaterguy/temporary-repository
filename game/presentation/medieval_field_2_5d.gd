class_name MedievalField25D
extends Node3D

const GRASS_TILE_SCENE: PackedScene = preload("res://assets/third_party/kaykit_medieval_hexagon/terrain/hex_grass.gltf")
const TREE_SCENE: PackedScene = preload("res://assets/third_party/kaykit_medieval_hexagon/nature/tree_single_A.gltf")
const ROCK_SCENE: PackedScene = preload("res://assets/third_party/kaykit_medieval_hexagon/nature/rock_single_A.gltf")
const HOME_SCENE: PackedScene = preload("res://assets/third_party/kaykit_medieval_hexagon/landmarks/blue/building_home_A_blue.gltf")
const CHURCH_SCENE: PackedScene = preload("res://assets/third_party/kaykit_medieval_hexagon/landmarks/blue/building_church_blue.gltf")
const BRIDGE_SCENE: PackedScene = preload("res://assets/third_party/kaykit_medieval_hexagon/landmarks/neutral/building_bridge_A.gltf")
const ROAD_SCENE: PackedScene = preload("res://assets/third_party/kaykit_medieval_hexagon/terrain/roads/hex_road_A.gltf")
const RIVER_SCENE: PackedScene = preload("res://assets/third_party/kaykit_medieval_hexagon/terrain/rivers/hex_river_A.gltf")
const RIVER_CROSSING_SCENE: PackedScene = preload("res://assets/third_party/kaykit_medieval_hexagon/terrain/rivers/hex_river_crossing_A.gltf")
const SLOPED_GRASS_SCENE: PackedScene = preload("res://assets/third_party/kaykit_medieval_hexagon/terrain/elevation/hex_grass_sloped_high.gltf")
const WorldProjection25D = preload("res://game/presentation/world_projection_2_5d.gd")

const WORLD_BOUNDS_GAMEPLAY := Rect2(Vector2(-4608.0, -3072.0), Vector2(9216.0, 6144.0))
const TILE_COLUMNS := 86
const TILE_ROWS := 50
const TILE_SPACING_X := 1.5
const TILE_SPACING_Z := 1.7320508
const CAMERA_OFFSET := Vector3(0.0, 18.0, 14.0)
const CAMERA_ORTHO_SIZE := 14.0
const TREES_PER_CLUSTER := 9
const ROCKS_PER_CLUSTER := 4
const NATURE_VISIBILITY_RANGE := 90.0
const LANDMARK_VISIBILITY_RANGE := 120.0
const CLEAR_CORRIDOR_WIDTH_GAMEPLAY := 300.0
const DEFAULT_REGION_ID := "twilight_shipyard"
const SUPPORTED_REGION_IDS := ["twilight_shipyard", "glass_garden", "flooded_archive", "ash_railway", "eclipse_fortress"]

const FOREST_CLUSTER_CENTERS := [
    Vector2(-720.0, -430.0), Vector2(760.0, -360.0), Vector2(-880.0, 690.0), Vector2(930.0, 760.0),
    Vector2(-2750.0, -1900.0), Vector2(2650.0, -1850.0), Vector2(-2450.0, 2050.0), Vector2(2750.0, 1900.0),
    Vector2(-4200.0, -1700.0), Vector2(-4200.0, -250.0), Vector2(-4200.0, 1350.0),
    Vector2(4100.0, -1650.0), Vector2(4100.0, 250.0), Vector2(4100.0, 1550.0),
    Vector2(-1800.0, -2650.0), Vector2(0.0, -2550.0), Vector2(1800.0, -2650.0),
    Vector2(-1800.0, 2550.0), Vector2(0.0, 2450.0), Vector2(1800.0, 2550.0),
]

const ROCK_CLUSTER_CENTERS := [
    Vector2(-320.0, 240.0), Vector2(420.0, -280.0), Vector2(-1500.0, -950.0),
    Vector2(1550.0, 1050.0), Vector2(-3250.0, 850.0), Vector2(3350.0, -900.0),
    Vector2(-4100.0, -700.0), Vector2(-4050.0, 900.0), Vector2(4050.0, -700.0), Vector2(4150.0, 900.0),
    Vector2(-2100.0, -2450.0), Vector2(2100.0, -2400.0), Vector2(-2000.0, 2450.0), Vector2(2200.0, 2400.0),
]

const ROAD_GAMEPLAY_POINTS := [
    Vector2(-1200.0, 0.0), Vector2(-1050.0, 0.0), Vector2(-900.0, 0.0), Vector2(-750.0, 0.0),
    Vector2(-600.0, 0.0), Vector2(-450.0, 0.0), Vector2(-300.0, 0.0), Vector2(-150.0, 0.0),
    Vector2(0.0, 0.0), Vector2(150.0, 0.0), Vector2(300.0, 0.0), Vector2(450.0, 0.0),
    Vector2(600.0, 0.0), Vector2(750.0, 0.0), Vector2(900.0, 0.0), Vector2(1050.0, 0.0), Vector2(1200.0, 0.0),
]

const RIVER_GAMEPLAY_POINTS := [
    Vector2(0.0, -1384.0), Vector2(0.0, -1211.0), Vector2(0.0, -1038.0), Vector2(0.0, -865.0),
    Vector2(0.0, -692.0), Vector2(0.0, -519.0), Vector2(0.0, -346.0), Vector2(0.0, -173.0),
    Vector2(0.0, 0.0), Vector2(0.0, 173.0), Vector2(0.0, 346.0), Vector2(0.0, 519.0),
    Vector2(0.0, 692.0), Vector2(0.0, 865.0), Vector2(0.0, 1038.0), Vector2(0.0, 1211.0), Vector2(0.0, 1384.0),
]

const HAMLET_GAMEPLAY_POINTS := [
    Vector2(720.0, 520.0), Vector2(980.0, 660.0), Vector2(820.0, 880.0),
    Vector2(3900.0, 260.0), Vector2(4150.0, 520.0),
    Vector2(-3950.0, -320.0), Vector2(-4200.0, -560.0),
    Vector2(1550.0, 2450.0), Vector2(-1550.0, -2420.0),
]

# The high-slope pieces are long-distance silhouettes, not a spawn-screen wall.
# Keeping them beyond the initial camera and at sub-unit scale avoids the large
# bright foreground blocks seen in the first W04 landmark render.
const RIDGE_GAMEPLAY_POINTS := [
    Vector2(-1050.0, 1750.0), Vector2(-750.0, 1750.0), Vector2(-450.0, 1750.0), Vector2(-150.0, 1750.0),
    Vector2(150.0, 1750.0), Vector2(450.0, 1750.0), Vector2(750.0, 1750.0), Vector2(1050.0, 1750.0),
]

const CHAPEL_GAMEPLAY_POSITION := Vector2(-760.0, -520.0)
const BRIDGE_GAMEPLAY_POSITION := Vector2.ZERO
const WAYFINDING_LANDMARK_CENTERS := [
    BRIDGE_GAMEPLAY_POSITION, CHAPEL_GAMEPLAY_POSITION, Vector2(840.0, 680.0), Vector2(-900.0, 1750.0),
    Vector2(4025.0, 390.0), Vector2(-4075.0, -440.0), Vector2(1550.0, 2450.0), Vector2(-1550.0, -2420.0),
]

var _camera: Camera3D
var _environment: Environment
var _key_light: DirectionalLight3D
var _region_id: String = DEFAULT_REGION_ID

func _ready() -> void:
    _build_terrain()
    _build_nature_landmarks()
    _build_wayfinding_landmarks()
    _build_environment()
    _build_camera()
    set_gameplay_focus(Vector2.ZERO)

func set_gameplay_focus(gameplay_position: Vector2) -> void:
    if _camera == null:
        return
    var clamped := Vector2(
        clamp(gameplay_position.x, WORLD_BOUNDS_GAMEPLAY.position.x, WORLD_BOUNDS_GAMEPLAY.end.x),
        clamp(gameplay_position.y, WORLD_BOUNDS_GAMEPLAY.position.y, WORLD_BOUNDS_GAMEPLAY.end.y)
    )
    var focus := WorldProjection25D.gameplay_to_world3d(clamped)
    _camera.position = focus + CAMERA_OFFSET
    _camera.look_at(focus, Vector3.UP)

func set_region_id(region_id: String) -> bool:
    if region_id.is_empty():
        return false
    _region_id = region_id if region_id in SUPPORTED_REGION_IDS else DEFAULT_REGION_ID
    _apply_region_environment()
    return _region_id == region_id

func presentation_spec() -> Dictionary:
    return {
        "asset_path": "res://assets/third_party/kaykit_medieval_hexagon/terrain/hex_grass.gltf",
        "nature_asset_paths": [
            "res://assets/third_party/kaykit_medieval_hexagon/nature/tree_single_A.gltf",
            "res://assets/third_party/kaykit_medieval_hexagon/nature/rock_single_A.gltf",
        ],
        "landmark_asset_paths": [
            "res://assets/third_party/kaykit_medieval_hexagon/landmarks/blue/building_home_A_blue.gltf",
            "res://assets/third_party/kaykit_medieval_hexagon/landmarks/blue/building_church_blue.gltf",
            "res://assets/third_party/kaykit_medieval_hexagon/landmarks/neutral/building_bridge_A.gltf",
            "res://assets/third_party/kaykit_medieval_hexagon/terrain/roads/hex_road_A.gltf",
            "res://assets/third_party/kaykit_medieval_hexagon/terrain/rivers/hex_river_A.gltf",
            "res://assets/third_party/kaykit_medieval_hexagon/terrain/rivers/hex_river_crossing_A.gltf",
            "res://assets/third_party/kaykit_medieval_hexagon/terrain/elevation/hex_grass_sloped_high.gltf",
        ],
        "landmark_types": ["chapel", "hamlet", "bridge", "road", "river", "elevated_ridge"],
        "asset_backed": true,
        "rendering": "MultiMesh terrain + PackedScene nature/landmarks/routes",
        "terrain_instances": TILE_COLUMNS * TILE_ROWS,
        "tree_instances": FOREST_CLUSTER_CENTERS.size() * TREES_PER_CLUSTER,
        "rock_instances": ROCK_CLUSTER_CENTERS.size() * ROCKS_PER_CLUSTER,
        "nature_clusters": FOREST_CLUSTER_CENTERS.size() + ROCK_CLUSTER_CENTERS.size(),
        "spawn_area_forest_clusters": 4,
        "spawn_area_rock_clusters": 2,
        "road_instances": ROAD_GAMEPLAY_POINTS.size(),
        "river_instances": RIVER_GAMEPLAY_POINTS.size(),
        "building_instances": HAMLET_GAMEPLAY_POINTS.size() + 2,
        "elevation_instances": RIDGE_GAMEPLAY_POINTS.size(),
        "wayfinding_landmarks": WAYFINDING_LANDMARK_CENTERS.size(),
        "wayfinding_landmark_centers_gameplay": WAYFINDING_LANDMARK_CENTERS,
        "spawn_area_wayfinding_landmarks": 3,
        "route_pattern": "crossroads_river_ford",
        "clear_corridor_width_gameplay": CLEAR_CORRIDOR_WIDTH_GAMEPLAY,
        "river_crossing_passable_visual": true,
        "world_size_gameplay": WORLD_BOUNDS_GAMEPLAY.size,
        "world_size_meters": WorldProjection25D.gameplay_size_to_world(WORLD_BOUNDS_GAMEPLAY.size),
        "camera_projection": "orthogonal_3d",
        "camera_sync_source": "CombatCamera",
        "region_id": _region_id,
        "supported_region_ids": SUPPORTED_REGION_IDS.duplicate(),
        "region_variant": "lighting_palette",
        "depth_cues": ["height", "cast_shadows", "camera-relative parallax", "cluster silhouette", "architectural scale", "elevation break"],
        "authoritative_gameplay": false,
    }

func _build_terrain() -> void:
    var source := GRASS_TILE_SCENE.instantiate()
    var source_mesh := _first_mesh_instance(source)
    if source_mesh == null or source_mesh.mesh == null:
        push_error("MedievalField25D could not resolve KayKit hex_grass mesh")
        source.free()
        return
    var multimesh := MultiMesh.new()
    multimesh.transform_format = MultiMesh.TRANSFORM_3D
    multimesh.mesh = source_mesh.mesh
    multimesh.instance_count = TILE_COLUMNS * TILE_ROWS
    var origin_x := -float(TILE_COLUMNS - 1) * TILE_SPACING_X * 0.5
    var origin_z := -float(TILE_ROWS - 1) * TILE_SPACING_Z * 0.5
    var index := 0
    for row in range(TILE_ROWS):
        var row_offset := TILE_SPACING_X * 0.5 if row % 2 == 1 else 0.0
        for column in range(TILE_COLUMNS):
            var position := Vector3(origin_x + float(column) * TILE_SPACING_X + row_offset, 0.0, origin_z + float(row) * TILE_SPACING_Z)
            multimesh.set_instance_transform(index, Transform3D(Basis.IDENTITY, position))
            index += 1
    var terrain := MultiMeshInstance3D.new()
    terrain.name = "KayKitGrassField"
    terrain.multimesh = multimesh
    terrain.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
    add_child(terrain)
    source.free()

func _build_nature_landmarks() -> void:
    var nature_root := Node3D.new()
    nature_root.name = "KayKitNatureLandmarks"
    add_child(nature_root)

    for cluster_index in range(FOREST_CLUSTER_CENTERS.size()):
        var center: Vector2 = FOREST_CLUSTER_CENTERS[cluster_index]
        for tree_index in range(TREES_PER_CLUSTER):
            var angle := float(tree_index) * TAU / float(TREES_PER_CLUSTER) + float(cluster_index) * 0.37
            var radius := 95.0 + float((tree_index * 73 + cluster_index * 41) % 220)
            var gameplay_position := center + Vector2(cos(angle), sin(angle)) * radius
            var tree := TREE_SCENE.instantiate()
            tree.name = "Forest_%02d_Tree_%02d" % [cluster_index, tree_index]
            tree.position = WorldProjection25D.gameplay_to_world3d(gameplay_position, 0.02)
            tree.rotation.y = angle * 0.61
            tree.scale = Vector3.ONE * (1.55 + float((tree_index + cluster_index * 2) % 5) * 0.12)
            _configure_geometry(tree, NATURE_VISIBILITY_RANGE)
            nature_root.add_child(tree)

    for cluster_index in range(ROCK_CLUSTER_CENTERS.size()):
        var center: Vector2 = ROCK_CLUSTER_CENTERS[cluster_index]
        for rock_index in range(ROCKS_PER_CLUSTER):
            var angle := float(rock_index) * TAU / float(ROCKS_PER_CLUSTER) + float(cluster_index) * 0.53
            var radius := 55.0 + float((rock_index * 61 + cluster_index * 29) % 135)
            var gameplay_position := center + Vector2(cos(angle), sin(angle)) * radius
            var rock := ROCK_SCENE.instantiate()
            rock.name = "Rock_%02d_%02d" % [cluster_index, rock_index]
            rock.position = WorldProjection25D.gameplay_to_world3d(gameplay_position, 0.015)
            rock.rotation.y = angle
            rock.scale = Vector3.ONE * (4.4 + float((rock_index + cluster_index) % 4) * 0.55)
            _configure_geometry(rock, NATURE_VISIBILITY_RANGE)
            nature_root.add_child(rock)

func _build_wayfinding_landmarks() -> void:
    var landmark_root := Node3D.new()
    landmark_root.name = "KayKitWayfindingLandmarks"
    add_child(landmark_root)

    for road_index in range(ROAD_GAMEPLAY_POINTS.size()):
        _spawn_landmark_scene(ROAD_SCENE, "Crossroad_%02d" % road_index, ROAD_GAMEPLAY_POINTS[road_index], 0.025, 1.0, 0.0, landmark_root)

    for river_index in range(RIVER_GAMEPLAY_POINTS.size()):
        var gameplay_position: Vector2 = RIVER_GAMEPLAY_POINTS[river_index]
        var river_scene := RIVER_CROSSING_SCENE if gameplay_position == Vector2.ZERO else RIVER_SCENE
        _spawn_landmark_scene(river_scene, "River_%02d" % river_index, gameplay_position, 0.03, 1.0, PI * 0.5, landmark_root)

    _spawn_landmark_scene(BRIDGE_SCENE, "CentralStoneBridge", BRIDGE_GAMEPLAY_POSITION, 0.075, 1.35, PI * 0.5, landmark_root)
    _spawn_landmark_scene(CHURCH_SCENE, "MoonChapel", CHAPEL_GAMEPLAY_POSITION, 0.04, 1.65, 0.28, landmark_root)

    for home_index in range(HAMLET_GAMEPLAY_POINTS.size()):
        _spawn_landmark_scene(
            HOME_SCENE, "EastHamletHome_%02d" % home_index, HAMLET_GAMEPLAY_POINTS[home_index], 0.04,
            1.45 + float(home_index) * 0.08, -0.32 + float(home_index) * 0.29, landmark_root
        )

    for ridge_index in range(RIDGE_GAMEPLAY_POINTS.size()):
        _spawn_landmark_scene(
            SLOPED_GRASS_SCENE, "NorthRidge_%02d" % ridge_index, RIDGE_GAMEPLAY_POINTS[ridge_index], 0.015,
            0.72, PI if ridge_index % 2 == 1 else 0.0, landmark_root
        )

func _spawn_landmark_scene(scene: PackedScene, node_name: String, gameplay_position: Vector2, elevation: float, uniform_scale: float, rotation_y: float, parent: Node3D) -> Node3D:
    var instance := scene.instantiate() as Node3D
    if instance == null:
        push_error("MedievalField25D could not instantiate landmark %s" % node_name)
        return null
    instance.name = node_name
    instance.position = WorldProjection25D.gameplay_to_world3d(gameplay_position, elevation)
    instance.rotation.y = rotation_y
    instance.scale = Vector3.ONE * uniform_scale
    _configure_geometry(instance, LANDMARK_VISIBILITY_RANGE)
    parent.add_child(instance)
    return instance

func _configure_geometry(node: Node, visibility_range: float) -> void:
    if node is GeometryInstance3D:
        var geometry := node as GeometryInstance3D
        geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        geometry.visibility_range_end = visibility_range
        geometry.visibility_range_end_margin = 8.0
    for child in node.get_children():
        _configure_geometry(child, visibility_range)

func _build_environment() -> void:
    _environment = Environment.new()
    _environment.background_mode = Environment.BG_COLOR
    _environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    var world_environment := WorldEnvironment.new()
    world_environment.name = "MedievalWorldEnvironment"
    world_environment.environment = _environment
    add_child(world_environment)
    _key_light = DirectionalLight3D.new()
    _key_light.name = "MoonKeyLight"
    _key_light.rotation_degrees = Vector3(-58.0, -32.0, 0.0)
    _key_light.shadow_enabled = true
    _key_light.directional_shadow_max_distance = 72.0
    add_child(_key_light)
    _apply_region_environment()

func _apply_region_environment() -> void:
    if _environment == null or _key_light == null:
        return
    match _region_id:
        "glass_garden":
            _environment.background_color = Color(0.032, 0.052, 0.066, 1.0)
            _environment.ambient_light_color = Color(0.38, 0.52, 0.62, 1.0)
            _environment.ambient_light_energy = 0.46
            _key_light.light_color = Color(0.62, 0.84, 0.96, 1.0)
            _key_light.light_energy = 0.98
        "flooded_archive":
            _environment.background_color = Color(0.010, 0.036, 0.046, 1.0)
            _environment.ambient_light_color = Color(0.20, 0.44, 0.50, 1.0)
            _environment.ambient_light_energy = 0.40
            _key_light.light_color = Color(0.44, 0.78, 0.84, 1.0)
            _key_light.light_energy = 0.88
        "ash_railway":
            _environment.background_color = Color(0.054, 0.024, 0.014, 1.0)
            _environment.ambient_light_color = Color(0.48, 0.31, 0.24, 1.0)
            _environment.ambient_light_energy = 0.44
            _key_light.light_color = Color(0.96, 0.58, 0.32, 1.0)
            _key_light.light_energy = 1.02
        "eclipse_fortress":
            _environment.background_color = Color(0.018, 0.010, 0.036, 1.0)
            _environment.ambient_light_color = Color(0.34, 0.25, 0.50, 1.0)
            _environment.ambient_light_energy = 0.39
            _key_light.light_color = Color(0.70, 0.48, 0.94, 1.0)
            _key_light.light_energy = 0.94
        _:
            _environment.background_color = Color(0.018, 0.028, 0.045, 1.0)
            _environment.ambient_light_color = Color(0.32, 0.42, 0.55, 1.0)
            _environment.ambient_light_energy = 0.42
            _key_light.light_color = Color(0.66, 0.74, 0.92, 1.0)
            _key_light.light_energy = 0.92

func _build_camera() -> void:
    _camera = Camera3D.new()
    _camera.name = "PresentationCamera3D"
    _camera.projection = Camera3D.PROJECTION_ORTHOGONAL
    _camera.size = CAMERA_ORTHO_SIZE
    _camera.current = true
    add_child(_camera)

func _first_mesh_instance(node: Node) -> MeshInstance3D:
    if node is MeshInstance3D:
        return node as MeshInstance3D
    for child in node.get_children():
        var found := _first_mesh_instance(child)
        if found != null:
            return found
    return null