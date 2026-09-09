extends Node2D

const Catalog = preload("res://game/presentation/art_catalog.gd")

var _textures: Dictionary = {}
var _elapsed: float = 0.0


func _ready() -> void:
    for asset_id in Catalog.all_asset_ids():
        var resource := load(Catalog.path_for(asset_id))
        if resource is Texture2D:
            _textures[asset_id] = resource
    queue_redraw()


func _process(delta: float) -> void:
    _elapsed += maxf(0.0, delta)
    queue_redraw()


func _draw() -> void:
    var environment: Texture2D = _textures.get("environment_twilight_shipyard")
    if environment != null:
        draw_texture_rect(environment, Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), false)
    draw_rect(Rect2(Vector2.ZERO, Vector2(1280.0, 720.0)), Color(0.02, 0.03, 0.06, 0.10), true)

    _sprite("player_aurora", Vector2(180.0, 524.0), Vector2(88.0, 104.0), sin(_elapsed * 2.0) * 0.02)
    _sprite("player_cinder", Vector2(295.0, 524.0), Vector2(88.0, 104.0), -sin(_elapsed * 2.0) * 0.02)
    _sprite("ark_lantern_bastion", Vector2(644.0, 542.0), Vector2(224.0, 140.0))
    _sprite("boss_drowned_navigator", Vector2(1112.0, 392.0), Vector2(148.0, 170.0), sin(_elapsed * 1.3) * 0.018)

    var enemy_positions := [
        Vector2(164.0, 246.0), Vector2(286.0, 250.0), Vector2(408.0, 244.0), Vector2(530.0, 250.0),
        Vector2(652.0, 244.0), Vector2(774.0, 250.0), Vector2(896.0, 244.0), Vector2(1018.0, 250.0),
    ]
    for index in range(Catalog.ENEMY_IDS.size()):
        _sprite(str(Catalog.ENEMY_IDS[index]), enemy_positions[index], Vector2(76.0, 76.0), sin(_elapsed * 1.7 + index) * 0.045)
        draw_arc(enemy_positions[index], 45.0, 0.0, TAU, 32, Color(0.63, 0.48, 0.72, 0.26), 2.0, true)

    var vfx: Texture2D = _textures.get("vfx_phase_burst")
    if vfx != null:
        var pulse := 122.0 + sin(_elapsed * 3.0) * 8.0
        _sprite("vfx_phase_burst", Vector2(1112.0, 392.0), Vector2.ONE * pulse, _elapsed * 0.18, Color(1.0, 1.0, 1.0, 0.76))
    draw_arc(Vector2(1112.0, 392.0), 92.0, -PI * 0.5, PI * 1.15, 56, Color(1.0, 0.69, 0.27, 0.98), 6.0, true)

    var panel: Texture2D = _textures.get("hud_lantern_panel")
    if panel != null:
        draw_texture_rect(panel, Rect2(Vector2(30.0, 28.0), Vector2(270.0, 68.0)), false)
        draw_texture_rect(panel, Rect2(Vector2(465.0, 28.0), Vector2(350.0, 68.0)), false)
        draw_texture_rect(panel, Rect2(Vector2(935.0, 28.0), Vector2(315.0, 68.0)), false)
    var font := ThemeDB.fallback_font
    draw_string(font, Vector2(47.0, 55.0), "SURVIVOR  HP 100", HORIZONTAL_ALIGNMENT_LEFT, 230.0, 16, Color(1.0, 0.91, 0.72, 1.0))
    draw_string(font, Vector2(486.0, 55.0), "ARK / TWILIGHT SHIPYARD", HORIZONTAL_ALIGNMENT_LEFT, 310.0, 16, Color(1.0, 0.85, 0.58, 1.0))
    draw_string(font, Vector2(958.0, 55.0), "PHASE MATERIAL / VFX HIGH", HORIZONTAL_ALIGNMENT_LEFT, 270.0, 15, Color(0.82, 0.89, 1.0, 1.0))
    draw_string(font, Vector2(38.0, 690.0), "W13 REPRESENTATIVE ART • RUNTIME VECTOR ASSETS • DANGER TELEGRAPH ABOVE DECORATION", HORIZONTAL_ALIGNMENT_LEFT, 1100.0, 15, Color(0.76, 0.83, 0.91, 0.96))


func _sprite(asset_id: String, center: Vector2, size: Vector2, rotation: float = 0.0, modulate: Color = Color.WHITE) -> void:
    var texture: Texture2D = _textures.get(asset_id)
    if texture == null:
        return
    draw_set_transform(center, rotation, Vector2.ONE)
    draw_texture_rect(texture, Rect2(-size * 0.5, size), false, modulate)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
