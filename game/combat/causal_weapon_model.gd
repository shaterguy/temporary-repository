extends RefCounted

const WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const RelicCatalogScript = preload("res://game/data/relic_catalog.gd")
const SNAPSHOT_SCHEMA: String = "causal-weapon-v2"
const LEGACY_SNAPSHOT_SCHEMA: String = "causal-weapon-v1"
const OLDEST_SNAPSHOT_SCHEMA: String = "causal-weapon-v0"
const RECENT_CAUSE_LIMIT: int = 64
const DEFAULT_WEAPON_ID: String = "shade_halo"
const DEFAULT_EVENT_DAMAGE: int = 12

var equipped_weapon_id: String = DEFAULT_WEAPON_ID
var equipped_relic_ids: Array[String] = []
var last_rejection_reason: String = ""
var resolution_generation: int = 0
var _consumed_causes: Dictionary = {}
var _cause_order: Array[String] = []

func reset() -> void:
    equipped_weapon_id = DEFAULT_WEAPON_ID
    equipped_relic_ids.clear()
    last_rejection_reason = ""
    resolution_generation = 0
    _consumed_causes.clear()
    _cause_order.clear()

func equip_curated_weapon(weapon_id: String) -> bool:
    var recipe: Dictionary = WeaponPartCatalogScript.recipe_for_weapon(weapon_id)
    if recipe.is_empty():
        last_rejection_reason = "unknown_weapon"
        return false
    var validation: Dictionary = WeaponPartCatalogScript.validate_recipe(recipe)
    if not bool(validation.get("valid", false)):
        last_rejection_reason = str(validation.get("reason", "invalid_recipe"))
        return false
    equipped_weapon_id = weapon_id
    last_rejection_reason = ""
    return true

func equip_relics(relic_ids_value: Array[String]) -> bool:
    var validation: Dictionary = RelicCatalogScript.validate_loadout(relic_ids_value)
    if not bool(validation.get("valid", false)):
        last_rejection_reason = str(validation.get("reason", "invalid_relic_loadout"))
        return false
    equipped_relic_ids = _copy_ids(relic_ids_value)
    last_rejection_reason = ""
    return true

func equipped_recipe() -> Dictionary:
    return WeaponPartCatalogScript.recipe_for_weapon(equipped_weapon_id)

func build_status_snapshot() -> Dictionary:
    return {"weapon_id": equipped_weapon_id, "weapon_card": WeaponPartCatalogScript.choice_card(equipped_weapon_id), "relic_ids": _copy_ids(equipped_relic_ids), "relic_cards": _relic_cards(), "relic_limits": RelicCatalogScript.hard_limits()}

func resolve_event(event: Dictionary, context: Dictionary) -> Array[Dictionary]:
    var actions: Array[Dictionary] = []
    if bool(context.get("paused", false)):
        last_rejection_reason = "paused"
        return actions
    var recipe: Dictionary = equipped_recipe()
    var validation: Dictionary = WeaponPartCatalogScript.validate_recipe(recipe)
    if not bool(validation.get("valid", false)):
        last_rejection_reason = str(validation.get("reason", "invalid_recipe"))
        return actions
    var relic_validation: Dictionary = RelicCatalogScript.validate_loadout(equipped_relic_ids)
    if not bool(relic_validation.get("valid", false)):
        last_rejection_reason = str(relic_validation.get("reason", "invalid_relic_loadout"))
        return actions
    var trigger_id: String = str(recipe.get("trigger", ""))
    var trigger: Dictionary = WeaponPartCatalogScript.TRIGGERS.get(trigger_id, {})
    if str(event.get("type", "")) != str(trigger.get("event", "")):
        last_rejection_reason = "trigger_mismatch"
        return actions
    var chain_depth: int = int(event.get("chain_depth", 0))
    if chain_depth >= WeaponPartCatalogScript.MAX_CHAIN_DEPTH:
        last_rejection_reason = "chain_limit"
        return actions
    var cause_id: String = str(event.get("cause_id", ""))
    if cause_id.is_empty():
        last_rejection_reason = "missing_cause_id"
        return actions
    var cause_key: String = "%s|%s" % [cause_id, equipped_weapon_id]
    if _consumed_causes.has(cause_key):
        last_rejection_reason = "duplicate_cause"
        return actions
    var delivery_id: String = str(recipe.get("delivery", ""))
    var transform_id: String = str(recipe.get("transform", ""))
    var delivery: Dictionary = WeaponPartCatalogScript.DELIVERIES.get(delivery_id, {})
    var base_damage: int = maxi(1, int(event.get("damage", recipe.get("base_damage", DEFAULT_EVENT_DAMAGE))))
    var damage_multiplier: float = float(delivery.get("damage_multiplier", 1.0))
    var max_targets: int = maxi(1, int(delivery.get("max_targets", 1)))
    var transform_active: bool = _transform_condition_met(transform_id, context)
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
    var relic_effects: Dictionary = RelicCatalogScript.effect_summary(equipped_relic_ids, recipe, context, max_targets)
    if not bool(relic_effects.get("valid", false)):
        last_rejection_reason = str(relic_effects.get("reason", "invalid_relic_loadout"))
        return actions
    damage_multiplier *= float(relic_effects.get("damage_multiplier", 1.0))
    max_targets += int(relic_effects.get("extra_targets", 0))
    var selected_targets: Array[Dictionary] = _select_targets(event, context, max_targets)
    if selected_targets.is_empty():
        last_rejection_reason = "no_target"
        return actions
    _remember_cause(cause_key)
    resolution_generation += 1
    var resolved_damage: int = maxi(1, roundi(float(base_damage) * damage_multiplier) + int(relic_effects.get("flat_damage", 0)))
    var resolved_barrier_pressure: int = int(relic_effects.get("barrier_pressure", 0))
    if transform_id == "shadow_fracture" and transform_active:
        resolved_barrier_pressure += 6
    for target: Dictionary in selected_targets:
        actions.append({
            "type": "weapon_damage",
            "weapon_id": equipped_weapon_id,
            "relic_ids": _copy_ids(equipped_relic_ids),
            "activated_relic_ids": relic_effects.get("activated_relic_ids", []).duplicate(),
            "relic_effects": relic_effects.get("disclosures", []).duplicate(true),
            "target_id": int(target.get("id", -1)),
            "damage": resolved_damage,
            "cause_id": cause_id,
            "chain_depth": chain_depth + 1,
            "effect_order": ["trigger", "delivery", "transform"],
            "build_effect_order": ["trigger", "delivery", "transform", "relics"],
            "trigger": trigger_id,
            "delivery": delivery_id,
            "transform": transform_id,
            "transform_active": transform_active,
            "phase": str(context.get("phase", "material")),
            "status": "ember_mark" if transform_id == "ember_mark" and transform_active else "",
            "barrier_pressure": resolved_barrier_pressure,
            "resolution_generation": resolution_generation,
            "hard_limits": RelicCatalogScript.hard_limits(),
        })
    last_rejection_reason = ""
    return actions

func upgrade_comparison(candidate_weapon_id: String) -> Dictionary:
    return WeaponPartCatalogScript.comparison(equipped_weapon_id, candidate_weapon_id)

func snapshot() -> Dictionary:
    return {"schema": SNAPSHOT_SCHEMA, "equipped_weapon_id": equipped_weapon_id, "equipped_relic_ids": _copy_ids(equipped_relic_ids), "resolution_generation": resolution_generation, "consumed_causes": _cause_order.duplicate()}

func restore_snapshot(snapshot_state: Dictionary) -> bool:
    var schema: String = str(snapshot_state.get("schema", ""))
    var weapon_id: String = ""
    var generation: int = 0
    var restored_causes: Array = []
    var restored_relic_ids: Array[String] = []
    if schema == SNAPSHOT_SCHEMA:
        weapon_id = str(snapshot_state.get("equipped_weapon_id", ""))
        generation = int(snapshot_state.get("resolution_generation", 0))
        var raw_causes: Variant = snapshot_state.get("consumed_causes", [])
        var raw_relics: Variant = snapshot_state.get("equipped_relic_ids", [])
        if not raw_causes is Array or not raw_relics is Array:
            return false
        restored_causes = raw_causes
        for raw_relic: Variant in raw_relics:
            restored_relic_ids.append(str(raw_relic))
    elif schema == LEGACY_SNAPSHOT_SCHEMA:
        weapon_id = str(snapshot_state.get("equipped_weapon_id", ""))
        generation = int(snapshot_state.get("resolution_generation", 0))
        var legacy_causes: Variant = snapshot_state.get("consumed_causes", [])
        if not legacy_causes is Array:
            return false
        restored_causes = legacy_causes
    elif schema == OLDEST_SNAPSHOT_SCHEMA:
        weapon_id = str(snapshot_state.get("weapon", DEFAULT_WEAPON_ID))
        generation = 0
        restored_causes = []
    else:
        return false
    if generation < 0 or not equip_curated_weapon(weapon_id) or not equip_relics(restored_relic_ids):
        return false
    _consumed_causes.clear()
    _cause_order.clear()
    for raw_cause: Variant in restored_causes:
        var cause_key: String = str(raw_cause)
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
        "circuit_split": return bool(context.get("crosses_circuit_boundary", false))
        "shadow_fracture": return str(context.get("phase", "material")) == "shadow"
        "material_anchor": return str(context.get("phase", "material")) == "material"
        "ricochet_once", "ember_mark": return true
        "snare_resonance": return "snare" in context.get("active_circuit_modules", [])
        "ark_resonance": return bool(context.get("ark_pressure_active", false))
        "phase_afterglow": return bool(context.get("phase_transition_recent", false))
        _: return false

func _select_targets(event: Dictionary, context: Dictionary, limit: int) -> Array[Dictionary]:
    var result: Array[Dictionary] = []
    var candidates: Array[Dictionary] = []
    var raw_targets: Variant = context.get("targets", [])
    if raw_targets is Array:
        for item: Variant in raw_targets:
            if item is Dictionary and bool(item.get("active", true)) and int(item.get("id", -1)) >= 0:
                candidates.append(item)
    _sort_targets_by_id(candidates)
    var primary_id: int = int(event.get("target_id", -1))
    if primary_id >= 0:
        for candidate: Dictionary in candidates:
            if int(candidate.get("id", -1)) == primary_id:
                result.append(candidate)
                break
    for candidate: Dictionary in candidates:
        if result.size() >= limit:
            break
        var candidate_id: int = int(candidate.get("id", -1))
        var duplicate: bool = false
        for selected: Dictionary in result:
            if int(selected.get("id", -1)) == candidate_id:
                duplicate = true
                break
        if not duplicate:
            result.append(candidate)
    return result

static func _sort_targets_by_id(candidates: Array[Dictionary]) -> void:
    for index: int in range(1, candidates.size()):
        var current: Dictionary = candidates[index]
        var current_id: int = int(current.get("id", -1))
        var cursor: int = index - 1
        while cursor >= 0 and int(candidates[cursor].get("id", -1)) > current_id:
            candidates[cursor + 1] = candidates[cursor]
            cursor -= 1
        candidates[cursor + 1] = current

func _remember_cause(cause_key: String) -> void:
    _consumed_causes[cause_key] = true
    _cause_order.append(cause_key)
    while _cause_order.size() > RECENT_CAUSE_LIMIT:
        var expired: String = str(_cause_order.pop_front())
        _consumed_causes.erase(expired)

func _copy_ids(source: Array[String]) -> Array[String]:
    var copied: Array[String] = []
    for item: String in source:
        copied.append(item)
    return copied

func _relic_cards() -> Array[Dictionary]:
    var cards: Array[Dictionary] = []
    for relic_id: String in equipped_relic_ids:
        cards.append(RelicCatalogScript.selection_card(relic_id))
    return cards
