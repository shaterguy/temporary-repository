extends SceneTree

const CombatVisualsScript = preload("res://game/presentation/medieval_combat_visuals_2_5d.gd")

const REQUIRED_ASSETS := [
    "res://assets/third_party/kaykit_adventurers/characters/Knight.glb",
    "res://assets/third_party/kaykit_adventurers/characters/Barbarian.glb",
    "res://assets/third_party/kaykit_adventurers/characters/Mage.glb",
    "res://assets/third_party/kaykit_adventurers/characters/Rogue_Hooded.glb",
    "res://assets/third_party/kaykit_adventurers/weapons/sword_1handed.gltf",
    "res://assets/third_party/kaykit_adventurers/weapons/staff.gltf",
    "res://assets/third_party/kaykit_adventurers/weapons/dagger.gltf",
    "res://assets/third_party/kaykit_adventurers/weapons/crossbow_1handed.gltf",
    "res://assets/third_party/kaykit_adventurers/weapons/arrow.gltf",
]
const REQUIRED_READABILITY_CUES := [
    "impact_burst",
    "damage_number",
    "hit_reaction",
    "death_marker",
    "chain_marker",
    "area_marker",
]


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    for asset_path: String in REQUIRED_ASSETS:
        if not ResourceLoader.exists(asset_path):
            printerr("W05_COMBAT_VISUALS=FAIL_ASSET:%s" % asset_path)
            quit(2)
            return

    var layer := CombatVisualsScript.new()
    root.add_child(layer)
    await process_frame
    var spec: Dictionary = layer.presentation_spec()
    if str(spec.get("player_asset", "")).is_empty():
        printerr("W05_COMBAT_VISUALS=FAIL_PLAYER_SPEC")
        quit(3)
        return
    if (spec.get("enemy_assets", []) as Array).size() != 3:
        printerr("W05_COMBAT_VISUALS=FAIL_ENEMY_SPEC")
        quit(4)
        return
    if (spec.get("weapon_assets", {}) as Dictionary).size() != 6:
        printerr("W05_COMBAT_VISUALS=FAIL_WEAPON_SPEC")
        quit(5)
        return
    var stages: Array = spec.get("causal_stages", [])
    if stages != ["trigger", "travel", "impact", "damage", "death"]:
        printerr("W05_COMBAT_VISUALS=FAIL_CAUSAL_STAGES")
        quit(6)
        return
    var readability_cues: Array = spec.get("readability_cues", [])
    if readability_cues != REQUIRED_READABILITY_CUES:
        printerr("W05_COMBAT_VISUALS=FAIL_READABILITY_CUES")
        quit(7)
        return
    var timing: Dictionary = spec.get("effect_timing", {})
    if float(timing.get("impact_seconds", 0.0)) < 0.40:
        printerr("W05_COMBAT_VISUALS=FAIL_IMPACT_TIMING")
        quit(8)
        return
    if float(timing.get("damage_seconds", 0.0)) < 0.68:
        printerr("W05_COMBAT_VISUALS=FAIL_DAMAGE_TIMING")
        quit(9)
        return
    if float(timing.get("death_seconds", 0.0)) < 0.84:
        printerr("W05_COMBAT_VISUALS=FAIL_DEATH_TIMING")
        quit(10)
        return

    layer.configure_showcase()
    await process_frame
    var snapshot: Dictionary = layer.visual_debug_snapshot()
    if not bool(snapshot.get("player_asset_backed", false)):
        printerr("W05_COMBAT_VISUALS=FAIL_PLAYER_RUNTIME")
        quit(11)
        return
    if int(snapshot.get("enemy_visual_count", 0)) != 3:
        printerr("W05_COMBAT_VISUALS=FAIL_ENEMY_RUNTIME")
        quit(12)
        return
    if int(snapshot.get("active_effects", 0)) < 3:
        printerr("W05_COMBAT_VISUALS=FAIL_EFFECT_RUNTIME")
        quit(13)
        return
    if "lantern_bolt" not in str(snapshot.get("weapon_visual_key", "")):
        printerr("W05_COMBAT_VISUALS=FAIL_WEAPON_RUNTIME")
        quit(14)
        return

    layer.debug_step_effects(0.20)
    layer.debug_step_effects(0.24)
    var impact_snapshot: Dictionary = layer.visual_debug_snapshot()
    if int(impact_snapshot.get("active_effects", 0)) < 3:
        printerr("W05_COMBAT_VISUALS=FAIL_IMPACT_SEQUENCE")
        quit(15)
        return
    if int(impact_snapshot.get("visible_impact_cues", 0)) < 3:
        printerr("W05_COMBAT_VISUALS=FAIL_IMPACT_CUES")
        quit(16)
        return
    if int(impact_snapshot.get("visible_damage_cues", 0)) < 3:
        printerr("W05_COMBAT_VISUALS=FAIL_DAMAGE_CUES")
        quit(17)
        return
    if int(impact_snapshot.get("visible_death_cues", 0)) < 1:
        printerr("W05_COMBAT_VISUALS=FAIL_DEATH_CUE")
        quit(18)
        return
    if int(impact_snapshot.get("visible_chain_cues", 0)) < 1:
        printerr("W05_COMBAT_VISUALS=FAIL_CHAIN_CUE")
        quit(19)
        return
    if int(impact_snapshot.get("visible_area_cues", 0)) < 1:
        printerr("W05_COMBAT_VISUALS=FAIL_AREA_CUE")
        quit(20)
        return

    print("W05_CONTRACT=r05-combat-visuals-v2")
    print("W05_ASSET_SCENES=%d" % REQUIRED_ASSETS.size())
    print("W05_ENEMY_VARIANTS=3")
    print("W05_WEAPON_DELIVERIES=6")
    print("W05_CAUSAL_STAGES=5")
    print("W05_READABILITY_CUES=%d" % REQUIRED_READABILITY_CUES.size())
    print("W05_IMPACT_CUES=%d" % int(impact_snapshot.get("visible_impact_cues", 0)))
    print("W05_DAMAGE_CUES=%d" % int(impact_snapshot.get("visible_damage_cues", 0)))
    print("W05_DEATH_CUES=%d" % int(impact_snapshot.get("visible_death_cues", 0)))
    print("W05_CHAIN_CUES=%d" % int(impact_snapshot.get("visible_chain_cues", 0)))
    print("W05_AREA_CUES=%d" % int(impact_snapshot.get("visible_area_cues", 0)))
    print("W05_COMBAT_VISUALS=PASS")
    layer.queue_free()
    await process_frame
    quit(0)
