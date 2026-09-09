extends Node2D

const ArtCatalogScript = preload("res://game/presentation/w23_world_event_art_catalog.gd")
const BASELINE_SIZE := Vector2(1280.0, 720.0)

var _page: String = "enemy_region"


func set_page(page: String) -> void:
    _page = page
    queue_redraw()


func _ready() -> void:
    queue_redraw()


func _draw() -> void:
    draw_rect(Rect2(Vector2.ZERO, BASELINE_SIZE), Color(0.020, 0.029, 0.050, 1.0), true)
    if _page == "events":
        _draw_event_page()
    else:
        _draw_enemy_region_page()


func _draw_enemy_region_page() -> void:
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(36.0, 38.0), "LANTERNFALL · W23C ENEMY / REGION PRODUCTION REVIEW", HORIZONTAL_ALIGNMENT_LEFT, 1160.0, 22, Color(0.95, 0.89, 0.76, 1.0))
    draw_string(font, Vector2(36.0, 62.0), "30 tracked enemy visual roles · 5 runtime region environments · human acceptance pending", HORIZONTAL_ALIGNMENT_LEFT, 1160.0, 14, Color(0.66, 0.77, 0.86, 1.0))
    var regions := ArtCatalogScript.region_entries()
    for index: int in range(regions.size()):
        var entry: Dictionary = regions[index]
        var x := 36.0 + float(index) * 244.0
        var texture := ArtCatalogScript.region_texture(str(entry.get("id", "")))
        draw_rect(Rect2(Vector2(x, 80.0), Vector2(232.0, 102.0)), Color(0.035, 0.052, 0.084, 1.0), true)
        if texture != null:
            draw_texture_rect(texture, Rect2(Vector2(x, 80.0), Vector2(232.0, 82.0)), false)
        draw_string(font, Vector2(x + 5.0, 177.0), str(entry.get("id", "")), HORIZONTAL_ALIGNMENT_CENTER, 222.0, 11, Color(0.90, 0.84, 0.72, 1.0))

    var enemies := ArtCatalogScript.enemy_entries()
    for index: int in range(enemies.size()):
        var entry: Dictionary = enemies[index]
        var col := index % 6
        var row := index / 6
        var origin := Vector2(43.0 + float(col) * 204.0, 205.0 + float(row) * 98.0)
        draw_rect(Rect2(origin, Vector2(190.0, 88.0)), Color(0.030, 0.044, 0.071, 0.96), true)
        draw_rect(Rect2(origin, Vector2(190.0, 88.0)), Color(0.23, 0.52, 0.62, 0.46), false, 1.0)
        var texture := ArtCatalogScript.enemy_texture(str(entry.get("id", "")))
        if texture != null:
            var native := texture.get_size()
            var h := 58.0
            var w := h if native.y <= 0.0 else h * native.x / native.y
            draw_texture_rect(texture, Rect2(origin + Vector2(8.0 + (62.0 - w) * 0.5, 6.0), Vector2(w, h)), false)
        draw_string(font, origin + Vector2(73.0, 38.0), str(entry.get("id", "")), HORIZONTAL_ALIGNMENT_LEFT, 110.0, 10, Color(0.87, 0.83, 0.75, 1.0))
        draw_string(font, origin + Vector2(73.0, 57.0), str(entry.get("parent_region", "")), HORIZONTAL_ALIGNMENT_LEFT, 110.0, 9, Color(0.57, 0.73, 0.80, 1.0))


func _draw_event_page() -> void:
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(36.0, 38.0), "LANTERNFALL · W23C CHOICE EVENT ILLUSTRATION REVIEW", HORIZONTAL_ALIGNMENT_LEFT, 1160.0, 22, Color(0.95, 0.89, 0.76, 1.0))
    draw_string(font, Vector2(36.0, 62.0), "40 authored event frames · 8 per parent region · presentation-only mapping · human narrative/visual acceptance pending", HORIZONTAL_ALIGNMENT_LEFT, 1160.0, 14, Color(0.66, 0.77, 0.86, 1.0))
    var events := ArtCatalogScript.event_entries()
    for index: int in range(events.size()):
        var entry: Dictionary = events[index]
        var col := index % 8
        var row := index / 8
        var origin := Vector2(36.0 + float(col) * 153.0, 88.0 + float(row) * 121.0)
        draw_rect(Rect2(origin, Vector2(143.0, 109.0)), Color(0.030, 0.044, 0.071, 0.98), true)
        var texture := ArtCatalogScript.event_texture(str(entry.get("id", "")))
        if texture != null:
            draw_texture_rect(texture, Rect2(origin + Vector2(3.0, 3.0), Vector2(137.0, 77.0)), false)
        draw_rect(Rect2(origin + Vector2(3.0, 3.0), Vector2(137.0, 77.0)), Color(0.63, 0.73, 0.78, 0.36), false, 1.0)
        draw_string(font, origin + Vector2(4.0, 97.0), str(entry.get("id", "")), HORIZONTAL_ALIGNMENT_CENTER, 135.0, 10, Color(0.90, 0.84, 0.72, 1.0))
