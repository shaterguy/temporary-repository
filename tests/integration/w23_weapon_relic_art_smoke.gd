extends SceneTree

const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const RelicCatalogScript = preload("res://game/data/relic_catalog.gd")
const ChoiceModelScript = preload("res://game/ui/weapon_relic_choice_model.gd")
const ArtCatalogScript = preload("res://game/presentation/w23_weapon_relic_art_catalog.gd")
const MANIFEST_PATH := "res://assets/runtime/w23/weapon_relic_art_manifest.json"
const SOURCE_RECORD := "res://assets/source/w23/WEAPON_RELIC_ART_DIRECTION.md"
const LICENSE_RECORD := "res://assets/licenses/W23_ORIGINAL_WEAPON_RELIC_ART.md"

var _failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    _expect(FileAccess.file_exists(MANIFEST_PATH), "W23B manifest missing")
    _expect(FileAccess.file_exists(SOURCE_RECORD), "W23B source record missing")
    _expect(FileAccess.file_exists(LICENSE_RECORD), "W23B provenance record missing")
    if not FileAccess.file_exists(MANIFEST_PATH):
        _finish()
        return
    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
    _expect(parsed is Dictionary, "W23B manifest must parse")
    if not parsed is Dictionary:
        _finish()
        return
    var manifest: Dictionary = parsed
    _expect(str(manifest.get("milestone", "")) == "W23B", "W23B milestone mismatch")
    _expect(int(manifest.get("placeholder_count", -1)) == 0, "W23B placeholder count must be zero")
    var weapons: Dictionary = manifest.get("weapons", {})
    var relics: Dictionary = manifest.get("relics", {})
    _expect(weapons.size() == 18, "W23B must map exactly 18 curated weapons")
    _expect(relics.size() == 48, "W23B must map exactly 48 relics")

    var seen_payloads: Dictionary = {}
    for weapon_id: String in WeaponPartCatalogScript.weapon_ids():
        _check_asset(weapon_id, str(weapons.get(weapon_id, "")), ArtCatalogScript.weapon_path(weapon_id), seen_payloads, "weapon")
    for relic_id: String in RelicCatalogScript.relic_ids():
        _check_asset(relic_id, str(relics.get(relic_id, "")), ArtCatalogScript.relic_path(relic_id), seen_payloads, "relic")
    _expect(seen_payloads.size() == 66, "W23B all 66 SVG payloads must be distinct")

    var weapon_choices: Array[Dictionary] = ChoiceModelScript.weapon_choices("shade_halo", 17)
    var relic_choices: Array[Dictionary] = ChoiceModelScript.relic_choices([], 29)
    _expect(weapon_choices.size() == 3, "W23B weapon choices must preserve W17 three-choice contract")
    _expect(relic_choices.size() == 3, "W23B relic choices must preserve W17 three-choice contract")
    for card: Dictionary in weapon_choices:
        var art_path := str(card.get("art_path", ""))
        _expect(art_path == ArtCatalogScript.weapon_path(str(card.get("id", ""))), "W23B weapon choice art mapping mismatch")
        _expect(FileAccess.file_exists(art_path), "W23B weapon choice art missing")
    for card: Dictionary in relic_choices:
        var art_path := str(card.get("art_path", ""))
        _expect(art_path == ArtCatalogScript.relic_path(str(card.get("id", ""))), "W23B relic choice art mapping mismatch")
        _expect(FileAccess.file_exists(art_path), "W23B relic choice art missing")

    var main_scene: Resource = load("res://game/ui/main_shell.tscn")
    _expect(main_scene is PackedScene, "W23B actual main scene must load")
    if main_scene is PackedScene:
        var shell: Node = (main_scene as PackedScene).instantiate()
        _expect(shell.get_node_or_null("ScreenUI/W23WeaponRelicHud") != null, "W23B live weapon/relic HUD must be mounted in actual main scene")
        shell.free()
    var showcase: Resource = load("res://game/presentation/w23_weapon_relic_showcase.tscn")
    _expect(showcase is PackedScene, "W23B review showcase must load")
    _finish()


func _check_asset(asset_id: String, manifest_path: String, catalog_path: String, seen_payloads: Dictionary, kind: String) -> void:
    _expect(not manifest_path.is_empty(), "W23B manifest missing %s: %s" % [kind, asset_id])
    _expect(manifest_path == catalog_path, "W23B manifest/catalog path mismatch: %s" % asset_id)
    _expect(FileAccess.file_exists(catalog_path), "W23B runtime SVG missing: %s" % catalog_path)
    if not FileAccess.file_exists(catalog_path):
        return
    var svg := FileAccess.get_file_as_string(catalog_path)
    _expect(svg.contains("<svg"), "W23B asset must be SVG: %s" % asset_id)
    _expect(svg.contains("<path"), "W23B asset must contain authored path geometry: %s" % asset_id)
    _expect(svg.contains("linearGradient"), "W23B asset must keep authored gradient treatment: %s" % asset_id)
    _expect(not seen_payloads.has(svg), "W23B duplicate SVG payload: %s" % asset_id)
    seen_payloads[svg] = true
    var texture: Resource = load(catalog_path)
    _expect(texture is Texture2D, "Godot must import W23B SVG as Texture2D: %s" % asset_id)


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _finish() -> void:
    print("W23_WEAPON_ART_COUNT=18")
    print("W23_RELIC_ART_COUNT=48")
    print("W23_WEAPON_RELIC_PLACEHOLDER_COUNT=0")
    if _failures.is_empty():
        print("W23_WEAPON_RELIC_RUNTIME=PASS")
        print("W23_WEAPON_RELIC_ART=PASS")
        quit(0)
        return
    for failure: String in _failures:
        printerr("W23B_FAIL: %s" % failure)
    printerr("W23_WEAPON_RELIC_ART=FAIL")
    quit(1)
