extends RefCounted

const WorldCampaignScript = preload("res://game/world/world_campaign_model.gd")
const RegionCatalogScript = preload("res://game/data/region_catalog.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []
    _verify_topology(failures)
    _verify_pre_w21_migration(failures)
    _verify_recoverable_final_branch(failures)
    return failures


static func _verify_topology(failures: Array[String]) -> void:
    if WorldCampaignScript.SCHEMA != "lanternfall-world-v2":
        failures.append("W21 world schema did not advance to lanternfall-world-v2")
    if WorldCampaignScript.PRE_W21_SCHEMA != "lanternfall-world-v1":
        failures.append("W21 did not retain the pre-W21 world schema identifier")
    if WorldCampaignScript.PAYLOAD_SCHEMA != "lanternfall-save-payload-v1":
        failures.append("W21 changed the W12 save payload envelope schema")
    if WorldCampaignScript.CAMPAIGN_SEGMENTS != 4 or WorldCampaignScript.FINAL_BRANCH_SEGMENT != 3:
        failures.append("W21 campaign did not expose three retained stages plus one final branch stage")

    var expected_parent_ids: Array[String] = [
        "twilight_shipyard",
        "glass_garden",
        "flooded_archive",
        "ash_railway",
        "eclipse_fortress",
    ]
    if WorldCampaignScript.campaign_parent_region_ids() != expected_parent_ids:
        failures.append("W21 campaign parent-region topology did not expose exactly five ordered identities")

    var expected_stage_parents := [
        ["twilight_shipyard"],
        ["glass_garden"],
        ["flooded_archive"],
        ["ash_railway", "eclipse_fortress"],
    ]
    var campaign = WorldCampaignScript.new()
    campaign.reset(210921)
    for stage: int in range(WorldCampaignScript.CAMPAIGN_SEGMENTS):
        var options := campaign.departure_options()
        if options.size() != 2:
            failures.append("W21 campaign stage %d did not retain exactly two departures" % stage)
            return
        var stage_parent_ids: Array[String] = []
        for option: Dictionary in options:
            var parent_region_id := str(option.get("parent_region_id", ""))
            if parent_region_id.is_empty():
                failures.append("W21 campaign option omitted parent-region identity at stage %d" % stage)
            elif not stage_parent_ids.has(parent_region_id):
                stage_parent_ids.append(parent_region_id)
            if stage > 0:
                var profile := RegionCatalogScript.profile_for_region(str(option.get("next_region", "")))
                if profile.is_empty():
                    failures.append("W21 stage %d option did not resolve through the regional runtime catalog" % stage)
                elif str(profile.get("parent_region_id", "")) != parent_region_id:
                    failures.append("W21 campaign/runtime parent-region identity drifted at stage %d" % stage)
        stage_parent_ids.sort()
        var expected: Array[String] = []
        for raw_expected: Variant in expected_stage_parents[stage]:
            expected.append(str(raw_expected))
        expected.sort()
        if stage_parent_ids != expected:
            failures.append("W21 campaign stage %d parent-region topology changed" % stage)

        var start := campaign.begin_expedition(str(options[0].get("choice_id", "")))
        if not bool(start.get("ok", false)):
            failures.append("W21 campaign stage %d could not start" % stage)
            return
        var context: Dictionary = start.get("context", {})
        if stage == WorldCampaignScript.FINAL_BRANCH_SEGMENT:
            if bool(context.get("post_final", true)):
                failures.append("W21 final regional branch was incorrectly marked post-final before completion")
            if str(context.get("parent_region_id", "")) != "ash_railway":
                failures.append("W21 first final branch did not target Ash Railway")
        var settled := campaign.settle_expedition("w21-stage-%d" % stage, "success")
        if not bool(settled.get("ok", false)):
            failures.append("W21 campaign stage %d could not settle" % stage)
            return

    if not campaign.is_campaign_complete() or campaign.segment_index != 4 or campaign.state != WorldCampaignScript.STATE_POST_FINAL:
        failures.append("W21 final regional branch did not complete into POST_FINAL at segment 4")
        return
    var post_final_options := campaign.departure_options()
    if post_final_options.size() != 2:
        failures.append("W21 POST_FINAL did not retain the two W19 continuation departures")
        return
    var post_start := campaign.begin_expedition(str(post_final_options[1].get("choice_id", "")))
    var post_context: Dictionary = post_start.get("context", {})
    if not bool(post_start.get("ok", false)) or not bool(post_context.get("post_final", false)):
        failures.append("W21 post-final continuation was not identified as post-final")
        return
    if str(post_context.get("parent_region_id", "")) != "eclipse_fortress":
        failures.append("W21 post-final continuation lost Eclipse Fortress routing")
    var post_settlement := campaign.settle_expedition("w21-post-final-1", "success")
    if not bool(post_settlement.get("ok", false)) or campaign.segment_index != 4 or campaign.post_final_cycle != 1:
        failures.append("W21 post-final continuation changed campaign completion instead of advancing its cycle")


static func _verify_pre_w21_migration(failures: Array[String]) -> void:
    var fresh_snapshot := _pre_w21_snapshot(WorldCampaignScript.STATE_POST_FINAL)
    fresh_snapshot["salvage"] = 91
    fresh_snapshot["failure_count"] = 2
    fresh_snapshot["applied_settlement_ids"] = ["settlement:pre-w21-stage-2"]
    var fresh = WorldCampaignScript.new()
    if not fresh.restore_snapshot(fresh_snapshot):
        failures.append("W21 could not restore a fresh pre-W21 POST_FINAL snapshot")
    else:
        if fresh.segment_index != 3 or fresh.state != WorldCampaignScript.STATE_HUB:
            failures.append("fresh pre-W21 completion was not promoted into the new final branch hub")
        if fresh.salvage != 91 or fresh.failure_count != 2 or not fresh.applied_settlement_ids.has("settlement:pre-w21-stage-2"):
            failures.append("W21 pre-W21 migration changed retained progression/idempotency state")
        if fresh.departure_options().size() != 2:
            failures.append("fresh pre-W21 completion did not expose the two W21 final-region choices")

    var payload_world := fresh_snapshot.duplicate(true)
    payload_world.erase("salvage")
    payload_world.erase("failure_count")
    payload_world.erase("suspended_expedition")
    payload_world.erase("cross_run_state")
    var old_payload := {
        "payload_schema": WorldCampaignScript.PAYLOAD_SCHEMA,
        "settings": {"reduced_flash": true},
        "profile": {"salvage": 91, "failure_count": 2},
        "world": payload_world,
        "suspended_expedition": {},
        "cross_run": {
            "tactical_echo_record": {},
            "doctrine_observation_summary": {"sample_count": 24},
            "doctrine_plan": {},
        },
    }
    var payload_restored = WorldCampaignScript.new()
    if not payload_restored.restore_save_payload(old_payload):
        failures.append("W21 did not accept the retained W12 payload schema containing a v1 world")
    elif payload_restored.segment_index != 3 or payload_restored.state != WorldCampaignScript.STATE_HUB:
        failures.append("W21 payload migration did not land a fresh v1 completion at the final branch")

    var active_snapshot := _pre_w21_snapshot(WorldCampaignScript.STATE_EXPEDITION)
    active_snapshot["active_choice_id"] = "deep_rescue_patrol"
    active_snapshot["active_region_id"] = "afterglow_frontier"
    active_snapshot["active_expedition_id"] = "exp-pre-w21-final"
    active_snapshot["expedition_attempt"] = 7
    var active = WorldCampaignScript.new()
    if not active.restore_snapshot(active_snapshot):
        failures.append("W21 could not restore a pre-W21 active Ash Railway expedition")
    else:
        var active_context := active.expedition_context()
        if active.segment_index != 3 or bool(active_context.get("post_final", true)):
            failures.append("pre-W21 first post-final expedition was not adopted as the W21 final branch")
        var active_settlement := active.settle_expedition("settlement:pre-w21-final", "success")
        if not bool(active_settlement.get("ok", false)) or active.segment_index != 4 or active.state != WorldCampaignScript.STATE_POST_FINAL:
            failures.append("adopted pre-W21 final expedition did not complete the W21 campaign once")
        else:
            var after_once := active.snapshot()
            var duplicate := active.settle_expedition("settlement:pre-w21-final", "success")
            if str(duplicate.get("status", "")) != "ALREADY_APPLIED" or active.snapshot() != after_once:
                failures.append("W21 migration broke settlement idempotency after completing an adopted expedition")

    var completed_snapshot := _pre_w21_snapshot(WorldCampaignScript.STATE_POST_FINAL)
    completed_snapshot["post_final_cycle"] = 1
    completed_snapshot["completed_choices"] = ["deep_rescue_patrol"]
    completed_snapshot["horizontal_unlocks"] = ["rescue_network"]
    completed_snapshot["access_rights"] = ["ark_berth", "post_final_patrol"]
    completed_snapshot["applied_settlement_ids"] = ["settlement:pre-w21-repeat"]
    var completed = WorldCampaignScript.new()
    if not completed.restore_snapshot(completed_snapshot):
        failures.append("W21 could not restore a pre-W21 world that had already completed a W19 connection")
    else:
        if completed.segment_index != 4 or completed.state != WorldCampaignScript.STATE_POST_FINAL:
            failures.append("pre-W21 completed W19 progress was incorrectly replayed as a new final branch")
        if not completed.horizontal_unlocks.has("rescue_network") or not completed.access_rights.has("post_final_patrol"):
            failures.append("pre-W21 W19 persistent world effects were lost during W21 migration")
        if not completed.applied_settlement_ids.has("settlement:pre-w21-repeat"):
            failures.append("pre-W21 settlement ledger was lost during W21 migration")


static func _verify_recoverable_final_branch(failures: Array[String]) -> void:
    var model = WorldCampaignScript.new()
    model.segment_index = WorldCampaignScript.FINAL_BRANCH_SEGMENT
    model.state = WorldCampaignScript.STATE_HUB
    var start := model.begin_expedition("lighthouse_survey")
    if not bool(start.get("ok", false)):
        failures.append("W21 recoverable-failure fixture could not enter Eclipse Fortress")
        return
    var failed := model.settle_expedition("w21-final-failed", "failed")
    if str(failed.get("status", "")) != "SETTLED_FAILED_RECOVERABLE":
        failures.append("W21 final regional branch failure was not explicitly recoverable")
    if model.segment_index != WorldCampaignScript.FINAL_BRANCH_SEGMENT or model.state != WorldCampaignScript.STATE_HUB:
        failures.append("W21 failed final regional branch advanced campaign progression")
    if not model.has_progress_path() or model.departure_options().size() != 2:
        failures.append("W21 failed final regional branch created a world-graph dead end")


static func _pre_w21_snapshot(restored_state: String) -> Dictionary:
    return {
        "schema": WorldCampaignScript.PRE_W21_SCHEMA,
        "campaign_seed": 20260910,
        "segment_index": WorldCampaignScript.PRE_W21_CAMPAIGN_SEGMENTS,
        "post_final_cycle": 0,
        "state": restored_state,
        "active_choice_id": "",
        "active_region_id": "",
        "active_expedition_id": "",
        "expedition_attempt": 6,
        "salvage": 80,
        "failure_count": 0,
        "rescued_residents": 9,
        "repaired_lighthouses": 3,
        "preserved_routes": 2,
        "tension": {"afterglow_frontier": 1},
        "access_rights": ["ark_berth", "archive_access"],
        "horizontal_unlocks": ["echo_archive"],
        "completed_choices": ["rescue_dockhands", "preserve_smuggler_route", "evacuate_archive"],
        "applied_settlement_ids": ["settlement:old-1", "settlement:old-2", "settlement:old-3"],
        "suspended_expedition": {},
        "cross_run_state": {
            "tactical_echo_record": {},
            "doctrine_observation_summary": {},
            "doctrine_plan": {},
        },
    }
