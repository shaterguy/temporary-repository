extends RefCounted

const RegionCatalogScript = preload("res://game/data/region_catalog.gd")
const SNAPSHOT_SCHEMA: String = "w18-region-expedition-v1"

var active_profile: Dictionary = {}
var observed_phases: Array[String] = []
var circuit_activation_count: int = 0
var rest_reached: bool = false
var objective_generation: int = 0


func reset() -> void:
    active_profile = {}
    observed_phases.clear()
    circuit_activation_count = 0
    rest_reached = false
    objective_generation = 0


func configure(expedition_context: Dictionary) -> bool:
    reset()
    var region_id := str(expedition_context.get("region_id", ""))
    var profile := RegionCatalogScript.profile_for_region(region_id)
    if profile.is_empty():
        return false
    if not RegionCatalogScript.validate_profile(profile):
        return false
    if str(profile.get("route_id", "")) != str(expedition_context.get("route_id", "")):
        return false
    active_profile = profile.duplicate(true)
    observed_phases.append(RegionCatalogScript.PHASE_MATERIAL)
    return true


func is_active() -> bool:
    return not active_profile.is_empty()


func region_id() -> String:
    return str(active_profile.get("region_id", ""))


func parent_region_id() -> String:
    return str(active_profile.get("parent_region_id", ""))


func display_name() -> String:
    return str(active_profile.get("display_name", ""))


func route_config() -> Dictionary:
    var value: Variant = active_profile.get("route_config", {})
    return value.duplicate(true) if value is Dictionary else {}


func spawn_profile() -> Dictionary:
    if active_profile.is_empty():
        return {}
    return {
        "region_id": region_id(),
        "parent_region_id": parent_region_id(),
        "enemy_behaviors": active_profile.get("enemy_behaviors", []).duplicate(true),
    }


func phase_rule(phase_id: String) -> Dictionary:
    var rules: Variant = active_profile.get("phase_rules", {})
    if not rules is Dictionary:
        return {}
    var value: Variant = rules.get(phase_id, {})
    return value.duplicate(true) if value is Dictionary else {}


func record_phase_transition(phase_id: String) -> bool:
    if not is_active() or not [RegionCatalogScript.PHASE_MATERIAL, RegionCatalogScript.PHASE_SHADOW].has(phase_id):
        return false
    if not observed_phases.has(phase_id):
        observed_phases.append(phase_id)
        objective_generation += 1
    return true


func record_circuit_activation() -> bool:
    if not is_active():
        return false
    circuit_activation_count += 1
    objective_generation += 1
    return true


func record_route_state(route_status: String) -> bool:
    if not is_active() or route_status != "RESTING":
        return false
    if not rest_reached:
        rest_reached = true
        objective_generation += 1
    return true


func objective_complete() -> bool:
    if not is_active() or not rest_reached:
        return false
    if bool(active_profile.get("requires_both_phases", false)):
        if not observed_phases.has(RegionCatalogScript.PHASE_MATERIAL) or not observed_phases.has(RegionCatalogScript.PHASE_SHADOW):
            return false
    return circuit_activation_count >= int(active_profile.get("required_circuits", 1))


func objective_snapshot() -> Dictionary:
    if not is_active():
        return {"active": false}
    var required_circuits := int(active_profile.get("required_circuits", 1))
    return {
        "active": true,
        "region_id": region_id(),
        "parent_region_id": parent_region_id(),
        "objective_id": str(active_profile.get("objective_id", "")),
        "objective_label": str(active_profile.get("objective_label", "")),
        "observed_phases": observed_phases.duplicate(),
        "phase_count": observed_phases.size(),
        "required_phase_count": 2 if bool(active_profile.get("requires_both_phases", false)) else 1,
        "circuit_activation_count": circuit_activation_count,
        "required_circuits": required_circuits,
        "rest_reached": rest_reached,
        "complete": objective_complete(),
        "generation": objective_generation,
    }


func snapshot() -> Dictionary:
    if not is_active():
        return {}
    return {
        "schema": SNAPSHOT_SCHEMA,
        "region_id": region_id(),
        "observed_phases": observed_phases.duplicate(),
        "circuit_activation_count": circuit_activation_count,
        "rest_reached": rest_reached,
        "objective_generation": objective_generation,
    }


func restore_snapshot(snapshot_state: Dictionary, expedition_context: Dictionary) -> bool:
    if str(snapshot_state.get("schema", "")) != SNAPSHOT_SCHEMA:
        return false
    if not configure(expedition_context):
        return false
    if str(snapshot_state.get("region_id", "")) != region_id():
        reset()
        return false
    var raw_phases: Variant = snapshot_state.get("observed_phases", [])
    if not raw_phases is Array:
        reset()
        return false
    observed_phases.clear()
    for raw_phase: Variant in raw_phases:
        var phase_id := str(raw_phase)
        if not [RegionCatalogScript.PHASE_MATERIAL, RegionCatalogScript.PHASE_SHADOW].has(phase_id):
            reset()
            return false
        if not observed_phases.has(phase_id):
            observed_phases.append(phase_id)
    if not observed_phases.has(RegionCatalogScript.PHASE_MATERIAL):
        reset()
        return false
    circuit_activation_count = maxi(0, int(snapshot_state.get("circuit_activation_count", 0)))
    rest_reached = bool(snapshot_state.get("rest_reached", false))
    objective_generation = maxi(0, int(snapshot_state.get("objective_generation", 0)))
    return true
