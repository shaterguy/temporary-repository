extends RefCounted

const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const RelicCatalogScript = preload("res://game/data/relic_catalog.gd")
const W23WeaponRelicArtCatalogScript = preload("res://game/presentation/w23_weapon_relic_art_catalog.gd")

const CHOICE_COUNT: int = 3


static func weapon_choices(current_weapon_id: String, seed_value: int) -> Array[Dictionary]:
    var ids: Array[String] = WeaponPartCatalogScript.weapon_ids()
    var choices: Array[Dictionary] = []
    if ids.is_empty():
        return choices
    var start_index: int = posmod(seed_value, ids.size())
    for offset: int in range(ids.size()):
        var candidate_id: String = ids[(start_index + offset) % ids.size()]
        if candidate_id == current_weapon_id:
            continue
        var card: Dictionary = WeaponPartCatalogScript.choice_card(candidate_id)
        card["comparison"] = WeaponPartCatalogScript.comparison(current_weapon_id, candidate_id)
        card["art_path"] = W23WeaponRelicArtCatalogScript.weapon_path(candidate_id)
        choices.append(card)
        if choices.size() >= CHOICE_COUNT:
            break
    return choices


static func relic_choices(equipped_relic_ids: Array[String], seed_value: int) -> Array[Dictionary]:
    var ids: Array[String] = RelicCatalogScript.relic_ids()
    var choices: Array[Dictionary] = []
    if ids.is_empty():
        return choices
    var start_index: int = posmod(seed_value, ids.size())
    for offset: int in range(ids.size()):
        var candidate_id: String = ids[(start_index + offset) % ids.size()]
        if candidate_id in equipped_relic_ids:
            continue
        var proposed: Array[String] = _copy_ids(equipped_relic_ids)
        if proposed.size() >= RelicCatalogScript.MAX_EQUIPPED_RELICS:
            proposed.pop_front()
        proposed.append(candidate_id)
        var validation: Dictionary = RelicCatalogScript.validate_loadout(proposed)
        if not bool(validation.get("valid", false)):
            continue
        var card: Dictionary = RelicCatalogScript.selection_card(candidate_id)
        card["resulting_loadout"] = proposed
        card["art_path"] = W23WeaponRelicArtCatalogScript.relic_path(candidate_id)
        choices.append(card)
        if choices.size() >= CHOICE_COUNT:
            break
    return choices


static func apply_paused_weapon_choice(player: Object, weapon_id: String, combat_paused: bool) -> bool:
    if not combat_paused or not is_instance_valid(player) or not player.has_method("equip_curated_weapon"):
        return false
    return bool(player.call("equip_curated_weapon", weapon_id))


static func apply_paused_relic_choice(player: Object, equipped_relic_ids: Array[String], relic_id: String, combat_paused: bool) -> bool:
    if not combat_paused or not is_instance_valid(player) or not player.has_method("equip_relics"):
        return false
    var proposed: Array[String] = _copy_ids(equipped_relic_ids)
    if proposed.size() >= RelicCatalogScript.MAX_EQUIPPED_RELICS:
        proposed.pop_front()
    proposed.append(relic_id)
    var validation: Dictionary = RelicCatalogScript.validate_loadout(proposed)
    if not bool(validation.get("valid", false)):
        return false
    return bool(player.call("equip_relics", proposed))


static func _copy_ids(source: Array[String]) -> Array[String]:
    var copied: Array[String] = []
    for item: String in source:
        copied.append(item)
    return copied
