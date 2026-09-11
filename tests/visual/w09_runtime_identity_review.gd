extends Node

const CampaignRuntimeW22Script = preload("res://game/world/campaign_runtime_w22.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")

const TEST_ROOT: String = "user://ci_w09_runtime_identity"
const MAX_TARGET_WAIT_FRAMES: int = 360
const EXPECTED_CHARACTER_ASSETS := {
    "aurora": "Mage",
    "cinder": "Barbarian",
    "rivet": "Knight",
    "veil": "Rogue_Hooded",
    "mneme": "Mage",
    "vesper": "Rogue_Hooded",
}
const EXPECTED_REGION_IDS := [
    "twilight_shipyard",
    "glass_garden",
    "flooded_archive",
    "ash_railway",
    "eclipse_fortress",
]

var _failures: Array[String] = []


func _ready() -> void:
    call_deferred("_run")


func _run() -> void:
    _clear_save()
    var packed: Resource = load("res://game/ui/main_shell.tscn")
    _expect(packed is PackedScene, "W09 real main shell could not be loaded")
    if not packed is PackedScene:
        _finish(null)
        return

    var shell: Node = (packed as PackedScene).instantiate()
    shell.set("campaign", CampaignRuntimeW22Script.new(TEST_ROOT))
    add_child(shell)
    for _frame in range(8):
        await get_tree().process_frame

    _expect(str(shell.get("shell_mode")) == "SLOT_SELECT", "W09 did not start at slot select")
    _expect(bool(shell.call("select_save_slot", 0)), "W09 slot selection failed")
    for _frame in range(4):
        await get_tree().process_frame
    _expect(str(shell.get("shell_mode")) == "HUB", "W09 slot selection did not enter HUB")

    var combat_visuals := shell.get_node_or_null("WorldPresentation/SubViewport/MedievalCombatVisuals3D")
    var field := shell.get_node_or_null("WorldPresentation/SubViewport/MedievalField3D")
    _expect(combat_visuals != null and combat_visuals.has_method("set_player_character"), "W09 3D character binding API is missing")
    _expect(field != null and field.has_method("set_region_id"), "W09 3D region binding API is missing")
    if combat_visuals == null or field == null:
        _finish(shell)
        return

    for character_id: String in EXPECTED_CHARACTER_ASSETS.keys():
        _expect(bool(combat_visuals.call("set_player_character", character_id)), "W09 character binding rejected %s" % character_id)
        var character_snapshot: Dictionary = combat_visuals.call("visual_debug_snapshot")
        _expect(str(character_snapshot.get("player_character_id", "")) == character_id, "W09 character id did not reach 3D presentation: %s" % character_id)
        _expect(str(character_snapshot.get("player_asset_id", "")) == str(EXPECTED_CHARACTER_ASSETS[character_id]), "W09 wrong 3D asset for character %s" % character_id)

    for region_id: String in EXPECTED_REGION_IDS:
        _expect(bool(field.call("set_region_id", region_id)), "W09 region binding rejected %s" % region_id)
        var region_spec: Dictionary = field.call("presentation_spec")
        _expect(str(region_spec.get("region_id", "")) == region_id, "W09 field did not retain region %s" % region_id)
    var supported_regions: Array = field.call("presentation_spec").get("supported_region_ids", [])
    for region_id: String in EXPECTED_REGION_IDS:
        _expect(supported_regions.has(region_id), "W09 field region contract omitted %s" % region_id)

    _expect(bool(shell.call("select_world_choice", 0)), "W09 HUB choice could not begin expedition")
    await get_tree().process_frame
    await get_tree().physics_frame
    await get_tree().process_frame
    _expect(str(shell.get("shell_mode")) == "EXPEDITION", "W09 HUB choice did not enter EXPEDITION")
    shell.call("_sync_medieval_presentation")

    var presentation: Dictionary = shell.call("medieval_presentation_snapshot")
    var selected_character := str(shell.get("selected_character_id"))
    var runtime_combat: Dictionary = presentation.get("combat", {})
    var runtime_field: Dictionary = presentation.get("field", {})
    _expect(str(presentation.get("selected_character_id", "")) == selected_character, "W09 shell presentation snapshot lost selected character")
    _expect(str(runtime_combat.get("player_character_id", "")) == selected_character, "W09 selected character did not reach live 3D runtime")
    _expect(str(runtime_combat.get("player_asset_id", "")) == str(EXPECTED_CHARACTER_ASSETS.get(selected_character, "")), "W09 live 3D player asset does not match selected character")
    _expect(str(runtime_field.get("region_id", "")) == str(presentation.get("region_id", "")), "W09 live region id did not reach MedievalField25D")
    _expect(EXPECTED_REGION_IDS.has(str(runtime_field.get("region_id", ""))), "W09 live region is outside the supported five-region contract")

    var encounter := shell.get("encounter_preview") as Node
    _expect(encounter != null and encounter.has_method("combat_target_snapshot"), "W09 real encounter target provider is missing")
    var target_metadata_verified := false
    if encounter != null:
        for _frame in range(MAX_TARGET_WAIT_FRAMES):
            await get_tree().physics_frame
            await get_tree().process_frame
            var raw_targets: Variant = encounter.call("combat_target_snapshot")
            if not raw_targets is Array:
                continue
            for raw_target: Variant in raw_targets:
                if not raw_target is Dictionary:
                    continue
                var target: Dictionary = raw_target
                if not bool(target.get("active", false)) or str(target.get("archetype", "")) == "boss":
                    continue
                _expect(target.has("archetype"), "W09 target snapshot omitted archetype")
                _expect(target.has("health"), "W09 target snapshot omitted health")
                _expect(target.has("max_health"), "W09 target snapshot omitted max_health")
                _expect(target.has("behavior_id"), "W09 target snapshot omitted behavior_id")
                _expect(int(target.get("health", -1)) >= 0, "W09 target health is invalid")
                _expect(int(target.get("max_health", 0)) > 0, "W09 target max health is invalid")
                _expect(not str(target.get("behavior_id", "")).is_empty(), "W09 regular target behavior id is empty")
                target_metadata_verified = true
                break
            if target_metadata_verified:
                break
    _expect(target_metadata_verified, "W09 did not observe authoritative metadata on a live regular target")

    var identity_cases := [
        {"behavior_id": "dusk_mite", "expected": "Barbarian"},
        {"behavior_id": "chain_wraith", "expected": "Mage"},
        {"behavior_id": "rivet_hound", "expected": "Rogue_Hooded"},
    ]
    for identity_case: Dictionary in identity_cases:
        var identity: Dictionary = combat_visuals.call("_enemy_visual_identity", {
            "archetype": "swarm",
            "behavior_id": str(identity_case.get("behavior_id", "")),
        })
        _expect(str(identity.get("asset_id", "")) == str(identity_case.get("expected", "")), "W09 behavior metadata did not deterministically select the expected 3D enemy identity")

    if _failures.is_empty():
        print("W09_CHARACTER_IDENTITY=PASS")
        print("W09_ENEMY_METADATA=PASS")
        print("W09_REGION_PROJECTION=PASS")
        print("W09_RUNTIME_IDENTITY=PASS")
    _finish(shell)


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _clear_save() -> void:
    for slot in range(SaveStoreScript.SLOT_COUNT):
        SaveStoreScript.clear_slot(slot, TEST_ROOT)


func _finish(shell: Node) -> void:
    if is_instance_valid(shell):
        shell.queue_free()
    _clear_save()
    if _failures.is_empty():
        get_tree().quit(0)
        return
    for failure: String in _failures:
        printerr("W09_FAIL: %s" % failure)
    printerr("W09_RUNTIME_IDENTITY=FAIL")
    get_tree().quit(1)
