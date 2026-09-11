extends RefCounted

const PhaseBattlefieldModelScript = preload("res://game/world/phase_battlefield_model.gd")
const MainShellScene = preload("res://game/ui/main_shell.tscn")


static func run() -> Array[String]:
    var failures: Array[String] = []

    var bounds: Rect2 = PhaseBattlefieldModelScript.WORLD_BOUNDS
    if bounds.size.x < 1280.0 * 4.0 or bounds.size.y < 720.0 * 4.0:
        failures.append("R03 world bounds do not span several 1280x720 viewports")

    var terrain = PhaseBattlefieldModelScript.new()
    var far_northwest := Vector2(-2400.0, -1600.0)
    var far_southeast := Vector2(2600.0, 1800.0)
    if not terrain.is_position_walkable(PhaseBattlefieldModelScript.PHASE_MATERIAL, far_northwest):
        failures.append("R03 multi-screen northwest field is not walkable")
    if not terrain.is_position_walkable(PhaseBattlefieldModelScript.PHASE_MATERIAL, far_southeast):
        failures.append("R03 multi-screen southeast field is not walkable")
    if terrain.is_position_walkable(PhaseBattlefieldModelScript.PHASE_MATERIAL, Vector2(-4000.0, 0.0)):
        failures.append("R03 world boundary no longer rejects positions outside the field")

    var shell = MainShellScene.instantiate()
    if shell == null:
        failures.append("R03 main shell could not be instantiated")
        return failures
    var shell_script: Script = shell.get_script()
    if shell_script == null or shell_script.resource_path != "res://game/ui/main_shell_medieval_rebuild.gd":
        failures.append("R03 main shell is not using the medieval rebuild camera adapter")
    var screen_ui := shell.get_node_or_null("ScreenUI")
    if not screen_ui is CanvasLayer:
        failures.append("R03 fixed HUD is not isolated in a CanvasLayer")
    for path in [
        "ScreenUI/SafeArea",
        "ScreenUI/W13RepresentativeHud",
        "ScreenUI/W23WeaponRelicHud",
        "ScreenUI/W23WorldEventHud",
        "ScreenUI/W15FirstExpeditionTutorial",
        "ScreenUI/W16CharacterTutorial",
        "ScreenUI/W25MobileControls",
    ]:
        if shell.get_node_or_null(path) == null:
            failures.append("R03 missing fixed screen-space node: %s" % path)
    if shell.get_node_or_null("W13Environment") == null or shell.get_node_or_null("W13RepresentativeArt") == null:
        failures.append("R03 world-space presentation nodes were incorrectly moved into screen UI")

    var viewport_container := shell.get_node_or_null("WorldPresentation")
    if not viewport_container is SubViewportContainer:
        failures.append("R04 3D world presentation is not mounted through a SubViewportContainer")
    var presentation_viewport := shell.get_node_or_null("WorldPresentation/SubViewport")
    if not presentation_viewport is SubViewport:
        failures.append("R04 3D world presentation is missing its SubViewport")
    var field := shell.get_node_or_null("WorldPresentation/SubViewport/MedievalField3D")
    if not field is Node3D:
        failures.append("R04 medieval field is not a Node3D presentation layer")
    elif not field.has_method("presentation_spec"):
        failures.append("R04 medieval field does not expose its presentation contract")
    else:
        var spec: Dictionary = field.call("presentation_spec")
        if not bool(spec.get("asset_backed", false)):
            failures.append("R04 medieval field is not asset-backed")
        if str(spec.get("asset_path", "")) != "res://assets/third_party/kaykit_medieval_hexagon/terrain/hex_grass.gltf":
            failures.append("R04 medieval field is not using the admitted KayKit terrain asset")
        if int(spec.get("terrain_instances", 0)) < 2000:
            failures.append("R04 terrain coverage is too small for the mapped world")
        var nature_paths: Array = spec.get("nature_asset_paths", [])
        if nature_paths.size() < 2:
            failures.append("R04 nature layer does not expose multiple admitted KayKit assets")
        if not nature_paths.has("res://assets/third_party/kaykit_medieval_hexagon/nature/tree_single_A.gltf"):
            failures.append("R04 KayKit tree asset is not in the presentation contract")
        if not nature_paths.has("res://assets/third_party/kaykit_medieval_hexagon/nature/rock_single_A.gltf"):
            failures.append("R04 KayKit rock asset is not in the presentation contract")
        if int(spec.get("tree_instances", 0)) < 72:
            failures.append("R04 forest depth layer is too sparse")
        if int(spec.get("rock_instances", 0)) < 24:
            failures.append("R04 rock depth layer is too sparse")
        if int(spec.get("nature_clusters", 0)) < 14:
            failures.append("R04 nature landmarks do not cover enough of the multi-screen world")
        var depth_cues: Array = spec.get("depth_cues", [])
        for cue in ["height", "cast_shadows", "camera-relative parallax", "cluster silhouette"]:
            if not depth_cues.has(cue):
                failures.append("R04 missing 2.5D depth cue: %s" % cue)
        if bool(spec.get("authoritative_gameplay", true)):
            failures.append("R04 visual 3D layer incorrectly became gameplay-authoritative")
    shell.free()

    return failures
