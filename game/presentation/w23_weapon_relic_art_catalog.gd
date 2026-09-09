extends RefCounted

const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const RelicCatalogScript = preload("res://game/data/relic_catalog.gd")

const MANIFEST_PATH: String = "res://assets/runtime/w23/weapon_relic_art_manifest.json"
const WEAPON_ROOT: String = "res://assets/runtime/w23/weapons"
const RELIC_ROOT: String = "res://assets/runtime/w23/relics"


static func weapon_path(weapon_id: String) -> String:
    if weapon_id not in WeaponPartCatalogScript.weapon_ids():
        return ""
    return "%s/%s.svg" % [WEAPON_ROOT, weapon_id]


static func relic_path(relic_id: String) -> String:
    if RelicCatalogScript.definition(relic_id).is_empty():
        return ""
    return "%s/%s.svg" % [RELIC_ROOT, relic_id]


static func weapon_paths() -> Dictionary:
    var paths: Dictionary = {}
    for weapon_id: String in WeaponPartCatalogScript.weapon_ids():
        paths[weapon_id] = weapon_path(weapon_id)
    return paths


static func relic_paths() -> Dictionary:
    var paths: Dictionary = {}
    for relic_id: String in RelicCatalogScript.relic_ids():
        paths[relic_id] = relic_path(relic_id)
    return paths


static func counts() -> Dictionary:
    return {
        "weapons": WeaponPartCatalogScript.weapon_ids().size(),
        "relics": RelicCatalogScript.relic_ids().size(),
    }
