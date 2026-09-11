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
    shell.free()

    return failures
