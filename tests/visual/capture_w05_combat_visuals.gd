extends SceneTree

const MedievalFieldScript = preload("res://game/presentation/medieval_field_2_5d.gd")
const CombatVisualsScript = preload("res://game/presentation/medieval_combat_visuals_2_5d.gd")

const OUTPUT_DIR := "res://artifacts/w05"
const TRIGGER_OUTPUT := "res://artifacts/w05/combat-trigger.png"
const TRAVEL_OUTPUT := "res://artifacts/w05/combat-travel.png"
const IMPACT_OUTPUT := "res://artifacts/w05/combat-impact.png"
const EXPECTED_SIZE := Vector2i(1280, 720)


func _initialize() -> void:
    call_deferred("_capture")


func _capture() -> void:
    root.size = EXPECTED_SIZE
    var stage := Node3D.new()
    stage.name = "W05CombatStage"
    root.add_child(stage)

    var field := MedievalFieldScript.new()
    field.name = "MedievalField"
    stage.add_child(field)
    var combat := CombatVisualsScript.new()
    combat.name = "CombatVisuals"
    stage.add_child(combat)
    for _frame in range(8):
        await process_frame

    field.set_gameplay_focus(Vector2(240.0, -10.0))
    combat.set_process(false)
    combat.configure_showcase()
    for _frame in range(2):
        await process_frame

    var output_dir_absolute := ProjectSettings.globalize_path(OUTPUT_DIR)
    if DirAccess.make_dir_recursive_absolute(output_dir_absolute) != OK:
        printerr("W05_RENDER=FAIL_DIRECTORY")
        quit(2)
        return

    if not _save_frame(TRIGGER_OUTPUT):
        printerr("W05_RENDER=FAIL_TRIGGER")
        quit(3)
        return
    combat.debug_step_effects(0.20)
    for _frame in range(2):
        await process_frame
    if not _save_frame(TRAVEL_OUTPUT):
        printerr("W05_RENDER=FAIL_TRAVEL")
        quit(4)
        return
    combat.debug_step_effects(0.24)
    for _frame in range(2):
        await process_frame
    var impact_snapshot: Dictionary = combat.visual_debug_snapshot()
    if int(impact_snapshot.get("visible_impact_cues", 0)) < 3:
        printerr("W05_RENDER=FAIL_IMPACT_CUES")
        quit(5)
        return
    if int(impact_snapshot.get("visible_damage_cues", 0)) < 3:
        printerr("W05_RENDER=FAIL_DAMAGE_CUES")
        quit(6)
        return
    if int(impact_snapshot.get("visible_death_cues", 0)) < 1:
        printerr("W05_RENDER=FAIL_DEATH_CUE")
        quit(7)
        return
    if int(impact_snapshot.get("visible_chain_cues", 0)) < 1:
        printerr("W05_RENDER=FAIL_CHAIN_CUE")
        quit(8)
        return
    if int(impact_snapshot.get("visible_area_cues", 0)) < 1:
        printerr("W05_RENDER=FAIL_AREA_CUE")
        quit(9)
        return
    if not _save_frame(IMPACT_OUTPUT):
        printerr("W05_RENDER=FAIL_IMPACT")
        quit(10)
        return

    var hashes := [
        FileAccess.get_sha256(TRIGGER_OUTPUT),
        FileAccess.get_sha256(TRAVEL_OUTPUT),
        FileAccess.get_sha256(IMPACT_OUTPUT),
    ]
    var unique_hashes: Dictionary = {}
    for hash_value: String in hashes:
        unique_hashes[hash_value] = true
    if unique_hashes.size() != 3:
        printerr("W05_RENDER=FAIL_HASH_COLLISION")
        quit(11)
        return

    var snapshot: Dictionary = combat.visual_debug_snapshot()
    print("W05_RENDER=PASS")
    print("W05_RENDER_SIZE=%dx%d" % [EXPECTED_SIZE.x, EXPECTED_SIZE.y])
    print("W05_RENDER_FRAMES=3")
    print("W05_RENDER_HASHES_DISTINCT=PASS")
    print("W05_RENDER_ENEMIES=%d" % int(snapshot.get("enemy_visual_count", 0)))
    print("W05_RENDER_VISIBLE_IMPACT_CUES=%d" % int(impact_snapshot.get("visible_impact_cues", 0)))
    print("W05_RENDER_VISIBLE_DAMAGE_CUES=%d" % int(impact_snapshot.get("visible_damage_cues", 0)))
    print("W05_RENDER_VISIBLE_DEATH_CUES=%d" % int(impact_snapshot.get("visible_death_cues", 0)))
    print("W05_RENDER_VISIBLE_CHAIN_CUES=%d" % int(impact_snapshot.get("visible_chain_cues", 0)))
    print("W05_RENDER_VISIBLE_AREA_CUES=%d" % int(impact_snapshot.get("visible_area_cues", 0)))
    print("W05_TRIGGER_SHA256=%s" % hashes[0])
    print("W05_TRAVEL_SHA256=%s" % hashes[1])
    print("W05_IMPACT_SHA256=%s" % hashes[2])
    stage.queue_free()
    await process_frame
    quit(0)


func _save_frame(output_path: String) -> bool:
    var image: Image = root.get_texture().get_image()
    if image == null or image.get_width() != EXPECTED_SIZE.x or image.get_height() != EXPECTED_SIZE.y:
        return false
    return image.save_png(ProjectSettings.globalize_path(output_path)) == OK
