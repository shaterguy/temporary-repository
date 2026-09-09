extends Node2D

const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const RelicCatalogScript = preload("res://game/data/relic_catalog.gd")
const ArtCatalogScript = preload("res://game/presentation/w23_weapon_relic_art_catalog.gd")

const BASELINE_SIZE := Vector2(1280.0, 720.0)
var _weapon_textures: Dictionary = {}
var _relic_textures: Dictionary = {}


func _ready() -> void:
    for weapon_id: String in WeaponPartCatalogScript.weapon_ids():
        var resource: Resource = load(ArtCatalogScript.weapon_path(weapon_id))
        if resource is Texture2D:
            _weapon_textures[weapon_id] = resource
    for relic_id: String in RelicCatalogScript.relic_ids():
        var resource: Resource = load(ArtCatalogScript.relic_path(relic_id))
        if resource is Texture2D:
            _relic_textures[relic_id] = resource
    queue_redraw()


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, BASELINE_SIZE), Color(0.022, 0.032, 0.056, 1.0), true)
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(38.0, 38.0), "LANTERNFALL · W23B WEAPON / RELIC PRODUCTION REVIEW", HORIZONTAL_ALIGNMENT_LEFT, 1100.0, 22, Color(0.95, 0.89, 0.76, 1.0))
    draw_string(font, Vector2(38.0, 62.0), "18 curated weapons · 48 relics · runtime mapped · human visual acceptance pending", HORIZONTAL_ALIGNMENT_LEFT, 1100.0, 14, Color(0.66, 0.77, 0.86, 1.0))

    var weapon_ids := WeaponPartCatalogScript.weapon_ids()
    for index: int in range(weapon_ids.size()):
        var weapon_id: String = weapon_ids[index]
        var col := index % 9
        var row := index / 9
        var origin := Vector2(38.0 + col * 137.0, 82.0 + row * 116.0)
        draw_rect(Rect2(origin, Vector2(126.0, 106.0)), Color(0.035, 0.052, 0.084, 0.94), true)
        draw_rect(Rect2(origin, Vector2(126.0, 106.0)), Color(0.25, 0.57, 0.69, 0.55), false, 1.5)
        var texture: Texture2D = _weapon_textures.get(weapon_id)
        if texture != null:
            draw_texture_rect(texture, Rect2(origin + Vector2(31.0, 4.0), Vector2(64.0, 64.0)), false)
        draw_string(font, origin + Vector2(7.0, 84.0), weapon_id, HORIZONTAL_ALIGNMENT_CENTER, 112.0, 10, Color(0.88, 0.84, 0.75, 1.0))

    draw_string(font, Vector2(38.0, 326.0), "RELIC FAMILIES × EFFECT GLYPHS", HORIZONTAL_ALIGNMENT_LEFT, 700.0, 16, Color(0.78, 0.87, 0.91, 1.0))
    var families: Array[String] = RelicCatalogScript.FAMILY_ORDER
    var suffixes := ["edge", "nail", "fork", "ward", "lens", "pulse"]
    for family_index: int in range(families.size()):
        var family_id: String = families[family_index]
        var x := 44.0 + family_index * 154.0
        draw_string(font, Vector2(x, 351.0), family_id, HORIZONTAL_ALIGNMENT_CENTER, 128.0, 12, Color(0.67, 0.82, 0.88, 1.0))
        for variant_index: int in range(suffixes.size()):
            var relic_id := "%s_%s" % [family_id, suffixes[variant_index]]
            var y := 362.0 + variant_index * 55.0
            draw_rect(Rect2(Vector2(x, y), Vector2(128.0, 49.0)), Color(0.032, 0.046, 0.075, 0.92), true)
            var texture: Texture2D = _relic_textures.get(relic_id)
            if texture != null:
                draw_texture_rect(texture, Rect2(Vector2(x + 4.0, y + 3.0), Vector2(43.0, 43.0)), false)
            draw_string(font, Vector2(x + 50.0, y + 29.0), suffixes[variant_index], HORIZONTAL_ALIGNMENT_LEFT, 72.0, 10, Color(0.85, 0.81, 0.72, 1.0))
