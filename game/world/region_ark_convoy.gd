extends "res://game/world/ark_convoy.gd"

const RegionArkRouteModelScript = preload("res://game/world/region_ark_route_model.gd")


func _init() -> void:
    model = RegionArkRouteModelScript.new()


func configure_region_route(route_id: String, route_config: Dictionary) -> bool:
    return bool(model.call("configure_region_route", route_id, route_config))


func clear_region_route() -> void:
    model.call("clear_region_route")


func active_region_route_id() -> String:
    return str(model.call("active_region_route_id"))
