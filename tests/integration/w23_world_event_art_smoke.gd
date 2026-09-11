extends SceneTree

const RegionCatalogScript = preload("res://game/data/region_catalog.gd")
const StoryCatalogScript = preload("res://game/data/campaign_story_event_catalog.gd")
const ArtCatalogScript = preload("res://game/presentation/w23_world_event_art_catalog.gd")
const W23EncounterScript = preload("res://game/combat/w23_region_swarm_encounter.gd")

const MANIFEST_PATH := "res://assets/runtime/w23/world_event_art_manifest.json"
const SOURCE_RECORD := "res://assets/source/w23/WORLD_EVENT_ART_DIRECTION.md"
const LICENSE_RECORD := "res://assets/licenses/W23_ORIGINAL_WORLD_EVENT_ART.md"
const EXPECTED_REGIONS: Array[String] = ["twilight_shipyard", "glass_garden", "flooded_archive", "ash_railway", "eclipse_fortress"]
const W23_SHELL_SCRIPT_PATH := "res://game/ui/main_shell_w23.gd"

var _failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    _expect(FileAccess.file_exists(MANIFEST_PATH), "W23C manifest missing")
    _expect(FileAccess.file_exists(SOURCE_RECORD), "W23C source record missing")
    _expect(FileAccess.file_exists(LICENSE_RECORD), "W23C provenance record missing")
    _expect(FileAccess.file_exists("res://assets/runtime/w23/enemy_behavior_atlas.svg"), "W23C enemy atlas missing")
    _expect(FileAccess.file_exists("res://assets/runtime/w23/choice_event_atlas.svg"), "W23C event atlas missing")
    var counts := ArtCatalogScript.counts()
    _expect(int(counts.get("enemies", 0)) == 30, "W23C must track 30 enemy visual roles")
    _expect(int(counts.get("events", 0)) == 40, "W23C must track 40 event illustrations")
    _expect(int(counts.get("regions", 0)) == 5, "W23C must track five regions")
    _expect(int(counts.get("placeholders", -1)) == 0, "W23C placeholders must be zero")

    var enemy_ids := ArtCatalogScript.enemy_ids()
    _expect(enemy_ids.size() == 30, "W23C enemy IDs must be unique count 30")
    var seen_enemy: Dictionary = {}
    for enemy_id: String in enemy_ids:
        _expect(not seen_enemy.has(enemy_id), "W23C duplicate enemy ID: %s" % enemy_id)
        seen_enemy[enemy_id] = true
        _expect(ArtCatalogScript.enemy_texture(enemy_id) is Texture2D, "W23C enemy texture must import: %s" % enemy_id)
    for enemy_id: String in ArtCatalogScript.TWILIGHT_ENEMY_IDS:
        _expect(seen_enemy.has(enemy_id), "W23C Twilight production mapping missing: %s" % enemy_id)

    var regional_count := 0
    var behavior_groups := [
        RegionCatalogScript.GLASS_GARDEN_BEHAVIORS,
        RegionCatalogScript.FLOODED_ARCHIVE_BEHAVIORS,
        RegionCatalogScript.ASH_RAILWAY_BEHAVIORS,
        RegionCatalogScript.ECLIPSE_FORTRESS_BEHAVIORS,
    ]
    for group: Array in behavior_groups:
        for behavior: Dictionary in group:
            var behavior_id := str(behavior.get("behavior_id", ""))
            _expect(seen_enemy.has(behavior_id), "W23C canonical regional behavior art missing: %s" % behavior_id)
            regional_count += 1
    _expect(regional_count == 24, "W23C must cover all 24 W18/W19 behavior IDs")

    var event_ids := ArtCatalogScript.event_ids()
    _expect(event_ids.size() == StoryCatalogScript.EXPECTED_EVENT_COUNT, "W23C event art count must match W21 catalog")
    var seen_event: Dictionary = {}
    for event: Dictionary in StoryCatalogScript.all_events():
        var event_id := str(event.get("event_id", ""))
        var art := ArtCatalogScript.event_art_snapshot(event_id)
        _expect(not art.is_empty(), "W23C event art missing: %s" % event_id)
        _expect(str(art.get("parent_region_id", "")) == str(event.get("parent_region_id", "")), "W23C event parent mismatch: %s" % event_id)
        _expect(ArtCatalogScript.event_texture(event_id) is Texture2D, "W23C event texture must import: %s" % event_id)
        _expect(not seen_event.has(event_id), "W23C duplicate event ID: %s" % event_id)
        seen_event[event_id] = true
    _expect(seen_event.size() == 40, "W23C all forty W21 events must be mapped")

    var regions := ArtCatalogScript.region_ids()
    _expect(regions == EXPECTED_REGIONS, "W23C region order/coverage mismatch")
    for region_id: String in EXPECTED_REGIONS:
        _expect(ArtCatalogScript.region_texture(region_id) is Texture2D, "W23C region environment must import: %s" % region_id)

    var encounter := W23EncounterScript.new()
    encounter.call("_spawn_enemy", {
        "archetype": "runner",
        "position": Vector2(64.0, 64.0),
        "behavior_id": "prism_skater",
        "spawn_id": "w18-000000",
    })
    var binding: Dictionary = encounter.call("w23_art_binding_snapshot")
    var mapped: Dictionary = binding.get("mapped_entities", {})
    _expect(mapped.values().has("prism_skater"), "W23C live behavior_id must bind to its exact art ID")
    encounter.free()

    var main_scene: Resource = load("res://game/ui/main_shell.tscn")
    _expect(main_scene is PackedScene, "W23C main scene must load")
    if main_scene is PackedScene:
        var shell: Node = (main_scene as PackedScene).instantiate()
        var script: Script = shell.get_script()
        _expect(_script_chain_contains(script, W23_SHELL_SCRIPT_PATH), "W23C main scene must retain W23 shell behavior in its inheritance chain")
        var hud := shell.get_node_or_null("ScreenUI/W23WorldEventHud")
        _expect(hud != null, "W23C main scene must mount story event art HUD")
        if hud != null:
            _expect(bool(hud.call("show_event", "ts_s01")), "W23C event HUD must accept canonical event art")
            var hud_snapshot: Dictionary = hud.call("event_snapshot")
            _expect(str(hud_snapshot.get("event_id", "")) == "ts_s01", "W23C event HUD snapshot mismatch")
        shell.free()
    _finish()


func _script_chain_contains(script: Script, target_path: String) -> bool:
    var current: Script = script
    while current != null:
        if current.resource_path == target_path:
            return true
        current = current.get_base_script()
    return false


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _finish() -> void:
    print("W23C_ENEMY_VISUAL_ROLES=30")
    print("W23C_CHOICE_EVENT_ART=40")
    print("W23C_REGION_ART=5")
    print("W23C_PLACEHOLDER_COUNT=0")
    if _failures.is_empty():
        print("W23C_RUNTIME_MAPPING=PASS")
        print("W23C_WORLD_EVENT_ART=PASS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("W23C_FAIL: %s" % failure)
    printerr("W23C_WORLD_EVENT_ART=FAIL")
    quit(1)
