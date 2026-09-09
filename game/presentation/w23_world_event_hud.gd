extends Control

const ArtCatalogScript = preload("res://game/presentation/w23_world_event_art_catalog.gd")

var _event_id: String = ""


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    queue_redraw()


func show_event(event_id: String) -> bool:
    if ArtCatalogScript.event_entry(event_id).is_empty():
        clear_event()
        return false
    _event_id = event_id
    queue_redraw()
    return true


func clear_event() -> void:
    if _event_id.is_empty():
        return
    _event_id = ""
    queue_redraw()


func event_snapshot() -> Dictionary:
    if _event_id.is_empty():
        return {}
    return ArtCatalogScript.event_art_snapshot(_event_id)


func _draw() -> void:
    if _event_id.is_empty():
        return
    var texture := ArtCatalogScript.event_texture(_event_id)
    if texture == null:
        return
    var card_size := Vector2(320.0, 180.0)
    var origin := Vector2(maxf(24.0, size.x - card_size.x - 44.0), 86.0)
    var outer := Rect2(origin - Vector2(10.0, 10.0), card_size + Vector2(20.0, 38.0))
    draw_rect(outer, Color(0.018, 0.028, 0.048, 0.90), true)
    draw_rect(outer, Color(0.91, 0.69, 0.36, 0.66), false, 2.0)
    draw_texture_rect(texture, Rect2(origin, card_size), false)
    draw_rect(Rect2(origin, card_size), Color(0.72, 0.84, 0.88, 0.38), false, 1.0)
    var font := ThemeDB.fallback_font
    draw_string(
        font,
        origin + Vector2(0.0, card_size.y + 24.0),
        "STORY SIGNAL · %s" % _event_id.to_upper(),
        HORIZONTAL_ALIGNMENT_LEFT,
        card_size.x,
        13,
        Color(0.93, 0.86, 0.72, 1.0)
    )
