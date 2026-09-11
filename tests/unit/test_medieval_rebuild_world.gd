extends RefCounted

const PhaseBattlefieldModelScript = preload("res://game/world/phase_battlefield_model.gd")
const MedievalWorldLayoutScript = preload("res://game/world/medieval_world_layout.gd")
const MainShellScene = preload("res://game/ui/main_shell.tscn")

static func run() -> Array[String]:
    var failures: Array[String] = []

    var bounds: Rect2 = PhaseBattlefieldModelScript.WORLD_BOUNDS
    if bounds != MedievalWorldLayoutScript.WORLD_BOUNDS:
        failures.append("R04 gameplay battlefield bounds drifted from the medieval authority layout")
    if bounds.size.x < 1280.0 * 4.0 or bounds.size.y < 720.0 * 4.0:
        failures.append("R03 world bounds do not span several 1280x720 viewports")

    var terrain = PhaseBattlefieldModelScript.new()
    if not terrain.is_position_walkable(PhaseBattlefieldModelScript.PHASE_MATERIAL, Vector2(-2400.0, -1600.0)):
        failures.append("R03 multi-screen northwest field is not walkable")
    if not terrain.is_position_walkable(PhaseBattlefieldModelScript.PHASE_MATERIAL, Vector2(2600.0, 1800.0)):
        failures.append("R03 multi-screen southeast field is not walkable")
    var outside_world := bounds.position - Vector2.ONE
    if terrain.is_position_walkable(PhaseBattlefieldModelScript.PHASE_MATERIAL, outside_world):
        failures.append("R03 world boundary no longer rejects positions outside the field")

    for blocked_position in [
        MedievalWorldLayoutScript.CHAPEL_GAMEPLAY_POSITION,
        MedievalWorldLayoutScript.HAMLET_GAMEPLAY_POINTS[0],
        MedievalWorldLayoutScript.HAMLET_GAMEPLAY_POINTS[1],
        MedievalWorldLayoutScript.HAMLET_GAMEPLAY_POINTS[2],
    ]:
        if terrain.is_position_walkable(PhaseBattlefieldModelScript.PHASE_MATERIAL, blocked_position):
            failures.append("R04 visible building footprint is walkable in material gameplay: %s" % blocked_position)
        if terrain.is_position_walkable(PhaseBattlefieldModelScript.PHASE_SHADOW, blocked_position):
            failures.append("R04 visible building footprint is walkable in shadow gameplay: %s" % blocked_position)
    if not terrain.is_position_walkable(PhaseBattlefieldModelScript.PHASE_MATERIAL, MedievalWorldLayoutScript.BRIDGE_GAMEPLAY_POSITION):
        failures.append("R04 central bridge/ford stopped being a passable gameplay corridor")

    var blocked_spawn := Vector2(0.0, 620.0)
    if MedievalWorldLayoutScript.is_spawn_position_allowed(blocked_spawn):
        failures.append("R04 visual river surface is still accepted as a spawn position")
    var resolved_spawn: Vector2 = terrain.resolve_spawn_position(blocked_spawn, Vector2.ZERO)
    if not terrain.is_spawn_position_allowed(resolved_spawn):
        failures.append("R04 authoritative spawn resolver did not return legal terrain")
    if resolved_spawn.is_equal_approx(blocked_spawn):
        failures.append("R04 authoritative spawn resolver did not move a river-surface spawn")
    if resolved_spawn.distance_to(Vector2.ZERO) < MedievalWorldLayoutScript.MIN_SPAWN_DISTANCE_FROM_ORIGIN:
        failures.append("R04 spawn resolver moved the spawn inside the minimum player clearance")

    var shell = MainShellScene.instantiate()
    if shell == null:
        failures.append("R03 main shell could not be instantiated")
        return failures
    var shell_script: Script = shell.get_script()
    if shell_script == null or shell_script.resource_path != "res://game/ui/main_shell_medieval_rebuild.gd":
        failures.append("R03 main shell is not using the medieval rebuild camera adapter")
    if not shell.get_node_or_null("ScreenUI") is CanvasLayer:
        failures.append("R03 fixed HUD is not isolated in a CanvasLayer")
    for path in ["ScreenUI/SafeArea", "ScreenUI/W13RepresentativeHud", "ScreenUI/W23WeaponRelicHud", "ScreenUI/W23WorldEventHud", "ScreenUI/W15FirstExpeditionTutorial", "ScreenUI/W16CharacterTutorial", "ScreenUI/W25MobileControls"]:
        if shell.get_node_or_null(path) == null:
            failures.append("R03 missing fixed screen-space node: %s" % path)
    if shell.get_node_or_null("W13Environment") == null or shell.get_node_or_null("W13RepresentativeArt") == null:
        failures.append("R03 world-space presentation nodes were incorrectly moved into screen UI")

    if not shell.get_node_or_null("WorldPresentation") is SubViewportContainer:
        failures.append("R04 3D world presentation is not mounted through a SubViewportContainer")
    if not shell.get_node_or_null("WorldPresentation/SubViewport") is SubViewport:
        failures.append("R04 3D world presentation is missing its SubViewport")
    var field := shell.get_node_or_null("WorldPresentation/SubViewport/MedievalField3D")
    if not field is Node3D or not field.has_method("presentation_spec"):
        failures.append("R04 medieval field presentation contract is missing")
    else:
        var spec: Dictionary = field.call("presentation_spec")
        if not bool(spec.get("asset_backed", false)):
            failures.append("R04 medieval field is not asset-backed")
        if str(spec.get("asset_path", "")) != "res://assets/third_party/kaykit_medieval_hexagon/terrain/hex_grass.gltf":
            failures.append("R04 medieval field is not using the admitted KayKit terrain asset")
        if spec.get("world_size_gameplay", Vector2.ZERO) != MedievalWorldLayoutScript.WORLD_BOUNDS.size:
            failures.append("R04 3D field size drifted from authoritative 2D world bounds")
        var wayfinding_centers: Array = spec.get("wayfinding_landmark_centers_gameplay", [])
        for center in MedievalWorldLayoutScript.WAYFINDING_LANDMARK_CENTERS:
            if not wayfinding_centers.has(center):
                failures.append("R04 3D wayfinding landmark drifted from authoritative gameplay coordinate: %s" % center)
        if int(spec.get("terrain_instances", 0)) < 2000:
            failures.append("R04 terrain coverage is too small for the mapped world")
        var nature_paths: Array = spec.get("nature_asset_paths", [])
        for nature_path in ["res://assets/third_party/kaykit_medieval_hexagon/nature/tree_single_A.gltf", "res://assets/third_party/kaykit_medieval_hexagon/nature/rock_single_A.gltf"]:
            if not nature_paths.has(nature_path):
                failures.append("R04 missing admitted nature asset: %s" % nature_path)
        if int(spec.get("tree_instances", 0)) < 72 or int(spec.get("rock_instances", 0)) < 24:
            failures.append("R04 nature depth layer is too sparse")
        if int(spec.get("nature_clusters", 0)) < 14 or int(spec.get("spawn_area_forest_clusters", 0)) < 4 or int(spec.get("spawn_area_rock_clusters", 0)) < 2:
            failures.append("R04 nature landmarks do not cover the initial and multi-screen field")

        var landmark_paths: Array = spec.get("landmark_asset_paths", [])
        var required_landmark_paths := [
            "res://assets/third_party/kaykit_medieval_hexagon/landmarks/blue/building_home_A_blue.gltf",
            "res://assets/third_party/kaykit_medieval_hexagon/landmarks/blue/building_church_blue.gltf",
            "res://assets/third_party/kaykit_medieval_hexagon/landmarks/neutral/building_bridge_A.gltf",
            "res://assets/third_party/kaykit_medieval_hexagon/terrain/roads/hex_road_A.gltf",
            "res://assets/third_party/kaykit_medieval_hexagon/terrain/rivers/hex_river_A.gltf",
            "res://assets/third_party/kaykit_medieval_hexagon/terrain/rivers/hex_river_crossing_A.gltf",
            "res://assets/third_party/kaykit_medieval_hexagon/terrain/elevation/hex_grass_sloped_high.gltf",
        ]
        for asset_path in required_landmark_paths:
            if not landmark_paths.has(asset_path):
                failures.append("R04 missing admitted landmark/route asset: %s" % asset_path)
        var landmark_types: Array = spec.get("landmark_types", [])
        for landmark_type in ["chapel", "hamlet", "bridge", "road", "river", "elevated_ridge"]:
            if not landmark_types.has(landmark_type):
                failures.append("R04 missing wayfinding landmark type: %s" % landmark_type)
        if int(spec.get("road_instances", 0)) < 17 or int(spec.get("river_instances", 0)) < 17:
            failures.append("R04 route composition is too short for multi-screen direction")
        if int(spec.get("building_instances", 0)) < 5 or int(spec.get("elevation_instances", 0)) < 8:
            failures.append("R04 architectural/elevation landmarks are too sparse")
        if int(spec.get("wayfinding_landmarks", 0)) < 4 or int(spec.get("spawn_area_wayfinding_landmarks", 0)) < 3:
            failures.append("R04 wayfinding anchors are too sparse")
        if str(spec.get("route_pattern", "")) != "crossroads_river_ford":
            failures.append("R04 route composition does not expose the crossroads/ford pattern")
        if float(spec.get("clear_corridor_width_gameplay", 0.0)) < MedievalWorldLayoutScript.CLEAR_CORRIDOR_WIDTH_GAMEPLAY or not bool(spec.get("river_crossing_passable_visual", false)):
            failures.append("R04 route composition does not preserve a broad readable crossing")

        var depth_cues: Array = spec.get("depth_cues", [])
        for cue in ["height", "cast_shadows", "camera-relative parallax", "cluster silhouette", "architectural scale", "elevation break"]:
            if not depth_cues.has(cue):
                failures.append("R04 missing 2.5D depth cue: %s" % cue)
        if bool(spec.get("authoritative_gameplay", true)):
            failures.append("R04 visual 3D layer incorrectly became gameplay-authoritative")
    shell.free()

    return failures
