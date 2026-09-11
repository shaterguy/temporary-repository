extends RefCounted

const Catalog = preload("res://game/presentation/art_catalog.gd")
const RepresentativeHud = preload("res://game/presentation/representative_hud.gd")
const MANIFEST_PATH := "res://assets/runtime/w13/art_manifest.json"
const SOURCE_RECORD := "res://assets/source/w13/ART_DIRECTION.md"
const LICENSE_RECORD := "res://assets/licenses/W13_ORIGINAL_ART.md"


static func run() -> Array[String]:
    var failures: Array[String] = []
    _expect(FileAccess.file_exists(MANIFEST_PATH), "W13 art manifest must exist", failures)
    _expect(FileAccess.file_exists(SOURCE_RECORD), "W13 source/edit record must exist", failures)
    _expect(FileAccess.file_exists(LICENSE_RECORD), "W13 license/provenance record must exist", failures)
    if not FileAccess.file_exists(MANIFEST_PATH):
        return failures

    var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST_PATH))
    _expect(parsed is Dictionary, "W13 art manifest must parse as a dictionary", failures)
    if not parsed is Dictionary:
        return failures
    var manifest: Dictionary = parsed
    _expect(str(manifest.get("milestone", "")) == "W13", "W13 manifest milestone identity must be W13", failures)
    _expect(str(manifest.get("status", "")) == "runtime-integrated", "W13 manifest must record runtime integration", failures)
    var assets_value: Variant = manifest.get("assets", [])
    _expect(assets_value is Array, "W13 manifest assets must be an array", failures)
    if not assets_value is Array:
        return failures
    var assets: Array = assets_value
    _expect(assets.size() == 15, "W13 representative manifest must track exactly 15 runtime vector assets", failures)

    var kind_counts: Dictionary = {}
    var seen_ids: Dictionary = {}
    var seen_svg_contents: Dictionary = {}
    for value in assets:
        _expect(value is Dictionary, "every W13 asset entry must be a dictionary", failures)
        if not value is Dictionary:
            continue
        var asset: Dictionary = value
        var asset_id := str(asset.get("id", ""))
        var kind := str(asset.get("kind", ""))
        var runtime_path := str(asset.get("runtime_path", ""))
        _expect(not asset_id.is_empty(), "W13 asset IDs must be non-empty", failures)
        _expect(not seen_ids.has(asset_id), "W13 asset IDs must be unique: %s" % asset_id, failures)
        seen_ids[asset_id] = true
        kind_counts[kind] = int(kind_counts.get(kind, 0)) + 1
        _expect(not bool(asset.get("placeholder", true)), "W13 runtime art must not be marked placeholder: %s" % asset_id, failures)
        _expect(runtime_path == Catalog.path_for(asset_id), "catalog path must match W13 manifest for %s" % asset_id, failures)
        _expect(FileAccess.file_exists(runtime_path), "W13 runtime asset must exist: %s" % runtime_path, failures)
        if not FileAccess.file_exists(runtime_path):
            continue
        var svg := FileAccess.get_file_as_string(runtime_path)
        _expect(svg.contains("<svg"), "W13 runtime asset must be SVG: %s" % asset_id, failures)
        _expect(svg.contains("<path"), "W13 SVG must contain authored path geometry: %s" % asset_id, failures)
        _expect(svg.contains("Gradient"), "W13 SVG must contain authored gradient treatment: %s" % asset_id, failures)
        _expect(not seen_svg_contents.has(svg), "W13 representative assets must not be duplicate SVG payloads: %s" % asset_id, failures)
        seen_svg_contents[svg] = true
        var texture := load(runtime_path)
        _expect(texture is Texture2D, "Godot must import W13 SVG as Texture2D: %s" % asset_id, failures)

    _expect(int(kind_counts.get("player", 0)) == 2, "W13 must contain two player visual identities", failures)
    _expect(int(kind_counts.get("enemy_visual", 0)) == 8, "W13 must contain eight enemy visual identities", failures)
    _expect(int(kind_counts.get("boss", 0)) == 1, "W13 must contain one representative boss visual", failures)
    _expect(int(kind_counts.get("ark", 0)) == 1, "W13 must contain one Ark visual", failures)
    _expect(int(kind_counts.get("region", 0)) == 1, "W13 must contain the Twilight Shipyard region visual", failures)
    _expect(int(kind_counts.get("hud", 0)) == 1, "W13 must contain one HUD chrome asset", failures)
    _expect(int(kind_counts.get("vfx", 0)) == 1, "W13 must contain one representative VFX asset", failures)
    _expect(Catalog.PLAYER_IDS.size() == 2, "presentation catalog must expose two players", failures)
    _expect(Catalog.ENEMY_IDS.size() == 8, "presentation catalog must expose eight enemy visuals", failures)
    _expect(Catalog.enemy_visual_id("boss", 7) == "boss_drowned_navigator", "boss visual mapping must be explicit", failures)
    _expect(Catalog.enemy_visual_id("runner", 7) in Catalog.ENEMY_IDS, "runner visual mapping must stay inside representative enemy set", failures)
    _expect(Catalog.enemy_visual_id("swarm", 8) in Catalog.ENEMY_IDS, "swarm visual mapping must stay inside representative enemy set", failures)

    var baseline_layout := RepresentativeHud.layout_for(Vector2(1280.0, 720.0))
    var notice: Rect2 = baseline_layout["notice"]
    var weapon: Rect2 = baseline_layout["weapon"]
    _expect(not notice.intersects(weapon), "W13 baseline HUD field log and loadout panels must not overlap", failures)
    _expect(not baseline_layout["player"].intersects(baseline_layout["ark"]), "W13 baseline survivor and Ark panels must not overlap", failures)
    _expect(not baseline_layout["ark"].intersects(baseline_layout["pause"]), "W13 baseline Ark and pause panels must not overlap", failures)

    var shell_resource: Resource = load("res://game/ui/main_shell.tscn")
    _expect(shell_resource is PackedScene, "main shell must remain loadable with W13 presentation", failures)
    if shell_resource is PackedScene:
        var shell_scene: PackedScene = shell_resource as PackedScene
        var shell: Node = shell_scene.instantiate()
        _expect(shell.get_node_or_null("W13Environment") != null, "main shell must mount W13 environment", failures)
        _expect(shell.get_node_or_null("W13RepresentativeArt") != null, "main shell must mount W13 representative art layer", failures)
        _expect(shell.get_node_or_null("ScreenUI/W13RepresentativeHud") != null, "main shell must mount W13 representative HUD in fixed screen UI", failures)
        shell.free()
    var showcase_resource: Resource = load("res://game/presentation/w13_showcase.tscn")
    _expect(showcase_resource is PackedScene, "W13 showcase scene must load for rendered review", failures)
    return failures


static func _expect(condition: bool, message: String, failures: Array[String]) -> void:
    if not condition:
        failures.append(message)
