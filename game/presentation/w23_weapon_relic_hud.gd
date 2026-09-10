extends Control

const ArtCatalogScript = preload("res://game/presentation/w23_weapon_relic_art_catalog.gd")
const RepresentativeHudScript = preload("res://game/presentation/representative_hud.gd")
const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const RelicCatalogScript = preload("res://game/data/relic_catalog.gd")

const WEAPON_SIZE := Vector2(52.0, 52.0)
const RELIC_SIZE := Vector2(28.0, 28.0)
const PANEL_MAX_SIZE := Vector2(282.0, 108.0)
const PANEL_MIN_WIDTH: float = 236.0

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
    var panel_width := minf(PANEL_MAX_SIZE.x, maxf(PANEL_MIN_WIDTH, viewport_size.x * 0.22))
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
        var base: Dictionary = RepresentativeHudScript.layout_for(viewport_size)
        var pause_rect: Rect2 = base.get("pause", Rect2())
        var top_y := pause_rect.position.y + pause_rect.size.y + pad
        panel.position = Vector2(
            maxf(pad, viewport_size.x - pad - panel_size.x),
            minf(top_y, maxf(pad, viewport_size.y - pad - panel_size.y))
        )
        placement = "combat-upper-right-rail"
    return {
        "panel": panel,
        "placement": placement,
        "safe_margin": pad,
    }


static func weapon_label_for(weapon_id: String) -> String:
    var card: Dictionary = WeaponPartCatalogScript.choice_card(weapon_id)
    return str(card.get("label", "선택 무장")) if not card.is_empty() else "선택 무장"


static func relic_label_for(relic_id: String) -> String:
    var card: Dictionary = RelicCatalogScript.selection_card(relic_id)
    return str(card.get("label", "유물")) if not card.is_empty() else "유물"


func visual_snapshot() -> Dictionary:
    var relic_paths: Array[String] = []
    var relic_loaded: Array[bool] = []
    var relic_labels: Array[String] = []
    for relic_id: String in _relic_ids:
        relic_paths.append(ArtCatalogScript.relic_path(relic_id))
        relic_loaded.append(_relic_textures.get(relic_id) is Texture2D)
        relic_labels.append(relic_label_for(relic_id))
    var layout := layout_for(size, _is_expedition())
    return {
        "weapon_id": _weapon_id,
        "weapon_label": weapon_label_for(_weapon_id),
        "weapon_path": ArtCatalogScript.weapon_path(_weapon_id),
        "weapon_texture_loaded": _weapon_texture is Texture2D,
        "relic_ids": _relic_ids.duplicate(),
        "relic_labels": relic_labels,
        "relic_paths": relic_paths,
        "relic_textures_loaded": relic_loaded,
        "layout_version": "w23d-responsive-v2",
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


func _relic_summary() -> String:
    if _relic_ids.is_empty():
        return "유물 없음"
    var labels: Array[String] = []
    for relic_id: String in _relic_ids:
        labels.append(relic_label_for(relic_id))
    if labels.size() <= 2:
        return "유물 · %s" % " · ".join(labels)
    return "유물 · %s · %s 외 %d" % [labels[0], labels[1], labels.size() - 2]


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

    var weapon_rect := Rect2(panel.position + Vector2(12.0, 12.0), WEAPON_SIZE)
    if _weapon_texture != null:
        draw_texture_rect(_weapon_texture, weapon_rect, false, Color(1.0, 1.0, 1.0, 0.98))

    var font := get_theme_default_font()
    var text_width := maxf(72.0, panel.size.x - 78.0)
    draw_string(
        font,
        panel.position + Vector2(72.0, 27.0),
        weapon_label_for(_weapon_id),
        HORIZONTAL_ALIGNMENT_LEFT,
        text_width,
        13,
        Color(0.92, 0.88, 0.77, 1.0)
    )

    var relic_origin := panel.position + Vector2(72.0, 38.0)
    var relic_count := mini(_relic_ids.size(), 4)
    var relic_available := maxf(RELIC_SIZE.x, panel.size.x - 84.0)
    var relic_step := 34.0
    if relic_count > 1:
        relic_step = minf(relic_step, maxf(24.0, (relic_available - RELIC_SIZE.x) / float(relic_count - 1)))
    for index: int in range(relic_count):
        var relic_id: String = _relic_ids[index]
        var texture: Texture2D = _relic_textures.get(relic_id)
        if texture != null:
            var relic_rect := Rect2(relic_origin + Vector2(float(index) * relic_step, 0.0), RELIC_SIZE)
            draw_texture_rect(texture, relic_rect, false, Color(1.0, 1.0, 1.0, 0.96))

    draw_string(
        font,
        panel.position + Vector2(12.0, panel.size.y - 10.0),
        _relic_summary(),
        HORIZONTAL_ALIGNMENT_LEFT,
        panel.size.x - 24.0,
        11,
        Color(0.78, 0.86, 0.90, 1.0)
    )
