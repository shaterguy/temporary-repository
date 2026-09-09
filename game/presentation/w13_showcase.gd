extends Node2D

const Catalog = preload("res://game/presentation/art_catalog.gd")
const RepresentativeHud = preload("res://game/presentation/representative_hud.gd")
const BASELINE_SIZE := Vector2(1280.0, 720.0)

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
        draw_texture_rect(environment, Rect2(Vector2.ZERO, BASELINE_SIZE), false)
    draw_rect(Rect2(Vector2.ZERO, BASELINE_SIZE), Color(0.02, 0.03, 0.06, 0.10), true)

    _sprite("player_aurora", Vector2(178.0, 474.0), Vector2(88.0, 104.0), sin(_elapsed * 2.0) * 0.02)
    _sprite("player_cinder", Vector2(300.0, 492.0), Vector2(88.0, 104.0), -sin(_elapsed * 2.0) * 0.02)
    _sprite("ark_lantern_bastion", Vector2(640.0, 468.0), Vector2(224.0, 140.0), sin(_elapsed * 1.1) * 0.006)

    var enemy_positions: Array[Vector2] = [
        Vector2(204.0, 226.0), Vector2(350.0, 310.0), Vector2(466.0, 214.0), Vector2(586.0, 306.0),
        Vector2(720.0, 218.0), Vector2(842.0, 314.0), Vector2(958.0, 222.0), Vector2(968.0, 438.0),
    ]
    for index in range(Catalog.ENEMY_IDS.size()):
        var center: Vector2 = enemy_positions[index]
        draw_circle(center + Vector2(0.0, 15.0), 31.0, Color(0.035, 0.045, 0.075, 0.72))
        _sprite(str(Catalog.ENEMY_IDS[index]), center, Vector2(76.0, 76.0), sin(_elapsed * 1.7 + index) * 0.045)
        draw_arc(center, 43.0, 0.0, TAU, 32, Color(0.55, 0.43, 0.70, 0.20), 2.0, true)

    var boss_center := Vector2(1110.0, 370.0)
    _sprite("boss_drowned_navigator", boss_center, Vector2(148.0, 170.0), sin(_elapsed * 1.3) * 0.018)
    var vfx: Texture2D = _textures.get("vfx_phase_burst")
    if vfx != null:
        var pulse := 122.0 + sin(_elapsed * 3.0) * 8.0
        _sprite("vfx_phase_burst", boss_center, Vector2.ONE * pulse, _elapsed * 0.18, Color(1.0, 1.0, 1.0, 0.76))
    draw_circle(boss_center, 91.0, Color(0.96, 0.34, 0.19, 0.055))
    draw_arc(boss_center, 92.0, -PI * 0.5, PI * 1.15, 56, Color(1.0, 0.69, 0.27, 0.98), 6.0, true)

    _draw_runtime_hud()


func _draw_runtime_hud() -> void:
    var layout: Dictionary = RepresentativeHud.layout_for(BASELINE_SIZE)
    _draw_panel(layout["player"], "SURVIVOR", "HP 100   ACTIVE", Color(0.96, 0.70, 0.34, 1.0))
    _draw_panel(layout["ark"], "LANTERN ARK", "HULL 240   ROUTE RISK   TRAVEL", Color(0.96, 0.62, 0.28, 1.0))
    _draw_panel(layout["pause"], "PAUSE", "II", Color(0.63, 0.78, 0.90, 1.0))
    _draw_panel(layout["notice"], "FIELD LOG", "WAVE INBOUND - MATERIAL PHASE", Color(0.72, 0.62, 0.96, 1.0), 13)
    _draw_panel(layout["weapon"], "LOADOUT", "SHADE HALO   CIRCUIT 065   PHASE MATERIAL", Color(0.57, 0.77, 0.92, 1.0))


func _draw_panel(rect: Rect2, title: String, line: String, accent: Color, line_size: int = 16) -> void:
    var panel: Texture2D = _textures.get("hud_lantern_panel")
    if panel != null:
        draw_texture_rect(panel, rect, false, Color(1.0, 1.0, 1.0, 0.96))
    else:
        draw_rect(rect, Color(0.04, 0.07, 0.11, 0.92), true)
        draw_rect(rect, Color(0.32, 0.39, 0.48, 0.95), false, 2.0)
    draw_rect(Rect2(rect.position + Vector2(12.0, 13.0), Vector2(5.0, rect.size.y - 26.0)), accent, true)
    var font := ThemeDB.fallback_font
    draw_string(font, rect.position + Vector2(28.0, 27.0), title, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 42.0, 13, Color(0.75, 0.82, 0.90, 1.0))
    draw_string(font, rect.position + Vector2(28.0, rect.size.y - 20.0), line, HORIZONTAL_ALIGNMENT_LEFT, rect.size.x - 42.0, line_size, Color(0.96, 0.93, 0.86, 1.0))


func _sprite(asset_id: String, center: Vector2, size: Vector2, rotation: float = 0.0, modulate: Color = Color.WHITE) -> void:
    var texture: Texture2D = _textures.get(asset_id)
    if texture == null:
        return
    draw_set_transform(center, rotation, Vector2.ONE)
    draw_texture_rect(texture, Rect2(-size * 0.5, size), false, modulate)
    draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
