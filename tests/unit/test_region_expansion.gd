extends RefCounted

const RegionCatalogScript = preload("res://game/data/region_catalog.gd")
const RegionExpeditionModelScript = preload("res://game/world/region_expedition_model.gd")
const RegionArkRouteModelScript = preload("res://game/world/region_ark_route_model.gd")
const RegionSpawnDirectorScript = preload("res://game/combat/region_spawn_director.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []
    var counts := RegionCatalogScript.catalog_counts()
    if int(counts.get("parent_regions", 0)) != 2:
        failures.append("W18 catalog did not expose exactly two parent regions")
    if int(counts.get("subregion_route_profiles", 0)) != 4:
        failures.append("W18 catalog did not expose exactly four subregion route profiles")
    if int(counts.get("phase_states_per_region", 0)) != 2:
        failures.append("W18 catalog did not retain two phase states per region")
    if int(counts.get("enemy_behavior_definitions", 0)) != 12:
        failures.append("W18 catalog did not expose exactly twelve regional enemy behavior definitions")

    var behavior_ids: Array[String] = []
    var checked_behavior_parents: Array[String] = []
    var route_signatures: Array[String] = []
    for region_id: String in RegionCatalogScript.region_ids():
        var profile := RegionCatalogScript.profile_for_region(region_id)
        if not RegionCatalogScript.validate_profile(profile):
            failures.append("W18 region profile failed validation: %s" % region_id)
            continue
        var route: Dictionary = profile.get("route_config", {})
        var points: PackedVector2Array = route.get("points", PackedVector2Array())
        var signature := str(points)
        if route_signatures.has(signature):
            failures.append("W18 region route geometry was duplicated: %s" % region_id)
        route_signatures.append(signature)
        var phase_rules: Dictionary = profile.get("phase_rules", {})
        var material_rule: Dictionary = phase_rules.get("material", {})
        var shadow_rule: Dictionary = phase_rules.get("shadow", {})
        if str(material_rule.get("hazard_id", "")) == str(shadow_rule.get("hazard_id", "")):
            failures.append("W18 region phases did not expose distinct hazard rules: %s" % region_id)

        var parent_region_id := str(profile.get("parent_region_id", ""))
        if not checked_behavior_parents.has(parent_region_id):
            checked_behavior_parents.append(parent_region_id)
            for raw_behavior: Variant in profile.get("enemy_behaviors", []):
                if not raw_behavior is Dictionary:
                    failures.append("W18 behavior entry was not a dictionary: %s" % region_id)
                    continue
                var behavior_id := str(raw_behavior.get("behavior_id", ""))
                if behavior_id.is_empty() or behavior_ids.has(behavior_id):
                    failures.append("W18 enemy behavior ID was empty or duplicated: %s" % behavior_id)
                else:
                    behavior_ids.append(behavior_id)
    if checked_behavior_parents.size() != 2:
        failures.append("W18 behavior catalog was not checked once per parent region")
    if behavior_ids.size() != 12:
        failures.append("W18 unique behavior set size changed from twelve")

    var glass_profile := RegionCatalogScript.profile_for_region("brine_veins")
    var route_model = RegionArkRouteModelScript.new()
    if not route_model.configure_region_route("supply_causeway", glass_profile.get("route_config", {})):
        failures.append("W18 Glass Garden route override could not be configured")
    route_model.reset(1818)
    var route_preview := route_model.route_preview("supply_causeway")
    var destination: Vector2 = route_preview.get("destination", Vector2.ZERO)
    if not destination.is_equal_approx(Vector2(680.0, 0.0)):
        failures.append("W18 Glass Garden route override did not replace the inherited route geometry")
    if not route_model.choose_route(RegionArkRouteModelScript.JUNCTION_ID, "supply_causeway"):
        failures.append("W18 overridden route could not be selected through the inherited route contract")
    route_model.step(1.0)
    if route_model.position.is_zero_approx():
        failures.append("W18 overridden route did not advance the Ark")
    route_model.clear_region_route()
    var inherited_preview := route_model.route_preview("supply_causeway")
    var inherited_destination: Vector2 = inherited_preview.get("destination", Vector2.ZERO)
    if inherited_destination.is_equal_approx(destination):
        failures.append("W18 route override did not clear back to the inherited W06 geometry")

    var objective = RegionExpeditionModelScript.new()
    if not objective.configure({"region_id": "brine_veins", "route_id": "supply_causeway"}):
        failures.append("W18 Glass Garden objective could not configure")
    else:
        if objective.objective_complete():
            failures.append("W18 objective completed before phase/circuit/rest conditions")
        objective.record_phase_transition("shadow")
        objective.record_circuit_activation()
        if objective.objective_complete():
            failures.append("W18 objective completed before the route rest condition")
        objective.record_route_state("RESTING")
        if not objective.objective_complete():
            failures.append("W18 Glass Garden objective did not complete after both phases, circuit and rest")
        var snapshot := objective.snapshot()
        var restored = RegionExpeditionModelScript.new()
        if not restored.restore_snapshot(snapshot, {"region_id": "brine_veins", "route_id": "supply_causeway"}):
            failures.append("W18 objective snapshot could not be restored")
        elif not restored.objective_complete():
            failures.append("W18 restored objective lost completion state")

    var archive_objective = RegionExpeditionModelScript.new()
    if not archive_objective.configure({"region_id": "drowned_archive", "route_id": "supply_causeway"}):
        failures.append("W18 Flooded Archive objective could not configure")
    else:
        archive_objective.record_phase_transition("shadow")
        archive_objective.record_circuit_activation()
        archive_objective.record_route_state("RESTING")
        if archive_objective.objective_complete():
            failures.append("W18 Flooded Archive ignored its second required circuit")
        archive_objective.record_circuit_activation()
        if not archive_objective.objective_complete():
            failures.append("W18 Flooded Archive objective did not complete after its second circuit")

    var stage_zero = RegionExpeditionModelScript.new()
    if stage_zero.configure({"region_id": "saltglass_reach", "route_id": "supply_causeway"}):
        failures.append("W18 incorrectly overrode the inherited stage-zero region")

    var director = RegionSpawnDirectorScript.new()
    if not director.configure_region_profile({
        "region_id": "brine_veins",
        "parent_region_id": RegionCatalogScript.REGION_GLASS_GARDEN,
        "enemy_behaviors": glass_profile.get("enemy_behaviors", []).duplicate(true),
    }):
        failures.append("W18 regional spawn profile could not be configured")
    director.reset(1818)
    director.set_route_context(Vector2.RIGHT, 2)
    var events := director.step(RegionSpawnDirectorScript.FIRST_SPAWN_TIME, Vector2.ZERO)
    var regional_warning := _first_event(events, "telegraph")
    if regional_warning.is_empty():
        failures.append("W18 regional director did not emit its first warning")
    else:
        if str(regional_warning.get("behavior_id", "")).is_empty():
            failures.append("W18 regional warning did not carry a behavior identity")
        if str(regional_warning.get("region_id", "")) != "brine_veins":
            failures.append("W18 regional warning lost its region identity")
        if not behavior_ids.has(str(regional_warning.get("behavior_id", ""))):
            failures.append("W18 regional warning referenced an unknown behavior identity")

    return failures


static func _first_event(events: Array[Dictionary], event_type: String) -> Dictionary:
    for event: Dictionary in events:
        if str(event.get("type", "")) == event_type:
            return event
    return {}
