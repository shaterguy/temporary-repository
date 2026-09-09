extends Node2D

const BossArtCatalog = preload("res://game/presentation/boss_art_catalog.gd")
const BossCatalog = preload("res://game/data/boss_catalog.gd")
const CANVAS_SIZE := Vector2(1280.0, 720.0)
const COLUMNS := 5
const ROWS := 2
const CELL_SIZE := Vector2(232.0, 258.0)
const ORIGIN := Vector2(44.0, 118.0)
const GAP := Vector2(14.0, 18.0)

var _textures: Dictionary = {}


func _ready() -> void:
    for boss_id in BossArtCatalog.boss_ids():
        var resource := load(BossArtCatalog.path_for(boss_id))
        if resource is Texture2D:
            _textures[boss_id] = resource
    queue_redraw()


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, CANVAS_SIZE), Color("07101b"), true)
    draw_rect(Rect2(Vector2(0.0, 0.0), Vector2(CANVAS_SIZE.x, 88.0)), Color("0d1c2c"), true)
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(44.0, 42.0), "LANTERNFALL · W20 BOSS IDENTITY CONTACT SHEET", HORIZONTAL_ALIGNMENT_LEFT, 900.0, 24, Color("f4dfb7"))
    draw_string(font, Vector2(44.0, 70.0), "10 authored identities · review silhouette, hierarchy, clipping and separation · runtime danger telegraphs remain authoritative", HORIZONTAL_ALIGNMENT_LEFT, 1160.0, 15, Color("9bb0c5"))

    var boss_ids := BossArtCatalog.boss_ids()
    for index in range(boss_ids.size()):
        _draw_boss_cell(index, str(boss_ids[index]))

    draw_string(font, Vector2(44.0, 694.0), "Automated render evidence is not a human visual PASS.", HORIZONTAL_ALIGNMENT_LEFT, 760.0, 14, Color("d29c7d"))


func _draw_boss_cell(index: int, boss_id: String) -> void:
    var column := index % COLUMNS
    var row := index / COLUMNS
    var cell_pos := ORIGIN + Vector2(float(column) * (CELL_SIZE.x + GAP.x), float(row) * (CELL_SIZE.y + GAP.y))
    var cell := Rect2(cell_pos, CELL_SIZE)
    var profile := BossArtCatalog.profile_for(boss_id)
    var boss_profile := BossCatalog.profile_for_boss(boss_id)
    var accent := Color(str(profile.get("accent", "#ffffff")))

    draw_rect(cell, Color("0b1724"), true)
    draw_rect(cell, Color(accent, 0.58), false, 2.0)
    draw_rect(Rect2(cell.position + Vector2(8.0, 8.0), Vector2(5.0, cell.size.y - 16.0)), Color(accent, 0.90), true)

    var center := cell.position + Vector2(cell.size.x * 0.5 + 4.0, 112.0)
    draw_circle(center, 84.0, Color(0.02, 0.04, 0.07, 0.92))
    draw_circle(center, 73.0, Color(accent, 0.08))
    draw_arc(center, 82.0, 0.0, TAU, 64, Color(accent, 0.42), 2.0, true)

    var texture: Texture2D = _textures.get(boss_id)
    if texture != null:
        var scale := clampf(float(profile.get("scale", 1.0)), 1.0, 1.20)
        var sprite_size := Vector2(122.0, 138.0) * scale
        draw_texture_rect(texture, Rect2(center - sprite_size * 0.5, sprite_size), false)

    var font := ThemeDB.fallback_font
    draw_string(font, cell.position + Vector2(22.0, 206.0), boss_id.to_upper(), HORIZONTAL_ALIGNMENT_LEFT, cell.size.x - 32.0, 13, Color("f0eadf"))
    var pattern := str(boss_profile.get("pattern_shape", "unknown")).to_upper()
    var region := str(boss_profile.get("parent_region_id", "unknown")).replace("_", " ").to_upper()
    draw_string(font, cell.position + Vector2(22.0, 228.0), "%s · %s" % [pattern, region], HORIZONTAL_ALIGNMENT_LEFT, cell.size.x - 32.0, 11, Color(accent, 0.92))
    draw_string(font, cell.position + Vector2(22.0, 248.0), "HP %d · R %d" % [int(boss_profile.get("max_health", 0)), int(boss_profile.get("radius", 0))], HORIZONTAL_ALIGNMENT_LEFT, cell.size.x - 32.0, 11, Color("8ea4b8"))
