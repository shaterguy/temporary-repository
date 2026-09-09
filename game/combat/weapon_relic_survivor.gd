extends "res://game/combat/character_role_survivor.gd"

const W17WeaponPartCatalogScript = preload("res://game/data/weapon_part_catalog.gd")
const EXTERNAL_TRIGGER_EVENTS: Array[String] = ["circuit_activated", "phase_changed", "ark_pressure"]


func _resolve_events(events: Array[Dictionary]) -> void:
    for event: Dictionary in events:
        var event_type: String = str(event.get("type", ""))
        if event_type != "auto_attack" and event_type != "dodge_started":
            continue
        _combat_event_generation += 1
        var causal_event: Dictionary = event.duplicate(true)
        var recipe: Dictionary = weapon_model.equipped_recipe()
        var trigger_id: String = str(recipe.get("trigger", ""))
        var trigger: Dictionary = W17WeaponPartCatalogScript.TRIGGERS.get(trigger_id, {})
        var expected_event: String = str(trigger.get("event", ""))
        if event_type == "auto_attack" and expected_event == "hit_confirmed":
            causal_event["type"] = "hit_confirmed"
        causal_event["cause_id"] = "combat-%d-%d" % [weapon_model.resolution_generation, _combat_event_generation]
        causal_event["chain_depth"] = 0
        var target_snapshot: Array[Dictionary] = _snapshot_targets()
        var context: Dictionary = _weapon_context(causal_event, target_snapshot)
        var actions: Array[Dictionary] = weapon_model.resolve_event(causal_event, context)
        for action: Dictionary in actions:
            _apply_weapon_action(action, target_snapshot)


func resolve_external_weapon_trigger(event_type: String, source_id: String, payload: Dictionary = {}) -> Array[Dictionary]:
    var actions: Array[Dictionary] = []
    if event_type not in EXTERNAL_TRIGGER_EVENTS or source_id.is_empty() or model.paused:
        return actions
    var causal_event: Dictionary = payload.duplicate(true)
    causal_event["type"] = event_type
    causal_event["cause_id"] = "external-%s-%s" % [event_type, source_id]
    causal_event["chain_depth"] = 0
    var target_snapshot: Array[Dictionary] = _snapshot_targets()
    var context: Dictionary = _weapon_context(causal_event, target_snapshot)
    if event_type == "phase_changed":
        context["phase_transition_recent"] = true
    elif event_type == "ark_pressure":
        context["ark_pressure_active"] = true
    actions = weapon_model.resolve_event(causal_event, context)
    for action: Dictionary in actions:
        _apply_weapon_action(action, target_snapshot)
    return actions
