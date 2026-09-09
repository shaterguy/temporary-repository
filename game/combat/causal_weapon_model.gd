extends RefCounted

const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const SNAPSHOT_SCHEMA: String = "causal-weapon-v1"
const LEGACY_SNAPSHOT_SCHEMA: String = "causal-weapon-v0"
const RECENT_CAUSE_LIMIT: int = 64
const DEFAULT_WEAPON_ID: String = "shade_halo"
const DEFAULT_EVENT_DAMAGE: int = 12

var equipped_weapon_id: String = DEFAULT_WEAPON_ID
var last_rejection_reason: String = ""
var resolution_generation: int = 0
var _consumed_causes: Dictionary = {}
var _cause_order: Array[String] = []


func reset() -> void:
    equipped_weapon_id = DEFAULT_WEAPON_ID
    last_rejection_reason = ""
    resolution_generation = 0
    _consumed_causes.clear()
    _cause_order.clear()


func equip_curated_weapon(weapon_id: String) -> bool:
    var recipe := WeaponPartCatalogScript.recipe_for_weapon(weapon_id)
    if recipe.is_empty():
        last_rejection_reason = "unknown_weapon"
        return false
    var validation := WeaponPartCatalogScript.validate_recipe(recipe)
    if not bool(validation.get("valid", false)):
        last_rejection_reason = str(validation.get("reason", "invalid_recipe"))
        return false
    equipped_weapon_id = weapon_id
    last_rejection_reason = ""
    return true


func equipped_recipe() -> Dictionary:
    return WeaponPartCatalogScript.recipe_for_weapon(equipped_weapon_id)


func resolve_event(event: Dictionary, context: Dictionary) -> Array[Dictionary]:
    var actions: Array[Dictionary] = []
    if bool(context.get("paused", false)):
        last_rejection_reason = "paused"
        return actions

    var recipe := equipped_recipe()
    var validation := WeaponPartCatalogScript.validate_recipe(recipe)
    if not bool(validation.get("valid", false)):
        last_rejection_reason = str(validation.get("reason", "invalid_recipe"))
        return actions

    var trigger_id := str(recipe.get("trigger", ""))
    var trigger: Dictionary = WeaponPartCatalogScript.TRIGGERS.get(trigger_id, {})
    if str(event.get("type", "")) != str(trigger.get("event", "")):
        last_rejection_reason = "trigger_mismatch"
        return actions

    var chain_depth := int(event.get("chain_depth", 0))
    if chain_depth >= WeaponPartCatalogScript.MAX_CHAIN_DEPTH:
        last_rejection_reason = "chain_limit"
        return actions

    var cause_id := str(event.get("cause_id", ""))
    if cause_id.is_empty():
        last_rejection_reason = "missing_cause_id"
        return actions
    var cause_key := "%s|%s" % [cause_id, equipped_weapon_id]
    if _consumed_causes.has(cause_key):
        last_rejection_reason = "duplicate_cause"
        return actions

    var delivery_id := str(recipe.get("delivery", ""))
    var transform_id := str(recipe.get("transform", ""))
    var delivery: Dictionary = WeaponPartCatalogScript.DELIVERIES.get(delivery_id, {})
    var base_damage := maxi(1, int(event.get("damage", recipe.get("base_damage", DEFAULT_EVENT_DAMAGE))))
    var damage_multiplier := float(delivery.get("damage_multiplier", 1.0))
    var max_targets := maxi(1, int(delivery.get("max_targets", 1)))
    var transform_active := _transform_condition_met(transform_id, context)

    if transform_id == "shadow_fracture" and transform_active:
        damage_multiplier *= 1.35
    elif transform_id == "material_anchor" and transform_active:
        damage_multiplier *= 1.15
    elif transform_id == "snare_resonance" and transform_active:
        damage_multiplier *= 1.20
    elif transform_id == "ark_resonance" and transform_active:
        damage_multiplier *= 1.20

    if transform_active and (transform_id == "circuit_split" or transform_id == "ricochet_once"):
        max_targets += 1

    var selected_targets := _select_targets(event, context, max_targets)
    if selected_targets.is_empty():
        last_rejection_reason = "no_target"
        return actions

    _remember_cause(cause_key)
    resolution_generation += 1
    var resolved_damage := maxi(1, roundi(float(base_damage) * damage_multiplier))
    for target in selected_targets:
        actions.append({
            "type": "weapon_damage",
            "weapon_id": equipped_weapon_id,
            "target_id": int(target.get("id", -1)),
            "damage": resolved_damage,
            "cause_id": cause_id,
            "chain_depth": chain_depth + 1,
            "effect_order": ["trigger", "delivery", "transform"],
            "trigger": trigger_id,
            "delivery": delivery_id,
            "transform": transform_id,
            "transform_active": transform_active,
            "phase": str(context.get("phase", "material")),
            "status": "ember_mark" if transform_id == "ember_mark" and transform_active else "",
            "barrier_pressure": 6 if transform_id == "shadow_fracture" and transform_active else 0,
            "resolution_generation": resolution_generation,
        })
    last_rejection_reason = ""
    return actions


func upgrade_comparison(candidate_weapon_id: String) -> Dictionary:
    var current := equipped_recipe()
    var candidate := WeaponPartCatalogScript.recipe_for_weapon(candidate_weapon_id)
    if candidate.is_empty():
        return {"valid": false, "reason": "unknown_weapon"}
    var validation := WeaponPartCatalogScript.validate_recipe(candidate)
    if not bool(validation.get("valid", false)):
        return {"valid": false, "reason": str(validation.get("reason", "invalid_recipe"))}

    var changed: Array[String] = []
    for field in ["trigger", "delivery", "transform", "base_damage"]:
        if current.get(field) != candidate.get(field):
            changed.append(str(field))
    var current_cost := WeaponPartCatalogScript.recipe_cost(current)
    var candidate_cost := WeaponPartCatalogScript.recipe_cost(candidate)
    var transform_id := str(candidate.get("transform", ""))
    var transform: Dictionary = WeaponPartCatalogScript.TRANSFORMS.get(transform_id, {})
    return {
        "valid": true,
        "from_weapon": equipped_weapon_id,
        "to_weapon": candidate_weapon_id,
        "changed_fields": changed,
        "energy_before": current_cost,
        "energy_after": candidate_cost,
        "energy_delta": candidate_cost - current_cost,
        "base_damage_before": int(current.get("base_damage", DEFAULT_EVENT_DAMAGE)),
        "base_damage_after": int(candidate.get("base_damage", DEFAULT_EVENT_DAMAGE)),
        "condition": str(transform.get("condition", "always")),
        "max_energy": WeaponPartCatalogScript.MAX_ENERGY_BUDGET,
        "max_chain_depth": WeaponPartCatalogScript.MAX_CHAIN_DEPTH,
    }


func snapshot() -> Dictionary:
    return {
        "schema": SNAPSHOT_SCHEMA,
        "equipped_weapon_id": equipped_weapon_id,
        "resolution_generation": resolution_generation,
        "consumed_causes": _cause_order.duplicate(),
    }


func restore_snapshot(snapshot_state: Dictionary) -> bool:
    var schema := str(snapshot_state.get("schema", ""))
    var weapon_id := ""
    var generation := 0
    var restored_causes: Array = []
    if schema == SNAPSHOT_SCHEMA:
        weapon_id = str(snapshot_state.get("equipped_weapon_id", ""))
        generation = int(snapshot_state.get("resolution_generation", 0))
        var raw_causes: Variant = snapshot_state.get("consumed_causes", [])
        if not raw_causes is Array:
            return false
        restored_causes = raw_causes
    elif schema == LEGACY_SNAPSHOT_SCHEMA:
        weapon_id = str(snapshot_state.get("weapon", DEFAULT_WEAPON_ID))
        generation = 0
        restored_causes = []
    else:
        return false

    if generation < 0 or not equip_curated_weapon(weapon_id):
        return false
    _consumed_causes.clear()
    _cause_order.clear()
    for raw_cause in restored_causes:
        var cause_key := str(raw_cause)
        if cause_key.is_empty() or _consumed_causes.has(cause_key):
            continue
        _consumed_causes[cause_key] = true
        _cause_order.append(cause_key)
        if _cause_order.size() >= RECENT_CAUSE_LIMIT:
            break
    resolution_generation = generation
    last_rejection_reason = ""
    return true


func _transform_condition_met(transform_id: String, context: Dictionary) -> bool:
    match transform_id:
        "circuit_split":
            return bool(context.get("crosses_circuit_boundary", false))
        "shadow_fracture":
            return str(context.get("phase", "material")) == "shadow"
        "material_anchor":
            return str(context.get("phase", "material")) == "material"
        "ricochet_once", "ember_mark":
            return true
        "snare_resonance":
            return "snare" in context.get("active_circuit_modules", [])
        "ark_resonance":
            return bool(context.get("ark_pressure_active", false))
        "phase_afterglow":
            return bool(context.get("phase_transition_recent", false))
        _:
            return false


func _select_targets(event: Dictionary, context: Dictionary, limit: int) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var candidates: Array[Dictionary] = []
    var raw_targets: Variant = context.get("targets", [])
    if raw_targets is Array:
        for item in raw_targets:
            if item is Dictionary and bool(item.get("active", true)) and int(item.get("id", -1)) >= 0:
                candidates.append(item)
    _sort_targets_by_id(candidates)

    var primary_id := int(event.get("target_id", -1))
    if primary_id >= 0:
        for candidate in candidates:
            if int(candidate.get("id", -1)) == primary_id:
                result.append(candidate)
                break
    for candidate in candidates:
        if result.size() >= limit:
            break
        var candidate_id := int(candidate.get("id", -1))
        var duplicate := false
        for selected in result:
            if int(selected.get("id", -1)) == candidate_id:
                duplicate = true
                break
        if not duplicate:
            result.append(candidate)
    return result


static func _sort_targets_by_id(candidates: Array[Dictionary]) -> void:
    for index in range(1, candidates.size()):
        var current: Dictionary = candidates[index]
        var current_id := int(current.get("id", -1))
        var cursor := index - 1
        while cursor >= 0 and int(candidates[cursor].get("id", -1)) > current_id:
            candidates[cursor + 1] = candidates[cursor]
            cursor -= 1
        candidates[cursor + 1] = current


func _remember_cause(cause_key: String) -> void:
    _consumed_causes[cause_key] = true
    _cause_order.append(cause_key)
    while _cause_order.size() > RECENT_CAUSE_LIMIT:
        var expired := _cause_order.pop_front()
        _consumed_causes.erase(expired)
