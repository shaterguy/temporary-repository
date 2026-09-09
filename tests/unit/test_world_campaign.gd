extends RefCounted

const WorldCampaignScript = preload("res://game/world/world_campaign_model.gd")
const SaveStoreScript = preload("res://game/core/save_store.gd")


static func run() -> Array[String]:
    var failures: Array[String] = []
    var campaign = WorldCampaignScript.new()
    campaign.reset(20260909)

    var opening := campaign.departure_options()
    if opening.size() != 2:
        failures.append("opening hub did not expose exactly two mutually exclusive choices")
        return failures
    var first: Dictionary = opening[0]
    var second: Dictionary = opening[1]
    for changed_field in ["next_region", "support_id", "shop_modifier", "threat_route", "horizontal_unlock"]:
        if first.get(changed_field, "") == second.get(changed_field, ""):
            failures.append("opening choices did not diverge %s" % changed_field)

    var start := campaign.begin_expedition(str(first.get("choice_id", "")))
    if not bool(start.get("ok", false)):
        failures.append("valid hub choice did not start expedition")
    elif campaign.begin_expedition(str(second.get("choice_id", ""))).get("status", "") != "CHOICE_ALREADY_LOCKED":
        failures.append("mutually exclusive hub choice could be switched after departure")

    var context := campaign.expedition_context()
    if context.get("region_id", "") != first.get("next_region", ""):
        failures.append("departure did not carry selected region into expedition context")
    if context.get("support_id", "") != first.get("support_id", ""):
        failures.append("departure did not carry selected support into expedition context")

    var suspend_state := {
        "ark_route": {"route_id": context.get("route_id", ""), "progress": 0.42},
        "phase": {"active": "shadow"},
        "weapon": {"weapon_id": "sunwake_lance"},
    }
    if not campaign.suspend_current_expedition(suspend_state):
        failures.append("active expedition could not create suspend checkpoint")
    var suspended_snapshot := campaign.snapshot()
    var restored = WorldCampaignScript.new()
    if not restored.restore_snapshot(suspended_snapshot):
        failures.append("world snapshot did not restore")
    elif restored.resume_payload().get("runtime_state", {}) != suspend_state:
        failures.append("suspended expedition runtime state did not round-trip")

    restored.set_cross_run_state(
        {"record_id": "echo-prior-run", "duration": 6.5},
        {"sample_count": 48, "ranged_ratio": 0.72},
        {"doctrine_id": "cover_advance", "response_cap": 0.3}
    )
    var before_success_salvage: int = int(restored.salvage)
    var settled := restored.settle_expedition(
        "settlement-alpha",
        "success",
        {"sample_count": 48, "ranged_ratio": 0.72},
        {"record_id": "echo-prior-run", "duration": 6.5},
        {"doctrine_id": "cover_advance", "response_cap": 0.3}
    )
    if not bool(settled.get("ok", false)) or not bool(settled.get("applied", false)):
        failures.append("successful expedition settlement did not apply")
    if restored.segment_index != 1:
        failures.append("successful settlement did not advance campaign segment")
    if restored.salvage <= before_success_salvage:
        failures.append("successful settlement did not apply route-specific reward")
    if restored.access_rights.size() < 2 or restored.horizontal_unlocks.is_empty():
        failures.append("successful world choice did not open persistent access and horizontal tactics")

    var after_once := restored.snapshot()
    var duplicate := restored.settle_expedition("settlement-alpha", "success")
    if duplicate.get("status", "") != "ALREADY_APPLIED" or bool(duplicate.get("applied", true)):
        failures.append("duplicate settlement id was not idempotent")
    if restored.snapshot() != after_once:
        failures.append("duplicate settlement changed persistent world state")

    var payload := restored.make_save_payload(
        {"text_scale": 1.1, "reduced_flash": true},
        {"profile_name": "CI"}
    )
    if payload.get("payload_schema", "") != WorldCampaignScript.PAYLOAD_SCHEMA:
        failures.append("save payload did not expose versioned section schema")
    for required_section in ["settings", "profile", "world", "suspended_expedition", "cross_run"]:
        if typeof(payload.get(required_section, null)) != TYPE_DICTIONARY:
            failures.append("save payload missing section %s" % required_section)
    var payload_round_trip = JSON.parse_string(JSON.stringify(payload, "", true))
    if typeof(payload_round_trip) != TYPE_DICTIONARY:
        failures.append("campaign save payload was not JSON-compatible")
    else:
        var payload_restored = WorldCampaignScript.new()
        if not payload_restored.restore_save_payload(payload_round_trip):
            failures.append("campaign save payload did not restore")
        elif payload_restored.cross_run_state.get("tactical_echo_record", {}).get("record_id", "") != "echo-prior-run":
            failures.append("W10 tactical echo carry-over was not persisted")
        elif payload_restored.cross_run_state.get("doctrine_observation_summary", {}).get("sample_count", 0) != 48:
            failures.append("W11 doctrine observation carry-over was not persisted")

    var envelope := SaveStoreScript.make_envelope(payload, 11, "settlement-alpha")
    if not SaveStoreScript.validate_envelope(envelope):
        failures.append("campaign payload could not be wrapped in transactional save envelope")

    var failure_campaign = WorldCampaignScript.new()
    failure_campaign.reset(77)
    var initial_access: Array[String] = failure_campaign.access_rights.duplicate()
    var fail_choice := str(failure_campaign.departure_options()[1].get("choice_id", ""))
    failure_campaign.begin_expedition(fail_choice)
    var failed_region := str(failure_campaign.expedition_context().get("region_id", ""))
    var failed := failure_campaign.settle_expedition("settlement-failed", "failed")
    if failed.get("status", "") != "SETTLED_FAILED_RECOVERABLE":
        failures.append("failed expedition was not converted to recoverable hub state")
    if failure_campaign.segment_index != 0:
        failures.append("failed expedition incorrectly advanced campaign")
    if int(failure_campaign.tension.get(failed_region, 0)) <= 0:
        failures.append("failed expedition did not alter regional tension")
    for right in initial_access:
        if not failure_campaign.access_rights.has(right):
            failures.append("failed expedition permanently removed a core access right")
    if not failure_campaign.has_progress_path() or failure_campaign.departure_options().size() != 2:
        failures.append("failed expedition created a dead-end instead of a retry path")

    var full_campaign = WorldCampaignScript.new()
    full_campaign.reset(99)
    for stage in range(WorldCampaignScript.CAMPAIGN_SEGMENTS):
        var options := full_campaign.departure_options()
        if options.size() < 2:
            failures.append("campaign stage %d did not retain choice" % stage)
            break
        full_campaign.begin_expedition(str(options[stage % 2].get("choice_id", "")))
        var stage_settlement := full_campaign.settle_expedition("campaign-%d" % stage, "success")
        if not bool(stage_settlement.get("ok", false)):
            failures.append("campaign stage %d could not settle" % stage)
            break
    if not full_campaign.is_campaign_complete():
        failures.append("first campaign did not reach explicit completion")
    elif full_campaign.state != WorldCampaignScript.STATE_POST_FINAL:
        failures.append("campaign completion did not enter persistent post-final hub")
    elif full_campaign.departure_options().size() != 2 or not full_campaign.has_progress_path():
        failures.append("post-final world did not retain ongoing playable choices")

    var legacy_world := {
        "schema": WorldCampaignScript.LEGACY_SCHEMA,
        "seed": 12,
        "chapter": 1,
        "credits": 31,
        "rescued": 2,
        "lighthouses": 1,
        "routes": 1,
        "access": ["legacy_key"],
        "settlements": ["legacy-settlement"],
        "doctrine_observations": {"sample_count": 20},
    }
    var migrated_world := WorldCampaignScript.migrate_snapshot(legacy_world)
    var legacy_restored = WorldCampaignScript.new()
    if migrated_world.get("schema", "") != WorldCampaignScript.SCHEMA:
        failures.append("legacy world snapshot did not migrate to current schema")
    elif not legacy_restored.restore_snapshot(legacy_world):
        failures.append("legacy world snapshot was not accepted by restore path")
    elif not legacy_restored.access_rights.has("ark_berth") or not legacy_restored.access_rights.has("legacy_key"):
        failures.append("legacy migration did not preserve access while restoring mandatory berth")

    return failures
