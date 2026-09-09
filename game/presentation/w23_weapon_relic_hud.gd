extends Control

const ArtCatalogScript = preload("res://game/presentation/w23_weapon_relic_art_catalog.gd")
const RepresentativeHudScript = preload("res://game/presentation/representative_hud.gd")

const WEAPON_SIZE := Vector2(56.0, 56.0)
const RELIC_SIZE := Vector2(34.0, 34.0)
const PANEL_MAX_SIZE := Vector2(255.0, 88.0)
const PANEL_MIN_WIDTH: float = 216.0

var _weapon_id: String = ""
var _relic_ids: Array[String] = []
var _weapon_texture: Texture2D
var _relic_textures: Dictionary = {}
var _signature: String = ""
var _elapsed: float = 0.0


func _ready() -> void:
    mouse_filter = Control.MOUSE_FILTER_IGNORE
    set_process(true)
    _refresh(true)


func _process(delta: float) -> void:
    _elapsed += maxf(0.0, delta)
    _refresh(false)
    if not _weapon_id.is_empty():
        queue_redraw()


static func layout_for(viewport_size: Vector2, expedition: bool) -> Dictionary:
    var min_axis := minf(viewport_size.x, viewport_size.y)
    var pad := maxf(18.0, min_axis * 0.025)
    var panel_width := minf(PANEL_MAX_SIZE.x, maxf(PANEL_MIN_WIDTH, viewport_size.x * 0.20))
    panel_width = minf(panel_width, maxf(1.0, viewport_size.x - pad * 2.0))
    var panel_size := Vector2(panel_width, PANEL_MAX_SIZE.y)
    var panel := Rect2(
        Vector2(
            maxf(pad, viewport_size.x - pad - panel_size.x),
            maxf(pad, viewport_size.y - pad - panel_size.y)
        ),
        panel_size
    )
    var placement := "hub-bottom-right"
    if expedition:
        placement = "combat-bottom-right"
        var base: Dictionary = RepresentativeHudScript.layout_for(viewport_size)
        var blocked := false
        for key: String in ["weapon", "notice"]:
            var avoid: Rect2 = base.get(key, Rect2())
            if panel.intersects(avoid):
                blocked = true
                break
        if blocked:
            var pause_rect: Rect2 = base.get("pause", Rect2())
            var fallback_y := pause_rect.position.y + pause_rect.size.y + pad
            fallback_y = minf(fallback_y, viewport_size.y - pad - panel_size.y)
            panel.position = Vector2(
                maxf(pad, viewport_size.x - pad - panel_size.x),
                maxf(pad, fallback_y)
            )
            placement = "combat-right-rail"
    return {
        "panel": panel,
        "placement": placement,
        "safe_margin": pad,
    }


func visual_snapshot() -> Dictionary:
    var relic_paths: Array[String] = []
    var relic_loaded: Array[bool] = []
    for relic_id: String in _relic_ids:
        relic_paths.append(ArtCatalogScript.relic_path(relic_id))
        relic_loaded.append(_relic_textures.get(relic_id) is Texture2D)
    var layout := layout_for(size, _is_expedition())
    return {
        "weapon_id": _weapon_id,
        "weapon_path": ArtCatalogScript.weapon_path(_weapon_id),
        "weapon_texture_loaded": _weapon_texture is Texture2D,
        "relic_ids": _relic_ids.duplicate(),
        "relic_paths": relic_paths,
        "relic_textures_loaded": relic_loaded,
        "layout_version": "w23d-responsive-v1",
        "panel_rect": layout.get("panel", Rect2()),
        "placement": str(layout.get("placement", "")),
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


func _is_expedition() -> bool:
    var shell := get_parent()
    return shell != null and str(shell.get("shell_mode")) == "EXPEDITION"


func _draw() -> void:
    if _weapon_id.is_empty() or size.x < 240.0:
        return
    var layout := layout_for(size, _is_expedition())
    var panel: Rect2 = layout.get("panel", Rect2())
    if panel.size.x <= 0.0 or panel.size.y <= 0.0:
        return
    var pulse := 0.68 + sin(_elapsed * 2.1) * 0.06
    draw_rect(panel, Color(0.025, 0.04, 0.07, 0.90), true)
    draw_rect(panel, Color(0.34, 0.66, 0.75, pulse), false, 2.0)

    var weapon_rect := Rect2(panel.position + Vector2(12.0, 14.0), WEAPON_SIZE)
    if _weapon_texture != null:
        draw_texture_rect(_weapon_texture, weapon_rect, false, Color(1.0, 1.0, 1.0, 0.98))

    var font := ThemeDB.fallback_font
    var text_width := maxf(72.0, panel.size.x - 90.0)
    draw_string(
        font,
        panel.position + Vector2(76.0, 27.0),
        _weapon_id,
        HORIZONTAL_ALIGNMENT_LEFT,
        text_width,
        13,
        Color(0.92, 0.88, 0.77, 1.0)
    )

    var relic_origin := panel.position + Vector2(76.0, 38.0)
    var relic_count := mini(_relic_ids.size(), 4)
    var relic_available := maxf(RELIC_SIZE.x, panel.size.x - 88.0)
    var relic_step := 40.0
    if relic_count > 1:
        relic_step = minf(relic_step, maxf(26.0, (relic_available - RELIC_SIZE.x) / float(relic_count - 1)))
    for index: int in range(relic_count):
        var relic_id: String = _relic_ids[index]
        var texture: Texture2D = _relic_textures.get(relic_id)
        if texture != null:
            var relic_rect := Rect2(relic_origin + Vector2(float(index) * relic_step, 0.0), RELIC_SIZE)
            draw_texture_rect(texture, relic_rect, false, Color(1.0, 1.0, 1.0, 0.96))
