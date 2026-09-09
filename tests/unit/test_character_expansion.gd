extends RefCounted

const CharacterCatalogScript = preload("res://game/data/character_catalog.gd")
const CharacterRoleModelScript = preload("res://game/combat/character_role_model.gd")
const WorldCampaignModelScript = preload("res://game/world/world_campaign_model.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []
    _test_catalog_contract(failures)
    _test_unlock_progression(failures)
    _test_role_mechanics(failures)
    return failures


static func _test_catalog_contract(failures: Array[String]) -> void:
    var ids := CharacterCatalogScript.character_ids()
    if ids.size() != 6:
        failures.append("W16 character catalog must expose exactly 6 playable role definitions")
        return

    var seen_ids: Dictionary = {}
    var seen_roles: Dictionary = {}
    for character_id in ids:
        var definition := CharacterCatalogScript.definition(character_id)
        if definition.is_empty():
            failures.append("W16 character definition missing for %s" % character_id)
            continue
        var role_id := str(definition.get("role_id", ""))
        if seen_ids.has(character_id):
            failures.append("W16 duplicate character id: %s" % character_id)
        if seen_roles.has(role_id):
            failures.append("W16 duplicate gameplay role: %s" % role_id)
        seen_ids[character_id] = true
        seen_roles[role_id] = true
        for field in ["display_name", "role_name", "summary", "unlock_text", "tutorial", "mechanic_text"]:
            if str(definition.get(field, "")).is_empty():
                failures.append("W16 %s missing required field %s" % [character_id, field])


static func _test_unlock_progression(failures: Array[String]) -> void:
    var world = WorldCampaignModelScript.new()
    var fresh := CharacterCatalogScript.unlocked_character_ids(world)
    if fresh.size() != 2 or not fresh.has(CharacterCatalogScript.ID_AURORA) or not fresh.has(CharacterCatalogScript.ID_CINDER):
        failures.append("W16 fresh campaign must start with Aurora and Cinder only")

    var begin_first: Dictionary = world.begin_expedition("rescue_dockhands")
    if not bool(begin_first.get("ok", false)):
        failures.append("W16 unlock fixture could not start first expedition")
        return
    var settle_first: Dictionary = world.settle_expedition(
        "w16-unlock-first",
        "success",
        {},
        {"record_id": "echo-w16-first"},
        {}
    )
    if not bool(settle_first.get("ok", false)):
        failures.append("W16 unlock fixture could not settle first expedition")
        return

    var after_first := CharacterCatalogScript.unlocked_character_ids(world)
    for expected_id in [
        CharacterCatalogScript.ID_AURORA,
        CharacterCatalogScript.ID_CINDER,
        CharacterCatalogScript.ID_RIVET,
        CharacterCatalogScript.ID_MNEME,
        CharacterCatalogScript.ID_VESPER,
    ]:
        if not after_first.has(expected_id):
            failures.append("W16 first rescue path did not unlock expected character %s" % expected_id)
    if after_first.has(CharacterCatalogScript.ID_VEIL):
        failures.append("W16 first rescue path unlocked Veil before its phase/route condition")

    var begin_second: Dictionary = world.begin_expedition("preserve_smuggler_route")
    if not bool(begin_second.get("ok", false)):
        failures.append("W16 unlock fixture could not start second expedition")
        return
    var settle_second: Dictionary = world.settle_expedition("w16-unlock-second", "success")
    if not bool(settle_second.get("ok", false)):
        failures.append("W16 unlock fixture could not settle second expedition")
        return
    var after_second := CharacterCatalogScript.unlocked_character_ids(world)
    if after_second.size() != 6:
        failures.append("W16 campaign must expose all 6 character roles by segment 2 fallback progression")


static func _test_role_mechanics(failures: Array[String]) -> void:
    var role = CharacterRoleModelScript.new()

    role.configure(CharacterCatalogScript.definition(CharacterCatalogScript.ID_AURORA))
    role.on_circuit_activated()
    role.on_circuit_activated()
    var architect_first := role.attack_modifiers("cause-a", false)
    var architect_repeat := role.attack_modifiers("cause-a", false)
    var architect_second := role.attack_modifiers("cause-b", false)
    var architect_empty := role.attack_modifiers("cause-c", false)
    if not is_equal_approx(float(architect_first.get("damage_multiplier", 1.0)), 1.35):
        failures.append("W16 circuit architect did not consume a circuit charge for +35% damage")
    if bool(architect_repeat.get("first_for_cause", true)) or not is_equal_approx(float(architect_repeat.get("damage_multiplier", 1.0)), 1.35):
        failures.append("W16 repeated causal action did not reuse architect modifier without double-consuming state")
    if not is_equal_approx(float(architect_second.get("damage_multiplier", 1.0)), 1.35) or not is_equal_approx(float(architect_empty.get("damage_multiplier", 1.0)), 1.0):
        failures.append("W16 circuit architect charge cap/consumption is not deterministic")

    role.configure(CharacterCatalogScript.definition(CharacterCatalogScript.ID_CINDER))
    var escort := role.attack_modifiers("escort-a", true)
    if not is_equal_approx(float(escort.get("damage_multiplier", 1.0)), 1.20) or role.incoming_armor_bonus(true) != 3:
        failures.append("W16 close escort did not apply its near-Ark attack/defense contract")
    if role.incoming_armor_bonus(false) != 0:
        failures.append("W16 close escort retained armor outside the Ark radius")

    role.configure(CharacterCatalogScript.definition(CharacterCatalogScript.ID_RIVET))
    var engineer_repair := 0
    for index in range(4):
        var engineer := role.attack_modifiers("engineer-%d" % index, true)
        engineer_repair += int(engineer.get("repair_amount", 0))
    if engineer_repair != CharacterRoleModelScript.ENGINEER_REPAIR_AMOUNT:
        failures.append("W16 Ark engineer did not produce exactly one repair pulse per four near-Ark attack causes")

    role.configure(CharacterCatalogScript.definition(CharacterCatalogScript.ID_VEIL))
    role.on_phase_changed()
    var scout_first := role.attack_modifiers("phase-a", false)
    var scout_second := role.attack_modifiers("phase-b", false)
    var scout_empty := role.attack_modifiers("phase-c", false)
    if not is_equal_approx(float(scout_first.get("damage_multiplier", 1.0)), 1.30) or not is_equal_approx(float(scout_second.get("damage_multiplier", 1.0)), 1.30) or not is_equal_approx(float(scout_empty.get("damage_multiplier", 1.0)), 1.0):
        failures.append("W16 phase scout did not expose exactly two post-transition boosted attack causes")

    role.configure(CharacterCatalogScript.definition(CharacterCatalogScript.ID_MNEME))
    if not is_equal_approx(role.echo_damage_multiplier(), 1.50):
        failures.append("W16 echo recorder did not expose the intended limited replay damage multiplier")

    role.configure(CharacterCatalogScript.definition(CharacterCatalogScript.ID_VESPER))
    var observer := role.attack_modifiers("observer-a", false)
    if not is_equal_approx(float(observer.get("observer_followup_scale", 0.0)), 0.55) or not is_equal_approx(role.observer_range(), 720.0):
        failures.append("W16 ranged observer did not expose its one-cause long-range follow-up contract")
