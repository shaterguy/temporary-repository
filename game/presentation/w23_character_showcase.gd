extends Node2D

const CharacterCatalogScript = preload("res://game/data/character_catalog.gd")
const BASELINE_SIZE := Vector2(1280.0, 720.0)
const LARGE_SIZE := Vector2(128.0, 160.0)
const COMBAT_SIZE := Vector2(48.0, 60.0)
const CENTERS := [
    Vector2(220.0, 230.0), Vector2(640.0, 230.0), Vector2(1060.0, 230.0),
    Vector2(220.0, 520.0), Vector2(640.0, 520.0), Vector2(1060.0, 520.0),
]

var _textures: Dictionary = {}
var _environment: Texture2D


func _ready() -> void:
    var environment_resource: Resource = load("res://assets/runtime/w13/environment_twilight_shipyard.svg")
    if environment_resource is Texture2D:
        _environment = environment_resource as Texture2D
    for character_id in CharacterCatalogScript.character_ids():
        var definition := CharacterCatalogScript.definition(character_id)
        var resource: Resource = load(str(definition.get("representative_art", "")))
        if resource is Texture2D:
            _textures[character_id] = resource
    queue_redraw()


func _draw() -> void:
    if _environment != null:
        draw_texture_rect(_environment, Rect2(Vector2.ZERO, BASELINE_SIZE), false, Color(0.44, 0.50, 0.58, 0.42))
    draw_rect(Rect2(Vector2.ZERO, BASELINE_SIZE), Color(0.025, 0.035, 0.065, 0.82), true)
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(48.0, 54.0), "LANTERNFALL · W23A CHARACTER PRODUCTION REVIEW", HORIZONTAL_ALIGNMENT_LEFT, 900.0, 24, Color(0.95, 0.89, 0.76, 1.0))
    draw_string(font, Vector2(48.0, 82.0), "Large identity + exact 48×60 combat-scale read · human visual acceptance pending", HORIZONTAL_ALIGNMENT_LEFT, 1100.0, 16, Color(0.68, 0.77, 0.86, 1.0))

    var ids := CharacterCatalogScript.character_ids()
    for index in range(ids.size()):
        var character_id: String = ids[index]
        var definition := CharacterCatalogScript.definition(character_id)
        var center: Vector2 = CENTERS[index]
        var card := Rect2(center - Vector2(172.0, 112.0), Vector2(344.0, 224.0))
        draw_rect(card, Color(0.035, 0.055, 0.09, 0.94), true)
        draw_rect(card, _role_color(str(definition.get("role_id", ""))), false, 2.0)
        var texture: Texture2D = _textures.get(character_id)
        if texture != null:
            draw_texture_rect(texture, Rect2(center + Vector2(-135.0, -80.0), LARGE_SIZE), false)
            draw_circle(center + Vector2(112.0, 30.0), 36.0, Color(0.03, 0.04, 0.06, 0.85))
            draw_texture_rect(texture, Rect2(center + Vector2(88.0, 0.0), COMBAT_SIZE), false)
            draw_arc(center + Vector2(112.0, 30.0), 41.0, 0.0, TAU, 32, _role_color(str(definition.get("role_id", ""))), 2.0, true)
        draw_string(font, center + Vector2(-5.0, -55.0), str(definition.get("display_name", character_id)), HORIZONTAL_ALIGNMENT_LEFT, 130.0, 20, Color(0.97, 0.91, 0.81, 1.0))
        draw_string(font, center + Vector2(-5.0, -28.0), str(definition.get("role_name", "")), HORIZONTAL_ALIGNMENT_LEFT, 130.0, 15, Color(0.72, 0.84, 0.91, 1.0))
        draw_string(font, center + Vector2(-5.0, 2.0), "48×60", HORIZONTAL_ALIGNMENT_LEFT, 85.0, 13, Color(0.58, 0.68, 0.77, 1.0))
        draw_string(font, center + Vector2(-5.0, 28.0), character_id, HORIZONTAL_ALIGNMENT_LEFT, 95.0, 12, _role_color(str(definition.get("role_id", ""))))


func _role_color(role_id: String) -> Color:
    match role_id:
        CharacterCatalogScript.ROLE_CIRCUIT_ARCHITECT:
            return Color(0.42, 0.92, 0.92, 0.95)
        CharacterCatalogScript.ROLE_CLOSE_ESCORT:
            return Color(1.0, 0.48, 0.25, 0.95)
        CharacterCatalogScript.ROLE_ARK_ENGINEER:
            return Color(0.96, 0.78, 0.30, 0.95)
        CharacterCatalogScript.ROLE_PHASE_SCOUT:
            return Color(0.60, 0.46, 1.0, 0.95)
        CharacterCatalogScript.ROLE_ECHO_RECORDER:
            return Color(0.78, 0.48, 0.96, 0.95)
        CharacterCatalogScript.ROLE_RANGED_OBSERVER:
            return Color(0.46, 0.86, 0.58, 0.95)
    return Color(0.75, 0.82, 0.90, 0.95)
