extends "res://game/world/ark_route_model.gd"

var _region_route_id: String = ""
var _region_route_config: Dictionary = {}


func configure_region_route(route_id: String, route_config: Dictionary) -> bool:
    if not route_ids().has(route_id):
        return false
    var points: Variant = route_config.get("points", null)
    if not points is PackedVector2Array or points.size() < 2:
        return false
    if int(route_config.get("threat_level", 0)) < 1 or int(route_config.get("threat_level", 0)) > 3:
        return false
    if float(route_config.get("travel_speed", 0.0)) <= 0.0:
        return false
    _region_route_id = route_id
    _region_route_config = route_config.duplicate(true)
    return true


func clear_region_route() -> void:
    _region_route_id = ""
    _region_route_config = {}


func active_region_route_id() -> String:
    return _region_route_id


func _route_config(route_id: String) -> Dictionary:
    if route_id == _region_route_id and not _region_route_config.is_empty():
        return _region_route_config.duplicate(true)
    return super._route_config(route_id)
