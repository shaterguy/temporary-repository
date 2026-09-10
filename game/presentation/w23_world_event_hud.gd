extends Control

const ArtCatalogScript = preload("res://game/presentation/w23_world_event_art_catalog.gd")
const StoryEventCatalogScript = preload("res://game/data/campaign_story_event_catalog.gd")

const CARD_MAX_WIDTH: float = 360.0
const CARD_MIN_WIDTH: float = 240.0
const FOOTER_HEIGHT: float = 32.0
const FRAME_INSET: float = 10.0
const REVEAL_DURATION: float = 0.18
const REVEAL_SLIDE: float = 12.0

var _event_id: String = ""
var _reveal: float = 1.0


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)
    queue_redraw()


func _process(delta: float) -> void:
    if _event_id.is_empty():
        return
    if _reveal < 1.0:
        _reveal = minf(1.0, _reveal + maxf(0.0, delta) / REVEAL_DURATION)
    queue_redraw()


static func layout_for(viewport_size: Vector2) -> Dictionary:
    var min_axis := minf(viewport_size.x, viewport_size.y)
    var pad := maxf(20.0, min_axis * 0.03)
    var width_target := clampf(viewport_size.x * 0.28, CARD_MIN_WIDTH, CARD_MAX_WIDTH)
    var max_width_by_viewport := maxf(1.0, viewport_size.x - pad * 2.0 - FRAME_INSET * 2.0)
    var max_width_by_height := maxf(
        1.0,
        (viewport_size.y - pad * 2.0 - FOOTER_HEIGHT - FRAME_INSET * 2.0) * (16.0 / 9.0)
    )
    var card_width := minf(width_target, minf(max_width_by_viewport, max_width_by_height))
    var card_size := Vector2(card_width, card_width * 9.0 / 16.0)
    var outer_size := card_size + Vector2(FRAME_INSET * 2.0, FRAME_INSET * 2.0 + FOOTER_HEIGHT)
    var outer_x := maxf(pad, viewport_size.x - pad - outer_size.x)
    var outer_y := clampf(
        viewport_size.y * 0.28,
        pad,
        maxf(pad, viewport_size.y - pad - outer_size.y)
    )
    var outer := Rect2(Vector2(outer_x, outer_y), outer_size)
    var card := Rect2(outer.position + Vector2(FRAME_INSET, FRAME_INSET), card_size)
    return {
        "outer": outer,
        "card": card,
        "label_baseline": card.position + Vector2(0.0, card.size.y + 24.0),
        "safe_margin": pad,
    }


static func transition_profile() -> Dictionary:
    return {
        "duration_seconds": REVEAL_DURATION,
        "max_slide_px": REVEAL_SLIDE,
        "hitbox_motion": false,
        "presentation_only": true,
    }


static func event_label_for(event_id: String) -> String:
    var event: Dictionary = StoryEventCatalogScript.event_by_id(event_id)
    return str(event.get("title", "항로의 이야기")) if not event.is_empty() else "항로의 이야기"


func show_event(event_id: String) -> bool:
    if ArtCatalogScript.event_entry(event_id).is_empty():
        clear_event()
        return false
    if event_id != _event_id:
        _reveal = 0.0
    _event_id = event_id
    queue_redraw()
    return true


func clear_event() -> void:
    if _event_id.is_empty():
        return
    _event_id = ""
    _reveal = 1.0
    queue_redraw()


func event_snapshot() -> Dictionary:
    if _event_id.is_empty():
        return {}
    var snapshot := ArtCatalogScript.event_art_snapshot(_event_id)
    var layout := layout_for(size)
    snapshot["event_label"] = event_label_for(_event_id)
    snapshot["layout_version"] = "w23d-responsive-v2"
    snapshot["outer_rect"] = layout.get("outer", Rect2())
    snapshot["card_rect"] = layout.get("card", Rect2())
    snapshot["reveal_progress"] = _reveal
    return snapshot


func _draw() -> void:
    if _event_id.is_empty():
        return
    var texture := ArtCatalogScript.event_texture(_event_id)
    if texture == null:
        return
    var layout := layout_for(size)
    var outer: Rect2 = layout.get("outer", Rect2())
    var card: Rect2 = layout.get("card", Rect2())
    var reveal_eased := _reveal * _reveal * (3.0 - 2.0 * _reveal)
    var slide := Vector2(0.0, (1.0 - reveal_eased) * REVEAL_SLIDE)
    outer.position += slide
    card.position += slide
    var alpha := clampf(reveal_eased, 0.0, 1.0)

    draw_rect(outer, Color(0.018, 0.028, 0.048, 0.90 * alpha), true)
    draw_rect(outer, Color(0.91, 0.69, 0.36, 0.66 * alpha), false, 2.0)
    draw_texture_rect(texture, card, false, Color(1.0, 1.0, 1.0, alpha))
    draw_rect(card, Color(0.72, 0.84, 0.88, 0.38 * alpha), false, 1.0)
    var font := get_theme_default_font()
    draw_string(
        font,
        card.position + Vector2(0.0, card.size.y + 24.0),
        "이야기 · %s" % event_label_for(_event_id),
        HORIZONTAL_ALIGNMENT_LEFT,
        card.size.x,
        13,
        Color(0.93, 0.86, 0.72, alpha)
    )
