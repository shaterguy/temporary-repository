extends Control

const ArtCatalogScript = preload("res://game/presentation/w23_weapon_relic_art_catalog.gd")

const WEAPON_SIZE := Vector2(56.0, 56.0)
const RELIC_SIZE := Vector2(34.0, 34.0)

var _weapon_id: String = ""
var _relic_ids: Array[String] = []
var _weapon_texture: Texture2D
var _relic_textures: Dictionary = {}
var _signature: String = ""


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)
    _refresh(true)


func _process(_delta: float) -> void:
    _refresh(false)


func visual_snapshot() -> Dictionary:
    var relic_paths: Array[String] = []
    var relic_loaded: Array[bool] = []
    for relic_id: String in _relic_ids:
        relic_paths.append(ArtCatalogScript.relic_path(relic_id))
        relic_loaded.append(_relic_textures.get(relic_id) is Texture2D)
    return {
        "weapon_id": _weapon_id,
        "weapon_path": ArtCatalogScript.weapon_path(_weapon_id),
        "weapon_texture_loaded": _weapon_texture is Texture2D,
        "relic_ids": _relic_ids.duplicate(),
        "relic_paths": relic_paths,
        "relic_textures_loaded": relic_loaded,
    }


func _refresh(force: bool) -> void:
    var shell := get_parent()
    if shell == null:
        return
    var weapon_id := str(shell.get("selected_weapon_id"))
    var raw_relics: Variant = shell.get("selected_relic_ids")
    var relic_ids: Array[String] = []
    if raw_relics is Array:
        for raw_relic: Variant in raw_relics:
            relic_ids.append(str(raw_relic))
    var next_signature := "%s|%s" % [weapon_id, str(relic_ids)]
    if not force and next_signature == _signature:
        return
    _signature = next_signature
    _weapon_id = weapon_id
    _relic_ids = relic_ids
    _weapon_texture = null
    _relic_textures.clear()
    var weapon_path := ArtCatalogScript.weapon_path(_weapon_id)
    if not weapon_path.is_empty():
        var weapon_resource: Resource = load(weapon_path)
        if weapon_resource is Texture2D:
            _weapon_texture = weapon_resource as Texture2D
    for relic_id: String in _relic_ids:
        var relic_path := ArtCatalogScript.relic_path(relic_id)
        if relic_path.is_empty():
            continue
        var relic_resource: Resource = load(relic_path)
        if relic_resource is Texture2D:
            _relic_textures[relic_id] = relic_resource
    queue_redraw()


func _draw() -> void:
    if _weapon_id.is_empty() or size.x < 240.0:
        return
    var panel_width := 255.0
    var panel_height := 88.0
    var origin := Vector2(size.x - panel_width - 28.0, 26.0)
    draw_rect(Rect2(origin, Vector2(panel_width, panel_height)), Color(0.025, 0.04, 0.07, 0.90), true)
    draw_rect(Rect2(origin, Vector2(panel_width, panel_height)), Color(0.34, 0.66, 0.75, 0.72), false, 2.0)
    if _weapon_texture != null:
        draw_texture_rect(_weapon_texture, Rect2(origin + Vector2(12.0, 14.0), WEAPON_SIZE), false)
    var font := ThemeDB.fallback_font
    draw_string(font, origin + Vector2(76.0, 27.0), _weapon_id, HORIZONTAL_ALIGNMENT_LEFT, 162.0, 13, Color(0.92, 0.88, 0.77, 1.0))
    var relic_origin := origin + Vector2(76.0, 38.0)
    for index: int in range(mini(_relic_ids.size(), 4)):
        var relic_id: String = _relic_ids[index]
        var texture: Texture2D = _relic_textures.get(relic_id)
        if texture != null:
            draw_texture_rect(texture, Rect2(relic_origin + Vector2(index * 40.0, 0.0), RELIC_SIZE), false)
