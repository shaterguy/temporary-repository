extends RefCounted

const RegionCatalogScript = preload("res://game/data/region_catalog.gd")
const WorldCampaignModelScript = preload("res://game/world/world_campaign_model.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []
    var counts := RegionCatalogScript.w19_catalog_counts()
    if int(counts.get("parent_regions", 0)) != 2:
        failures.append("W19 did not expose exactly two new parent regions")
    if int(counts.get("subregion_route_profiles", 0)) != 2:
        failures.append("W19 did not expose exactly two new route profiles")
    if int(counts.get("enemy_behavior_definitions", 0)) != 12:
        failures.append("W19 did not expose exactly twelve new enemy behavior definitions")
    if int(counts.get("persistent_world_connections", 0)) != 2:
        failures.append("W19 did not expose exactly two persistent world connections")

    var full_counts := RegionCatalogScript.full_catalog_counts()
    if int(full_counts.get("parent_regions", 0)) != 4:
        failures.append("W19 full runtime catalog did not retain four expanded parent regions")
    if int(full_counts.get("subregion_route_profiles", 0)) != 6:
        failures.append("W19 full runtime catalog did not retain six route profiles")
    if int(full_counts.get("enemy_behavior_definitions", 0)) != 24:
        failures.append("W19 full runtime catalog did not expose twenty-four unique regional behaviors")

    var behavior_ids: Array[String] = []
    var route_signatures: Array[String] = []
    for region_id: String in RegionCatalogScript.all_region_ids():
        var profile := RegionCatalogScript.profile_for_region(region_id)
        if not RegionCatalogScript.validate_profile(profile):
            failures.append("W19 full region profile failed validation: %s" % region_id)
            continue
        var route: Dictionary = profile.get("route_config", {})
        var points: PackedVector2Array = route.get("points", PackedVector2Array())
        var signature := str(points)
        if route_signatures.has(signature):
            failures.append("W19 found duplicated route geometry: %s" % region_id)
        route_signatures.append(signature)
        if RegionCatalogScript.w19_region_ids().has(region_id):
            var phase_rules: Dictionary = profile.get("phase_rules", {})
            if str((phase_rules.get("material", {}) as Dictionary).get("hazard_id", "")) == str((phase_rules.get("shadow", {}) as Dictionary).get("hazard_id", "")):
                failures.append("W19 phase hazards were not distinct: %s" % region_id)
            var connection: Dictionary = profile.get("world_connection", {})
            if str(connection.get("failure_contract", "")) != "recoverable_no_dead_end":
                failures.append("W19 world connection lost its recoverable failure contract: %s" % region_id)
            for raw_behavior: Variant in profile.get("enemy_behaviors", []):
                if not raw_behavior is Dictionary:
                    failures.append("W19 behavior entry was not a dictionary: %s" % region_id)
                    continue
                var behavior_id := str((raw_behavior as Dictionary).get("behavior_id", ""))
                if behavior_id.is_empty() or behavior_ids.has(behavior_id):
                    failures.append("W19 behavior ID was empty or duplicated: %s" % behavior_id)
                else:
                    behavior_ids.append(behavior_id)
    if behavior_ids.size() != 12:
        failures.append("W19 unique behavior set size changed from twelve")

    _verify_connection(
        failures,
        "deep_rescue_patrol",
        "afterglow_frontier",
        RegionCatalogScript.REGION_ASH_RAILWAY,
        "rescue_network",
        "post_final_patrol",
        "residents"
    )
    _verify_connection(
        failures,
        "lighthouse_survey",
        "far_lantern_chain",
        RegionCatalogScript.REGION_ECLIPSE_FORTRESS,
        "survey_beacon",
        "post_final_survey",
        "lighthouse"
    )

    var failure_model = WorldCampaignModelScript.new()
    failure_model.segment_index = WorldCampaignModelScript.CAMPAIGN_SEGMENTS
    failure_model.state = WorldCampaignModelScript.STATE_POST_FINAL
    if not bool(failure_model.begin_expedition("deep_rescue_patrol").get("ok", false)):
        failures.append("W19 recoverable-failure fixture could not start")
    else:
        var failed_settlement := failure_model.settle_expedition("w19-failed-1", "failed")
        if str(failed_settlement.get("status", "")) != "SETTLED_FAILED_RECOVERABLE":
            failures.append("W19 failed connection did not remain explicitly recoverable")
        if not failure_model.has_progress_path():
            failures.append("W19 failed connection produced a world-graph dead end")

    return failures


static func _verify_connection(
    failures: Array[String],
    choice_id: String,
    expected_region_id: String,
    expected_parent_region_id: String,
    expected_unlock: String,
    expected_access: String,
    expected_axis: String
) -> void:
    var model = WorldCampaignModelScript.new()
    model.segment_index = WorldCampaignModelScript.CAMPAIGN_SEGMENTS
    model.state = WorldCampaignModelScript.STATE_POST_FINAL
    var options := model.departure_options()
    if options.size() != 2:
        failures.append("W19 post-final world graph did not expose two recoverable departures")
        return
    var start := model.begin_expedition(choice_id)
    if not bool(start.get("ok", false)):
        failures.append("W19 world connection could not start: %s" % choice_id)
        return
    var context: Dictionary = start.get("context", {})
    if str(context.get("region_id", "")) != expected_region_id:
        failures.append("W19 world connection targeted the wrong runtime region: %s" % choice_id)
    var profile := RegionCatalogScript.profile_for_region(expected_region_id)
    if str(profile.get("parent_region_id", "")) != expected_parent_region_id:
        failures.append("W19 world connection targeted the wrong parent region: %s" % choice_id)
    if str(profile.get("route_id", "")) != str(context.get("route_id", "")):
        failures.append("W19 world connection route contract drifted: %s" % choice_id)
    var connection: Dictionary = profile.get("world_connection", {})
    if str(connection.get("choice_id", "")) != choice_id or str(connection.get("persistent_axis", "")) != expected_axis:
        failures.append("W19 region profile did not describe its authoritative persistent connection: %s" % choice_id)
    if str(connection.get("support_id", "")) != str(context.get("support_id", "")):
        failures.append("W19 connection support metadata drifted from campaign context: %s" % choice_id)
    if str(connection.get("shop_modifier", "")) != str(context.get("shop_modifier", "")):
        failures.append("W19 connection shop metadata drifted from campaign context: %s" % choice_id)
    if str(connection.get("threat_route", "")) != str(context.get("threat_route", "")):
        failures.append("W19 connection threat metadata drifted from campaign context: %s" % choice_id)

    var settlement := model.settle_expedition("w19-success-%s" % choice_id, "success")
    if not bool(settlement.get("ok", false)) or not bool(settlement.get("progress_path_available", false)):
        failures.append("W19 successful connection did not preserve a valid onward path: %s" % choice_id)
    if not model.horizontal_unlocks.has(expected_unlock) or not model.access_rights.has(expected_access):
        failures.append("W19 successful connection did not persist unlock/access effects: %s" % choice_id)

    var restored = WorldCampaignModelScript.new()
    if not restored.restore_snapshot(model.snapshot()):
        failures.append("W19 persistent world connection snapshot could not restore: %s" % choice_id)
    elif not restored.horizontal_unlocks.has(expected_unlock) or not restored.access_rights.has(expected_access):
        failures.append("W19 restored world connection lost unlock/access state: %s" % choice_id)
