extends "res://game/combat/swarm_encounter.gd"

const RegionSpawnDirectorScript = preload("res://game/combat/region_spawn_director.gd")


func _init() -> void:
    _director = RegionSpawnDirectorScript.new()


func configure_region_profile(profile: Dictionary) -> bool:
    return bool(_director.call("configure_region_profile", profile))


func clear_region_profile() -> void:
    _director.call("clear_region_profile")


func region_behavior_ids() -> Array[String]:
    var result: Array[String] = []
    var raw_ids: Variant = _director.call("region_behavior_ids")
    if raw_ids is Array:
        for raw_id: Variant in raw_ids:
            result.append(str(raw_id))
    return result
