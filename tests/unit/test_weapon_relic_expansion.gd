extends RefCounted

const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const RelicCatalogScript = preload("res://game/data/relic_catalog.gd")
const WeaponBuildCatalogScript = preload("res://game/data/weapon_build_catalog.gd")
const CausalWeaponModelScript = preload("res://game/combat/causal_weapon_model.gd")
const WeaponRelicSurvivorScript = preload("res://game/combat/weapon_relic_survivor.gd")
const ChoiceModelScript = preload("res://game/ui/weapon_relic_choice_model.gd")

class FakeTargetProvider:
    extends Node
    var health: int = 100

    func combat_target_snapshot() -> Array[Dictionary]:
        return [{"id": 1, "active": health > 0, "position": Vector2(24.0, 0.0)}]

    func apply_target_damage(target_id: int, damage: int) -> bool:
        if target_id != 1 or damage <= 0 or health <= 0:
            return false
        health = maxi(0, health - damage)
        return true


static func run() -> Array[String]:
    var failures: Array[String] = []
    var weapon_counts: Dictionary = WeaponPartCatalogScript.catalog_counts()
    if int(weapon_counts.get("triggers", 0)) != 6 or int(weapon_counts.get("deliveries", 0)) != 6 or int(weapon_counts.get("transforms", 0)) != 8:
        failures.append("W17 changed the retained W09 6/6/8 part contract")
    if int(weapon_counts.get("curated_weapons", 0)) != 18:
        failures.append("W17 curated catalog does not contain exactly 18 weapons")

    var recipe_signatures: Dictionary = {}
    for weapon_id: String in WeaponPartCatalogScript.weapon_ids():
        var recipe: Dictionary = WeaponPartCatalogScript.recipe_for_weapon(weapon_id)
        var validation: Dictionary = WeaponPartCatalogScript.validate_recipe(recipe)
        var card: Dictionary = WeaponPartCatalogScript.choice_card(weapon_id)
        if not bool(validation.get("valid", false)):
            failures.append("W17 curated weapon %s violates the compatibility/energy contract" % weapon_id)
        var signature: String = "%s|%s|%s" % [str(recipe.get("trigger", "")), str(recipe.get("delivery", "")), str(recipe.get("transform", ""))]
        if recipe_signatures.has(signature):
            failures.append("W17 curated weapons %s and %s share the same causal recipe" % [str(recipe_signatures[signature]), weapon_id])
        recipe_signatures[signature] = weapon_id
        for field: String in ["label", "condition", "base_damage", "energy_cost", "handling", "purpose", "max_energy", "max_chain_depth"]:
            if not card.has(field) or str(card.get(field, "")).is_empty():
                failures.append("W17 weapon choice card %s does not disclose %s" % [weapon_id, field])

    var relic_counts: Dictionary = RelicCatalogScript.catalog_counts()
    if int(relic_counts.get("families", 0)) != 8 or int(relic_counts.get("variants_per_family", 0)) != 6 or int(relic_counts.get("relics", 0)) != 48:
        failures.append("W17 relic catalog is not the required 8x6=48 set")
    for relic_id: String in RelicCatalogScript.relic_ids():
        var relic_card: Dictionary = RelicCatalogScript.selection_card(relic_id)
        for field: String in ["label", "family", "condition", "effect", "magnitude", "target_gate", "tradeoff", "purpose", "hard_limits"]:
            if not relic_card.has(field):
                failures.append("W17 relic choice card %s does not disclose %s" % [relic_id, field])
    var family_conflict: Array[String] = ["wake_edge", "wake_nail"]
    var family_conflict_validation: Dictionary = RelicCatalogScript.validate_loadout(family_conflict)
    if bool(family_conflict_validation.get("valid", true)) or str(family_conflict_validation.get("reason", "")) != "family_conflict":
        failures.append("W17 relic loadout allowed two relics from one mutually-exclusive family")

    var build_ids: Array[String] = WeaponBuildCatalogScript.build_ids()
    if build_ids.size() != 6:
        failures.append("W17 does not expose exactly 6 representative builds")
    for build_id: String in build_ids:
        var build_validation: Dictionary = WeaponBuildCatalogScript.validate_build(build_id)
        if not bool(build_validation.get("valid", false)):
            failures.append("W17 representative build %s is invalid: %s" % [build_id, str(build_validation.get("reason", "unknown"))])

    var targets: Array[Dictionary] = [
        {"id": 1, "active": true}, {"id": 2, "active": true}, {"id": 3, "active": true}, {"id": 4, "active": true}, {"id": 5, "active": true},
    ]
    var base_model = CausalWeaponModelScript.new()
    base_model.equip_curated_weapon("sunwake_lance")
    var base_actions: Array[Dictionary] = base_model.resolve_event({"type": "dodge_started", "cause_id": "w17-base", "damage": 14, "chain_depth": 0}, {"phase": "material", "targets": targets, "crosses_circuit_boundary": true, "phase_transition_recent": true})
    var relic_model = CausalWeaponModelScript.new()
    relic_model.equip_curated_weapon("sunwake_lance")
    var relic_loadout: Array[String] = ["wake_edge", "circuit_fork", "navigation_nail", "phase_ward"]
    if not relic_model.equip_relics(relic_loadout):
        failures.append("W17 representative relic loadout could not be equipped")
    var relic_actions: Array[Dictionary] = relic_model.resolve_event({"type": "dodge_started", "cause_id": "w17-relic", "damage": 14, "chain_depth": 0}, {"phase": "material", "targets": targets, "crosses_circuit_boundary": true, "phase_transition_recent": true})
    if base_actions.is_empty() or relic_actions.is_empty():
        failures.append("W17 representative build did not resolve through the causal weapon runtime")
    else:
        if relic_actions.size() <= base_actions.size():
            failures.append("W17 circuit-fork relic did not change actual target count")
        if int(relic_actions[0].get("damage", 0)) <= int(base_actions[0].get("damage", 0)):
            failures.append("W17 wake/navigation relics did not change actual resolved damage")
        if int(relic_actions[0].get("barrier_pressure", 0)) < 3:
            failures.append("W17 phase ward relic did not expose its actual pressure coefficient")
        if relic_actions[0].get("effect_order", []) != ["trigger", "delivery", "transform"]:
            failures.append("W17 changed the retained W09 causal effect order")
        if relic_actions[0].get("build_effect_order", []) != ["trigger", "delivery", "transform", "relics"]:
            failures.append("W17 did not disclose relic application after the retained causal chain")

    var duplicate: Array[Dictionary] = relic_model.resolve_event({"type": "dodge_started", "cause_id": "w17-relic", "damage": 14, "chain_depth": 0}, {"phase": "material", "targets": targets, "crosses_circuit_boundary": true, "phase_transition_recent": true})
    if not duplicate.is_empty() or relic_model.last_rejection_reason != "duplicate_cause":
        failures.append("W17 relic effects bypassed duplicate-cause suppression")
    var depth_blocked: Array[Dictionary] = relic_model.resolve_event({"type": "dodge_started", "cause_id": "w17-depth", "damage": 14, "chain_depth": WeaponPartCatalogScript.MAX_CHAIN_DEPTH}, {"phase": "material", "targets": targets, "crosses_circuit_boundary": true})
    if not depth_blocked.is_empty() or relic_model.last_rejection_reason != "chain_limit":
        failures.append("W17 relic effects bypassed the finite causal-chain depth")
    var paused_blocked: Array[Dictionary] = relic_model.resolve_event({"type": "dodge_started", "cause_id": "w17-paused", "damage": 14, "chain_depth": 0}, {"phase": "material", "targets": targets, "paused": true, "crosses_circuit_boundary": true})
    if not paused_blocked.is_empty() or relic_model.last_rejection_reason != "paused":
        failures.append("W17 level-up pause allowed causal combat mutation")

    var restored_model = CausalWeaponModelScript.new()
    if not restored_model.restore_snapshot(relic_model.snapshot()):
        failures.append("W17 weapon/relic snapshot could not restore")
    elif restored_model.equipped_relic_ids != relic_loadout:
        failures.append("W17 snapshot restore changed the equipped relic loadout")
    var v1_model = CausalWeaponModelScript.new()
    if not v1_model.restore_snapshot({"schema": "causal-weapon-v1", "equipped_weapon_id": "arklight_arc", "resolution_generation": 2, "consumed_causes": []}):
        failures.append("W17 did not preserve W09 v1 snapshot migration")
    elif not v1_model.equipped_relic_ids.is_empty():
        failures.append("W17 v1 migration invented relic state")

    var weapon_choices: Array[Dictionary] = ChoiceModelScript.weapon_choices("shade_halo", 17)
    var relic_choices: Array[Dictionary] = ChoiceModelScript.relic_choices([], 29)
    if weapon_choices.size() != 3 or relic_choices.size() != 3:
        failures.append("W17 selection model did not expose exactly 3 deterministic choices")
    else:
        var comparison: Dictionary = weapon_choices[0].get("comparison", {})
        if not comparison.has("changed_fields") or not comparison.has("condition") or not comparison.has("delivery_form"):
            failures.append("W17 weapon selection does not disclose upgrade deltas")
    var paused_choice_model = CausalWeaponModelScript.new()
    if ChoiceModelScript.apply_paused_weapon_choice(paused_choice_model, "sunwake_lance", false):
        failures.append("W17 weapon selection mutated an unpaused combat build")
    if not ChoiceModelScript.apply_paused_weapon_choice(paused_choice_model, "sunwake_lance", true):
        failures.append("W17 weapon selection could not apply while combat was paused")
    var no_relics: Array[String] = []
    if not ChoiceModelScript.apply_paused_relic_choice(paused_choice_model, no_relics, "wake_edge", true):
        failures.append("W17 relic selection could not apply while combat was paused")

    _test_runtime_trigger_bridges(failures)
    return failures


static func _test_runtime_trigger_bridges(failures: Array[String]) -> void:
    var provider := FakeTargetProvider.new()
    var runtime = WeaponRelicSurvivorScript.new()
    runtime.call("set_target_provider", provider)

    provider.health = 100
    runtime.call("equip_curated_weapon", "circuit_pulse")
    var circuit_actions: Array = runtime.call("resolve_external_weapon_trigger", "circuit_activated", "test-circuit", {})
    if circuit_actions.is_empty() or provider.health >= 100:
        failures.append("W17 circuit_birth curated weapon is not connected to actual survivor damage")

    provider.health = 100
    runtime.call("equip_curated_weapon", "phase_lance")
    var phase_actions: Array = runtime.call("resolve_external_weapon_trigger", "phase_changed", "test-phase", {})
    if phase_actions.is_empty() or provider.health >= 100:
        failures.append("W17 phase_entry curated weapon is not connected to actual survivor damage")

    provider.health = 100
    runtime.call("equip_curated_weapon", "pressure_fan")
    var ark_actions: Array = runtime.call("resolve_external_weapon_trigger", "ark_pressure", "test-ark", {})
    if ark_actions.is_empty() or provider.health >= 100:
        failures.append("W17 ark_pressure curated weapon is not connected to actual survivor damage")

    provider.health = 100
    runtime.call("equip_curated_weapon", "confirmed_bolt")
    var hit_events: Array[Dictionary] = [{"type": "auto_attack", "target_id": 1, "damage": 14, "direction": Vector2.RIGHT}]
    runtime.call("_resolve_events", hit_events)
    if provider.health >= 100:
        failures.append("W17 hit_confirmed curated weapon is not connected to actual W04 target confirmation")

    runtime.free()
    provider.free()
