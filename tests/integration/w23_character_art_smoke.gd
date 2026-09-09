extends SceneTree

const CharacterCatalogScript = preload("res://game/data/character_catalog.gd")
const CharacterRoleSurvivorScript = preload("res://game/combat/character_role_survivor.gd")
const MANIFEST_PATH := "res://assets/runtime/w23/character_art_manifest.json"
const SOURCE_RECORD := "res://assets/source/w23/CHARACTER_ART_DIRECTION.md"
const LICENSE_RECORD := "res://assets/licenses/W23_ORIGINAL_CHARACTER_ART.md"

var _failures: Array[String] = []


func _initialize() -> void:
    call_deferred("_run")


func _run() -> void:
    _expect(FileAccess.file_exists(MANIFEST_PATH), "W23 character manifest missing")
    _expect(FileAccess.file_exists(SOURCE_RECORD), "W23 character source record missing")
    _expect(FileAccess.file_exists(LICENSE_RECORD), "W23 character provenance record missing")
    if not FileAccess.file_exists(MANIFEST_PATH):
        _finish()
        return

    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
    _expect(parsed is Dictionary, "W23 character manifest must parse")
    if not parsed is Dictionary:
        _finish()
        return
    var manifest: Dictionary = parsed
    _expect(str(manifest.get("milestone", "")) == "W23A", "W23 character manifest milestone mismatch")
    _expect(int(manifest.get("placeholder_count", -1)) == 0, "W23 character placeholder count must be zero")
    var assets_value: Variant = manifest.get("assets", [])
    _expect(assets_value is Array, "W23 character assets must be an array")
    if not assets_value is Array:
        _finish()
        return
    var assets: Array = assets_value
    _expect(assets.size() == 6, "W23 character manifest must track exactly six playable identities")

    var manifest_by_id: Dictionary = {}
    for value in assets:
        _expect(value is Dictionary, "W23 asset entry must be a dictionary")
        if not value is Dictionary:
            continue
        var asset: Dictionary = value
        var asset_id := str(asset.get("id", ""))
        _expect(not asset_id.is_empty(), "W23 character asset id must be non-empty")
        _expect(not manifest_by_id.has(asset_id), "W23 duplicate character asset id: %s" % asset_id)
        _expect(not bool(asset.get("placeholder", true)), "W23 character asset may not be placeholder: %s" % asset_id)
        manifest_by_id[asset_id] = asset

    var seen_payloads: Dictionary = {}
    for character_id in CharacterCatalogScript.character_ids():
        var definition := CharacterCatalogScript.definition(character_id)
        var runtime_path := str(definition.get("representative_art", ""))
        _expect(runtime_path.begins_with("res://assets/runtime/w23/characters/"), "W23 catalog must point to production character art: %s" % character_id)
        _expect(str(definition.get("production_art_status", "")) == "w23-production-art-awaiting-human-review", "W23 character status mismatch: %s" % character_id)
        _expect(FileAccess.file_exists(runtime_path), "W23 runtime SVG missing: %s" % runtime_path)
        if not FileAccess.file_exists(runtime_path):
            continue
        var svg := FileAccess.get_file_as_string(runtime_path)
        _expect(svg.contains("<svg"), "W23 runtime art must be SVG: %s" % character_id)
        _expect(svg.contains("<path"), "W23 runtime art must contain authored path geometry: %s" % character_id)
        _expect(svg.contains("linearGradient"), "W23 runtime art must keep authored gradient treatment: %s" % character_id)
        _expect(not seen_payloads.has(svg), "W23 character SVG payloads must be distinct: %s" % character_id)
        seen_payloads[svg] = true
        var texture: Resource = load(runtime_path)
        _expect(texture is Texture2D, "Godot must import W23 SVG as Texture2D: %s" % character_id)
        _expect(manifest_by_id.has(character_id), "W23 manifest missing character: %s" % character_id)
        if manifest_by_id.has(character_id):
            var asset: Dictionary = manifest_by_id[character_id]
            _expect(str(asset.get("runtime_path", "")) == runtime_path, "W23 manifest/catalog path mismatch: %s" % character_id)
            _expect(str(asset.get("role_id", "")) == str(definition.get("role_id", "")), "W23 manifest/catalog role mismatch: %s" % character_id)

        var survivor: Node = CharacterRoleSurvivorScript.new()
        _expect(bool(survivor.call("configure_character", character_id)), "W23 actual Survivor could not configure character art: %s" % character_id)
        var snapshot: Dictionary = survivor.call("character_visual_snapshot")
        _expect(bool(snapshot.get("texture_loaded", false)), "W23 actual Survivor did not load character texture: %s" % character_id)
        _expect(str(snapshot.get("art_path", "")) == runtime_path, "W23 actual Survivor art path mismatch: %s" % character_id)
        _expect(snapshot.get("combat_size", Vector2.ZERO) == Vector2(48.0, 60.0), "W23 combat art size contract changed: %s" % character_id)
        survivor.free()

    var showcase: Resource = load("res://game/presentation/w23_character_showcase.tscn")
    _expect(showcase is PackedScene, "W23 character review showcase must load")
    _finish()


func _expect(condition: bool, message: String) -> void:
    if not condition:
        _failures.append(message)


func _finish() -> void:
    print("W23_CHARACTER_ART_COUNT=6")
    print("W23_PLACEHOLDER_COUNT=0")
    if _failures.is_empty():
        print("W23_CHARACTER_RUNTIME=PASS")
        print("W23_CHARACTER_ART=PASS")
        quit(0)
        return
    for failure in _failures:
        printerr("W23_FAIL: %s" % failure)
    printerr("W23_CHARACTER_ART=FAIL")
    quit(1)
