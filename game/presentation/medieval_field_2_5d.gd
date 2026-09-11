class_name MedievalField25D
extends Node3D

const GRASS_TILE_SCENE: PackedScene = preload("res://assets/third_party/kaykit_medieval_hexagon/terrain/hex_grass.gltf")
const TREE_SCENE: PackedScene = preload("res://assets/third_party/kaykit_medieval_hexagon/nature/tree_single_A.gltf")
const ROCK_SCENE: PackedScene = preload("res://assets/third_party/kaykit_medieval_hexagon/nature/rock_single_A.gltf")
const WorldProjection25D = preload("res://game/presentation/world_projection_2_5d.gd")

const WORLD_BOUNDS_GAMEPLAY := Rect2(Vector2(-4608.0, -3072.0), Vector2(9216.0, 6144.0))
const TILE_COLUMNS := 62
const TILE_ROWS := 36
const TILE_SPACING_X := 1.5
const TILE_SPACING_Z := 1.7320508
const CAMERA_OFFSET := Vector3(0.0, 18.0, 14.0)
const CAMERA_ORTHO_SIZE := 14.0
const TREES_PER_CLUSTER := 9
const ROCKS_PER_CLUSTER := 4
const NATURE_VISIBILITY_RANGE := 58.0

const FOREST_CLUSTER_CENTERS := [
    Vector2(-3300.0, -2100.0),
    Vector2(-1800.0, -2450.0),
    Vector2(450.0, -2350.0),
    Vector2(2850.0, -1850.0),
    Vector2(-3000.0, 1950.0),
    Vector2(-700.0, 2400.0),
    Vector2(1650.0, 2150.0),
    Vector2(3350.0, 1250.0),
]

const ROCK_CLUSTER_CENTERS := [
    Vector2(-3850.0, -450.0),
    Vector2(-2200.0, 650.0),
    Vector2(-350.0, -1450.0),
    Vector2(900.0, 1350.0),
    Vector2(2450.0, 250.0),
    Vector2(3900.0, -900.0),
]

var _camera: Camera3D

func _ready() -> void:
    _build_terrain()
    _build_nature_landmarks()
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

func presentation_spec() -> Dictionary:
    return {
        "asset_path": "res://assets/third_party/kaykit_medieval_hexagon/terrain/hex_grass.gltf",
        "nature_asset_paths": [
            "res://assets/third_party/kaykit_medieval_hexagon/nature/tree_single_A.gltf",
            "res://assets/third_party/kaykit_medieval_hexagon/nature/rock_single_A.gltf",
        ],
        "asset_backed": true,
        "rendering": "MultiMesh terrain + PackedScene nature",
        "terrain_instances": TILE_COLUMNS * TILE_ROWS,
        "tree_instances": FOREST_CLUSTER_CENTERS.size() * TREES_PER_CLUSTER,
        "rock_instances": ROCK_CLUSTER_CENTERS.size() * ROCKS_PER_CLUSTER,
        "nature_clusters": FOREST_CLUSTER_CENTERS.size() + ROCK_CLUSTER_CENTERS.size(),
        "world_size_gameplay": WORLD_BOUNDS_GAMEPLAY.size,
        "world_size_meters": WorldProjection25D.gameplay_size_to_world(WORLD_BOUNDS_GAMEPLAY.size),
        "camera_projection": "orthogonal_3d",
        "camera_sync_source": "CombatCamera",
        "depth_cues": ["height", "cast_shadows", "camera-relative parallax", "cluster silhouette"],
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
            var radius := 120.0 + float((tree_index * 73 + cluster_index * 41) % 260)
            var gameplay_position := center + Vector2(cos(angle), sin(angle)) * radius
            var tree := TREE_SCENE.instantiate()
            tree.name = "Forest_%02d_Tree_%02d" % [cluster_index, tree_index]
            tree.position = WorldProjection25D.gameplay_to_world3d(gameplay_position, 0.02)
            tree.rotation.y = angle * 0.61
            var scale_variation := 0.9 + float((tree_index + cluster_index * 2) % 5) * 0.07
            tree.scale = Vector3.ONE * scale_variation
            _configure_nature_geometry(tree)
            nature_root.add_child(tree)

    for cluster_index in range(ROCK_CLUSTER_CENTERS.size()):
        var center: Vector2 = ROCK_CLUSTER_CENTERS[cluster_index]
        for rock_index in range(ROCKS_PER_CLUSTER):
            var angle := float(rock_index) * TAU / float(ROCKS_PER_CLUSTER) + float(cluster_index) * 0.53
            var radius := 70.0 + float((rock_index * 61 + cluster_index * 29) % 170)
            var gameplay_position := center + Vector2(cos(angle), sin(angle)) * radius
            var rock := ROCK_SCENE.instantiate()
            rock.name = "Rock_%02d_%02d" % [cluster_index, rock_index]
            rock.position = WorldProjection25D.gameplay_to_world3d(gameplay_position, 0.015)
            rock.rotation.y = angle
            var scale_variation := 2.4 + float((rock_index + cluster_index) % 4) * 0.38
            rock.scale = Vector3.ONE * scale_variation
            _configure_nature_geometry(rock)
            nature_root.add_child(rock)

func _configure_nature_geometry(node: Node) -> void:
    if node is GeometryInstance3D:
        var geometry := node as GeometryInstance3D
        geometry.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
        geometry.visibility_range_end = NATURE_VISIBILITY_RANGE
        geometry.visibility_range_end_margin = 5.0
    for child in node.get_children():
        _configure_nature_geometry(child)

func _build_environment() -> void:
    var environment := Environment.new()
    environment.background_mode = Environment.BG_COLOR
    environment.background_color = Color(0.055, 0.075, 0.095, 1.0)
    environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
    environment.ambient_light_color = Color(0.58, 0.67, 0.78, 1.0)
    environment.ambient_light_energy = 0.72
    var world_environment := WorldEnvironment.new()
    world_environment.name = "MedievalWorldEnvironment"
    world_environment.environment = environment
    add_child(world_environment)
    var key_light := DirectionalLight3D.new()
    key_light.name = "MoonKeyLight"
    key_light.rotation_degrees = Vector3(-58.0, -32.0, 0.0)
    key_light.light_color = Color(0.86, 0.91, 1.0, 1.0)
    key_light.light_energy = 1.15
    key_light.shadow_enabled = true
    key_light.directional_shadow_max_distance = 52.0
    add_child(key_light)

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
