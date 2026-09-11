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

    layer.configure_showcase()
    await process_frame
    var snapshot: Dictionary = layer.visual_debug_snapshot()
    if not bool(snapshot.get("player_asset_backed", false)):
        printerr("W05_COMBAT_VISUALS=FAIL_PLAYER_RUNTIME")
        quit(7)
        return
    if int(snapshot.get("enemy_visual_count", 0)) != 3:
        printerr("W05_COMBAT_VISUALS=FAIL_ENEMY_RUNTIME")
        quit(8)
        return
    if int(snapshot.get("active_effects", 0)) < 2:
        printerr("W05_COMBAT_VISUALS=FAIL_EFFECT_RUNTIME")
        quit(9)
        return
    if "lantern_bolt" not in str(snapshot.get("weapon_visual_key", "")):
        printerr("W05_COMBAT_VISUALS=FAIL_WEAPON_RUNTIME")
        quit(10)
        return

    layer.debug_step_effects(0.20)
    layer.debug_step_effects(0.24)
    var impact_snapshot: Dictionary = layer.visual_debug_snapshot()
    if int(impact_snapshot.get("active_effects", 0)) < 2:
        printerr("W05_COMBAT_VISUALS=FAIL_IMPACT_SEQUENCE")
        quit(11)
        return

    print("W05_CONTRACT=r05-combat-visuals-v1")
    print("W05_ASSET_SCENES=%d" % REQUIRED_ASSETS.size())
    print("W05_ENEMY_VARIANTS=3")
    print("W05_WEAPON_DELIVERIES=6")
    print("W05_CAUSAL_STAGES=5")
    print("W05_COMBAT_VISUALS=PASS")
    layer.queue_free()
    await process_frame
    quit(0)
